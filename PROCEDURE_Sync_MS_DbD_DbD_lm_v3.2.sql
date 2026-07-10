/* PROCEDURE_Sync_MS_DbD_DbD_lm.sql - Check Last Month Raw data: Stored data Vs New downloaded data (DbD vs DbD_lm)


Descripción:
  Procedimiento Sync_MS_DbD_DbD_lm_dev.
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value debe estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
p_InputCommLine = [valor]. Parámetro de entrada.

Mode     = [ VIEW | RUN | FACT1 | DEBUG ]. Default=VIEW.
             VIEW: Muestra diferencias sin modificar datos
             RUN: Reemplaza contenido de DbD por DbD_LM para el Last Month (completo o por Brand)
             FACT1: Ejecuta Snapshot_day_by_day_fact1_upd_from_dbd('LM') para recalcular Fact1
             DEBUG: Igual que VIEW pero muestra SQL generados y variables internas
Brand    = [ Advertiser_Name ]. Filtra por marca. OPCIONAL. Default='' (todas)
Filters  = [ YES | NO ]. Devuelve lista de filtros disponibles. OPCIONAL. Default=NO
Meta     = [ YES | NO ]. Fila de metadatos/settings para grid. OPCIONAL. Default=YES
Debug    = [ YES | NO ]. Muestra SQL y variables. OPCIONAL. Default=NO

Parámetros ('[Key=Value[,...]]')

Ejemplos:

call Sync_MS_DbD_DbD_lm('Mode=View');
call Sync_MS_DbD_DbD_lm_dev('Mode=View');
call Sync_MS_DbD_DbD_lm_dev('Mode=View,Brand=Betsson');
call Sync_MS_DbD_DbD_lm_dev('Mode=Debug');
call Sync_MS_DbD_DbD_lm_dev('Mode=Run');
call Sync_MS_DbD_DbD_lm_dev('Mode=Run,Brand=Betssona,debug=yes');
call Sync_MS_DbD_DbD_lm_dev('Mode=Run,Brand=Betssona,Filters=Yes,debug=ye');
call Sync_MS_DbD_DbD_lm_dev('Filters=Yes,debug=yes');

Modificaciones:
   21.09.2022 V1     Sincroniza una Marketing Source entre Snapshot_day_by_day y Snapshot_day_by_day_lm
   22.09.2022 V1.1   Sincroniza todo entre Snapshot_day_by_day y Snapshot_day_by_day_lm
   05.10.2022        Muestra diferencias también de NR, además de CPA
   19.10.2022 V1.2   Columna Meta
   02.11.2022 V1.4   Línea de totales
   08.11.2022        Se invierte el cálculo de las DIFFerencias
   06.01.2023 v1.5   Identifica afiliado de cada movimiento
   17.09.2023 v1.6   Fix order by Diff
   27.09.2023 v1.7   Fix DELETE from DbD (Utilizaba el campo Area)
   10.01.2024 v1.7.1 Quita Tracker_name de factor de comparación para determinar MS
   18.01.2024 v1.8   Renombra de columnas grid para hacerla más comprensible
   01.02.2024 v1.9   En view no hace comparación si LM no tiene datos
   17.03.2024 v2     Completa Brand en DbD/LM
   01.10.2024        Elimina control de si hay datos en DbD para mes anterior
   14.04.2025 v2.1   Excluye datos obtenidos de cuentas indirectas por procedure PseudoBOT_Indirect_account
   03.03.2026 v2.2   Refactorización procedimiento con variables locales
   12.03.2026 v3.0   Parámetros Key=Value, modo Filters, filtro por Brand, sync por Brand individual
                     Refactoring para sync por Brand individual
   13.03.2026 v3.1   Añade modo FACT1 para recalcular Fact1 LM
   12.05.2026 v3.2   Añade comprobación de si hay datos en DbD para evitar pantalla vacía

*/

-- DROP PROCEDURE IF EXISTS Sync_MS_DbD_DbD_lm_dev;
DROP PROCEDURE IF EXISTS Sync_MS_DbD_DbD_lm;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Sync_MS_DbD_DbD_lm`(
   IN p_InputCommLine VARCHAR(500)
)
   COMMENT 'v3.2 12.05.2026 Check/Sync LM Raw data: Stored data Vs New downloaded data (DbD vs DbD_lm)'
   LANGUAGE SQL
   SQL SECURITY DEFINER

proc_label: BEGIN

DECLARE v_version                VARCHAR(30);
DECLARE v_mode                   VARCHAR(20);
DECLARE v_brand                  VARCHAR(100);
DECLARE v_filters                VARCHAR(3);
DECLARE v_meta                   VARCHAR(3);
DECLARE v_debug                  VARCHAR(3);
DECLARE v_last_month             CHAR(7);
DECLARE v_indirect_accounts      LONGTEXT;
DECLARE v_where_not_in_acct      TEXT;
DECLARE v_where_not_in_acct_view TEXT;
DECLARE v_where_brand            TEXT;
DECLARE v_sql_delete             LONGTEXT;
DECLARE v_sql_insert             LONGTEXT;
DECLARE v_sqlview                LONGTEXT;
DECLARE v_sqlfilters             LONGTEXT;
DECLARE v_cte_dbd_agg            LONGTEXT;
DECLARE v_cte_lm_agg             LONGTEXT;
DECLARE v_cte_lm_minus_dbd       LONGTEXT;
DECLARE v_sqlmeta                LONGTEXT;
DECLARE v_sqldetail              LONGTEXT;
DECLARE v_sqltotal               LONGTEXT;
DECLARE v_step                   VARCHAR(64);
DECLARE v_e                      INT;
DECLARE v_c                      INT;
DECLARE v_k                      VARCHAR(100);
DECLARE v_v                      VARCHAR(250);
DECLARE v_input_comm_line        VARCHAR(500);
DECLARE v_sql_check_run          LONGTEXT;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   IF v_step LIKE 'RUN%' THEN ROLLBACK; END IF;
   RESIGNAL;
END;

-- Defaults -------------------------------------------------------------------
SET v_version                = 'v3.2 12.05.2026';
SET v_mode                   = 'VIEW';
SET v_brand                  = '';
SET v_filters                = 'NO';
SET v_meta                   = 'YES';
SET v_debug                  = 'NO';
SET v_where_not_in_acct      = '';
SET v_where_not_in_acct_view = '';
SET v_where_brand            = '';
SET v_step                   = 'INIT';

-- Parser Key=Value -----------------------------------------------------------
SET v_input_comm_line = IFNULL(p_InputCommLine, '');
SET v_input_comm_line = CONCAT(v_input_comm_line, ',');
SET v_input_comm_line = REPLACE(v_input_comm_line, '"', '');

parse_loop: WHILE v_input_comm_line > ' ' DO
   SET v_e = INSTR(v_input_comm_line, '=');
   SET v_c = INSTR(v_input_comm_line, ',');
   IF v_e = 0 OR v_c = 0 THEN LEAVE parse_loop; END IF;
   SET v_k = TRIM(SUBSTRING(v_input_comm_line, 1, v_e - 1));
   SET v_v = TRIM(SUBSTRING(v_input_comm_line, v_e + 1, v_c - (v_e + 1)));
   SET v_input_comm_line = SUBSTRING(v_input_comm_line, v_c + 1);

   IF LOWER(v_k) = 'mode'    THEN SET v_mode    = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'brand'   THEN SET v_brand   = v_v;        END IF;
   IF LOWER(v_k) = 'filters' THEN SET v_filters = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'meta'    THEN SET v_meta    = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'debug'   THEN SET v_debug   = UPPER(v_v); END IF;

END WHILE parse_loop;
-- ----------------------------------------------------------------------------

-- Mode=DEBUG equivale a VIEW con debug activado
IF v_mode = 'DEBUG' THEN
   SET v_mode  = 'VIEW';
   SET v_debug = 'YES';
END IF;

-- Inicialización -------------------------------------------------------------
SET v_last_month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7);

SET SESSION group_concat_max_len = 10000;

-- Exclusión de cuentas indirectas --------------------------------------------
SET v_indirect_accounts = (
   SELECT CONCAT('(', GROUP_CONCAT(u.id SEPARATOR ', '), ')')
   FROM campaign_username u
   WHERE u.is_indirect = '1' AND IFNULL(u.db_indirect, '') > ''
);

IF v_indirect_accounts IS NOT NULL
THEN SET v_where_not_in_acct      = CONCAT(' AND D.Username NOT IN ', v_indirect_accounts);
     SET v_where_not_in_acct_view = REPLACE(v_where_not_in_acct, 'NOT', '');
ELSE SET v_where_not_in_acct      = '';
     SET v_where_not_in_acct_view = '';
END IF;

-- Filtro por Brand -----------------------------------------------------------
IF v_brand != '' THEN
   SET v_where_brand = CONCAT(' AND AD.Advertiser_Name = ', QUOTE(v_brand));
END IF;

-- ============================================================================
-- CTEs reutilizables (Filters y View comparten la misma base)
-- ============================================================================
SET v_cte_dbd_agg = CONCAT('
DbD_agg AS (
   SELECT
      AD.Advertiser_Name AS Brand
      ,D.Username
      ,D.Tracker_ID
      ,D.Tracker_name AS Tracker_name
      ,D.Product
      ,SUM(IFNULL(D.Qualified_players, 0)) AS CPA_DbD
      ,SUM(IFNULL(D.Net_Revenue, 0))       AS NR_DbD
   FROM Snapshot_day_by_day D
   LEFT JOIN campaign_username U ON U.id = D.Username
   LEFT JOIN campaign_advertiser AD ON AD.id = U.Advertiser_id
   WHERE LEFT(Date, 7) = ', QUOTE(v_last_month), '
   ', v_where_not_in_acct, '
   ', v_where_brand, '
   GROUP BY Brand, D.Username, D.Tracker_ID, D.Tracker_name
)');

SET v_cte_lm_agg = CONCAT('
LM_agg AS (
   SELECT
      AD.Advertiser_Name AS Brand
      ,D.Username
      ,D.Tracker_ID
      ,D.Tracker_name AS Tracker_name
      ,D.Product
      ,SUM(IFNULL(D.Qualified_players, 0)) AS CPA_LM
      ,SUM(IFNULL(D.Net_Revenue, 0))       AS NR_LM
   FROM Snapshot_day_by_day_lm D
   LEFT JOIN campaign_username U ON U.id = D.Username
   LEFT JOIN campaign_advertiser AD ON AD.id = U.Advertiser_id
   WHERE LEFT(Date, 7) = ', QUOTE(v_last_month), '
   ', v_where_not_in_acct, '
   ', v_where_brand, '
   GROUP BY Brand, D.Username, D.Tracker_ID, D.Tracker_name
)');

SET v_cte_lm_minus_dbd = '
LM_minus_Dbd AS (
   SELECT
      "" AS Meta
      ,L.Brand
      ,L.Username AS "Username_id"
      ,U.Username
      ,L.Tracker_ID
      ,COALESCE(L.Tracker_name, D.Tracker_name) AS Tracker_name
      ,COALESCE(L.Product, D.Product) AS Product
      ,IFNULL(D.CPA_DbD, 0) AS CPA_DbD
      ,IFNULL(L.CPA_LM, 0)  AS CPA_LM
      ,IFNULL(L.CPA_LM, 0) - IFNULL(D.CPA_DbD, 0) AS DIFF
      ,IFNULL(D.NR_DbD, 0) AS NR_DbD
      ,IFNULL(L.NR_LM, 0)  AS NR_LM
   FROM LM_agg L
   LEFT JOIN DbD_agg D ON L.Brand <=> D.Brand
      AND L.Username = D.Username
      AND L.Tracker_ID <=> D.Tracker_ID
   LEFT JOIN campaign_username U ON U.id = L.Username
   WHERE IFNULL(L.CPA_LM, 0) - IFNULL(D.CPA_DbD, 0) <> 0
      OR IFNULL(D.NR_DbD, 0) <> IFNULL(L.NR_LM, 0)
)';

-- ============================================================================
-- Comprueba si hay diferencias para mostrar/procesar
-- ============================================================================

SET @v_Count_DbD_diff = 0;
SET v_sql_check_run = CONCAT(
   'SET @v_Count_DbD_diff = (
      WITH ', v_cte_dbd_agg,
   ',',     v_cte_lm_agg,
   ',',     v_cte_lm_minus_dbd, '
   SELECT COUNT(*) FROM LM_minus_Dbd
   );');

SET @stmt_sql = v_sql_check_run;
PREPARE stmt2 FROM @stmt_sql;
EXECUTE stmt2;
DEALLOCATE PREPARE stmt2;
SET @stmt_sql = NULL;

-- ============================================================================
-- Modo FILTERS: devuelve lista de filtros disponibles
-- ============================================================================
IF v_filters='YES' THEN

   SET v_sqlfilters = CONCAT(
      'WITH ', v_cte_dbd_agg,
      ',',     v_cte_lm_agg,
      ',',     v_cte_lm_minus_dbd, '

   (SELECT "01" AS `Korder`,"Brand" AS `Key`,Brand AS `Value`,"Brand" AS `CallKey`,Brand AS `CallValue`,COUNT(*) AS `Rows`
         ,"no" AS "TypeAction","" AS "MsgAction"  FROM LM_minus_Dbd GROUP BY Brand)
   UNION ALL (SELECT "98", "Transfer selected LM data to daily data (DbD)",  "CONFIRM UPDATE daily data" , "Mode", "RUN", "","yes" AS "TypeAction","" AS "MsgAction" 
   FROM DUAL WHERE @v_Count_DbD_diff > 0) 
   UNION ALL (SELECT "99", "Recalc Master with new data (takes a few seconds)","CONFIRM UPDATE LM Master data", "Mode", "FACT1", "","yes" AS "TypeAction","" AS "MsgAction" FROM DUAL)
   ORDER BY 1, 3
   ;');

   IF v_debug != 'NO' THEN
      SELECT v_version AS Version, v_mode AS Mode, v_brand AS Brand,
             v_last_month AS LastMonth, p_InputCommLine AS InputParams;
      SELECT v_sqlfilters AS SQL_Filters;
   END IF;

   SET @stmt_sql = v_sqlfilters;
   PREPARE stmt1 FROM @stmt_sql;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
   SET @stmt_sql = NULL;
   -- LEAVE proc_label;
END IF;

-- ============================================================================
-- SQL de ejecución (modo RUN): DELETE + INSERT
-- ============================================================================
IF v_brand != '' THEN
   -- DELETE filtrado por Brand (JOIN para resolver Advertiser_Name)
   SET v_sql_delete= CONCAT('
   DELETE D FROM Snapshot_day_by_day D
   INNER JOIN campaign_username U ON U.id = D.Username
   INNER JOIN campaign_advertiser AD ON AD.id = U.Advertiser_id
   WHERE AD.Advertiser_Name = ', QUOTE(v_brand), '
     AND LEFT(D.Date, 7) = ', QUOTE(v_last_month), '
   ', v_where_not_in_acct, '
   ;');

   -- INSERT filtrado por Brand
   SET v_sql_insert = CONCAT('
   INSERT IGNORE INTO Snapshot_day_by_day
   SELECT D.* FROM Snapshot_day_by_day_lm D
   INNER JOIN campaign_username U ON U.id = D.Username
   INNER JOIN campaign_advertiser AD ON AD.id = U.Advertiser_id
   WHERE AD.Advertiser_Name = ', QUOTE(v_brand), '
     AND LEFT(D.Date, 7) = ', QUOTE(v_last_month), '
   ', v_where_not_in_acct, '
   ;');
ELSE
   -- DELETE completo (comportamiento original v2.x)
   SET v_sql_delete= CONCAT('
   DELETE FROM Snapshot_day_by_day D
   WHERE LEFT(Date, 7) = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7)
   ', v_where_not_in_acct, '
   ;');

   -- INSERT completo
   SET v_sql_insert = CONCAT('
   INSERT IGNORE INTO Snapshot_day_by_day
   SELECT * FROM Snapshot_day_by_day_lm D
   WHERE LEFT(Date, 7) = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7)
   ', v_where_not_in_acct, '
   ;');
END IF;

-- ============================================================================
-- SQL de visualización (modo VIEW / DEBUG) — SELECTs
-- ============================================================================
SET v_sqlmeta = CONCAT('
   SELECT
   "setting" AS Meta
   ,"width=150px" AS `Brand`
   ,"width=80px"  AS `Acct id`
   ,"width=150px" AS `Account`
   ,"width=90px"  AS `MS id`
   ,"width=100px" AS `Tracker ID`
   ,"width=200px" AS `Tracker name`
   ,"width=100px" AS `Product`
   ,"width=150px" AS `Affiliate`
   ,"width=100px" AS `CPA our database`
   ,"width=100px" AS `CPA in Brand`
   ,"width=100px" AS `Difference`
   ,"width=100px" AS `NR our database`
   ,"width=100px" AS `NR in Brand`
   FROM DUAL WHERE ', QUOTE(v_meta), ' = "YES"

   UNION ALL
');

SET v_sqldetail = '
   SELECT
    D.Meta
   ,D.Brand
   ,D.Username_id AS `Acct id`
   ,D.Username
   ,M.id AS `MS_id`
   ,D.Tracker_ID
   ,D.Tracker_name
   ,D.Product
   ,IFNULL(A.username, "_Unassigned") AS `Affiliate`
   ,CPA_DbD
   ,CPA_LM
   ,DIFF
   ,NR_DbD
   ,NR_LM
   FROM LM_minus_Dbd D
   LEFT JOIN LATERAL (
      SELECT
         CASE WHEN M.Tracker_ID = D.Tracker_ID AND M.Tracker_Name = D.Tracker_Name THEN 4
              WHEN M.Tracker_ID = D.Tracker_ID THEN 3
              WHEN M.Tracker_Name = D.Tracker_Name THEN 2
              ELSE 1 END AS MatchValue
         ,M.* FROM campaign_marketing_source M
      WHERE M.Username_id = D.Username_id AND
         (D.Tracker_ID IN (M.Tracker_ID, M.Tracker_Name)
      )
      ORDER BY MatchValue DESC LIMIT 1
   ) AS M ON TRUE
   LEFT JOIN LATERAL (
      SELECT *, ROW_NUMBER() OVER(PARTITION BY MS_id ORDER BY Deal_Valid_From DESC) AS RowNr
      FROM campaign_mkt_source_deal WHERE MS_id = M.id AND is_active = 1
      ORDER BY RowNr LIMIT 1
   ) AS M2 ON TRUE
   LEFT JOIN account_account A ON A.id = M2.Affiliate_id
';

SET v_sqltotal = CONCAT('
   UNION ALL
   SELECT "",CONCAT(" Total Diff ", ', QUOTE(v_last_month), '),"~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~",SUM(CPA_DbD),SUM(CPA_LM),SUM(DIFF),SUM(NR_DbD),SUM(NR_LM)
   FROM LM_minus_Dbd

   ORDER BY
       CASE WHEN `Difference` = 0 THEN 0 ELSE 1 END DESC
      ,Brand, Account, `Difference` DESC;
');

-- Ensamblaje de v_sqlview
SET v_sqlview = CONCAT(
   'WITH ', v_cte_dbd_agg,
   ',',     v_cte_lm_agg,
   ',',     v_cte_lm_minus_dbd,
            v_sqlmeta,
            v_sqldetail,
            v_sqltotal
);

-- ============================================================================
-- Debug output
-- ============================================================================
IF v_debug != 'NO' THEN
   SELECT v_version AS Version, v_mode AS Mode, v_brand AS Brand,
          v_last_month AS LastMonth,
          v_where_not_in_acct AS ExclIndirect, v_where_brand AS BrandFilter,
          p_InputCommLine AS InputParams;
   SELECT v_sql_delete AS SQL_Delete;
   SELECT v_sql_insert AS SQL_Insert;
   SELECT v_sqlview AS SQL_View;
   SELECT v_sql_check_run,@v_Count_DbD_diff;
END IF;

-- ============================================================================
-- Ejecución condicional
-- ============================================================================

IF v_mode = 'RUN' THEN
   IF @v_Count_DbD_diff = 0 THEN
      SET v_mode = 'VIEW';
   END IF;
END IF;

IF v_filters='NO' THEN
   IF v_mode = 'RUN' THEN

      SET v_step = 'RUN_DELETE';
      START TRANSACTION;

      SET @stmt_sql = v_sql_delete;
      PREPARE stmt1 FROM @stmt_sql;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
      SET @stmt_sql = NULL;

      SET v_step = 'RUN_INSERT';

      SET @stmt_sql = v_sql_insert;
      PREPARE stmt2 FROM @stmt_sql;
      EXECUTE stmt2;
      DEALLOCATE PREPARE stmt2;
      SET @stmt_sql = NULL;

      COMMIT;
      SET v_step = 'RUN_DONE';

   ELSEIF v_mode = 'FACT1' THEN

      SET v_step = 'FACT1';
      CALL Snapshot_day_by_day_fact1_upd_from_dbd('LM');
      SET v_step = 'FACT1_DONE';

   END IF;

   SET v_step = 'VIEW';

   SET @stmt_sql = v_sqlview;
   PREPARE stmt3 FROM @stmt_sql;
   EXECUTE stmt3;
   DEALLOCATE PREPARE stmt3;
   SET @stmt_sql = NULL;

END IF;

END$$
DELIMITER ;

/*

call Sync_MS_DbD_DbD_lm('Mode=View');
call Sync_MS_DbD_DbD_lm('Mode=View,Brand=Betsson');
call Sync_MS_DbD_DbD_lm('Mode=Debug');
call Sync_MS_DbD_DbD_lm('Mode=Debug,Brand=Betsson');
call Sync_MS_DbD_DbD_lm('Mode=Run');
call Sync_MS_DbD_DbD_lm('Mode=Run,Brand=Betsson');
call Sync_MS_DbD_DbD_lm('Mode=Fact1');
call Sync_MS_DbD_DbD_lm('Filters=Yes');
call Sync_MS_DbD_DbD_lm('Filters=Yes,Debug=Yes');

*/
