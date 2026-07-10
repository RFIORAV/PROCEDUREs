SET @Version      ='v4.7 01.08.2024';
SET @Owner        ='ALL';
SET @Month        =LEFT(CURDATE(),7);
SET @Month        =IF(DAY(CURDATE())<=5,LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),LEFT(CURDATE(),7));
SET @Month_Report =@Month;
SET @MasterAff_id ='';
SET @Advertiser_id='ALL';
SET @Brand        ='ALL';
SET @Area         ='ALL';
SET @Publisher_id ='ALL';
SET @Currency     ='EUR';
-- SET @Currency     ='original';
SET @GridCurrency ='USD';
SET @ByAccount    ='NO';
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

-- IF @Debug!="NO" THEN 
SELECT @Owner,@Month,@Month_Report,@MasterAff_id,@Advertiser_id,@Brand,@Area,@Publisher_id,@Currency
                           ,@GridCurrency,@ByAccount,@ShowDate,@ShowOwner,@OnlyOverCap,@Filters;

SET @WhereAffiliate_list="";
SET @WhereAdvertiserID  ="";
SET @WhereBrand         ="";
SET @WhereOwner         ="";
SET @WhereArea          ="";                         




WITH
SetFact_ges as (
   SELECT
      G.Owner     as Owner_id
     ,AC.username as Owner
     ,DATE,Area
     ,Publisher_id
     ,Brand,Advertiser_id
     ,Username_id
     ,'ALL' as Username
     ,sum(IFNULL(Qualified_Players,0) ) AS CPA
     ,sum(IFNULL(First_Time_Deposit,0)) AS FTD
     ,sum(IFNULL(Views,0)             ) AS Views
     ,sum(IFNULL(Clicks,0)            ) AS Clicks
     ,sum(IFNULL(Signups,0)           ) AS Signups
     ,Data_Currency
     ,getCurrencyConversion(1, Data_Currency, IF(lower(@Currency)="original",Data_Currency,@GridCurrency)) as XCH -- FactorToGridCurrency 
   FROM Snapshot_day_by_day_fact1 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(DATE,7) ='2024-07' 
   GROUP BY G.Owner,Brand,Username_id  -- 08.09.2023
), /*
SetFact_maf as (
   SELECT
      G.Owner     as Owner_id
     ,AC.username as Owner
     ,DATE,Area
     ,Publisher_id
     ,Brand,Advertiser_id
     ,Username_id
     ,'ALL' as Username
     ,sum(IFNULL(Qualified_Players,0) ) AS CPA
     ,sum(IFNULL(First_Time_Deposit,0)) AS FTD
     ,sum(IFNULL(Views,0)             ) AS Views
     ,sum(IFNULL(Clicks,0)            ) AS Clicks
     ,sum(IFNULL(Signups,0)           ) AS Signups
     ,DA.Currency
     ,getCurrencyConversion(1,DA.Data_Currency,@GridCurrency) as XCH -- FactorToGridCurrency 
   FROM Snapshot_day_by_day_fact2 G
   LEFT JOIN campaign_deal_affiliate DA ON DA.id=G.Deal_Aff_id
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(DATE,7) ='2024-07' 
   GROUP BY G.Owner,Brand,Username_id  -- 08.09.2023 
), */
SetCommConverted_ges as (
   SELECT
       U.Owner          as Owner_id
      ,AC.username      as `Owner`
      ,U.Area
      ,G.Month          AS Date
      ,G.Brand          as `Brand`
      ,U.id             as Username_id
      ,'ALL' as `Username`
      ,A.Stat_effect    as `StatAdv`
      ,U.Stat_effect    as `StatAcct`
      ,U.Data_Currency as `Data_Currency`
      ,A.CPA_Limit as CPA_Limit
      ,CASE WHEN A.CPA_Limit>0
                   AND SUM(G.CPA)/A.CPA_Limit>=0.8
            THEN ROUND(SUM(G.CPA)/A.CPA_Limit*100,0)
            ELSE 0 END                         as `UsedLim`
      ,sum(Fact.Signups)                       as `Signup`
      ,sum(Fact.FTD)                           as `FTD`
      ,sum(G.CPA)                              as `CPA`
      ,round(sum(net_CPA_Val     ),2)          as `CPA_Value`
      ,round(sum(Net_Revenue     ),2)          as `Net_Revenue`
      ,round(sum(net_RS_Val      ),2)          as `RS_AJUST`
      ,round(sum(net_Total_comm  ),2)          as `Total_Commission`
      ,round(sum(RS_CarryOver_Pend),2)         as `RS_CarryOver_Pend`
      ,G.Publisher
      ,G.Publisher_id
      ,getCurrencyConversion(1,G.Data_Currency,@GridCurrency) as XCH -- FactorToGridCurrency 
      FROM monthly_comms_gestor_v5 G
         LEFT JOIN campaign_username   U     ON U.id=G.Username_id
         LEFT JOIN campaign_advertiser A     ON A.id=U.Advertiser_id
         LEFT JOIN account_account     AC    ON AC.id=U.Owner
         LEFT JOIN SetFact_ges         Fact  ON U.Owner=Fact.Owner_id AND G.Advertiser_id=Fact.Advertiser_id
                                             AND G.Username_id=Fact.Username_id
      WHERE G.Month ='2024-07' 
      GROUP BY U.Owner,U.Data_Currency,Publisher_id,Brand 
      ORDER BY U.Owner,U.Data_Currency,Publisher_id,Brand 
),
SetCommConverted_aff as (
   SELECT G.Owner as Owner_id,AC.username as Owner
     ,DATE,Brand,Advertiser_id,Username_id
     ,'ALL' as Username
     ,G.Data_Currency as Data_Currency
     ,round(SUM(CPA_Value)            ,2) as Aff_Comm_CPA
     ,round(SUM(RS_AJUST)             ,2) as Aff_Comm_RS
     ,round(SUM(CPA_Val_AJ_RS)        
     +SUM(RS_AJUST)                   ,2) as Aff_Comm_TOT
     ,round(`Aff_CPA`                 ,2) as `Aff_CPA`
     ,round(`Aff_RS`,1)                   as `Aff_RS`
     ,getCurrencyConversion(1,G.Data_Currency,@GridCurrency) as XCH -- FactorToGridCurrency     
   FROM view_monthly_fact_aff_v5 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(G.DATE,7) ='2024-07' 
   GROUP BY G.Owner,Brand,Username_id /*
),
SetCommConverted_sub as (
   SELECT G.Owner as Owner_id,AC.username as Owner
     ,DATE,Brand,Advertiser_id,Username_id
     ,'ALL' as Username
     ,G.Data_Currency as Data_Currency
     ,round(SUM(CPA_Value)            ,2) as Aff_Comm_CPA
     ,round(SUM(RS_AJUST)             ,2) as Aff_Comm_RS
     ,round(SUM(CPA_Val_AJ_RS)        
     +SUM(RS_AJUST)                   ,2) as Aff_Comm_TOT
     ,round(`Aff_CPA`                 ,2) as `Aff_CPA`
     ,round(`Aff_RS`,1)                   as `Aff_RS`
     ,getCurrencyConversion(1,G.Data_Currency,@GridCurrency) as XCH -- FactorToGridCurrency 
   FROM sub_view_monthly_fact_aff4 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(G.DATE,7) ='2024-07' 
   GROUP BY G.Owner,Brand,Username_id
), 
SetCommConverted_maf as (
   SELECT G.Owner as Owner_id,AC.username as Owner
     ,G.DATE,G.Brand,G.Advertiser_id,G.Username_id
     ,U.Area
     ,"" AS `Publisher`
     ,A.Stat_effect                       as `StatAdv`
     ,U.Stat_effect                       as `StatAcct`
     ,'ALL' as Username
     ,G.Data_Currency as Data_Currency
     ,round(SUM(CPA_Value)            ,2) as `CPA_Value`
     ,round(SUM(RS_AJUST)             ,2) as `RS_AJUST`
     ,round(SUM(CPA_Val_AJ_RS)        
     +SUM(RS_AJUST)                   ,2) as `Total_Commission`
     ,round(`Aff_CPA`                 ,2) as `Aff_CPA`
     ,round(`Aff_RS`,1)                   as `Aff_RS`   
     ,sum(Fact.Signups)                   as `Signup`
     ,sum(Fact.FTD)                       as `FTD`
     ,sum(G.CPA)                          as `CPA`
     ,round(sum(G.Net_Revenue)/xx.Coef,2) as `Net_Revenue`
     ,0                                   as `RS_CarryOver_Pend`
     ,getCurrencyConversion(1,G.Data_Currency,@GridCurrency) as XCH -- FactorToGridCurrency      
   FROM view_monthly_fact_aff4 G
   LEFT JOIN account_account     AC    ON AC.id=G.Owner
   LEFT JOIN campaign_username   U     ON U.id=G.Username_id
   LEFT JOIN campaign_advertiser A     ON A.id=U.Advertiser_id
   LEFT JOIN SetFact_ges         Fact  ON G.Owner=Fact.Owner_id AND G.Advertiser_id=Fact.Advertiser_id
                                       AND G.Username_id=Fact.Username_id   
   WHERE LEFT(G.DATE,7) ='2024-07' 
   GROUP BY G.Owner,Brand,Username_id */
)

-- SELECT * FROM SetFact_ges;
-- SELECT * FROM SetCommConverted_ges;
-- SELECT * FROM SetCommConverted_aff;

(SELECT 'data' as `Meta`,
    S.Date
   ,S.Owner_id
   ,S.Owner
   ,S.Publisher                                 as `Publisher`
   ,S.Brand                                     as `Brand`
   ,S.StatAdv  as `Status`
   ,S.Username                                  AS `Account`
   ,S.StatAcct  as `Status`
   ,S.Data_Currency                             as `Curr`
   ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(" / ",S.UsedLim," %") ELSE "" END)
   -- ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(" / ",S.UsedLim," %") ELSE "" END)
                                                AS `Cap/Used`
   ,round(sum(S.Signup),0)                      as `Signup`
   ,round(sum(S.FTD),0)                         as `FTD`
   ,round(sum(S.CPA),0)                         as `CPA`
   ,round(sum(S.CPA_Value*S.XCH       ),2)            as `CPA_Value`  -- `CPA Commiss`
   ,round(sum(S.Net_Revenue*S.XCH     ),2)            as Net_Rev      -- `Net Revenue`
   ,round(sum(S.RS_AJUST*S.XCH        ),2)            as RS_Val       -- `R Share Commiss`
   -- ,round(sum(S.CPA_Val_AJ_RS   ),2)         as CPA_Val_AJ_RS
   ,round(sum(S.Total_Commission*S.XCH),2)            as Tot_Comm     -- `TOTAL Commiss`
   ,CASE WHEN S.Data_Currency=ifnull(T.Data_Currency,"EUR")
         THEN (round(sum(S.Total_Commission)-sum(ifnull(T.Aff_Comm_TOT,0)),2))
         ELSE (round(sum(S.Total_Commission),2)) END AS `Profit`
   -- ,round(S.Ges_CPA              ,2)         as Ges_CPA
   -- ,round(S.Ges_RS               ,2)         as Ges_RS
   ,ifnull(T.Data_Currency,"EUR")               as AfCurr      -- `Aff Curr`
   ,round(sum(ifnull(T.Aff_Comm_CPA,0)*T.XCH),2)      AS AfCom_cpa   -- `Affiliate CPA comm`
   ,round(sum(ifnull(T.Aff_Comm_RS ,0)*T.XCH),2)      AS AfCom_rs    -- `Affiliate RS comm`
   ,round(sum(ifnull(T.Aff_Comm_TOT,0)*T.XCH),2)      AS AfCom_tot   -- `Affiliate Tot comm`
   ,round(sum(ifnull(T.Aff_CPA     ,0)*T.XCH),2)      AS AfCPA       -- `Aff CPA`
   ,round(sum(ifnull(T.Aff_RS      ,0)),2)      AS AfRS        -- `Aff RS`
   ,S.Area                                      as `Area`
   ,S.`RS_CarryOver_Pend`                       as `RS COver Pend`
   FROM SetCommConverted_ges S
   LEFT JOIN SetCommConverted_aff T ON T.Username_id=S.Username_id
   GROUP by S.Owner,Publisher ,S.Data_Currency,S.Brand)

UNION ALL

(SELECT 'total' as `Meta`,
    "TOTAL"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ," TOTAL"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,S.Data_Currency
   -- ,"~~~~~"
   ,"~~~~~"
   ,round(sum(S.Signup),0)           as `Signup`
   ,round(sum(S.FTD),0)              as `FTD`
   ,round(sum(S.CPA),0)              as `CPA`
   ,round(sum(S.CPA_Value*S.XCH       ),2) as CPA_Value
   ,round(sum(S.Net_Revenue*S.XCH     ),2) as Net_Revenue
   ,round(sum(S.RS_AJUST*S.XCH        ),2) as RS_AJUST
   -- ,round(sum(S.CPA_Val_AJ_RS   ),2) as CPA_Val_AJ_RS
   ,round(sum(S.Total_Commission*S.XCH),2) as Total_Commission
   ,round(sum(S.Total_Commission*S.XCH)-sum(ifnull(T.Aff_Comm_TOT,0)*T.XCH),2) AS `Profit`
   -- ,"~~~~~"
   -- ,"~~~~~"
   ,ifnull(T.Data_Currency,"")
   ,round(sum(ifnull(T.Aff_Comm_CPA,0)*T.XCH),2) AS Aff_Comm_CPA
   ,round(sum(ifnull(T.Aff_Comm_RS ,0)*T.XCH),2) AS Aff_Comm_RS
   ,round(sum(ifnull(T.Aff_Comm_TOT,0)*T.XCH),2) AS Aff_Comm_TOT
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   FROM SetCommConverted_ges S
   LEFT JOIN SetCommConverted_aff T ON T.Username_id=S.Username_id
   -- FROM SetCommConverted_ges S
   -- LEFT JOIN SetCommConverted_aff T ON T.Username_id=S.Username_id    -- 05.10.2023
   GROUP by S.Owner,CASE WHEN @Currency='original' THEN S.Data_Currency ELSE S.Owner END 
      HAVING (`Total_Commission`<>0 OR `Profit`<>0)
)
UNION ALL
(
SELECT 'no data' as `Meta`,
   "~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~"
   ,"~~~~~"
   ,0,0,0,0,0,0,0,0
   -- ,"~~~~~","~~~~~"
   ,"~~~~~"
   ,0,0,0,"~~~~~","~~~~~","~~~~~"
   ,"~~~~~"
	FROM DUAL WHERE NOT EXISTS (SELECT * FROM SetCommConverted_ges)
) UNION ALL (
SELECT
   "setting"
   ,"width=100px,omit=true"               Date
   ,"width=100px,omit=true"               Owner_id
   ,"width=100px,omit=true"               `Owner`
   ,"width=110px,sortable=yes" as `Publisher`
   ,"width=130px,sortable=yes"            Brand
   ,"width=080px" as `StatAdv`
   ,"omit=true"  as Usrn
   ,"omit=true"   as StatAcct
   ,"width=070px"                          Curr
   ,"width=080px,center=true" as `CapUsed`
   ,"width=80px,right=true,sortable=yes"  sup
   ,"width=80px,right=true,sortable=yes"  ftd
   ,"width=80px,right=true,sortable=yes"  cpa
   ,"width=110px,right=true,sortable=yes" cpaval
   ,"width=110px,right=true"              nr
   ,"width=110px,right=true"              rsval
   ,"width=110px,right=true"              totcomm
   ,"width=110px,right=true,sortable=yes" profit
   ,"width=080px,right=true"  afcurr
   ,"width=110px,right=true"  AfCom_cpa
   ,"width=110px,right=true"  AfCom_rs
   ,"width=110px,right=true"  AfCom_tot
   ,"width=80px,right=true,omit=true"     AfCPA
   ,"width=80px,right=true,omit=true"     AfRS
   ,"width=80px,right=true,omit=true"     `Area`
   ,"width=110px,right=true" as `RS_CarryOver_Pend`
	FROM DUAL WHERE @Meta="YES") ORDER BY Date DESC,convert(`CPA`,signed) DESC;