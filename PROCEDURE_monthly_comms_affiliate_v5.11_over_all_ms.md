# RS afiliado `aggregate_all_ms` — propuesta v5.11

Valor grabado en `campaign_deal_affiliate.RS_Base` y en `Snapshot_day_by_day_fact2.Deal_Aff_RS_Base`: `aggregate_all_ms`.

Propuesta para `monthly_comms_affiliate_v5`, a partir de `PROCEDURE_monthly_comms_affiliate_v5.10.sql`.
No sustituye las bases `account`, `operator`, `operator/brand` ni `brand`. Solo añade el valor `aggregate_all_ms` en `campaign_deal_affiliate.RS_Base`.

Modalidad pedida para ritemood: el RS a pagar al afiliado en un mes es la suma algebraica de todas sus MS, sin carry over, y solo se paga si esa suma es positiva. La tabla `monthly_comms_affiliate_v5` debe seguir pudiendo alimentar el Gross Margin por account/brand, así que las filas de detalle conservan el signo.

## 1. Qué cambia respecto de v5.10

En v5.10 un valor de `RS_Base` distinto de `account`, `operator` y `operator/brand` se trata como `brand`. `aggregate_all_ms` hoy entraría en ese `ELSE`.

El prorrateo v5.10 (`KeyRSAcum`) hace tres cosas que esta modalidad no quiere:

- agrupa por account, operator o brand, no por el afiliado entero;
- pone `net_RS_Val = 0` en toda fila con RS previa ≤ 0;
- reparte el neto positivo entre las filas positivas, de modo que ninguna fila queda negativa.

`aggregate_all_ms` no prorratea. Cada fila de detalle guarda la suma con signo. El pago del afiliado es `MAX(suma, 0)`. Si la suma es negativa, una fila extra deja el total en cero.

## 2. Quién entra en el pool

Una fila diaria de `Snapshot_day_by_day_fact2` entra en el pool si, con el mismo fallback que v5.10, la base normalizada es `aggregate_all_ms`:

1. `TRIM(campaign_deal_affiliate.RS_Base)` si el deal existe y el texto no es vacío (`Deal_Aff_id = campaign_deal_affiliate.id`);
2. si no, `TRIM(fact2.Deal_Aff_RS_Base)` si no es vacío;
3. si no, no es `aggregate_all_ms` (sigue el default `brand`).

Comparación con `LOWER`. El literal es `aggregate_all_ms`.

El pool de un mes es:

`Affiliate_id + Month + Currency`

`Currency` es `Data_Currency` de fact2. No se convierten importes: la suma pedida es la de la columna ya calculada. Si el mismo afiliado y mes tuviera dos monedas, son dos pools y dos decisiones de pago. En ritemood se asume una sola moneda.

No se separa por MS, `Code_To_Affiliate`, account, brand, operator ni `Publisher_id`. Esas dimensiones solo sirven para el desglose que se graba.

Las filas con otra `RS_Base` siguen el cálculo v5.10, incluido el prorrateo que no deja `net_RS_Val` negativo. No se mezclan con este pool ni con su fila de compensación.

## 3. Importe de RS que se suma

Para estas filas el RS no se recalcula con `Deal_Aff_RS * Net_Revenue / 100`.

```text
RS_linea = IFNULL(fact2.Revenue_Share_Affiliate, 0)
S        = ROUND(SUM(RS_linea), 2)   -- pool: afiliado + mes + moneda
```

`S` es la suma algebraica: positivos y negativos se suman tal cual. Incluye todas las MS del afiliado en el mes que estén en el pool.

`Deal_Aff_RS_Against_CPA` no se aplica dentro de este pool. El CPA de las filas de detalle sigue la fórmula v5.10 (`Deal_Aff_CPA * Qualified_Players`, o `CPA_Value_Affiliate` si el CPA del deal no es > 0). El RS no se resta del CPA.

No hay carry over. `RS_carry_NCO` sigue en 0. Un mes negativo no pasa al mes siguiente.

## 4. Qué se paga

| S del pool | RS pagado al afiliado |
|---|---|
| S > 0 | S |
| S = 0 | 0 |
| S < 0 | 0 |

El CPA del mes se paga igual que en v5.10. Esta regla solo anula el RS cuando el pool es negativo o cero.

## 5. Filas de detalle en `monthly_comms_affiliate_v5`

Grano, el mismo del insert `CPA+RS` actual:

`Affiliate_id + Account_id + Advertiser_id + Month`

`Account_id` es `fact2.Username_id`. `Advertiser_id` es la brand.

Para cada grano que tenga alguna línea del pool:

```text
gross_RS_Val = ROUND(SUM(RS_linea), 2)
net_RS_Val   = gross_RS_Val
```

El valor puede ser negativo. No se reemplaza por 0 ni se prorratea contra otras brands.

`net_Total_comm = net_CPA_Val + net_RS_Val`. Con RS negativa, el total de esa fila puede ser menor que el CPA o negativo.

`Comm_type = 'CPA+RS'`. `Owner`, `Affiliate`, `Brand`, `Product`, `Product_Real`, `Channel` y `Channel_id` se rellenan como en v5.10 (`MAX` de las filas del grano).

Así, al agrupar la tabla por account/brand, el RS es la suma algebraica de ese account/brand. El Gross Margin por operator/brand/account puede usar esas filas con signo. El operator no es columna de la tabla; sale del account (`campaign_username.Publisher_id`), igual que hoy.

Invariante de las filas de detalle del pool:

```text
SUM(net_RS_Val de detalle) = S
```

## 6. Fila de compensación

Solo si `S < 0`. No se inserta si `S >= 0`.

Una fila por pool (`Affiliate_id + Month + Currency`):

| Columna | Valor |
|---|---|
| `Comm_type` | `RS-OFFSET` |
| `Account_id` | 0 |
| `Advertiser_id` | 0 |
| `Brand` | vacío |
| `Affiliate_id` | el del pool |
| `Currency` | la moneda del pool |
| `CPA` | 0 |
| `net_CPA_Val` | 0 |
| `gross_CPA_Val` | 0 |
| `gross_RS_Val` | 0 |
| `Net_Revenue` | 0 |
| `net_RS_Val` | `-S` (positivo) |
| `net_Total_comm` | `net_RS_Val` |
| `RS_carry_NCO` | 0 |
| `Sub_Affiliate_id` | 0 |

`-S` se calcula sobre los `net_RS_Val` ya redondeados del detalle, no sobre la suma cruda, para que el total almacenado cierre en cero:

```text
net_RS_Val_offset = -SUM(net_RS_Val de las filas CPA+RS del pool)
```

Efecto sobre el afiliado y el mes:

| | SUM(`gross_RS_Val`) | SUM(`net_RS_Val`) | RS que entra al pago |
|---|---:|---:|---:|
| S > 0 | S | S | S |
| S = 0 | 0 | 0 | 0 |
| S < 0 | S | 0 | 0 |

`Report_balance_by_affiliate` suma `net_Total_comm` de todas las filas del afiliado y el mes, sin filtrar `Comm_type`. Con la fila `RS-OFFSET`, un pool negativo no aumenta ni disminuye el saldo: el RS pagado queda en 0 y el CPA sigue en las filas de detalle.

La fila no lleva `Advertiser_id` real. Un Gross Margin agrupado por brand no debe atribuirla a un operador. Quien sume `net_RS_Val` sin excluir `Comm_type = 'RS-OFFSET'` verá el RS pagado (`MAX(S,0)`), no el RS algebraico por brand.

## 7. Ejemplos

Un afiliado, un mes, EUR. CPA aparte, para aislar el RS.

### 7.1 Total positivo

| Account | Brand | SUM(`Revenue_Share_Affiliate`) |
|---|---|---:|
| 10 | Spinbara | 100.00 |
| 20 | Golaimo | -30.00 |

`S = 70`. No hay fila offset.

| Fila | net_RS_Val | net_CPA_Val (ejemplo) | net_Total_comm |
|---|---:|---:|---:|
| account 10 / Spinbara | 100.00 | 50.00 | 150.00 |
| account 20 / Golaimo | -30.00 | 20.00 | -10.00 |

RS pagado = 70. CPA pagado = 70. Total pagado = 140.

En v5.10 (base brand, prorrateo) la fila negativa habría quedado en 0 y los 70 se habrían cargado solo a Spinbara. Aquí no.

### 7.2 Total negativo

| Account | Brand | SUM(`Revenue_Share_Affiliate`) |
|---|---|---:|
| 10 | Spinbara | 40.00 |
| 20 | Golaimo | -100.00 |

`S = -60`. Se paga 0 de RS.

| Fila | Comm_type | net_RS_Val |
|---|---|---:|
| account 10 / Spinbara | CPA+RS | 40.00 |
| account 20 / Golaimo | CPA+RS | -100.00 |
| compensación | RS-OFFSET | 60.00 |

`SUM(net_RS_Val) = 0`. El margen de Spinbara sigue viendo +40 y el de Golaimo -100.

### 7.3 Total cero

40 y -40 en dos brands. `S = 0`. No hay offset. `SUM(net_RS_Val) = 0`.

## 8. Qué no cambia

- Ventana del procedure: `p_month` `YYYY-MM`, o corte a dos meses si viene NULL, vacío o inválido. `DELETE` de `Month >= corte` y los tres inserts.
- CPA+RS de las otras `RS_Base`, con el prorrateo actual.
- BONUS.
- `RS_carry_NCO = 0`.

REFER sigue leyendo solo `Comm_type = 'CPA+RS'`. La fila `RS-OFFSET` no genera referral.

Consecuencia: `Perc_on_RS` se aplica al `net_RS_Val` con signo de cada brand, no al RS pagado del afiliado. En el ejemplo 7.2 el master vería +40 y -100 por brand, aunque el afiliado cobre 0 de RS. No se cambia esa fórmula en esta propuesta. Si el referral debe ser `Perc_on_RS` sobre `MAX(S, 0)` una sola vez por afiliado y mes, es un cambio aparte.

## 9. Cambios concretos en el procedure (v5.11)

Archivo nuevo `PROCEDURE_monthly_comms_affiliate_v5.11.sql`. Misma firma `monthly_comms_affiliate_v5(IN p_month VARCHAR(7))`. Historial: línea nueva, sin borrar las anteriores. `v_Version` y `COMMENT` a `v5.11`.

Dentro del CTE `src` del insert CPA+RS, reconocer la base antes del `ELSE`:

```sql
WHEN 'aggregate_all_ms' THEN 'aggregate_all_ms'
```

`KeyRSAcum` de esas filas:

```text
M|{Affiliate_id}|{Data_Currency}
```

No incluye account, brand ni publisher.

El RS mensual de esas filas, en el CTE `monthly`, usa la suma de `Revenue_Share_Affiliate` en lugar de `Deal_Aff_RS * Net_Revenue / 100 * FactorNR`. Hay que arrastrar la columna desde `src`.

En `netted`, si `RS_Base = 'aggregate_all_ms'`:

- `net_CPA_Val = gross_CPA_Val` (sin Against_CPA);
- `net_RS_pre = gross_RS_Val` (con signo; no se anula por `Deal_Aff_RS = 0` si la columna de fact2 trae importe).

En `final_rows`, si la base es `aggregate_all_ms`, `net_RS_Val = net_RS_pre`. No entra al `CASE` que pone 0 y prorratea.

Después del `INSERT` de detalle, un segundo insert del mismo paso, solo pools con suma de detalle < 0:

```sql
INSERT INTO monthly_comms_affiliate_v5 ( ... Comm_type, net_RS_Val, net_Total_comm ... )
SELECT
    MAX(Owner), 0, 'RS-OFFSET', Month, MAX(Affiliate), '',
    Affiliate_id, 0, Currency,
    0, 0,
    -SUM(net_RS_Val),
    -SUM(net_RS_Val),
    0, 0, 0, 0,
    '', 0, '', '', '', 0
FROM monthly_comms_affiliate_v5
WHERE Month >= corte
  AND Comm_type = 'CPA+RS'
  AND Affiliate_id IN ( /* afiliados con alguna fila aggregate_all_ms en el mes */ )
GROUP BY Affiliate_id, Month, Currency
HAVING SUM(net_RS_Val) < 0;
```

Ese `IN` no puede ser “cualquier CPA+RS del afiliado”: un afiliado puede tener deals `brand` y deals `aggregate_all_ms` en el mismo mes. La suma y el offset usan solo las filas cuyo RS salió del pool `aggregate_all_ms`.

Hace falta marcarlas. La tabla no tiene columna `RS_Base`. Opciones, en este orden:

1. Calcular el offset en el mismo `INSERT` del paso 1, con un `UNION ALL` sobre los CTE, antes de que las filas de otras bases se mezclen. No exige columna nueva. Es la opción propuesta.
2. Añadir `RS_Base VARCHAR(30)` a `monthly_comms_affiliate_v5` y filtrar `RS_Base = 'aggregate_all_ms'`. Hace visible la base en la app y en el GM, a cambio de un `ALTER` y de tocar los tres inserts.

La opción 1 basta para el criterio pedido. La marca en tabla queda fuera de esta versión.

REFER y BONUS no se reescriben. El offset tiene que existir antes de REFER solo si más adelante el referral debe ver el RS pagado. Con la regla del apartado 8, REFER no lo usa, así que puede insertarse al final del paso 1, antes del paso 2.

## 10. Comprobaciones

Para un afiliado y un mes con todos los deals en `aggregate_all_ms`:

```sql
-- S de fact2
SELECT Affiliate_id, LEFT(`Date`, 7) AS Month, Data_Currency,
       ROUND(SUM(IFNULL(Revenue_Share_Affiliate, 0)), 2) AS S
FROM Snapshot_day_by_day_fact2
WHERE Affiliate_id = :id AND LEFT(`Date`, 7) = :month
GROUP BY Affiliate_id, LEFT(`Date`, 7), Data_Currency;

-- detalle: debe coincidir con S, partido por account/brand
SELECT Account_id, Advertiser_id, Brand, net_RS_Val, gross_RS_Val, net_CPA_Val
FROM monthly_comms_affiliate_v5
WHERE Affiliate_id = :id AND Month = :month AND Comm_type = 'CPA+RS';

-- pago de RS
SELECT SUM(net_RS_Val) AS rs_pagado
FROM monthly_comms_affiliate_v5
WHERE Affiliate_id = :id AND Month = :month;
-- esperado: GREATEST(S, 0)
```

Casos mínimos: S positivo con una brand negativa, S negativo, S cero, afiliado con un deal `aggregate_all_ms` y otro `brand` en el mismo mes (el offset no absorbe el RS del deal `brand`).
