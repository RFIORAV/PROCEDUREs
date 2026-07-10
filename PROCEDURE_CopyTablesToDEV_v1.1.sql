/*
PROCEDURE_CopyTablesToDEV.sql -  ACTUALIZAR TABLAS euroaffiliati_dev desde euroaffiliati2

Descripción:
  Procedimiento CopyTablesToDEV.

Keys:
  DB_destination = [valor]. Parámetro de entrada.

29.08.2024 v1
05.06.2025 v1.1   DB destino como parámetro. Default=euroaffiliati_dev
03.07.2026 v1.2   Añadidas nuevas tablas.
*/

DROP PROCEDURE IF EXISTS CopyTablesToDEV;
    
-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE CopyTablesToDEV(IN DB_destination varchar (80))
COMMENT 'v1.2 - 03.07.2026 Procedimiento CopyTablesToDEV.'

Proc_Main:BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);
    DECLARE version VARCHAR(255) DEFAULT 'v1.2 - 03.07.2026';

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
    
    SET @Debug="no";
    
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
        
        IF @Debug="YES" 
        THEN
            SELECT @K_fields_diff,@dropTableQuery,@copyTableQuery,@truncateTableQuery,@insertDataQuery;
            LEAVE Proc_Main;
        END IF;        
        
        PREPARE stmt FROM @copyTableQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        PREPARE stmt FROM @truncateTableQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        PREPARE stmt FROM @insertDataQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
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