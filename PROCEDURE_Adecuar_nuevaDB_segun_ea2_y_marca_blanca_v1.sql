/*
PROCEDURE_Adecuar_nuevaDB_segun_ea2_y_marca_blanca_v1.sql - Transferir contenido de tablas de euroaffiliati2 a tyltyco

DESCRIPCIÓN:
   Transfiere el contenido de las tablas a la base de datos tyltyco y marca_blanca según los siguientes criterios:
   - Desde euroaffiliati2: tablas que existen en tyltyco, NO terminan en "_history" y NO están vacías en marca_blanca
   - Desde marca_blanca: tablas que existen en tyltyco y NO están vacías en marca_blanca
   - Ignorar las tablas cuyo nombre termina en "_history"
   - Ignorar las tablas que existen en db marca_blanca y están vacías (0 registros)

Keys:

CONDICIONES DE EJECUCIÓN:
   1. Las bases de datos euroaffiliati2, tyltyco y marca_blanca deben existir
   2. Las tablas destino en tyltyco y marca_blanca deben tener la misma estructura que las de euroaffiliati2
   3. Se recomienda hacer backup antes de ejecutar

FECHA: $(date)
VERSIÓN: 1.0
*/

DROP PROCEDURE IF EXISTS Adecuar_nuevaDB_segun_ea2_y_marca_blanca;
    
-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE Adecuar_nuevaDB_segun_ea2_y_marca_blanca()
COMMENT 'Procedimiento Adecuar_nuevaDB_segun_ea2_y_marca_blanca.'

Proc_Main:BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);
    DECLARE sourceDb VARCHAR(255);
    DECLARE rowsCount INT DEFAULT 0;
    DECLARE debugMode VARCHAR(10) DEFAULT 'no';

    -- Cursor para obtener las tablas que cumplen los criterios:
    -- 1. Tablas de euroaffiliati2 que NO terminan en _history
    -- 2. Tablas de marca_blanca que NO están vacías
    -- 3. Que existen en tyltyco
    -- 4. Priorizar marca_blanca cuando ambas fuentes tienen la tabla
    DECLARE cur CURSOR FOR 
        WITH tablas_euroaffiliati2 AS (
            SELECT TABLE_NAME, 'euroaffiliati2' AS source_db
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = 'euroaffiliati2' 
            AND table_type = 'BASE TABLE' 
            AND TABLE_NAME NOT LIKE '%_history'
            AND TABLE_NAME NOT LIKE '%_old'
            AND TABLE_NAME NOT LIKE '%copy'
            AND TABLE_NAME NOT LIKE '%_url'
        ),
        tablas_marca_blanca_con_datos AS (
            SELECT TABLE_NAME, 'marca_blanca' AS source_db
            FROM information_schema.TABLES 
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
        tablas_tyltyco AS (
            SELECT TABLE_NAME 
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = 'tyltyco' 
            AND table_type = 'BASE TABLE'
        ),
        tablas_marca_blanca_vacias AS (
            SELECT TABLE_NAME 
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = 'marca_blanca' 
            AND table_type = 'BASE TABLE'
            AND (TABLE_ROWS = 0 OR TABLE_ROWS IS NULL)
        )

-- SELECT * FROM tablas_marca_blanca_vacias;
-- SELECT * FROM tablas_euroaffiliati2;
-- SELECT * FROM tablas_tyltyco;
-- SELECT * FROM tablas_marca_blanca_con_datos;

        -- Priorizar marca_blanca, luego euroaffiliati2
        SELECT DISTINCT 
            COALESCE(tmb.TABLE_NAME, te.TABLE_NAME) AS TABLE_NAME,
            COALESCE(tmb.source_db, te.source_db) AS source_db
        FROM tablas_marca_blanca_con_datos tmb
        INNER JOIN tablas_tyltyco tt ON tmb.TABLE_NAME = tt.TABLE_NAME
        LEFT JOIN tablas_euroaffiliati2 te ON tmb.TABLE_NAME = te.TABLE_NAME
        LEFT JOIN tablas_marca_blanca_vacias tmv ON tmb.TABLE_NAME = tmv.TABLE_NAME
        WHERE tmv.TABLE_NAME IS NULL  -- Excluir tablas que están vacías (0 registros) en marca_blanca
        
        UNION ALL
        
        -- Agregar tablas de euroaffiliati2 que NO están en marca_blanca
        SELECT DISTINCT 
            te.TABLE_NAME,
            te.source_db
        FROM tablas_euroaffiliati2 te
        INNER JOIN tablas_tyltyco tt ON te.TABLE_NAME = tt.TABLE_NAME
        LEFT JOIN tablas_marca_blanca_con_datos tmb ON te.TABLE_NAME = tmb.TABLE_NAME
        LEFT JOIN tablas_marca_blanca_vacias tmv ON te.TABLE_NAME = tmv.TABLE_NAME
        WHERE tmb.TABLE_NAME IS NULL  -- Solo tablas que NO están en marca_blanca
        AND tmv.TABLE_NAME IS NULL    -- Excluir tablas que están vacías (0 registros) en marca_blanca
        
        ORDER BY source_db DESC, TABLE_NAME ASC;  -- marca_blanca primero, luego euroaffiliati2

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Configuración inicial
    SET FOREIGN_KEY_CHECKS = 0;
    
    -- Mostrar información inicial
    SELECT 'Iniciando transferencia de datos desde euroaffiliati2 y marca_blanca hacia tyltyco...' AS mensaje;
    SELECT CONCAT('Fecha y hora: ', NOW()) AS timestamp_inicio;
    
    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO tableName, sourceDb;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Verificar si la tabla origen tiene datos
        SET @checkRowsQuery = CONCAT('SELECT COUNT(*) INTO @rowCount FROM ', sourceDb, '.', tableName);
        PREPARE stmt FROM @checkRowsQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        SET rowsCount = @rowCount;
        
        -- Solo procesar si la tabla origen tiene datos
        IF rowsCount > 0 THEN
            -- Verificar diferencias de estructura entre tablas
            SET @fields_diff = (
                SELECT COUNT(*) FROM information_schema.columns 
                WHERE table_schema = sourceDb AND table_name = tableName
            ) - (
                SELECT COUNT(*) FROM information_schema.columns 
                WHERE table_schema = 'tyltyco' AND table_name = tableName
            );

            -- Si hay diferencias estructurales, mostrar advertencia
            IF @fields_diff != 0 THEN
                SELECT CONCAT('ADVERTENCIA: ', tableName, ' (', sourceDb, ') tiene estructura diferente (', @fields_diff, ' campos de diferencia)') AS advertencia;
                
                -- Opcional: saltar tablas con estructura diferente
                -- ITERATE read_loop;
            END IF;

            -- Preparar consultas para la transferencia
            SET @truncateTableQuery = CONCAT('TRUNCATE TABLE tyltyco.', tableName);
            SET @insertDataQuery = CONCAT('INSERT INTO tyltyco.', tableName, ' SELECT * FROM ', sourceDb, '.', tableName);
            
            IF debugMode = 'YES' THEN
                SELECT tableName, sourceDb, @truncateTableQuery, @insertDataQuery, rowsCount AS filas_origen;
                LEAVE Proc_Main;
            END IF;
            
            -- Ejecutar transferencia
            BEGIN
                DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
                BEGIN
                    SELECT CONCAT('ERROR al procesar tabla: ', tableName) AS error_mensaje;
                    GET DIAGNOSTICS CONDITION 1
                        @sqlstate = RETURNED_SQLSTATE, 
                        @errno = MYSQL_ERRNO, 
                        @text = MESSAGE_TEXT;
                    SELECT @sqlstate, @errno, @text AS error_detalle;
                END;
                
                -- Truncar tabla destino
                PREPARE stmt FROM @truncateTableQuery;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                -- Insertar datos
                PREPARE stmt FROM @insertDataQuery;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                -- Mostrar progreso
                SELECT CONCAT('✓ Tabla ', tableName, ' transferida exitosamente desde ', sourceDb, ' (', rowsCount, ' filas)') AS progreso;
                
            END;
        ELSE
            SELECT CONCAT('⚠ Tabla ', tableName, ' está vacía en ', sourceDb, ', omitiendo...') AS info;
        END IF;
        
    END LOOP;

    CLOSE cur;

    -- Restaurar configuración
    SET FOREIGN_KEY_CHECKS = 1;
    
    -- Mostrar resumen final
    SELECT 'Transferencia completada exitosamente' AS mensaje_final;
    SELECT CONCAT('Fecha y hora de finalización: ', NOW()) AS timestamp_fin;
    
    -- Estadísticas finales
    SELECT 
        (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'tyltyco' AND table_type = 'BASE TABLE') AS total_tablas_tyltyco,
        (SELECT SUM(TABLE_ROWS) FROM information_schema.TABLES WHERE TABLE_SCHEMA = 'tyltyco' AND table_type = 'BASE TABLE') AS total_filas_aproximadas;
    
    UPDATE IGNORE tyltyco.account_account
    SET `password`	   ='pbkdf2_sha256$216000$EZ1yW38gUNop$Kyn7iJzrwONvIKnVVtrfxVbM3nR0MqQp3YkBIwygTa8='
      -- password "ilGatto8"
	   ,`date_joined`	   =CURDATE()
	   ,`last_login`	   =CURDATE()
      ;

END //

DELIMITER ;

/*
EJEMPLOS DE USO:

-- Ejecutar el procedimiento
CALL Adecuar_nuevaDB_segun_ea2_y_marca_blanca();

-- Para modo debug (ver consultas sin ejecutar)
-- Modificar la variable debugMode = 'YES' en el procedimiento

-- Verificar tablas transferidas
SELECT 
    t.TABLE_NAME,
    t.TABLE_ROWS,
    'tyltyco' AS base_datos
FROM information_schema.TABLES t
WHERE t.TABLE_SCHEMA = 'tyltyco'
AND t.table_type = 'BASE TABLE'
AND t.TABLE_ROWS > 0
ORDER BY t.TABLE_ROWS DESC;

-- Comparar estructura entre bases de datos
SELECT 
    'euroaffiliati2' AS origen,
    COUNT(*) AS total_tablas
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'euroaffiliati2' 
AND table_type = 'BASE TABLE'
AND TABLE_NAME NOT LIKE '%_history'

UNION ALL

SELECT 
    'marca_blanca' AS origen,
    COUNT(*) AS total_tablas
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'marca_blanca' 
AND table_type = 'BASE TABLE'
AND TABLE_ROWS > 0

UNION ALL

SELECT 
    'tyltyco' AS destino,
    COUNT(*) AS total_tablas
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'tyltyco' 
AND table_type = 'BASE TABLE';

-- Verificar tablas que se transferirán desde cada fuente
SELECT 
    tmb.TABLE_NAME,
    'marca_blanca' AS fuente,
    tmb.TABLE_ROWS AS filas_aprox
FROM information_schema.TABLES tmb
WHERE tmb.TABLE_SCHEMA = 'marca_blanca'
AND tmb.table_type = 'BASE TABLE'
AND tmb.TABLE_ROWS > 0
AND tmb.TABLE_NAME NOT LIKE 'django%'
AND tmb.TABLE_NAME NOT LIKE 'api_%'
AND tmb.TABLE_NAME NOT LIKE 'dash_%'
AND tmb.TABLE_NAME NOT LIKE '%_url'
AND tmb.TABLE_NAME NOT LIKE '%_old'
AND tmb.TABLE_NAME NOT LIKE 'auth_ea2_%'
AND EXISTS (
    SELECT 1 FROM information_schema.TABLES tt 
    WHERE tt.TABLE_SCHEMA = 'tyltyco' 
    AND tt.TABLE_NAME = tmb.TABLE_NAME
    AND tt.table_type = 'BASE TABLE'
)

UNION ALL

SELECT 
    te.TABLE_NAME,
    'euroaffiliati2' AS fuente,
    te.TABLE_ROWS AS filas_aprox
FROM information_schema.TABLES te
WHERE te.TABLE_SCHEMA = 'euroaffiliati2'
AND te.table_type = 'BASE TABLE'
AND te.TABLE_NAME NOT LIKE '%_history'
AND te.TABLE_NAME NOT LIKE '%_old'
AND te.TABLE_NAME NOT LIKE '%copy'
AND te.TABLE_NAME NOT LIKE '%_url'
AND EXISTS (
    SELECT 1 FROM information_schema.TABLES tt 
    WHERE tt.TABLE_SCHEMA = 'tyltyco' 
    AND tt.TABLE_NAME = te.TABLE_NAME
    AND tt.table_type = 'BASE TABLE'
)
AND NOT EXISTS (
    SELECT 1 FROM information_schema.TABLES tmb 
    WHERE tmb.TABLE_SCHEMA = 'marca_blanca' 
    AND tmb.TABLE_NAME = te.TABLE_NAME
    AND tmb.table_type = 'BASE TABLE'
    AND tmb.TABLE_ROWS > 0
)
ORDER BY fuente, TABLE_NAME;
*/
