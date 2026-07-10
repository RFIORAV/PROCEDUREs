/*REATE_gambling_tables_from_DB_A_to_DB_B.sql


Descripción:
  Procedimiento CreateGamblingTablesFromAtoB.
Script MySQL 8.0 que crea en la base de datos destino las tablas que coinciden con un patrón
que existen en la base de datos origen y que no existen en la base de datos destino.

Keys:
p_db_origen = [valor]. Parámetro de entrada.
p_db_destino = [valor]. Parámetro de entrada.
p_table_pattern = [valor]. Parámetro de entrada.

INSTRUCCIONES:
1. Ejecutar el script para crear el procedimiento almacenado
2. Llamar al procedimiento con los parámetros necesarios:
   CALL CreateGamblingTablesFromAtoB('DB_ORIGEN', 'DB_DESTINO', 'patron_tablas');

Ejemplo:
   CALL CreateGamblingTablesFromAtoB('euroaffiliati2', 'euroaffiliati_dev', 'gambling_%');

2026-01-13 V1
*/

-- ============================================================
-- PROCEDIMIENTO ALMACENADO
-- ============================================================
DROP PROCEDURE IF EXISTS CreateGamblingTablesFromAtoB;

DELIMITER //

CREATE PROCEDURE CreateGamblingTablesFromAtoB(
    IN p_db_origen VARCHAR(255),
    IN p_db_destino VARCHAR(255),
    IN p_table_pattern VARCHAR(255)
)
COMMENT 'Procedimiento CreateGamblingTablesFromAtoB.'
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);
    DECLARE tableExists INT DEFAULT 0;
    
    -- Cursor para obtener todas las tablas que coinciden con el patrón en la DB origen
    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME 
        FROM `information_schema`.`TABLES` 
        WHERE TABLE_SCHEMA = p_db_origen
        AND table_type = 'BASE TABLE'
        AND TABLE_NAME LIKE p_table_pattern
        ORDER BY TABLE_NAME ASC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Crear tabla temporal para almacenar los mensajes
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_mensajes (
        id INT AUTO_INCREMENT PRIMARY KEY,
        mensaje TEXT,
        orden INT DEFAULT 0
    );
    
    -- Desactivar verificación de claves foráneas temporalmente
    SET FOREIGN_KEY_CHECKS = 0;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO tableName;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si la tabla ya existe en la DB destino
        SELECT COUNT(*) INTO tableExists
        FROM `information_schema`.`TABLES`
        WHERE TABLE_SCHEMA = p_db_destino
        AND TABLE_NAME = tableName;
        
        -- Si la tabla no existe, crearla
        IF tableExists = 0 THEN
            SET @createTableQuery = CONCAT('CREATE TABLE IF NOT EXISTS `', p_db_destino, '`.`', tableName, '` LIKE `', p_db_origen, '`.`', tableName, '`');
            
            PREPARE stmt FROM @createTableQuery;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            -- Insertar mensaje en tabla temporal
            INSERT INTO temp_mensajes (mensaje) VALUES (CONCAT('✓ Tabla creada: ', tableName));
        ELSE
            -- Insertar mensaje en tabla temporal
            INSERT INTO temp_mensajes (mensaje) VALUES (CONCAT('⊘ Tabla ya existe (omitida): ', tableName));
        END IF;
        
    END LOOP;
    
    CLOSE cur;
    
    -- Reactivar verificación de claves foráneas
    SET FOREIGN_KEY_CHECKS = 1;
    
    -- Mostrar todos los mensajes acumulados
    SELECT mensaje AS Resultado FROM temp_mensajes ORDER BY id;
    
    -- Mostrar mensaje final
    -- SELECT 'Proceso completado.' AS Finalizado;
    
END //

DELIMITER ;

-- ============================================================
-- EJEMPLO DE EJECUCIÓN DEL PROCEDIMIENTO
-- ============================================================
-- CALL CreateGamblingTablesFromAtoB('DB_A', 'DB_B', 'gambling_%');

-- ============================================================
-- OPCIONAL: Eliminar el procedimiento después de usarlo
-- ============================================================
-- DROP PROCEDURE IF EXISTS CreateGamblingTablesFromAtoB;
