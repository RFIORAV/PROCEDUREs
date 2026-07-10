/*
PROCEDURE_sync_common_tables_upd.sql 

Descripción:
  Procedimiento sync_common_tables_upd.
   - Update tabla exchange_rate               desde euroaffiliati2.exchange_rate
   - Update tabla campaign_advertiser_licence desde euroaffiliati2.campaign_advertiser_licence

Keys:

Ejemplos:

call sync_common_tables_upd();

25.07.2024 V1     Update tabla exchange_rate
05.09.2024 v1.1   Update tabla campaign_advertiser_licence
                  PROCEDURE_exchange_rate_upd.sql obsoleto
2025.10.24 v1.2   Utilizar Prepared Statements

*/

DROP PROCEDURE IF EXISTS sync_common_tables_upd;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `sync_common_tables_upd`()
    COMMENT 'Update exchange_rate/campaign_advertiser_licence desde ea'
    
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.2 2025.10.24';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Debug           ='NO';
SET @Meta            ='YES';
SET @DB              =DATABASE();

-- Sincronizar tabla exchange_rate
IF @DB!="euroaffiliati2" THEN
   SET @sql_exchange = CONCAT('CREATE TABLE IF NOT EXISTS exchange_rate LIKE euroaffiliati2.exchange_rate');
   PREPARE stmt_exchange_create FROM @sql_exchange;
   EXECUTE stmt_exchange_create;
   DEALLOCATE PREPARE stmt_exchange_create;
   
   SET @sql_exchange = 'TRUNCATE exchange_rate';
   PREPARE stmt_exchange_truncate FROM @sql_exchange;
   EXECUTE stmt_exchange_truncate;
   DEALLOCATE PREPARE stmt_exchange_truncate;
   
   SET @sql_exchange = 'INSERT IGNORE INTO exchange_rate SELECT * FROM euroaffiliati2.exchange_rate';
   PREPARE stmt_exchange_insert FROM @sql_exchange;
   EXECUTE stmt_exchange_insert;
   DEALLOCATE PREPARE stmt_exchange_insert;
END IF;

-- Sincronizar tabla campaign_advertiser_licence
IF @DB!="euroaffiliati2" THEN
   SET @sql_campaign = CONCAT('CREATE TABLE IF NOT EXISTS campaign_advertiser_licence LIKE euroaffiliati2.campaign_advertiser_licence');
   PREPARE stmt_campaign_create FROM @sql_campaign;
   EXECUTE stmt_campaign_create;
   DEALLOCATE PREPARE stmt_campaign_create;
   
   SET @sql_campaign = 'TRUNCATE campaign_advertiser_licence';
   PREPARE stmt_campaign_truncate FROM @sql_campaign;
   EXECUTE stmt_campaign_truncate;
   DEALLOCATE PREPARE stmt_campaign_truncate;
   
   SET @sql_campaign = 'INSERT IGNORE INTO campaign_advertiser_licence SELECT * FROM euroaffiliati2.campaign_advertiser_licence';
   PREPARE stmt_campaign_insert FROM @sql_campaign;
   EXECUTE stmt_campaign_insert;
   DEALLOCATE PREPARE stmt_campaign_insert;
END IF;

END$$

DELIMITER ;

/*
Ejemplos:

CALL sync_common_tables_upd();

*/