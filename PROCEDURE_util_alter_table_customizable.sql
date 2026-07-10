/*
PROCEDURE_util_alter_table_customizable.sql - Ajuste masivo de longitud de columna Product

Descripción:
  Procedimiento util_alter_table_customizable.

Keys:

Version history:
27.03.2026 v1.0 

Usage:
CALL util_alter_table_customizable();

Observaciones:
- Recorre tablas BASE TABLE del esquema actual con nombre Snapshot_day_by_day%
- Aplica ALTER TABLE ... CHANGE COLUMN Product a VARCHAR(200) NULL DEFAULT NULL
*/

-- ALTER TABLE `Snapshot_day_by_day_fact2`  CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_2021                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_2022                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_2023                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_2024                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_2025                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_copy                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_dev                  CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_dev_copy             CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact1                CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact1_2022           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact1_2023           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact1_2024           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact2                CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact2_2022           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact2_2023           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_fact2_2024           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_lm                   CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_manual               CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_temp                 CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_temp_NR              CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_temp_NR_AR           CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_temp_NR_dev          CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;
-- ALTER TABLE Snapshot_day_by_day_temp_lm              CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL;

DROP PROCEDURE IF EXISTS util_alter_table_customizable;
DELIMITER $$

CREATE PROCEDURE util_alter_table_customizable()
COMMENT 'Ajusta Product a VARCHAR(200) en tablas Snapshot_day_by_day%'
SQL SECURITY DEFINER
ProcedureBody: BEGIN
    DECLARE v_Version VARCHAR(30);
    DECLARE v_done INT DEFAULT 0;
    DECLARE v_table_name VARCHAR(255);
    DECLARE v_sql TEXT;

    DECLARE cur CURSOR FOR
        SELECT c.TABLE_NAME
        FROM information_schema.COLUMNS c
        JOIN information_schema.TABLES t
          ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
         AND t.TABLE_NAME = c.TABLE_NAME
        WHERE c.TABLE_SCHEMA = DATABASE()
          AND t.TABLE_TYPE = 'BASE TABLE'
          AND c.TABLE_NAME LIKE 'Snapshot_day_by_day%'
          AND c.COLUMN_NAME = 'Product'
          AND c.DATA_TYPE IN ('char','varchar')
          AND c.CHARACTER_MAXIMUM_LENGTH < 200;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    SET v_Version = 'v1 27.03.2026';

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_table_name;
        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        SET v_sql = CONCAT(
            'ALTER TABLE `', REPLACE(v_table_name, '`', '``'),
            '` CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL'
        );

        -- PREPARE en MySQL requiere variable de sesion para SQL dinamico
        SET @sql = v_sql;
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;