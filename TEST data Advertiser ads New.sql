-- DELIMITER //
--
-- DROP PROCEDURE sp_GetAffiliateData;
--
-- CREATE PROCEDURE sp_GetAffiliateData (IN p_Affiliate_id INT)
-- BEGIN

SET @p_Affiliate_id=39;

    -- Primer conjunto de resultados: campaign_marketing_source
    SELECT cms.*
    FROM campaign_marketing_source cms
    WHERE cms.Affiliate_id = @p_Affiliate_id
      AND cms.Status_id = '1'
      AND EXISTS (
            SELECT 1
            FROM campaign_advertiser_ads_v2 caa
            WHERE caa.Account_id = cms.Username_id
              AND caa.Status_id = '1'
              AND CURDATE() >= caa.Valid_From
              AND (caa.Valid_To IS NULL OR CURDATE() <= caa.Valid_To)
      );

    -- Segundo conjunto de resultados: campaign_advertiser_ads_v2
    SELECT caa.*
    FROM campaign_advertiser_ads_v2 caa
    WHERE caa.Status_id = '1'
      AND CURDATE() >= caa.Valid_From
      AND (caa.Valid_To IS NULL OR CURDATE() <= caa.Valid_To)
      AND caa.Account_id IN (
            SELECT cms.Username_id
            FROM campaign_marketing_source cms
            WHERE cms.Affiliate_id = @p_Affiliate_id
              AND cms.Status_id = '1'
      );
-- END //

-- DELIMITER ;



-- Selección de posibles URL base
-- ------------------------------
SELECT
    SUBSTRING_INDEX(m.Tracklink, '?', 1) AS TracklinkBase,
    ANY_VALUE(m.Tracklink)    AS Tracklink,
    ANY_VALUE(m.Tracker_ID)   AS Tracker_ID,
    ANY_VALUE(m.Tracker_Name) AS Tracker_Name,
    count(*)   AS `Cant`
FROM campaign_marketing_source m
WHERE m.Status_id IN ('1')
  AND m.Tracklink NOT LIKE '%rebrand.ly%'
--   AND (
--        m.Tracklink LIKE '%bid=%'
--     OR m.Tracklink LIKE '%pid=%'
--     OR m.Tracklink LIKE '%siteid=%'
--     OR m.Tracklink LIKE '%source=%'
--     OR m.Tracklink LIKE '%offer_id=%'
--   )
GROUP BY SUBSTRING_INDEX(m.Tracklink, '?', 1)
ORDER BY TracklinkBase
;

-- Selección de posibles URL base con BID/PID
-- ------------------------------------------
SELECT
    B.Advertiser_name as Brand,
    SUBSTRING_INDEX(m.Tracklink, '?', 1) AS TracklinkBase,
    ANY_VALUE(m.Tracklink)    AS "Tracklink example",
    ANY_VALUE(m.Tracker_ID)   AS Tracker_ID,
    ANY_VALUE(m.Tracker_Name) AS Tracker_Name,
    count(*)   AS `Cant`
FROM campaign_marketing_source m
LEFT JOIN campaign_advertiser B ON B.id=m.Advertiser_id

WHERE m.Status_id IN ('1')
  AND m.Tracklink NOT LIKE '%rebrand.ly%'
  AND (
       m.Tracklink LIKE '%bid=%'
    OR m.Tracklink LIKE '%pid=%'
--     OR m.Tracklink LIKE '%siteid=%'
--     OR m.Tracklink LIKE '%source=%'
--     OR m.Tracklink LIKE '%offer_id=%'
  )
GROUP BY SUBSTRING_INDEX(m.Tracklink, '?', 1)
ORDER BY TracklinkBase
;

WITH Base_select as (
SELECT
     B.Advertiser_name as Brand
    ,SUBSTRING_INDEX(m.Tracklink, '?', 1) AS TracklinkBase
    ,SUBSTRING_INDEX(SUBSTRING(m.Tracklink,LOCATE('pid=',m.Tracklink) + 4), "&", 1) as `PID`
    ,SUBSTRING_INDEX(SUBSTRING(m.Tracklink,LOCATE('bid=',m.Tracklink) + 4), "&", 1) as `BID`
    ,ANY_VALUE(m.Tracklink)    AS "Tracklink example"
    ,ANY_VALUE(m.Tracker_ID)   AS Tracker_ID
    ,ANY_VALUE(m.Tracker_Name) AS Tracker_Name
    ,count(*)   AS `Cant`
FROM campaign_marketing_source m
LEFT JOIN campaign_advertiser B ON B.id=m.Advertiser_id

WHERE m.Status_id IN ('1')
  AND m.Tracklink NOT LIKE '%rebrand.ly%'
  AND (
       m.Tracklink LIKE '%bid=%'
    OR m.Tracklink LIKE '%pid=%'
--     OR m.Tracklink LIKE '%siteid=%'
--     OR m.Tracklink LIKE '%source=%'
--     OR m.Tracklink LIKE '%offer_id=%'
  )
GROUP BY SUBSTRING_INDEX(m.Tracklink, '?', 1)
)
select
    CONCAT(TracklinkBase,"?pid=",PID,"&bid=",BID) as `rebuilt_URL`
   ,b.*
from Base_select b
ORDER BY Brand,TracklinkBase
;























-- ------------------------ADECUACION TABLA ANTERIOR-------------------------------------------------
--
SELECT Advertiser_id,Username_id,COUNT(*) AS K
FROM `euroaffiliati_dev`.`campaign_marketing_source`
WHERE Stat_aggreg='1'
GROUP BY Advertiser_id,Username_id
ORDER BY Advertiser_id,Username_id,K desc
;

WITH ranked AS (
  SELECT
    Advertiser_id,
    Username_id,
    COUNT(*) AS K,
    ROW_NUMBER() OVER (
      PARTITION BY Advertiser_id
      ORDER BY COUNT(*) DESC
    ) AS rn
  FROM euroaffiliati_dev.campaign_marketing_source
  WHERE Stat_aggreg = '1'
  GROUP BY Advertiser_id, Username_id
)
SELECT
  Advertiser_id,
  Username_id,
  K
FROM ranked
WHERE rn = 1;


WITH Advertiser_Account as (
   SELECT
     Advertiser_id,
     Username_id AS Account_id,
     K
   FROM
   (
     SELECT
       Advertiser_id,
       Username_id,
       COUNT(*) AS K,
       ROW_NUMBER() OVER (
         PARTITION BY Advertiser_id
         ORDER BY COUNT(*) DESC
       ) AS rn
     FROM campaign_marketing_source
     WHERE Stat_aggreg = '1'
     GROUP BY Advertiser_id, Username_id
   ) AS ranked
   WHERE rn = 1
)
UPDATE campaign_advertiser_ads_v2 ad
INNER JOIN Advertiser_Account AA ON AA.Advertiser_id=ad.Advertiser_id
SET ad.Account_id=AA.Account_id
;

