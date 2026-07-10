-- call Dash_Gestor_TotalByAdvertiser('debug=ye');

-- Crear tablas temporales con índices
CREATE TEMPORARY TABLE temp_SetCommConverted_ges (
    Owner_id INT,
    Owner VARCHAR(255),
    Date DATE,
    Publisher VARCHAR(255),
    Brand VARCHAR(255),
    StatAdv VARCHAR(255),
    Username VARCHAR(255),
    StatAcct VARCHAR(255),
    Data_Currency VARCHAR(10),
    CPA_Limit DECIMAL(10,2),
    UsedLim DECIMAL(10,2),
    Signup INT,
    FTD INT,
    CPA INT,
    CPA_Value DECIMAL(10,2),
    Net_Revenue DECIMAL(10,2),
    RS_AJUST DECIMAL(10,2),
    Total_Commission DECIMAL(10,2),
    RS_CarryOver_Pend DECIMAL(10,2),
    Area VARCHAR(255),
    Publisher_id INT,
    Username_id INT,
    INDEX idx_username_id (Username_id),
    INDEX idx_owner (Owner_id)
);

CREATE TEMPORARY TABLE temp_SetCommConverted_aff (
    Owner_id INT,
    Owner VARCHAR(255),
    Date DATE,
    Brand VARCHAR(255),
    Publisher_id INT,
    Advertiser_id INT,
    Username_id INT,
    Data_Currency VARCHAR(10),
    Aff_Comm_CPA DECIMAL(10,2),
    Aff_Comm_RS DECIMAL(10,2),
    Aff_Comm_TOT DECIMAL(10,2),
    Aff_CPA DECIMAL(10,2),
    Aff_RS DECIMAL(10,2),
    INDEX idx_username_id (Username_id)
);

EXPLAIN ANALYZE
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
   FROM Snapshot_day_by_day_fact1 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(DATE,7) ='2025-06' 
   GROUP BY G.Owner,Username_id
),
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
   FROM Snapshot_day_by_day_fact2 G
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(DATE,7) ='2025-06' 
   GROUP BY G.Owner,Brand,Username_id  -- 08.09.2023
),
SetCommConverted_ges as (
   SELECT
       G.Owner          as Owner_id
      ,AC.username      as `Owner`
      ,U.Area
      ,G.Month          AS Date
      ,G.Brand          as `Brand`
      ,U.id             as Username_id
      ,'ALL' as `Username`
      ,A.Stat_effect    as `StatAdv`
      ,U.Stat_effect    as `StatAcct`
      ,'EUR' as `Data_Currency`
      ,A.CPA_Limit as CPA_Limit
      ,CASE WHEN A.CPA_Limit>0
                   AND SUM(G.CPA)/A.CPA_Limit>=0.8
            THEN ROUND(SUM(G.CPA)/A.CPA_Limit*100,0)
            ELSE 0 END                         as `UsedLim`
      ,sum(Fact.Signups)                       as `Signup`
      ,sum(Fact.FTD)                           as `FTD`
      ,sum(G.CPA)                              as `CPA`
      ,round(sum(net_CPA_Val     )/xx.Coef,2)  as `CPA_Value`
      ,round(sum(Net_Revenue     )/xx.Coef,2)  as `Net_Revenue`
      ,round(sum(net_RS_Val      )/xx.Coef,2)  as `RS_AJUST`
      ,round(sum(net_Total_comm  )/xx.Coef,2)  as `Total_Commission`
      ,round(sum(RS_CarryOver_Pend)/xx.Coef,2) as `RS_CarryOver_Pend`
      ,G.Publisher
      ,G.Publisher_id
      -- ,(@Data_Currency:=U.Data_Currency) AS dummy
      FROM monthly_comms_gestor_v5 G
         LEFT JOIN LATERAL
            (SELECT
               (SELECT Rate FROM exchange_rate x WHERE x.Currency=G.Data_Currency) /
               (SELECT Rate FROM exchange_rate x WHERE x.Currency='EUR') as Coef
            ) AS xx ON TRUE
         LEFT JOIN campaign_username   U     ON U.id=G.Username_id
         LEFT JOIN campaign_advertiser A     ON A.id=U.Advertiser_id
         LEFT JOIN account_account     AC    ON AC.id=G.Owner
         LEFT JOIN SetFact_ges         Fact  ON G.Owner=Fact.Owner_id AND G.Advertiser_id=Fact.Advertiser_id
                                             AND G.Username_id=Fact.Username_id
      WHERE G.Month ='2025-06' 
      GROUP BY G.Owner,Username_id 
),
SetCommConverted_aff as (
   SELECT
      G.Owner        as Owner_id
     ,AC.username    as Owner
     ,G.`Month`      as `DATE`
     ,Brand
     ,U.Publisher_id
     ,G.Advertiser_id
     ,Account_id     as "Username_id"
     -- ,'ALL' as Username
     ,'EUR' as Data_Currency
     ,round(SUM(ifnull(net_CPA_Val,0)   ) /xx.Coef,2) as Aff_Comm_CPA
     ,round(SUM(ifnull(net_RS_Val,0)    ) /xx.Coef,2) as Aff_Comm_RS
     ,round(SUM(ifnull(net_Total_comm,0)) /xx.Coef,2) as Aff_Comm_TOT
     ,0 as `Aff_CPA`
     ,0 as `Aff_RS`
   FROM monthly_comms_affiliate_v5 G
   LEFT JOIN LATERAL (SELECT
         (SELECT Rate FROM exchange_rate x WHERE x.Currency=G.Currency) /
         (SELECT Rate FROM exchange_rate x WHERE x.Currency='EUR') as Coef)
            AS xx ON TRUE
   LEFT JOIN account_account AC ON AC.id=G.Owner
   LEFT JOIN campaign_username   U ON U.id=G.Account_id
   WHERE G.`Month`='2025-06' 
   GROUP BY G.Owner,Username_id
),
SetCommConverted_sub as (
   SELECT G.Owner as Owner_id,AC.username as Owner
     ,DATE,Brand,Advertiser_id,Username_id
     ,'ALL' as Username
     ,'EUR' as Data_Currency
     ,round(SUM(CPA_Value)    /xx.Coef,2) as Aff_Comm_CPA
     ,round(SUM(RS_AJUST)     /xx.Coef,2) as Aff_Comm_RS
     ,round(SUM(CPA_Val_AJ_RS)
     +SUM(RS_AJUST)           /xx.Coef,2) as Aff_Comm_TOT
     ,round(`Aff_CPA`         /xx.Coef,2) as `Aff_CPA`
     ,round(`Aff_RS`,1)                   as `Aff_RS`
   FROM sub_view_monthly_fact_aff4 G
   LEFT JOIN LATERAL (SELECT
         (SELECT Rate FROM exchange_rate x WHERE x.Currency=G.Data_Currency) /
         (SELECT Rate FROM exchange_rate x WHERE x.Currency='EUR') as Coef)
            AS xx ON TRUE
   LEFT JOIN account_account AC ON AC.id=G.Owner
   WHERE LEFT(G.DATE,7) ='2025-06' 
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
     ,'EUR' as Data_Currency
     ,round(SUM(CPA_Value)    /xx.Coef,2) as `CPA_Value`
     ,round(SUM(RS_AJUST)     /xx.Coef,2) as `RS_AJUST`
     ,round(SUM(CPA_Val_AJ_RS)
     +SUM(RS_AJUST)           /xx.Coef,2) as `Total_Commission`
     ,round(`Aff_CPA`         /xx.Coef,2) as `Aff_CPA`
     ,round(`Aff_RS`,1)                   as `Aff_RS`
     ,sum(Fact.Signups)                   as `Signup`
     ,sum(Fact.FTD)                       as `FTD`
     ,sum(G.CPA)                          as `CPA`
     ,round(sum(G.Net_Revenue)/xx.Coef,2) as `Net_Revenue`
     ,0                                   as `RS_CarryOver_Pend`
   FROM view_monthly_fact_aff4 G
   LEFT JOIN LATERAL (SELECT
         (SELECT Rate FROM exchange_rate x WHERE x.Currency=G.Data_Currency) /
         (SELECT Rate FROM exchange_rate x WHERE x.Currency='EUR') as Coef)
            AS xx ON TRUE
   LEFT JOIN account_account     AC    ON AC.id=G.Owner
   LEFT JOIN campaign_username   U     ON U.id=G.Username_id
   LEFT JOIN campaign_advertiser A     ON A.id=U.Advertiser_id
   LEFT JOIN SetFact_ges         Fact  ON G.Owner=Fact.Owner_id AND G.Advertiser_id=Fact.Advertiser_id
                                       AND G.Username_id=Fact.Username_id
   WHERE LEFT(G.DATE,7) ='2025-06' 
   GROUP BY G.Owner,Brand,Username_id
)
-- --------------------------------
-- select * from SetFact_ges;
-- select * from SetFact_maf;
-- select * from SetCommConverted_ges WHERE publisher_id=17;
-- select * from SetCommConverted_aff WHERE publisher_id=17;
-- select * from SetCommConverted_sub;
-- select * from SetCommConverted_maf;
-- --------------------------------
INSERT INTO temp_SetCommConverted_ges
SELECT /*+ INDEX(S idx_username_id) */
    S.Date
   ,S.Owner_id
   ,S.Owner
   ,S.Publisher                                 as `Publisher`
   ,S.Brand                                     as `Brand`
   ,S.StatAdv  as `StatusAdv`
   ,S.Username                                  AS `Account`
   ,S.StatAcct  as `Status`
   ,S.Data_Currency                             as `Curr`
   ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(' / ',S.UsedLim,' %') ELSE '' END)
   -- ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(" / ",S.UsedLim," %") ELSE "" END)
                                                AS `Cap/Used`
   ,format(sum(S.Signup),0)                      as `Signup`
   ,format(sum(S.FTD),0)                         as `FTD`
   ,format(sum(S.CPA),0)                         as `CPA`
   ,format(sum(S.CPA_Value       ),2)            as `CPA_Value`  -- `CPA Commiss`
   ,format(sum(S.Net_Revenue     ),2)            as Net_Rev      -- `Net Revenue`
   ,format(sum(S.RS_AJUST        ),2)            as RS_Val       -- `R Share Commiss`
   -- ,format(sum(S.CPA_Val_AJ_RS   ),2)         as CPA_Val_AJ_RS
   ,format(sum(S.Total_Commission),2)            as Tot_Comm     -- `TOTAL Commiss`
   ,CASE WHEN S.Data_Currency=ifnull(T.Data_Currency,"EUR")
         THEN (format(sum(S.Total_Commission)-sum(ifnull(T.Aff_Comm_TOT,0)),2))
         ELSE (format(sum(S.Total_Commission),2)) END AS `Profit`
   -- ,format(S.Ges_CPA              ,2)         as Ges_CPA
   -- ,format(S.Ges_RS               ,2)         as Ges_RS
   ,ifnull(T.Data_Currency,"EUR")               as AfCurr      -- `Aff Curr`
   ,format(sum(ifnull(T.Aff_Comm_CPA,0)),2)      AS AfCom_cpa   -- `Affiliate CPA comm`
   ,format(sum(ifnull(T.Aff_Comm_RS ,0)),2)      AS AfCom_rs    -- `Affiliate RS comm`
   ,format(sum(ifnull(T.Aff_Comm_TOT,0)),2)      AS AfCom_tot   -- `Affiliate Tot comm`
   ,format(sum(ifnull(T.Aff_CPA     ,0)),2)      AS AfCPA       -- `Aff CPA`
   ,format(sum(ifnull(T.Aff_RS      ,0)),2)      AS AfRS        -- `Aff RS`
   ,S.Area                                      as `Area`
   ,S.`RS_CarryOver_Pend`                       as `RS COver Pend`
   ,S.Publisher_id as Publisher_id  -- K 20.01.2025
FROM SetCommConverted_ges S
LEFT JOIN SetCommConverted_aff T ON T.Username_id=S.Username_id
WHERE @Rec_log="NO"
GROUP by S.Owner_id,Publisher ,S.Brand;

INSERT INTO temp_SetCommConverted_aff
SELECT /*+ INDEX(T idx_username_id) */
    G.Owner        as Owner_id
   ,AC.username    as Owner
   ,G.`Month`      as `DATE`
   ,Brand
   ,U.Publisher_id
   ,G.Advertiser_id
   ,Account_id     as "Username_id"
   -- ,'ALL' as Username
   ,'EUR' as Data_Currency
   ,round(SUM(ifnull(net_CPA_Val,0)   ) /xx.Coef,2) as Aff_Comm_CPA
   ,round(SUM(ifnull(net_RS_Val,0)    ) /xx.Coef,2) as Aff_Comm_RS
   ,round(SUM(ifnull(net_Total_comm,0)) /xx.Coef,2) as Aff_Comm_TOT
   ,0 as `Aff_CPA`
   ,0 as `Aff_RS`
FROM monthly_comms_affiliate_v5 G
LEFT JOIN LATERAL (SELECT
         (SELECT Rate FROM exchange_rate x WHERE x.Currency=G.Currency) /
         (SELECT Rate FROM exchange_rate x WHERE x.Currency='EUR') as Coef)
            AS xx ON TRUE
LEFT JOIN account_account AC ON AC.id=G.Owner
LEFT JOIN campaign_username   U ON U.id=G.Account_id
WHERE G.`Month`='2025-06' 
GROUP BY G.Owner,Username_id;

-- Modificar la consulta principal para usar las tablas temporales
SELECT 'data' as `Meta`,
    S.Date
   ,S.Owner_id
   ,S.Owner
   ,S.Publisher                                 as `Publisher`
   ,S.Brand                                     as `Brand`
   ,S.StatAdv  as `StatusAdv`
   ,S.Username                                  AS `Account`
   ,S.StatAcct  as `Status`
   ,S.Data_Currency                             as `Curr`
   ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(' / ',S.UsedLim,' %') ELSE '' END)
   -- ,CONCAT(S.CPA_Limit,CASE WHEN S.UsedLim>0 THEN CONCAT(" / ",S.UsedLim," %") ELSE "" END)
                                                AS `Cap/Used`
   ,format(sum(S.Signup),0)                      as `Signup`
   ,format(sum(S.FTD),0)                         as `FTD`
   ,format(sum(S.CPA),0)                         as `CPA`
   ,format(sum(S.CPA_Value       ),2)            as `CPA_Value`  -- `CPA Commiss`
   ,format(sum(S.Net_Revenue     ),2)            as Net_Rev      -- `Net Revenue`
   ,format(sum(S.RS_AJUST        ),2)            as RS_Val       -- `R Share Commiss`
   -- ,format(sum(S.CPA_Val_AJ_RS   ),2)         as CPA_Val_AJ_RS
   ,format(sum(S.Total_Commission),2)            as Tot_Comm     -- `TOTAL Commiss`
   ,CASE WHEN S.Data_Currency=ifnull(T.Data_Currency,"EUR")
         THEN (format(sum(S.Total_Commission)-sum(ifnull(T.Aff_Comm_TOT,0)),2))
         ELSE (format(sum(S.Total_Commission),2)) END AS `Profit`
   -- ,format(S.Ges_CPA              ,2)         as Ges_CPA
   -- ,format(S.Ges_RS               ,2)         as Ges_RS
   ,ifnull(T.Data_Currency,"EUR")               as AfCurr      -- `Aff Curr`
   ,format(sum(ifnull(T.Aff_Comm_CPA,0)),2)      AS AfCom_cpa   -- `Affiliate CPA comm`
   ,format(sum(ifnull(T.Aff_Comm_RS ,0)),2)      AS AfCom_rs    -- `Affiliate RS comm`
   ,format(sum(ifnull(T.Aff_Comm_TOT,0)),2)      AS AfCom_tot   -- `Affiliate Tot comm`
   ,format(sum(ifnull(T.Aff_CPA     ,0)),2)      AS AfCPA       -- `Aff CPA`
   ,format(sum(ifnull(T.Aff_RS      ,0)),2)      AS AfRS        -- `Aff RS`
   ,S.Area                                      as `Area`
   ,S.`RS_CarryOver_Pend`                       as `RS COver Pend`
   ,S.Publisher_id as Publisher_id  -- K 20.01.2025
FROM temp_SetCommConverted_ges S
LEFT JOIN temp_SetCommConverted_aff T ON T.Username_id = S.Username_id
WHERE @Rec_log = "NO"
GROUP BY S.Owner_id, Publisher, S.Brand;

-- Limpiar tablas temporales
DROP TEMPORARY TABLE IF EXISTS temp_SetCommConverted_ges;
DROP TEMPORARY TABLE IF EXISTS temp_SetCommConverted_aff;

-- Results:
