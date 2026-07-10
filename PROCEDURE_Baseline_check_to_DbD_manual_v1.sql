/*
PROCEDURE_Baseline_check_to_DbD_manual_v1.sql

Descripción:
  Procedimiento PROCEDURE_Baseline_check_to_DbD_manual_v1.
      Cálculo y generación de movimientos en DbD_manual para compensar CPA que no llegan al baseline del afiliado

  Cada Key debe estar seguida de = y el valor deseado SIN comillas.
  Cada par Key=Value debe ir seguido de una COMA.
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string.

Keys:
  Month = [AAAA-MM | CM | LM]. Mes a procesar. OPCIONAL. Default=CM (mes actual).
  Debug = [No | Yes ]. Modo depuración. OPCIONAL. Default=No.
          Yes       → muestra parámetros de entrada y SQL generado SIN ejecutar el REPLACE.

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  call Baseline_check_to_DbD_manual('');
  call Baseline_check_to_DbD_manual('Month=CM');
  call Baseline_check_to_DbD_manual('Month=LM,Debug=Yes');
  call Baseline_check_to_DbD_manual('Month=2024-05');
  call Baseline_check_to_DbD_manual('Debug=Yes');
  call Baseline_check_to_DbD_manual('Month=2025-01,Debug=Yes');

24.06.2026 v1    Primera versión operativa
 
*/

-- DROP PROCEDURE IF EXISTS Baseline_check_to_DbD_manual_dev;
DROP PROCEDURE IF EXISTS Baseline_check_to_DbD_manual;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Baseline_check_to_DbD_manual`(IN InputCommLine VARCHAR(250))
COMMENT 'v1 24.06.2026 - Cálculo y generación de movimientos DbD_manual para compensar CPA que no llegan al baseline del afiliado'
SQL SECURITY DEFINER

proc_label:BEGIN

  DECLARE v_Version        VARCHAR(32)  DEFAULT 'v1 24.06.2026';
  DECLARE v_Month          VARCHAR(7)   DEFAULT '';
  DECLARE v_Debug          VARCHAR(20)  DEFAULT 'NO';
  DECLARE v_SQL            TEXT         DEFAULT '';
  DECLARE v_InputCommLine  VARCHAR(252) DEFAULT '';
  DECLARE v_e              INT          DEFAULT 0;
  DECLARE v_c              INT          DEFAULT 0;
  DECLARE v_k              VARCHAR(100) DEFAULT '';
  DECLARE v_v              VARCHAR(100) DEFAULT '';
  DECLARE v_SQLdelete      TEXT         DEFAULT '';
  DECLARE v_SQLinsert      TEXT         DEFAULT '';
  DECLARE v_SQL_CTE        TEXT         DEFAULT '';
  DECLARE v_EnforceBaseline VARCHAR(50)  DEFAULT 'NO';
  -- ── Defaults ─────────────────────────────────────────────────────────────────
  SET v_Month = LEFT(CURDATE(), 7);

  -- ── Parseo InputCommLine ──────────────────────────────────────────────────────
  SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
  SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

  WHILE v_InputCommLine > ' ' DO
    SET v_e = INSTR(v_InputCommLine, '=');
    SET v_c = INSTR(v_InputCommLine, ',');
    SET v_k = UPPER(TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1)));
    SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
    SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

    IF LOWER(v_k) = 'month' THEN
      IF UPPER(v_v) IN ('', 'CM') THEN
        SET v_Month = LEFT(CURDATE(), 7);
      ELSEIF UPPER(v_v) = 'LM' THEN
        SET v_Month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7);
      ELSEIF LEFT(v_v, 3) = '202'
         AND MID(v_v, 6, 2) IN ('01','02','03','04','05','06','07','08','09','10','11','12') THEN
        SET v_Month = v_v;
      END IF;
    ELSEIF LOWER(v_k) = 'debug' THEN
      SET v_Debug = UPPER(v_v);
    END IF;
  END WHILE;

-- Determina si se ha activado control de Baseline
SET v_EnforceBaseline=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='EnforceBaseline'); 
IF  v_EnforceBaseline='NO' THEN LEAVE proc_label; END IF;

-- ── Mes como variable de sesión para que el PREPARE lo resuelva ───────────────
SET @v_Month = v_Month;

-- ── SQL dinámico ──────────────────────────────────────────────────────────────
SET v_SQLdelete = 'DELETE FROM `Snapshot_day_by_day_manual` WHERE Origin="autoBLcheck" AND LEFT(Date,7) = @v_Month;';

SET v_SQLinsert = '
INSERT INTO `Snapshot_day_by_day_manual` (
      `Origin`,`MS_id`,`Username`,`Area`,`Brand`,`Affiliate`
    ,`Date`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`
    ,`Product`,`Product_Real`
    ,`Qualified_Players`
    ,`deal_to_apply`,`is_active`
)
';
/*
CREATE TABLE `players_general_API_idx` (
   `API` VARCHAR(20) NULL DEFAULT 'netrefer' COLLATE 'utf8mb4_0900_ai_ci',
   `Date` VARCHAR(7) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Advertiser_id` INT NOT NULL DEFAULT '0',
   `Advertiser` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Username_id` INT NULL DEFAULT NULL,
   `Username` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Customer_Reference_ID` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Signup_Date` VARCHAR(7) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Marketing_Source_Name` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Affiliate_id` INT NOT NULL DEFAULT '0',
   `Affiliate` VARCHAR(100) NOT NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   `CPA_Processed_Date` VARCHAR(7) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Deposits` DECIMAL(10,2) NULL DEFAULT NULL,
   `MS_id` INT NULL DEFAULT NULL,
);
*/
SET v_SQL_CTE = '
WITH Players_info AS (
  SELECT i.Date,i.API
      ,i.Advertiser as Brand
      ,i.Username_id
      ,i.Customer_Reference_ID
      ,i.CPA_Processed_Date
      ,i.Affiliate
      ,i.MS_id
      ,m.Deal_id
      ,i.Deposits
      ,d.Baseline
      ,CASE WHEN i.`Deposits`<d.Baseline THEN "BL" ELSE "" END AS `Warn_Flag`
      ,m.Tracker_ID
      ,m.Tracker_Name
      ,m.Code_To_Affiliate
      ,m.Product
      ,m.Product AS Product_Real
  FROM `players_general_API_idx` i
  INNER JOIN campaign_marketing_source m ON m.id=i.MS_id
  INNER JOIN campaign_deal_affiliate d ON d.id=m.Deal_id
  WHERE CPA_Processed_Date IS NOT NULL AND CPA_Processed_Date=@v_Month
)
-- SELECT * FROM Players_info WHERE Warn_Flag="BL";
SELECT
      "autoBLcheck" AS Origin
      ,MS_id, Username_id, null as Area, Brand, Affiliate
      ,concat(@v_Month,"-01") AS Date, Tracker_ID, Tracker_Name, Code_To_Affiliate
      ,Product, Product_Real
      ,-1 AS `Qualified_Players`
      ,1  AS `deal_to_apply`
      ,1  AS `is_active`
FROM Players_info
WHERE Warn_Flag="BL"
; 
';

SET v_SQL = CONCAT(v_SQLinsert, v_SQL_CTE);
-- ── Ejecución o Debug ─────────────────────────────────────────────────────────
IF v_Debug != 'NO' THEN
  -- Muestra parámetros y SQL generado sin ejecutar el REPLACE
  SELECT
    InputCommLine ,
    v_Month,
    v_Debug,
    v_SQLdelete,
    v_SQLinsert,
    v_SQL_CTE,
    v_SQL;
ELSE
  SET @v_stmt_sql = v_SQLdelete;
  PREPARE stmt1 FROM @v_stmt_sql;
  EXECUTE stmt1;
  DEALLOCATE PREPARE stmt1;
  
  SET @v_stmt_sql = v_SQL;
  PREPARE stmt1 FROM @v_stmt_sql;
  EXECUTE stmt1;
  DEALLOCATE PREPARE stmt1;     

END IF;

END$$
DELIMITER ;

/*
call Baseline_check_to_DbD_manual_dev('');
call Baseline_check_to_DbD_manual_dev('Month=CM');
call Baseline_check_to_DbD_manual_dev('Month=LM');
call Baseline_check_to_DbD_manual_dev('Month=2024-05');
call Baseline_check_to_DbD_manual_dev('Debug=Yes');
call Baseline_check_to_DbD_manual_dev('Month=2025-01,Debug=Yes');
*/
