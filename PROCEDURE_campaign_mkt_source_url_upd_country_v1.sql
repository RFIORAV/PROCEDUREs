/*
PROCEDURE_campaign_mkt_source_url_upd_country_v1.sql - Update Country_web from account_landing_pages

Descripción:
  Procedimiento campaign_mkt_source_url_upd_country.

Keys:

22.02.2025 v1  Se ejecuta en EVENT cada media hora

*/
-- ----------------------------------------------------------
DROP PROCEDURE IF EXISTS campaign_mkt_source_url_upd_country;
-- ----------------------------------------------------------

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `campaign_mkt_source_url_upd_country`()

    COMMENT 'Update Country_web from account_landing_pages'

ProcedureBody: BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 22.02.2025';
SET @CurrentDay      =CURDATE();

UPDATE campaign_mkt_source_url u
INNER JOIN campaign_marketing_source m on m.id=u.MS_id
INNER JOIN account_landing_pages ch on ch.id=m.Channel_id
SET u.Channel_web=ch.nation
WHERE IFNULL(ch.nation,'')>'' AND NOT (u.Channel_web<=>ch.nation)
;

END;
$$
DELIMITER ;
-- -----------------------------------------------------
-- -----------------------------------------------------
/*
SELECT u.MS_id,m.Channel_id,ch.nation,u.Channel_web 
FROM campaign_mkt_source_url u
-- UPDATE campaign_mkt_source_url u
inner join campaign_marketing_source m on m.id=u.MS_id
inner join account_landing_pages ch on ch.id=m.Channel_id
-- set u.Channel_web=ch.nation
WHERE ifnull(ch.nation,'')>'' and NOT (u.Channel_web<=>ch.nation)
;
*/
