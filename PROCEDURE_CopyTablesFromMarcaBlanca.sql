/*
PROCEDURE_CopyTablesFromMarcaBlanca.sql -  Copia tablas con datos básicos desde MarcaBlanca a una db nueva

Descripción:
  Procedimiento CopyTablesFromMarcaBlanca.

Keys:

CONDICIONES DE EJECUCION:
   ESTE PROCEDURE NO SE EJECUTARA SI LA TABLA DESTINO NO ESTA VACIA, PARA EVITAR ERRORES.
   1. Crear una nueba db con la estructura (tablas,views,triggers,procedures) de euraffiliati2 SIN DATOS
   2. Ejecutar este procedure desde la nueva db

02.10.2024 v1

*/

DROP PROCEDURE IF EXISTS CopyTablesFromMarcaBlanca;
    

-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE CopyTablesFromMarcaBlanca()
COMMENT 'Procedimiento CopyTablesFromMarcaBlanca.'

BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);

    DECLARE cur CURSOR FOR 
      WITH tablas_basicas_marca_blanca  as (
        SELECT TABLE_NAME 
        FROM `information_schema`.`TABLES` 
        WHERE TABLE_SCHEMA = 'marca_blanca' 
        AND table_type = 'BASE TABLE' 
        AND TABLE_ROWS > 0
        AND TABLE_NAME NOT LIKE 'django%'
        AND TABLE_NAME NOT LIKE 'api_%'
        AND TABLE_NAME NOT LIKE 'dash_%'
        AND TABLE_NAME NOT LIKE '%_url'
        AND TABLE_NAME NOT LIKE '%_old'
        AND TABLE_NAME NOT LIKE 'auth_ea2_%'
      ),
      tablas_nueva_db  as (
        SELECT TABLE_NAME 
        FROM `information_schema`.`TABLES` 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND table_type = 'BASE TABLE' 
        AND TABLE_ROWS = 0
      )
      SELECT tb.TABLE_NAME 
      FROM tablas_basicas_marca_blanca tb
      INNER JOIN tablas_nueva_db tn ON tb.TABLE_NAME=tn.TABLE_NAME    
      ORDER BY `TABLE_NAME` ASC;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE euroaffiliati_dev.campaign_mkt_source_url;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO tableName;
        IF done THEN
            LEAVE read_loop;
        END IF;
/*
        SET @copyTableQuery = CONCAT('CREATE TABLE IF NOT EXISTS euroaffiliati_dev.', tableName, ' LIKE marca_blanca.', tableName);
        PREPARE stmt FROM @copyTableQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @copyTableQuery = CONCAT('TRUNCATE euroaffiliati_dev.', tableName, ';');
        PREPARE stmt FROM @copyTableQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
  */      
        SET @insertDataQuery = CONCAT('INSERT INTO ', tableName, ' SELECT * FROM marca_blanca.', tableName);
        PREPARE stmt FROM @insertDataQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
    END LOOP;

    CLOSE cur;
    
END //

DELIMITER ;

/*
CALL CopyTablesFromMarcaBlanca();

*/
