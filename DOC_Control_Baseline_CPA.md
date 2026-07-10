# Control de Baseline y reversión de CPA

**Versión del documento:** 1.0 — 25.06.2026

---

## ¿Qué es el Baseline?

El **Baseline** es el depósito mínimo que debe realizar un jugador para que su CPA sea válido según el deal del afiliado. El valor se define en el deal de afiliado (`campaign_deal_affiliate.Baseline`) y queda asociado a cada Marketing Source (MS) a través de `campaign_marketing_source.Deal_id`.

Cuando un jugador **ya tiene CPA procesado** en un mes (`CPA_Processed_Date`), pero sus depósitos acumulados **no alcanzan** el Baseline del deal, el sistema genera automáticamente un movimiento compensatorio en `Snapshot_day_by_day_manual` que **revierte** ese CPA en la comisión del afiliado.

> **Diferencia con el Cap (`EnforceCapCPA`):** el Cap limita la **cantidad** de CPAs por MS en un mes; el Baseline valida la **calidad** de cada jugador individual (depósito mínimo). Ambos controles son independientes y pueden estar activos simultáneamente.

---

## Componentes del sistema

| Componente | Tipo | Responsabilidad |
|---|---|---|
| `campaign_deal_affiliate.Baseline` | Campo en deal | Umbral de depósito mínimo por deal de afiliado |
| `players_general_API_idx` | Tabla índice | Resumen por jugador/MS con depósitos y mes de CPA procesado |
| `Baseline_check_to_DbD_manual` | Stored Procedure | Detecta jugadores bajo Baseline y genera la reversión |
| `Snapshot_day_by_day_manual` | Tabla | Almacena el movimiento compensatorio (`Origin = "autoBLcheck"`) |
| `Snapshot_day_by_day_fact1_upd_from_dbd_manual` | Stored Procedure | Propaga los movimientos manuales a `Snapshot_day_by_day_fact1` y calcula comisiones |
| `util_settings.EnforceBaseline` | Parámetro global | Interruptor ON/OFF del control |
| `Report_day_by_day` | Stored Procedure | Permite filtrar y auditar movimientos `autoBLcheck` en la UI |

---

## Parámetro global — `util_settings.EnforceBaseline`

### Consultar y modificar

```sql
-- Ver estado actual
SELECT Setting, Value_01, Description
FROM util_settings
WHERE Setting = 'EnforceBaseline';

-- Activar el control
UPDATE util_settings SET Value_01 = 'YES' WHERE Setting = 'EnforceBaseline';

-- Desactivar el control
UPDATE util_settings SET Value_01 = 'NO'  WHERE Setting = 'EnforceBaseline';
```

| Valor | Efecto |
|---|---|
| `YES` | `Baseline_check_to_DbD_manual` ejecuta el cálculo y escribe/actualiza movimientos `autoBLcheck` |
| `NO` | El procedimiento **termina inmediatamente** sin calcular ni modificar datos |
| *(no existe la fila)* | `IFNULL` devuelve `'NO'` → comportamiento seguro, sin compensaciones |

### Efectos al cambiar el parámetro

| Acción del admin | Qué ocurre |
|---|---|
| **Activar (`YES`)** | En la próxima ejecución de `Baseline_check_to_DbD_manual`, se recalculan las reversiones del mes indicado. Los movimientos previos de ese mes con `Origin = "autoBLcheck"` se **borran y regeneran**. |
| **Desactivar (`NO`)** | El procedimiento deja de ejecutar lógica. **No elimina** movimientos `autoBLcheck` ya existentes; las reversiones previas siguen en `Snapshot_day_by_day_manual` y en comisiones hasta que se reprocese manualmente o se vuelva a activar y recalcular. |
| **Cambiar Baseline en un deal** | Solo afecta en la **siguiente** ejecución del check (tras regenerar `players_general_API_idx`). |

> **Recomendación:** tras activar o cambiar deals, ejecutar manualmente la cadena completa (ver [Guía de operación](#guía-de-operación-paso-a-paso)) para el mes afectado.

---

## Tabla índice — `players_general_API_idx`

Tabla de trabajo que consolida jugadores de todas las APIs (`netrefer`, `mexos`, `referon`, `flutter`) en un formato uniforme. Es la **fuente de datos** del control de Baseline.

### Estructura relevante

| Campo | Descripción |
|---|---|
| `API` | Origen de datos (`netrefer`, `mexos`, `referon`, `flutter`) |
| `Customer_Reference_ID` | Identificador del jugador en la plataforma |
| `MS_id` | Marketing Source asociada |
| `Affiliate_id` / `Affiliate` | Afiliado propietario de la MS |
| `CPA_Processed_Date` | Mes (`YYYY-MM`) en que se procesó el CPA del jugador. `NULL` = sin CPA |
| `Deposits` | **Suma acumulada** de depósitos del jugador (todas las filas API agrupadas) |
| `Advertiser` / `Username_id` | Brand y cuenta operador |

### Cómo se alimenta

La tabla se regenera con:

```sql
CALL Report_players_general('genidx=yes');
```

Esto ejecuta `TRUNCATE` + recarga desde `players_netrefer_API`, `players_mexos_API`, `players_referon_API` y `players_flutter`, agrupando por jugador y MS, y calculando:

- `CPA_Processed_Date` → mes en que el operador reportó CPA procesado
- `Deposits` → `SUM()` de depósitos históricos del jugador en esa MS

> **Importante:** el Baseline compara **depósitos acumulados totales** del jugador frente al umbral del deal, no solo el depósito del mes del CPA.

### Frecuencia de actualización automática

El evento `EVENT_Snapshot_day_by_day_fact1_event` regenera el índice **dos veces al día** (12:00 y 18:00, ventana `:00–:29`) y acto seguido ejecuta `Baseline_check_to_DbD_manual`.

---

## Criterio de detección — jugador bajo Baseline

El procedimiento `Baseline_check_to_DbD_manual` evalúa, para el mes indicado:

```sql
-- Lógica simplificada
FROM players_general_API_idx i
INNER JOIN campaign_marketing_source m ON m.id = i.MS_id
INNER JOIN campaign_deal_affiliate d ON d.id = m.Deal_id
WHERE i.CPA_Processed_Date = @Mes
  AND i.Deposits < d.Baseline    -- condición de incumplimiento
```

| Condición | Resultado |
|---|---|
| `CPA_Processed_Date` del mes procesado **y** `Deposits < Baseline` | Jugador marcado como incumplimiento (`Warn_Flag = "BL"`) → se genera reversión |
| `CPA_Processed_Date` es `NULL` | Jugador **ignorado** (sin CPA procesado) |
| `Deposits >= Baseline` | Jugador **válido**, sin movimiento |
| `Baseline = 0` | Ningún depósito positivo incumple (`Deposits < 0` es improbable) → sin reversiones |
| `Baseline IS NULL` | La comparación no produce incumplimiento → sin reversiones |
| MS sin match en `campaign_marketing_source` | Jugador **excluido** del cálculo (INNER JOIN) |

---

## Procedimiento principal — `Baseline_check_to_DbD_manual`

### Qué hace (paso a paso)

1. Lee `EnforceBaseline` de `util_settings`. Si es `NO`, **sale sin hacer nada**.
2. Determina el mes a procesar (default: mes actual `CM`).
3. **Borra** movimientos previos del mismo mes con `Origin = "autoBLcheck"` en `Snapshot_day_by_day_manual`.
4. Consulta `players_general_API_idx` unido al deal de cada MS.
5. **Inserta** una fila compensatoria por cada jugador bajo Baseline.

### Movimiento generado en `Snapshot_day_by_day_manual`

| Campo | Valor | Significado |
|---|---|---|
| `Origin` | `"autoBLcheck"` | Identifica reversión automática por Baseline |
| `Date` | `YYYY-MM-01` | Primer día del mes procesado |
| `Qualified_Players` | **`-1`** | Un CPA a revertir |
| `deal_to_apply` | `1` | Aplica solo al deal de **afiliado** |
| `is_active` | `1` | Registro activo |
| `MS_id`, `Username_id`, `Brand`, `Affiliate`, etc. | Desde el jugador/MS | Trazabilidad |

### Sintaxis de llamada

```sql
CALL Baseline_check_to_DbD_manual('');                        -- mes actual
CALL Baseline_check_to_DbD_manual('Month=CM');                -- mes actual (explícito)
CALL Baseline_check_to_DbD_manual('Month=LM');                -- mes anterior
CALL Baseline_check_to_DbD_manual('Month=2025-06');           -- mes específico
CALL Baseline_check_to_DbD_manual('Month=2025-06,Debug=Yes'); -- ver SQL sin ejecutar
```

| Key | Valores | Default | Descripción |
|---|---|---|---|
| `Month` | `CM` / `LM` / `AAAA-MM` | `CM` | Mes a procesar |
| `Debug` | `No` / `Yes` | `No` | `Yes` muestra parámetros y SQL **sin ejecutar** |

---

## Cómo se revierte la comisión del CPA

Los movimientos en `Snapshot_day_by_day_manual` **no modifican** los datos originales de las APIs ni de `Snapshot_day_by_day_fact1` de forma directa. Se propagan mediante `Snapshot_day_by_day_fact1_upd_from_dbd_manual`.

Con `deal_to_apply = 1` (Solo Afiliado), el procedimiento de propagación calcula:

| Campo en fact1 | Valor para `autoBLcheck` | Efecto |
|---|---|---|
| `Qualified_Players` (lado gestor) | `0` | No impacta contadores del gestor |
| `Qualified_Players_Adjusted` | `-1` | Registra el ajuste real |
| `CPA_Value_Affiliate` | `-1 × CPA_Value del deal` | **Comisión negativa** → revierte el CPA del afiliado |
| `CPA_Value_Gestor` | `0` | Sin impacto en gestor |

**Ejemplo:** deal con `CPA_Value = 150` y jugador bajo Baseline → se inserta `Qualified_Players = -1` → `CPA_Value_Affiliate = -150`.

---

## Visualización y auditoría — `Report_day_by_day`

Cuando `EnforceBaseline = YES`, el reporte Day-by-Day (modo `manual`) expone el filtro **"only auto BLine"** que corresponde a `Origin = autoBLcheck`.

```sql
-- Ver solo reversiones por Baseline del mes actual
CALL Report_day_by_day('origin=autoBLcheck,month=CM');

-- Consulta directa en tabla manual
SELECT *
FROM Snapshot_day_by_day_manual
WHERE Origin = 'autoBLcheck'
  AND LEFT(Date, 7) = '2025-06'
ORDER BY Affiliate, MS_id;
```

Si `EnforceBaseline = NO`, el filtro **no aparece** en la lista de filtros del reporte (aunque los datos históricos sigan en la tabla).

---

## Flujo operativo completo

```
  ┌──────────────────────────────────────────────────────────────┐
  │  APIs de operadores (netrefer, mexos, referon, flutter)      │
  └────────────────────────────┬─────────────────────────────────┘
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Report_players_general('genidx=yes')                        │
  │  → TRUNCATE + recarga players_general_API_idx                │
  │     (Deposits acumulados + CPA_Processed_Date por jugador)   │
  └────────────────────────────┬─────────────────────────────────┘
                               │
              ┌────────────────▼────────────────┐
              │  EnforceBaseline = YES ?        │
              └────────┬───────────────┬────────┘
                    NO│               │YES
                      ▼               ▼
              (sin cambios)   Baseline_check_to_DbD_manual
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
        Borra autoBLcheck   Detecta jugadores  Inserta filas
        del mes             con Deposits <      Qualified_Players=-1
                            Baseline            Origin=autoBLcheck
                               │
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  Snapshot_day_by_day_fact1_upd_from_dbd_manual('CM'/'LM')    │
  │  → CPA_Value_Affiliate negativo en Snapshot_day_by_day_fact1 │
  └────────────────────────────┬─────────────────────────────────┘
                               ▼
  ┌──────────────────────────────────────────────────────────────┐
  │  total_monthy_comm_aff_upd / fact2 / dashboards / facturas   │
  └──────────────────────────────────────────────────────────────┘
```

### Ejecución automática (evento programado)

En cada ciclo del evento `EVENT_Snapshot_day_by_day_fact1_event` (cada ~30 min):

1. **Siempre** (inicio del evento): `Cap_excess_to_DbD_manual`, luego `Snapshot_day_by_day_fact1_upd_from_dbd_manual` para CM y LM.
2. **Solo a las 12:00 y 18:00** (`:00–:29`):
   - `Report_players_general('genidx=yes')`
   - `Baseline_check_to_DbD_manual('')`

> **Nota de timing:** en la ventana 12:00/18:00, el `Baseline_check` se ejecuta **después** del `fact1_upd_from_dbd_manual` del mismo ciclo. Las reversiones generadas se reflejan en comisiones en el **ciclo siguiente** del evento (~30 minutos después), cuando vuelve a ejecutarse `Snapshot_day_by_day_fact1_upd_from_dbd_manual`.

---

## Guía de operación paso a paso

### Situación 1 — Activar el control por primera vez

```sql
-- 1. Activar interruptor
UPDATE util_settings SET Value_01 = 'YES' WHERE Setting = 'EnforceBaseline';

-- 2. Regenerar índice de jugadores
CALL Report_players_general('genidx=yes');

-- 3. Calcular reversiones (mes anterior como ejemplo)
CALL Baseline_check_to_DbD_manual('Month=LM');

-- 4. Propagar a tabla de hechos y comisiones
CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('LM');
CALL total_monthy_comm_aff_upd('');
```

### Situación 2 — Verificar antes de aplicar

```sql
CALL Baseline_check_to_DbD_manual('Month=2025-06,Debug=Yes');
```

Muestra el SQL de borrado, inserción y la consulta CTE **sin modificar datos**.

### Situación 3 — Reprocesar un mes

```sql
CALL Report_players_general('genidx=yes');
CALL Baseline_check_to_DbD_manual('Month=2025-01');
CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('2025-01');
```

El procedimiento borra automáticamente los `autoBLcheck` previos de ese mes y los recalcula.

### Situación 4 — Desactivar el control

```sql
UPDATE util_settings SET Value_01 = 'NO' WHERE Setting = 'EnforceBaseline';
```

Para **eliminar** reversiones ya aplicadas de un mes:

```sql
-- Opción A: borrar manualmente y reprocesar fact1
DELETE FROM Snapshot_day_by_day_manual
WHERE Origin = 'autoBLcheck' AND LEFT(Date, 7) = '2025-06';

CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('2025-06');
CALL total_monthy_comm_aff_upd('');
```

### Situación 5 — Consultar jugadores bajo Baseline sin escribir datos

```sql
SELECT i.Customer_Reference_ID, i.Affiliate, i.Advertiser AS Brand,
       i.CPA_Processed_Date, i.Deposits, d.Baseline,
       CASE WHEN i.Deposits < d.Baseline THEN 'BL' ELSE 'OK' END AS Estado
FROM players_general_API_idx i
INNER JOIN campaign_marketing_source m ON m.id = i.MS_id
INNER JOIN campaign_deal_affiliate d ON d.id = m.Deal_id
WHERE i.CPA_Processed_Date = '2025-06'
  AND i.Deposits < d.Baseline;
```

### Situación 6 — Auditar en la interfaz

En el reporte Day-by-Day (DbD manual), filtrar por **Data type → only auto BLine** (visible solo con `EnforceBaseline = YES`).

---

## Relación con otros controles

| Control | Setting | Origin en DbD manual | Qué compensa |
|---|---|---|---|
| Cap de CPA | `EnforceCapCPA` | `autoCapExcess` | Exceso de jugadores calificados sobre `CPA_Limit` de la MS |
| Baseline | `EnforceBaseline` | `autoBLcheck` | CPAs de jugadores con depósitos por debajo del umbral del deal |

Ambos pueden coexistir. Un mismo jugador podría, en teoría, aparecer en ambos controles por motivos distintos. Los movimientos se distinguen por el campo `Origin`.

---

## Preguntas frecuentes

**¿El procedimiento modifica los datos originales de las APIs o de `Snapshot_day_by_day_fact1` directamente?**
No. Solo escribe en `Snapshot_day_by_day_manual` con `Origin = "autoBLcheck"`. La propagación a fact1 y comisiones la hace `Snapshot_day_by_day_fact1_upd_from_dbd_manual`.

**¿Qué pasa si cambio el Baseline de un deal ya procesado?**
Las reversiones existentes no se actualizan solas. Hay que regenerar el índice (`genidx=yes`), volver a ejecutar `Baseline_check_to_DbD_manual` para el mes y propagar con `fact1_upd_from_dbd_manual`.

**¿Un jugador con depósito exactamente igual al Baseline se revierte?**
No. La condición es estricta: `Deposits < Baseline`. Si `Deposits = Baseline`, el jugador cumple.

**¿Se revierte si el jugador nunca depositó (`Deposits = 0`)?**
Sí, siempre que tenga `CPA_Processed_Date` en el mes y `0 < Baseline`.

**¿Qué ocurre si `EnforceBaseline` no existe en `util_settings`?**
`IFNULL` devuelve `'NO'` y el procedimiento sale sin hacer nada (fallo seguro).

**¿Por qué no veo el filtro "only auto BLine" en Day-by-Day?**
El filtro solo se muestra cuando `EnforceBaseline = 'YES'` y el reporte está en modo `DbD = manual`.

**¿Cuántas reversiones se generan por jugador?**
Una fila con `Qualified_Players = -1` por jugador/MS que incumple en el mes procesado.

**¿El índice `players_general_API_idx` está desactualizado?**
El control puede omitir jugadores nuevos o usar depósitos obsoletos. Asegurarse de ejecutar `genidx=yes` antes del check, especialmente en reprocesos manuales.

---

## Referencia de stored procedures

| Procedure | Uso de `EnforceBaseline` |
|---|---|
| `Baseline_check_to_DbD_manual` | Lee el setting; si `NO`, termina sin procesar |
| `Report_day_by_day` | Muestra filtro `Origin=autoBLcheck` solo si `YES` |
| `Report_players_general` | Regenera `players_general_API_idx` (`GenIdx=Yes`) — prerequisito del check |
| `Snapshot_day_by_day_fact1_upd_from_dbd_manual` | Propaga movimientos `autoBLcheck` a comisiones |
| `EVENT_Snapshot_day_by_day_fact1_event` | Orquesta `genidx` + `Baseline_check` a las 12:00 y 18:00 |
