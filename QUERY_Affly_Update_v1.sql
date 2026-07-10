/* ARMADO PARAMETROS PARA INVOCAR API AFFLY/REBRANDLY
   28.08.2024 V1

*/

SET @Comparator=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='Comparator');

WITH Pending_URL_status AS (
SELECT 
    URL.id 
   ,ms.Channel_id
   ,getLicenseBrand(ad.Advertiser_Name, 'IT') AS CheckPlayerAge
   ,case trim(upper(replace(ch.nation,".","")))
      when "COM" THEN ""
      WHEN ""  THEN ""
      ELSE trim(upper(replace(ch.nation,".",""))) end 
                        AS Language 
   ,XX.MS_active_count 
   ,CONCAT(@Comparator,IFNULL(ch.landing_page_url,'')) AS LandPageComparator
   ,case when left(IFNULL(ch.landing_page_channel,''),8)!="https://"
         then CONCAT("https://affly/404/",trim(upper(replace(ch.nation,".",""))))
         ELSE ch.landing_page_channel
         END            AS LandPageChannelAff   
   ,URL.MS_id 
   ,URL.Affiliate_id
   ,CASE WHEN URL.Stat_aggreg=1 THEN "ACTIVE" ELSE "INACTIVE" END AS Status
   ,URL.Tracklink
   ,URL.Shortlink
   ,URL.Shortlink_id
from campaign_mkt_source_url URL
LEFT JOIN campaign_marketing_source ms ON ms.id= URL.MS_id
LEFT JOIN account_landing_pages ch ON ch.id= ms.Channel_id
LEFT JOIN campaign_advertiser ad ON ad.id= ms.Advertiser_id
JOIN LATERAL (
      SELECT COUNT(id) AS MS_active_count  FROM campaign_marketing_source ms1 
      WHERE ms1.Channel_id=ms.Channel_id AND ms1.Stat_aggreg=1) AS XX
WHERE URL.Stat_Sent_to_API!=1 AND ms.Channel_id is not NULL
-- ORDER BY ms.Channel_id,URL.Stat_aggreg,URL.MS_id  
)
SELECT
    id
   ,Shortlink
   ,Shortlink_id
   ,CASE WHEN Status="ACTIVE" THEN Tracklink
         ELSE CASE WHEN MS_active_count>=3 
                   THEN LandPageComparator 
                   ELSE LandPageChannelAff
              END
    END            AS Tracklink_to_API
   ,Language
   ,Status
   ,CheckPlayerAge
FROM Pending_URL_status   
;
  
  
/*---- TEST ----------------------------------------------------------

TRUNCATE           euroaffiliati_dev.campaign_mkt_source_url; 
INSERT IGNORE INTO euroaffiliati_dev.campaign_mkt_source_url SELECT * FROM euroaffiliati2.campaign_mkt_source_url             ;

update campaign_mkt_source_url
set Stat_Sent_to_API=0
   ,Stat_aggreg=case when Stat_aggreg=1 then 4 else 1 end
where id BETWEEN 660 AND 800
; 
*/  