/*
PROCEDURE_Report_ip_log_v1.sql - Report IP Tracking User IP Log

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
*/

DROP PROCEDURE IF EXISTS Report_ip_log;

   DELIMITER $$
   CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_ip_log`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report IP Tracking User IP Log'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 2026-01-08';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Device_type     ='ALL';
SET @Risk_level      ='ALL';
SET @Severity        ='ALL';
SET @Risk_score      ='ALL';
SET @User_id         ='ALL';
SET @Month_filter    ='ALL';
SET @Month_Day       ='ALL';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
   SET @e=INSTR(@InputCommLine,'=');
   SET @c=INSTR(@InputCommLine,',');
   SET @k=SUBSTRING(@InputCommLine,1,@e-1);
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1));
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   IF lower(@k)='device_type'   THEN SET @Device_type =      @v;  END IF;
   IF lower(@k)='risk_level'    THEN SET @Risk_level  =UPPER(@v); END IF;
   IF lower(@k)='severity'      THEN SET @Severity    =UPPER(@v); END IF;
   IF lower(@k)='risk_score'    THEN SET @Risk_score  =      @v;  END IF;
   IF lower(@k)='user_id'       THEN SET @User_id     =      @v;  END IF;
   IF lower(@k)='month'          THEN SET @Month_filter=      @v;  END IF;
   IF lower(@k)='month_day'      THEN SET @Month_Day   =      @v;  END IF;
   IF lower(@k)='debug'          THEN SET @Debug       =UPPER(@v); END IF;
   IF lower(@k)='filters'        THEN SET @Filters     =UPPER(@v); END IF;
   IF lower(@k)='meta'           THEN SET @Meta        =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Device_type,@Risk_level,@Risk_score,@User_id,@Month_filter,@Month_Day,@Debug,@Filters,@Meta,InputCommLine; END IF;

SET @WhereDevice_type='';
SET @WhereRisk_level='';
SET @WhereSeverity='';
SET @WhereRisk_score='';
SET @WhereUser_id='';
SET @WhereMonth='';
SET @WhereMonth_Day='';

IF @Device_type  !="ALL" THEN SET @WhereDevice_type =CONCAT(" AND T.`device_type`='",@Device_type,"'");                    END IF;
IF @Risk_level   !="ALL" THEN SET @WhereRisk_level  =CONCAT(" AND T.`risk_level`='",@Risk_level,"'");                     END IF;
IF @Severity     !="ALL" THEN SET @WhereSeverity    =CONCAT(" AND F.`severity`='",@Severity,"'");                     END IF;
IF @Risk_score   !="ALL" THEN SET @WhereRisk_score  =CONCAT(" AND T.`risk_score`=",@Risk_score);                          END IF;
IF @User_id      !="ALL" THEN SET @WhereUser_id     =CONCAT(" AND T.`user_id`=",@User_id);                                END IF;
IF @Month_filter !="ALL" THEN SET @WhereMonth       =CONCAT(" AND DATE_FORMAT(T.`timestamp`,'%Y-%m')='",@Month_filter,"'"); END IF;
IF @Month_Day    !="ALL" THEN SET @WhereMonth_Day    =CONCAT(" AND DATE_FORMAT(T.`timestamp`,'%Y-%m-%d')='",@Month_Day,"'"); END IF;

IF @Debug!="NO" THEN SELECT @WhereDevice_type,@WhereRisk_level,@WhereSeverity,@WhereRisk_score,@WhereUser_id,@WhereMonth,@WhereMonth_Day; END IF;

SET @Count=0;

/**************************************************************************************************************/
/*
SELECT `id`,`ip_address`,`ip_type`,`is_vpn`,`geolocation`,`user_agent`,`device_type`,`browser`,`os`
      ,`timestamp`,`session_id`,`endpoint`,`method`,`request_data`,`flagged_for_review`,`risk_level`
      ,`risk_score`,`notes`,`user_id`
FROM ip_tracking_user_ip_log;
*/

SET @CTE=CONCAT('
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
   ,@WhereDevice_type
   ,@WhereRisk_level
   ,@WhereSeverity
   ,@WhereRisk_score
   ,@WhereUser_id
   ,@WhereMonth
   ,@WhereMonth_Day
,'
GROUP BY `ip_address`,`user_id`,ifnull(`indicator_type`,""),ifnull(`severity`,"LOW"),ifnull(`risk_score`,"0")
)
');

SET @SQLmeta=CONCAT(
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
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`
--    ,"..." as `Action`
   ,MT.*
FROM Main_Table_Data MT
ORDER BY `risk score` DESC, `Affiliate`
;'
);

SET @SQLfilters=CONCAT(
@CTE,'
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

IF @Filters="yes" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
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
