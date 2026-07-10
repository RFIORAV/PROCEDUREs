/* PATCH VARIOS

*/

DROP PROCEDURE IF EXISTS AddColumnIfNotExists;

DELIMITER //
CREATE PROCEDURE AddColumnIfNotExists()
BEGIN
    DECLARE rowCount INT;
    SELECT COUNT(*) INTO rowCount
    FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name  = 'campaign_username'
      AND column_name = 'stat_publ';

    IF rowCount < 1 THEN
        SET @query ='ALTER TABLE `campaign_username` 	ADD COLUMN `Stat_Publ` VARCHAR(2) NULL DEFAULT "1" AFTER `Stat_Adve`;';
        PREPARE stmt FROM @query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
    -- Inicializa campo nuevo
    UPDATE `campaign_username`
    SET `Stat_Publ`=(SELECT IFNULL(P.Status_id,'1')   FROM campaign_publisher P where P.id=Publisher_id)
    WHERE 1=1;
    
END //
DELIMITER ;

CALL AddColumnIfNotExists();

DROP PROCEDURE IF EXISTS AddColumnIfNotExists;
