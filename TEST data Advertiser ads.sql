ALTER TABLE `campaign_advertiser_ads_affiliate_v2`
   ADD COLUMN `Ads_Code` `Ads_Code` VARCHAR(10) NOT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Product`,
   CHANGE COLUMN `Country` `Country` VARCHAR(2) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Ads_Code`,
   CHANGE COLUMN `Description` `Description` TEXT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Title`,
   CHANGE COLUMN `Status_id` `Status_id` SMALLINT NULL DEFAULT NULL COMMENT '1=Active' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Valid_From`,
   CHANGE COLUMN `Advertiser_id` `Advertiser_id` INT NOT NULL AFTER `Status_id`,
   CHANGE COLUMN `Valid_From` `Valid_From` DATE NOT NULL DEFAULT (CURDATE()) AFTER `Advertiser_Name`,
   ADD COLUMN `Valid_To` DATE NULL AFTER `Valid_From`,
   ADD COLUMN `MS_id` INT NULL DEFAULT NULL AFTER `Affiliate_id`,
   CHANGE COLUMN `Ads_Code_Default` `Ads_Code_Default` VARCHAR(50) NULL DEFAULT NULL AFTER `Base_Url`,
   CHANGE COLUMN `Creation_Date` `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) AFTER `Ads_Code_Default`,
   CHANGE COLUMN `Operator` `User` INT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Last_Update`,
   DROP COLUMN `Owner`,
   DROP COLUMN `Channel_id`,
   DROP COLUMN `Ads_id`,
   DROP INDEX `campaign_advertiser__Channel_id_a2fa0cbd_fk_account_l`
   ;
/*
ALTER TABLE `campaign_advertiser_ads_affiliate_v2`
   CHANGE COLUMN `Valid_From` `Valid_From` DATE NOT NULL DEFAULT (CURDATE()) AFTER `id`,
   CHANGE COLUMN `Status_id` `Status_id` SMALLINT NULL DEFAULT NULL COMMENT '1=Active' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Valid_From`,
   CHANGE COLUMN `Channel_id` `MS_id` INT NULL DEFAULT NULL AFTER `Affiliate_id`,
   CHANGE COLUMN `Advertiser_Name` `Advertiser_Name` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `MS_id`,
   CHANGE COLUMN `Operator` `User` INT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Last_Update`,
--    DROP COLUMN `Advertiser_id`,
   DROP COLUMN `Owner`,
   ADD COLUMN `Valid_To` DATE NULL AFTER `Valid_From`,   
   DROP INDEX `campaign_advertiser__Channel_id_a2fa0cbd_fk_account_l`,
   ADD INDEX `campaign_advertiser__Channel_id_a2fa0cbd_fk_account_l` (`MS_id`) USING BTREE;
*/   
SELECT ads.`id`,ads.`Valid_From`,ads.`Status_id`,ads.`Ads_id`,ads.`Affiliate_id`,ads.`Product`,ads.`Country`
      ,ms.id "MS_id",ms.Tracklink,ms.Tracker_ID,adv.Advertiser_Name
FROM `euroaffiliati_dev`.`campaign_advertiser_ads_affiliate_v2` ads
INNER JOIN campaign_marketing_source ms ON ms.Affiliate_id=ads.Affiliate_id AND ms.Advertiser_id=ads.Advertiser_id
INNER JOIN campaign_advertiser adv ON adv.id=ads.Advertiser_id
-- WHERE Affiliate_id IN (100) AND Advertiser_id IN (17)
;

SELECT ads.`id`,ads.`Valid_From`,ads.`Status_id`,ads.`Ads_id`,ads.`Affiliate_id`
      ,ads.`MS_id`,ads.`Advertiser_Name`,ads.`Advertiser_id`,ads.`Product`,ads.`Country`
      ,ads.`Creation_Date`,ads.`Last_Update`,ads.`User` 
FROM campaign_advertiser_ads_affiliate_v2 ads;