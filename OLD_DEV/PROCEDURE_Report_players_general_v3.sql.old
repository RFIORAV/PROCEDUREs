/*
PROCEDURE_Report_players_general.sql

Descripción:
  Procedimiento Report_players_general.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles "), salvo Advertiser con espacios: usar comillas dobles en el valor (Advertiser="Nombre con espacios")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id de Affiliate]. OPCIONAL. Default=ALL.
Data_Month      =[ALL | fecha en formato YYYY-MM]. OPCIONAL. Default=ALL.
Advertiser      =[ALL | nombre de Advertiser]. OPCIONAL. Default=ALL. Si el nombre contiene espacios, encerrar el valor entre comillas dobles.
Account         =[ALL | id de Account]. OPCIONAL. Default=ALL.
Tracker_name    =[ALL | nombre de Tracker]. OPCIONAL. Default=ALL.
Signup_month    =[ALL | fecha en formato YYYY-MM]. OPCIONAL. Default=ALL.
Customer_ID     =[ALL | id de Customer]. OPCIONAL. Default=ALL.
Show_products   =[Yes | No]. Devuelve los productos. OPCIONAL. Default=no.

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
GenIdx          =[No | Yes]. OPCIONAL. Si es Yes, regenera players_netrefer_API_idx (TRUNCATE + recarga). Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_players_general('debug=ye'); -- Devuelve todas las MS
call Report_players_general('debug=ye,filters=yeS');
call Report_players_general('debug=ye,filters=ye,Advertiser=Bwin');
call Report_players_general('debug=ye,filters=ye,Advertiser="Bet 365",show_products=yes');
call Report_players_general('debug=ye,filters=ye,Advertiser=Bwin,show_products=yes');
call Report_players_general('debug=ye,filters=ye,CPA_Month=2025-05,Advertiser=Bwin');
call Report_players_general('debug=ye,filters=yes,Affiliate_id=39');
call Report_players_general('genidx=yes,debug=YE');

17.06.2026 v3.3 Advertiser admite espacios si el valor viene entre comillas dobles
17.06.2026 v3.4 CallValue de filtro Brand con comillas dobles via CHAR(34)
*/

DROP PROCEDURE IF EXISTS Report_players_general;
DROP PROCEDURE IF EXISTS Report_players_general_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_players_general`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v3.4 Report Affiliate Interactions'

proc_label:BEGIN
DECLARE v_Version            VARCHAR(50);
DECLARE v_CurrentDay         DATE;
DECLARE v_Data_Month         VARCHAR(20);
DECLARE v_Signup_month       VARCHAR(20);
DECLARE v_Customer_ID        VARCHAR(50);
DECLARE v_CPA_month          VARCHAR(20);
DECLARE v_Affiliate_id       VARCHAR(30);
DECLARE v_Account            VARCHAR(50);
DECLARE v_Tracker_name       VARCHAR(100);
DECLARE v_Advertiser         VARCHAR(50);
DECLARE v_rest               VARCHAR(500);
DECLARE v_Show_products      VARCHAR(10);
DECLARE v_Debug              VARCHAR(20);
DECLARE v_Filters            VARCHAR(10);
DECLARE v_Meta               VARCHAR(10);
DECLARE v_GenIdx             VARCHAR(10);
DECLARE v_InputCommLine      VARCHAR(500);
DECLARE v_e                  INT;
DECLARE v_c                  INT;
DECLARE v_q2                 INT;
DECLARE v_k                  VARCHAR(100);
DECLARE v_v                  VARCHAR(250);
DECLARE v_Month              VARCHAR(20);
DECLARE v_Username           VARCHAR(100);
DECLARE v_First_pass         TINYINT DEFAULT 0;
DECLARE v_WhereAffiliate     TEXT;
DECLARE v_WhereSignup_month  TEXT;
DECLARE v_WhereCustomer_ID   TEXT;
DECLARE v_WhereCPAMonth      TEXT;
DECLARE v_WhereDataMonth     TEXT;
DECLARE v_WhereAdvertiser    TEXT;
DECLARE v_WhereAccount       TEXT;
DECLARE v_WhereTracker_name  TEXT;
DECLARE v_GROUPBY            TEXT;
DECLARE v_Count              INT DEFAULT 0;
DECLARE v_SQLgenidx          LONGTEXT;
DECLARE v_CTE_players        LONGTEXT;
DECLARE v_SQLmeta_players    LONGTEXT;
DECLARE v_SQL                LONGTEXT;
DECLARE v_Month_INI          VARCHAR(7);
DECLARE v_SQLfilters_where   LONGTEXT;
DECLARE v_SQLfilters         LONGTEXT;
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v3.4 17.06.2026';
SET v_CurrentDay      =CURDATE();
SET v_Data_Month      ='ALL';
SET v_Signup_month    ='ALL';
SET v_Customer_ID     ='ALL';
SET v_CPA_month       ='ALL';
SET v_Affiliate_id    ='ALL';
SET v_Account         ='ALL';
SET v_Tracker_name    ='ALL';
SET v_Advertiser      ='ALL';
SET v_Show_products   ='NO';
SET v_Debug           ='NO';
SET v_Filters         ='NO';
SET v_Meta            ='YES';
SET v_GenIdx          ='NO';
SET v_Month           =NULL;
SET v_Username        =NULL;

SET v_InputCommLine=CONCAT(InputCommLine,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
   SET v_e=INSTR(v_InputCommLine,'=');
   SET v_k=TRIM(SUBSTRING(v_InputCommLine,1,v_e-1));
   SET v_rest=SUBSTRING(v_InputCommLine,v_e+1);

   IF LOWER(v_k)='advertiser' AND LEFT(TRIM(v_rest),1)='"' THEN
      SET v_rest=TRIM(v_rest);
      SET v_q2=INSTR(SUBSTRING(v_rest,2),'"');
      IF v_q2>0 THEN
         SET v_v=SUBSTRING(v_rest,2,v_q2-1);
         SET v_InputCommLine=SUBSTRING(v_rest,v_q2+2);
         IF LEFT(v_InputCommLine,1)=',' THEN SET v_InputCommLine=SUBSTRING(v_InputCommLine,2); END IF;
      ELSE
         SET v_c=INSTR(v_rest,',');
         SET v_v=TRIM(BOTH '"' FROM SUBSTRING(v_rest,1,v_c-1));
         SET v_InputCommLine=SUBSTRING(v_rest,v_c+1);
      END IF;
   ELSE
      SET v_c=INSTR(v_rest,',');
      SET v_v=TRIM(SUBSTRING(v_rest,1,v_c-1));
      SET v_InputCommLine=SUBSTRING(v_rest,v_c+1);
   END IF;

   IF LOWER(v_k)='affiliate_id'    THEN SET v_Affiliate_id  =UPPER(v_v); END IF;
   IF LOWER(v_k)='account'         THEN SET v_Account       =UPPER(v_v); END IF;
   IF LOWER(v_k)='tracker_name'    THEN SET v_Tracker_name  =UPPER(v_v); END IF;
   IF LOWER(v_k)='data_month'      THEN SET v_Data_Month    =UPPER(v_v); END IF;
   IF LOWER(v_k)='signup_month'    THEN SET v_Signup_month  =UPPER(v_v); END IF;
   IF LOWER(v_k)='cpa_month'       THEN SET v_CPA_month     =UPPER(v_v); END IF;
   IF LOWER(v_k)='customer_id'     THEN SET v_Customer_ID   =UPPER(v_v); END IF;
   IF LOWER(v_k)='show_products'   THEN SET v_Show_products =UPPER(v_v); END IF;
   IF LOWER(v_k)='advertiser'      THEN SET v_Advertiser    =v_v; END IF;
   IF LOWER(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF LOWER(v_k)='filters'         THEN SET v_Filters       =UPPER(v_v); END IF;
   IF LOWER(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;
   IF LOWER(v_k)='genidx'          THEN SET v_GenIdx        =UPPER(v_v); END IF;

END WHILE;

IF v_Debug!="NO" THEN SELECT v_Month,v_Filters,v_Data_Month,v_Signup_month,v_Show_products,v_Customer_ID,v_Affiliate_id,v_Advertiser
                                 ,v_Username,v_Tracker_name,v_Debug,v_Meta,v_GenIdx,InputCommLine; END IF;
                                 
                             
-- Evita presentar todos los datos sin filtros
IF     v_Data_Month      ='ALL'
   AND v_Signup_month    ='ALL'
   AND v_Customer_ID     ='ALL'
   AND v_CPA_month       ='ALL'
   AND v_Affiliate_id    ='ALL'
   AND v_Account         ='ALL'
   AND v_Tracker_name    ='ALL'
   AND v_Advertiser      ='ALL'
THEN SET v_First_pass=1;
ELSE SET v_First_pass=0;
END IF;

SET v_WhereAffiliate   ='';
SET v_WhereSignup_month='';
SET v_WhereCustomer_ID ='';
SET v_WhereCPAMonth    ='';
SET v_WhereDataMonth   ='';
SET v_WhereAdvertiser  ='';
SET v_WhereAccount     ='';
SET v_WhereTracker_name='';

SET v_GROUPBY=CASE WHEN v_Show_products="YES"
                  THEN ' GROUP BY LEFT(`Date`,7),p.`Username_id`,`Customer_Reference_ID`,`Prodotto` '
                  ELSE ' GROUP BY LEFT(`Date`,7),`Username_id`,`Customer_Reference_ID` '
             END;

-- IF v_Data_Month    ="ALL"  AND v_Filters!="YES" THEN SET v_WhereDataMonth=CONCAT(" AND Left(p.`Date`,7)='",v_Data_Month,"'");   END IF;
IF v_Affiliate_id  !="ALL" THEN SET v_WhereAffiliate    =CONCAT(" AND M.Affiliate_id=",v_Affiliate_id );   END IF;
IF v_Data_Month    !="ALL" THEN SET v_WhereDataMonth    =CONCAT(" AND Left(p.`Date`,7)='",v_Data_Month,"'");   END IF;
IF v_Signup_month  !="ALL" THEN SET v_WhereSignup_month =CONCAT(" AND Left(`Signup_Date`,7)='",v_Signup_month,"'");  END IF;
IF v_CPA_month     !="ALL" THEN SET v_WhereCPAMonth     =CONCAT(" AND Left(`CPA_Processed_Date`,7)='",v_CPA_month,"'");  END IF;
IF v_Customer_ID   !="ALL" THEN SET v_WhereCustomer_ID  =CONCAT(" AND Customer_Reference_ID='",v_Customer_ID,"'");   END IF;
IF v_Advertiser !="ALL" THEN SET v_WhereAdvertiser   =CONCAT(" AND Advertiser='",REPLACE(v_Advertiser,"'","''"),"'"); END IF;
IF v_Account       !="ALL" THEN SET v_WhereAccount      =CONCAT(" AND p.`Username_id`='",v_Account,"'");          END IF;
IF v_Tracker_name  !="ALL" THEN SET v_WhereTracker_name =CONCAT(" AND p.`Marketing_Source_Name`='",v_Tracker_name,"'"); END IF;

IF v_Debug!="NO" THEN SELECT v_First_pass,v_WhereDataMonth,v_WhereSignup_month,v_WhereCustomer_ID,v_WhereAffiliate,v_WhereAdvertiser
                           ,v_WhereAccount,v_WhereTracker_name,v_GROUPBY; END IF;

SET v_Count=0;
SET v_SQLgenidx='';

/*******************************************************************************************/
CREATE TABLE IF NOT EXISTS `players_general_API_idx` (
   `API` VARCHAR(20) NULL DEFAULT "netrefer",
   `Date` VARCHAR(7) NULL DEFAULT NULL,
   `Advertiser_id` INT NOT NULL DEFAULT '0',
   `Advertiser` VARCHAR(50) NULL DEFAULT NULL,
   `Username_id` INT NULL DEFAULT NULL,
   `Username` VARCHAR(50) NULL DEFAULT NULL,
   `Customer_Reference_ID` VARCHAR(50) NULL DEFAULT NULL,
   `Signup_Date` VARCHAR(7) NULL DEFAULT NULL,
   `Marketing_Source_Name` VARCHAR(50) NULL DEFAULT NULL,
   `Affiliate_id` BIGINT NOT NULL DEFAULT '0',
   `Affiliate` VARCHAR(100) NOT NULL DEFAULT '',
   `CPA_Processed_Date` VARCHAR(7) NULL DEFAULT NULL,
   INDEX `Date` (`Date`),
   INDEX `Advertiser_id` (`Advertiser_id`),
   INDEX `Username_id` (`Username_id`),
   INDEX `Signup_Date` (`Signup_Date`),
   INDEX `Affiliate_id` (`Affiliate_id`),
   INDEX `CPA_Processed_Date` (`CPA_Processed_Date`),
   INDEX `Customer_Reference_ID` (`Customer_Reference_ID`),
   INDEX `Marketing_Source_Name` (`Marketing_Source_Name`)
);

IF v_GenIdx="YES" THEN
   TRUNCATE TABLE `players_general_API_idx`;
END IF;

SET v_SQLgenidx=CONCAT('
   INSERT IGNORE INTO players_general_API_idx
   SELECT 
      "netrefer"                         `API`
      ,Left(p.`Date`,7)                  `Date`
      ,ifnull(M.`Advertiser_id`,0)       `Advertiser_id`
      ,p.`Advertiser`                    `Advertiser`
      ,p.`Username_id`                   `Username_id`
      ,u.`Username`                      `Username`
      ,p.`Customer_Reference_ID`         `Customer_Reference_ID`
      ,MAX(left(DATE_FORMAT(STR_TO_DATE(Signup_Date, "%d-%m-%Y"), "%Y-%m-%d"),7)
         )                               `Signup_Date`
      ,p.`Marketing_Source_Name`         `Marketing_Source_Name`
      ,ifnull(M.Affiliate_id,0)          `Affiliate_id`
      ,ifnull(a.Username ,"_OldData")    `Affiliate`
      ,MAX(left(DATE_FORMAT(STR_TO_DATE(CPA_Processed_Date, "%d-%m-%Y"), "%Y-%m-%d"),7)
         )                              `CPA_Processed_Date`

   FROM players_netrefer_API p  
   LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                             AND  (M.`Tracker_ID`=p.`Marketing_Source_ID`
                                                OR M.`Tracker_Name`=p.`Marketing_Source_Name`)
   LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
   LEFT JOIN campaign_username   u     ON u.id=p.`Username_id` 
   GROUP BY `Advertiser_id`,p.`Username_id`,p.`Customer_Reference_ID`,p.`Marketing_Source_Name`
   UNION ALL  -- -------------------------------------------------------------------------------
   SELECT 
      "mexos"                            `API`
      ,Left(p.`Periodo_di_riferimento`,7) `Date`
      ,ifnull(M.`Advertiser_id`,0)       `Advertiser_id`
      ,p.`Advertiser`                    `Advertiser`
      ,p.`Username_id`                   `Username_id`
      ,p.`Username`                      `Username`
      ,p.`ID_cliente`                    `Customer_Reference_ID`
      ,MAX(left(Player_Signup_Date,7))   `Signup_Date`
      ,p.`Profilo`                       `Marketing_Source_Name`
      ,ifnull(M.Affiliate_id,0)          `Affiliate_id`
      ,ifnull(a.Username ,"_OldData")    `Affiliate`
      ,MAX(CASE WHEN IFNULL(p.`CPA1_Acquisitions_Cnt`,0) > 0
                THEN LEFT(p.`Periodo_di_riferimento`,7)
                ELSE NULL
           END)                          `CPA_Processed_Date`
   FROM players_mexos_API p  
   LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                             AND  (M.`Tracker_ID`=p.`Profilo`
                                                OR M.`Tracker_Name`=p.`Profilo`)
   LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
   LEFT JOIN campaign_username   u     ON u.id=p.`Username_id` 
   WHERE Periodo_di_riferimento NOT IN ("Totali") AND Periodo_di_riferimento IS NOT NULL
      AND p.Date <= "2026-05-31"
   GROUP BY `Advertiser_id`,p.`Username_id`,p.`ID_cliente`,p.`Profilo` 

   UNION ALL  -- -------------------------------------------------------------------------------
   SELECT 
      "referon"                          `API`
      ,Left(p.`Date`,7)                  `Date`
      ,ifnull(M.`Advertiser_id`,0)       `Advertiser_id`
      ,p.`Advertiser`                    `Advertiser`
      ,p.`Username_id`                   `Username_id`
      ,p.`Username`                      `Username`
      ,p.`Customer_ID`                   `Customer_Reference_ID`
      ,MAX(LEFT(ifnull(Customer_Reg__Date,""),7)) `Signup_Date`
      ,p.`Marketing_Source`              `Marketing_Source_Name`
      ,ifnull(M.Affiliate_id,0)          `Affiliate_id`
      ,ifnull(a.Username ,"_OldData")    `Affiliate`
      ,MAX(CASE WHEN IFNULL(p.`CPA`,0) > 0
                THEN LEFT(p.`Date`,7)
                ELSE NULL
           END)                          `CPA_Processed_Date`

   FROM players_referon_API p  
   LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                             AND  (M.`Tracker_ID`=p.`Marketing_Source_ID`
                                                OR M.`Tracker_Name`=p.`Marketing_Source`)
   LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
   LEFT JOIN campaign_username   u     ON u.id=p.`Username_id` 
   GROUP BY `Advertiser_id`,p.`Username_id`,p.`Customer_ID`,p.`Marketing_Source_ID`
   UNION ALL  -- -------------------------------------------------------------------------------
   SELECT 
      "flutter"                          `API`
      ,Left(p.`Date`,7)                  `Date`
      ,ifnull(M.`Advertiser_id`,0)       `Advertiser_id`
      ,p.`Advertiser`                    `Advertiser`
      ,p.`Username_id`                   `Username_id`
      ,p.`Username`                      `Username`
      ,p.`ID_riferimento_cliente`        `Customer_Reference_ID`
      ,MAX(left(DATE_FORMAT(STR_TO_DATE(Data_di_iscrizione, "%d-%m-%Y"), "%Y-%m-%d"),7)
         )                               `Signup_Date`
      ,p.`Codice_campagna`               `Marketing_Source_Name`
      ,ifnull(M.Affiliate_id,0)          `Affiliate_id`
      ,ifnull(a.Username ,"_OldData")    `Affiliate`
      ,MAX(left(DATE_FORMAT(STR_TO_DATE(Data_elaborazione_CPA, "%d-%m-%Y"), "%Y-%m-%d"),7)
         )                              `CPA_Processed_Date`

   FROM players_flutter p  
   LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                             AND  (M.`Tracker_ID`=p.`Codice_campagna`
                                                OR M.`Tracker_Name`=p.`Codice_campagna`)
   LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
   LEFT JOIN campaign_username   u     ON u.id=p.`Username_id` 
   GROUP BY `Advertiser_id`,p.`Username_id`,p.`ID_riferimento_cliente`,p.`Codice_campagna`   
   ;
');

/******************************************************************************************* *******************/

SET v_CTE_players=CONCAT('
WITH Main_Table_Data AS -- Original_data as 
(
SELECT 
    p.`Date`                          `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Username`                      `Username`
   ,p.`Username_id`                   `Username_id`
-- ,p.`Method`                        `Method`
   ,p.`Prodotto`                      `Prodotto`
   ,p.`Customer_Reference_ID`         `Customer_Reference_ID`
-- ,p.`Alias`                         `Alias`
-- ,p.`AffiliateID`                   `AffiliateID`
   ,p.`Country`                       `Country`
   ,case when p.`Signup_Date` is not null
         then DATE_FORMAT(STR_TO_DATE(Signup_Date, "%d-%m-%Y"), "%Y-%m-%d")
         else null end                `Signup_Date`
   ,p.`Reward_Plan`                   `Reward_Plan`
   ,p.`Marketing_Source_Name`         `Marketing_Source_Name`
   ,p.`Marketing_Source_ID`           `Marketing_Source_ID`
   ,M.id                              `MS_id`
   ,M.Affiliate_id                    `Affiliate_id`
   ,a.Username                        `Affiliate`
-- ,p.`URL`                           `URL`
-- ,p.`Expiry_Date`                   `Expiry_Date`
   ,p.`Customer_Type`                 `Customer_Type`
   ,p.`Customer_Level`                `Customer_Level`
   ,case when p.`CPA_Processed_Date` is not null
         then DATE_FORMAT(STR_TO_DATE(CPA_Processed_Date, "%d-%m-%Y"), "%Y-%m-%d")
         else null end                `CPA_Processed_Date`
   ,p.`Brand`                         `Brand`
   ,p.`Customer_Signup_Source`        `Customer_Signup_Source`
   ,FORMAT(SUM(p.`Gross_Revenue`    ),2) `Gross_Revenue`
   ,FORMAT(SUM(p.`Deposits`         ),2) `Deposits`
   ,FORMAT(SUM(p.`Turnover`         ),2) `Turnover`
   ,FORMAT(SUM(p.`Payouts`          ),2) `Payouts`
   ,FORMAT(SUM(p.`Contributions`    ),2) `Contributions`
   ,FORMAT(SUM(p.`Transactions`     ),0) `Transactions`
   ,FORMAT(SUM(p.`Points`           ),0) `Points`
   ,FORMAT(SUM(p.`Adj_(Chargebacks)`),2) `Adj_(Chargebacks)`
   ,FORMAT(SUM(p.`Total_Net_Revenue`),2) `Total_Net_Revenue`
   ,p.`Total_Net_Revenue_MTD`         `Total_Net_Revenue_MTD`
-- ,p.`Details`                       `Details` 

FROM players_netrefer_API p  
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                          AND   (M.`Tracker_ID`=p.`Marketing_Source_ID`
                                              OR M.`Tracker_Name`=p.`Marketing_Source_Name`)
LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 

WHERE 1=1  AND ',v_First_pass,'=0 '
   ,v_WhereDataMonth
   ,v_WhereAdvertiser
   ,v_WhereAffiliate
   ,v_WhereAccount
   ,v_WhereTracker_name
,v_GROUPBY,
'
UNION ALL -- -------------------------------------------------------------------------------
SELECT 
    Left(p.`Periodo_di_riferimento`,7) `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Username`                      `Username`
   ,p.`Username_id`                   `Username_id`
   ,p.`Prodotto`                      `Prodotto`
   ,p.`ID_cliente`                    `Customer_Reference_ID`
   ,""                                `Country`
   ,MAX(left(Player_Signup_Date,7))   `Signup_Date`
   ,p.`Reward_Plan`                   `Reward_Plan`
   ,p.`Profilo`                       `Marketing_Source_Name`
   ,p.`Marketing_Source_ID`           `Marketing_Source_ID`
   ,M.id                              `MS_id`
   ,M.Affiliate_id                    `Affiliate_id`
   ,a.Username                        `Affiliate`
   ,""                                `Customer_Type`
   ,""                                `Customer_Level`
   ,MAX(CASE WHEN IFNULL(p.`CPA1_Acquisitions_Cnt`,0) > 0
               THEN LEFT(p.`Periodo_di_riferimento`,7)
               ELSE NULL
         END)                         `CPA_Processed_Date`
   ,p.`Advertiser`                    `Brand`
   ,""                                `Customer_Signup_Source`
   ,FORMAT(SUM(p.Casino_NGR+Poker_NGR+Scommesse_NGR+Slot_NGR),2) `Gross_Revenue`
   ,FORMAT(SUM(p.`Somma_totale_depositi`),2) `Deposits`
   ,0                                  `Turnover`
   ,0                                  `Payouts`
   ,0                                  `Contributions`
   ,0                                  `Transactions`
   ,0                                  `Points`
   ,0                                  `Adj_(Chargebacks)`
   ,FORMAT(SUM(p.Casino_NGR+Poker_NGR+Scommesse_NGR+Slot_NGR),2) `Total_Net_Revenue`
   ,0                                 `Total_Net_Revenue_MTD`

FROM players_mexos_API p  
   LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                             AND  (M.`Tracker_ID`=p.`Profilo`
                                                OR M.`Tracker_Name`=p.`Profilo`)
   LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 
   LEFT JOIN campaign_username   u     ON u.id=p.`Username_id` 
WHERE Periodo_di_riferimento NOT IN ("Totali") AND Periodo_di_riferimento IS NOT NULL
      AND p.Date <= "2026-05-31"
 AND ',v_First_pass,'=0 '
   ,v_WhereDataMonth
   ,v_WhereAdvertiser
   ,v_WhereAffiliate
   ,v_WhereAccount
   ,v_WhereTracker_name
,v_GROUPBY,
'
UNION ALL -- -------------------------------------------------------------------------------
SELECT 
    p.`Date`                          `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Username`                      `Username`
   ,p.`Username_id`                   `Username_id`
   ,p.`Product_Name`                  `Prodotto`
   ,p.`Customer_ID`                   `Customer_Reference_ID`
   ,""                                `Country`
   ,case when p.`Customer_Reg__Date` is not null
         then DATE_FORMAT(STR_TO_DATE(Customer_Reg__Date, "%Y-%m-%d"), "%Y-%m-%d")
         else null end                `Signup_Date`
   ,p.`Rewarding_Plan`                `Reward_Plan`
   ,p.`Marketing_Source`              `Marketing_Source_Name`
   ,p.`Marketing_Source_ID`           `Marketing_Source_ID`
   ,M.id                              `MS_id`
   ,M.Affiliate_id                    `Affiliate_id`
   ,a.Username                        `Affiliate`
   ,""                                `Customer_Type`
   ,""                                `Customer_Level`
   ,MAX(CASE WHEN IFNULL(p.`CPA`,0) > 0
               THEN LEFT(p.`Date`,7)
               ELSE NULL
         END)                         `CPA_Processed_Date`
   ,p.`Brand_Name`                    `Brand`
   ,""                                `Customer_Signup_Source`
   ,FORMAT(SUM(p.`NGR`              ),2) `Gross_Revenue`
   ,FORMAT(SUM(p.`Deposits`         ),2) `Deposits`
   ,FORMAT(SUM(p.`Turnover`         ),2) `Turnover`
   ,0                                    `Payouts`
   ,0                                    `Contributions`
   ,0                                    `Transactions`
   ,0                                    `Points`
   ,0                                    `Adj_(Chargebacks)`
   ,FORMAT(SUM(p.`NGR`              ),2) `Total_Net_Revenue`
   ,0                                    `Total_Net_Revenue_MTD`

FROM players_referon_API p  
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                          AND   (M.`Tracker_ID`=p.`Marketing_Source_ID`
                                              OR M.`Tracker_Name`=p.`Marketing_Source`)
LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 

WHERE 1=1  AND ',v_First_pass,'=0 AND p.`Customer_ID` IS NOT NULL '
   ,v_WhereDataMonth
   ,v_WhereAdvertiser
   ,v_WhereAffiliate
   ,v_WhereAccount
   ,v_WhereTracker_name
,v_GROUPBY,
'
UNION ALL -- -------------------------------------------------------------------------------
SELECT 
    p.`Date`                          `Date`
   ,p.`Advertiser`                    `Advertiser`
   ,p.`Username`                      `Username`
   ,p.`Username_id`                   `Username_id`
   ,p.`Prodotto`                      `Prodotto`
   ,p.`ID_riferimento_cliente`        `Customer_Reference_ID`
   ,""                                `Country`
   ,case when p.`Data_di_iscrizione` is not null
         then DATE_FORMAT(STR_TO_DATE(Data_di_iscrizione, "%Y-%m-%d"), "%Y-%m-%d")
         else null end                `Signup_Date`
   ,p.`Piano_di_incentivazione`       `Reward_Plan`
   ,p.`Codice_campagna`               `Marketing_Source_Name`
   ,p.`Codice_campagna`               `Marketing_Source_ID`
   ,M.id                              `MS_id`
   ,M.Affiliate_id                    `Affiliate_id`
   ,a.Username                        `Affiliate`
   ,""                                `Customer_Type`
   ,""                                `Customer_Level`
   ,MAX(CASE WHEN IFNULL(p.`CPA_scattata`,"no") > "si"
               THEN DATE_FORMAT(STR_TO_DATE(Data_elaborazione_CPA, "%d-%m-%Y"), "%Y-%m-%d")
               ELSE NULL
         END)                         `CPA_Processed_Date`  
   ,p.`Advertiser`                    `Brand`
   ,""                                `Customer_Signup_Source`
   ,FORMAT(SUM(CAST(REPLACE(REPLACE(REGEXP_REPLACE(p.`Ricavo_netto_totale`, "[^0-9,-]", ""),".", ""),",", ".") AS DECIMAL(10,2))),2) AS `Gross_Revenue`
   ,FORMAT(SUM(CAST(REPLACE(REPLACE(REGEXP_REPLACE(p.`Versamenti`, "[^0-9,-]", ""),".", ""),",", ".") AS DECIMAL(10,2))),2) AS `Deposits`
   ,0 `Turnover`
   ,0                                    `Payouts`
   ,0                                    `Contributions`
   ,0                                    `Transactions`
   ,0                                    `Points`
   ,0                                    `Adj_(Chargebacks)`
   ,FORMAT(SUM(CAST(REPLACE(REPLACE(REGEXP_REPLACE(p.`Ricavo_netto_totale`, "[^0-9,-]", ""),".", ""),",", ".") AS DECIMAL(10,2))),2) AS `Total_Net_Revenue`
   ,0                                    `Total_Net_Revenue_MTD`
FROM players_flutter p  
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`Username_id`=p.`Username_id` 
                                          AND   (M.`Tracker_ID`=p.`Codice_campagna`
                                              OR M.`Tracker_Name`=p.`Codice_campagna`)
LEFT JOIN account_account     a     ON a.id=M.Affiliate_id 

WHERE 1=1  AND ',v_First_pass,'=0 AND p.`ID_riferimento_cliente` IS NOT NULL '
   ,v_WhereDataMonth
   ,v_WhereAdvertiser
   ,v_WhereAffiliate
   ,v_WhereAccount
   ,v_WhereTracker_name
,v_GROUPBY,
'
)
');
-- ----------------------------------------------------------------
-- ----------------------------------------------------------------
SET v_SQLmeta_players=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"width=100px"            as `Date data`
   ,"width=150px"            as `Brand`
   ,"width=150px,tooltip=yes" as `Account`
   ,"omit=yes"               as `Username_id`
   ,',IF(v_Show_products="YES","\"width=150px\"","\"omit=yes\""),' as `Prod`
   ,"width=100px"            as `Cust ID`
   ,"width=100px"            as `Country`
   ,"width=100px"            as `Signup Date`
   ,"width=200px,tooltip=yes" as `Reward Plan`
   ,"width=100px"            as `MS Name`
   ,"width=100px"            as `Tracking id`
   ,"width=100px"            as `MS_id`
   ,"width=100px"            as `Affiliate id`
   ,"width=200px"            as `Affiliate`
   ,"width=100px"            as `Cust Type`
   ,"width=100px"            as `Cust Level`
   ,"width=100px"            as `CPA Date`
   ,"omit=yes"               as `Web`
   ,"width=100px"            as `Cust Sgnup Source`
   ,"width=100px,right=true" as `Gross Revenue`
   ,"width=100px,right=true" as `Deposits`
   ,"width=100px,right=true" as `Turnover`
   ,"width=100px,right=true" as `Payouts`
   ,"width=100px,right=true" as `Contribt`
   ,"width=100px,right=true" as `Transacts`
   ,"width=100px,right=true" as `Points`
   ,"width=100px,right=true" as `Adj (Chargebacks)`
   ,"width=100px,right=true" as `Total NR`
   ,"width=100px,right=true" as `Total NR MTD`   
FROM DUAL WHERE "',v_Meta,'"="YES")
UNION ALL '
);

SET v_SQL=CONCAT(
v_CTE_players,
v_SQLmeta_players,
'
SELECT "data" as `Meta`, -- "..." as `Action`,
   MT.*
FROM Main_Table_Data MT 
WHERE 1=1 '
   ,v_WhereSignup_month
   ,v_WhereCustomer_ID
   ,v_WhereCPAMonth
, 
'
-- LIMIT 1000
;'
);

-- ------------------------------------------------------------

SET v_Month_INI=LEFT(DATE_SUB(CURDATE(), INTERVAL 12 MONTH),7);

SET v_SQLfilters_where=CONCAT("p WHERE 1=1 ",v_WhereDataMonth,v_WhereAdvertiser,v_WhereAffiliate,v_WhereAccount,v_WhereTracker_name," ");
SET v_SQLfilters_where=REPLACE(v_SQLfilters_where,"M.","");
SET v_SQLfilters=CONCAT(
'
(SELECT "00" as "Korder","Options" AS "Key","Show detail by prod" AS "Value","Show_products" AS "CallKey","YES" AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "04","Affiliate"   ,`Affiliate`,"Affiliate_id",`Affiliate_id`,""                      FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Affiliate_id`) UNION ALL
(SELECT "01","Data Month"  ,`Date`     ,"Data_Month" ,`Date`,""                               FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Date`) UNION ALL
(SELECT "03","Brand"       ,`Advertiser`,"Advertiser",CONCAT(CHAR(34),`Advertiser`,CHAR(34)),""     FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Advertiser`)   UNION ALL
(SELECT "05","SignUp Month",`Signup_Date`,"Signup_Month" ,`Signup_Date`,""                    FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Signup_Date`) UNION ALL
(SELECT "06","CPA Month"   ,`CPA_Processed_Date`,"CPA_Month" ,`CPA_Processed_Date`,""         FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `CPA_Processed_Date`) UNION ALL
(SELECT "07","Customer ID" ,`Customer_Reference_ID`,"Customer_ID" ,`Customer_Reference_ID`,"" FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Customer_Reference_ID`) UNION ALL
(SELECT "11","Account"     ,`Username`    ,"Account"    ,`Username_id`    ,""                 FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Username_id`)     UNION ALL
(SELECT "13","MS Name"     ,`Marketing_Source_Name`,"Tracker_name",`Marketing_Source_Name`,"" FROM players_general_API_idx ',v_SQLfilters_where,' GROUP BY `Marketing_Source_Name`) -- UNION ALL
ORDER BY Korder ASC, 
         CASE WHEN Korder IN ("01","05","06") THEN Value END DESC,
         CASE WHEN Korder NOT IN ("01","05","06") THEN Value END ASC
;');


IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL;        END IF;
IF v_Debug!="NO" THEN SELECT v_SQLgenidx;  END IF;

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;
IF v_GenIdx="YES"  THEN SET v_SQL=v_SQLgenidx;  END IF;

IF v_Debug != "YES" THEN
	SET @v_stmt_sql=v_SQL;
	PREPARE stmt1 FROM @v_stmt_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/* 

call Report_players_general('debug=ye'); -- Devuelve todas las MS
call Report_players_general('debug=ye,filters=yeS');
call Report_players_general('debug=ye,Customer_ID=42555');
call Report_players_general('debug=ye,filters=no,Affiliate_id=2');
call Report_players_general('debug=ye,filters=no,Invoice_id=10');
call Report_players_general('debug=ye,filters=no,Invoiced_Month=2024-01');
*/

