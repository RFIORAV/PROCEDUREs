/*
PROCEDURE_Check_CAP_limit_v1.sql

Descripción:
  Procedimiento PROCEDURE_Check_CAP_limit_v1.

Keys:
  Sin parámetros de entrada documentables.

Ejemplo:
  CALL PROCEDURE_Check_CAP_limit_v1();
*/
-- -------------------------------------------------------------------

SET @Margen_Limit=0.95;

WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month         ,IFNULL(D.Channel,'')   AS `Channel`
   ,P.Advertiser_Name      as Publisher     ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Publisher_id                          ,D.Tracker_ID
   ,D.Brand                                 ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,D.Advertiser_id                         ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,D.Username                              ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,D.Username_id                           ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,D.Affiliate                             ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,D.Affiliate_id                          ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
-- LEFT JOIN `account_landing_pages`     CH ON CH.id=D.Channel_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY D.Publisher_id
)
UPDATE `campaign_publisher` P
INNER JOIN CPA_current_month C ON P.ID=C.Publisher_id
Set P.Status_id=6
WHERE C.P_CPA_Limit>0
  AND round(C.P_CPA_Limit*@Margen_Limit,0)<=C.`CPA`
  AND P.Status_id=1 -- Sólo activos
;
WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month         ,IFNULL(D.Channel,'')   AS `Channel`
   ,P.Advertiser_Name      as Publisher     ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Publisher_id                          ,D.Tracker_ID
   ,D.Brand                                 ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,D.Advertiser_id                         ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,D.Username                              ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,D.Username_id                           ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,D.Affiliate                             ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,D.Affiliate_id                          ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY D.Advertiser_id
)
UPDATE `campaign_advertiser` P
INNER JOIN CPA_current_month C ON P.ID=C.Advertiser_id
Set P.Status_id=6
WHERE C.B_CPA_Limit>0
  AND round(C.B_CPA_Limit*@Margen_Limit,0)<=C.`CPA`
  AND P.Status_id=1 -- Sólo activos
;
WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month         ,IFNULL(D.Channel,'')   AS `Channel`
   ,P.Advertiser_Name      as Publisher     ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Publisher_id                          ,D.Tracker_ID
   ,D.Brand                                 ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,D.Advertiser_id                         ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,D.Username                              ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,D.Username_id                           ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,D.Affiliate                             ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,D.Affiliate_id                          ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY D.Username_id
)
SELECT * FROM 
-- UPDATE 
`campaign_username` P
INNER JOIN CPA_current_month C ON P.ID=C.Username_id
-- Set P.Status_id=6
WHERE C.U_CPA_Limit>0
  AND round(C.U_CPA_Limit*@Margen_Limit,0)<=C.`CPA`
  AND P.Status_id=1 -- Sólo activos
;
WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month         ,IFNULL(D.Channel,'')   AS `Channel`
   ,P.Advertiser_Name      as Publisher     ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Publisher_id                          ,D.Tracker_ID
   ,D.Brand                                 ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,D.Advertiser_id                         ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,D.Username                              ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,D.Username_id                           ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,D.Affiliate                             ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,D.Affiliate_id                          ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY D.Affiliate_id
)
SELECT * FROM 
-- UPDATE 
`campaign_username` P
INNER JOIN CPA_current_month C ON P.ID=C.Affiliate_id
-- Set P.Status_id=6
WHERE C.A_CPA_Limit>0
  AND round(C.A_CPA_Limit*@Margen_Limit,0)<=C.`CPA`
  AND P.Status_id=1 -- Sólo activos
;

WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month         ,IFNULL(D.Channel,'')   AS `Channel`
   ,P.Advertiser_Name      as Publisher     ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Publisher_id                          ,D.Tracker_ID
   ,D.Brand                                 ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,D.Advertiser_id                         ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,D.Username                              ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,D.Username_id                           ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,D.Affiliate                             ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,D.Affiliate_id                          ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY D.MS_id
)
SELECT * FROM 
-- UPDATE 
`campaign_marketing_source` P
INNER JOIN CPA_current_month C ON P.ID=C.Affiliate_id
-- Set P.Status_id=6
WHERE C.M_CPA_Limit>0
  AND round(C.M_CPA_Limit*@Margen_Limit,0)<=C.`CPA`
  AND P.Status_id=1 -- Sólo activos
;



-- -------------------------------------------------------------------

WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month
   ,P.Advertiser_Name      as Publisher
   ,D.Publisher_id
   ,D.Brand
   ,D.Advertiser_id
   ,D.Username
   ,D.Username_id
   ,D.Affiliate
   ,D.Affiliate_id
   ,IFNULL(D.Channel,'')   AS `Channel`
   ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Tracker_ID
   ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
-- LEFT JOIN `account_landing_pages`     CH ON CH.id=D.Channel_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY Publisher_id,Advertiser_id,Username_id,Affiliate_id,MS_id
ORDER BY Publisher_id,Advertiser_id,Username_id,Affiliate_id,MS_id
),
Publisher_to_disable as (
SELECT "Publ." AS `Type`
      ,Publisher_id          as `ID`
      ,Publisher            as `Name`
      ,"" as `Ref_id`  ,"" as `Ref_name`
      ,P_CPA_Limit,round(P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(CPA) as `SumCPA`
FROM CPA_current_month C
GROUP BY 2,3 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
Brand_to_disable as (
SELECT "Brand" AS `Type`
      ,C.Advertiser_id      as `ID`
      ,C.Brand              as `Name`
      ,C.Publisher_id       ,C.Publisher
      ,C.B_CPA_Limit,round(C.B_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Publisher_to_disable P ON P.ID=C.Publisher_id
WHERE P.ID is NULL
GROUP BY 2,3 HAVING `Eff limit`>0 and sum(C.CPA)>`Eff limit`
),
Account_to_disable as (
SELECT "Acct." AS `Type`
      ,C.Username_id       as `ID`
      ,C.Username          as `Name`
      ,C.Publisher      ,C.Brand
      ,C.U_CPA_Limit,round(C.U_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Publisher_to_disable P ON P.ID=C.Publisher_id
LEFT JOIN Brand_to_disable     B ON B.ID=C.Advertiser_id
WHERE P.ID is NULL and B.ID is NULL
GROUP BY 2,3 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
Affiliate_to_disable as (
SELECT "Affil" AS `Type`
      ,Affiliate_id        as `ID`
      ,Affiliate           as `Name`
      ,"" as `Ref_id`  ,"" as `Ref_name`
      ,C.A_CPA_Limit,round(C.A_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
GROUP BY 2,3 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
MS_to_disable as (
SELECT "MS" AS `Type`
      ,C.MS_id             as `ID`
      ,C.Tracker_ID        as `Name`
      ,C.`Brand`,C.`Affiliate`
      ,C.M_CPA_Limit,round(C.M_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Account_to_disable   U ON U.ID=C.Username_id
LEFT JOIN Affiliate_to_disable A ON A.ID=C.Affiliate_id
WHERE U.ID is NULL and A.ID is NULL
GROUP BY 2,3 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
)

Select * from Publisher_to_disable  union all
Select * from Brand_to_disable      union all
Select * from Account_to_disable    union all
Select * from Affiliate_to_disable  union all
Select * from MS_to_disable
;

/*
-- -------------------------------------------------------------------

SET @Margen_Limit=0.95;

WITH CPA_current_month as (
SELECT
    left(D.DATE,7)         AS Month
   ,P.Advertiser_Name      as Publisher
   ,D.Publisher_id
   ,D.Brand
   ,D.Advertiser_id
   ,D.Username
   ,D.Username_id
   ,D.Affiliate
   ,D.Affiliate_id
   ,IFNULL(D.Channel,'')   AS `Channel`
   ,IFNULL(D.Channel_id,0) AS `Channel_id`
   ,D.Tracker_ID
   ,IFNULL(D.MS_id,0)      AS `MS_id`
   ,IFNULL(P.CPA_Limit,0)  as `P_CPA_Limit`
   ,IFNULL(B.CPA_Limit,0)  as `B_CPA_Limit`
   ,IFNULL(U.CPA_Limit,0)  as `U_CPA_Limit`
   ,IFNULL(A.CPA_Limit,0)  as `A_CPA_Limit`
   ,IFNULL(M.CPA_Limit,0)  as `M_CPA_Limit`
   ,sum(Qualified_Players) as `CPA`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_publisher`        P  ON P.id=D.Publisher_id
LEFT JOIN `campaign_advertiser`       B  ON B.id=D.Advertiser_id
LEFT JOIN `campaign_username`         U  ON U.id=D.Username_id
LEFT JOIN `account_account`           A  ON A.id=D.Affiliate_id
LEFT JOIN `campaign_marketing_source` M  ON M.id=D.MS_id
-- LEFT JOIN `account_landing_pages`     CH ON CH.id=D.Channel_id
WHERE LEFT(DATE,7)=LEFT(CURDATE(),7)
GROUP BY Publisher_id,Advertiser_id,Username_id,Affiliate_id,MS_id
ORDER BY Publisher_id,Advertiser_id,Username_id,Affiliate_id,MS_id
),
Publisher_to_disable as (
SELECT "Publ." AS `Type`
      ,Publisher_id,Publisher
      ,"" as `Advertiser_id` ,"" as `Brand`
      ,"" as `Username_id`   ,"" as `Username`
      ,"" as `Affiliate_id`  ,"" as `Affiliate`
      ,"" as `MS_id`        ,"" as `Tracker_ID`
      ,P_CPA_Limit,round(P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(CPA) as `SumCPA`
FROM CPA_current_month C
GROUP BY 2 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
Brand_to_disable as (
SELECT "Brand" AS `Type`
      ,C.Publisher_id       ,C.Publisher
      ,C.Advertiser_id      ,C.Brand
      ,"" as `Username_id`  ,"" as `Username`
      ,"" as `Affiliate_id` ,"" as `Affiliate`
      ,"" as `MS_id`        ,"" as `Tracker_ID`
      ,C.P_CPA_Limit,round(C.P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Publisher_to_disable P ON P.Publisher_id=C.Publisher_id
WHERE P.Publisher_id is NULL
GROUP BY 4,2 HAVING `Eff limit`>0 and sum(C.CPA)>`Eff limit`
),
Account_to_disable as (
SELECT "Acct." AS `Type`
      ,C.Publisher_id       ,C.Publisher
      ,C.Advertiser_id      ,C.Brand
      ,C.Username_id        ,C.Username
      ,"" as `Affiliate_id` ,"" as `Affiliate`
      ,"" as `MS_id`        ,"" as `Tracker_ID`
      ,C.P_CPA_Limit,round(C.P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Publisher_to_disable P ON P.Publisher_id=C.Publisher_id
LEFT JOIN Brand_to_disable     B ON B.Advertiser_id=C.Advertiser_id
WHERE P.Publisher_id is NULL and B.Advertiser_id is NULL
GROUP BY 6,4,2 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
Affiliate_to_disable as (
SELECT "Affil" AS `Type`
      ,"" as `Publisher_id` ,"" as `Publisher`
      ,"" as `Advertiser_id`,"" as `Brand`
      ,"" as `Username_id`  ,"" as `Username`
      ,Affiliate_id         ,Affiliate
      ,"" as `MS_id`        ,"" as `Tracker_ID`
      ,C.P_CPA_Limit,round(C.P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
GROUP BY 8,6,4,2 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
),
MS_to_disable as (
SELECT "Affil" AS `Type`
      ,"" as `Publisher_id` ,"" as `Publisher`
      ,"" as `Advertiser_id`,"" as `Brand`
      ,"" as `Username_id`  ,"" as `Username`
      ,"" as `Affiliate_id` ,"" as `Affiliate`
      ,C.MS_id              ,C.Tracker_ID
      ,C.P_CPA_Limit,round(C.P_CPA_Limit*@Margen_Limit,0) AS `Eff limit`,sum(C.CPA) as `SumCPA`
FROM CPA_current_month C
LEFT JOIN Account_to_disable   U ON U.Username_id=C.Username_id
LEFT JOIN Affiliate_to_disable A ON A.Affiliate_id=C.Affiliate_id
WHERE U.Username_id is NULL and A.Affiliate_id is NULL
GROUP BY 10,8,6,4,2 HAVING `Eff limit`>0 and sum(CPA)>`Eff limit`
)

Select * from Publisher_to_disable  union all
Select * from Brand_to_disable      union all
Select * from Account_to_disable    union all
Select * from Affiliate_to_disable  union all
Select * from MS_to_disable
;
*/