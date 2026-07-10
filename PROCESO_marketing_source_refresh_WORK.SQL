/**
 
   REEMPLAZO MASIVO DE MS CONSERVANDO Cod2Affiliate
   14.02.2024
   Creación y reformateo de tablas
   para proceso: call marketing_source_refresh();
   
*/

DROP TABLE IF EXISTS `campaign_tracking_sources`;

CREATE TABLE IF NOT EXISTS `campaign_tracking_sources` (
  `id`            int NOT NULL AUTO_INCREMENT,
  `Publisher`     varchar(100) NULL DEFAULT NULL,
  `Publisher_id`  int          NULL DEFAULT NULL,
  `Brand`         varchar(100) NULL DEFAULT NULL,
  `Advertiser_id` int          NULL DEFAULT NULL,
  `Account_id`    int          NULL DEFAULT NULL,
  `Account`       varchar(100) NULL DEFAULT NULL,
  `Product`       varchar(100) NULL DEFAULT NULL,
  `Tracker_id`    varchar(100) NULL DEFAULT NULL,
  `Tracker_Name`  varchar(100) NULL DEFAULT NULL,
  `Tracklink`     Varchar(200) NULL DEFAULT NULL,
  `Status_id`     Varchar(2)   NULL DEFAULT '',
  `Creation_Date` datetime     NULL DEFAULT CURRENT_TIMESTAMP,
  `Last_Update`   datetime     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `Operator`      varchar(30)  NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
        
INSERT INTO campaign_tracking_sources
(`Publisher`,`Brand`,`Account_id`,`Account`,`Product`,`Tracker_id`,`Tracker_name`,`Tracklink`)
VALUES ("Entain","Bwin","5","giocatorivip","SPORT","54541100","reinaldo65","https://mediaserver.entainpartners.com/renderBanner.do?zoneId=2130282"),
       ("Entain","Bwin","5","giocatorivip","SPORT","54541066","reinaldo23","https://mediaserver.entainpartners.com/renderBanner.do?zoneId=2130278"),
       ("Entain","Gioco Digitale","93","Betquoteit","CASINO","54541111","reinaldo56","https://mediaserver.entainpartners.com/renderBanner.do?zoneId=2130283"),
       ("Entain","Gioco Digitale","93","Betquoteit","CASINO","54541077","reinaldo32","https://mediaserver.entainpartners.com/renderBanner.do?zoneId=2130279"),
       ("Betpartners","EuroBet","15","Misteraff_1","SPORT","lookño111","lookño111","https://record.betpartners.it/_ooS83izLXsmPR5lwTtbLKGNd7ZgqdRLk/93/"),
       ("Betpartners","EuroBet","15","Misteraff_1","SPORT","zjhaef122","zjhaef122","https://record.betpartners.it/_ooS83izLXsmPR5lwTtbLKGNd7ZgqdRLk/91/"),
       ("Betpartners","EuroBet","15","Misteraff_1","CASINO","hubuy344","hubuy344","https://record.betpartners.it/_ooS83izLXskd2bMnnkYwymNd7ZgqdRLk/92/"),
       ("Betpartners","EuroBet","15","Misteraff_1","CASINO","hftftkj988","hftftkj988","https://record.betpartners.it/_ooS83izLXskd2bMnnkYwymNd7ZgqdRLk/90/"),
       ("Sisal","Sisal","196","Affiliateintelligence","CASINO","iusbd555","iusbd555","https://ads.sisal.it/promoRedirect?key=ej0xMzc3NzMwNSZsPTE1ODE2NTM5JnA9MTI2MDEx"),
       ("Sisal","Sisal","196","Affiliateintelligence","CASINO","jdjwnc555","jdjwnc555","https://ads.sisal.it/promoRedirect?key=ej0xMzc3NzMwNSZsPTE1ODAzMzM5JnA9MTI1OTg5"),
       ("Sisal","Sisal","196","Affiliateintelligence","SPORT","ladno444","ladno444","https://ads.sisal.it/promoRedirect?key=ej0xMzc3NzMwNSZsPTE1ODE2NTE5JnA9MTI2MDA5"),
       ("Sisal","Sisal","196","Affiliateintelligence","SPORT","sjbuyer66","sjbuyer66","https://ads.sisal.it/promoRedirect?key=ej0xMzc3NzMwNSZsPTE1ODE2NTE5JnA9MTI2MDI5")
;
-- --------------------------------------------------------
UPDATE campaign_tracking_sources t
LEFT JOIN campaign_username u on u.id=t.`Account_id`
SET  t.`Publisher_id`=u.`Publisher_id`
    ,t.`Advertiser_id`=u.`Advertiser_id`
    ,t.Status_id=''
;
-- --------------------------------------------------------
DROP TABLE IF EXISTS `campaign_marketing_source_refresh`;
CREATE TABLE `campaign_marketing_source_refresh`
SELECT * FROM campaign_marketing_source
WHERE Status_id IN ("1","6")
  AND OWNER=IN (2,864, 865, 866)
  AND Advertiser_id IN (1,3,2,13) -- Adecuar a lo que se quiere
--   AND Affiliate_id IN (39,130)    -- Sólo para pruebas
  AND Deal_id IS NOT NULL         -- Sólo para pruebas
;
ALTER TABLE `campaign_marketing_source_refresh` CHANGE COLUMN `id` `id` INT(10) NULL DEFAULT NULL;

UPDATE `campaign_marketing_source_refresh`
SET `Code`=`Tracker_id`,
    `Creation_Date`=null,`Last_Update`=NULL,`Tracker_id`=NULL -- ,`Username_id`=NULL
;

-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
call marketing_source_refresh();
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------

-- ---------- PROCESOS LUEGO DE call marketing_source_refresh();
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------

-- Actualiza MS anterior para cambio de Afiliado
UPDATE `campaign_marketing_source` m
INNER JOIN `campaign_marketing_source_refresh` r ON r.id=m.id AND r.`Tracker_id` IS NOT NULL
SET m.Description=CONCAT("Swap date: ",CURDATE()," Previous affiliate: ",m.Affiliate_id),
    m.Affiliate_id=2,m.Channel_id=null,m.Shortlink_id=NULL,
    m.Deal_Valid_From="2024-02-01",  -- Adecuar a lo que se quiere
    m.Deal_id=CASE when m.Deal_id IS NULL then 0 ELSE m.Deal_id END ,
    m.Operator="SwapSysOp"
;
 
-- Prepara campaign_marketing_source_refresh para insertar nuevas en MS (con id null)
UPDATE `campaign_marketing_source_refresh` r 
SET r.Description=CONCAT("Swap date: ",CURDATE()," Swapped MS: ",r.id),
    r.id = NULL,r.Creation_Date= CURRENT_TIMESTAMP(),r.Operator="SwapSysOp"
WHERE r.`Tracker_id` IS NOT NULL;

-- Inserta MS nuevas
INSERT INTO campaign_marketing_source
   SELECT * FROM campaign_marketing_source_refresh r
   WHERE r.`Tracker_id` IS NOT NULL AND r.id IS NULL
;