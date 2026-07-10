/*
PROCEDURE_Dash_Gestor_TotalByAdvertiser.sql - Dashboard Gestor Performance por Advertiser

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:

MasterAff_id    =[ MasterAff_id ]. SOLO PARA MAF EN MODO MAF. Default=''
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Month           =[AAAA-MM].            OPCIONAL. Default=Current Month.
Area            =[ALL | forex | gaming ]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | Publisher_id]. OPCIONAL. Default=ALL
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
Brand           =[ALL | NOMBRE de Brand]. OPCIONAL. Default=ALL
Currency        =[EUR | Original].     Moneda a la que se convierten los resultados. Original  No hace conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
ByAccount       =[No | Yes]. OPCIONAL. Default=No
OnlyOverCap     =[No | Yes]. OPCIONAL. Default=No
OrderBy         =[CPA | CPAvalue | Profit | Brand | Publisher]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc
ShowDate        =[Yes | No]. Incluye columna Date en resultado. OPCIONAL. Default=Yes
ShowOwner       =[Yes | No]. Incluye columna Owner en resultado. OPCIONAL. Default=Yes
Total           =[Yes | No]. Incluye línea/s de Totales x OWNER/Currency. OPCIONAL. Default=Yes
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Rec_log         =[Yes | No | NOW ]. Guarda la primera fila de todas las columnas del grid en un una tabla. 
                                    NOW=Crea una tabla temporal con el resultado
                                    OPCIONAL. Default=no

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query. [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Dash_Gestor_TotalByAdvertiser_dev('Debug=ye'); -- Asumirá todos los defaults
call Dash_Gestor_TotalByAdvertiser_dev('Debug=ye,publisher_id=17');
call Dash_Gestor_TotalByAdvertiser_dev('month=CM,publisher_id=80,Debug=ye'); -- Asumirá todos los defaults

*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DROP PROCEDURE IF EXISTS Dash_Gestor_TotalByAdvertiser_dev;
-- DROP PROCEDURE IF EXISTS Dash_Gestor_TotalByAdvertiser;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_Gestor_TotalByAdvertiser_dev`(IN
   InputCommLine    VARCHAR(250)
   )
COMMENT 'Dashboard Gestor/MAF. PERFORMANCE Advertiser/Account - Currency conversion'

BEGIN

-- Defaults
SET @Version      ='v4.8 20.03.2026';
SET @Owner        ='ALL';
SET @Month        =LEFT(CURDATE(),7);
SET @Month        =IF(DAY(CURDATE())<=5,LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),LEFT(CURDATE(),7));
SET @MasterAff_id ='';
SET @Advertiser_id='ALL';
SET @Brand        ='ALL';
SET @Area         ='ALL';
SET @Publisher_id ='ALL';
SET @Currency     ='EUR';
SET @ByAccount    ='NO';
SET @Rec_log      ='NO';
SET @Rec_log_NOW  ="NO";
SET @OrderBy      ='CPA';
SET @Order        ='DESC';
SET @Total        ='YES';
SET @TotLine      ='FIRST';
SET @Debug        ='NO';
SET @Meta         ='YES';
SET @ShowDate     ='YES';
SET @ShowOwner    ='YES';
SET @OnlyOverCap  ='NO';
SET @Filters      ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit
-- @InputCommLine: ----5----0----5----0----5----0----5----0--
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   IF lower(@k)='owner'         THEN SET @Owner        =UPPER(@v); END IF;
   IF lower(@k)='month'         THEN SET @Month        =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;
   IF lower(@k)='rec_log'       THEN SET @Rec_log      =UPPER(@v); END IF;
   IF lower(@k)='area'          THEN SET @Area         =UPPER(@v); END IF;
   IF lower(@k)='masteraff_id'  THEN SET @MasterAff_id =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id' THEN SET @Advertiser_id=UPPER(@v); END IF;
   IF lower(@k)='brand'         THEN SET @Brand        =UPPER(@v); END IF;
   IF lower(@k)='currency'      THEN SET @Currency     =UPPER(@v); END IF;
   IF lower(@k)='byaccount'     THEN SET @ByAccount    =UPPER(@v); END IF;
   IF lower(@k)='showdate'      THEN SET @ShowDate     =UPPER(@v); END IF;
   IF lower(@k)='showowner'     THEN SET @ShowOwner    =UPPER(@v); END IF;
   IF lower(@k)='orderby'       THEN SET @OrderBy      =UPPER(@v); END IF;
   IF lower(@k)='order'         THEN SET @Order        =UPPER(@v); END IF;
   IF lower(@k)='total'         THEN SET @Total        =UPPER(@v); END IF;
   IF lower(@k)='totline'       THEN SET @TotLine      =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;
   IF lower(@k)='onlyovercap'   THEN SET @OnlyOverCap  =UPPER(@v); END IF;
   IF lower(@k)='publisher_id'  THEN SET @Publisher_id =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Owner,@Month,@Currency,@OnlyOverCap,@Advertiser_id,@Brand,@ByAccount,@Rec_log
                           ,@Debug,@Meta,@Total,@TotLine,@OrderBy,@Order,@ShowDate,@ShowOwner,InputCommLine; END IF;

/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET @MasterAffGroup=(SELECT group_id FROM account_account_groups
                     WHERE account_id=@MasterAff_id AND group_id=4);
IF  @MasterAffGroup IS NULL THEN SET @MasterAffGroup=0; END IF;

SET @Affiliate_list="";
IF  @MasterAffGroup=4 THEN
    CALL Master_Sub_Affiliate(@MasterAff_id,@Affiliate_list);
END IF;

SET @WhereAffiliate_list='';
IF  @MasterAffGroup=4 THEN
    SET @WhereAffiliate_list=CONCAT(" AND Affiliate_id IN ",@Affiliate_list);
END IF;

IF @Debug!="NO" THEN SELECT @MasterAff_id,@MasterAffGroup,@WhereAffiliate_list; END IF;

/*---------------------------------------------------------------------------------*/

/**************************************************************************************************************/

SET @WhereAdvertiserID='';
SET @WhereBrand='';
SET @WhereOwner='';
SET @WherePublisher_id='';
SET @WherePublisher_id_A='';
SET @WhereArea='';
SET @HavingOverCap='';

IF @Advertiser_id!="ALL" THEN SET @WhereAdvertiserID=CONCAT(" AND G.Advertiser_id='",@Advertiser_id,"'"); END IF;
IF @Brand        !="ALL" THEN SET @WhereBrand=CONCAT(" AND G.Brand='",@Brand,"'");                        END IF;
IF @Owner        !="ALL" THEN SET @WhereOwner=CONCAT(" AND G.Owner='",@Owner,"'");                        END IF;
IF @Publisher_id !="ALL" THEN SET @WherePublisher_id_A=CONCAT(" AND A.Publisher_id='",@Publisher_id,"'"); END IF;
IF @Publisher_id !="ALL" THEN SET @WherePublisher_id  =CONCAT(" AND G.Publisher_id='",@Publisher_id,"'"); END IF;
IF @Area         !="ALL" THEN SET @WhereArea=CONCAT(" AND G.Area='",@Area,"'");                           END IF;

IF @OnlyOverCap="YES" THEN SET @HavingOverCap=' HAVING UsedLim>=0.8 '; END IF;

IF @Debug!="NO" THEN SELECT @WhereAdvertiserID,@WhereBrand,@WhereOwner,@WherePublisher_id_A,@WherePublisher_id,@WhereArea,@HavingOverCap,@OnlyOverCap; END IF;  

-- Toma de datos para campaign_log_dashboard - @Rec_log="NOW" es para comparación con la situación del momento
IF @Rec_log="NOW" 
THEN SET @Rec_log_NOW="YES";
     SET @Rec_log="YES";
END IF;     

SET @Month_Report=@Month;
IF  @Month = "CM" THEN SET @Month_Report=LEFT(CURDATE(),7); END IF;                             -- K 16.03.2023
IF  @Month = "LM" THEN SET @Month_Report=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF; -- K 16.03.2023

-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @GridCurrency =(SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');
-- -----------------------------------------------------------------------------------------------------

IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@GridCurrency); END IF;
-- ----------------------------------------------------
-- TRATAMIENTO DE TOTALES Y ORDER----------------------
-- ----------------------------------------------------
SET @RollUp=UPPER(@Total);      -- Variable de entrada
SET @OrderBy=UPPER(@OrderBy);   -- Variable de entrada

SET @OrderByClause='';          -- Variable a aplicar

IF @Total='YES' THEN
   IF @TotLine='LAST'
   THEN SET @OrderByClause=' ORDER BY Date';
   ELSE SET @OrderByClause=' ORDER BY Date DESC';
   END IF;
END IF;

IF @Total='YES' THEN
   IF  @ShowDate='NO' THEN
       IF  @TotLine='LAST' THEN SET @OrderByClause=' ORDER BY Brand DESC';
                           ELSE SET @OrderByClause=' ORDER BY Brand';
       END IF;
   END IF;
END IF;

IF  @OrderBy="CPA"       THEN SET @OrderByClause=CONCAT(@OrderByClause,',convert(REPLACE(`CPA`      ,",",""),signed) ',@Order); END IF;
IF  @OrderBy="PROFIT"    THEN SET @OrderByClause=CONCAT(@OrderByClause,',convert(REPLACE(`Profit`   ,",",""),signed) ',@Order); END IF;
IF  @OrderBy="CPAVALUE"  THEN SET @OrderByClause=CONCAT(@OrderByClause,',convert(REPLACE(`CPA_Value`,",",""),signed) ',@Order); END IF;
IF  @OrderBy="BRAND"     THEN SET @OrderByClause=CONCAT(@OrderByClause,',`Brand` ',@Order);                     END IF;
IF  @OrderBy="PUBLISHER" THEN SET @OrderByClause=CONCAT(@OrderByClause,',`Publisher` ',@Order);                 END IF;

SET @Kforex=(
-- >>>>>>> FILTRO POR SUBAFF <<<<<<<<
   SELECT COUNT(*) FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU` ON `CU`.`id` = `M`.`Username_id`
   WHERE CU.Area="forex" and @MasterAffGroup!=4
);

SET @K_Owner=(SELECT COUNT(distinct Owner) FROM Snapshot_day_by_day_fact1 WHERE LEFT(Date,7)=@Month_Report);

IF @Debug!="NO" THEN SELECT @Kforex,@K_Owner FROM DUAL; END IF;

-- -----------------------------------------------------------------------------------------------------
-- SET SESSION group_concat_max_len = 200000;

SET @SQLmeta=CONCAT(
' UNION ALL (
SELECT
   "setting"
   ," width=100px,omit=true"              `Date`    -- OjO: el blanco delante de width es para el ORDEN BY final
   ,"width=100px,omit=true"               `Owner_id`
   ,"width=100px,"                        `Owner`
   ,"',IF(@MasterAffGroup=4,"omit=true","width=150px,sortable=yes,action=4"),'" as `Publisher`  -- K 20.01.2025
   ,"width=130px,sortable=yes"            `Brand`
   ,"',IF(@MasterAffGroup=4,"omit=true","width=080px"),'" as `StatAdv`
   ,"',IF(@ByAccount="YES","width=200px","omit=true"),'"  as `Usrn`
   ,"',IF(@ByAccount="YES","width=90px","omit=true"),'"   as `StatAcct`
   ,"width=070px"                         `Curr`
   ,"',IF(@MasterAffGroup=4,"omit=true","width=080px,center=true"),'" as `CapUsed`
   ,"width=80px,right=true,sortable=yes"  `sup`
   ,"width=80px,right=true,sortable=yes"  `ftd`
   ,"width=80px,right=true,sortable=yes"  `cpa`
   ,"width=110px,right=true,sortable=yes" `cpaval`
   ,"width=110px,right=true"              `nr`
   ,"width=110px,right=true"              `rsval`
   ,"width=110px,right=true"              `totcomm`
   ,"',IF(@ByAccount="YES","omit=true","width=110px,right=true,sortable=yes"),'" `profit`
   ,"',IF(@ByAccount="YES","omit=true","width=080px"),'"            `afcurr`
   ,"',IF(@ByAccount="YES","omit=true","width=110px,right=true"),'" `AfCom_cpa`
   ,"',IF(@ByAccount="YES","omit=true","width=110px,right=true"),'" `AfCom_rs`
   ,"',IF(@ByAccount="YES","omit=true","width=110px,right=true"),'" `AfCom_tot`
   ,"width=80px,right=true"     `AfCPA`
   ,"width=80px,right=true"     `AfRS`
   ,"width=80px,right=true"     `Area`
   ,"',IF(@MasterAffGroup=4,"omit=true","width=110px,right=true"),'" as `RS_CarryOver_Pend`
   ,"omit=true" `Publisher_id`           -- K 20.01.2025
	FROM DUAL WHERE ',QUOTE(@Meta),'="YES")'
);
-- select @SQLmeta;
-- -------------------------------
SET @SQL_GrandTotal=CONCAT('
(SELECT '
   ,IF(@Meta="YES","'total' as `Meta`,",""),'
    IF(@Rec_log_NOW="YES","TOTAL NOW","TOTAL") 
   ,CASE WHEN @Rec_log="YES" THEN CONCAT(@Month_Report," ",(LEFT(NOW(),16))) ELSE "" END AS Date
   -- ,CASE WHEN @Rec_log="YES" THEN (LEFT(NOW(),16)) ELSE "" END AS Date
   -- ,IF(@Rec_log="YES",(LEFT(NOW(),16)),"") AS Date
   ,"All Owners" -- S.Owner
   ," "
   ," GRAND TOTAL"
   ," "
   ," "
   ," "
   ,S.Data_Currency
   -- ,"~~~~~"
   ," "
   ,format(sum(S.Signup),0)           as `Signup`
   ,format(sum(S.FTD),0)              as `FTD`
   ,format(sum(S.CPA),0)              as `CPA`
   ,format(sum(S.CPA_Value       ),2) as CPA_Value
   ,format(sum(S.Net_Revenue     ),2) as Net_Revenue
   ,format(sum(S.RS_AJUST        ),2) as RS_AJUST
   -- ,format(sum(S.CPA_Val_AJ_RS   ),2) as CPA_Val_AJ_RS
   ,format(sum(S.Total_Commission),2) as Total_Commission
   ,format(sum(S.Total_Commission)-sum(T.Aff_Comm_TOT),2) AS `Profit`
   -- ,"~~~~~"
   -- ,"~~~~~"
   ,"~~~~~" -- ifnull(T.Data_Currency,"")
   ,format(sum(T.Aff_Comm_CPA),2) AS Aff_Comm_CPA
   ,format(sum(T.Aff_Comm_RS ),2) AS Aff_Comm_RS
   ,format(sum(T.Aff_Comm_TOT),2) AS Aff_Comm_TOT
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~" -- K 20.01.2025
   FROM ',IF(@MasterAffGroup=4,"SetCommConverted_maf","SetCommConverted_ges"),' S
   LEFT JOIN LATERAL (
      SELECT
          IFNULL(Aff_Comm_CPA,0)   as Aff_Comm_CPA
         ,IFNULL(Aff_Comm_RS ,0)   as Aff_Comm_RS
         ,IFNULL(Aff_Comm_TOT,0)   as Aff_Comm_TOT
      FROM ',IF(@MasterAffGroup=4,"SetCommConverted_sub","SetCommConverted_aff"),' T
      WHERE S.Username_id=T.Username_id
      ',IF(@Currency_result="ALL",' AND S.Data_Currency=T.Data_Currency',''), '
   ) as T on TRUE
   WHERE 1=1 '
   ,IF(@Currency_result="ALL"," GROUP by S.Data_Currency",""),
	'
)
UNION ALL
');

IF @K_Owner=1 THEN SET @SQL_GrandTotal=""; END IF;

SET @SQLinsert='';

IF @Rec_log="YES"     THEN SET @SQLinsert='INSERT INTO campaign_log_dashboard '; END IF;
IF @Rec_log_NOW="YES" THEN SET @SQLinsert='CREATE TEMPORARY TABLE campaign_log_dashboard_temp '; END IF;

DROP TEMPORARY TABLE IF EXISTS campaign_log_dashboard_temp;

-- -------------------------------
SET @Main_SQL = CONCAT('
WITH
SetFact_ges as (
   SELECT
      G.Owner     as Owner_id
     ,AC.username as Owner
     ,DATE,Area
     ,Publisher_id
     ,Brand,Advertiser_id
     ,Username_id
     ,G.Username
     ,G.Data_Currency
     ,sum(IFNULL(Qualified_Players,0) ) AS CPA
     ,sum(IFNULL(First_Time_Deposit,0)) AS FTD
     ,sum(IFNULL(Views,0)             ) AS Views
     ,sum(IFNULL(Clicks,0)            ) AS Clicks
     ,sum(IFNULL(Signups,0)           ) AS Signups
   FROM Snapshot_day_by_day_fact1 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(DATE,7) =',CONCAT("'",@Month_Report,"' ")
      ,@WhereAffiliate_list
      ,@WherePublisher_id
      ,@WhereAdvertiserID
      ,@WhereOwner
      ,@WhereArea,'
   GROUP BY G.Owner,Username_id
),
commissions_ges AS (
    SELECT
        g.Month,
        g.Owner,
        g.Area,
        g.Publisher_id,
        g.Advertiser_id,
        g.Brand,
        g.Username_id,
        g.`Data_Currency`,
        SUM(IFNULL(g.CPA, 0))                 AS ges_cpa,
        SUM(IFNULL(g.Net_Revenue, 0))         AS ges_revenue,
        SUM(IFNULL(g.net_CPA_Val, 0))         AS ges_cpa_val,
        SUM(IFNULL(g.net_RS_Val, 0))          AS ges_rs_val,
        SUM(IFNULL(g.net_Total_comm, 0))      AS ges_total_comm,
        SUM(IFNULL(g.RS_CarryOver_Pend, 0))   AS ges_RS_CarryOver_Pend
    FROM monthly_comms_gestor_v5 g
    WHERE g.Month = ',CONCAT("'",@Month_Report,"' "), '
    GROUP BY g.Month, g.Brand, g.Username_id
),
commissions_aff AS (
    SELECT
        a.Month,
        a.Owner,
        U.Area,
        U.Publisher_id,
        a.Advertiser_id,
        a.Brand,
        a.Account_id,
        a.`Currency`,
        SUM(IFNULL(a.CPA, 0))             AS aff_cpa,
        SUM(IFNULL(a.Net_Revenue, 0))     AS aff_revenue,
        SUM(IFNULL(a.net_CPA_Val, 0))     AS aff_cpa_val,
        SUM(IFNULL(a.net_RS_Val, 0))      AS aff_rs_val,
        SUM(IFNULL(a.net_Total_comm, 0))  AS aff_total_comm
    FROM monthly_comms_affiliate_v5 a
    LEFT JOIN `campaign_username` U ON U.id=a.Account_id
    WHERE a.Month = ',CONCAT("'",@Month_Report,"' "), '
    GROUP BY a.Month, a.Brand, a.Account_id
),
commissions_ges_aff as (
   SELECT
       g.Month,
       g.Owner,
       g.Area,
       g.Publisher_id,
       g.Advertiser_id,
       g.Brand,
       g.Username_id,
       g.Data_Currency,
       g.ges_cpa                    AS ges_cpa,
       g.ges_revenue                AS ges_revenue,
       g.ges_cpa_val                AS ges_cpa_val,
       g.ges_rs_val                 AS ges_rs_val,
       g.ges_total_comm             AS ges_total_comm,
       g.ges_RS_CarryOver_Pend      AS ges_RS_CarryOver_Pend,
       ifnull(a.Currency, "EUR")    AS Currency,
       ifnull(a.aff_cpa, 0)         AS aff_cpa,
       ifnull(a.aff_revenue, 0)     AS aff_revenue,
       ifnull(a.aff_cpa_val, 0)     AS aff_cpa_val,
       ifnull(a.aff_rs_val, 0)      AS aff_rs_val,
       ifnull(a.aff_total_comm, 0)  AS aff_total_comm
   FROM commissions_ges g
   LEFT JOIN commissions_aff a
       ON a.Month = g.Month
      AND a.Brand = g.Brand
      AND a.Account_id = g.Username_id
   -- ORDER BY g.Month DESC, g.Brand, g.Username_id
),
Complete_Table as (
SELECT
    g.Owner_id,
    g.Area,
    g.Publisher_id,
    g.Advertiser_id,
    g.Brand,
    g.Username_id,
    g.Data_Currency,
    g.CPA,
    g.FTD,
    g.Views,
    g.Clicks,
    g.Signups,
    cga.Currency,
    cga.ges_cpa,
    cga.ges_revenue,
    cga.ges_cpa_val,
    cga.ges_rs_val,
    cga.ges_total_comm,
    cga.ges_RS_CarryOver_Pend,
    cga.aff_cpa,
    cga.aff_revenue,
    cga.aff_cpa_val,
    cga.aff_rs_val,
    cga.aff_total_comm
FROM SetFact_ges g 
LEFT JOIN commissions_ges_aff cga ON g.Username_id = cga.Username_id
),
Final_Table as (
SELECT 
   ft.Owner_id,
   AC.username as Owner,
   ft.Area,
   ft.Publisher_id,
   PP.Advertiser_name AS `Publisher` ,
   ft.Advertiser_id,
   AD.Advertiser_name AS `Advertiser` ,
   ft.Brand,
   ft.Username_id,
   UN.username AS Account,
   ft.Data_Currency,
   SUM(ft.CPA) as `CPA` ,
   SUM(ft.FTD) as `FTD` ,
   SUM(ft.Views) as `Views` ,
   SUM(ft.Clicks) as `Clicks` ,
   SUM(ft.Signups) as `Signups` ,
   ft.Currency as `Currency` ,
   SUM(ft.ges_cpa) as `ges_cpa` ,
   SUM(ft.ges_revenue) as `ges_revenue` ,
   SUM(ft.ges_cpa_val) as `ges_cpa_val` ,
   SUM(ft.ges_rs_val) as `ges_rs_val` ,
   SUM(ft.ges_total_comm) as `ges_total_comm` ,
   SUM(ft.ges_RS_CarryOver_Pend) as `ges_RS_CarryOver_Pend` ,
   SUM(ft.aff_cpa) as `aff_cpa` ,
   SUM(ft.aff_revenue) as `aff_revenue` ,
   SUM(ft.aff_cpa_val) as `aff_cpa_val` ,
   SUM(ft.aff_rs_val) as `aff_rs_val` ,
   SUM(ft.aff_total_comm) as `aff_total_comm`

FROM Complete_Table ft
LEFT JOIN account_account AC ON AC.id=ft.Owner_id
LEFT JOIN campaign_publisher PP ON PP.id=ft.Publisher_id
LEFT JOIN campaign_advertiser AD ON AD.id=ft.Advertiser_id
LEFT JOIN campaign_username UN ON UN.id=ft.Username_id
GROUP BY ft.Owner_id, ft.Publisher_id, ft.Advertiser_id -- , ft.Brand, ft.Username_id, ft.Data_Currency, ft.Currency
)
-- SELECT * FROM commissions_ges;
-- SELECT * FROM commissions_aff;
-- SELECT * FROM commissions_ges_aff;
-- SELECT * FROM Complete_Table;

-- por Brand
SELECT 
   Owner_id,
   Owner,
   Area,
   Publisher_id,
   `Publisher` ,
   `Advertiser_id`,
   Advertiser,
   Brand,
   "^^^^^^^" as `Username_id`,
   "^^^^^^^" as `Account`,
   Data_Currency,
   SUM(CPA) as `CPA` ,
   SUM(FTD) as `FTD` ,
   SUM(Views) as `Views` ,
   SUM(Clicks) as `Clicks` ,
   SUM(Signups) as `Signups` ,
   Currency as `Currency` ,
   SUM(ges_cpa) as `ges_cpa` ,
   SUM(ges_revenue) as `ges_revenue` ,
   SUM(ges_cpa_val) as `ges_cpa_val` ,
   SUM(ges_rs_val) as `ges_rs_val` ,
   SUM(ges_total_comm) as `ges_total_comm` ,
   SUM(ges_RS_CarryOver_Pend) as `ges_RS_CarryOver_Pend` ,
   SUM(aff_cpa) as `aff_cpa` ,
   SUM(aff_revenue) as `aff_revenue` ,
   SUM(aff_cpa_val) as `aff_cpa_val` ,
   SUM(aff_rs_val) as `aff_rs_val` ,
   SUM(aff_total_comm) as `aff_total_comm`
FROM Final_Table ft
GROUP BY Owner_id, Publisher_id, Brand
union all
-- Por Publisher
SELECT 
   Owner_id,
   Owner,
   Area,
   Publisher_id,
   `Publisher` ,
   "^^^^^^^" as `Advertiser_id`,
   "^^^^^^^" as `Advertiser`,
   "^^^^^^^" as `Brand`,
   "^^^^^^^" as `Username_id`,
   "^^^^^^^" as `Account`,
   Data_Currency,
   SUM(CPA) as `CPA` ,
   SUM(FTD) as `FTD` ,
   SUM(Views) as `Views` ,
   SUM(Clicks) as `Clicks` ,
   SUM(Signups) as `Signups` ,
   Currency as `Currency` ,
   SUM(ges_cpa) as `ges_cpa` ,
   SUM(ges_revenue) as `ges_revenue` ,
   SUM(ges_cpa_val) as `ges_cpa_val` ,
   SUM(ges_rs_val) as `ges_rs_val` ,
   SUM(ges_total_comm) as `ges_total_comm` ,
   SUM(ges_RS_CarryOver_Pend) as `ges_RS_CarryOver_Pend` ,
   SUM(aff_cpa) as `aff_cpa` ,
   SUM(aff_revenue) as `aff_revenue` ,
   SUM(aff_cpa_val) as `aff_cpa_val` ,
   SUM(aff_rs_val) as `aff_rs_val` ,
   SUM(aff_total_comm) as `aff_total_comm`
FROM Final_Table ft
GROUP BY Owner_id, Publisher_id
union all
-- Por Owner
SELECT 
   Owner_id,
   Owner,
   Area,
   "^^^^^^^" as `Publisher_id`,
   "^^^^^^^" as `Publisher` ,
   "^^^^^^^" as `Advertiser_id`,
   "^^^^^^^" as `Advertiser`,
   "^^^^^^^" as `Brand`,
   "^^^^^^^" as `Username_id`,
   "^^^^^^^" as `Account`,
   Data_Currency,
   SUM(CPA) as `CPA` ,
   SUM(FTD) as `FTD` ,
   SUM(Views) as `Views` ,
   SUM(Clicks) as `Clicks` ,
   SUM(Signups) as `Signups` ,
   Currency as `Currency` ,
   SUM(ges_cpa) as `ges_cpa` ,
   SUM(ges_revenue) as `ges_revenue` ,
   SUM(ges_cpa_val) as `ges_cpa_val` ,
   SUM(ges_rs_val) as `ges_rs_val` ,
   SUM(ges_total_comm) as `ges_total_comm` ,
   SUM(ges_RS_CarryOver_Pend) as `ges_RS_CarryOver_Pend` ,
   SUM(aff_cpa) as `aff_cpa` ,
   SUM(aff_revenue) as `aff_revenue` ,
   SUM(aff_cpa_val) as `aff_cpa_val` ,
   SUM(aff_rs_val) as `aff_rs_val` ,
   SUM(aff_total_comm) as `aff_total_comm`
FROM Final_Table ft
GROUP BY Owner_id
union all
-- total general
SELECT 
   "^^^^^^^" as `Owner_id`,
   "^^^^^^^" as `Owner`,
   "^^^^^^^" as `Area`,
   "^^^^^^^" as `Publisher_id`,
   "^^^^^^^" as `Publisher` ,
   "^^^^^^^" as `Advertiser_id`,
   "^^^^^^^" as `Advertiser`,
   "^^^^^^^" as `Brand`,
   "^^^^^^^" as `Username_id`,
   "^^^^^^^" as `Account`,
   Data_Currency,
   SUM(CPA) as `CPA` ,
   SUM(FTD) as `FTD` ,
   SUM(Views) as `Views` ,
   SUM(Clicks) as `Clicks` ,
   SUM(Signups) as `Signups` ,
   Currency as `Currency` ,
   SUM(ges_cpa) as `ges_cpa` ,
   SUM(ges_revenue) as `ges_revenue` ,
   SUM(ges_cpa_val) as `ges_cpa_val` ,
   SUM(ges_rs_val) as `ges_rs_val` ,
   SUM(ges_total_comm) as `ges_total_comm` ,
   SUM(ges_RS_CarryOver_Pend) as `ges_RS_CarryOver_Pend` ,
   SUM(aff_cpa) as `aff_cpa` ,
   SUM(aff_revenue) as `aff_revenue` ,
   SUM(aff_cpa_val) as `aff_cpa_val` ,
   SUM(aff_rs_val) as `aff_rs_val` ,
   SUM(aff_total_comm) as `aff_total_comm`
FROM Final_Table ft
ORDER BY Owner, Publisher, Brand,`ges_cpa` desc -- , UN.Username
;');

-- ---------------------------------------------------
IF @Debug!="NO" THEN SELECT @Main_SQL; END IF;
IF @Debug!="NO" THEN SELECT @SQL_meta; END IF;
IF @Debug!="NO" THEN SELECT @SQL_GrandTotal; END IF;

IF @Debug!="YES" THEN
   SET @SQL = @Main_SQL;
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

-- IF @Debug!="NO" AND @Rec_log="YES" THEN SELECT * FROM campaign_log_dashboard_temp; END IF;

END$$
DELIMITER ;

