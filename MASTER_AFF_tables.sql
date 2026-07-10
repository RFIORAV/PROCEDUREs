/*
Affiliate_id IN (527,532,538,531,549,826,829,723)

-- Nuevas tablas --------------------
sub_account_account_bills
sub_account_financial_movement
sub_account_landing_pages
sub_account_manual_adjustments
sub_account_payment_methods
sub_campaign_deal_affiliate
sub_campaign_deal_marketplace
sub_campaign_marketing_source
sub_campaign_mkt_source_deal
sub_monthly_comms_affiliate
sub_view_monthly_fact_aff4
sub_Snapshot_day_by_day_fact3

*/

USE euroaffiliati_dev;
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS euroaffiliati_dev.account_account_OLD;
-- CREATE TABLE euroaffiliati_dev.account_account_OLD LIKE euroaffiliati_dev.account_account;
-- INSERT INTO  euroaffiliati_dev.account_account_OLD SELECT * FROM euroaffiliati_dev.account_account;
--
-- CREATE TABLE if NOT exists euroaffiliati_dev.account_account LIKE euroaffiliati2.account_account;
-- TRUNCATE     euroaffiliati_dev.account_account;
-- INSERT INTO  euroaffiliati_dev.account_account SELECT * FROM euroaffiliati2.account_account;

-- --------------------------------------------------------------------------------------
-- 
REPLACE INTO `account_account_groups` (`account_id`, `group_id`)
-- ;
SELECT a.id,IFNULL(g.`group_id`,4) FROM euroaffiliati2.`account_account` a
LEFT JOIN euroaffiliati_dev.`account_account_groups` g ON g.`account_id`=a.id AND g.`group_id`=4
WHERE a.id IN (440,128)

UNION ALL

SELECT a.id,IFNULL(g.`group_id`,6) FROM euroaffiliati2.`account_account` a
LEFT JOIN euroaffiliati_dev.`account_account_groups` g ON g.`account_id`=a.id AND g.`group_id`=6
WHERE a.second_level IN (440,128)
;
DELETE g
FROM        euroaffiliati_dev.`account_account_groups` g 
INNER JOIN  euroaffiliati_dev.`account_account_groups` g1 ON g1.`account_id`=g.`account_id` AND g1.`group_id`=6
WHERE g.`group_id`=3;
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS sub_account_landing_pages;
CREATE TABLE if NOT EXISTS sub_account_landing_pages LIKE account_landing_pages;
INSERT IGNORE INTO sub_account_landing_pages              
   SELECT d.* FROM account_landing_pages d
   INNER JOIN account_account_groups m on d.Account_id=m.account_id and group_id="6"
;

-- DROP TABLE IF EXISTS sub_account_payment_methods;
CREATE TABLE if NOT EXISTS sub_account_payment_methods LIKE account_payment_methods;
INSERT IGNORE INTO sub_account_payment_methods              
   SELECT d.* FROM account_payment_methods d
   INNER JOIN account_account_groups m on d.Account_id=m.account_id and group_id="6"
;
-- --------------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS sub_account_financial_movement;
CREATE TABLE if NOT EXISTS sub_account_financial_movement LIKE account_financial_movement;
INSERT IGNORE INTO sub_account_financial_movement              
   SELECT d.* FROM account_financial_movement d
   INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
;
-- DROP TABLE IF EXISTS sub_account_manual_adjustments;
CREATE TABLE if NOT EXISTS sub_account_manual_adjustments LIKE account_manual_adjustments;
INSERT IGNORE INTO sub_account_manual_adjustments              
   SELECT d.* FROM account_manual_adjustments d
   INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
;
-- DROP TABLE IF EXISTS sub_account_account_bills;
CREATE TABLE if NOT EXISTS sub_account_account_bills LIKE account_account_bills;
INSERT IGNORE INTO sub_account_account_bills              
   SELECT d.* FROM account_account_bills d
   INNER JOIN account_account_groups m on d.Account_id=m.account_id and group_id="6"
;
-- DROP TABLE IF EXISTS sub_campaign_deal_marketplace;
CREATE TABLE if NOT EXISTS sub_campaign_deal_marketplace LIKE campaign_deal_marketplace;
INSERT IGNORE INTO sub_campaign_deal_marketplace              
   SELECT d.* FROM campaign_deal_marketplace d
   -- INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
;
UPDATE `sub_campaign_deal_marketplace` 
SET owner="440";

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------

SET FOREIGN_KEY_CHECKS = 0;
/*
SELECT `id`,`Owner`,`Code`,`Tracklink`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`
      ,`Product`,`Source`,`CPA_Limit`,`Status`,`Status_id`,`NotUse_StatEf`,`Stat_effect`
      ,`Stat_aggreg`,`Stat_Chan`,`Stat_Acct`,`Status_Adv_id`,`Status_Acct_id`,`Status_Aff_id`
      ,`Status_Channel_id`,`Status_Pub_id`,`Valid_From`,`Valid_Until`,`Description`
      ,`Affiliate_id`,`Advertiser_id`,`Advertiser_id_OK`,`Publisher_id`,`Campaign_id`
      ,`Username_id`,`Channel_id`,`Deal_id`,`Country_Deal`,`Product_Deal`,`Deal_Valid_From`
      ,`Shortlink`,`Shortlink_id`,`Manual_Adjustment_CPA`,`Manual_Adjustment_Euro`,`Priority`
      ,`Creation_Date`,`Last_Update`,`Operator` 
FROM campaign_marketing_source
*/

DROP TABLE IF EXISTS sub_campaign_marketing_source;  -- OJO TRIGGER sub_campaign_marketing_source_after_update_deal;
CREATE TABLE if NOT EXISTS sub_campaign_marketing_source LIKE campaign_marketing_source;
ALTER TABLE `sub_campaign_marketing_source` CHANGE COLUMN `id` `id` VARCHAR(50) NOT NULL DEFAULT '' FIRST;


-- TRUNCATE           sub_campaign_marketing_source;
INSERT IGNORE INTO sub_campaign_marketing_source (
      `id`,`Owner`,`Code`,`Tracklink`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`
      ,`Product`,`Source`,`CPA_Limit`,`Status`,`Status_id`,`NotUse_StatEf`,`Stat_effect`
      ,`Stat_aggreg`,`Stat_Chan`,`Stat_Acct`,`Status_Adv_id`,`Status_Acct_id`,`Status_Aff_id`
      ,`Status_Channel_id`,`Status_Pub_id`,`Valid_From`,`Valid_Until`,`Description`
      ,`Affiliate_id`,`Advertiser_id`,`Advertiser_id_OK`,`Publisher_id`,`Campaign_id`
      ,`Username_id`,`Channel_id`,`Deal_id`,`Country_Deal`,`Product_Deal`,`Deal_Valid_From`
      ,`Shortlink`,`Shortlink_id`,`Manual_Adjustment_CPA`,`Manual_Adjustment_Euro`,`Priority`
      ,`Creation_Date`,`Last_Update`,`Operator`)             
   SELECT `Code_To_Affiliate` as `id`
      ,d.`Owner`
      ,d.`id` as `Code`
      ,d.`Tracklink`,d.`Tracker_ID`,d.`Tracker_Name`,d.`Code_To_Affiliate`
      ,d.`Product`,d.`Source`,d.`CPA_Limit`,d.`Status`,d.`Status_id`,d.`NotUse_StatEf`,d.`Stat_effect`
      ,d.`Stat_aggreg`,d.`Stat_Chan`,d.`Stat_Acct`,d.`Status_Adv_id`,d.`Status_Acct_id`,d.`Status_Aff_id`
      ,d.`Status_Channel_id`,d.`Status_Pub_id`,d.`Valid_From`,d.`Valid_Until`,d.`Description`
      ,d.`Affiliate_id`,d.`Advertiser_id`,d.`Advertiser_id_OK`,d.`Publisher_id`,d.`Campaign_id`
      ,d.`Username_id`,d.`Channel_id`,d.`Deal_id`,d.`Country_Deal`,d.`Product_Deal`,d.`Deal_Valid_From`
      ,d.`Shortlink`,d.`Shortlink_id`,d.`Manual_Adjustment_CPA`,d.`Manual_Adjustment_Euro`,d.`Priority`
      ,d.`Creation_Date`,d.`Last_Update`,d.`Operator` 
      FROM campaign_marketing_source d
   INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id IN ("4","6")
;
UPDATE `sub_campaign_marketing_source` m
LEFT JOIN `account_account` a ON m.`Affiliate_id`=a.id
SET owner=a.second_level,Tracker_ID=Code_To_Affiliate,Tracker_Name=Code_To_Affiliate
   ,Tracklink=Shortlink,Shortlink_id="";
   
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------

DROP TABLE IF EXISTS sub_campaign_mkt_source_deal;
CREATE TABLE if NOT EXISTS sub_campaign_mkt_source_deal LIKE campaign_mkt_source_deal;
ALTER TABLE `sub_campaign_mkt_source_deal` CHANGE COLUMN `MS_id` `MS_id` VARCHAR(50) NULL DEFAULT NULL ;

INSERT IGNORE INTO sub_campaign_mkt_source_deal (
          `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
          ,`Country`,`is_active`,`Code`,`Creation_Date`,`Last_Update`,`Operator`)             
   SELECT NULL,MS.`Code_To_Affiliate` AS `MS_id`
         ,d.`Deal_Valid_From`,d.`Product`,d.`Affiliate_id`,d.`Channel_id`,d.`Deal_id`
         ,d.`Country`,d.`is_active`
         ,d.`MS_id` AS `Code`
         ,d.`Creation_Date`,NOW(),"SysOp"
   FROM campaign_mkt_source_deal d
   LEFT JOIN  campaign_marketing_source MS ON MS.id=d.MS_id
   INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
   WHERE d.`is_active`=1
;

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------

-- OjO trigger sub_campaign_deal_affiliate_before_insert.

TRUNCATE           sub_campaign_deal_affiliate;
INSERT IGNORE INTO sub_campaign_deal_affiliate             
   SELECT d.* FROM campaign_deal_affiliate d
   INNER JOIN sub_campaign_mkt_source_deal m on d.id=m.Deal_id
   ;
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------

-- ADECUAR Snapshot_day_by_day_fact2 a la situación real donde las MS son del MAF

-- SELECT d.Affiliate_id,a.second_level FROM 
UPDATE
Snapshot_day_by_day_fact2 d
INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
INNER JOIN account_account a on d.Affiliate_id=a.id
SET d.Affiliate_id=a.second_level
;

-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------




/*
SELECT `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
      ,`Advertiser_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
      ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
      ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
      ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
      ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
      ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
      ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen` 
FROM Snapshot_day_by_day_fact2
*/
/*
DROP TABLE IF EXISTS sub_Snapshot_day_by_day_fact3;
CREATE TABLE if NOT EXISTS sub_Snapshot_day_by_day_fact3 LIKE Snapshot_day_by_day_fact2;
ALTER TABLE `sub_Snapshot_day_by_day_fact3` CHANGE COLUMN `MS_id` `MS_id` VARCHAR(50) NULL DEFAULT NULL ;

INSERT IGNORE INTO sub_Snapshot_day_by_day_fact3 (
      `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
      ,`Advertiser_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
      ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
      ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
      ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
      ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
      ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
      ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`)             
   SELECT
      d.`id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
      ,`Advertiser_id`,`Tracker_ID`
      ,d.`Code_To_Affiliate` as `MS_id`
      ,`Tracker_Name`
      ,d.`MS_id` as `Code_To_Affiliate`
      ,`Product`,`Product_Real`
      ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
      ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
      ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
      ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
      ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
      ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`
   FROM Snapshot_day_by_day_fact2 d
   INNER JOIN account_account_groups m on d.Affiliate_id=m.account_id and group_id="6"
;

UPDATE `sub_Snapshot_day_by_day_fact3` f
LEFT JOIN `account_account` a ON f.`Affiliate_id`=a.id
SET owner=a.second_level;
*/
-- --------------------------------------------------------------------------------------

-- --------------------------------------------------------------------------------------
-- normalmente creadas por procedures
-- --------------------------------------------------------------------------------------

CALL sub_Snapshot_day_by_day_fact3_upd('LM');
-- CALL sub_Snapshot_day_by_day_fact3_upd('ALLALL');
call sub_total_monthy_comm_aff_upd;

;
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
