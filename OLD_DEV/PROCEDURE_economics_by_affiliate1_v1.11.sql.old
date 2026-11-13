/*
PROCEDURE_economics_by_affiliate1_v1.11.sql - GENERACION DE RESUMEN ECONOMICS

Descripción:
  Procedimiento economics_by_affiliate1.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id del Affiliate]. OBLIGATORIO. Default=''
GenFile         =[Yes | No]. Guarda resultados en tabla temporal tmp_economics_by_affiliate. OPCIONAL. Default=No.
                  Con GenFile=Yes es obligatorio Affiliate_id numérico (no ALL).
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
OnlyBalance     =[Yes | No]. Sólo la línea de saldo final. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
economics_by_affiliate1

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call economics_by_affiliate1_dev(''); -- Devuelve todas las MS
call economics_by_affiliate1_dev(''); -- Devuelve todas las MS
call economics_by_affiliate1_dev('Affiliate_id=450,Meta=yes,debug=ye');
call economics_by_affiliate1_dev('Affiliate_id=all,OnlyBalance=yes,Meta=yes,debug=ye');
call economics_by_affiliate1_dev('Affiliate_id=450,GenFile=yes,debug=ye');

01.03.2022 v1.0   Mov "Accepted" el día 20
09.05.2022 v1.0   Optimización
02.09.2022 v1.0   Prueba y deploy
17.11.2022 v1.1   Refactoring
22.11.2022 v1.2   Parámetro OnlyBalance
11.01.2024 v1.3   view_monthly_fact_aff4
                  Tratamiento comisiones referral
04.08.2024 v1.4   Tratamiento Currency
                  Obtiene @Currency desde @GridCurrency en tabla util_settings
06.08.2024 v1.5   Reestructuración query con CTE para evitar warnings
                  Posible ejecución autónoma con filtros
09.08.2024 v1.6   Acumula comisiones del mes para poder mostrar en dashboard
10.09.2024 v1.6.1 Withdraw pending resta de Bal_Confirmed
02.11.2024 v1.7   Utiliza monthly_comms_affiliate_v5 en lugar de view_monthly_fact_aff4
                  Identifica comisiones de Referrer como "RFR"
16.12.2024 v1.8   comisiones de Bonus
24.07.2025 v1.9   Pending Withdraws resta a Confirmed balance
18.08.2025        "width=300px,tooltip=yes"  `Descr`
28.02.2026 v1.10  Fix: eliminación de variables globales
19.06.2026 v1.11  Parámetro GenFile: tabla temporal tmp_economics_by_affiliate
*/
SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS economics_by_affiliate1_dev;
-- DROP PROCEDURE IF EXISTS economics_by_affiliate1;
-- -----------------------------------------------------

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `economics_by_affiliate1_dev`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.11 19.06.2026 - RESUMEN [Affiliate_id] de Comisiones, Pagos, Ajustes desde el inicio, en forma de cuadro contabilidad'

ProcedureBody: BEGIN
-- --------------------------------------------------------------------------------------------
DECLARE v_version        VARCHAR(30);
DECLARE v_current_day    DATE;
DECLARE v_affiliate_id   VARCHAR(32);
DECLARE v_onlybalance    VARCHAR(10);
DECLARE v_meta           VARCHAR(10);
DECLARE v_month          CHAR(7);
DECLARE v_status         VARCHAR(32);
DECLARE v_currency       VARCHAR(10);
DECLARE v_filters        VARCHAR(10);
DECLARE v_debug          VARCHAR(20);
DECLARE v_genfile        VARCHAR(10);
DECLARE v_inputCommLine  VARCHAR(300);
DECLARE v_e              INT;
DECLARE v_c              INT;
DECLARE v_k              VARCHAR(100);
DECLARE v_v              VARCHAR(200);
DECLARE v_multicurrency  VARCHAR(10);
DECLARE v_lmonth         CHAR(7);
DECLARE v_date_confirm   CHAR(10);
DECLARE v_insertinto     VARCHAR(80);
DECLARE v_sqlmeta        LONGTEXT;
DECLARE v_cte            LONGTEXT;
DECLARE v_sql            LONGTEXT;
DECLARE v_sqlfilters     LONGTEXT;

-- Defaults
SET v_version         ='v1.11 19.06.2026';
SET v_current_day     =curdate();
SET v_affiliate_id    ='0';
SET v_onlybalance     ='NO';
SET v_meta            ='YES';
SET v_month           =LEFT(CURDATE(),7);

SET v_status          ='ALL';
SET v_currency        ='EUR';
SET v_filters         ='NO';
SET v_debug           ='NO';
SET v_genfile         ='NO';
SET v_insertinto      ='';

SET v_inputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_inputCommLine=replace(v_inputCommLine,' ','');  -- Elimina espacios
SET v_inputCommLine=replace(v_inputCommLine,'"','');  -- Elimina comillas

IF v_debug!="NO" THEN SELECT v_inputCommLine; END IF;
-- IF v_debug="YES" THEN SELECT @Owner,v_month,v_currency,@Advertiser_id,@ByAccount,v_debug,@Total,@TotLine,@OrderBy,@Order,v_inputCommLine; END IF;

WHILE v_inputCommLine>' ' DO
-- v_inputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- v_inputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_inputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_inputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_inputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_inputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_inputCommLine=SUBSTRING(v_inputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='affiliate_id'    THEN SET v_affiliate_id  =UPPER(v_v); END IF;
   IF lower(v_k)='onlybalance'     THEN SET v_onlybalance   =UPPER(v_v); END IF;
   IF lower(v_k)='currency'        THEN SET v_currency      =UPPER(v_v); END IF;
   IF lower(v_k)='debug'           THEN SET v_debug         =UPPER(v_v); END IF;
   IF lower(v_k)='filters'         THEN SET v_filters       =UPPER(v_v); END IF;
   IF lower(v_k)='meta'            THEN SET v_meta          =UPPER(v_v); END IF;
   IF lower(v_k)='status'          THEN SET v_status        =      v_v;  END IF;
   IF lower(v_k)='genfile'         THEN SET v_genfile       =UPPER(v_v); END IF;

END WHILE;

/**************************************************************************************************************/
IF v_genfile='YES' THEN
   IF v_affiliate_id IN ('0','ALL','') OR IFNULL(CAST(v_affiliate_id AS UNSIGNED),0)=0 THEN
      SELECT 'GenFile=Yes: Affiliate_id obligatorio (id numérico, no ALL)' AS Mensaje;
      LEAVE ProcedureBody;
   END IF;
END IF;
/**************************************************************************************************************/
IF v_genfile!='YES' AND v_affiliate_id="0" THEN SET v_affiliate_id="ALL"; END IF; -- ALL no muestra detalles en grid

-- Obtiene v_multicurrency y v_currency desde tabla util_settings
SET v_multicurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET v_currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

SET v_lmonth=left(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET v_date_confirm=CONCAT(LEFT(CURDATE(),7),"-20");

IF v_debug!="NO" THEN SELECT v_affiliate_id,v_date_confirm,v_lmonth,v_onlybalance,v_multicurrency,v_currency,v_filters,v_meta,v_genfile; END IF;

-- SQL dinámico ejecutado con PREPARE: puente en variables de sesión (@)
SET @Affiliate_id := v_affiliate_id;
SET @Date_confirm := v_date_confirm;
SET @LMonth := v_lmonth;
SET @OnlyBalance := v_onlybalance;
SET @MultiCurrency := v_multicurrency;
SET @Currency := v_currency;
SET @Filters := v_filters;
SET @Meta := v_meta;
SET @Month := v_month;
SET @Debug := v_debug;

IF v_genfile='YES' THEN
   DROP TEMPORARY TABLE IF EXISTS `tmp_economics_by_affiliate`;
   CREATE TEMPORARY TABLE `tmp_economics_by_affiliate` (
      `Month`                CHAR(7) NULL DEFAULT NULL,
      `Date`                 DATE NULL DEFAULT NULL,
      `Descr`                VARCHAR(500) NULL DEFAULT NULL,
      `Op`                   VARCHAR(32) NULL DEFAULT NULL,
      `Operation Currency`   VARCHAR(16) NULL DEFAULT NULL,
      `Operation Value`      DECIMAL(20,2) NULL DEFAULT NULL,
      `Financial currency`   VARCHAR(16) NULL DEFAULT NULL,
      `Financial Value`      DECIMAL(20,2) NULL DEFAULT NULL,
      `Status`               VARCHAR(32) NULL DEFAULT NULL,
      `Estimated Balance`    DECIMAL(20,2) NULL DEFAULT NULL,
      `Confirmed Balance`    DECIMAL(20,2) NULL DEFAULT NULL,
      `Acum_Comm_CM`         DECIMAL(20,2) NULL DEFAULT NULL,
      `RowNum`               INT NULL DEFAULT NULL,
      INDEX `RowNum` (`RowNum`) USING BTREE
      )
   COLLATE='utf8mb4_0900_ai_ci'
   ENGINE=InnoDB
   ;
   SET v_insertinto='INSERT INTO `tmp_economics_by_affiliate` ';
END IF;

SET v_sqlmeta=CONCAT('
(
SELECT
   "setting"                   `Meta`
   ,"width=090px"              `Month`
   ,"width=100px"              `Date`
   ,"width=300px,tooltip=yes"  `Descr`
   ,"width=100px"              `Op`
   ,"width=100px"              `Operation Currency`
   ,"width=100px,right=true"   `Operation Value`
   ,IF(@MultiCurrency="YES","width=090px,right=true","omit=true") AS `Financial currency`
   ,IF(@MultiCurrency="YES","width=090px,right=true","omit=true") AS `Financial Value`
   ,"width=090px"              `Status`
   ,"width=100px,right=true"   `Estimated Balance`
   ,"width=100px,right=true"   `Confirmed Balance`
   ,"omit=true"                `Acum_Comm_CM`
   ,"omit=true"                `RowNum`
FROM DUAL
)
UNION ALL
'
);

SET v_cte=CONCAT(
'
WITH All_records AS (
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"CPA" AS Op_type
   ,Currency AS Currency
   ,CONCAT_WS(" ",Brand,Product_Real,Channel,Sub_Affiliate) AS Description
   ,(net_CPA_Val) AS Amount
   ,getCurrencyConversion(net_CPA_Val,Currency,@Currency) AS Transact
	,CASE WHEN `Month`<@LMonth THEN "1"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "1"
         ELSE 0 END AS Status
	,CASE WHEN `Month`<@LMonth THEN "Confirmed"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "Confirmed"
         ELSE "Provisional" END AS StatusText
	,0 as balance_est,0 as balance_conf
FROM monthly_comms_affiliate_v5 F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND (net_CPA_Val)<>0 AND Sub_Affiliate_id=0 AND Comm_type="CPA+RS"

UNION ALL -- ----------------------------------------------------------------
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"RShare" AS Op_type
   ,Currency AS Currency
   ,CONCAT_WS(" ",Brand,Product_Real,Channel,Sub_Affiliate) AS Description
   ,(net_RS_Val) AS Amount
   ,getCurrencyConversion(net_RS_Val,Currency,@Currency) AS Transact
	,CASE WHEN `Month`<@LMonth THEN "1"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "1"
         ELSE 0 END AS Status
	,CASE WHEN `Month`<@LMonth THEN "Confirmed"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "Confirmed"
         ELSE "Provisional" END AS StatusText
	,0 as balance_est,0 as balance_conf
FROM monthly_comms_affiliate_v5 F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND (net_RS_Val)<>0 AND Sub_Affiliate_id=0 AND Comm_type="CPA+RS"

UNION ALL -- ----------------------------------------------------------------
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"RFR" AS Op_type
   ,Currency AS Currency
   ,CONCAT_WS(" ",Brand,Product_Real,Channel,Sub_Affiliate) AS Description
   ,(net_Total_comm) AS Amount
   ,getCurrencyConversion(net_Total_comm,Currency,@Currency) AS Transact
	,CASE WHEN `Month`<@LMonth THEN "1"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "1"
         ELSE 0 END AS Status
	,CASE WHEN `Month`<@LMonth THEN "Confirmed"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "Confirmed"
         ELSE "Provisional" END AS StatusText
	,0 as balance_est,0 as balance_conf
FROM monthly_comms_affiliate_v5 F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND (net_Total_comm)<>0 AND Sub_Affiliate_id!=0 AND Comm_type="REFER"

UNION ALL -- ----------------------------------------------------------------
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"Bonus" AS Op_type
   ,Currency AS Currency
   ,CONCAT_WS(" ","Bonus",Brand,`CPA`,"CPA") AS Description
   ,(net_Total_comm) AS Amount
   ,getCurrencyConversion(net_Total_comm,Currency,@Currency) AS Transact
	,CASE WHEN `Month`<@LMonth THEN "1"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "1"
         ELSE 0 END AS Status
	,CASE WHEN `Month`<@LMonth THEN "Confirmed"
         WHEN `Month`=@LMonth and CURDATE()>=@Date_confirm THEN "Confirmed"
         ELSE "Provisional" END AS StatusText
	,0 as balance_est,0 as balance_conf
FROM monthly_comms_affiliate_v5 F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND (net_Total_comm)<>0 AND Comm_type="BONUS"

UNION ALL -- ----------------------------------------------------------------
SELECT Affiliate_id,LEFT(Date,10) AS "Date"
   ,Op_type
   ,Currency
   ,Description
   ,Amount_Debit*-1 AS Amount
   ,getCurrencyConversion(Amount_Debit*-1,Currency,@Currency) AS Transact
   ,CASE WHEN IFNULL(Status,"0")="0" -- AND Op_type="WithDraw" 
         THEN "1" ELSE IFNULL(Status,"0") END AS `Status`
	,CASE IFNULL(Status,"0")
		WHEN "0" THEN "Pending"
		WHEN "1" THEN "Accepted"
		WHEN "2" THEN "Paid"
		WHEN "3" THEN "Denied"
	 END AS StatusText
	,0 as balance_est, 0 as balance_conf
FROM account_financial_movement F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND ifnull(F.Status,0)<>3

UNION ALL -- ----------------------------------------------------------------
SELECT Affiliate_id,LEFT(Date,10) AS "Date"
   ,Op_type
   ,Currency
   ,Description
   ,Amount_Credit AS Amount
   ,getCurrencyConversion(Amount_Credit,Currency,@Currency) AS Transact
   ,IFNULL(Status,0) AS Status
	,CASE IFNULL(Status,0)
		WHEN 0 THEN "Pending"
		WHEN 1 THEN "Accepted"
		WHEN 2 THEN "Paid"
		WHEN 3 THEN "Denied"
		WHEN 5 THEN "INFO" END AS StatusText
	,0 as balance_est,0 as balance_conf
FROM account_manual_adjustments F
WHERE ',IF(v_affiliate_id="ALL","1=1","F.Affiliate_id=@Affiliate_id"),' AND ifnull(F.Status,0)<>3
ORDER BY DATE ASC
),
--
All_records_numbered as (
SELECT Date,Description,Op_type,Currency,Amount,Transact,Status,StatusText
	,ROW_NUMBER() OVER (ORDER BY Date) as RowNum
from All_records
)');

SET v_sql=CONCAT(
IF(v_genfile='YES',v_insertinto,''),   -- Si GenFile=YES, inserta en tabla temporal
v_cte
,IF(v_genfile='YES','',IF(v_meta="YES",v_sqlmeta,""))
,'
(SELECT
   ',
    IF(v_meta="YES" AND v_genfile!='YES',"'data' as `Meta`,",""),'
   left(date,7) as Month,Date,',IF(v_genfile='YES','DESCRIPTION AS Descr,Op_type AS Op','DESCRIPTION,Op_type'),'
   ,Currency               AS `Operation Currency`
   ,round(Amount,2)        AS `Operation Value`
   ,@Currency              AS `Financial currency`
   ,round(Transact,2)      AS `Financial Value`
   ,StatusText             AS `Status`
   ,SUM(CASE WHEN Status IN (0, 1, 2) THEN Transact ELSE 0 END) OVER (ORDER BY RowNum) AS `',IF(v_genfile='YES','Estimated Balance','Bal_Estimated'),'`
   ,SUM(CASE WHEN Status IN (1, 2)    THEN Transact ELSE 0 END) OVER (ORDER BY RowNum) AS `',IF(v_genfile='YES','Confirmed Balance','Bal_Confirmed'),'`
   ,SUM(CASE WHEN Status IN (0, 1, 2) AND LEFT(Date,7)=@Month AND Op_type IN ("CPA","RShare")
             THEN Transact ELSE 0 END) OVER (ORDER BY RowNum)                          AS `Acum_Comm_CM`
   ,RowNum
from All_records_numbered
WHERE @Affiliate_id!="ALL"
)
ORDER BY CASE WHEN LEFT(`RowNum`,4)!="omit" THEN CONVERT(`RowNum`,UNSIGNED) ELSE 0 END desc '
,IF(v_onlybalance="YES","LIMIT 1",""),
';');

SET v_sqlfilters=CONCAT(
v_cte,'
(SELECT "01" as "Korder"
            ,"Affiliate" AS "Key"
                         ,a.`username` AS "Value"
                                          ,"Affiliate_id" AS `CallKey`
                                                         ,`Affiliate_id` AS "CallValue"
                                                                         ,COUNT(*) AS "Rows"
FROM All_records R
INNER JOIN account_account a ON a.id=R.Affiliate_id
GROUP BY `Affiliate_id`
)
ORDER BY 1,3
;');

IF v_genfile='YES' THEN
   IF v_debug!="NO" THEN SELECT v_sql; END IF;
   IF v_debug != "YES" THEN
      SET @sql_exec := v_sql;
      PREPARE stmt1 FROM @sql_exec;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;
   IF v_debug!="NO" THEN SELECT * FROM `tmp_economics_by_affiliate`; END IF;
   LEAVE ProcedureBody;
END IF;

IF v_debug!="NO"   THEN SELECT v_sql;          END IF;
IF v_filters="YES" THEN SET v_sql=v_sqlfilters; END IF;
IF v_debug!="NO"   THEN SELECT v_sqlfilters;   END IF;

IF v_debug != "YES" THEN
	SET @sql_exec := v_sql;
	PREPARE stmt1 FROM @sql_exec;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

-- -----------------------------------------------------
-- -----------------------------------------------------
/*

CALL  economics_by_affiliate1('Affiliate_id=all,Meta=no,debug=ye');
CALL  economics_by_affiliate1('Affiliate_id=39,OnlyBalance=YES,Meta=yes,debug=ye');
CALL  economics_by_affiliate1('Affiliate_id=130,Meta=no,debug=ye');
CALL  economics_by_affiliate1('Affiliate_id=827,Meta=yes,debug=ye');
CALL  economics_by_affiliate1_dev('Affiliate_id=all,filters=yeS,debug=ye');
CALL  economics_by_affiliate1('Affiliate_id=74,filters=ye,debug=ye');
CALL  economics_by_affiliate1('Affiliate_id=39,GenFile=yes');
CALL  economics_by_affiliate1('Affiliate_id=39,GenFile=yes,debug=ye');
SELECT * FROM tmp_economics_by_affiliate;
*/
