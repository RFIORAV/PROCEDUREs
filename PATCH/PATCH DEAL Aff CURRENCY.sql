-- -------------------------------------------
-- INTRODUCCIÓN DE CURRENCY EN DEALS AFFILIADO
-- 28.07.2024
-- -------------------------------------------


-- ALTER TABLE `campaign_marketing_source`
--    ADD COLUMN `BLine_currency` VARCHAR(50) NULL DEFAULT NULL AFTER `Deal_Valid_From`,
--    ADD COLUMN `BLine_value` INT NULL DEFAULT NULL AFTER `BLine_currency`;
   
-- ALTER TABLE `monthly_comms_affiliate_v5`
--    ADD COLUMN `Deal_currency` VARCHAR(80) NOT NULL DEFAULT '' AFTER `Advertiser_id`;   
--    
-- ALTER TABLE `view_monthly_fact_aff4`
--    ADD COLUMN `Deal_currency` VARCHAR(80) NOT NULL DEFAULT '' AFTER `Advertiser_id`;      
    
-- DROP TABLE `campaign_deal_affiliate_v5`;

CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_v5` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Multilevel` CHAR(1) NULL DEFAULT NULL,
   `Owner` VARCHAR(30) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Deal_Name` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Description` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `CPA_Value` DECIMAL(12,2) NULL DEFAULT '0.00',
   `RS_Percentage` DECIMAL(12,2) NULL DEFAULT '0.00',
   `RS_Percentage_Displayed` DECIMAL(12,2) NULL DEFAULT '0.00',
   `RS_Base` VARCHAR(30) NULL DEFAULT 'Brand' COLLATE 'utf8mb4_0900_ai_ci',
   `RS_Against_CPA` CHAR(1) NULL DEFAULT '0',
--    `Status`  VARCHAR(30) NULL DEFAULT '',
--    `Status_id` VARCHAR(2) NULL DEFAULT '1' COLLATE 'utf8mb4_0900_ai_ci',
   `Currency` VARCHAR(5) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Operator` VARCHAR(30) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
AUTO_INCREMENT=0
;
/* --
INSERT IGNORE INTO campaign_deal_affiliate_v5
SELECT `id`,`Multilevel`,`Owner`,`Deal_Name`,`Description`,`CPA_Value`,`RS_Percentage`,`RS_Percentage_Displayed`
      ,`RS_Base`,`RS_Against_CPA` -- ,`Status`,`Status_id`
      ,`Currency`,`Last_Update`,`Creation_Date`,`Operator` 
FROM campaign_deal_affiliate
;    
UPDATE campaign_deal_affiliate_v5 
SET Currency="USD",RS_Base="brand",Operator=CASE WHEN Operator="Gestor_Fra" THEN "2" else Operator END,
`Deal_Name`=
	CONCAT('CPA: ',round(CPA_value,0),' ',Currency,
	CASE WHEN RS_Percentage_Displayed>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage_Displayed,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        WHEN RS_Percentage>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        ELSE '' END)
;
*/

SELECT * FROM campaign_deal_affiliate_v5 d
INNER JOIN campaign_marketing_source m ON m.Deal_id=d.id
;
-- <<<<<<< AFFILIATE <<<<<<<<<<
TRUNCATE           campaign_deal_affiliate_copy;
INSERT IGNORE INTO campaign_deal_affiliate_copy
   SELECT d.* FROM campaign_deal_affiliate d
   INNER JOIN campaign_mkt_source_deal m on d.id=m.Deal_id
   GROUP BY d.id
   ;

UPDATE campaign_deal_affiliate -- _copy
SET Currency=CASE WHEN Currency IS NULL OR Currency=""  THEN "EUR" ELSE Currency END
   ,RS_Base="brand",Operator=CASE WHEN Operator="Gestor_Fra" THEN "2" else Operator END,
`Deal_Name`=
	CONCAT('CPA: ',round(CPA_value,0),' ',Currency,IF(Baseline>0,CONCAT(' BL: ',Baseline,' ',Currency),''),
	CASE WHEN RS_Percentage_Displayed>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage_Displayed,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        WHEN RS_Percentage>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        ELSE '' END)
,Multilevel=0,`OWNER`="",Description="",traffic_source="",Deal_Type="",Advertiser="",Country="",Product="",Carry_Over=""       
;
insert into campaign_deal_affiliate_copy (id,Deal_Name,CPA_Value,RS_Percentage,RS_Against_CPA,Baseline,Currency) values
 (11,'',0,0,0,0,'EUR')
,(12,'',20,0,0,10,'EUR')
,(13,'',25,0,0,5,'EUR')
,(14,'',25,0,0,2,'EUR')
,(15,'',10,0,0,5,'EUR')
,(16,'',25,0,0,5,'EUR')
,(17,'',15,0,0,2,'EUR')
,(18,'',20,0,0,5,'EUR')
,(19,'',25,0,0,10,'EUR')
,(20,'',25,0,0,10,'EUR')
,(21,'',25,0,0,12,'EUR')
,(22,'',20,0,0,4,'EUR')
,(23,'',0,0,0,0,'BRL')
,(24,'',125,0,0,100,'BRL')
,(25,'',175,0,0,100,'BRL')
,(26,'',150,0,0,100,'BRL')
,(27,'',150,0,0,100,'BRL')
,(28,'',150,0,0,100,'BRL')
,(29,'',60,0,0,15,'BRL')
;
TRUNCATE           campaign_deal_affiliate;
INSERT IGNORE INTO campaign_deal_affiliate
   SELECT d.* FROM brasiliacon_dev.campaign_deal_affiliate_copy d
;
-- <<<<<<< GESTOR <<<<<<<<<<
/*
SELECT  d.`id`,d.`Multilevel`,d.`Owner`,d.`Deal_Name`,d.`Description`,d.`traffic_source`,d.`CPA_Value`,d.`RS_Percentage`
       ,d.`RS_Percentage_Displayed`,d.`RS_Base`,d.`Carry_Over`,d.`RS_Against_CPA`,d.`Valid_From`,d.`Status`,d.`Status_id`
       ,d.`Baseline`,d.`Deal_Type`,d.`Advertiser`,d.`Country`,d.`Currency`,d.`Product`,d.`Campaign_id`
       ,d.`Last_Update`,d.`Creation_Date`,d.`Operator` 
FROM campaign_deal_gestor
*/
TRUNCATE           campaign_deal_gestor_copy;
INSERT IGNORE INTO campaign_deal_gestor_copy 
   SELECT d.`id`,d.`Multilevel`,d.`Owner`,d.`Deal_Name`
       ,"" as `Description`,"" as `traffic_source`
       ,d.`CPA_Value`,d.`RS_Percentage`
       ,d.`RS_Percentage_Displayed`
       ,case when d.`RS_Percentage`>0 and d.`RS_Base`="" then "Publisher/Account" else d.`RS_Base` end
       ,case when d.`Carry_Over`!='1' then "0" else d.`Carry_Over` end
       ,d.`RS_Against_CPA`,d.`Valid_From`,d.`Status`,d.`Status_id`
       ,d.`Baseline`
       ,"" as `Deal_Type`
       ,"" as `Advertiser`
       ,"" as `Country`
       ,u.`Data_Currency`
       ,"" as `Product`
       ,null as `Campaign_id`
       ,d.`Last_Update`,d.`Creation_Date`,d.`Operator`
   FROM campaign_deal_gestor d
   INNER JOIN campaign_deal_gestor_prod_date m on d.id=m.Deal_id
   LEFT  JOIN campaign_username u on u.id=m.Username_id
   GROUP BY d.id
   ;
 
UPDATE campaign_deal_gestor -- _copy
SET Currency=""
   ,Operator=CASE WHEN Operator="Gestor_Fra" THEN "2" else Operator END,
`Deal_Name`=
	CONCAT('CPA: ',round(CPA_value,0),IF(Baseline>0,CONCAT(' BL: ',Baseline),''),
	CASE WHEN RS_Percentage_Displayed>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage_Displayed,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        WHEN RS_Percentage>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),'/COv:',IF(Carry_Over>0,'Yes','No'),')')
        ELSE '' END)
;
SELECT * FROM campaign_deal_gestor_copy d
INNER JOIN campaign_username m ON m.Deal_Main_id=d.id
;
TRUNCATE           campaign_deal_gestor;
INSERT IGNORE INTO campaign_deal_gestor
   SELECT d.* FROM brasiliacon_dev.campaign_deal_gestor_copy d
;
-- /*
-- truncate Snapshot_day_by_day_fact1;
-- truncate Snapshot_day_by_day_fact2;
call Snapshot_day_by_day_fact1_upd_from_dbd('AllAll');  
call Snapshot_day_by_day_fact1_upd_from_dbd_manual('AllAll'); 
call Sync_Fact2_from_Fact1('mode=RUN,month=2024-05,MS_id=allall,db=brasiliacon');
call Sync_Fact2_from_Fact1('mode=RUN,month=2024-06,MS_id=allall,db=brasiliacon');
call Sync_Fact2_from_Fact1('mode=RUN,month=LM,MS_id=allall,db=brasiliacon_dev');
call Sync_Fact2_from_Fact1('mode=RUN,month=CM,MS_id=allall,db=brasiliacon_dev');
*/

-- <<<<<<< ---- <<<<<<<<<<
-- TRUNCATE           campaign_deal_affiliate;
-- INSERT IGNORE INTO campaign_deal_affiliate 
   SELECT d.id AS DealID,d.Deal_Name
         ,case when u.Data_Currency="brl" then d.CPA_Value*5 ELSE d.CPA_Value end
         ,d.RS_Percentage,d.RS_Against_CPA,d.Baseline
         ,u.Data_Currency Curr_Deal
--          ,u.Data_Currency AS Curr_Acct
         ,m.MS_id
         ,p.Advertiser_Name AS publisher,p.id,u.Username AS Account,u.id
   FROM campaign_deal_affiliate d
   INNER JOIN campaign_mkt_source_deal m on d.id=m.Deal_id
   INNER JOIN campaign_marketing_source ms ON ms.id=m.MS_id   
   INNER JOIN campaign_username u on u.id=ms.Username_id
   INNER JOIN campaign_publisher p on p.id=u.Publisher_id
   INNER JOIN campaign_advertiser a on a.id=u.Advertiser_id
   GROUP BY d.id,m.MS_id,u.id
   ORDER BY p.Advertiser_Name,u.Username,d.id
   ;
   -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      SELECT d.id AS DealID,d.Deal_Name
         ,case when u.Data_Currency="brl" then d.CPA_Value*5 ELSE d.CPA_Value END AS CPA_Value
         ,d.RS_Percentage,d.RS_Against_CPA,d.Baseline
         ,u.Data_Currency Curr_Deal
--          ,u.Data_Currency AS Curr_Acct
         ,m.id AS rule,m.MS_id
         ,p.Advertiser_Name AS publisher,p.id AS PublID,u.Username AS Account,u.id AS usernameID
   -- FROM campaign_deal_affiliate d
   FROM campaign_mkt_source_deal m
   -- INNER JOIN campaign_mkt_source_deal m on d.id=m.Deal_id
   INNER JOIN campaign_deal_affiliate d on d.id=m.Deal_id
   INNER JOIN campaign_marketing_source ms ON ms.id=m.MS_id   
   INNER JOIN campaign_username u on u.id=ms.Username_id
   INNER JOIN campaign_publisher p on p.id=u.Publisher_id
   INNER JOIN campaign_advertiser a on a.id=u.Advertiser_id
   GROUP BY d.id,m.MS_id,u.id
   ORDER BY d.id,Curr_Deal DESC ,p.Advertiser_Name,u.Username -- ,d.id
   ;


insert into campaign_deal_affiliate_copy (id,Deal_Name,CPA_Value,RS_Percentage,RS_Against_CPA,Baseline,Currency) values
 (11,'',0,0,0,0,'EUR')
,(12,'',20,0,0,10,'EUR')
,(13,'',25,0,0,5,'EUR')
,(14,'',25,0,0,2,'EUR')
,(15,'',10,0,0,5,'EUR')
,(16,'',25,0,0,5,'EUR')
,(17,'',15,0,0,2,'EUR')
,(18,'',20,0,0,5,'EUR')
,(19,'',25,0,0,10,'EUR')
,(20,'',25,0,0,10,'EUR')
,(21,'',25,0,0,12,'EUR')
,(22,'',20,0,0,4,'EUR')
,(23,'',0,0,0,0,'BRL')
,(24,'',125,0,0,100,'BRL')
,(25,'',175,0,0,100,'BRL')
,(26,'',150,0,0,100,'BRL')
,(27,'',150,0,0,100,'BRL')
,(28,'',150,0,0,100,'BRL')
,(29,'',60,0,0,15,'BRL')
;

-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
SELECT md.*
   ,d.id,d.Deal_Name,d.CPA_Value,d.RS_Percentage,d.RS_Against_CPA,d.Baseline,d.Currency
   ,dc.id,dc.Deal_Name,dc.CPA_Value,dc.RS_Percentage,dc.RS_Against_CPA,dc.Baseline,dc.Currency
FROM campaign_mkt_source_deal md
INNER JOIN campaign_marketing_source ms ON ms.id=md.MS_id   
INNER JOIN campaign_username u on u.id=ms.Username_id
INNER JOIN campaign_deal_affiliate d on d.id=md.Deal_id
INNER JOIN LATERAL (select * from campaign_deal_affiliate_copy dc 
                     where dc.Currency=u.Data_Currency
                       and dc.CPA_Value=case when u.Data_Currency="brl" then d.CPA_Value*5 ELSE d.CPA_Value END
                       and dc.RS_Percentage=d.RS_Percentage
                       and dc.Baseline=case when u.Data_Currency="brl" then d.Baseline*5 ELSE d.Baseline END
                       limit 1
                    ) as dc
-- where u.Data_Currency="brl"                    
;
-- SELECT md.*
   -- ,d.id,d.Deal_Name,d.CPA_Value,d.RS_Percentage,d.RS_Against_CPA,d.Baseline,d.Currency
   -- ,dc.id,dc.Deal_Name,dc.CPA_Value,dc.RS_Percentage,dc.RS_Against_CPA,dc.Baseline,dc.Currency
-- FROM campaign_mkt_source_deal md
UPDATE campaign_mkt_source_deal_copy md
INNER JOIN campaign_marketing_source ms ON ms.id=md.MS_id   
INNER JOIN campaign_username u on u.id=ms.Username_id
INNER JOIN campaign_deal_affiliate d on d.id=md.Deal_id
INNER JOIN LATERAL (select * from campaign_deal_affiliate_copy dc 
                     where dc.Currency=u.Data_Currency
                       and dc.CPA_Value=case when u.Data_Currency="brl" then d.CPA_Value*5 ELSE d.CPA_Value END
                       and dc.RS_Percentage=d.RS_Percentage
                       and dc.Baseline=case when u.Data_Currency="brl" then d.Baseline*5 ELSE d.Baseline END
                       limit 1
                    ) as dc
SET md.Deal_id=dc.id,md.Channel_id=0
-- where u.Data_Currency="brl"                    
;
-- UPDATE campaign_mkt_source_deal_copy SET Channel_id=0;
TRUNCATE           campaign_mkt_source_deal;
INSERT IGNORE INTO campaign_mkt_source_deal
   SELECT d.* FROM brasiliacon_dev.campaign_mkt_source_deal_copy d
;











SELECT f.Code_To_Affiliate,f.MS_id,f.Deal_Aff_id,f.Data_Currency,u.Data_Currency,d.*
FROM Snapshot_day_by_day_fact1 f
INNER JOIN campaign_deal_affiliate_copy d on d.id=f.Deal_Aff_id
INNER JOIN campaign_username u on u.id=f.Username_id
GROUP BY f.Code_To_Affiliate,f.Data_Currency,f.Deal_Aff_id
ORDER BY f.Code_To_Affiliate,f.Data_Currency,f.Deal_Aff_id
;