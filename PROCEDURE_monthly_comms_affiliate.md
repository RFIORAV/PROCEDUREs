# monthly_comms_affiliate_v5 — especificación v5.10 (12.09.2026)

Documento para reconstruir el proceso sin el fuente.
Implementación de referencia: `PROCEDURE_monthly_comms_affiliate_v5.10.sql`.
Procedure: `monthly_comms_affiliate_v5`. MySQL 8.0.37 / 8.4 (`LATERAL` requiere 8.0.14+).

El procedure no devuelve un resultset. Borra una ventana de `monthly_comms_affiliate_v5` y la vuelve a cargar en tres pasos: `CPA+RS`, `REFER`, `BONUS`.

```sql
CALL monthly_comms_affiliate_v5('2026-08');  -- desde 2026-08 inclusive
CALL monthly_comms_affiliate_v5(NULL);       -- desde hace 2 meses
CALL monthly_comms_affiliate_v5('');         -- igual que NULL
```

## 1. Parámetro y ventana

`p_month VARCHAR(7)`.

Corte `v_LMonth`:

- usar `p_month` solo si no es NULL, no es `''`, cumple `^[0-9]{4}-[0-9]{2}$` y `STR_TO_DATE(CONCAT(p_month,'-01'),'%Y-%m-%d')` no es NULL (`2026-13` cae al default);
- si no, `LEFT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), 7)`.

Fechas:

- `v_LMonthDate` = día 1 del corte.
- `v_CurrentMonthDate` = día 1 del mes de `CURDATE()`.

Efecto: `DELETE` e inserts cubren todo `Month >= corte`, sin tope superior. Meses futuros presentes en fact entran en CPA+RS y en BONUS. En REFER, un enlace con `Valid_To` NULL no pasa del mes corriente (apartado 5).

Asignar también `@LMonthDate`, `@CurrentMonthDate` y `@Version` (`'v5.10 12.09.2026'`). El cálculo usa las variables locales `v_*`.

## 2. Tabla destino

Crear si no existe. No añadir clave única: el `DELETE` es lo que hace idempotente el recálculo. `INSERT IGNORE` no deduplica sin unique key.

```sql
CREATE TABLE IF NOT EXISTS `monthly_comms_affiliate_v5` (
  `Owner`            INT            NOT NULL DEFAULT 0,
  `Account_id`       INT            NOT NULL DEFAULT 0,
  `Comm_type`        VARCHAR(80)        NULL DEFAULT NULL COMMENT 'CPA+RS | REFER | BONUS',
  `Month`            VARCHAR(7)     NOT NULL DEFAULT '0000-00',
  `Affiliate`        VARCHAR(80)    NOT NULL DEFAULT '',
  `Brand`            VARCHAR(80)    NOT NULL DEFAULT '',
  `Affiliate_id`     INT            NOT NULL DEFAULT 0,
  `Advertiser_id`    INT            NOT NULL DEFAULT 0,
  `Currency`         VARCHAR(20)    NOT NULL DEFAULT '',
  `CPA`              DECIMAL(12,0)  NOT NULL DEFAULT 0,
  `net_CPA_Val`      DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `net_RS_Val`       DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `net_Total_comm`   DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `RS_carry_NCO`     DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `Net_Revenue`      DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `gross_CPA_Val`    DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `gross_RS_Val`     DECIMAL(12,2)  NOT NULL DEFAULT 0,
  `Sub_Affiliate`    VARCHAR(80)        NULL DEFAULT '',
  `Sub_Affiliate_id` INT                NULL DEFAULT 0,
  `Product`          VARCHAR(80)        NULL DEFAULT '',
  `Product_Real`     VARCHAR(80)        NULL DEFAULT '',
  `Channel`          VARCHAR(80)        NULL DEFAULT '',
  `Channel_id`       INT                NULL DEFAULT 0,
  INDEX `Month_Affiliate_id` (`Month`, `Affiliate_id`),
  INDEX `Affiliate_id_Month` (`Affiliate_id`, `Month`),
  INDEX `Month_Advertiser_id` (`Month`, `Advertiser_id`)
);
```

Borrado, antes de cualquier insert (comparar como fecha, no como string):

```sql
DELETE FROM `monthly_comms_affiliate_v5`
WHERE STR_TO_DATE(CONCAT(`Month`, '-01'), '%Y-%m-%d') >= v_LMonthDate;
```

`RS_carry_NCO` se inserta siempre en 0. `campaign_deal_affiliate.Carry_Over` / `Deal_Aff_Carry_Over` se leen en el agregado mensual y no intervienen en ningún importe.

## 3. Dependencias

| Objeto | Uso |
|---|---|
| `Snapshot_day_by_day_fact2` | Hechos diarios del afiliado (CPA+RS y BONUS) |
| `campaign_deal_affiliate` | `RS_Base`, `Currency` del deal (`id` = `fact2.Deal_Aff_id`) |
| `getCurrencyConversion(valor, origen, destino)` | Factor NR. `exchange_rate.Rate` por `LEFT(simbolo,3)`. Misma moneda → 1. Devuelve `valor * rate_dest / rate_origen` |
| `monthly_comms_affiliate_v5` | REFER lee las filas `CPA+RS` del propio paso 1 |
| `master_affiliate_deals_per_affiliate` | Enlace Master–Sub, brand, vigencia, `Deal_id` |
| `master_affiliate_deals_v2` | Importes y % del deal MA |
| `account_account` | `username` de Master y Sub (`id`) |
| `Snapshot_day_by_day_fact1` | Margen gestor − afiliado |
| `campaign_deal_affiliate_bonus_v2` | Reglas de bonus |
| `campaign_deal_affiliate_bonus_brand` | Brands de la regla (`Bonus_id`, `Advertiser_id`). Cero filas = todas |
| `campaign_advertiser` | `Advertiser_Name` para el CSV de `Brand` |

Columnas de fact2 usadas: `Owner`, `Username_id`, `DATE`, `Affiliate_id`, `Affiliate`, `Advertiser_id`, `Publisher_id`, `Brand`, `Qualified_Players`, `Net_Revenue`, `First_Time_Deposit`, `Deal_Aff_id`, `Deal_Aff_CPA`, `Deal_Aff_Carry_Over`, `Deal_Aff_RS_Against_CPA`, `Deal_Aff_RS`, `Deal_Aff_RS_Base`, `CPA_Value_Affiliate`, `Data_Currency`, `Product`, `Product_Real`, `Channel`, `Channel_id`, `Code_To_Affiliate`.

Columnas de fact1 usadas: `DATE`, `Affiliate_id`, `Advertiser_id`, `CPA_Value_Gestor`, `CPA_Value_Affiliate`, `Revenue_Share_Gestor`, `Revenue_Share_Affiliate`.

`campaign_deal_affiliate`: `id`, `RS_Base` (default de tabla `brand`), `Currency`.

`master_affiliate_deals_v2`: `Value_by_CPA`, `Perc_on_Tot_Comm`, `Perc_on_CPA_Value`, `Perc_on_RS`, `Perc_on_Margin_value`, `Deal_Currency` (default `EUR`).

`master_affiliate_deals_per_affiliate`: `Master_Affiliate_id`, `Sub_Affiliate_id`, `Advertiser_id`, `Status_id` (default `'1'`), `Deal_id`, `Valid_From`, `Valid_To`.

`campaign_deal_affiliate_bonus_v2`: `id`, `Affiliate_id`, `Code_to_Affiliate`, `Date_Valid_From`, `Date_Valid_to`, `Bonus_Value`, `Bonus_NR`, `Bonus_Value_per_CPA`, `Currency`, `Conditions` (`ANY`|`ALL`), `CPA_min`, `NR_min`, `FTD_min`, `Status_id`. En el esquema desplegado `Affiliate_id` es `NOT NULL`; el SP igual trata NULL y 0 como “todos”.

## 4. Paso 1 — CPA+RS

Filtro: `fact2.DATE >= v_LMonthDate`. `LEFT JOIN campaign_deal_affiliate d ON f.Deal_Aff_id = d.id`.

### 4.1 Fila diaria (`src`)

| Campo | Expresión |
|---|---|
| `Account_id` | `Username_id` |
| `Month` | `LEFT(DATE,7)` |
| `Publisher_id` | `IFNULL(...,0)` |
| `Qualified_Players`, `Net_Revenue` | `IFNULL(...,0)` |
| `Deal_Aff_CPA`, `Deal_Aff_RS`, `CarryOver`, `CPAminusRS` | columnas `Deal_Aff_*` con `IFNULL(...,0)` |
| `gross_CPA_Val_raw` | `IFNULL(CPA_Value_Affiliate,0)` |
| `Deal_Currency` | `IFNULL(d.Currency, f.Data_Currency)` |
| `FactorNR` | `1` si `Data_Currency = d.Currency`; si no `getCurrencyConversion(1, Data_Currency, d.Currency)` |
| `RS_Base` | ver 4.2 |

### 4.2 RS_Base y KeyRSAcum

Texto normalizado, en este orden de fallback:

1. `TRIM(d.RS_Base)` si no es NULL ni `''`;
2. si no, `TRIM(fact2.Deal_Aff_RS_Base)` si no es NULL ni `''`;
3. si no, `'brand'`.

Luego `LOWER` y solo estos cuatro valores; cualquier otro (incluido vacío ya resuelto) queda en `brand`:

| RS_Base | KeyRSAcum |
|---|---|
| `account` | `A\|{Affiliate_id}\|{Account_id}` |
| `operator` | `O\|{Affiliate_id}\|{Publisher_id}` |
| `operator/brand` | `OB\|{Affiliate_id}\|{Publisher_id}\|{Brand}` |
| `brand` (default) | `B\|{Affiliate_id}\|{Brand}` |

La clave ya incluye `Affiliate_id`. El acumulado agrupa además por `Month`.

### 4.3 Agregado mensual (antes del netting)

`GROUP BY Account_id, Month, Affiliate_id, Advertiser_id, Publisher_id, Deal_Aff_id, RS_Base, Deal_Currency, Brand, Product_Real, Channel_id`.

`Owner`, `Affiliate`, `Product`, `Channel`, `Deal_Aff_CPA`, `CarryOver`, `CPAminusRS`, `Deal_Aff_RS` = `MAX`. Métricas = `SUM`.

```text
gross_CPA_Val = ROUND(SUM(
    CASE WHEN Deal_Aff_CPA > 0
         THEN Deal_Aff_CPA * Qualified_Players
         ELSE gross_CPA_Val_raw
    END), 2)

gross_RS_Val = ROUND(SUM(
    CASE WHEN Deal_Aff_RS = 0 THEN 0
         ELSE Deal_Aff_RS * Net_Revenue / 100 * FactorNR
    END), 2)
```

`HAVING SUM(Qualified_Players) <> 0 OR MAX(Deal_Aff_RS) <> 0`.

### 4.4 CPA contra RS (`netted`)

Solo si `CPAminusRS = 1` y `gross_RS_Val < 0`. RS positiva no se resta del CPA.

| Caso | `net_CPA_Val` | `net_RS_pre` |
|---|---|---|
| Against_CPA y RS<0 y `gross_CPA >= ABS(gross_RS)` | `gross_CPA - ABS(gross_RS)` | `0` |
| Against_CPA y RS<0 y el CPA no cubre | `0` | `gross_CPA - ABS(gross_RS)` (negativo) |
| `Deal_Aff_RS = 0` | `gross_CPA` | `0` |
| resto | `gross_CPA` | `gross_RS_Val` |

### 4.5 Acumulado y prorrateo

Por `Month, Affiliate_id, KeyRSAcum`:

- `net_RS_Acum` = `SUM(net_RS_pre)` (incluye negativas);
- `net_RS_Pos` = `SUM(net_RS_pre)` solo donde `net_RS_pre > 0`.

Por fila de `netted`:

```text
net_RS_Val = 0
  si net_RS_Acum <= 0
  o net_RS_pre <= 0
  o net_RS_Pos <= 0
si no
  ROUND(net_RS_pre * net_RS_Acum / net_RS_Pos, 2)
```

Las filas negativas o cero no cobran RS. Las positivas se reparten el neto del grupo (positivas menos negativas) en proporción a su `net_RS_pre`. El resultado de cada fila es ≥ 0. El redondeo a 2 decimales puede dejar céntimos de diferencia entre la suma asignada y `net_RS_Acum`.

### 4.6 Insert

Segundo `GROUP BY` (aquí se pierden publisher, deal, moneda, brand, producto y canal como clave):

`Affiliate_id, Account_id, Advertiser_id, Month`.

| Columna | Valor |
|---|---|
| `Owner`, `Affiliate`, `Brand`, `Deal_Currency`, `Product`, `Product_Real`, `Channel`, `Channel_id` | `MAX` |
| `Comm_type` | `'CPA+RS'` |
| `CPA` | `ROUND(SUM(CPA),0)` |
| `net_CPA_Val`, `net_RS_Val`, `Net_Revenue`, `gross_CPA_Val`, `gross_RS_Val` | `ROUND(SUM(...),2)` |
| `net_Total_comm` | `ROUND(SUM(net_CPA_Val)+SUM(net_RS_Val),2)` |
| `RS_carry_NCO` | `0` |
| `Sub_Affiliate` | `' '` (un espacio) |
| `Sub_Affiliate_id` | `0` |
| `Currency` | `MAX(Deal_Currency)` |

`ORDER BY Affiliate_id, Account_id, Advertiser_id, Month`. `Owner` no va en ningún `GROUP BY` ni `ORDER BY` de este paso.

Si un mismo `Account_id + Advertiser_id + Month` mezcla deals, monedas o brands, los importes se suman y los textos/moneda quedan en el `MAX`.

## 5. Paso 2 — REFER

Se ejecuta después del paso 1 y solo lee `Comm_type = 'CPA+RS'` con `Month >= corte`.

### 5.1 Catálogo de enlaces

`master_affiliate_deals_per_affiliate` M
`LEFT JOIN account_account` del Sub y del Master (`username`)
`LEFT JOIN master_affiliate_deals_v2` por `M.Deal_id`.

`Advertiser_id` y porcentajes/valores: `IFNULL(...,0)`. `Status_id`: `IFNULL(...,'1')`. `Deal_Currency`: `IFNULL(...,'EUR')`.

### 5.2 Producción del subafiliado

Agrupar CPA+RS por `Month, Affiliate_id, Advertiser_id, Brand`:

`CPA`, `net_CPA_Val`, `net_RS_Val`, `net_Total_comm`, `Net_Revenue` = `SUM`. `Affiliate` y `Owner` = `MAX`. Los accounts quedan sumados.

### 5.3 Un deal por SA + mes + brand

`INNER JOIN LATERAL` al catálogo:

- mismo `Sub_Affiliate_id`;
- `Status_id = '1'`;
- `Advertiser_id = 0` o `= Advertiser_id` de la brand;
- día 1 del `Month` `>= Valid_From`;
- día 1 del `Month` `<= COALESCE(Valid_To, v_CurrentMonthDate)`.

`ORDER BY Advertiser_id DESC LIMIT 1`. El id concreto gana al 0. Dos filas con el mismo `Advertiser_id` dejan el ganador indefinido (no hay segundo criterio).

Sin enlace vigente no hay fila REFER. `Net_Revenue` del SA se arrastra en el CTE y no se graba (la columna sale 0).

### 5.4 Margen

Sobre fact1 con `DATE >= v_LMonthDate`, por `LEFT(DATE,7), Affiliate_id, Advertiser_id`:

```text
Estimated_Margin = SUM(
    IFNULL(CPA_Value_Gestor,0) - IFNULL(CPA_Value_Affiliate,0)
  + IFNULL(Revenue_Share_Gestor,0) - IFNULL(Revenue_Share_Affiliate,0)
)
```

`LEFT JOIN` al deal por Sub + Advertiser + Month. Sin fact1, el margen es 0.

### 5.5 Importes y filtro

Sobre las cifras ya neteadas del SA+brand (no sobre el gross):

```text
net_CPA_Val = ROUND(
    CPA * Value_by_CPA
  + net_CPA_Val * Perc_on_CPA_Value / 100, 2)

net_RS_Val = ROUND(net_RS_Val * Perc_on_RS / 100, 2)

net_Total_comm = ROUND(
    CPA * Value_by_CPA
  + net_CPA_Val * Perc_on_CPA_Value / 100
  + net_RS_Val * Perc_on_RS / 100
  + net_Total_comm * Perc_on_Tot_Comm / 100
  + IFNULL(Estimated_Margin,0) * Perc_on_Margin_value / 100, 2)
```

Insertar solo si ese `net_Total_comm <> 0`. Puede ser negativo (los % no se truncan).

| Columna | Valor |
|---|---|
| `Comm_type` | `'REFER'` |
| `Affiliate_id`, `Affiliate` | Master |
| `Sub_Affiliate_id`, `Sub_Affiliate` | SA |
| `Owner` | `MAX(Owner)` de las filas CPA+RS del SA |
| `Account_id` | `0` |
| `Brand`, `Advertiser_id`, `Month`, `CPA` | los del agregado SA+brand |
| `Currency` | `Deal_Currency` del deal MA |
| `Net_Revenue`, `gross_CPA_Val`, `gross_RS_Val`, `RS_carry_NCO` | `0` |
| `Product`, `Product_Real`, `Channel` | `''` |
| `Channel_id` | `0` |

`ORDER BY Master_Affiliate_id, Sub_Affiliate_id, Advertiser_id, Month`.

## 6. Paso 3 — BONUS

Independiente de las filas CPA+RS. Lee fact2 otra vez.

### 6.1 Reglas candidatas

`campaign_deal_affiliate_bonus_v2` con:

- `IFNULL(Status_id,0) = 1`;
- `Date_Valid_From IS NOT NULL`;
- `Date_Valid_From <= LAST_DAY(v_CurrentMonthDate)`;
- `IFNULL(Date_Valid_to,'9999-12-31') >= v_LMonthDate`.

Campos: `Bonus_Value`, `Bonus_NR`, `Bonus_Value_per_CPA` con `IFNULL(...,0)`. `Currency`: `TRIM`; vacío o NULL → `'EUR'`. `Conditions`: `UPPER(TRIM(IFNULL(...,'ANY')))`. Umbrales `IFNULL(...,0)`.

`Has_Brands` = existe al menos una fila en `campaign_deal_affiliate_bonus_brand` para ese `id`.

`Brand` = `LEFT(GROUP_CONCAT(DISTINCT campaign_advertiser.Advertiser_Name ORDER BY Advertiser_Name SEPARATOR ','), 80)`. Sin filas hija, `'ALL'`.

`Code_to_Affiliate` = `NULLIF(TRIM(IFNULL(...,'')),'')` (vacío pasa a NULL = sin filtro).

### 6.2 Acumulado del mes

`INNER JOIN fact2` con `DATE >= v_LMonthDate` y:

- `LEFT(DATE,7) >= LEFT(Date_Valid_From,7)`;
- `LEFT(DATE,7) <= LEFT(Date_Valid_to,7)` (NULL ya sustituido por `9999-12-31`);
- `Affiliate_id` de la regla IS NULL o = 0 o = `fact2.Affiliate_id`;
- si `Code_to_Affiliate` no es NULL: `UPPER(TRIM(fact2.Code_To_Affiliate)) = UPPER(Code_to_Affiliate)`;
- si `Has_Brands`: `Advertiser_id` está en la hija.

No se recorta al día de `Date_Valid_From` ni de `Date_Valid_to`: entra el mes calendario entero.

`GROUP BY Bonus_id, mes, fact2.Affiliate_id` y los atributos de la regla (`Brand`, `Currency`, importes, `Conditions`, umbrales, `Has_Brands`).

| Campo | Expresión |
|---|---|
| `CPA` | `SUM(Qualified_Players)` |
| `Net_Revenue` | `SUM(Net_Revenue)` |
| `FTD` | `SUM(First_Time_Deposit)` |
| `Owner`, `Affiliate` | `MAX` |
| `Account_id` | `0` |
| `Advertiser_id` | si `Has_Brands` y `COUNT(DISTINCT fact2.Advertiser_id)=1` entonces ese id; si no `0` |

Varias brands en la regla, o una sola brand con más de un `Advertiser_id` en el mes, dejan `Advertiser_id=0`. El CSV de `Brand` sigue siendo el de la regla, no el de la actividad.

### 6.3 Umbrales

Cualquier `Conditions` distinto de `'ALL'` se evalúa como ANY.

Umbral `<= 0` no aplica.

**ALL:** pasan a la vez `(CPA_min<=0 OR CPA>=CPA_min)`, `(NR_min<=0 OR NR>=NR_min)` y `(FTD_min<=0 OR FTD>=FTD_min)`. Los tres en 0 ⇒ la regla pasa.

**ANY:** pasa si los tres umbrales son `<= 0`, o si algún umbral `> 0` se cumple. No exige cumplir los que están en 0.

### 6.4 Importe e insert

```text
Bonus_Amount = ROUND(
    Bonus_Value
  + Net_Revenue * Bonus_NR / 100
  + CPA * Bonus_Value_per_CPA, 2)
```

Omitir si `Bonus_Amount = 0`. No hay piso en cero: un NR negativo con `Bonus_NR>0` y fijo 0 puede dar importe negativo y se graba.

| Columna | Valor |
|---|---|
| `Comm_type` | `'BONUS'` |
| `net_CPA_Val`, `net_Total_comm` | `Bonus_Amount` |
| `net_RS_Val`, `gross_CPA_Val`, `gross_RS_Val`, `RS_carry_NCO` | `0` |
| `CPA` | `ROUND(CPA,0)` |
| `Net_Revenue` | `ROUND(Net_Revenue,2)` |
| `Sub_Affiliate` | `' '` |
| `Sub_Affiliate_id` | `0` |
| `Product`, `Product_Real`, `Channel` | `''` |
| `Channel_id` | `0` |
| `Account_id` | `0` |
| `Currency` | la de la regla |

`Affiliate_id` es el del hecho, no un “todos” cuando la regla es global. `ORDER BY Affiliate_id, Month, Bonus_id`.

## 7. Qué no hace este proceso

- No aplica carry-over de RS entre meses (`RS_carry_NCO` queda en 0).
- No parte el mes de bonus por el día de vigencia.
- No convierte a EUR los importes REFER ni BONUS: respetan la moneda del deal o de la regla. La conversión solo entra en `gross_RS_Val` del paso CPA+RS (`FactorNR`).
- No genera fila REFER si el total redondeado es 0, ni BONUS si el importe redondeado es 0.
- No usa `Owner` como clave de agrupación.
- No toca meses anteriores al corte.

## 8. Comprobaciones para dar por bueno un recálculo

1. Tras `CALL` con un `YYYY-MM` válido, no quedan filas de esa tabla con `Month` anterior a ese valor tocadas, y no quedan filas `>= corte` de una ejecución previa.
2. Una fila `CPA+RS` con `Deal_Aff_RS=0` tiene `gross_RS_Val=0` y `net_RS_Val=0`.
3. Con `RS_Against_CPA=1` y RS de fila negativa, `net_CPA_Val` no baja de 0 y el remanente negativo solo sobrevive si el grupo `KeyRSAcum` cierra en positivo (entonces se absorbe en las positivas; la fila negativa queda en 0).
4. Si `SUM(net_RS_pre)` del grupo es `<= 0`, todas sus `net_RS_Val` son 0.
5. `net_Total_comm` de `CPA+RS` = `net_CPA_Val + net_RS_Val`.
6. REFER conserva una fila por brand (`Advertiser_id` y `Brand` del SA), no un único `ALL`.
7. Entre un deal MA `Advertiser_id=0` y uno de esa brand, ambos vigentes, gana el de la brand.
8. BONUS de un mes usa NR/CPA/FTD del mes completo aunque `Date_Valid_to` caiga a mitad de mes.
9. `Conditions='ALL'` con un solo umbral incumplido no inserta; `'ANY'` inserta si ese u otro umbral activo se cumple.
