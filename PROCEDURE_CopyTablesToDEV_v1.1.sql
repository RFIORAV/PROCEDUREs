/*
PROCEDURE_CopyTablesToDEV.sql -  ACTUALIZAR TABLAS euroaffiliati_dev desde euroaffiliati2

Descripción:
  Procedimiento CopyTablesToDEV.

Keys:
  DB_destination = [valor]. Parámetro de entrada.
  
Examples:

CALL CopyTablesToDEV('');
CALL CopyTablesToDEV('affacc_dev');
CALL CopyTablesToDEV('euroaffiliati_mkt');

29.08.2024 v1
05.06.2025 v1.1   DB destino como parámetro. Default=euroaffiliati_dev
03.07.2026 v1.2   Añadidas nuevas tablas.
15.07.2026 v1.3   Añadida comprobación de tablas a copiar según db destino.
*/

DROP PROCEDURE IF EXISTS CopyTablesToDEV;
    
-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE CopyTablesToDEV(IN DB_destination varchar (80))
COMMENT 'v1.3 - 15.07.2026 Procedimiento CopyTablesToDEV.'

Proc_Main:BEGIN
    DECLARE version VARCHAR(255) DEFAULT 'v1.3 - 15.07.2026';
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);

    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME 
        FROM `information_schema`.`TABLES` 
        WHERE TABLE_SCHEMA = 'euroaffiliati2' 
        AND table_type = 'BASE TABLE' 
        AND (
            TABLE_NAME LIKE 'account_%'    
         OR TABLE_NAME LIKE 'campaign_%'    
         OR TABLE_NAME LIKE 'master_%'    
         OR TABLE_NAME LIKE 'super_%'   
         OR TABLE_NAME LIKE 'comm_%'   
        --  OR TABLE_NAME LIKE 'dash%'   
         OR TABLE_NAME LIKE 'postback%'              
        --  OR TABLE_NAME LIKE 'util_%'
         OR TABLE_NAME LIKE 'players_netrefer_API' 
         OR TABLE_NAME LIKE 'Snapshot%'  
         OR TABLE_NAME LIKE 'monthly_comms%'  
         OR TABLE_NAME LIKE 'legal_entities'  
        )
        AND TABLE_NAME NOT LIKE '%history'
        AND TABLE_NAME NOT LIKE '%_202%'
        AND TABLE_NAME NOT LIKE '%copy'
        AND TABLE_NAME NOT LIKE '%_url'       
--         AND TABLE_NAME NOT LIKE 'notification%' 
        ORDER BY `TABLE_NAME` ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET @Debug="NO";
    
    IF DB_destination="" THEN SET DB_destination="euroaffiliati_dev"; END IF;

    SET FOREIGN_KEY_CHECKS = 0;
 
    SET @truncateTableURL  = CONCAT('TRUNCATE ',DB_destination,'.campaign_mkt_source_url;');
    PREPARE stmt FROM @truncateTableURL;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO tableName;
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF  DB_destination="euroaffiliati_mkt" AND
           (tableName="account_account" 
         OR tableName="campaign_campaign" 
         OR tableName="account_affiliate_interactions"
         OR tableName="campaign_deal_affiliate"
         OR tableName="campaign_deal_affiliate_bonus"
         OR tableName="monthly_comms_affiliate_v5"
         OR tableName="account_publisher_interactions"
         OR tableName="campaign_publisher_proforma"
         OR tableName="account_account_bills"
         OR tableName="account_account_files"
         OR tableName="account_account_filters"
         OR tableName="account_account_groups"
         OR tableName="account_account_referral"
         OR tableName="account_account_table_setting"
         OR tableName="account_account_tags"
         OR tableName="account_account_tags_list"
         OR tableName="account_dash_module_access"
         OR tableName="account_dash_module_layouts"
         OR tableName="account_financial_movement"
         OR tableName="account_landing_pages"
         OR tableName="account_manual_adjustments"
         OR tableName="account_publisher_interactions"
         OR tableName="campaign_log_dashboard"
         OR tableName="campaign_publisher_%"
         OR tableName="account_notifications%"
         OR tableName="account_payment_method%"
         OR tableName="campaign_bonus"
         OR tableName LIKE "campaign_deal%"
         OR tableName LIKE "campaign_mkt_source_%"
         OR tableName LIKE "campaign_shortlink"
         OR tableName LIKE "campaign_sub_username"
         OR tableName LIKE "comm_%"
         OR tableName LIKE "dash_%"
         OR tableName LIKE "legal_entities"
         OR tableName LIKE "master_affiliate_%"
         OR tableName LIKE "monthly_comms_%"
         OR tableName LIKE "multi_query"
         OR tableName LIKE "setting_%"
         OR tableName LIKE "util_%"
         )
        THEN
            ITERATE read_loop;
        END IF;
        
        SET @K_fields_diff =(
             SELECT COUNT(*) FROM information_schema.columns 
             WHERE table_schema = 'euroaffiliati2' AND table_name = tableName
             )- 
             (
             SELECT COUNT(*) FROM information_schema.columns 
             WHERE table_schema = DB_destination AND table_name = tableName
             );

        IF @K_fields_diff!=0 
        THEN 
             SELECT tableName," Distinta estructura" FROM DUAL; 
             SET @dropTableQuery  = CONCAT('DROP TABLE IF EXISTS ',DB_destination,'.', tableName, ';');
             PREPARE stmt FROM @dropTableQuery;
             EXECUTE stmt;
             DEALLOCATE PREPARE stmt;
        END IF;   

        -- SELECT tableName FROM DUAL;
        
        SET @copyTableQuery      = CONCAT('CREATE TABLE IF NOT EXISTS ',DB_destination,'.', tableName, ' LIKE euroaffiliati2.', tableName);
        SET @truncateTableQuery  = CONCAT('TRUNCATE ',DB_destination,'.', tableName, ';');
        SET @insertDataQuery     = CONCAT('INSERT INTO ',DB_destination,'.', tableName, ' SELECT * FROM euroaffiliati2.', tableName);
              
        IF @Debug="NO"        
        THEN
           PREPARE stmt FROM @copyTableQuery;
           EXECUTE stmt;
           DEALLOCATE PREPARE stmt;

           PREPARE stmt FROM @truncateTableQuery;
           EXECUTE stmt;
           DEALLOCATE PREPARE stmt;
           
           PREPARE stmt FROM @insertDataQuery;
           EXECUTE stmt;
           DEALLOCATE PREPARE stmt;     
        END IF;
        
    END LOOP;

    CLOSE cur;

    UPDATE account_account a
    SET a.id_alias='2',a.id_default='2',a.username_alias="Gestor_Fra",a.username_default="Gestor_Fra"
    WHERE id IN (449, 508, 334, 177, 179);   
    
    CALL total_monthy_comm_ges_upd('');
    CALL total_monthy_comm_aff_upd('');
    
END //

DELIMITER ;

/*

CALL CopyTablesToDEV('');
CALL CopyTablesToDEV('affacc_dev');
CALL CopyTablesToDEV('euroaffiliati_mkt');

*/