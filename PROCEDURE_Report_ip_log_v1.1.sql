/*
PROCEDURE_Report_ip_log_v1.1.sql - Report IP Tracking User IP Log

Descripción:
  Procedimiento Report_ip_log.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Device_type    =[ALL | device_type]. OPCIONAL. Default=ALL
Risk_level     =[ALL | risk_level]. OPCIONAL. Default=ALL
Risk_score     =[ALL | risk_score]. OPCIONAL. Default=ALL
Severity       =[ALL | severity]. OPCIONAL. Default=ALL
User_id        =[ALL | id del account_account]. OPCIONAL. Default=ALL
Month          =[ALL | YYYY-MM]. OPCIONAL. Default=ALL. Formato: 2024-01
Month_Day      =[ALL | YYYY-MM-DD]. OPCIONAL. Default=ALL. Formato: 2024-01-15
Filters        =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta           =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug          =[No | Yes | KeyValues]. OPCIONAL. Default=No
               [No] NO EJECUTA QUERY y devuelve el código del Query.
               [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]')

Ejemplos:

call Report_ip_log('');
call Report_ip_log('debug=ye');
call Report_ip_log('debug=ye,filters=yes');
call Report_ip_log('device_type=mobile,risk_level=high');
call Report_ip_log('user_id=123,month=2024-01');
call Report_ip_log('month_day=2024-01-15,risk_score=50');

2026-01-08 v1  Primera versión operativa
13.04.2026 v1.1 Reemplazo de variables de sesión por variables locales
*/

DROP PROCEDURE IF EXISTS Report_ip_log;

   DELIMITER $$
   CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_ip_log`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report IP Tracking User IP Log'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Variables locales
DECLARE v_Version         VARCHAR(32) DEFAULT 'v1.1 13.04.2026';
DECLARE v_CurrentDay      DATE        DEFAULT CURDATE();
DECLARE v_Month           CHAR(7)     DEFAULT LEFT(CURDATE(),7);
DECLARE v_Device_type     VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Risk_level      VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Severity        VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Risk_score      VARCHAR(64) DEFAULT 'ALL';
DECLARE v_User_id         VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Month_filter    VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Month_Day       VARCHAR(64) DEFAULT 'ALL';
DECLARE v_Debug           VARCHAR(16) DEFAULT 'NO';
DECLARE v_Filters         VARCHAR(16) DEFAULT 'NO';
DECLARE v_Meta            VARCHAR(16) DEFAULT 'YES';

DECLARE v_InputCommLine   VARCHAR(500) DEFAULT '';
DECLARE v_e               INT DEFAULT 0;
DECLARE v_c               INT DEFAULT 0;
DECLARE v_k               VARCHAR(128) DEFAULT '';
DECLARE v_v               VARCHAR(250) DEFAULT '';

DECLARE v_WhereDevice_type TEXT DEFAULT '';
DECLARE v_WhereRisk_level  TEXT DEFAULT '';
DECLARE v_WhereSeverity    TEXT DEFAULT '';
DECLARE v_WhereRisk_score  TEXT DEFAULT '';
DECLARE v_WhereUser_id     TEXT DEFAULT '';
DECLARE v_WhereMonth       TEXT DEFAULT '';
DECLARE v_WhereMonth_Day   TEXT DEFAULT '';

DECLARE v_CTE        LONGTEXT DEFAULT '';
DECLARE v_SQLmeta    LONGTEXT DEFAULT '';
DECLARE v_SQL        LONGTEXT DEFAULT '';
DECLARE v_SQLfilters LONGTEXT DEFAULT '';
DECLARE v_Count      INT DEFAULT 0;

-- Defaults y parseo de InputCommLine
SET v_InputCommLine = CONCAT(InputCommLine ,',');      -- Coma de cierre
SET v_InputCommLine = REPLACE(v_InputCommLine,'"',''); -- Elimina comillas

IF v_Debug != 'NO' THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine > ' ' DO
   SET v_e = INSTR(v_InputCommLine,'=');
   SET v_c = INSTR(v_InputCommLine,',');
   SET v_k = SUBSTRING(v_InputCommLine,1,v_e-1);
   SET v_v = SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1));
   SET v_InputCommLine = SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k = TRIM(v_k);
   SET v_v = TRIM(v_v);

   IF LOWER(v_k) = 'device_type' THEN SET v_Device_type  = v_v;        END IF;
   IF LOWER(v_k) = 'risk_level'  THEN SET v_Risk_level   = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'severity'    THEN SET v_Severity     = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'risk_score'  THEN SET v_Risk_score   = v_v;        END IF;
   IF LOWER(v_k) = 'user_id'     THEN SET v_User_id      = v_v;        END IF;
   IF LOWER(v_k) = 'month'       THEN SET v_Month_filter = v_v;        END IF;
   IF LOWER(v_k) = 'month_day'   THEN SET v_Month_Day    = v_v;        END IF;
   IF LOWER(v_k) = 'debug'       THEN SET v_Debug        = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'filters'     THEN SET v_Filters      = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'meta'        THEN SET v_Meta         = UPPER(v_v); END IF;
END WHILE;

IF v_Debug != 'NO' THEN
    SELECT v_Device_type,v_Risk_level,v_Risk_score,v_User_id,v_Month_filter,v_Month_Day,v_Debug,v_Filters,v_Meta,InputCommLine,v_Version,v_CurrentDay,v_Month;
END IF;

IF v_Device_type  != 'ALL' THEN SET v_WhereDevice_type = CONCAT(" AND T.`device_type`='",v_Device_type,"'");                          END IF;
IF v_Risk_level   != 'ALL' THEN SET v_WhereRisk_level  = CONCAT(" AND T.`risk_level`='",v_Risk_level,"'");                            END IF;
IF v_Severity     != 'ALL' THEN SET v_WhereSeverity    = CONCAT(" AND F.`severity`='",v_Severity,"'");                                END IF;
IF v_Risk_score   != 'ALL' THEN SET v_WhereRisk_score  = CONCAT(" AND T.`risk_score`=",v_Risk_score);                                END IF;
IF v_User_id      != 'ALL' THEN SET v_WhereUser_id     = CONCAT(" AND T.`user_id`=",v_User_id);                                      END IF;
IF v_Month_filter != 'ALL' THEN SET v_WhereMonth       = CONCAT(" AND DATE_FORMAT(T.`timestamp`,'%Y-%m')='",v_Month_filter,"'");     END IF;
IF v_Month_Day    != 'ALL' THEN SET v_WhereMonth_Day   = CONCAT(" AND DATE_FORMAT(T.`timestamp`,'%Y-%m-%d')='",v_Month_Day,"'");     END IF;

IF v_Debug != 'NO' THEN SELECT v_WhereDevice_type,v_WhereRisk_level,v_WhereSeverity,v_WhereRisk_score,v_WhereUser_id,v_WhereMonth,v_WhereMonth_Day; END IF;

SET v_Count = 0;

/**************************************************************************************************************/
/*
SELECT `id`,`ip_address`,`ip_type`,`is_vpn`,`geolocation`,`user_agent`,`device_type`,`browser`,`os`
      ,`timestamp`,`session_id`,`endpoint`,`method`,`request_data`,`flagged_for_review`,`risk_level`
      ,`risk_score`,`notes`,`user_id`
FROM ip_tracking_user_ip_log;
*/

SET v_CTE = CONCAT('
WITH Main_Table_Data as (
SELECT
    DATE_FORMAT(T.`timestamp`,''%Y-%m'') as `month`
   ,DATE_FORMAT(T.`timestamp`,''%Y-%m-%d'') as `month_day`
   ,T.`id`
   ,T.`ip_address`
   ,T.`ip_type`
   ,T.`is_vpn`
   -- ,T.`geolocation`
   ,JSON_EXTRACT(T.`geolocation`,''$.country'') as `country`
   ,JSON_EXTRACT(T.`geolocation`,''$.city'') as `city`
   ,JSON_EXTRACT(T.`geolocation`,''$.isp'') as `isp`
   ,T.`user_agent`
   ,T.`device_type`
   ,T.`browser`
   ,T.`os`
   ,T.`timestamp`
   ,T.`session_id`
   ,T.`endpoint`
   ,T.`method`
   -- ,T.`request_data`
   ,T.`flagged_for_review`
   ,T.`risk_level`
   ,T.`risk_score`
   ,T.`notes`
   ,T.`user_id`
   ,A.`username` as `user_username`
   ,F.`indicator_type`
   ,F.`description`
   ,ifnull(F.`severity`,"low") as `severity`
FROM ip_tracking_user_ip_log T
LEFT JOIN `account_account` `A` ON `A`.`id` = `T`.`user_id`
LEFT JOIN `ip_tracking_ip_fraud_indicator` `F` ON `F`.`ip_log_id` = T.`id`
WHERE 1=1 '
   ,v_WhereDevice_type
   ,v_WhereRisk_level
   ,v_WhereSeverity
   ,v_WhereRisk_score
   ,v_WhereUser_id
   ,v_WhereMonth
   ,v_WhereMonth_Day
,'
GROUP BY `ip_address`,`user_id`,ifnull(`indicator_type`,""),ifnull(`severity`,"LOW"),ifnull(`risk_score`,"0")
)
');

SET v_SQLmeta = CONCAT(
'(
SELECT
   "setting" as Meta
--    ,"width=80px,action=2" as `Action`
   ,"width=80px"    as `month`
   ,"omit=true"     as `month day`
   ,"omit=true"     as `id`
   ,"width=150px"   as `ip address`
   ,"omit=true"     as `ip type`
   ,"omit=true"     as `is vpn`
   ,"width=100px"   as `country`
   ,"width=200px"   as `city`
   ,"omit=true"     as `isp`
   ,"omit=true"     as `user agent`
   ,"width=80px"    as `device type`
   ,"omit=true"     as `browser`
   ,"omit=true"     as `os`
   ,"omit=true"     as `timestamp`
   ,"omit=true"     as `session id`
   ,"omit=true"     as `endpoint`
   ,"omit=true"     as `method`
   ,"omit=true"     as `flagged for review`
   ,"width=80px"    as `risk level`
   ,"width=80px"    as `risk score`
   ,"omit=true"     as `notes`
   ,"omit=true"     as `user_id`
   ,"width=150px"   as `Affiliate`
   ,"width=150px,tooltip=yes"   as `indicator type`
   ,"width=300px,tooltip=yes"   as `description`
   ,"width=100px"   as `severity`
FROM DUAL WHERE "',v_Meta,'"="YES")
UNION ALL '
);

SET v_SQL = CONCAT(
v_CTE,
v_SQLmeta,
'
SELECT "data" as `Meta`
--    ,"..." as `Action`
   ,MT.*
FROM Main_Table_Data MT
ORDER BY `risk score` DESC, `Affiliate`
;'
);

SET v_SQLfilters = CONCAT(
v_CTE,'
(SELECT "01" as "Korder","Device Type" AS "Key",`device_type` AS "Value","device_type" AS `CallKey`,`device_type` AS "CallValue",COUNT(*) AS "Rows"
                                                                                                FROM Main_Table_Data GROUP BY `device_type`)                    UNION ALL
(SELECT "03","Severity",`Severity`,"Severity" ,`Severity`         ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`Severity` ,""))    UNION ALL
(SELECT "05","Risk Level",`risk_level`,"risk_level" ,`risk_level` ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`risk_level` ,""))    UNION ALL
(SELECT "07","Risk Score",`risk_score`,"risk_score" ,`risk_score` ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`risk_score` ,""))    UNION ALL
(SELECT "09","User"       ,`user_username`,"user_id" ,`user_id`   ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`user_id` ,""))       UNION ALL
(SELECT "11","Month"      ,`month`         ,"month"   ,`month`     ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`month` ,""))         UNION ALL
(SELECT "13","Month Day"  ,`month_day`     ,"month_day",`month_day` ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`month_day` ,""))
ORDER BY 1,3
;');

IF v_Filters = 'YES' THEN SET v_SQL = v_SQLfilters; END IF;

IF v_Debug != 'NO' THEN SELECT v_SQLfilters; END IF;
IF v_Debug != 'NO' THEN SELECT v_SQL; END IF;

IF v_Debug != 'YES' THEN
    -- PREPARE requiere variable de sesión en MySQL 8.0
    SET @v_stmt_sql = v_SQL;
	PREPARE stmt1 FROM @v_stmt_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Report_ip_log('debug=yes');
call Report_ip_log('debug=yes,filters=yes');
call Report_ip_log('device_type=mobile,risk_level=HIGH');
call Report_ip_log('user_id=123,month=2024-01');
call Report_ip_log('month_day=2024-01-15,risk_score=50');
call Report_ip_log('risk_level=HIGH,flagged_for_review=1');
*/
