# Auditoría de vulnerabilidades SQL Injection — MySQL 8
**Proyecto:** euroaffiliati · **Carpeta:** `PROCEDUREs/` · **Fecha:** 28.07.2026

Alcance: archivos `PROCEDURE_*.sql`, `FUNCTION_*.sql` y `EVENT_*.sql` en la raíz del repositorio (prioridad a código activo; se revisaron también utilidades de sync/copy/DDL). No se asume seguridad por el hecho de que el código “funcione”.

---

# Resumen

| Métrica | Valor |
|--------|------:|
| Archivos `PROCEDURE_*.sql` analizados (raíz) | 177 |
| Archivos `FUNCTION_*.sql` | 5 |
| Archivos `EVENT_*.sql` | 3 |
| Procedimientos con `PREPARE … FROM` | **115** |
| Uso de `EXECUTE … USING` (placeholders) | **0** |
| Vulnerabilidades críticas | **13** |
| Vulnerabilidades altas | **16** |
| Vulnerabilidades medias | **5** |
| Vulnerabilidades bajas / informativas | **5** |

## Observaciones

1. **Patrón sistémico:** la gran mayoría de reportes/dashboards construyen SQL con `CONCAT` + `PREPARE/EXECUTE` e inyectan valores de `InputCommLine` en el texto SQL.
2. **Falsa mitigación dominante:** `REPLACE(InputCommLine, '"', '')` elimina comillas dobles. Protege literales delimitados con `"…"`, pero **no** protege literales con `'…'`, inyección en expresiones numéricas sin comillas, ni identificadores (DB/tabla).
3. **Parser Key=Value:** los valores no pueden contener `,` (rompe el parseo). Limita payloads multilínea/multicláusula, pero **no** impide `OR 1=1`, breakout con `'` ni manipulación de WHERE.
4. **Amplificador:** muchos SP usan `DEFINER=b3w1nn3r@%` / `SQL SECURITY DEFINER` → una SQLi exitosa corre con privilegios elevados.
5. **Buenas prácticas ya presentes (referencia positiva):** `QUOTE()` en `Sync_MS_DbD_DbD_lm_v3.2`; variables de sesión dentro del prepared SQL en `Cap_excess_to_DbD_manual` / `Baseline_check_to_DbD_manual`; escape de backticks en `Optimize_tables` / `util_alter_table_customizable`.

---

# Tabla resumen

| Riesgo | Archivo | Procedimiento | Línea | Descripción |
| ------ | ------- | ------------- | ----- | ----------- |
| CRÍTICO | PROCEDURE_CopyTablesToDEV_v1.1.sql | CopyTablesToDEV | ~69–149 | `DB_destination` concatenado en DROP/TRUNCATE/CREATE/INSERT sin whitelist |
| CRÍTICO | PROCEDURE_CREATE_gambling_tables_from_DB1_to_DB2.sql | CreateGamblingTablesFromAtoB | ~80–84 | `p_db_origen`/`p_db_destino` en backticks sin escapar `` ` `` |
| CRÍTICO | PROCEDURE_util_copy_table_only_same_fields_v1.sql | util_copy_table… | ~44–97 | Nombres de tabla origen/destino concatenados en INSERT dinámico |
| CRÍTICO | PROCEDURE_Report_Publisher_ManAdj_v1_op.sql | Report_Publisher_ManAdj | ~121 | `@Search` en `LIKE '%…%'` con comilla simple, sin escape |
| CRÍTICO | PROCEDURE_Report_Affiliates_v1.6.2_tag.sql | Report_Affiliates | ~128 | `@LoginInit` en `LIKE '…%'` sin escape |
| CRÍTICO | PROCEDURE_Sync_Fact2_from_Fact1_v1.6.x.sql | Sync_Fact2_from_Fact1 | ~176–230 | `v_DB` + filtros en TRUNCATE/DELETE/INSERT dinámicos |
| CRÍTICO | PROCEDURE_Sync_MS_Fact1_Fact2_lm_v1.3.sql | Sync_MS_Fact1_Fact2_lm | ~91–152 | `MS_id` en CALL dinámico a Sync_Fact2 + DELETE local |
| CRÍTICO | PROCEDURE_Sync_MS_DbD_DbD_lm_byBrand_v1.sql | Sync_MS…byBrand | ~85–205 | `Brand` con `'` en DELETE/INSERT modo RUN |
| CRÍTICO | PROCEDURE_Publisher_balance_to_Proforma_v1.6_op.sql | Publisher_balance_to_Proforma | ~425–451 | Rama `Export=YES`: DELETE/UPDATE/INSERT dinámicos con filtros concatenados |
| CRÍTICO | PROCEDURE_MS_autogen_from_DbD_v1.sql | MS_autogen_from_DbD | ~120–138 | `@Month` en INSERT…SELECT con `'''` (comilla simple) |
| CRÍTICO | PROCEDURE_dbd_to_fact1_v1.1.sql | dbd_to_fact1 | ~146–180 | Month/Account en DELETE+INSERT dinámicos |
| CRÍTICO | PROCEDURE_Compare_Tables_Between_DBs_v1.sql | Compare_Tables_Between_DBs | ~184–256 | Schemas/tablas en PREPARE; genera ALTER |
| CRÍTICO | PROCEDURE_Compare_Fact1_Fact2_v2.sql | Compare_Fact1_Fact2 | ~157–382 | Filtros string + DELETE/INSERT de sync |
| ALTO | PROCEDURE_Report_MarketingSources1_v2.4g_MAF_op.sql | Report_MarketingSources1 | ~304–316 | Area/Account/Product/Channel/Status con `'` |
| ALTO | PROCEDURE_Report_Deal_MktPlace_v1.3_MAF_op.sql | Report_Deal_MktPlace | ~162–171 | Product/Country/Status con `'` |
| ALTO | PROCEDURE_Report_players_general_v3.5.1.sql | Report_players_general | ~205–208 | Customer_ID/Account/Tracker sin escape (Advertiser sí) |
| ALTO | PROCEDURE_Report_Documents.v2.6.3.sub.sql | Report_Documents | ~189–200 | ActionTaken/Month con `'`; Affiliate_id sin cast |
| ALTO | PROCEDURE_Report_Ads_v1.1.sql | Report_Ads | ~146–149 | Product/Account/Brand con `'` |
| ALTO | PROCEDURE_Report_ip_log_v1.1.sql | Report_ip_log | ~120–126 | device_type/risk_level/severity/month con `'` |
| ALTO | PROCEDURE_Report_Countries_v1.sql | Report_Countries | ~149–157 | SearchClause activo + Product con `'` |
| ALTO | PROCEDURE_Report_Accounts_v1.6_multibrand.sql | Report_Accounts | ~165–172 | Area/Brand/Product con `'`; Account escapa `"` solo |
| ALTO | PROCEDURE_Report_Campaign_v1.1c_op.sql | Report_Campaign | ~105–107 | Product/Country/Status_id con `'` |
| ALTO | PROCEDURE_Dash_Gestor_TotalByAdvertiser_v4.7.7_man_adj_op.sql | Dash_Gestor_TotalByAdvertiser | ~229–285 | Brand/Owner/Area con `'`; `@Order` sin whitelist ASC/DESC |
| ALTO | PROCEDURE_Aff_MarketingSources_v2_op.sql | Aff_MarketingSources | ~157–162 | Area/Brand/Product con `'` |
| ALTO | PROCEDURE_Edit_FinMov_ManAdj_v1.5.8.sql | Edit_FinMov_ManAdj | ~191–197 | Status/Operation con `'''`; Affiliate_id sin cast |
| ALTO | PROCEDURE_InvoiceToPubliser_v1.x_op.sql | InvoiceToPubliser | ~141–145 | Owner/Area/Brand/ids con `'` |
| ALTO | PROCEDURE_FM_edit_info_fact1_v1.1.sql | FM_edit_info_fact1 | ~154–162 | Brand/Tracker/Date + IDs en SQL dinámico |
| ALTO | PROCEDURE_PseudoBOT_Indirect_account_v1.sql | PseudoBOT_Indirect_account | ~78–125 | Second-order: valores de tablas → DELETE/INSERT |
| ALTO | PROCEDURE_Aff_Postback_Outbound_v1.2_sub.SQL | Aff_Postback_Outbound | ~95–146 | affiliate_id concatenado sin cast |
| MEDIO | PROCEDURE_Affiliate_Monthly_Sources_v1.6.6_mov.sql | Affiliate_Monthly_Sources | ~149–155 | Product/Tracker con `"` tras strip `"`; IDs sin cast |
| MEDIO | PROCEDURE_Report_MultiQuery_v1.3.2.sql | Report_MultiQuery | ~104 | Account_id concatenado sin validación numérica |
| MEDIO | PROCEDURE_DbD_fact_data_to_history_v1.1.sql | DbD_fact_data_to_history | ~51–165 | Año en nombre de tabla (parcialmente validado) |
| MEDIO | PROCEDURE_Postback_for_Affiliate_v1.SQL | Postback_for_Affiliate | ~80–233 | GROUP_CONCAT(account_id) en IN() (second-order) |
| MEDIO | Varios Report_* (Channels, Comm_*, Tags, Referral, Publisher Status, …) | — | — | Mismo anti-patrón `'` + strip `"` en docenas de filtros UI |
| BAJO | PROCEDURE_Optimize_tables_v1.sql | Optimize_tables | ~125–147 | Dinámico sobre metadata; backticks escapados |
| BAJO | PROCEDURE_util_alter_table_customizable.sql | util_alter_table… | ~83–92 | Sin params de usuario; backticks escapados |
| INFORMATIVO | Todo el corpus | — | — | **0** usos de `EXECUTE … USING` |
| INFORMATIVO | PROCEDURE_Sync_MS_DbD_DbD_lm_v3.2.sql / Cashflow / Payment_methods v2.2 | — | — | Referencias positivas: `QUOTE()`, user-var, SQL estático |
| INFORMATIVO | PROCEDURE_Dash_BrandMatrix_v2.3.3_graph.sql | Dash_BrandMatrix | ~273 | `@DataTable` por View (whitelist); Owner sí inyectable con `'` |

---

# Detalle de cada vulnerabilidad

## V1 — CRÍTICO — Identificador de base de datos en DDL/DML

### Archivo
`PROCEDURE_CopyTablesToDEV_v1.1.sql`

### Procedimiento
`CopyTablesToDEV`

### Línea aproximada
69–149

### Código afectado
```sql
SET @truncateTableURL  = CONCAT('TRUNCATE ',DB_destination,'.campaign_mkt_source_url;');
SET @dropTableQuery    = CONCAT('DROP TABLE IF EXISTS ',DB_destination,'.', tableName, ';');
SET @copyTableQuery    = CONCAT('CREATE TABLE IF NOT EXISTS ',DB_destination,'.', tableName, ' LIKE euroaffiliati2.', tableName);
SET @insertDataQuery   = CONCAT('INSERT INTO ',DB_destination,'.', tableName, ' SELECT * FROM euroaffiliati2.', tableName);
```

### Problema
El parámetro `DB_destination` se concatena como identificador sin whitelist ni escape de backticks. Un valor malicioso puede apuntar a otro schema o alterar la estructura del SQL generado. Impacto: DROP/TRUNCATE/CREATE masivos bajo DEFINER privilegiado.

### Escenario de ataque
```sql
CALL CopyTablesToDEV('otra_db_produccion');
-- o intento de inyección de identificador si el caller no está restringido
```

### Nivel de riesgo
CRÍTICO

### Recomendación
Validar con lista blanca (`euroaffiliati_dev`, `affacc_dev`, `euroaffiliati_mkt`, …) o regex `^[A-Za-z0-9_]+$`, comprobar existencia en `INFORMATION_SCHEMA.SCHEMATA`, y citar con backticks escapados: `` ` `` → `` `` ``.

### Ejemplo seguro
```sql
IF DB_destination NOT IN ('euroaffiliati_dev','affacc_dev','euroaffiliati_mkt') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DB_destination no permitida';
END IF;
SET @truncateTableURL = CONCAT('TRUNCATE `', REPLACE(DB_destination,'`','``'), '`.`campaign_mkt_source_url`');
```

---

## V2 — CRÍTICO — Nombres de tabla como parámetros en INSERT dinámico

### Archivo
`PROCEDURE_util_copy_table_only_same_fields_v1.sql`

### Procedimiento
(copia de campos comunes origen→destino)

### Línea aproximada
44–97

### Código afectado
```sql
CONCAT('INSERT INTO ', target_table, ' (', … ,
       ' SELECT … FROM ', source_table)
PREPARE stmt FROM @sql_stmt;
EXECUTE stmt;
```

### Problema
`source_table` / `target_table` son identificadores controlados por el caller, sin validación. Permite escribir en tablas arbitrarias del schema actual (o con cualificación cruzada si se admite `.`).

### Escenario de ataque
Pasar `target_table = account_account` o un nombre cualificado inesperado y sobrescribir datos críticos.

### Nivel de riesgo
CRÍTICO

### Recomendación
Whitelist de tablas, o validar que ambos nombres existen en `INFORMATION_SCHEMA.TABLES` del schema esperado y solo contienen `[A-Za-z0-9_]`. Escapar backticks.

### Ejemplo seguro
```sql
IF source_table NOT REGEXP '^[A-Za-z0-9_]+$' OR target_table NOT REGEXP '^[A-Za-z0-9_]+$' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de tabla inválido';
END IF;
```

---

## V2b — CRÍTICO — CreateGamblingTablesFromAtoB: schemas en backticks sin escape

### Archivo
`PROCEDURE_CREATE_gambling_tables_from_DB1_to_DB2.sql`

### Procedimiento
`CreateGamblingTablesFromAtoB`

### Línea aproximada
80–84

### Código afectado
```sql
CONCAT('CREATE TABLE IF NOT EXISTS `', p_db_destino, '`.`', tableName,
       '` LIKE `', p_db_origen, '`.`', tableName, '`')
```

### Problema
Identificadores de usuario dentro de backticks **sin** `REPLACE(name,'`','``')`. Un `` ` `` en el nombre rompe el identificador y permite inyección de DDL.

### Escenario de ataque
`p_db_destino` con backtick embebido apuntando a CREATE/DROP colateral bajo DEFINER.

### Nivel de riesgo
CRÍTICO

### Recomendación
Whitelist de schemas + escape de backticks; validar `tableName` del cursor.

---

## V2c — CRÍTICO — Sync_MS_Fact1_Fact2_lm: CALL dinámico + DELETE

### Archivo
`PROCEDURE_Sync_MS_Fact1_Fact2_lm_v1.3.sql`

### Procedimiento
`Sync_MS_Fact1_Fact2_lm`

### Línea aproximada
91–152

### Código afectado
```sql
Concat("CALL Sync_Fact2_from_Fact1('month=LM,MS_id=",@MS_id,",mode=",@Action,...")")
-- + DELETE local con MS_id=',@MS_id
```

### Problema
Cadena de inyección: `@MS_id` / `@Action` rompen el string del CALL hacia otro SP de escritura y el DELETE local.

### Escenario de ataque
`ms_id=1 OR 1=1` o manipulación de `mode`/`MS_id` que altera el CALL embebido.

### Nivel de riesgo
CRÍTICO

### Recomendación
No construir CALL por CONCAT; invocar el SP hijo con variables locales validadas; `MS_id` solo dígitos.

---

## V2d — CRÍTICO — Sync_MS_DbD_DbD_lm_byBrand: Brand en DELETE

### Archivo
`PROCEDURE_Sync_MS_DbD_DbD_lm_byBrand_v1.sql`

### Procedimiento
`Sync_MS_DbD_DbD_lm_byBrand`

### Línea aproximada
85–205

### Código afectado
```sql
CONCAT(" AND Brand='",@Brand,"' ")  -- alimenta DELETE en modo RUN
```

### Problema
Breakout con `'` en filtro que borra `Snapshot_day_by_day` del last month.

### Escenario de ataque
`Brand=x' OR '1'='1,mode=RUN` → DELETE de todo el LM.

### Nivel de riesgo
CRÍTICO

### Recomendación
`QUOTE(@Brand)` o user-var; exigir `mode=RUN` solo tras validar Brand contra catálogo.

---

## V3 — CRÍTICO — Search en LIKE con comilla simple

### Archivo
`PROCEDURE_Report_Publisher_ManAdj_v1_op.sql`

### Procedimiento
`Report_Publisher_ManAdj`

### Línea aproximada
121

### Código afectado
```sql
SET @WhereSearch = CONCAT(
  " AND (M.Description LIKE '%",@Search,"%' OR M.Remarks LIKE '%",@Search,"%')"
);
```

### Problema
`@Search` proviene de `InputCommLine`. Solo se eliminan `"` (y espacios). El literal generado usa `'…'`, por lo que una comilla simple rompe el LIKE y permite boolean-based SQLi. Además, `%` / `_` no se escapan (abuso de comodines).

### Escenario de ataque
```sql
CALL Report_Publisher_ManAdj('Search=x%''OR''1''=''1,debug=ye');
```
(el parser corta en `,`; el payload sin comas sigue siendo explotable)

### Nivel de riesgo
CRÍTICO

### Recomendación
Usar `QUOTE(@Search)` o mejor `EXECUTE … USING`; escapar `%`/`_` para LIKE (`REPLACE(REPLACE(v,'%','\%'),'_','\_')`).

### Ejemplo seguro
```sql
SET @WhereSearch = CONCAT(
  ' AND (M.Description LIKE CONCAT(''%'', REPLACE(REPLACE(', QUOTE(@Search),
  ', ''%'', ''\\%''), ''_'', ''\\_''), ''%'') OR M.Remarks LIKE CONCAT(''%'', REPLACE(REPLACE(',
  QUOTE(@Search), ', ''%'', ''\\%''), ''_'', ''\\_''), ''%''))'
);
-- Preferible: SQL estático + EXECUTE stmt USING v_SearchPattern;
```

---

## V4 — CRÍTICO — LoginInit en LIKE

### Archivo
`PROCEDURE_Report_Affiliates_v1.6.2_tag.sql`

### Procedimiento
`Report_Affiliates`

### Línea aproximada
128

### Código afectado
```sql
IF @LoginInit >"" THEN
  SET @WhereLogin = CONCAT(" AND A.`username` LIKE '",@LoginInit,"%'");
END IF;
```

### Problema
Prefijo de usuario controlado por el cliente, embebido en literal `'…'` sin escape. Bypass del filtro y posible exfiltración vía condiciones inyectadas.

### Escenario de ataque
```sql
CALL Report_Affiliates('LoginInit=a''OR''1''=''1''OR''username''LIKE'',meta=yes');
```

### Nivel de riesgo
CRÍTICO

### Recomendación
`QUOTE()` + concatenación de `%` fuera del valor, o placeholder; validar charset (`^[A-Za-z0-9_.@-]+$`).

### Ejemplo seguro
```sql
SET @WhereLogin = CONCAT(' AND A.`username` LIKE CONCAT(', QUOTE(@LoginInit), ', ''%'')');
```

---

## V5 — CRÍTICO — Sync Fact2: schema + WHERE dinámicos de escritura

### Archivo
`PROCEDURE_Sync_Fact2_from_Fact1_v1.6.x.sql`

### Procedimiento
`Sync_Fact2_from_Fact1` (nombre efectivo en CREATE)

### Línea aproximada
176–230

### Código afectado
```sql
SET v_Where_Clause=CONCAT('LEFT(DATE,7)="',v_Month,'" ');
…
SET v_Where_Clause=CONCAT(v_Where_Clause,' AND Affiliate_id="',v_Affiliate_id,'"');
SET v_SQLdelete=CONCAT('TRUNCATE ',v_DB,'.Snapshot_day_by_day_fact2;');
-- / DELETE FROM ',v_DB,'.Snapshot_day_by_day_fact2 WHERE ',v_Where_Clause
SET v_SQLinsert=CONCAT('INSERT IGNORE INTO ',v_DB,'.Snapshot_day_by_day_fact2 (…) … FROM ',v_DB,'.Snapshot_day_by_day_fact1 WHERE ',v_Where_Clause,…);
```

### Problema
Aunque `v_DB` se valida contra `SCHEMATA`, se concatena sin backticks. `Month`/`Affiliate_id`/`MS_id` entran en WHERE de DELETE/INSERT. Con `Mode=RUN` el impacto es destrucción/reescritura de fact2.

### Escenario de ataque
Caller autenticado (o comprometido) con `Mode=RUN` y filtros manipulados para ampliar el DELETE o apuntar a schema validado no deseado.

### Nivel de riesgo
CRÍTICO (escritura masiva)

### Recomendación
Whitelist de DB; `CAST`/`REGEXP` para IDs y mes `YYYY-MM`; WHERE estático con variables de sesión + `EXECUTE USING`, o `QUOTE()`.

### Ejemplo seguro
```sql
IF v_Month NOT REGEXP '^[0-9]{4}-[0-9]{2}$' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Month inválido'; END IF;
SET @p_month = v_Month;
SET v_SQLdelete = 'DELETE FROM `euroaffiliati2`.`Snapshot_day_by_day_fact2` WHERE LEFT(`Date`,7)=?';
PREPARE s FROM v_SQLdelete; -- usar variable de sesión: WHERE LEFT(Date,7)=@p_month
```

---

## V6 — CRÍTICO — Export a facturas con DML dinámico

### Archivo
`PROCEDURE_Publisher_balance_to_Proforma_v1.6_op.sql`

### Procedimiento
`Publisher_balance_to_Proforma`

### Línea aproximada
425–451

### Código afectado
Rama `IF v_Export="YES"` con `PREPARE` sobre `@v_SQL_DELETE` / `@v_SQL_UPDATE` / `@v_SQL_EXPORT` construidos con filtros (`Month`, Owner, Publisher) concatenados.

### Problema
Misma familia de inyección que los reportes, pero con **efectos de escritura** (DELETE/UPDATE/INSERT en invoices/proforma).

### Escenario de ataque
`Export=YES` + `Month` o filtros string manipulados para ampliar el alcance del DELETE/UPSERT.

### Nivel de riesgo
CRÍTICO

### Recomendación
Validar mes; IDs con `CAST AS UNSIGNED`; literales con `QUOTE()`; preferir SQL estático.

### Ejemplo seguro
```sql
SET v_EXP_WhereInvoiced_Month = CONCAT(' AND Invoiced_Month=', QUOTE(v_Month));
```

---

## V7 — CRÍTICO — MS_autogen: Month con comilla simple en INSERT

### Archivo
`PROCEDURE_MS_autogen_from_DbD_v1.sql`

### Procedimiento
`MS_autogen_from_DbD`

### Línea aproximada
120–138

### Código afectado
```sql
WHERE LEFT(D.`Date`, 7) = ''', @Month, '''
…
PREPARE stmt1 FROM @SQL;
EXECUTE stmt1;
```

### Problema
`@Month` se embebe con delimitador `'`. Breakout clásico permite ampliar el WHERE del INSERT hacia `campaign_marketing_source` (u objeto destino del SP).

### Escenario de ataque
```sql
CALL MS_autogen_from_DbD('month=2025-01'' OR ''1''=''1');
```

### Nivel de riesgo
CRÍTICO

### Recomendación
Validar `YYYY-MM`; usar `@Month` como variable de sesión referenciada en el texto SQL **sin** concatenar el valor, o `QUOTE(@Month)`.

### Ejemplo seguro
```sql
-- En el SQL preparado (texto fijo):
-- WHERE LEFT(D.`Date`, 7) = @Month
SET @Month = v_Month;  -- ya validado
PREPARE stmt1 FROM @SQL;
EXECUTE stmt1;  -- @Month se resuelve en ejecución
```

---

## V8 — CRÍTICO — dbd_to_fact1: DELETE/INSERT con Month/Account

### Archivo
`PROCEDURE_dbd_to_fact1_v1.1.sql`

### Procedimiento
(dbd → fact1)

### Línea aproximada
146–180, ~360

### Código afectado
Fragmentos del tipo:
```sql
AND (LEFT(DATE,7)="',@Month,'" OR ',@ProcessALL,')
Username_id =',@Account_id
```
con `PREPARE` sobre DELETE/INSERT.

### Problema
Parámetros de proceso concatenados en DML. `ProcessALL=1=1` (modo ALLALL) ya amplía alcance; inyección adicional puede extenderlo más.

### Escenario de ataque
`account_id=1 OR 1=1` o manipulación de `month` según delimitador usado en el SQL generado.

### Nivel de riesgo
CRÍTICO

### Recomendación
Validación estricta de mes; `Account_id` solo dígitos / `CAST`; evitar `1=1` genérico sin controles adicionales.

---

## V9 — CRÍTICO — Compare_Tables_Between_DBs

### Archivo
`PROCEDURE_Compare_Tables_Between_DBs_v1.sql`

### Procedimiento
`Compare_Tables_Between_DBs`

### Línea aproximada
184–256

### Código afectado
```sql
SET @sql = CONCAT(
  'SELECT COUNT(*) INTO @missing_columns FROM INFORMATION_SCHEMA.COLUMNS c1 ',
  'WHERE c1.TABLE_SCHEMA = "', p_source_db, '" AND c1.TABLE_NAME = "', v_table_name, '" ',
  …
);
PREPARE stmt FROM @sql; EXECUTE stmt;
```
También genera sentencias `ALTER TABLE {p_target_db}.{tabla} ADD COLUMN…`.

### Problema
Tres parámetros de entrada (`pattern`, `source_db`, `target_db`) concatenados en SQL dinámico ejecutado. Aunque el ALTER se almacena para reporte (no siempre se ejecuta), el SELECT dinámico sí se ejecuta y puede alterarse el control de flujo / lectura de metadata.

### Escenario de ataque
Caller con acceso al SP pasa schemas/patrones manipulados para forzar lecturas o generar ALTER peligrosos que luego se aplican manualmente.

### Nivel de riesgo
CRÍTICO (en contexto de herramienta admin DEFINER)

### Recomendación
Validar nombres de schema/tabla con regex + existencia; no concatenar; usar consultas estáticas a `INFORMATION_SCHEMA` con variables locales en WHERE (sin PREPARE).

---

## V10 — CRÍTICO — Compare_Fact1_Fact2 (rama sync)

### Archivo
`PROCEDURE_Compare_Fact1_Fact2_v2.sql`

### Procedimiento
`Compare_Fact1_Fact2`

### Línea aproximada
157–162, 351–382

### Código afectado
Filtros `Brand`/`Area` con `'…'` y DELETE/INSERT de sincronización con `Month` concatenado.

### Problema
Combinación de lectura inyectable + escritura dinámicamente construida.

### Escenario de ataque
Activar modo sync con `Month`/`Brand` manipulados para borrar/reinsertar fuera del alcance previsto.

### Nivel de riesgo
CRÍTICO (si el modo sync está expuesto a usuarios no-DBA)

---

## V11 — ALTO — Marketing Sources: filtros string con `'`

### Archivo
`PROCEDURE_Report_MarketingSources1_v2.4g_MAF_op.sql`

### Procedimiento
Reporte MS v2.4g

### Línea aproximada
304–316

### Código afectado
```sql
SET @WhereArea    = CONCAT(" AND CU.Area='",@Area,"'");
SET @WhereAdv_Account = CONCAT(" AND IFNULL(CU.Username,'')='",@Account,"'");
SET @WhereChannel = CONCAT(" AND CH.landing_page_name='",@Channel,"'");
SET @WhereProduct = CONCAT(" AND M.`Product`='",@Product,"'");
SET @WhereStatus  = CONCAT(" AND M.`Status_id`='",@STATUS,"'");
```

### Problema
Filtros de UI concatenados con comilla simple; strip de `"` insuficiente.

### Escenario de ataque
`Product=x'OR'1'='1` → bypass de filtros / exposición de marketing sources ajenos (según permisos de la app).

### Nivel de riesgo
ALTO

### Recomendación
`QUOTE(@Product)` etc., o SQL estático; IDs con cast numérico.

### Ejemplo seguro
```sql
SET @WhereProduct = CONCAT(' AND M.`Product`=', QUOTE(@Product));
```

---

## V12 — ALTO — Deal Marketplace: Product/Country/Status

### Archivo
`PROCEDURE_Report_Deal_MktPlace_v1.3_MAF_op.sql`

### Procedimiento
`Report_Deal_MktPlace`

### Línea aproximada
162–171

### Código afectado
Literales `='…'` para Product/Country/Status; Search con patrón `"%XXX%"` (mejor mitigado por strip de `"`).

### Problema
Breakout con `'` en filtros activos.

### Escenario de ataque
`Status=1'OR'1'='1`

### Nivel de riesgo
ALTO

### Recomendación
Igual que V11; whitelist para Status si el dominio es cerrado.

---

## V13 — ALTO — players_general: escape inconsistente

### Archivo
`PROCEDURE_Report_players_general_v3.5.1.sql`

### Procedimiento
`Report_players_general`

### Línea aproximada
205–208

### Código afectado
```sql
SET v_WhereCustomer_ID  = CONCAT(" AND Customer_Reference_ID='",v_Customer_ID,"'");
SET v_WhereAdvertiser   = CONCAT(" AND Advertiser='",REPLACE(v_Advertiser,"'","''"),"'"); -- OK parcial
SET v_WhereAccount      = CONCAT(" AND p.`Username_id`='",v_Account,"'");
SET v_WhereTracker_name = CONCAT(" AND p.`Marketing_Source_Name`='",v_Tracker_name,"'");
```

### Problema
Solo `Advertiser` escapa `'`. El resto es inyectable. Demuestra conocimiento de la mitigación sin aplicarla de forma uniforme.

### Escenario de ataque
`Customer_ID=x'OR'1'='1` / `Tracker_name=…`

### Nivel de riesgo
ALTO

### Recomendación
Aplicar `QUOTE()` a **todos** los literales string; parametrizar.

### Ejemplo seguro
```sql
SET v_WhereCustomer_ID = CONCAT(' AND Customer_Reference_ID=', QUOTE(v_Customer_ID));
SET v_WhereTracker_name = CONCAT(' AND p.`Marketing_Source_Name`=', QUOTE(v_Tracker_name));
```

---

## V14 — ALTO — Report_Documents

### Archivo
`PROCEDURE_Report_Documents.v2.6.3.sub.sql`

### Procedimiento
`Report_Documents` (sub)

### Línea aproximada
189–200

### Código afectado
```sql
SET v_whereop_type     = CONCAT(" AND b.Op_Type='",v_op_type,"'");
SET v_whereactiontaken = CONCAT(" AND ActionTaken='",v_actiontaken,"'");
SET v_wheremonth       = CONCAT(" AND LEFT(b.Creation_Date,7)='",v_month,"'");
SET v_whereaffiliate_id= CONCAT(" AND b.Account_id  =",v_affiliate_id);
```

### Problema
Strings con `'`; ID numérico sin validación (`1 OR 1=1`).

### Escenario de ataque
`ActionTaken=Accepted'OR'1'='1` o `Affiliate_id=1 OR 1=1` en modo GESTOR.

### Nivel de riesgo
ALTO

### Recomendación
Whitelist Op_Type/ActionTaken; mes `YYYY-MM`; `Affiliate_id` solo dígitos.

---

## V15 — ALTO — Report_Ads / Report_ip_log / Report_Countries

### Archivos
- `PROCEDURE_Report_Ads_v1.1.sql` (~146)
- `PROCEDURE_Report_ip_log_v1.1.sql` (~120–126)
- `PROCEDURE_Report_Countries_v1.sql` (~149–157)

### Problema
Misma familia: literales `'…'` desde `InputCommLine` sin `QUOTE()`. En Countries, `SearchClause` con `REPLACE(…XXX…, @Search)` está **activo**.

### Escenario de ataque
Análogo a V11–V14 según parámetro expuesto en UI.

### Nivel de riesgo
ALTO

### Recomendación
Plantilla común de construcción de filtros (ver recomendaciones generales).

---

## V16 — ALTO — Edit_FinMov_ManAdj

### Archivo
`PROCEDURE_Edit_FinMov_ManAdj_v1.5.8.sql`

### Procedimiento
`Edit_FinMov_ManAdj`

### Línea aproximada
191–197

### Código afectado
```sql
SET v_WhereStatus    = CONCAT(' AND M.`Status`       =''',v_Status,'''');
SET v_WhereOperation = CONCAT(' AND M.`Op_type`      =''',v_Operation,'''');
SET v_WhereAffiliate_id = CONCAT(' AND M.Affiliate_id   =',v_Affiliate_id);
```

### Problema
Usa `QUOTE()` en meta, pero **no** en filtros de datos. Breakout con `'` y affiliate sin cast. Alimenta pantalla de edición financiera.

### Escenario de ataque
`Status=0'OR'1'='1` → listado completo de movimientos/ajustes.

### Nivel de riesgo
ALTO

### Recomendación
Reutilizar `QUOTE(v_Status)`; validar Operation contra lista; cast de Affiliate_id.

### Ejemplo seguro
```sql
SET v_WhereStatus = CONCAT(' AND M.`Status`=', QUOTE(v_Status));
SET v_WhereAffiliate_id = CONCAT(' AND M.Affiliate_id=', CAST(v_Affiliate_id AS UNSIGNED));
```

---

## V17 — ALTO — InvoiceToPubliser / FM_edit_info_fact1

### Archivos
- `PROCEDURE_InvoiceToPubliser_v1.x_op.sql` (~141–145)
- `PROCEDURE_FM_edit_info_fact1_v1.1.sql` (~154–162)

### Problema
Filtros Brand/Owner/Area/Tracker concatenados; FM_edit encadena hacia edición de DbD.

### Nivel de riesgo
ALTO

### Recomendación
`QUOTE` + cast; reducir SQL dinámico en la cadena de edición.

---

## V18 — ALTO — Second-order / Postback

### Archivos
- `PROCEDURE_PseudoBOT_Indirect_account_v1.sql` (~78–125)
- `PROCEDURE_Aff_Postback_Outbound_v1.2_sub.SQL` (~95–146)
- `PROCEDURE_Postback_for_Affiliate_v1.SQL` (~80–233) — MEDIO/ALTO según tipado real de `account_id`

### Problema
Valores leídos de tablas (affiliate indirecto, db_indirect, listas GROUP_CONCAT) se concatenan a DELETE/INSERT/SELECT. Si un campo de configuración se envenena, hay SQLi de segundo orden.

### Escenario de ataque
Comprometer/actualizar un registro de configuración con `Affiliate_indirect = x" OR 1=1 OR Brand="y` y disparar el PseudoBOT.

### Nivel de riesgo
ALTO (PseudoBOT / Aff_Postback); MEDIO–ALTO (Postback GROUP_CONCAT si tipado INT)

### Recomendación
Tratar datos de tablas como no confiables: `QUOTE()`, cast, whitelist de `db_indirect`.

---

## V19 — MEDIO — Affiliate_Monthly_Sources / MultiQuery / DbD history

### Archivos
- `PROCEDURE_Affiliate_Monthly_Sources_v1.6.6_mov.sql`
- `PROCEDURE_Report_MultiQuery_v1.3.2.sql`
- `PROCEDURE_DbD_fact_data_to_history_v1.1.sql`

### Problema
- Monthly_Sources: literales con `"` tras strip `"` → breakout clásico mitigado; IDs sin cast → riesgo residual.
- MultiQuery: `@Account_id` concatenado sin validar dígitos.
- DbD history: año en nombre de tabla con validación parcial 2020–2040 (reduce pero no elimina riesgo de diseño).

### Nivel de riesgo
MEDIO

### Recomendación
Cast numérico; whitelist de tablas históricas; preferir SQL estático.

---

## V20 — BAJO / INFORMATIVO

| Ítem | Detalle |
|------|---------|
| Optimize_tables / util_alter_table_customizable | SQL dinámico necesario; fuente = information_schema; backticks escapados → **BAJO** |
| Corpus completo | **0** `EXECUTE … USING` → deuda estructural **INFORMATIVO** |
| Sync_MS_DbD_DbD_lm_v3.2 | Usa `QUOTE(v_brand)` → patrón a replicar |

---

# Recomendaciones generales

## Patrones inseguros más repetidos

1. **`CONCAT` + literal `'…'` + valor de `InputCommLine`** sin `QUOTE()` / sin placeholder.
2. **`REPLACE(..., '"', '')` como única “sanitización”** — no cubre `'`, numéricos ni identificadores.
3. **IDs concatenados sin comillas** (`Affiliate_id=`, `MS_id=`, `Owner=`) sin `REGEXP '^[0-9]+$'` ni `CAST`.
4. **Identificadores (DB/tabla) desde parámetros** en utilidades admin.
5. **SQL dinámico de escritura** (DELETE/TRUNCATE/INSERT/UPDATE) con los mismos filtros que los reportes.
6. **Second-order SQLi** desde tablas de configuración / `GROUP_CONCAT`.
7. **Ausencia total de `EXECUTE … USING`**.

## Acciones prioritarias

| Prioridad | Acción |
|-----------|--------|
| P0 | Restringir/auditar callers de `CopyTablesToDEV`, `CreateGamblingTablesFromAtoB`, `util_copy_table_*`, sync Fact2 / `Sync_MS_Fact1_Fact2_lm` / `Sync_MS…byBrand`, `dbd_to_fact1`, `MS_autogen`, Export de Proforma, Compare_* con DML |
| P0 | Corregir Search/LoginInit (Publisher_ManAdj, Affiliates) — exposición típica de UI |
| P1 | Introducir helper de filtros con `QUOTE()` + validación mes/ID; migrar MS / Deal / players / Documents / Ads / ip_log / Accounts / Campaign / Dash_Gestor / Aff_MS |
| P1 | Whitelist `Order IN ('ASC','DESC')` en Dash_Gestor y similares |
| P1 | En SP de escritura: validar mes `YYYY-MM`, IDs enteros, whitelist de schemas |
| P2 | Reducir SQL dinámico donde solo cambian literales WHERE; preferir SQL estático + variables locales |
| P2 | Donde el dinámico sea inevitable: user-var (`WHERE col=@p_x`) o `EXECUTE USING` |
| P3 | Revisar DEFINER: least privilege; no exponer SP admin a roles de afiliado/gestor |
| P3 | Tests negativos (`Debug=Yes` + payloads con `'`) en `TEST_PROCEDURE_*.sql` |

## Plantilla de remediación recomendada (MySQL 8.0/8.4)

```sql
-- 1) Validar
IF v_Month NOT REGEXP '^[0-9]{4}-[0-9]{2}$' THEN
  SELECT 'ERROR: Month inválido' AS Mensaje; LEAVE proc_label;
END IF;
IF v_Affiliate_id != 'ALL' AND v_Affiliate_id NOT REGEXP '^[0-9]+$' THEN
  SELECT 'ERROR: Affiliate_id inválido' AS Mensaje; LEAVE proc_label;
END IF;

-- 2) Literales: QUOTE() (produce '...' con escape correcto)
SET v_WhereProduct = CONCAT(' AND Product=', QUOTE(v_Product));

-- 3) Identificadores: whitelist + backticks
SET v_SQL = CONCAT('DELETE FROM `', REPLACE(v_DB,'`','``'), '`.`Snapshot_day_by_day_fact2` WHERE LEFT(`Date`,7)=', QUOTE(v_Month));

-- 4) Mejor aún: valor como user-var, no concatenado
SET @p_month = v_Month;
SET @SQL = 'DELETE FROM Snapshot_day_by_day_fact2 WHERE LEFT(`Date`,7)=@p_month';
PREPARE s FROM @SQL; EXECUTE s; DEALLOCATE PREPARE s;
```

## Nota de explotación en este proyecto

La explotabilidad real depende de:
- qué SP expone el frontend a cada rol;
- si el caller ya está autenticado como gestor/admin;
- delimitador real del SQL generado (`'` vs `"`) tras el strip de `"`.

**Cualquier concatenación de input en SQL dinámico se considera sospechosa** hasta demostrar validación adecuada. Los hallazgos marcados CRÍTICO asumen caller capaz de invocar el SP (directamente o vía API). Si un SP solo lo ejecuta un DBA en consola, el riesgo residual baja a operativo, pero el defecto de código permanece.

---

*Informe generado según `Auditor de vulnerabilidades SQL Injection.prompt` · 28.07.2026*  
*Actualizado con hallazgos complementarios de los barridos Report/Dash/Aff y escritura/Sync/Util.*
