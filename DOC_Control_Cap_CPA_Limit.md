# Control de Cap (CPA_Limit) por Marketing Source

**Versión del documento:** 1.0 — 02.06.2026

---

## ¿Qué es el Cap de una Marketing Source?

El **Cap** (también denominado `CPA_Limit`) es el límite máximo de jugadores calificados (CPA —
*Cost Per Acquisition*) que el sistema acepta acreditar a una Marketing Source (MS) durante
un período mensual.

Cuando la suma de jugadores calificados de una MS **supera** su Cap, el exceso **no** se
registra como ganancia del afiliado: el sistema genera automáticamente un movimiento
compensatorio negativo en `Snapshot_day_by_day_manual` para neutralizar el excedente.

---

## Componentes del sistema

El control de Cap involucra tres elementos que trabajan en conjunto:

| Componente | Tipo | Responsabilidad |
|---|---|---|
| `campaign_mkt_source_cap_date` | Tabla | Historial de valores de Cap por MS y fecha |
| `campaign_marketing_source_after_update_cap` | Trigger | Registra automáticamente cada cambio de Cap |
| `Cap_excess_to_DbD_manual` | Stored Procedure | Calcula y aplica la compensación por exceso |

Existe además una tabla de excepciones (`campaign_mkt_source_cap_real`) que permite
**anular** el Cap estándar para afiliados específicos.

---

## Tabla de historial de Cap — `campaign_mkt_source_cap_date`

Esta tabla almacena **una fila por Marketing Source y por fecha de cambio**, registrando
qué valor de Cap estaba vigente a partir de cada día.

| Campo | Tipo | Descripción |
|---|---|---|
| `MS_id` | INT | ID de la Marketing Source |
| `Date_Valid` | DATE | Fecha desde la que rige este valor de Cap |
| `Affiliate_id` | INT | ID del afiliado dueño de la MS |
| `CPA_Limit` | INT | Valor del Cap vigente desde `Date_Valid` |
| `is_active` | TINYINT | `1` = activo, `0` = ignorado en los cálculos |
| `User` | VARCHAR | Usuario que realizó el cambio |

> **Clave única:** la combinación `(MS_id, Date_Valid)` es única. Si se cambia el Cap más
> de una vez el mismo día, solo se guarda el **último valor** del día.

---

## Cómo se registran los cambios de Cap — Trigger

El trigger `campaign_marketing_source_after_update_cap` se dispara **automáticamente**
cada vez que se modifica el campo `CPA_Limit` en la tabla `campaign_marketing_source`.

### Flujo del trigger

```
Usuario/sistema modifica CPA_Limit en campaign_marketing_source
            ↓
  Trigger detecta que NEW.CPA_Limit ≠ OLD.CPA_Limit
            ↓
  INSERT en campaign_mkt_source_cap_date
    · MS_id       = id de la MS modificada
    · CPA_Limit   = nuevo valor
    · Date_Valid  = fecha actual (CURDATE())
    · Affiliate_id= afiliado de la MS
    · User        = Operator que hizo el cambio
            ↓
  Si ya existía fila para esa MS en esa fecha → actualiza CPA_Limit (ON DUPLICATE KEY)
```

**Resultado:** sin ninguna acción manual, el historial de Cap queda actualizado en tiempo
real cada vez que alguien modifica el límite de una MS.

---

## Cómo se determina el Cap vigente para un día concreto

Al calcular el exceso para un mes, el sistema necesita saber qué Cap correspondía a cada
MS en cada día de ese mes. La resolución sigue este **orden de prioridad**:

```
Prioridad 1 (mayor) → campaign_mkt_source_cap_real   (excepción por afiliado)
Prioridad 2         → campaign_mkt_source_cap_date    (historial por MS y fecha)
Prioridad 3         → CPA_Limit directo de la MS      (valor actual en campaign_marketing_source)
Prioridad 4 (menor) → 1 000                           (valor por defecto si no hay ningún dato)
```

### Tabla de excepciones — `campaign_mkt_source_cap_real`

Permite definir, para un afiliado específico, un **Cap Real** que **reemplaza por completo**
el Cap estándar de todas sus MS durante un rango de meses.

| Campo | Descripción |
|---|---|
| `Affiliate_id` | Afiliado al que aplica la excepción |
| `Cap_Real` | Valor de Cap alternativo |
| `Month_Valid_From` | Primer mes en que rige (`AAAA-MM`) |
| `Month_Valid_To` | Último mes (NULL = sin fecha de fin) |
| `is_active` | `1` = activo |

> **Importante:** cuando un afiliado tiene una fila activa en `campaign_mkt_source_cap_real`
> para el mes calculado, el historial de `campaign_mkt_source_cap_date` es **ignorado** para
> ese afiliado.

---

## Procedimiento principal — `Cap_excess_to_DbD_manual`

Este procedimiento realiza el cálculo mensual de exceso de Cap y genera los movimientos
de compensación.

### Qué hace

1. Verifica que el control de Cap esté **activado** en `util_settings`.
2. Para el mes indicado, agrega los jugadores calificados por MS desde
   `Snapshot_day_by_day_fact1`.
3. Determina el Cap vigente para cada MS usando el orden de prioridad descrito arriba.
4. Identifica las MS donde la suma de jugadores **supera** el Cap.
5. **Borra** los movimientos de compensación anteriores del mismo mes en
   `Snapshot_day_by_day_manual` (origen `"autoCapExcess"`).
6. **Inserta** nuevas filas con el exceso como valor negativo de `Qualified_Players`,
   marcadas con `Origin = "autoCapExcess"`.

### Sintaxis de llamada

```sql
call Cap_excess_to_DbD_manual('');                        -- mes actual
call Cap_excess_to_DbD_manual('Month=CM');                -- mes actual (explícito)
call Cap_excess_to_DbD_manual('Month=LM');                -- mes anterior
call Cap_excess_to_DbD_manual('Month=2025-06');           -- mes específico
call Cap_excess_to_DbD_manual('Month=2025-06,Debug=Yes'); -- ver SQL sin ejecutar
call Cap_excess_to_DbD_manual('Debug=Yes');               -- mes actual, sin ejecutar
```

### Parámetros

| Key | Valores posibles | Default | Descripción |
|---|---|---|---|
| `Month` | `CM` / `LM` / `AAAA-MM` | `CM` (mes actual) | Mes a procesar |
| `Debug` | `No` / `Yes` / `KeyValues` | `No` | Modo de depuración |

#### Modo Debug

| Valor | Comportamiento |
|---|---|
| `No` | Ejecución normal: borra y regenera los movimientos de compensación |
| `Yes` | Muestra los parámetros internos y el SQL generado **sin ejecutar nada** |
| `KeyValues` | Muestra los valores de las claves parseadas y ejecuta normalmente |

---

## Activar y desactivar el control de Cap

El control de Cap tiene un **interruptor global** en la tabla `util_settings`:

```sql
-- Ver estado actual
SELECT Value_01 FROM util_settings WHERE Setting = 'EnforceCapCPA';

-- Activar
UPDATE util_settings SET Value_01 = 'YES' WHERE Setting = 'EnforceCapCPA';

-- Desactivar
UPDATE util_settings SET Value_01 = 'NO'  WHERE Setting = 'EnforceCapCPA';
```

Mientras `EnforceCapCPA = 'NO'`, el procedimiento finaliza inmediatamente sin calcular
ni modificar ningún dato.

---

## Carga histórica inicial

Si la tabla `campaign_mkt_source_cap_date` está vacía o incompleta (por ejemplo, al
instalar el sistema por primera vez), se puede reconstruir el historial a partir de la
tabla de auditoría `campaign_marketing_source_history` ejecutando el script:

```
PROCESO_CPA_Limit_histórico_desde_campaign_marketing_source_history.sql
```

Este script:

1. Crea la tabla `campaign_mkt_source_cap_date` si no existe.
2. Recorre todas las entradas de auditoría donde `Aud_Action LIKE '%CPA_Limit%'`.
3. Para cada cambio detectado, determina el valor **resultante** usando `LEAD()`:
   - Si hay un cambio posterior → el Cap vigente desde esa fecha es el valor *siguiente*.
   - Si es el último cambio registrado → el Cap vigente es el valor actual en
     `campaign_marketing_source`.
4. Inserta o actualiza (`ON DUPLICATE KEY`) la tabla con todos los tramos históricos.

> **Cuándo ejecutarlo:** solo en la instalación inicial o si la tabla fue vaciada.
> En operación normal el trigger mantiene el historial actualizado de forma automática.

---

## Flujo operativo completo

```
                  ┌─────────────────────────────────────┐
                  │  Cambio de CPA_Limit en la MS       │
                  └──────────────────┬──────────────────┘
                                     │ Trigger automático
                                     ▼
                  ┌─────────────────────────────────────┐
                  │  campaign_mkt_source_cap_date       │
                  │  (historial actualizado)            │
                  └──────────────────┬──────────────────┘
                                     │
                  ┌──────────────────▼──────────────────┐
                  │  Cap_excess_to_DbD_manual (mensual) │
                  │  Llamar: al cierre de mes o         │
                  │  cuando se recalculen los datos     │
                  └──────────────────┬──────────────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              ▼                      ▼                      ▼
   Borra filas anteriores    Calcula exceso por MS   Inserta filas nuevas
   (Origin=autoCapExcess)    comparando acum. vs Cap  con valor negativo
   del mismo mes             vigente en cada fecha    (Origin=autoCapExcess)
```

---

## Guía de operación paso a paso

### Situación 1 — Operación mensual normal

Al finalizar cada mes (o cuando se desee actualizar los datos):

```sql
-- Procesar el mes anterior
call Cap_excess_to_DbD_manual('Month=LM');

-- O procesar el mes actual
call Cap_excess_to_DbD_manual('');
```

### Situación 2 — Verificar qué se va a calcular antes de aplicar

```sql
-- Ver el SQL y los parámetros sin modificar datos
call Cap_excess_to_DbD_manual('Month=2025-06,Debug=Yes');
```

### Situación 3 — Reprocesar un mes anterior

```sql
call Cap_excess_to_DbD_manual('Month=2025-01');
```

El procedimiento borrará automáticamente los movimientos anteriores de ese mes y los
recalculará con los datos actuales.

### Situación 4 — Agregar excepción de Cap para un afiliado

```sql
INSERT INTO campaign_mkt_source_cap_real
    (Affiliate_id, Brand, Cap_Real, Month_Valid_From, Month_Valid_To, Operator)
VALUES
    (39, 'BrandX', 50, '2025-06', NULL, 'admin');
-- Month_Valid_To = NULL significa "sin fecha de fin"
```

### Situación 5 — Consultar el historial de Cap de una MS

```sql
SELECT Date_Valid, CPA_Limit, User, Creation_Date
FROM campaign_mkt_source_cap_date
WHERE MS_id = 123          -- reemplazar por el MS_id deseado
  AND is_active = 1
ORDER BY Date_Valid DESC;
```

---

## Preguntas frecuentes

**¿Qué pasa si se cambia el Cap varias veces el mismo día?**
Solo se conserva el último valor del día. El trigger usa `ON DUPLICATE KEY UPDATE`, por
lo que la combinación `(MS_id, fecha_de_hoy)` siempre queda con el valor más reciente.

**¿El procedimiento modifica datos originales de `Snapshot_day_by_day_fact1`?**
No. Solo escribe en `Snapshot_day_by_day_manual` con `Origin = "autoCapExcess"`. Los
datos originales nunca se tocan.

**¿Puedo desactivar el control de Cap solo para un afiliado sin apagar todo el sistema?**
Sí. Inserta una fila en `campaign_mkt_source_cap_real` con `Cap_Real = 9999` para ese
afiliado durante el período deseado. Un Cap de 9999 en la práctica nunca se alcanza.

**¿Cuándo debo ejecutar la carga histórica inicial?**
Solo una vez, al instalar el sistema por primera vez o si la tabla
`campaign_mkt_source_cap_date` fue vaciada accidentalmente. En operación normal el
trigger mantiene el historial sin intervención manual.

**¿Qué ocurre si `EnforceCapCPA` no existe en `util_settings`?**
`IFNULL` devuelve `'NO'` y el procedimiento sale sin hacer nada. El sistema falla de
forma segura: nunca aplica compensaciones no esperadas.
