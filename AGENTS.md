# CLAUDE.md — Contexto de desarrollo: proyecto **euroaffiliati**

Este archivo describe el entorno, convenciones y patrones de desarrollo del proyecto.
Debe ser leído por cualquier asistente de IA antes de generar o modificar código.

---

## Entorno

- **Sistema operativo:** Windows 11 Pro (exclusivo)
- **Base de datos principal:** MySQL 8.0 — objetivo de compatibilidad: **MySQL 8.0.37**
- **Migración planificada:** MySQL 8.4 (señalar explícitamente si alguna sintaxis requiere 8.4+)
- **Herramientas secundarias (uso ocasional):** Python 3.10+, PowerShell, cmd
- **Idioma de código:** documentación, comentarios y mensajes internos siempre en **español**

## Conexión a base de datos

| Entorno      | Host        | Puerto | Usuario    | Contraseña | Versión    | Uso |
|--------------|-------------|--------|------------|------------|------------|-----|
| Local (dev)  | localhost   | 3304   | b3w1nn3r   | abcd       | MySQL 8.4  | Desarrollo y pruebas |

**Desde línea de comandos:**
```bash
mysql -h localhost -P 3304 -u b3w1nn3r -pabcd
```

**Con login path (alternativa segura):**
```bash
mysql --login-path=local
```
> Las credenciales también están almacenadas en `~/.mylogin.cnf` bajo el login path `local`.

**Modo de trabajo con el asistente de IA:**
El asistente no puede conectarse directamente al servidor local. El flujo es:
1. El asistente genera el SQL (SP, query de prueba, etc.)
2. El usuario lo ejecuta en su MySQL local y pega el resultado
3. El asistente valida, corrige si aplica, y se repite el ciclo

---

## Stack de desarrollo

El código está escrito **casi en su totalidad como Stored Procedures MySQL**.
No se utilizan ORMs, frameworks web ni capas intermedias como código principal.

### Ubicación del código fuente

```
D:\Reinaldo\_FRA\db\PROCEDUREs\*.sql
```

- Solo archivos `PROCEDURE_*.sql` en la carpeta raíz (no subcarpetas)
- Los archivos `.old` son versiones anteriores conservadas automáticamente

---

## Nomenclatura y versionado

### Nombre de archivo

```
PROCEDURE_<Nombre>_vX.Y[.Z].sql
```

**Ejemplos:**
```
PROCEDURE_Report_players_netrefer_v2.4.sql
PROCEDURE_clientes_v1.0.sql
```

### Reglas de versionado

- Incrementar la **versión menor** como máximo **una vez por día** por SP
- **No versionar cada modificación dentro del mismo día**: si ya hubo revisión ese día, seguir editando el **mismo archivo** activo sin renombrar, sin nuevo `.old` y sin nueva línea en el historial
- Al subir versión (primer cambio del día o día nuevo), actualizar **tres lugares** simultáneamente:
  1. Nombre del archivo
  2. Historial del encabezado (nueva línea `dd.mm.yyyy vX.Y descripción`)
  3. Variable interna de versión (`v_Version` o `@Version`)
- **No sobrescribir** el historial previo — solo agregar línea nueva cuando corresponda subir versión
- La versión anterior se conserva con el mismo nombre pero extensión **`.old`** (solo al renombrar por nueva revisión)

```
PROCEDURE_Report_players_netrefer_v2.3.sql  →  PROCEDURE_Report_players_netrefer_v2.3.old
PROCEDURE_Report_players_netrefer_v2.4.sql  ←  versión activa
```

---

## Estructura estándar de un Stored Procedure

### 1. Encabezado del archivo (bloque `/* ... */`)

```sql
/*
PROCEDURE_<Nombre>_vX.Y.sql

Observaciones:
  [instrucciones generales de uso]
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  KeyName   = [ValorA | ValorB]. Descripción. OPCIONAL. Default=[valor].
  MultiKey  = [ValorA ^ ValorB ^ ValorC]. Acepta múltiples valores separados por ^.
  ...

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  call NombreSP('debug=yes');
  call NombreSP('debug=yes,FiltroX=valor');
  call NombreSP('MultiKey=ValorA^ValorB,debug=yes');

dd.mm.yyyy V1     Primera versión operativa
dd.mm.yyyy v1.1   Descripción del cambio
dd.mm.yyyy v2     Descripción del cambio mayor
*/
```

### 2. Estructura del CREATE PROCEDURE

```sql
DROP PROCEDURE IF EXISTS Nombre_SP;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Nombre_SP`(IN InputCommLine VARCHAR(250))
COMMENT 'Descripción corta del propósito'
SQL SECURITY DEFINER
proc_label:BEGIN
  DECLARE v_Version VARCHAR(32) DEFAULT 'vX.Y dd.mm.yyyy';
  -- DECLARE variables locales...
  -- Defaults, parseo, validaciones, lógica, query final
END$$
DELIMITER ;
```

---

## Parámetros de entrada — `InputCommLine`

Todos los procedures reciben **un único parámetro `VARCHAR(250)`** llamado `InputCommLine`
con todos los parámetros como pares `Key=Value` separados por comas.

### Reglas de sintaxis

- Claves **case-insensitive** (se normalizan a `LOWER()` para comparación, se guardan en `UPPER()`)
- Valores **sin comillas** (ni simples ni dobles)
- Cada par termina en **coma**
- String completo entre **comillas simples** en el CALL
- Para múltiples valores en un mismo parámetro, separar con **`^`**

```sql
call MiProcedure('Affiliate_id=39,Data_Month=2025-06,Debug=yes');
call MiProcedure('Producto=Sport^Footbol,Debug=yes');
```

### Parseo interno

```sql
SET v_InputCommLine = CONCAT(InputCommLine, ',');       -- coma de cierre
SET v_InputCommLine = REPLACE(v_InputCommLine, '"', ''); -- eliminar comillas

WHILE v_InputCommLine > ' ' DO
    SET v_e = INSTR(v_InputCommLine, '=');
    SET v_c = INSTR(v_InputCommLine, ',');
    SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
    SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
    SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);
    -- mapeo con LOWER(v_k)...
END WHILE;
```

### Variables internas

- Usar siempre **`DECLARE v_*`** — nunca variables de sesión `@*` para lógica interna
- Usar `IFNULL` / `COALESCE` y conversiones explícitas para evitar nulos inesperados
- Inicializar todos los defaults al inicio del `BEGIN`, antes del parseo

### Keys estándar (presentes en todos los procedures de reporte)

| Key       | Valores                    | Default | Descripción |
|-----------|----------------------------|---------|-------------|
| `Debug`   | `No` / `Yes` / `KeyValues` | `No`    | Controla modo de ejecución |
| `Filters` | `Yes` / `No`               | `No`    | Devuelve lista de filtros en lugar de datos |
| `Meta`    | `Yes` / `No`               | `Yes`   | Incluye fila de metadatos de renderizado |

### Modo Debug

- `Debug=No` → ejecuta el SQL dinámico normalmente
- `Debug=Yes` → devuelve el SQL generado **sin ejecutarlo**
- `Debug=KeyValues` → ejecuta y devuelve los valores de los parámetros parseados

### Ejecución de SQL dinámico

Evitar SQL dinámico salvo necesidad real. Si se usa, siempre con `PREPARE / EXECUTE / DEALLOCATE`:

```sql
IF v_Debug != 'YES' THEN
    SET @v_stmt_sql = v_SQL;
    PREPARE stmt1 FROM @v_stmt_sql;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;
END IF;
```

### Literales en SQL dinámico generado

En el texto SQL que se arma con `CONCAT` / variables `@SQL*` para `PREPARE`, usar **comillas dobles** `"` para literales string del query generado. **No** duplicar apóstrofos (`''valor''`).

- Bloque embebido entre comillas simples del SP; literales del SQL resultante con `"`:
  `SET @SQL = CONCAT('SELECT "setting" AS Meta, "data" AS Meta FROM t WHERE `Status` = "', REPLACE(@Status, '"', '""'), '"');`
- Escapar `"` dentro de valores dinámicos con `REPLACE(..., '"', '""')`.
- La lógica interna del SP (`IF`, `SET`, comparaciones) sigue usando comillas simples `'`.
- Requiere `ANSI_QUOTES` activo en la sesión que ejecuta el SQL dinámico (habitual en este proyecto).

### Variante MySQL 9.7+ (`*_mysql98.sql`)

Para despliegues en **MySQL 9.7 / 9.8**, preferir SPs reescritos sin `PREPARE/EXECUTE`:

- Consultas **estáticas** con variables locales `DECLARE v_*` en `WHERE` / `IF`.
- Nombre del procedure distinto (ej. `Report_payment_methods_mysql98`) para convivir con la variante dinámica.
- Opcional: `SET optimizer_switch='hypergraph_optimizer=on'` (Hypergraph Optimizer, MySQL 9.7 Community).
- La variante dinámica con `"` en SQL generado sigue siendo válida para MySQL 8.0–8.4.

---

## Patrón Filters

Cuando `Filters=Yes`, el procedure devuelve los **valores disponibles por filtro**
en lugar de datos, respetando los filtros ya activos.

**Estructura del resultado:**

| Columna   | Descripción |
|-----------|-------------|
| `Korder`  | Orden de presentación |
| `Key`     | Nombre legible del filtro (ej. `"Data Month"`) |
| `Value`   | Valor a mostrar |
| `Caption` | Nombre del parámetro en InputCommLine (ej. `"Data_Month"`) |
| `id`      | Identificador interno |
| `extra`   | Campo adicional opcional |

**Construcción:**
```sql
(SELECT '01','Data Month', `Date`,    'Data_Month',    `Date`,         '' FROM tabla WHERE ...)
UNION ALL
(SELECT '04','Affiliate',  `Affiliate`,'Affiliate_id', `Affiliate_id`, '' FROM tabla WHERE ...)
ORDER BY Korder ASC,
         CASE WHEN Korder IN ('01','05','06') THEN Value END DESC,
         CASE WHEN Korder NOT IN ('01','05','06') THEN Value END ASC;
```

---

## Patrón Meta — setting / data / total

Cuando `Meta=YES` (default), el resultset incluye filas especiales para renderizado
dinámico en el frontend, sin lógica hardcodeada.

**Tipos de fila Meta:**

| Valor       | Descripción |
|-------------|-------------|
| `"setting"` | Metadatos de formato por columna (desde `DUAL`), siempre primera |
| `"data"`    | Filas de datos normales |
| `"total"`   | Filas de totales/resumen |

**Directivas disponibles en la fila `setting`:**

| Directiva            | Descripción |
|----------------------|-------------|
| `"width=100px"`      | Ancho de columna |
| `"right=true"`       | Alineación derecha (campos numéricos) |
| `"omit=yes"`         | Columna oculta en el frontend |
| `"tooltip=yes"`      | Mostrar tooltip en hover |

**Ejemplo:**
```sql
(
SELECT
   'setting'                  AS Meta,
   'width=100px'              AS `Date`,
   'width=150px,tooltip=yes'  AS `Brand`,
   'omit=yes'                 AS `Internal_id`,
   'width=100px,right=true'   AS `Gross_Revenue`
FROM DUAL WHERE 'YES' = 'YES'   -- condicionado por v_Meta
)
UNION ALL
SELECT 'data' AS Meta, campo1, campo2, ... FROM tabla WHERE ...
```

---

## SP de escritura (INSERT / UPDATE / DELETE)

- Incluir manejo de errores con `DECLARE ... HANDLER`
- En operaciones multi-paso usar transacciones explícitas:

```sql
START TRANSACTION;
-- operaciones...
IF v_Error = 0 THEN
    COMMIT;
ELSE
    ROLLBACK;
END IF;
```

- Registrar estado/versión cuando aplique y devolver resultado trazable
- Usar `LEAVE proc_label` para salida anticipada con mensaje claro ante parámetros inválidos

---

## Checklist antes de entregar un SP

- [ ] Compila sin errores en MySQL 8.0.37
- [ ] `DROP PROCEDURE IF EXISTS` presente antes del `CREATE`
- [ ] Versión actualizada en: nombre de archivo, historial del encabezado y variable interna
- [ ] `COMMENT` del `CREATE PROCEDURE` alineado al propósito actual
- [ ] Ejemplos de `CALL` actualizados y funcionales
- [ ] Comentarios y mensajes en **español**
- [ ] No se introducen cambios funcionales fuera del objetivo declarado
- [ ] Si aplica: crear o actualizar `TEST_PROCEDURE_*.sql`

---

## Reglas generales para el asistente de IA

1. Aplicar estas reglas **solo a archivos `PROCEDURE_*.sql`** en `PROCEDUREs/`
2. **No sobrescribir** el historial de versiones — siempre agregar línea nueva
3. Usar **`DECLARE v_*`** para variables locales; nunca `@*` para lógica interna
5. **Evitar SQL dinámico** salvo necesidad real; si se usa, siempre con flag `Debug` y literales `"` en el SQL generado (no `''`)
5. **No introducir cambios colaterales** fuera del objetivo del ticket/tarea
6. Señalar explícitamente si alguna sintaxis propuesta requiere **MySQL 8.4+**
7. Mantener **nombres de columnas de salida consistentes** con los reportes/UI existentes
8. El separador para múltiples valores en un mismo parámetro es **`^`**
