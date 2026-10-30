/*
PROCEDURE_Cap_excess_to_DbD_manual_v2.sql

Descripción:
  Procedimiento Cap_excess_to_DbD_manual_dev.
      Cálculo y generación de movimientos en DbD_manual para compensar exceso de Cap.
      Excepciones en tabla campaign_mkt_source_cap_real.

  Cada Key debe estar seguida de = y el valor deseado SIN comillas.
  Cada par Key=Value debe ir seguido de una COMA.
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string.

Keys:
  Month = [AAAA-MM | CM | LM]. Mes a procesar. OPCIONAL. Default=CM (mes actual).
  Debug = [No | Yes | KeyValues]. Modo depuración. OPCIONAL. Default=No.
          Yes       → muestra parámetros de entrada y SQL generado SIN ejecutar el REPLACE.
          KeyValues → muestra valores de claves parseadas (ejecuta normalmente).

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  call Cap_excess_to_DbD_manual('');
  call Cap_excess_to_DbD_manual('Month=CM,Debug=Yes');
  call Cap_excess_to_DbD_manual('Month=LM,Debug=Yes');
  call Cap_excess_to_DbD_manual('Month=2024-05');
  call Cap_excess_to_DbD_manual('Debug=Yes');
  call Cap_excess_to_DbD_manual('Month=2025-01,Debug=Yes');

09.06.2024 v1    Primera versión operativa
15.11.2024 v1.1  Corrección por cambio de MS por otra con igual `Code_To_Affiliate`
29.05.2026 v2    Parámetros Key=Value, SQL dinámico con PREPARE/EXECUTE, soporte Debug=Yes
29.05.2026 v2    Añadido control de activación/desactivación de control de Cap
12.06.2026 v2.1  Añadido cambio de Status_id de Marketing Source a "6" (Paused) 
13.07.2026 v2.2  Cambio criterio de selección de movimientos para poner en Paused los MS Cuando CPA=>Cap
                 Solo pone PAUSED para proceso del mes actual
*/

DROP PROCEDURE IF EXISTS Cap_excess_to_DbD_manual_dev;
DROP PROCEDURE IF EXISTS Cap_excess_to_DbD_manual;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Cap_excess_to_DbD_manual`(IN InputCommLine VARCHAR(250))
COMMENT 'v2.2 13.07.2026 - Cálculo y generación de movimientos DbD_manual para compensar exceso de Cap'
SQL SECURITY DEFINER

proc_label:BEGIN

  DECLARE v_Version        VARCHAR(32)  DEFAULT 'v2.2 13.07.2026';
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
  DECLARE v_EnforceCapCPA  VARCHAR(20)  DEFAULT 'NO';
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

-- Determina si se ha activado control de Cap
SET v_EnforceCapCPA=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='EnforceCapCPA'); 
IF  v_EnforceCapCPA='NO' THEN LEAVE proc_label; END IF;

  -- ── Crear tabla si no existe (DDL estático) ───────────────────────────────────
  CREATE TABLE IF NOT EXISTS `campaign_mkt_source_cap_real` (
     `id`                 INT         NOT NULL AUTO_INCREMENT,
     `is_active`          INT         NULL DEFAULT '1',
     `Affiliate_id`       INT         NOT NULL,
     `Brand`              VARCHAR(50) NULL DEFAULT '',
     `Code_To_Affiliate`  VARCHAR(50) NULL DEFAULT '',
     `Cap_Real`           INT         NULL DEFAULT '9999',
     `Month_Valid_From`   VARCHAR(7)  NOT NULL,
     `Month_Valid_To`     VARCHAR(7)  NULL DEFAULT NULL,
     `Creation_Date`      DATETIME    NULL DEFAULT CURRENT_TIMESTAMP,
     `Last_Update`        DATETIME    NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
     `Operator`           VARCHAR(30) NULL DEFAULT 'SysOp',
     PRIMARY KEY (`id`) USING BTREE,
     INDEX `Affiliate_id` (`Affiliate_id`,`Month_Valid_From`) USING BTREE
  );
  CREATE TABLE IF NOT EXISTS `campaign_mkt_source_cap_date` (
    `id`              INT           NOT NULL AUTO_INCREMENT,
    `MS_id`           INT           NOT NULL DEFAULT '0',
    `Date_Valid`      DATE          NULL     DEFAULT NULL,
    `Affiliate_id`    INT           NULL     DEFAULT NULL,
    `CPA_Limit`       INT           NULL     DEFAULT NULL,
    `is_active`       TINYINT       NULL     DEFAULT '1',
    `Creation_Date`   DATETIME      NULL     DEFAULT (now()),
    `Last_Update`     DATETIME      NULL     DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
    `User`            VARCHAR(30)   NULL     DEFAULT NULL,
    PRIMARY KEY (`id`) USING BTREE,
    INDEX `MS_id`        (`MS_id`)        USING BTREE,
    INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE
  );
  -- ── Mes como variable de sesión para que el PREPARE lo resuelva ───────────────
  SET @v_Month = v_Month;

  -- ── SQL dinámico ──────────────────────────────────────────────────────────────
  SET v_SQLdelete = '
  DELETE FROM `Snapshot_day_by_day_manual` WHERE Origin="autoCapExcess" AND LEFT(Date,7) = @v_Month;'
  ;

  SET v_SQLinsert = '
  INSERT INTO `Snapshot_day_by_day_manual` (
       `Origin`,`MS_id`,`Username`,`Area`,`Brand`,`Affiliate`
      ,`Date`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`
      ,`Product`,`Product_Real`
      ,`Qualified_Players`
      ,`deal_to_apply`,`is_active`
  )
';

  SET v_SQL_CTE = '
  WITH fact_by_Date AS (
  SELECT F.Date, F.Brand, F.Username_id
        ,F.Affiliate, F.Affiliate_id, F.Area
        ,F.MS_id, F.Tracker_ID, F.Tracker_Name, F.Code_To_Affiliate      
        ,F.Product, F.Product_Real
        ,SUM(Qualified_players)         AS CPAacum
        ,IFNULL(C.Cap_Real,IFNULL(D.CPA_Limit,IFNULL(F.CPA_Limit,1000))) AS CPA_Limit_consolidated  
        ,D.CPA_Limit AS CPA_Limit_to_date
        ,D.Date_Valid            
  FROM `Snapshot_day_by_day_fact1` F
  INNER JOIN `campaign_marketing_source` M ON M.id = F.MS_id
  -- ver afiliados sin limite de cap
  LEFT JOIN `campaign_mkt_source_cap_real` C ON C.Affiliate_id = F.Affiliate_id  AND C.is_active = 1
    AND LEFT(Date,7) BETWEEN `Month_Valid_From` AND IFNULL(`Month_Valid_To`,"2050-12") 
  LEFT JOIN lateral (SELECT * FROM `campaign_mkt_source_cap_date` D 
                     WHERE D.is_active = 1 AND D.MS_id = F.MS_id AND D.Date_Valid <= F.Date
                     AND C.Affiliate_id IS NULL 
                     ORDER BY D.Date_Valid DESC ,D.id DESC LIMIT 1) AS D ON TRUE    
  WHERE LEFT(Date,7) = @v_Month AND Origin IN ("user","") AND F.Affiliate_id>1
  GROUP BY F.Date, F.Affiliate_id, F.MS_id, F.Code_To_Affiliate
  HAVING CPAacum>0
),

fact_acum_by_MS_date as (
SELECT   f.MS_id,f.Username_id, f.Area, f.Brand, f.Affiliate
        ,MAX(f.Date) as Date, f.Tracker_ID, f.Tracker_Name, f.Code_To_Affiliate
        ,f.Product, f.Product_Real
        ,SUM(CPAacum) AS CPAacum
        ,f.CPA_Limit_consolidated
        ,CPA_Limit_to_date
        ,Date_Valid AS Rule_Date_Valid                   
FROM fact_by_Date f
GROUP BY MS_id,CPA_Limit_consolidated
HAVING CPAacum>0 and CPAacum>=CPA_Limit_consolidated
)
-- SELECT * from fact_acum_by_MS_date;

SELECT
      "autoCapExcess" AS Origin
      ,f.MS_id, f.Username_id, f.Area, f.Brand, f.Affiliate
      ,MAX(f.Date), f.Tracker_ID, f.Tracker_Name, f.Code_To_Affiliate
      ,f.Product, f.Product_Real
      ,f.CPA_Limit_consolidated - SUM(f.CPAacum) AS `CPAdifference`
      ,1 AS `deal_to_apply`
      ,1 AS `is_active`
FROM fact_acum_by_MS_date f
GROUP BY MS_id,CPA_Limit_consolidated 
HAVING CPAdifference<=0
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

    UPDATE campaign_marketing_source m
    INNER JOIN `Snapshot_day_by_day_manual` d ON `MS_id`=m.id 
           AND d.Origin='autoCapExcess' AND d.is_active=1 AND LEFT(d.`Date`,7)=LEFT(CURDATE(),7)
    SET Status_id="6"
    WHERE m.Status_id="1" AND @v_Month = LEFT(CURDATE(), 7);   -- solo para el mes actual
 
  END IF;

END$$
DELIMITER ;

/*
call Cap_excess_to_DbD_manual_dev('');
call Cap_excess_to_DbD_manual_dev('Month=CM');
call Cap_excess_to_DbD_manual_dev('Month=LM');
call Cap_excess_to_DbD_manual_dev('Month=2024-05');
call Cap_excess_to_DbD_manual_dev('Debug=Yes');
call Cap_excess_to_DbD_manual_dev('Month=2025-01,Debug=Yes');
*/
