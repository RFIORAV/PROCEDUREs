# Resumen

Auditoría estática de SQL Injection sobre stored procedures MySQL 8.x del proyecto **euroaffiliati** (`PROCEDUREs/`).

| Métrica | Valor |
|--------|------:|
| Archivos analizados (`PROCEDURE_*.sql` en raíz) | **177** |
| Procedimientos con `PREPARE ... FROM` | **115** |
| Uso de `EXECUTE ... USING` (bind) | **0** |
| Vulnerabilidades críticas (priorizadas) | **8** |
| Vulnerabilidades altas (priorizadas) | **14** |
| Vulnerabilidades medias (priorizadas) | **8** |
| Vulnerabilidades bajas / informativas | **3** |

### Observaciones

1. **Patrón dominante:** `InputCommLine` → parseo → `CONCAT` en `WHERE`/`DELETE`/identificadores → `PREPARE`/`EXECUTE` **sin** bind y a menudo **sin** escape coherente.
2. Mitigación parcial habitual: `REPLACE(InputCommLine,'"','')`. Protege literales `"..."` del SQL generado; **no** cubre literales `'...'`, IDs numéricos sin tipar ni nombres de DB/tabla.
3. El parser parte por la primera `=` y por `,`: espacios y `'` en el valor **sí** llegan al SQL. Por eso `Owner=x' OR '1'='1` es el vector más repetido en reportes.
4. Utilidades admin (`CopyTables*`, `util_copy*`, `CreateGambling*`, `Compare_Tables*`) elevan el impacto a integridad (TRUNCATE/DROP/CREATE cross-DB), sobre todo con `SQL SECURITY DEFINER`.
5. Existen referencias buenas (`Optimize_tables` con backticks, `Sync_MS_DbD` con `QUOTE()`, `Report_Payment_methods_v2.2` estático + CAST, `Dash_Mob_*` con REGEXP/`REPLACE` de `"`), pero **no** son el estándar del repo.

---

# Tabla resumen

| Riesgo | Archivo | Procedimiento | Línea | Descripción |
| ------ | ------- | ------------- | ----- | ----------- |
| CRÍTICO | PROCEDURE_CopyTablesToDEV_v1.1.sql | CopyTablesToDEV | ~69–163 | DB destino concatenada → TRUNCATE/DROP/INSERT |
| CRÍTICO | PROCEDURE_util_copy_table_only_same_fields_v1.sql | util_copy_table_only_same_fields | ~56–97 | Tablas origen/destino sin validación |
| CRÍTICO | PROCEDURE_CREATE_gambling_tables_from_DB1_to_DB2.sql | CreateGamblingTablesFromAtoB | ~80–84 | DB origen/destino en backticks sin escape |
| CRÍTICO | PROCEDURE_Sync_Fact2_from_Fact1_v1.6.x.sql | Sync_Fact2_from_Fact1 | ~189–204 | `MS_id=` + DELETE/INSERT dinámico |
| CRÍTICO | PROCEDURE_Dash_BrandMatrix_v2.3.5_graph.sql | Dash_BrandMatrix | ~307 | `Affiliate_id=` sin tipar → bypass |
| CRÍTICO | PROCEDURE_Compare_Tables_Between_DBs_v1.sql | Compare_Tables_Between_DBs | ~184–238 | DB en literales `"` del PREPARE |
| CRÍTICO | PROCEDURE_Report_Affiliates_v1.6.2_tag.sql | Report_Affiliates | ~128 | `LoginInit` en LIKE con `'` |
| CRÍTICO | PROCEDURE_Report_Ads_v1.1.sql | Report_Ads | ~146–149 | Product/Account/Brand con `'` |
| ALTO | PROCEDURE_Dash_BrandMatrix_v2.3.5_graph.sql | Dash_BrandMatrix | ~170 | `Owner='...'` sin escape |
| ALTO | PROCEDURE_Report_Accounts_v1.6.1_multibrand.sql | Report_Accounts | ~152–158 | Area/Brand/Product con `'`; Account sí escapado |
| ALTO | PROCEDURE_Report_Documents.v2.6.3.sub.sql | Report_Documents | ~199–200 | ActionTaken/Month con `'` |
| ALTO | PROCEDURE_Report_Snapshots_Dashboards_v1.4.1.sql | Report_Snapshots_Dashboards | ~138–140 | Owner/Month/Time con `'` |
| ALTO | PROCEDURE_Report_ip_log_v1.1.sql | Report_ip_log | ~120–126 | strings `'` + IDs numéricos abiertos |
| ALTO | PROCEDURE_Report_MarketingSources1_v2.4g_MAF_op.sql | Report_MarketingSources1 | ~304–316 | Filtros string con `'` |
| ALTO | PROCEDURE_Report_players_general_v3.5.sql | Report_players_general | ~202–205 | Customer/Account/Tracker con `'` |
| ALTO | PROCEDURE_Report_day_by_day_v1.3.8_manual.sql | Report_day_by_day | ~199–202 | MS_id / Affiliate_id / Advertiser_id sin tipar |
| ALTO | PROCEDURE_Dash_Gestor_TotalByAdvertiser_v4.7.7_man_adj_op.sql | Dash_Gestor_TotalByAdvertiser | ~281–285 | `@Order` sin whitelist ASC/DESC |
| ALTO | PROCEDURE_Dash_Gestor_TotalByAdvertiser_v4.8_test.sql | Dash_Gestor_TotalByAdvertiser | ~348 | Igual: Order sin whitelist |
| ALTO | PROCEDURE_Report_Deal_MktPlace_v1.3_MAF_op.sql | Report_Deal_MktPlace | ~167–169 | Product/Country/Status con `'` |
| ALTO | PROCEDURE_Report_Channels_v1.5.2_MAF.sql | Report_Channels | ~129–141 | Product (+ second_level) con `'` |
| ALTO | PROCEDURE_Report_Economics_Affiliate_v1.2_currency_op.sql | Report_Economics_Affiliate | ~198–199 | Status `'` + Affiliate_id abierto |
| ALTO | PROCEDURE_Report_MultiQuery_v1.3.2.sql | Report_MultiQuery | ~104 | `account_id=` concatenado |
| MEDIO | PROCEDURE_Aff_MarketingSources_v2_op.sql | Aff_MarketingSources | ~157–162 | Area/Brand/Product con `'` |
| MEDIO | PROCEDURE_Report_Brands_v1.5.3_op.sql | Report_Brands | ~169 | Advertiser_Name con `'` |
| MEDIO | PROCEDURE_CPA_ByAFFILIATE_BrandMatrix_v3.4_sub.sql | CPA_ByAFFILIATE_BrandMatrix | ~173 | Order concatenado |
| MEDIO | PROCEDURE_MS_Switch_Affiliate_batch_v2.sql | MS_Switch_Affiliate_batch | ~105 | FIND_IN_SET con lista usuario |
| MEDIO | PROCEDURE_Report_Reversed_CPA_v1.1.sql | Report_Reversed_CPA | ~184–196 | FIND_IN_SET con listas `^` |
| MEDIO | PROCEDURE_Util_TableCompareFields_v2.4.sql | Util_TableCompareFields | ~130+ | ALTER generado (no ejecuta) |
| MEDIO | PROCEDURE_Util_TableHistoryCompare_v2.3.sql | Util_TableHistoryCompare | ~93+ | ALTER generado con TableName/DB |
| MEDIO | PROCEDURE_Dash_Mob_Aff_BrandByWeek_v2.6.1.sql | Dash_Mob_Aff_BrandByWeek | ~207–221 | Advertiser_id sin REGEXP (Affiliate sí) |
| BAJO | Varios Report/Dash | * | — | `Debug=Yes` expone SQL generado |
| INFO | PROCEDURE_Optimize_tables_v1.sql | Optimize_tables | — | Buen patrón: escape backticks |
| INFO | PROCEDURE_Report_Payment_methods_v2.2.sql | Report_payment_methods | — | Buen patrón: SQL estático + CAST |

> El patrón `CONCAT(" AND col='",@v,"'")` aparece en **decenas** de archivos adicionales no listados uno a uno; la tabla prioriza impacto y representatividad.

---

# Detalle de cada vulnerabilidad

## 1. CRÍTICO — CopyTablesToDEV: DB destino sin whitelist

### Archivo
`PROCEDURE_CopyTablesToDEV_v1.1.sql`

### Procedimiento
`CopyTablesToDEV`

### Línea aproximada
69–163

### Código afectado
```sql
IF DB_destination="" THEN SET DB_destination="euroaffiliati_dev"; END IF;
SET @truncateTableURL  = CONCAT('TRUNCATE ',DB_destination,'.campaign_mkt_source_url;');
...
SET @dropTableQuery  = CONCAT('DROP TABLE IF EXISTS ',DB_destination,'.', tableName, ';');
SET @insertDataQuery = CONCAT('INSERT INTO ',DB_destination,'.', tableName, ' SELECT * FROM euroaffiliati2.', tableName);
```

### Problema
`DB_destination` se concatena como identificador sin whitelist ni escape de backticks. Con privilegios del DEFINER permite vaciar/reescribir cualquier schema alcanzable.

### Escenario de ataque
```sql
CALL CopyTablesToDEV('mysql');
CALL CopyTablesToDEV('euroaffiliati2');  -- TRUNCATE/reescritura sobre prod si grants lo permiten
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Whitelist de destinos; validar contra `INFORMATION_SCHEMA.SCHEMATA`; encapsular con backticks escapados (`REPLACE(name,'`','``')`).

### Ejemplo seguro
```sql
IF DB_destination NOT IN ('euroaffiliati_dev','affacc_dev','euroaffiliati_mkt') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DB_destination no permitido';
END IF;
SET v_db = CONCAT('`', REPLACE(DB_destination, '`', '``'), '`');
SET @truncateTableURL = CONCAT('TRUNCATE ', v_db, '.`campaign_mkt_source_url`');
```

---

## 2. CRÍTICO — util_copy_table_only_same_fields: tablas arbitrarias

### Archivo
`PROCEDURE_util_copy_table_only_same_fields_v1.sql`

### Procedimiento
`util_copy_table_only_same_fields`

### Línea aproximada
56–97

### Código afectado
```sql
CONCAT('INSERT INTO ', target_table, ' (', ... ') SELECT ', ... ' FROM ', source_table, ';')
```

### Problema
`source_table` / `target_table` entran directo al SQL dinámico sin validar charset ni existencia previa al armar el statement (solo se usan en el JOIN a `INFORMATION_SCHEMA`, pero el nombre crudo se concatena).

### Escenario de ataque
```sql
CALL util_copy_table_only_same_fields('account_account','evil_target');
-- o identificadores con caracteres especiales si el caller controla los args
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Exigir `REGEXP '^[A-Za-z0-9_]+$'`; comprobar existencia en `INFORMATION_SCHEMA.TABLES` del `DATABASE()` actual; backticks escapados.

### Ejemplo seguro
```sql
IF source_table NOT REGEXP '^[A-Za-z0-9_]+$' OR target_table NOT REGEXP '^[A-Za-z0-9_]+$' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Nombre de tabla inválido';
END IF;
SET v_src = CONCAT('`', REPLACE(source_table,'`','``'), '`');
SET v_tgt = CONCAT('`', REPLACE(target_table,'`','``'), '`');
```

---

## 3. CRÍTICO — CreateGamblingTablesFromAtoB: DB en backticks sin escape

### Archivo
`PROCEDURE_CREATE_gambling_tables_from_DB1_to_DB2.sql`

### Procedimiento
`CreateGamblingTablesFromAtoB`

### Línea aproximada
80–84

### Código afectado
```sql
SET @createTableQuery = CONCAT(
  'CREATE TABLE IF NOT EXISTS `', p_db_destino, '`.`', tableName,
  '` LIKE `', p_db_origen, '`.`', tableName, '`');
```

### Problema
Un backtick en `p_db_destino` / `p_db_origen` rompe el identificador. Además permite CREATE en schemas arbitrarios.

### Escenario de ataque
```sql
CALL CreateGamblingTablesFromAtoB('euroaffiliati2','evil`` .`t','gambling_%');
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Whitelist de schemas + `REPLACE(db,'`','``')` + validar patrón de tabla.

### Ejemplo seguro
```sql
SET v_db_dst = CONCAT('`', REPLACE(p_db_destino,'`','``'), '`');
SET v_db_src = CONCAT('`', REPLACE(p_db_origen,'`','``'), '`');
SET v_tbl    = CONCAT('`', REPLACE(tableName,'`','``'), '`');
SET @createTableQuery = CONCAT('CREATE TABLE IF NOT EXISTS ', v_db_dst, '.', v_tbl,
                               ' LIKE ', v_db_src, '.', v_tbl);
```

---

## 4. CRÍTICO — Sync_Fact2_from_Fact1: MS_id + DELETE dinámico

### Archivo
`PROCEDURE_Sync_Fact2_from_Fact1_v1.6.x.sql`

### Procedimiento
`Sync_Fact2_from_Fact1`

### Línea aproximada
183–204

### Código afectado
```sql
SET v_Where_Clause=CONCAT('LEFT(DATE,7)="',v_Month,'" ');
IF v_MS_id!='ALL' AND v_MS_id!='ALLALL'
THEN SET v_Where_Clause=CONCAT(v_Where_Clause,' AND MS_id=',v_MS_id);
END IF;
...
SET v_SQLdelete=CONCAT('DELETE FROM ',v_DB,'.Snapshot_day_by_day_fact2 WHERE ',v_Where_Clause,';');
```

### Problema
`MS_id` se concatena como expresión. Por precedencia `AND`/`OR`, un payload amplía el `DELETE`/`INSERT` a casi todo el mes. `v_DB` no es whitelist estricta.

### Escenario de ataque
```sql
CALL Sync_Fact2_from_Fact1('mode=RUN,month=2026-01,MS_id=1 OR 1=1,debug=no');
-- WHERE LEFT(DATE,7)="2026-01" AND MS_id=1 OR 1=1
```

### Nivel de riesgo
**CRÍTICO** (escritura masiva)

### Recomendación
Validar `REGEXP '^[0-9]+$'` / CAST UNSIGNED; tipar Month; whitelist DB; preferir SQL estático.

### Ejemplo seguro
```sql
IF v_MS_id NOT IN ('ALL','ALLALL') THEN
  IF v_MS_id NOT REGEXP '^[0-9]+$' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'MS_id inválido';
  END IF;
  SET v_Where_Clause = CONCAT(v_Where_Clause, ' AND MS_id=', CAST(v_MS_id AS UNSIGNED));
END IF;
```

---

## 5. CRÍTICO — Dash_BrandMatrix: Affiliate_id numérico abierto

### Archivo
`PROCEDURE_Dash_BrandMatrix_v2.3.5_graph.sql`

### Procedimiento
`Dash_BrandMatrix` (nombre CREATE del SP en el archivo)

### Línea aproximada
307–316

### Código afectado
```sql
SET @WhereAffiliate_id=CONCAT(' AND Affiliate_id=',@Affiliate_id);
...
SET @WhereAffiliate_id=CONCAT(' AND Affiliate_id IN ',@Affiliate_list);
```

### Problema
Bypass de aislamiento por afiliado (IDOR vía SQLi booleana). En VIEWMAF, `IN` + lista string empeora el vector.

### Escenario de ataque
```sql
CALL Dash_BrandMatrix('View=VIEWAFF,Affiliate_id=39 OR 1=1,MatrixBy=CPA,debug=yes');
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Solo `REGEXP '^[0-9]+$'` o whitelist `ALL|ALLdetail`; listas vía TEMP TABLE de enteros.

### Ejemplo seguro
```sql
IF @Affiliate_id NOT IN ('ALL','ALLdetail') THEN
  IF @Affiliate_id NOT REGEXP '^[0-9]+$' THEN LEAVE proc_label; END IF;
  SET @WhereAffiliate_id = CONCAT(' AND Affiliate_id=', CAST(@Affiliate_id AS UNSIGNED));
ELSE
  SET @WhereAffiliate_id = '';
END IF;
```

---

## 6. CRÍTICO — Compare_Tables_Between_DBs: DB en literales del PREPARE

### Archivo
`PROCEDURE_Compare_Tables_Between_DBs_v1.sql`

### Procedimiento
`Compare_Tables_Between_DBs`

### Línea aproximada
184–238

### Código afectado
```sql
SET @sql = CONCAT(
  'SELECT COUNT(*) INTO @source_columns FROM INFORMATION_SCHEMA.COLUMNS ',
  'WHERE TABLE_SCHEMA = "', p_source_db, '" AND TABLE_NAME = "', v_table_name, '"'
);
```

### Problema
`"` en el parámetro rompe el literal del SQL dinámico. Validar que el schema “existe” no sanitiza el valor usado en CONCAT.

### Escenario de ataque
```sql
CALL Compare_Tables_Between_DBs('x','euroaffiliati2" OR "1"="1','euroaffiliati_dev');
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
SQL estático con variables locales, o `REPLACE(p,'"','""')` / `QUOTE()`.

### Ejemplo seguro
```sql
-- Preferible: sin PREPARE
SELECT COUNT(*) INTO v_source_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = p_source_db AND TABLE_NAME = v_table_name;
```

---

## 7. CRÍTICO — Report_Affiliates: LoginInit en LIKE

### Archivo
`PROCEDURE_Report_Affiliates_v1.6.2_tag.sql`

### Procedimiento
`Report_Affiliates`

### Línea aproximada
128

### Código afectado
```sql
IF @LoginInit >"" THEN SET @WhereLogin = CONCAT(" AND A.`username` LIKE '",@LoginInit,"%'"); END IF;
```

### Problema
Valor de usuario dentro de literal `'...'` sin escape. El parser no elimina `'`.

### Escenario de ataque
```sql
CALL Report_Affiliates('LoginInit=a'' OR ''1''=''1,debug=no');
-- SQL: LIKE 'a' OR '1'='1%'
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Literales `"` + `REPLACE(val,'"','""')` (estándar del proyecto) o `QUOTE()`.

### Ejemplo seguro
```sql
SET @WhereLogin = CONCAT(' AND A.`username` LIKE "', REPLACE(@LoginInit,'"','""'), '%"');
```

---

## 8. CRÍTICO — Report_Ads: filtros string con comilla simple

### Archivo
`PROCEDURE_Report_Ads_v1.1.sql`

### Procedimiento
`Report_Ads`

### Línea aproximada
146–149

### Código afectado
```sql
CONCAT(" AND a.`Product`='",@Product,"'")
-- análogo Account / Brand
```

### Problema
Misma familia: ruptura de literal `'...'`.

### Escenario de ataque
```sql
CALL Report_Ads('Product=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**CRÍTICO**

### Recomendación
Unificar a literales `"` + `REPLACE(...,'"','""')`.

### Ejemplo seguro
```sql
SET @WhereProduct = CONCAT(' AND a.`Product`="', REPLACE(@Product,'"','""'), '"');
```

---

## 9. ALTO — Dash_BrandMatrix: Owner con `'`

### Archivo
`PROCEDURE_Dash_BrandMatrix_v2.3.5_graph.sql`

### Procedimiento
`Dash_BrandMatrix`

### Línea aproximada
169–170

### Código afectado
```sql
ELSE SET @WhereOwner=CONCAT(" AND Owner='",@Owner,"'"); END IF;
```

### Problema
Se eliminan `"` del input, no `'`. El SQL dinámico usa literales con `'`.

### Escenario de ataque
```sql
CALL Dash_BrandMatrix('Owner=x'' OR ''1''=''1,Affiliate_id=39,View=VIEWGES,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
`REPLACE` de `"` con literales `"` o `QUOTE(@Owner)`.

### Ejemplo seguro
```sql
SET @WhereOwner = CONCAT(' AND Owner="', REPLACE(@Owner,'"','""'), '"');
```

---

## 10. ALTO — Report_Accounts: endurecimiento inconsistente

### Archivo
`PROCEDURE_Report_Accounts_v1.6.1_multibrand.sql`

### Procedimiento
`Report_Accounts` (nombre CREATE del SP)

### Línea aproximada
152–168

### Código afectado
```sql
IF @Area  !="ALL" THEN SET @WhereArea  =CONCAT(" AND T.Area='",@Area,"'"); END IF;
IF @Brand !="ALL" THEN SET @WhereBrand =CONCAT(" AND AD.`Advertiser_name`='",@Brand,"'"); END IF;
...
IF @Account!="ALL" THEN SET @WhereAccount=CONCAT(" AND T.`Username`=\"",REPLACE(@Account,'"','""'),"\""); END IF;
```

### Problema
Solo `Account` está endurecido; Area/Brand/Product siguen con `'`. Owner e IDs numéricos también abiertos.

### Escenario de ataque
```sql
CALL Report_Accounts('Brand=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Aplicar el mismo patrón de `Account` a todos los strings; tipar IDs.

### Ejemplo seguro
```sql
SET @WhereBrand = CONCAT(' AND AD.`Advertiser_name`="', REPLACE(@Brand,'"','""'), '"');
IF @Advertiser_id NOT REGEXP '^[0-9]+$' AND @Advertiser_id!='ALL' THEN SET @Advertiser_id='ALL'; END IF;
```

---

## 11. ALTO — Report_Documents: ActionTaken / Month

### Archivo
`PROCEDURE_Report_Documents.v2.6.3.sub.sql`

### Procedimiento
`Report_Documents` (nombre CREATE del SP)

### Línea aproximada
199–200 (y Affiliate_id ~189–191 numérico)

### Código afectado
```sql
-- ActionTaken='..." / LEFT(...)= '",v_month,"'"
```

### Problema
Literales con `'`; Affiliate_id numérico sin CAST/REGEXP.

### Escenario de ataque
```sql
CALL Report_Documents('ActionTaken=x'' OR ''1''=''1,debug=yes');
CALL Report_Documents('Affiliate_id=1 OR 1=1,Mode=AFFILIATE,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Escape de strings + tipado de IDs.

### Ejemplo seguro
```sql
SET v_WhereAction = CONCAT(' AND ActionTaken="', REPLACE(v_actiontaken,'"','""'), '"');
IF v_affiliate_id NOT REGEXP '^[0-9]+$' THEN LEAVE proc_label; END IF;
```

---

## 12. ALTO — Report_Snapshots_Dashboards: Owner/Month/Time

### Archivo
`PROCEDURE_Report_Snapshots_Dashboards_v1.4.1.sql`

### Procedimiento
`Report_Snapshots_Dashboards`

### Línea aproximada
138–140

### Código afectado
Filtros `Owner='...'`, `Month='...'`, `Time IN ('...')` sin escape de `'`.

### Problema
`REPLACE(...,'!',' ')` solo normaliza espacios; no sanitiza `'`.

### Escenario de ataque
```sql
CALL Report_Snapshots_Dashboards('Owner=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Literales `"` + `REPLACE('"','""')`; Time con whitelist de valores conocidos.

### Ejemplo seguro
```sql
SET v_WhereOwner = CONCAT(' AND Owner="', REPLACE(v_Owner,'"','""'), '"');
```

---

## 13. ALTO — Report_ip_log: strings + numéricos

### Archivo
`PROCEDURE_Report_ip_log_v1.1.sql` (también `v1.sql`)

### Procedimiento
`Report_ip_log`

### Línea aproximada
~120–126

### Código afectado
```sql
-- device_type/risk_level/severity/Month con ='...",v,"'"
-- user_id / risk_score numéricos sin comillas
```

### Problema
Doble vector: ruptura de `'` e IDs abiertos.

### Escenario de ataque
```sql
CALL Report_ip_log('Device_type=x'' OR ''1''=''1,debug=yes');
CALL Report_ip_log('User_id=1 OR 1=1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Escape strings + REGEXP/CAST en enteros.

### Ejemplo seguro
```sql
SET v_WhereDevice = CONCAT(' AND T.`device_type`="', REPLACE(v_device_type,'"','""'), '"');
IF v_user_id NOT REGEXP '^[0-9]+$' THEN SET v_WhereUser = ''; 
ELSE SET v_WhereUser = CONCAT(' AND T.`user_id`=', CAST(v_user_id AS UNSIGNED)); END IF;
```

---

## 14. ALTO — Report_MarketingSources1: filtros string

### Archivo
`PROCEDURE_Report_MarketingSources1_v2.4g_MAF_op.sql`

### Procedimiento
`Report_MarketingSources1`

### Línea aproximada
304–316

### Código afectado
`CU.Area='...'`, `Username='...'`, `landing_page_name='...'`, `Product='...'` sin escape.

### Problema
Familia clásica de comilla simple. Además `@Search` se asigna a `@WhereSearch` sin construir `@SearchClause` en este archivo → riesgo residual de variable de sesión.

### Escenario de ataque
```sql
CALL Report_MarketingSources1('Account=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Escape uniforme; inicializar siempre `@WhereSearch=''` y no reutilizar `@` residuales.

### Ejemplo seguro
```sql
SET @WhereAccount = CONCAT(' AND CU.`Username`="', REPLACE(@Account,'"','""'), '"');
SET @WhereSearch = '';  -- nunca dejar residual de sesión
```

---

## 15. ALTO — Report_players_general: Customer/Account/Tracker

### Archivo
`PROCEDURE_Report_players_general_v3.5.sql` / `v3.5.1`

### Procedimiento
`Report_players_general`

### Línea aproximada
202–205

### Código afectado
`Customer_Reference_ID='...'`, `Username_id='...'`, `Marketing_Source_Name='...'`  
(`Advertiser` sí usa `REPLACE(...,'''','''''')` — parcial e inconsistente)

### Problema
Inconsistencia de escape entre columnas.

### Escenario de ataque
```sql
CALL Report_players_general('Customer_ID=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Mismo escape en todos los filtros string.

### Ejemplo seguro
```sql
SET v_WhereCust = CONCAT(' AND Customer_Reference_ID="', REPLACE(v_Customer,'"','""'), '"');
```

---

## 16. ALTO — Report_day_by_day: IDs numéricos abiertos

### Archivo
`PROCEDURE_Report_day_by_day_v1.3.8_manual.sql` (también v1.3.6)

### Procedimiento
`Report_day_by_day`

### Línea aproximada
199–202

### Código afectado
```sql
IF @MS_id        !='ALL' THEN SET @WhereMS_id        =CONCAT(' AND MS_id=',@MS_id); END IF;
IF @Affiliate_id !='ALL' THEN SET @WhereAffiliate_id =CONCAT(' AND `A`.`id`=',@Affiliate_id); END IF;
IF @Advertiser_id!='ALL' THEN SET @WhereAdvertiser_id=CONCAT(' AND `AD`.`id`=',@Advertiser_id); END IF;
```

### Problema
IDs concatenados como expresión. **Nota positiva:** el nombre de tabla vía `CASE`/`@DbD` es whitelist correcta (replicar).

### Escenario de ataque
```sql
CALL Report_day_by_day('MS_id=1 OR 1=1,Month=2026-01,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
REGEXP + CAST UNSIGNED por cada ID.

### Ejemplo seguro
```sql
IF @MS_id != 'ALL' THEN
  IF @MS_id NOT REGEXP '^[0-9]+$' THEN SET @MS_id='ALL';
  ELSE SET @WhereMS_id = CONCAT(' AND MS_id=', CAST(@MS_id AS UNSIGNED)); END IF;
END IF;
```

---

## 17. ALTO — Dash_Gestor_TotalByAdvertiser: Order sin whitelist

### Archivo
`PROCEDURE_Dash_Gestor_TotalByAdvertiser_v4.7.7_man_adj_op.sql`  
`PROCEDURE_Dash_Gestor_TotalByAdvertiser_v4.8_test.sql`

### Procedimiento
`Dash_Gestor_TotalByAdvertiser`

### Línea aproximada
281–285 (v4.7.7); ~348 (v4.8)

### Código afectado
```sql
IF @OrderBy="CPA" THEN SET @OrderByClause=CONCAT(@OrderByClause,',convert(...) ',@Order); END IF;
```

### Problema
`@OrderBy` tiene whitelist implícita (solo concatena si coincide). `@Order` se concatena tal cual tras `UPPER`.

### Escenario de ataque
```sql
CALL Dash_Gestor_TotalByAdvertiser('Month=2026-01,OrderBy=CPA,Order=ASC+(SELECT SLEEP(0)),debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
`IF @Order NOT IN ('ASC','DESC') THEN SET @Order='DESC'; END IF;`

### Ejemplo seguro
```sql
IF @Order NOT IN ('ASC','DESC') THEN SET @Order='DESC'; END IF;
IF @OrderBy='CPA' THEN
  SET @OrderByClause = CONCAT(@OrderByClause, ',convert(REPLACE(`CPA`,",",""),signed) ', @Order);
END IF;
```

---

## 18. ALTO — Report_Deal_MktPlace / Channels / Economics / MultiQuery

### Archivos
- `PROCEDURE_Report_Deal_MktPlace_v1.3_MAF_op.sql` (~167–169)
- `PROCEDURE_Report_Channels_v1.5.2_MAF.sql` (~129–141)
- `PROCEDURE_Report_Economics_Affiliate_v1.2_currency_op.sql` (~198–199)
- `PROCEDURE_Report_MultiQuery_v1.3.2.sql` (~104)

### Procedimiento
Respectivos `Report_*`

### Problema
Mismo patrón: strings con `'` y/o IDs sin tipar (`account_id=` en MultiQuery).

### Escenario de ataque
```sql
CALL Report_Deal_MktPlace('Country=x'' OR ''1''=''1,debug=yes');
CALL Report_MultiQuery('Account_id=1 OR 1=1,debug=yes');
```

### Nivel de riesgo
**ALTO**

### Recomendación
Plantilla única de filtros seguros (ver Recomendaciones generales).

### Ejemplo seguro
```sql
SET @WhereCountry = CONCAT(' AND Country="', REPLACE(@Country,'"','""'), '"');
SET @WhereAccount = CONCAT(' AND mqa.account_id=', CAST(@Account_id AS UNSIGNED));
```

---

## 19. MEDIO — Aff_MarketingSources / Report_Brands / CPA Order

### Archivos
`PROCEDURE_Aff_MarketingSources_v2_op.sql`, `PROCEDURE_Report_Brands_v1.5.3_op.sql`, `PROCEDURE_CPA_ByAFFILIATE_BrandMatrix_v3.4_sub.sql`

### Problema
Strings con `'` u `Order` concatenado; impacto típico de lectura / ordenación, no DDL.

### Escenario de ataque
```sql
CALL Aff_MarketingSources('Product=x'' OR ''1''=''1,debug=yes');
```

### Nivel de riesgo
**MEDIO**

### Recomendación
Mismos controles de escape / whitelist Order.

### Ejemplo seguro
Igual que §9 y §17.

---

## 20. MEDIO — FIND_IN_SET con listas de usuario

### Archivos
- `PROCEDURE_MS_Switch_Affiliate_batch_v2.sql` (~105)
- `PROCEDURE_Report_Reversed_CPA_v1.1.sql` (~184–196)

### Código afectado
```sql
FIND_IN_SET(..., REPLACE(v_Brand,'^',','))
```

### Problema
No es query-stacking clásico, pero valores no tipados permiten matching anómalo. En MS_Switch la lista origen no se valida como solo dígitos/comas.

### Escenario de ataque
Listas con tokens inesperados que alteran qué filas “coinciden” en operaciones batch / filtros.

### Nivel de riesgo
**MEDIO**

### Recomendación
Split `^` → insertar solo IDs `REGEXP '^[0-9]+$'` en TEMP TABLE; filtrar con `JOIN`.

### Ejemplo seguro
```sql
-- por cada token de REPLACE(lista,'^',','):
IF v_tok REGEXP '^[0-9]+$' THEN
  INSERT INTO tmp_ids(id) VALUES (CAST(v_tok AS UNSIGNED));
END IF;
-- WHERE id IN (SELECT id FROM tmp_ids)
```

---

## 21. MEDIO — Util_TableCompare* / HistoryCompare (ALTER generado)

### Archivos
`PROCEDURE_Util_TableCompareFields_v2.4.sql`, `PROCEDURE_Util_TableHistoryCompare_v2.3.sql`

### Problema
Generan `ALTER TABLE ...` con nombres de parámetro. **No ejecutan** el ALTER (riesgo secundario si un operador lo pega a ciegas).

### Nivel de riesgo
**MEDIO**

### Recomendación
Validar identificadores; marcar salida como “no ejecutable sin revisión”; no concatenar sin whitelist.

### Ejemplo seguro
Validar `TableName REGEXP '^[A-Za-z0-9_]+$'` antes de emitir DDL.

---

## 22. MEDIO — Dash_Mob: Advertiser_id residual

### Archivo
`PROCEDURE_Dash_Mob_Aff_BrandByWeek_v2.6.1.sql`

### Línea aproximada
207–221

### Problema
`Affiliate_id` tiene `REGEXP '^[0-9]+$'` (bien); `Advertiser_id` se concatena sin el mismo control. Brand usa `"` + `REPLACE` (bien).

### Escenario de ataque
```sql
CALL Dash_Mob_Aff_BrandByWeek('Advertiser_id=1 OR 1=1,Affiliate_id=39,debug=yes');
```

### Nivel de riesgo
**MEDIO**

### Recomendación
Aplicar el mismo REGEXP a Advertiser_id.

### Ejemplo seguro
```sql
IF v_Advertiser_id NOT IN ('ALL','') AND v_Advertiser_id NOT REGEXP '^[0-9]+$' THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Advertiser_id inválido';
END IF;
```

---

## 23. BAJO — Debug expone SQL

### Archivo
Decenas de Report/Dash (Ads, Accounts, BrandMatrix, day_by_day, MultiQuery, …)

### Problema
`Debug=Yes` / `!=NO` hace `SELECT @SQL` → fuga de esquema y facilita afinar payloads.

### Nivel de riesgo
**BAJO** (facilita ataque; no es inyección por sí solo)

### Recomendación
Restringir Debug a roles internos; no volcar SQL completo en producción.

### Ejemplo seguro
```sql
IF v_Debug = 'YES' AND v_AllowDebug = 'YES' THEN SELECT v_SQL; END IF;
```

---

## 24–25. INFORMACIÓN — Controles positivos (referencia)

| SP | Por qué es mejor |
|----|------------------|
| `Optimize_tables_v1` | Escape de backticks; params limitados |
| `Sync_MS_DbD_DbD_lm_v3.2` | `QUOTE()` en Brand/mes |
| `Report_Payment_methods_v2.2` | SQL estático; CAST UNSIGNED; Table_Type por IF |
| `Report_Reversed_CPA_v1.1` | WHERE estático + FIND_IN_SET (menor riesgo clásico) |
| `Dash_Mob_Aff_BrandByWeek_v2.6.1` | REGEXP Affiliate; Brand con `"`+REPLACE; whitelist Style/Metric |
| `Report_day_by_day` | Nombre de tabla vía CASE (whitelist) |
| `Set_record_dbd_manual` | Escritura estática sin PREPARE |

---

# Recomendaciones generales

### Patrones inseguros más repetidos

1. `CONCAT(" AND col='", @v, "'")` — literales con `'` mientras el parser solo quita `"`.
2. `CONCAT(' AND id=', @id)` — IDs sin `REGEXP`/`CAST`.
3. Identificadores DB/tabla concatenados en utilidades admin.
4. `@Order` concatenado sin whitelist `ASC|DESC`.
5. Variables de sesión `@*` residuales y `Debug` que expone SQL.
6. **Cero** usos de `EXECUTE ... USING`.

### Acciones prioritarias

| Prioridad | Acción |
|----------|--------|
| P0 | Blindar syncs/escrituras: tipar `MS_id`/IDs; whitelist DB en `Sync_Fact2`, `CopyTablesToDEV`, util_copy, CreateGambling |
| P0 | `Dash_BrandMatrix` / reportes con `Affiliate_id=` abierto |
| P1 | Migrar filtros string a literales `"` + `REPLACE(v,'"','""')` (estándar CLAUDE.md) en toda la familia Report/Dash |
| P1 | Whitelist `Order` ∈ {ASC,DESC} donde se concatene |
| P2 | Listas `^` → TEMP TABLE tipada; evitar `FIND_IN_SET` en escrituras |
| P2 | Introducir `EXECUTE stmt USING ?` donde el SQL sea fijo |
| P3 | Restringir GRANT EXECUTE de utilidades admin; limitar Debug en prod |

### Plantilla mínima de filtro seguro (MySQL 8)

```sql
-- String
SET v_WhereX = CONCAT(' AND col="', REPLACE(v_X, '"', '""'), '"');

-- Entero
IF v_Id NOT REGEXP '^[0-9]+$' THEN SET v_WhereId = '';
ELSE SET v_WhereId = CONCAT(' AND id=', CAST(v_Id AS UNSIGNED)); END IF;

-- Identificador
SET v_Ident = CONCAT('`', REPLACE(v_Name, '`', '``'), '`');

-- Orden
IF v_Order NOT IN ('ASC','DESC') THEN SET v_Order = 'DESC'; END IF;
```

### Límites de esta auditoría

- Revisión **estática**; no se explotó en vivo contra MySQL.
- Muestra priorizada; el patrón de comilla simple afecta a **muchos** reportes similares no enumerados exhaustivamente.
- El riesgo real depende de quién puede hacer `CALL` (`DEFINER`, grants de la app, red).

**Fecha del informe:** 13.08.2026  
**Alcance:** `PROCEDURE_*.sql` / `PROCEDURE_*.SQL` en la raíz de `PROCEDUREs/` (sin `OLD_DEV/`).
