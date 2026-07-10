/* PROCEDURE_Show_mkt_sources_deal.sql
   26.10.2022 V1 Muestra los registros de una MS en campaign_mkt_source_deal

Descripción:
  Procedimiento MktSrcDeal.

Keys:
  MS_id_IN = [valor]. Parámetro de entrada.
   
*/
DROP PROCEDURE IF EXISTS MktSrcDeal;

DELIMITER $$
CREATE PROCEDURE MktSrcDeal(IN MS_id_IN int)
   
   COMMENT 'campaign_mkt_source_deal - Show records'
   LANGUAGE SQL

BEGIN

SET @Version         ='v1 26.10.2022';
SET @Month           =left(curdate(),7);
SET @MS_id           =MS_id_IN;

SELECT D.`id`,D.`MS_id`,D.`Deal_Valid_From`,IFNULL(D.`Product`,"Any non defined") AS Product
   ,IFNULL(`A`.`username`, "_Unassigned") AS `Affiliate`
   ,IFNULL(`CDA`.`Deal_Name`,"") AS `Deal`
   ,IFNULL(`CH`.`landing_page_name`,"") AS `Channel`
   ,D.`Affiliate_id`,D.`Channel_id`,D.`Deal_id`
   ,D.`is_active`,D.`Code`
   ,D.`Creation_Date`,D.`Last_Update`,D.`Operator` 
FROM campaign_mkt_source_deal D
LEFT JOIN `account_account` `A` ON `A`.`id` = `D`.`Affiliate_id`
LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id` = `D`.`Deal_id`
LEFT JOIN `account_landing_pages` `CH` ON `CH`.`id` = `D`.`Channel_id`
WHERE D.MS_id=@MS_id

;

END$$
DELIMITER ;

/*
CALL MktSrcDeal(1791);

*/