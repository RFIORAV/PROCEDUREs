/**
PROCEDURE_Set_record_dbd_manual_v1.sql **	Agrega/modifica record a tabla Snapshot_day_by_day_manual

Descripción:
  Procedimiento Set_record_dbd_manual.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

DbD_id                     =[ '' | record id Snapshot_day_by_day_manual]. ''=Add record. OPCIONAL. Default=''
MS_id                      =[id de MS]. OBLIGATORIO
is_active                  =[ 0 | 1]. OPCIONAL. Default=0 (Paused)
deal_to_apply              =[ 0 | 1 | 2]. 0=Deal Ges+Aff 1=Deal Aff 2=Deal Ges. OPCIONAL. Default=0
Date                       =[AAAA-MM-DD]. OPCIONAL. Default=Current Day.
Product                    =OPCIONAL. Default=''
Qualified_Players          =OPCIONAL. Default='0'
First_Time_Deposit         =OPCIONAL. Default='0'
Views                      =OPCIONAL. Default='0'
Clicks                     =OPCIONAL. Default='0'
Signups                    =OPCIONAL. Default='0'
Deposits                   =OPCIONAL. Default='0'
Depositing_Customers       =OPCIONAL. Default='0'
Active_Customers           =OPCIONAL. Default='0'
First_Time_Active_Customers=OPCIONAL. Default='0'
Turnover                   =OPCIONAL. Default='0'
Net_Revenue                =OPCIONAL. Default='0'

Debug           =[No | Yes | Any ]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [Any] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

CALL Set_record_dbd_manual ('is_active=2,deal_to_apply=1,MS_id=5722,date=2026-01-03,Qualified_Players=-1,debug=yes');
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=1,MS_id=568,date=2023-02-02,Product=Sport ,Country=MX,Qualified_Players=2,Net_Revenue=2221.20,debug=yes');


13.02.2023 v1
14.02.2023        Procedure procesa Altas (DbD_id='') y Modificaciones (DbD_id=int)
18.03.2024 v1.1   Product default=Product Real MS
26.01.2026 v1.2   Revisión para correcto funcionamiento de Qualified_Players
12.02.2026 v1.2.1 Se elimina el parámetro Country.
28.02.2026 v1.2.2 Fix: eliminación de variables globales

*/

DROP PROCEDURE IF EXISTS Set_record_dbd_manual;
DROP PROCEDURE IF EXISTS Set_record_dbd_manual_dev;
-- -------------------------------------------------------------
DELIMITER //

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Set_record_dbd_manual`(IN
   InputCommLine    VARCHAR(500)
   )
    COMMENT 'ADD/EDIT record Snapshot_day_by_day_manual'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
DECLARE v_version                         VARCHAR(40);
DECLARE v_current_day                     DATE;
DECLARE v_month                           CHAR(7);
DECLARE v_dbd_id                          VARCHAR(30);
DECLARE v_ms_id                           VARCHAR(30);
DECLARE v_is_active                       VARCHAR(10);
DECLARE v_deal_to_apply                   VARCHAR(10);
DECLARE v_date                            VARCHAR(20);
DECLARE v_product                         VARCHAR(100);
DECLARE v_qualified_players               VARCHAR(30);
DECLARE v_first_time_deposit              VARCHAR(30);
DECLARE v_views                           VARCHAR(30);
DECLARE v_clicks                          VARCHAR(30);
DECLARE v_signups                         VARCHAR(30);
DECLARE v_deposits                        VARCHAR(30);
DECLARE v_depositing_customers            VARCHAR(30);
DECLARE v_active_customers                VARCHAR(30);
DECLARE v_first_time_active_customers     VARCHAR(30);
DECLARE v_turnover                        VARCHAR(30);
DECLARE v_net_revenue                     VARCHAR(30);
DECLARE v_debug                           VARCHAR(20);
DECLARE v_meta                            VARCHAR(10);
DECLARE v_filters                         VARCHAR(10);
DECLARE v_xdbd_id                         CHAR(1);
DECLARE v_xms_id                          CHAR(1);
DECLARE v_xis_active                      CHAR(1);
DECLARE v_xdeal_to_apply                  CHAR(1);
DECLARE v_xdate                           CHAR(1);
DECLARE v_xproduct                        CHAR(1);
DECLARE v_xqualified_players              CHAR(1);
DECLARE v_xfirst_time_deposit             CHAR(1);
DECLARE v_xviews                          CHAR(1);
DECLARE v_xclicks                         CHAR(1);
DECLARE v_xsignups                        CHAR(1);
DECLARE v_xdeposits                       CHAR(1);
DECLARE v_xdepositing_customers           CHAR(1);
DECLARE v_xactive_customers               CHAR(1);
DECLARE v_xfirst_time_active_customers    CHAR(1);
DECLARE v_xturnover                       CHAR(1);
DECLARE v_xnet_revenue                    CHAR(1);
DECLARE v_inputCommLine                   VARCHAR(550);
DECLARE v_e                               INT;
DECLARE v_c                               INT;
DECLARE v_k                               VARCHAR(150);
DECLARE v_v                               VARCHAR(300);
DECLARE v_dbd_id_int                      BIGINT UNSIGNED;

-- Defaults
SET v_version         ='v1.2.2 28.02.2026';
SET v_current_day     =curdate();
SET v_month           =LEFT(CURDATE(),7);

SET v_dbd_id                      ='' ;
SET v_ms_id                       ='' ;
SET v_is_active                   ='0';
SET v_deal_to_apply               ='0';
SET v_date                        =CURDATE();
SET v_product                     ='' ;
SET v_qualified_players           ='0';
SET v_first_time_deposit          ='0';
SET v_views                       ='0';
SET v_clicks                      ='0';
SET v_signups                     ='0';
SET v_deposits                    ='0';
SET v_depositing_customers        ='0';
SET v_active_customers            ='0';
SET v_first_time_active_customers ='0';
SET v_turnover                    ='0';
SET v_net_revenue                 ='0';

SET v_debug           ='NO';
SET v_meta            ='YES';
SET v_filters         ='NO';

SET v_xdbd_id=' '; SET v_xms_id=' '; SET v_xis_active=' '; SET v_xdeal_to_apply=' '; SET v_xdate=' '; SET v_xproduct=' ';
SET v_xqualified_players=' '; SET v_xfirst_time_deposit=' '; SET v_xviews=' '; SET v_xclicks=' '; SET v_xsignups=' ';
SET v_xdeposits=' '; SET v_xdepositing_customers=' '; SET v_xactive_customers=' ';
SET v_xfirst_time_active_customers=' '; SET v_xturnover=' '; SET v_xnet_revenue=' ';

SET v_inputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET v_inputCommLine=replace(v_inputCommLine,'"','');  -- Elimina comillas

IF v_debug!="NO" THEN SELECT v_inputCommLine; END IF;

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
--                                                                                            variable que indica dato informado
   if lower(v_k)='dbd_id'                      THEN SET v_dbd_id                      =v_v; SET v_xdbd_id                      ='x'; END IF;
   if lower(v_k)='ms_id'                       THEN SET v_ms_id                       =v_v; SET v_xms_id                       ='x'; END IF;
   if lower(v_k)='is_active'                   THEN SET v_is_active                   =v_v; SET v_xis_active                   ='x'; END IF;
   if lower(v_k)='deal_to_apply'               THEN SET v_deal_to_apply               =v_v; SET v_xdeal_to_apply               ='x'; END IF;
   if lower(v_k)='date'                        THEN SET v_date                        =v_v; SET v_xdate                        ='x'; END IF;
   if lower(v_k)='product'                     THEN SET v_product                     =v_v; SET v_xproduct                     ='x'; END IF;
   if lower(v_k)='qualified_players'           THEN SET v_qualified_players           =v_v; SET v_xqualified_players           ='x'; END IF;
   if lower(v_k)='first_time_deposit'          THEN SET v_first_time_deposit          =v_v; SET v_xfirst_time_deposit          ='x'; END IF;
   if lower(v_k)='views'                       THEN SET v_views                       =v_v; SET v_xviews                       ='x'; END IF;
   if lower(v_k)='clicks'                      THEN SET v_clicks                      =v_v; SET v_xclicks                      ='x'; END IF;
   if lower(v_k)='signups'                     THEN SET v_signups                     =v_v; SET v_xsignups                     ='x'; END IF;
   if lower(v_k)='deposits'                    THEN SET v_deposits                    =v_v; SET v_xdeposits                    ='x'; END IF;
   if lower(v_k)='depositing_customers'        THEN SET v_depositing_customers        =v_v; SET v_xdepositing_customers        ='x'; END IF;
   if lower(v_k)='active_customers'            THEN SET v_active_customers            =v_v; SET v_xactive_customers            ='x'; END IF;
   if lower(v_k)='first_time_active_customers' THEN SET v_first_time_active_customers =v_v; SET v_xfirst_time_active_customers ='x'; END IF;
   if lower(v_k)='turnover'                    THEN SET v_turnover                    =v_v; SET v_xturnover                    ='x'; END IF;
   if lower(v_k)='net_revenue'                 THEN SET v_net_revenue                 =v_v; SET v_xnet_revenue                 ='x'; END IF;
   IF lower(v_k)='debug'                       THEN SET v_debug                       =v_v; END IF;

END WHILE;

SET v_dbd_id_int = CASE
   WHEN TRIM(IFNULL(v_dbd_id,'')) REGEXP '^[0-9]+$' THEN CAST(v_dbd_id AS UNSIGNED)
   ELSE 0
END;

IF v_dbd_id_int>0 THEN SET v_dbd_id=v_dbd_id_int; ELSE SET v_dbd_id=''; END IF;

IF v_product="any" THEN SET v_product=""; SET v_xproduct=''; END IF;    -- 18.03.2024
-- ------------------------------------------------------------------------

/*
SELECT `id`,`is_active`,`deal_to_apply`,`MS_id`,`Area`,`Owner`,`Affiliate`,`Campaign`,`Deal`,`Deal_Aff`,`Hour_Update`
,`Date`,`Username`,`Portal`,`Brand`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
,`Qualified_Players`,`Qualified_Players_Adjusted`,`Criteria_Type`,`Level_Reached`
,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Country`,`Brand_Name`,`Registration_Date`
,`Deposits`,`Depositing_Customers`,`Active_Customers`,`New_Depositing_Customers`,`New_Active_Customers`
,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`,`Revenue_Share_Gestor`,`Revenue_Share_Affiliate`
,`CPA_Value_Affiliate`,`CPA_Value_Gestor`
FROM Snapshot_day_by_day_manual
*/
IF  v_dbd_id=''
THEN
   INSERT IGNORE INTO Snapshot_day_by_day_manual (
      `MS_id`
      ,`is_active`
      ,`deal_to_apply`
      ,`Date`
      ,`Product`
      ,`Qualified_Players`
      ,`First_Time_Deposit`
      ,`Views`
      ,`Clicks`
      ,`Signups`
--       ,`Country`
      ,`Deposits`
      ,`Depositing_Customers`
      ,`Active_Customers`
      ,`First_Time_Active_Customers`
      ,`Turnover`
      ,`Net_Revenue`
      ,`Area`
      ,`Username`
      ,`Brand`
      ,`Tracker_ID`
      ,`Tracker_Name`
      ,`Code_To_Affiliate`
      ,`Product_Real`
   )
   SELECT
       v_ms_id                       AS `MS_id`
      ,v_is_active                   AS `is_active`
      ,v_deal_to_apply               AS `deal_to_apply`
      ,v_date                        AS `Date`
      ,case when v_product=""                                 -- 18.03.2024
            then M.`Product`                                 -- 18.03.2024
            else  v_product end      AS `Product`             -- 18.03.2024
      ,v_qualified_players           AS `Qualified_Players`
      ,v_first_time_deposit          AS `First_Time_Deposit`
      ,v_views                       AS `Views`
      ,v_clicks                      AS `Clicks`
      ,v_signups                     AS `Signups`
--       ,M.`Country`                  AS `Country`
      ,v_deposits                    AS `Deposits`
      ,v_depositing_customers        AS `Depositing_Customers`
      ,v_active_customers            AS `Active_Customers`
      ,v_first_time_active_customers AS `First_Time_Active_Customers`
      ,v_turnover                    AS `Turnover`
      ,v_net_revenue                 AS `Net_Revenue`
      ,CU.`Area`                    AS `Area`
      ,M.`Username_id`              AS `Username`
      ,AD.`Advertiser_Name`         AS `Brand`
      ,M.`Tracker_ID`               AS `Tracker_ID`
      ,M.`Tracker_Name`             AS `Tracker_Name`
      ,M.`Code_To_Affiliate`        AS `Code_To_Affiliate`
      ,M.`Product`                  AS `Product_Real`
   FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU`   ON `CU`.`id` = `M`.`Username_id`
   LEFT JOIN `campaign_advertiser` `AD` ON `AD`.`id` = `CU`.`Advertiser_id`
   WHERE `M`.`id` = v_ms_id
	;
ELSE
   UPDATE Snapshot_day_by_day_manual D
   SET  `is_active`                   =IF(v_xis_active                   ="x",v_is_active                   ,is_active                  )
       ,`deal_to_apply`               =IF(v_xdeal_to_apply               ="x",v_deal_to_apply               ,deal_to_apply              )
       ,`Date`                        =IF(v_xdate                        ="x",v_date                        ,Date                       )
       ,`Product`                     =(case when v_product!=""    then v_product                         -- 18.03.2024
                                             WHEN `Product`="any" then `Product_Real`                   -- 18.03.2024
                                             else `Product` end)                                        -- 18.03.2024
       ,`Qualified_Players`           =IF(v_xqualified_players           ="x",v_qualified_players           ,Qualified_Players          )
       ,`First_Time_Deposit`          =IF(v_xfirst_time_deposit          ="x",v_first_time_deposit          ,First_Time_Deposit         )
       ,`Views`                       =IF(v_xviews                       ="x",v_views                       ,Views                      )
       ,`Clicks`                      =IF(v_xclicks                      ="x",v_clicks                      ,Clicks                     )
       ,`Signups`                     =IF(v_xsignups                     ="x",v_signups                     ,Signups                    )
       ,`Deposits`                    =IF(v_xdeposits                    ="x",v_deposits                    ,Deposits                   )
       ,`Depositing_Customers`        =IF(v_xdepositing_customers        ="x",v_depositing_customers        ,Depositing_Customers       )
       ,`Active_Customers`            =IF(v_xactive_customers            ="x",v_active_customers            ,Active_Customers           )
       ,`First_Time_Active_Customers` =IF(v_xfirst_time_active_customers ="x",v_first_time_active_customers ,First_Time_Active_Customers)
       ,`Turnover`                    =IF(v_xturnover                    ="x",v_turnover                    ,Turnover                   )
       ,`Net_Revenue`                 =IF(v_xnet_revenue                 ="x",v_net_revenue                 ,Net_Revenue                )
   WHERE D.id=v_dbd_id
   ;
END IF;

IF UPPER(v_debug)="YES" THEN SELECT v_xdbd_id,v_xms_id,v_xis_active,v_xdeal_to_apply,v_xdate,v_xproduct,v_xqualified_players;           END IF;
IF UPPER(v_debug)="YES" THEN SELECT v_xfirst_time_deposit,v_xviews,v_xclicks,v_xsignups,v_xdeposits,v_xdepositing_customers; END IF;
IF UPPER(v_debug)="YES" THEN SELECT v_xactive_customers,v_xfirst_time_active_customers,v_xturnover,v_xnet_revenue;                   END IF;
IF UPPER(v_debug)="YES" THEN SELECT v_ms_id,v_dbd_id_int,v_is_active,v_date,v_product,v_qualified_players,v_first_time_deposit,v_views,v_clicks
                           ,v_signups,v_deposits,v_depositing_customers,v_active_customers,v_first_time_active_customers
                           ,v_turnover,v_net_revenue; END IF;

END;
//
DELIMITER ;

/*
-- -----------------------------------------------------
Ejemplos:

CALL Set_record_dbd_manual ('is_active=2,deal_to_apply=1,Clicks=-120
 , Date=2026-01-15
 , Deposits=-25, First_Time_Deposit=-2, MS_id=5729
 , Net_Revenue=-20, Qualified_Players=-2, Signups=-2
 ,debug=yes');

TRUNCATE TABLE Snapshot_day_by_day_manual;
-- add Rec 1 a 3
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=0,MS_id=568,date=2023-02-01,Product=Sport ,Country=CO,Qualified_Players=1,Net_Revenue=1121.10,debug=yes');
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=1,MS_id=568,date=2023-02-02,Product=Sport ,Country=MX,Qualified_Players=2,Net_Revenue=2221.20,debug=yes');
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=2,MS_id=568,date=2023-02-03,Product=Sport ,Country=AR,Qualified_Players=3,Net_Revenue=3321.30,debug=yes');
-- add Rec 4 a 6                                                                                 
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=0,MS_id=568,date=2023-02-04,Product=Sport ,Country=ES,Qualified_Players=4,Net_Revenue=4421.40,debug=yes');
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=1,MS_id=568,date=2023-02-05,Product=Sport ,Country=IT,Qualified_Players=5,Net_Revenue=5521.50,debug=yes');
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=2,MS_id=568,date=2023-02-06,Product=Sport ,Country=US,Qualified_Players=6,Net_Revenue=6621.60,debug=yes');
-- add Rec 7 a 9                                                                                 
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=0,MS_id=568,date=2023-02-04,Product=Sport ,Country=ES,Qualified_Players=4,Net_Revenue=4421.40,debug=yes');
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=1,MS_id=568,date=2023-02-05,Product=Sport ,Country=IT,Qualified_Players=5,Net_Revenue=5521.50,debug=yes');
CALL Set_record_dbd_manual ('is_active=0,deal_to_apply=2,MS_id=568,date=2023-02-06,Product=Sport ,Country=US,Qualified_Players=6,Net_Revenue=6621.60,debug=yes');
-- edit Rec 7 a 9
CALL Set_record_dbd_manual ('dbd_id=7,is_active=0,deal_to_apply=0,MS_id=568 ,date=2023-02-14 ,Product=Sport,Country=ES,Qualified_Players=1,Net_Revenue=0421.40,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=8,is_active=0,deal_to_apply=1,MS_id=568 ,date=2023-02-15 ,Product=Sport,Country=IT,Qualified_Players=1,Net_Revenue=0521.50,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=9,is_active=0,deal_to_apply=2,MS_id=568 ,date=2023-02-16 ,Product=Sport,Country=US,Qualified_Players=1,Net_Revenue=0621.60,debug=yes');
-- edit Rec 7 a 9 solo cambia is_active
CALL Set_record_dbd_manual ('dbd_id=7,is_active=1,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=8,is_active=1,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=9,is_active=1,debug=yes');

CALL Set_record_dbd_manual ('MS_id=569, date=2023-01-24 ,Product=Sport, Country=MX, Qualified_Players=2, Net_Revenue=521.50, is_active=1, First_Time_Deposit=0, Views=0,Clicks=0, Signups=0');

-- -----------------------------------------------------
-- add Rec 1 a 3
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=0,MS_id=1932,date=2024-03-01,Product=Sport,Qualified_Players=1,Net_Revenue=1121.10,debug=yes');
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=1,MS_id=1932,date=2024-03-02,Qualified_Players=2,Net_Revenue=2221.20,debug=yes');
CALL Set_record_dbd_manual ('is_active=1,deal_to_apply=2,MS_id=1932,date=2024-03-03,Product=any,Qualified_Players=3,Net_Revenue=3321.30,debug=yes');

CALL Set_record_dbd_manual ('dbd_id=1,is_active=1,deal_to_apply=0,MS_id=1932,date=2024-03-11,Product=Sport,Qualified_Players=1,Net_Revenue=1121.10,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=2,is_active=1,deal_to_apply=0,MS_id=1932,date=2024-03-12,Qualified_Players=2,Net_Revenue=2221.20,debug=yes');
CALL Set_record_dbd_manual ('dbd_id=3,is_active=1,deal_to_apply=0,MS_id=1932,date=2024-03-13,Product=any,Qualified_Players=3,Net_Revenue=3321.30,debug=yes');








*/
