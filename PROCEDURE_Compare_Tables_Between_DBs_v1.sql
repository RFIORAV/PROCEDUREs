/*
PROCEDURE_Compare_Tables_Between_DBs_v1.sql

Descripción:
  Procedimiento PROCEDURE_Compare_Tables_Between_DBs_v1.

Keys:
  Sin parámetros de entrada documentables.
p_table_name_pattern = [valor]. Parámetro de entrada.
p_source_db = [valor]. Parámetro de entrada.
p_target_db = [valor]. Parámetro de entrada.

Ejemplo:
  CALL PROCEDURE_Compare_Tables_Between_DBs_v1();
*/
-- =====================================================
-- PROCEDURE: Compare_Tables_Between_DBs
-- =====================================================
-- 
-- DESCRIPCIÓN:
-- Este procedimiento compara la estructura de tablas entre dos bases de datos diferentes
-- que tengan el mismo nombre y coincidan con un patrón de búsqueda.
-- Genera las sentencias ALTER necesarias para sincronizar la estructura.
-- 
-- PARÁMETROS DE ENTRADA:
-- - p_table_name_pattern: Patrón de búsqueda para filtrar tablas (usa LIKE)
--   Ejemplos: 'user', 'order', 'log', 'temp', 'report'
-- - p_source_db: Nombre de la base de datos origen
-- - p_target_db: Nombre de la base de datos destino
-- 
-- FUNCIONALIDADES:
-- 1. Valida que ambas bases de datos existan
-- 2. Busca tablas que coincidan con el patrón en ambas DBs
-- 3. Compara la estructura de columnas entre tablas
-- 4. Identifica tablas que solo existen en una de las bases de datos
-- 5. Genera sentencias ALTER para sincronizar estructuras
-- 6. Genera reportes detallados de las diferencias
-- 
-- SALIDAS DEL PROCEDURE:
-- 1. Información inicial de la comparación
-- 2. Progreso durante la ejecución (tabla por tabla)
-- 3. Resumen final con estadísticas generales
-- 4. Lista detallada de todas las tablas comparadas
-- 5. Tablas que solo existen en la base de datos origen
-- 6. Tablas que solo existen en la base de datos destino
-- 7. Sentencias ALTER para sincronizar estructuras
-- 8. Tablas con diferencias en la estructura
-- 
-- EJEMPLOS DE USO:
-- CALL Compare_Tables_Between_DBs('account_account', 'euroaffiliati2', 'affacc_dev');
-- CALL Compare_Tables_Between_DBs('order', 'main_db', 'backup_db');
-- CALL Compare_Tables_Between_DBs('log', 'live', 'test');
-- 
-- EJEMPLOS DE PATRONES:
-- - 'user' -> encuentra: users, user_profiles, user_logs, etc.
-- - 'order' -> encuentra: orders, order_items, order_history, etc.
-- - 'log' -> encuentra: logs, login_attempts, log_entries, etc.
-- - 'temp' -> encuentra: temp_table, temporary_data, etc.
-- - 'report' -> encuentra: reports, report_data, report_summary, etc.
-- 
-- VERSIÓN: 1.0
-- FECHA: 2024
-- COMPATIBILIDAD: MySQL 8.0.37+
-- =====================================================

-- Eliminar el procedimiento si ya existe
DROP PROCEDURE IF EXISTS Compare_Tables_Between_DBs;
-- 
DELIMITER $$

CREATE PROCEDURE Compare_Tables_Between_DBs(
    IN p_table_name_pattern VARCHAR(100),
    IN p_source_db VARCHAR(100),
    IN p_target_db VARCHAR(100)
)
COMMENT 'Procedimiento Compare_Tables_Between_DBs.'
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_table_name VARCHAR(100);
    DECLARE v_source_exists BOOLEAN DEFAULT FALSE;
    DECLARE v_target_exists BOOLEAN DEFAULT FALSE;
    DECLARE v_total_tables INT DEFAULT 0;
    DECLARE v_matched_tables INT DEFAULT 0;
    DECLARE v_has_differences BOOLEAN DEFAULT FALSE;
    
    
    -- Cursor para iterar sobre las tablas que coinciden con el patrón
    DECLARE table_cursor CURSOR FOR
        SELECT DISTINCT t1.TABLE_NAME
        FROM (
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = p_source_db 
            AND TABLE_NAME LIKE CONCAT('%', p_table_name_pattern, '%')
        ) t1
        INNER JOIN (
            SELECT TABLE_NAME 
            FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = p_target_db 
            AND TABLE_NAME LIKE CONCAT('%', p_table_name_pattern, '%')
        ) t2 ON t1.TABLE_NAME = t2.TABLE_NAME;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Variables para almacenar resultados de consultas dinámicas
    SET @source_columns = 0;
    SET @target_columns = 0;
    SET @missing_columns = 0;
    
    -- Tabla temporal para almacenar resultados
    DROP TEMPORARY TABLE IF EXISTS temp_comparison_results;
    CREATE TEMPORARY TABLE temp_comparison_results (
        table_name VARCHAR(100),
        source_exists BOOLEAN,
        target_exists BOOLEAN,
        has_differences BOOLEAN,
        status VARCHAR(50)
    );
    
    -- Tabla temporal para almacenar sentencias ALTER
    DROP TEMPORARY TABLE IF EXISTS temp_alter_statements;
    CREATE TEMPORARY TABLE temp_alter_statements (
        table_name VARCHAR(100),
        alter_statement TEXT,
        statement_type VARCHAR(50)
    );
    
    -- Verificar que ambas bases de datos existen
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = p_source_db) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La base de datos origen no existe';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = p_target_db) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La base de datos destino no existe';
    END IF;
    
    -- Contar total de tablas que coinciden con el patrón en ambas DBs
    SELECT COUNT(DISTINCT t1.TABLE_NAME) INTO v_total_tables
    FROM (
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = p_source_db 
        AND TABLE_NAME LIKE CONCAT('%', p_table_name_pattern, '%')
    ) t1
    INNER JOIN (
        SELECT TABLE_NAME 
        FROM INFORMATION_SCHEMA.TABLES 
        WHERE TABLE_SCHEMA = p_target_db 
        AND TABLE_NAME LIKE CONCAT('%', p_table_name_pattern, '%')
    ) t2 ON t1.TABLE_NAME = t2.TABLE_NAME;
    
    -- Mostrar información inicial
    SELECT 
        CONCAT('Comparando estructura de tablas entre ', p_source_db, ' y ', p_target_db) AS info,
        CONCAT('Patrón de búsqueda: ', p_table_name_pattern) AS pattern,
        v_total_tables AS total_tables_to_compare;
    
    -- Abrir cursor
    OPEN table_cursor;
    
    -- Iterar sobre las tablas
    read_loop: LOOP
        FETCH table_cursor INTO v_table_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_matched_tables = v_matched_tables + 1;
        
        -- Verificar si la tabla existe en ambas bases de datos
        SET v_source_exists = EXISTS(
            SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = p_source_db AND TABLE_NAME = v_table_name
        );
        
        SET v_target_exists = EXISTS(
            SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = p_target_db AND TABLE_NAME = v_table_name
        );
        
        -- Comparar estructura de columnas si ambas tablas existen
        IF v_source_exists AND v_target_exists THEN
            -- Obtener número de columnas en cada tabla
            SET @sql = CONCAT(
                'SELECT COUNT(*) INTO @source_columns FROM INFORMATION_SCHEMA.COLUMNS ',
                'WHERE TABLE_SCHEMA = "', p_source_db, '" AND TABLE_NAME = "', v_table_name, '"'
            );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            SET @sql = CONCAT(
                'SELECT COUNT(*) INTO @target_columns FROM INFORMATION_SCHEMA.COLUMNS ',
                'WHERE TABLE_SCHEMA = "', p_target_db, '" AND TABLE_NAME = "', v_table_name, '"'
            );
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            -- Verificar si hay diferencias en el número de columnas
            IF @source_columns != @target_columns THEN
                SET v_has_differences = TRUE;
            ELSE
                -- Si tienen el mismo número de columnas, verificar si hay columnas diferentes
                SET @sql = CONCAT(
                    'SELECT COUNT(*) INTO @missing_columns FROM INFORMATION_SCHEMA.COLUMNS c1 ',
                    'WHERE c1.TABLE_SCHEMA = "', p_source_db, '" AND c1.TABLE_NAME = "', v_table_name, '" ',
                    'AND c1.COLUMN_NAME NOT IN (',
                    'SELECT c2.COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS c2 ',
                    'WHERE c2.TABLE_SCHEMA = "', p_target_db, '" AND c2.TABLE_NAME = "', v_table_name, '"',
                    ')'
                );
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                SET v_has_differences = (@missing_columns > 0);
            END IF;
            
            -- Generar sentencias ALTER si hay diferencias
            IF v_has_differences THEN
                -- Obtener columnas que faltan en target (simplificado)
                SET @sql = CONCAT(
                    'INSERT INTO temp_alter_statements (table_name, alter_statement, statement_type) ',
                    'SELECT "', v_table_name, '", ',
                    'CONCAT("ALTER TABLE ', p_target_db, '.', v_table_name, ' ADD COLUMN ", COLUMN_NAME, " ", COLUMN_TYPE, ',
                    'CASE WHEN IS_NULLABLE = "NO" THEN " NOT NULL" ELSE "" END, ',
                    'CASE WHEN COLUMN_DEFAULT IS NOT NULL THEN CONCAT(" DEFAULT ", COLUMN_DEFAULT) ELSE "" END, "") AS alter_statement, ',
                    '"ADD_COLUMN" ',
                    'FROM INFORMATION_SCHEMA.COLUMNS c1 ',
                    'WHERE c1.TABLE_SCHEMA = "', p_source_db, '" AND c1.TABLE_NAME = "', v_table_name, '" ',
                    'AND c1.COLUMN_NAME NOT IN (',
                    'SELECT c2.COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS c2 ',
                    'WHERE c2.TABLE_SCHEMA = "', p_target_db, '" AND c2.TABLE_NAME = "', v_table_name, '"',
                    ')'
                );
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                -- Obtener columnas que están en target pero no en source (para reporte)
                SET @sql = CONCAT(
                    'INSERT INTO temp_alter_statements (table_name, alter_statement, statement_type) ',
                    'SELECT "', v_table_name, '", ',
                    'CONCAT("-- COLUMNA EXTRA EN DESTINO: ", COLUMN_NAME, " (", COLUMN_TYPE, ")") AS alter_statement, ',
                    '"EXTRA_COLUMN" ',
                    'FROM INFORMATION_SCHEMA.COLUMNS c1 ',
                    'WHERE c1.TABLE_SCHEMA = "', p_target_db, '" AND c1.TABLE_NAME = "', v_table_name, '" ',
                    'AND c1.COLUMN_NAME NOT IN (',
                    'SELECT c2.COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS c2 ',
                    'WHERE c2.TABLE_SCHEMA = "', p_source_db, '" AND c2.TABLE_NAME = "', v_table_name, '"',
                    ')'
                );
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END IF;
        END IF;
        
        -- Determinar estado
        SET @status = CASE 
            WHEN NOT v_source_exists THEN 'No existe en origen'
            WHEN NOT v_target_exists THEN 'No existe en destino'
            WHEN v_has_differences THEN 'Diferencias en estructura'
            ELSE 'Estructura idéntica'
        END;
        
        -- Debug: mostrar información de la comparación
        -- IF v_source_exists AND v_target_exists THEN
        --     SELECT 
        --         v_table_name AS tabla,
        --         @source_columns AS columnas_origen,
        --         @target_columns AS columnas_destino,
        --         @missing_columns AS columnas_faltantes,
        --         v_has_differences AS tiene_diferencias,
        --         @status AS estado;
        -- END IF;
        
        -- Insertar resultado
        INSERT INTO temp_comparison_results 
        (table_name, source_exists, target_exists, has_differences, status)
        VALUES (v_table_name, v_source_exists, v_target_exists, v_has_differences, @status);
        
        -- Mostrar progreso
        -- SELECT 
        --     CONCAT('Procesando tabla ', v_matched_tables, ' de ', v_total_tables, ': ', v_table_name) AS progress,
        --     @status AS status;
        
    END LOOP;
    
    CLOSE table_cursor;
    
    -- Mostrar resumen final
    SELECT 
        'RESUMEN DE COMPARACIÓN DE ESTRUCTURA' AS title,
        p_source_db AS source_database,
        p_target_db AS target_database,
        p_table_name_pattern AS search_pattern;
    
    SELECT 
        COUNT(*) AS total_tables_compared,
        SUM(CASE WHEN status = 'Estructura idéntica' THEN 1 ELSE 0 END) AS identical_tables,
        SUM(CASE WHEN status != 'Estructura idéntica' THEN 1 ELSE 0 END) AS different_tables
    FROM temp_comparison_results;
    
    -- Mostrar resultados detallados
    SELECT 
        table_name AS tabla,
        source_exists AS existe_en_origen,
        target_exists AS existe_en_destino,
        has_differences AS tiene_diferencias,
        status AS estado
    FROM temp_comparison_results
    ORDER BY 
        CASE 
            WHEN status = 'Estructura idéntica' THEN 1
            WHEN status = 'Diferencias en estructura' THEN 2
            ELSE 3
        END,
        table_name;
    
    -- Mostrar tablas que solo existen en una de las bases de datos
    SELECT 
        'TABLAS SOLO EN ORIGEN' AS section,
        table_name AS tabla
    FROM temp_comparison_results
    WHERE source_exists = TRUE AND target_exists = FALSE
    ORDER BY table_name;
    
    SELECT 
        'TABLAS SOLO EN DESTINO' AS section,
        table_name AS tabla
    FROM temp_comparison_results
    WHERE source_exists = FALSE AND target_exists = TRUE
    ORDER BY table_name;
    
    -- Mostrar sentencias ALTER para sincronizar estructuras
    SELECT 
        'SENTENCIAS ALTER PARA SINCRONIZAR ESTRUCTURAS' AS section,
        table_name AS tabla,
        alter_statement AS sentencia_alter,
        statement_type AS tipo_sentencia
    FROM temp_alter_statements
    WHERE statement_type = 'ADD_COLUMN'
    ORDER BY table_name, alter_statement;
    
    -- Mostrar columnas extra en destino
    SELECT 
        'COLUMNAS EXTRA EN DESTINO' AS section,
        table_name AS tabla,
        alter_statement AS columna_extra
    FROM temp_alter_statements
    WHERE statement_type = 'EXTRA_COLUMN'
    ORDER BY table_name, alter_statement;
    
    -- Mostrar tablas con diferencias en estructura
    SELECT 
        'TABLAS CON DIFERENCIAS EN ESTRUCTURA' AS section,
        table_name AS tabla,
        status AS estado
    FROM temp_comparison_results
    WHERE has_differences = TRUE
    ORDER BY table_name;
    
    -- Limpiar tablas temporales
    DROP TEMPORARY TABLE IF EXISTS temp_comparison_results;
    DROP TEMPORARY TABLE IF EXISTS temp_alter_statements;
    
END$$

DELIMITER ; 