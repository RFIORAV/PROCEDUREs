/*
PROCEDURE_Report_balance_by_affiliate.sql - Report balance by affiliate

Descripción:
  Procedimiento Report_balance_by_affiliate.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
IncludeInactives=[Yes | No]. Muestra Afiliados Status<>1. OPCIONAL. Default=No.
ShowInactives   =[Yes | No]. Muestra Sólo Afiliados Status<>1. OPCIONAL. Default=No.
ShowActive      =[Yes | No]. Muestra Sólo Afiliados Status=1. OPCIONAL. Default=No.
Omit0           =[Yes | No]. Omite Afiliados con Saldo=0. OPCIONAL. Default=yes.
Tmptable        =[Yes | No]. Guarda resultados en tabla temporal. OPCIONAL. Default=no.
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
InputCommLine = [valor]. Parámetro de entrada.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

CALL  Report_balance_by_affiliate_dev('debug=ye');  -- asum defaults: LMonth
CALL  Report_balance_by_affiliate('filters=yes,debug=non');
CALL  Report_balance_by_affiliate('filters=ye,omit0=no,debug=non');
CALL  Report_balance_by_affiliate('filters=yes,debug=YE');
CALL  Report_balance_by_affiliate('tmptable=yes,debug=ye');

23.05.2024 v1
24.05.2024 v1.1   Antig último movim
28.05.2024 v1.3   Considera Status de Afiliado
08.08.2024 v1.4   Adapt muli Currency
02.11.2024 v1.5   Utiliza monthly_comms_affiliate_v5 en lugar de view_monthly_fact_aff4
21.11.2024 v1.6   Opciones inactives
24.03.2025 v1.6.1 Agrega dato Last Login
25.06.2025 v1.6.2 reemplaza CURDATE() por @CurrentDay para pruebas
10.12.2025 v1.6.3 cambia Status_id por is_active en filtros y en consulta (RS)
10.12.2025 v1.6.3 agrega opción ShowActive
18.02.2026 v1.6.4 agrega columna Confirmed 20th Day
19.02.2026 v1.6.5 Karen: agrega columnas Confirmed today y confirmed_days
20.02.2026 v1.6.6 agrega opción tmptable
21.02.2026 v1.6.7 Cambio de variables de sesión a variables locales
26.03.2026 v1.7   Refactoriza consulta para mejorar rendimiento
20.03.2026 v1.7   Cambia el formato de la columna Confirmed 20th Day

***** OJO CON LAS COLUMNAS DEL GRID `confirmed_today` `confirmed_days` MANTENER EN MINUSCULAS

*/	
SET NAMES 'utf8mb4';

-- -----------------------------------------------------
-- DROP PROCEDURE IF EXISTS Report_balance_by_affiliate_dev;
DROP PROCEDURE IF EXISTS Report_balance_by_affiliate;
-- -----------------------------------------------------

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_balance_by_affiliate`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report balance by affiliate'

ProcedureBody: BEGIN
DECLARE v_Version          VARCHAR(30);
DECLARE v_CurrentDay       DATE;
DECLARE v_Date_confirm     DATE;
DECLARE v_LMonth           CHAR(7);
DECLARE v_Month            CHAR(7);
DECLARE v_Omit_0           VARCHAR(3);
DECLARE v_IncludeInactives VARCHAR(3);
DECLARE v_ShowInactives    VARCHAR(3);
DECLARE v_ShowActive       VARCHAR(3);
DECLARE v_OldBalances      VARCHAR(3);
DECLARE v_tmptable         VARCHAR(3);
DECLARE v_Filters          VARCHAR(3);
DECLARE v_Meta             VARCHAR(3);
DECLARE v_Debug            VARCHAR(20);
DECLARE v_flag             VARCHAR(10);
DECLARE v_e                INT;
DECLARE v_c                INT;
DECLARE v_k                VARCHAR(80);
DECLARE v_v                VARCHAR(250);
DECLARE v_MultiCurrency    VARCHAR(3);
DECLARE v_Currency         VARCHAR(10);
DECLARE v_LabelConf        VARCHAR(200);
DECLARE v_InsertInto       VARCHAR(200);
DECLARE v_LatestMov        CHAR(7);
DECLARE v_LatestMovFin     DATE;
DECLARE v_SQLmeta          LONGTEXT;
DECLARE v_SQLtxt           LONGTEXT;
DECLARE v_SQLfilters       LONGTEXT;
DECLARE v_LabelConfToday   VARCHAR(200);
DECLARE v_LabelConf21      VARCHAR(200);
DECLARE v_LabelConfMonth   VARCHAR(200);
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.7 20.03.2026';
SET v_CurrentDay      =CURDATE();
SET v_Date_confirm    =STR_TO_DATE(CONCAT(LEFT(v_CurrentDay,7),'-20'),'%Y-%m-%d');
SET v_LMonth          =LEFT(DATE_SUB(v_CurrentDay, INTERVAL 1 MONTH),7);
SET v_Month           =LEFT(v_CurrentDay,7);

SET v_Omit_0          ='YES';
SET v_IncludeInactives='NO';
SET v_ShowInactives   ='NO';
SET v_ShowActive      ='NO';
SET v_OldBalances     ='NO';
SET v_tmptable        ='NO';  -- Guarda resultados en tabla temporal
SET v_Filters         ='NO';
SET v_Meta            ='YES';
SET v_Debug           ='NO';
SET v_flag            ='all';


SET InputCommLine=CONCAT(InputCommLine,',');      -- Coma de cierre
-- SET InputCommLine=replace(InputCommLine,' ','');  -- Elimina espacios
SET InputCommLine=REPLACE(InputCommLine,'"','');  -- Elimina comillas

-- IF v_Debug!="NO" THEN SELECT InputCommLine; END IF;

WHILE InputCommLine>' ' DO
-- InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET InputCommLine=SUBSTRING(InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF LOWER(v_k)='omit_0'           THEN SET v_Omit_0          =UPPER(v_v); END IF;
   IF LOWER(v_k)='includeinactives' THEN SET v_IncludeInactives=UPPER(v_v); END IF;
   IF LOWER(v_k)='showinactives'    THEN SET v_ShowInactives   =UPPER(v_v); END IF;
   IF LOWER(v_k)='showactive'       THEN SET v_ShowActive      =UPPER(v_v); END IF;
   IF LOWER(v_k)='oldbalances'      THEN SET v_OldBalances     =UPPER(v_v); END IF;
   IF LOWER(v_k)='tmptable'         THEN SET v_tmptable        =UPPER(v_v); END IF;
   IF LOWER(v_k)='debug'            THEN SET v_Debug           =UPPER(v_v); END IF;
   IF LOWER(v_k)='filters'          THEN SET v_Filters         =UPPER(v_v); END IF;
   IF LOWER(v_k)='meta'             THEN SET v_Meta            =UPPER(v_v); END IF;

END WHILE;

-- Obtiene MultiCurrency y Currency desde tabla util_settings
SET v_MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET v_Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

IF   v_CurrentDay>=v_Date_confirm
THEN SET v_LabelConf=CONCAT(',"width=110px,omit=true"  as `Confirmed ',v_Date_confirm,'`');
ELSE SET v_LabelConf=CONCAT(',"width=110px,right=true" as `Confirmed ',v_Date_confirm,'`');
END  IF;	

IF v_tmptable='YES' THEN SET v_InsertInto='INSERT IGNORE INTO `tmp_balance_by_affiliate` ';
ELSE SET v_InsertInto=''; END IF;

IF v_ShowInactives='YES' THEN SET v_IncludeInactives='YES'; END IF;
IF v_ShowActive='YES'    THEN SET v_IncludeInactives='NO'; END IF;

SET v_LabelConfToday=CONCAT('"width=110px,right=true" as `Balance Confirmed ',curdate(),' `');
SET v_LabelConf21=CONCAT('"width=110px,right=true" as `Balance Confirmed ',v_Date_confirm,'`');
-- IF   v_CurrentDay<v_Date_confirm
-- THEN SET v_LabelConf21=CONCAT('"width=110px,right=true" as `Balance Confirmed ',v_Date_confirm,'`');
-- ELSE SET v_LabelConf21=CONCAT('"width=110px,omit=true"  as `Balance Confirmed ',v_Date_confirm,'`');
-- END IF;

SET v_LabelConfMonth=CONCAT('"width=110px,right=true" as `Balance Confirmed ',left(curdate(),7),'`');

SET v_LatestMov=LEFT(DATE_SUB(v_CurrentDay, INTERVAL 3 MONTH),7);
SET v_LatestMovFin=DATE_SUB(v_CurrentDay, INTERVAL 1 MONTH);

IF v_Debug!='NO' THEN SELECT v_Date_confirm,v_LMonth,v_Omit_0,v_tmptable,v_IncludeInactives,v_ShowInactives,v_ShowActive,v_LatestMov,v_LatestMovFin
                           ,v_MultiCurrency,v_Currency,
                           v_InsertInto,v_Debug,v_Filters,v_Meta,v_LabelConf,v_LabelConfToday,v_LabelConf21,v_LabelConfMonth,InputCommLine; END IF;

/**************************************************************************************************************/
-- SET SESSION group_concat_max_len = 200000;
-- -----------------------------------------------------------------------------------------------------

SET v_SQLmeta='';
IF v_Meta='YES' THEN
   SET v_SQLmeta=CONCAT(
'SELECT
   "setting" as Meta
   ,"width=090px,center=true" `Affiliate id`
   ,"width=200px"            `Affiliate`
   ,"width=90px"             `Curr`
   ,"width=110px,right=true" `Estimated commision Curr Mnth`
   ,"width=110px,right=true" `Balance Confirmed today`
   ,',v_LabelConf21,'
   ,"width=110px,right=true" `Balance Confirmed this Month`
   ,',IF(v_MultiCurrency='YES','"width=110px,right=true"','"omit=true"'),' AS `Financial Currency`
   ,',IF(v_MultiCurrency='YES','"width=110px,right=true"','"omit=true"'),' AS `Financial Confirmed`
   ,"width=110px,center=true" `Latest operation`
   ,"width=50px"              ` `
   ,"width=120px,right=true"  `Withdraw last 30 days`
   ,"width=120px,colorBg=[Active:green;Other:red;Paused:orange;Confirmed:green;Non_applied:red]" AS `Status Affiliate`    
   -- ,"width=110px,center=true" `Status Affiliate`
   ,"width=140px"             `Last login`
   ,"omit=true"               `Estimated`        -- 26.03.2026
   ,"omit=true"               `confirmed_today`  -- K 19.02.2026
   ,"omit=true"               `confirmed_days`   -- K 19.02.2026
FROM DUAL
UNION ALL
');
END IF;

DROP TEMPORARY TABLE IF EXISTS `tmp_balance_by_affiliate`;
CREATE TEMPORARY TABLE IF NOT EXISTS `tmp_balance_by_affiliate` (
   `Meta`               VARCHAR(5) NOT NULL DEFAULT '',
   `Affiliate_id`       INT NOT NULL DEFAULT 0,
   `Affiliate`          VARCHAR(100) NULL DEFAULT NULL,
   `Currency`           VARCHAR(16) NULL DEFAULT NULL,
   `estimated_CM`       DECIMAL(20,2) NULL DEFAULT NULL,
   `Confirmed`          DECIMAL(20,2) NULL DEFAULT NULL,
   `Confirmed21`        DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_CM`       DECIMAL(20,2) NULL DEFAULT NULL,
   `Financial Currency` VARCHAR(16) NULL DEFAULT NULL,
   `Financial Confirmed` DECIMAL(20,2) NULL DEFAULT NULL,
   `Latest_op`          VARCHAR(9) NOT NULL DEFAULT '',
   `Curr`               VARCHAR(3) NULL DEFAULT NULL,
   `Withdraw`           VARCHAR(36) NULL DEFAULT NULL,
   `Status`             VARCHAR(6) NOT NULL DEFAULT '',
   `last_login`         VARCHAR(16) NULL DEFAULT NULL,
   `Estimated`          DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_today`    DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_days`     DECIMAL(20,2) NULL DEFAULT NULL,
   INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE
   )
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;

SET v_SQLtxt=CONCAT(
v_InsertInto,'
-- -----------------------------------------------------------------------------------------------------
WITH Main_data_origen as (
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"CPA" AS Op_type
   ,CONCAT_WS(" ",Brand,Product_Real) AS Description
   ,sum(getCurrencyConversion(net_Total_comm,Currency,',QUOTE(v_Currency),')) AS Amount
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "4"  -- Confirmed
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'<',QUOTE(v_Date_confirm),' THEN "21" -- Confirmed 20th Day
         WHEN `Month`=',QUOTE(v_LMonth),' THEN "5" -- Confirmed this Month
         ELSE 0 -- Commission CM
         END                                                         AS Status
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "Confirmed"
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'>=',QUOTE(v_Date_confirm),' THEN "Confirmed"
         ELSE "Provisional" END                                            AS StatusText
	,0 as balance_est,0 as balance_conf
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "1"
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'<',QUOTE(v_Date_confirm),' THEN "8"
         ELSE 1 END                                                        AS Status_21
   ,Currency
FROM monthly_comms_affiliate_v5 F 
WHERE Currency<>',QUOTE(v_Currency),' -- AND `Month`>=',QUOTE(v_LMonth),'
GROUP BY Affiliate_id,Month

UNION ALL
SELECT Affiliate_id
	,(DATE_ADD(DATE_SUB(CONCAT(`Month`,"-01"), INTERVAL 1 DAY), INTERVAL 1 MONTH)) as `DATE`
	,"CPA" AS Op_type
   ,CONCAT_WS(" ",Brand,Product_Real) AS Description
   ,sum(net_Total_comm) AS Amount
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "4"  -- Confirmed
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'<',QUOTE(v_Date_confirm),' THEN "21" -- Confirmed 20th Day
         WHEN `Month`=',QUOTE(v_LMonth),' THEN "5" -- Confirmed this Month
         ELSE 0 -- Commission CM
         END                                                        AS Status
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "Confirmed"
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'>=',QUOTE(v_Date_confirm),' THEN "Confirmed"
         ELSE "Provisional" END                                            AS StatusText
	,0 as balance_est,0 as balance_conf
	,CASE WHEN `Month`<',QUOTE(v_LMonth),' THEN "1"
         WHEN `Month`=',QUOTE(v_LMonth),' and ',QUOTE(v_CurrentDay),'<',QUOTE(v_Date_confirm),' THEN "8"
         ELSE 1 END                                                        AS Status_21
   ,Currency
FROM monthly_comms_affiliate_v5 F 
WHERE Currency=',QUOTE(v_Currency),'
GROUP BY Affiliate_id,Month

UNION ALL
SELECT Affiliate_id,LEFT(Date,10) AS "Date",Op_type,Description
   ,sum(getCurrencyConversion(Amount_Credit,Currency,',QUOTE(v_Currency),')) AS Amount
   ,IFNULL(Status,"0") AS Status
	,CASE IFNULL(Status,"0") WHEN "0" THEN "Pending" WHEN "1" THEN "Accepted" WHEN "2" THEN "Paid" WHEN "3" THEN "Denied" END AS StatusText
	,0 as balance_est,0 as balance_conf
	,IFNULL(Status,0) AS Status_21
   ,IFNULL(Currency,',QUOTE(v_Currency),')  as "Currency"
FROM account_manual_adjustments F WHERE ifnull(F.Status,0) in (1,2)
GROUP BY Affiliate_id,"DATE" -- ,F.Currency

UNION ALL
SELECT Affiliate_id
   ,LEFT(Date,10) AS "Date"
   ,Op_type
   ,Description
   ,sum(getCurrencyConversion(Amount_Debit*-1,Currency,',QUOTE(v_Currency),')) AS Amount
   ,IFNULL(Status,"0") AS Status
	,CASE IFNULL(Status,0) WHEN 0 THEN "Pending" WHEN 1 THEN "Accepted" WHEN 2 THEN "Paid" WHEN 3 THEN "Denied" END AS StatusText
	,0 as balance_est, 0 as balance_conf
	,IFNULL(Status,"0") AS Status_21
   ,IFNULL(Currency,',QUOTE(v_Currency),')  as "Currency"
FROM account_financial_movement F WHERE ifnull(F.Status,0) IN (1,2)
GROUP BY Affiliate_id,"DATE" -- ,F.Currency
),
-- -----------------------------------------------------------------------------------------------------
Main_data as (
SELECT Affiliate_id
   ,ifnull(A.username,"_Unassigned") AS `Affiliate`
   ,`Currency`
	,round(sum(case when x.Status in (0,1,2,4,5,21)	then Amount ELSE 0 END),2) AS `Estimated`    -- Estimated
	,round(sum(case when x.Status IN (1,2,4,5)		then Amount ELSE 0 END),2) AS `Confirmed`    -- Confirmed today
	-- ,round(sum(case when x.Status IN (1,2,4,21)     then Amount ELSE 0 END),2) AS `Confirmed21`  -- Confirmed 20th Day
	,round(sum(case when x.Status IN (1,2,4,case when ',QUOTE(v_CurrentDay),'<',QUOTE(v_Date_confirm),' then 21 else 5 end) 
      then Amount ELSE 0 END),2) AS `Confirmed21`  -- Confirmed 20th Day
   ,',QUOTE(v_Currency),'                                                  as `Financial Currency`
	,round(sum(case when x.Status IN (1,2,4,5)      then getCurrencyConversion(Amount,Currency,',QUOTE(v_Currency),') ELSE 0 END),2) AS `Financial Confirmed`
   ,A.Status
   ,A.Status_id
   ,A.last_login
	,round(sum(case when x.Status in (0)			   then Amount ELSE 0 END),2) AS `commision_CM`   -- Commission CM
	,round(sum(case when x.Status in (1,2,4,5,21)   then Amount ELSE 0 END),2) AS `confirmed_CM`  -- Confirmed this Month
FROM Main_data_origen AS x
LEFT JOIN account_account A ON Affiliate_id	=A.id
'
,IF(v_ShowInactives='YES',' WHERE A.`is_active`!=1 ',' ')
,IF(v_IncludeInactives='YES',' ',' WHERE A.`is_active`=1 '),
'
GROUP BY Affiliate,Currency -- WITH ROLLUP
),
-- -----------------------------------------------------------------------------------------------------
Latest_operation as (
SELECT Affiliate_id as `Aff_id`,IFNULL(A.username,"_Unassigned") AS `username`
      ,max(`Month`) as `Latest_op`
FROM monthly_comms_affiliate_v5 F 
LEFT JOIN account_account A ON F.Affiliate_id=A.id
WHERE net_Total_comm<>0 -- OR (RS_AJUST)<>0
GROUP by Affiliate_id
),
Latest_withdraw as (
SELECT Affiliate_id as `Aff_id`,IFNULL(A.username,"_Unassigned") AS `username`
      ,`Currency`,SUM(Amount_Debit) AS `Withdraw`
FROM account_financial_movement F 
LEFT JOIN account_account A ON F.Affiliate_id=A.id
WHERE IFNULL(F.Status,0) IN (1,2) AND LEFT(Date,10)>=',QUOTE(v_LatestMovFin),'
GROUP by Affiliate_id
),
Main_dataRollUp AS (
SELECT 
       IF(GROUPING(M.Affiliate), "___ GRAND TOTAL ___", M.Affiliate) AS Affiliate
      ,IF(GROUPING(M.Currency), "T.Curr", M.Currency) AS Currency
      ,sum(`Estimated`          )                   `Estimated`          
      ,sum(`Confirmed`          )                   `Confirmed`          
      ,sum(`Confirmed21`        )                   `Confirmed21`        
      ,`Financial Currency` 
      ,sum(`commision_CM`       )                   `commision_CM`
      ,sum(`confirmed_CM`       )                   `confirmed_CM`
      ,sum(`Financial Confirmed`)                   `Financial Confirmed`
      ,IF(L.`username` IS NULL,"",L.`Latest_op`) AS `Latest_op`
      ,IF(W.`username` IS NULL,"",W.`Currency`)  AS `Curr`
      ,IF(W.`username` IS NULL,"",W.`Withdraw`)  AS `Withdraw`
      ,Status
      ,last_login
      ,Affiliate_id
FROM Main_data M 
LEFT JOIN Latest_operation L ON L.username=M.Affiliate
LEFT JOIN Latest_withdraw  W ON W.username=M.Affiliate
WHERE ',QUOTE(v_flag),'="all" '
,IF(v_Omit_0='YES',' AND (`Estimated`<>0 OR `Confirmed`<>0 OR `Confirmed21`<>0)',''),
'
GROUP BY M.Affiliate,M.Currency WITH ROLLUP
)
-- SELECT * FROM Main_data_origen;  -- Test
-- SELECT * FROM Main_data;         -- Test
-- SELECT * FROM Main_dataRollUp;   -- Test 
-- SELECT * FROM Latest_operation;  -- Test
-- SELECT * FROM Latest_withdraw;   -- Test
'
,IF(v_tmptable='NO',v_SQLmeta,''),
'
SELECT IF(`Affiliate`="___ GRAND TOTAL ___","total","data") as `Meta`
      ,IF(`Affiliate`="___ GRAND TOTAL ___",0,`Affiliate_id`) as `Affiliate_id`
      ,`Affiliate`
      ,`Currency`
      ,`commision_CM`
      ,`Confirmed`
      ,`Confirmed21`
      ,`confirmed_CM`
      ,`Financial Currency`
      ,`Financial Confirmed`
      ,IF(`Affiliate`="___ GRAND TOTAL ___","",`Latest_op`) as `Latest_op`
      ,`Curr`
      ,`Withdraw`
      ,IF(`Affiliate`="___ GRAND TOTAL ___","",`Status`) as `Status`
      ,IF(`Affiliate`="___ GRAND TOTAL ___","",left(last_login,16)) as `last_login`
      ,`Estimated`
      ,`Confirmed`   as `confirmed_today`
      ,`Confirmed21` as `confirmed_days`
FROM Main_dataRollUp  
WHERE `Currency`!="T.Curr" OR Affiliate="___ GRAND TOTAL ___"
ORDER BY `Affiliate`
;');
/*
-- Filtros------------------------------------------------------------------------------------
*/
SET v_SQLfilters=CONCAT('
SELECT "01" as "Korder","Criteria" AS "Key","Show All" AS "Value","IncludeInactives" AS `CallKey`,"YES" AS `CallValue` UNION ALL
SELECT "01" as "Korder","Criteria" AS "Key","Show Only Actives" AS "Value","ShowActive" AS `CallKey`,"YES" AS `CallValue` UNION ALL
SELECT "01" as "Korder","Criteria" AS "Key","Show Only Inactives" AS "Value","ShowInactives" AS `CallKey`,"YES" AS `CallValue` UNION ALL
SELECT "01" as "Korder","Criteria" AS "Key","Show Balances = 0.00" AS "Value","Omit_0" AS `CallKey`,"NO" AS `CallValue`
-- UNION ALL
-- SELECT "01" as "Korder","Criteria" AS "Key","Show Old Balances" AS "Value","OldBalances" AS `CallKey`,"YES" AS `CallValue`
;');

IF v_Debug!='NO' THEN SELECT v_SQLfilters; END IF;
IF v_Debug!='NO' THEN SELECT v_SQLtxt; END IF;

IF v_Filters='YES' THEN SET v_SQLtxt=v_SQLfilters; END IF;

SET @SQL_Report_balance_by_affiliate=v_SQLtxt;

IF v_Debug!='YES' THEN
	PREPARE stmt1 FROM @SQL_Report_balance_by_affiliate;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

IF v_Debug!='NO' AND v_tmptable='YES' THEN SELECT * FROM `tmp_balance_by_affiliate`; END IF;

END;
$$
DELIMITER ;

-- -----------------------------------------------------
-- -----------------------------------------------------
/*
CALL  Report_balance_by_affiliate('debug=yes');
CALL  Report_balance_by_affiliate('filters=yes,debug=YE');
CALL  Report_balance_by_affiliate_dev('meta=yes,Omit_0=yes,OldBalances=YE,debug=YE');
CALL  Report_balance_by_affiliate('filters=ye,Omit_0=yes,IncludeInactives=ye,debug=YE');
CALL  Report_balance_by_affiliate('filters=ye,Omit_0=yes,showInactives=yes,debug=YE');

CALL  Report_balance_by_affiliate('tmptable=yes,debug=ye');

*/
