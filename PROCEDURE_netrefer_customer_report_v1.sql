/*
PROCEDURE_Report_players_netrefer_v1.sql

Descripción:
  Procedimiento netrefer_customer_report.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

data_month      [ALL | YYYY-MM]. OPCIONAL. Default=LM.

Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call netrefer_customer_report('debug=ye'); -- Devuelve todas las MS
call netrefer_customer_report('debug=ye,data_month=LM');
call netrefer_customer_report('debug=ye,data_month=2025-01');

18.03.2026 v1    Primera versión operativa

  
*/

DROP PROCEDURE IF EXISTS netrefer_customer_report;
-- DROP PROCEDURE IF EXISTS Report_players_netrefer_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `netrefer_customer_report`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Netrefer Customer Report'

proc_label:BEGIN
DECLARE v_Version            VARCHAR(30);
DECLARE v_CurrentDay         DATE;
DECLARE v_Data_Month         VARCHAR(20);
DECLARE v_Signup_month       VARCHAR(20);
DECLARE v_Customer_ID        VARCHAR(100);
DECLARE v_CPA_month          VARCHAR(20);
DECLARE v_Affiliate_id       VARCHAR(50);
DECLARE v_Show_products      VARCHAR(10);
DECLARE v_Account            VARCHAR(100);
DECLARE v_Tracker_name       VARCHAR(150);
DECLARE v_Brand              VARCHAR(100);
DECLARE v_Debug              VARCHAR(20);
DECLARE v_Filters            VARCHAR(10);
DECLARE v_Meta               VARCHAR(10);
DECLARE v_InputCommLine      VARCHAR(500);
DECLARE v_e                  INT;
DECLARE v_c                  INT;
DECLARE v_k                  VARCHAR(120);
DECLARE v_v                  VARCHAR(250);
DECLARE v_Month              VARCHAR(20);
DECLARE v_Username           VARCHAR(120);
DECLARE v_First_pass         TINYINT;
DECLARE v_WhereAffiliate     TEXT;
DECLARE v_WhereSignup_month  TEXT;
DECLARE v_WhereCustomer_ID   TEXT;
DECLARE v_WhereCPAMonth      TEXT;
DECLARE v_WhereDataMonth     TEXT;
DECLARE v_WhereBrand         TEXT;
DECLARE v_WhereAccount       TEXT;
DECLARE v_WhereTracker_name  TEXT;
DECLARE v_GROUPBY            TEXT;
DECLARE v_Count              INT;
DECLARE v_CTE_players_Insert LONGTEXT;
DECLARE v_CTE_players_Delete LONGTEXT;
DECLARE v_SQLmeta_players    LONGTEXT;
DECLARE v_SQL                LONGTEXT;
DECLARE v_Month_INI          VARCHAR(7);
DECLARE v_SQLfilters         LONGTEXT;
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.0 18.03.2026';
SET v_CurrentDay      =CURDATE();
SET v_Data_Month      =LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET v_Signup_month    ='ALL';
SET v_Customer_ID     ='ALL';
SET v_CPA_month       =LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET v_Affiliate_id    ='ALL';
SET v_Show_products   ='NO';
SET v_Account         ='ALL';
SET v_Tracker_name    ='ALL';
SET v_Brand           ='ALL';
SET v_Debug           ='NO';
SET v_Filters         ='NO';
SET v_Meta            ='YES';

SET v_InputCommLine=CONCAT(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=REPLACE(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=REPLACE(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- v_InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF LOWER(v_k)='data_month'      THEN SET v_Data_Month    =UPPER(v_v); END IF;
   IF LOWER(v_k)='brand'           THEN SET v_Brand         =UPPER(v_v); END IF;
   IF LOWER(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF LOWER(v_k)='filters'         THEN SET v_Filters       =UPPER(v_v); END IF;
   IF LOWER(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;

END WHILE;

IF v_Data_Month='CM' THEN SET v_Data_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF v_Data_Month='LM' THEN SET v_Data_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF v_Debug!="NO" THEN SELECT v_Month,v_Filters,v_Data_Month,v_Signup_month,v_Show_products,v_Customer_ID,v_Affiliate_id
                                 ,v_Username,v_Tracker_name,v_Debug,v_Meta,InputCommLine; END IF;
                                 
SET v_WhereSignup_month='';
SET v_WhereCPAMonth    ='';
SET v_WhereDataMonth   ='';
SET v_WhereBrand       ='';

IF v_Data_Month    !="ALL" THEN SET v_WhereDataMonth    =CONCAT(" AND Left(`Date`,7)>='",v_Data_Month,"'");   END IF;
IF v_Signup_month  !="ALL" THEN SET v_WhereSignup_month =CONCAT(" AND Left(`Signup_Date`,7)>='",v_Signup_month,"'");  END IF;
IF v_CPA_month     !="ALL" THEN SET v_WhereCPAMonth     =CONCAT(" AND Left(`CPA_Processed_Date`,7)>='",v_CPA_month,"'");  END IF;
IF v_Brand         !="ALL" THEN SET v_WhereBrand        =CONCAT(" AND p.`Advertiser`='",v_Brand,"'");          END IF;

IF v_Debug!="NO" THEN SELECT v_WhereDataMonth,v_WhereSignup_month,v_WhereCPAMonth,v_WhereBrand; END IF;

SET v_Count=0;

/**************************************************************************************************************/
-- DROP TABLE IF EXISTS `players_net_refer_extract_lm`;
CREATE TABLE IF NOT EXISTS `players_net_refer_extract_lm` (
   `id`                    INT NOT NULL AUTO_INCREMENT,
   `Date`                  DATE NULL DEFAULT NULL,
   `Brand`                 VARCHAR(50) NULL DEFAULT NULL,
   `Account`               VARCHAR(50) NULL DEFAULT NULL,
   `Username_id`           INT NULL DEFAULT NULL,
   `Prod`                  VARCHAR(50) NULL DEFAULT NULL,
   `Customer_Reference_ID` VARCHAR(50) NULL DEFAULT NULL,
   `Country`               VARCHAR(50) NULL DEFAULT NULL,
   `Signup_Date`           DATE NULL DEFAULT NULL,
   `Reward_Plan`           VARCHAR(50) NULL DEFAULT NULL,
   `Marketing_Source_Name` VARCHAR(50) NULL DEFAULT NULL,
   `Marketing_Source_ID`   VARCHAR(50) NULL DEFAULT NULL,
   `Customer_Type`         VARCHAR(50) NULL DEFAULT NULL,
   `Customer_Level`        VARCHAR(50) NULL DEFAULT NULL,
   `CPA_Processed_Date`    DATE NULL DEFAULT NULL,
   `Website`               VARCHAR(50) NULL DEFAULT NULL,
   `Customer_Signup_Source` VARCHAR(50) NULL DEFAULT NULL,
   `Gross_Revenue`         DECIMAL(20,2) NULL DEFAULT NULL,
   `Deposits`              DECIMAL(20,2) NULL DEFAULT NULL,
   `Turnover`              DECIMAL(20,2) NULL DEFAULT NULL,
   `Payouts`               DECIMAL(20,2) NULL DEFAULT NULL,
   `Contributions`         DECIMAL(20,2) NULL DEFAULT NULL,
   `Transactions`          DECIMAL(20,0) NULL DEFAULT NULL,
   `Points`                DECIMAL(20,0) NULL DEFAULT NULL,
   `Adj_(Chargebacks)`     DECIMAL(20,2) NULL DEFAULT NULL,
   `Total_Net_Revenue`     DECIMAL(20,2) NULL DEFAULT NULL,
   `Total_Net_Revenue_MTD` DECIMAL(20,2) NULL DEFAULT NULL,
   `Affiliate_id`          INT NULL DEFAULT NULL,
   `Affiliate`             VARCHAR(100) NULL DEFAULT NULL,
   `MS_id`                 INT NULL DEFAULT NULL,  
   `Deal_id`               INT NULL DEFAULT NULL,
   `Baseline`              INT NULL DEFAULT NULL,
   `BL_Flag`               TINYINT NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   INDEX `MS_id` (`MS_id`) USING BTREE,
   INDEX `CPA_Processed_Date` (`CPA_Processed_Date`) 
)
;
/**************************************************************************************************************/

SET v_CTE_players_Delete=CONCAT('
DELETE FROM players_net_refer_extract_lm
WHERE 1=1 '
   ,v_WhereDataMonth,';
');

SET v_CTE_players_Insert=CONCAT('
INSERT IGNORE INTO players_net_refer_extract_lm

WITH Main_Table_Data_Raw AS -- Original_data as 
(
SELECT 
    p.`Date`                          `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Username`                      `Account`
   ,p.`Username_id`                   `Username_id`
   ,p.`Prodotto`                      `Product`
   ,p.`Customer_Reference_ID`         `Customer_Reference_ID`
   ,p.`Country`                       `Country`
   ,MAX(IFNULL(p.`Signup_Date`,""))   `Signup_Date`
   ,p.`Reward_Plan`                   `Reward_Plan`
   ,p.`Marketing_Source_Name`         `Marketing_Source_Name`
   ,p.`Marketing_Source_ID`           `Marketing_Source_ID`
   ,p.`Customer_Type`                 `Customer_Type`
   ,p.`Customer_Level`                `Customer_Level`
   ,MAX(IFNULL(p.`CPA_Processed_Date`,"")) `CPA_Processed_Date`
   ,p.`Brand`                         `Brand`
   ,p.`Customer_Signup_Source`        `Customer_Signup_Source`
   ,SUM(p.`Gross_Revenue`    )        `Gross_Revenue`
   ,SUM(p.`Deposits`         )        `Deposits`
   ,SUM(p.`Turnover`         )        `Turnover`
   ,SUM(p.`Payouts`          )        `Payouts`
   ,SUM(p.`Contributions`    )        `Contributions`
   ,SUM(p.`Transactions`     )        `Transactions`
   ,SUM(p.`Points`           )        `Points`
   ,SUM(p.`Adj_(Chargebacks)`)        `Adj_Chargebacks`
   ,SUM(p.`Total_Net_Revenue`)        `Total_Net_Revenue`
   ,SUM(p.`Total_Net_Revenue_MTD`)    `Total_Net_Revenue_MTD` 

FROM players_netrefer_API p  
WHERE 1=1 '
   ,v_WhereDataMonth,'
   AND IFNULL(p.`CPA_Processed_Date`,"") > "" 
GROUP BY `Username_id`,`Customer_Reference_ID` 
),
Main_Table_Data AS (
SELECT 
    p.`Date`                          `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Account`                       `Account`
   ,p.`Username_id`                   `Username_id`
   ,p.`Product`                       `Product`
   ,p.`Customer_Reference_ID`         `Customer_Reference_ID`
   ,p.`Country`                       `Country`
   ,case when p.`Signup_Date` is not null
         then DATE_FORMAT(STR_TO_DATE(Signup_Date, "%d-%m-%Y"), "%Y-%m-%d")
         else null end                `Signup_Date`
   ,p.`Reward_Plan`                   `Reward_Plan`
   ,p.`Marketing_Source_Name`         `Marketing_Source_Name`
   ,p.`Marketing_Source_ID`           `Marketing_Source_ID`
   ,p.`Customer_Type`                 `Customer_Type`
   ,p.`Customer_Level`                `Customer_Level`
   ,case when p.`CPA_Processed_Date` is not null
         then DATE_FORMAT(STR_TO_DATE(CPA_Processed_Date, "%d-%m-%Y"), "%Y-%m-%d")
         else null end                `CPA_Processed_Date`
   ,p.`Brand`                         `Brand`
   ,p.`Customer_Signup_Source`        `Customer_Signup_Source`
   ,ROUND(p.`Gross_Revenue`    ,2)    `Gross_Revenue`
   ,ROUND(p.`Deposits`         ,2)    `Deposits`
   ,ROUND(p.`Turnover`         ,2)    `Turnover`
   ,ROUND(p.`Payouts`          ,2)    `Payouts`
   ,ROUND(p.`Contributions`    ,2)    `Contributions`
   ,ROUND(p.`Transactions`     ,0)    `Transactions`
   ,ROUND(p.`Points`           ,0)    `Points`
   ,ROUND(p.`Adj_Chargebacks`  ,2)    `Adj_Chargebacks`
   ,ROUND(p.`Total_Net_Revenue`,2)    `Total_Net_Revenue`
   ,ROUND(p.`Total_Net_Revenue_MTD`,2) `Total_Net_Revenue_MTD`

   ,M.Affiliate_id          `Affiliate_id`
   ,a.Username              `Affiliate`
   ,M.id                    `MS_id`
   ,M.Deal_id               `Deal_id`
   ,da.Baseline             `Baseline`   

FROM Main_Table_Data_Raw p
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                          AND   (M.`Tracker_ID`=p.`Marketing_Source_ID`
                                              OR M.`Tracker_Name`=p.`Marketing_Source_Name`)
LEFT JOIN campaign_deal_affiliate da ON M.Deal_id=da.id                                              
LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
WHERE 1=1 '
   ,v_WhereDataMonth,
')
');

SET v_SQL=CONCAT(
v_CTE_players_Insert,
'
SELECT 
   null as `id`,
   MT.*,
   case when Deposits>0 and Deposits<Baseline then 1 else 0 end `BL_Flag`
FROM Main_Table_Data MT  
ORDER BY Customer_Reference_ID,`CPA_Processed_Date`
;'
);

-- ------------------------------------------------------------
IF v_Debug!="NO" THEN SELECT v_CTE_players_Delete; END IF;
IF v_Debug!="NO" THEN SELECT v_CTE_players_Insert; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

-- IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug != "YES" THEN

   SET @v_SQL = v_CTE_players_Delete;
   PREPARE stmt1 FROM @v_SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;

   SET @v_SQL = v_SQL;
	PREPARE stmt2 FROM @v_SQL;
	EXECUTE stmt2;
	DEALLOCATE PREPARE stmt2;
END IF;

END$$
DELIMITER ;

/* 

call Report_players_netrefer('debug=ye'); -- Devuelve todas las MS
call Report_players_netrefer('debug=ye,filters=yeS');
call Report_players_netrefer('debug=ye,Customer_ID=42555');
call Report_players_netrefer('debug=ye,filters=no,Affiliate_id=2');
call Report_players_netrefer('debug=ye,filters=no,Invoice_id=10');
call Report_players_netrefer('debug=ye,filters=no,Invoiced_Month=2024-01');
*/

