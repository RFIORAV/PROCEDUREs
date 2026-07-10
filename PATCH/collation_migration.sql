-- ============================================================
--  MIGRACIÓN DE COLLATION A utf8mb4_0900_ai_ci
--  Compatible con MySQL 8.0+
--  Autor  : generado para uso DBA
--  Versión: 1.0
-- ============================================================
-- INSTRUCCIONES DE USO
-- --------------------
-- 1. Ejecutar primero la sección "PREFLIGHT CHECK" para revisar
--    el estado actual sin modificar nada.
-- 2. Ejecutar el SP en modo dry-run (p_dry_run = TRUE) para
--    ver todos los ALTER que se van a lanzar.
-- 3. Ejecutar el SP en modo real (p_dry_run = FALSE) sobre la
--    base de datos objetivo.
-- 4. Ejecutar la sección "VERIFICACIÓN POST-MIGRACIÓN" para
--    confirmar que no queda ninguna columna o tabla fuera de collation.
--
-- NOTAS IMPORTANTES
-- -----------------
-- • utf8mb4_0900_ai_ci requiere MySQL 8.0+. No es compatible con 5.7.
-- • El ALTER TABLE ... CONVERT TO rebuildea el índice completo de
--   la tabla; en tablas grandes puede tardar varios minutos y
--   genera I/O intenso. Planificar en ventana de mantenimiento.
-- • Las columnas BLOB/BINARY/TINYBLOB/etc. no tienen collation
--   y se omiten automáticamente.
-- • Si alguna tabla usa FOREIGN KEYS, el ALTER TABLE interno de
--   MySQL las gestiona de forma transparente en InnoDB.
-- • Se recomienda hacer un mysqldump completo antes de ejecutar.
-- ============================================================


-- ============================================================
-- SECCIÓN 1: PREFLIGHT CHECK (solo lectura, sin cambios)
-- ============================================================

-- 1a. Collation actual del servidor y la base de datos
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';

-- 1b. Resumen: tablas con collation distinta a utf8mb4_0900_ai_ci
-- Sustituir 'nombre_bd' por el nombre real de la base de datos
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_COLLATION,
    ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA   = DATABASE()      -- <<< CAMBIAR
  AND TABLE_TYPE     = 'BASE TABLE'
  AND TABLE_COLLATION <> 'utf8mb4_0900_ai_ci'
ORDER BY TABLE_NAME;

-- 1c. Resumen: columnas con collation distinta a utf8mb4_0900_ai_ci
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    CHARACTER_SET_NAME,
    COLLATION_NAME,
    COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA    = DATABASE()     -- <<< CAMBIAR
  AND COLLATION_NAME IS NOT NULL
  AND COLLATION_NAME <> 'utf8mb4_0900_ai_ci'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 1d. Número total de objetos a migrar (resumen ejecutivo)
SELECT
    'Tablas'   AS tipo,
    COUNT(*)   AS total_a_migrar
FROM information_schema.TABLES
WHERE TABLE_SCHEMA    = DATABASE()     -- <<< CAMBIAR
  AND TABLE_TYPE      = 'BASE TABLE'
  AND TABLE_COLLATION <> 'utf8mb4_0900_ai_ci'
UNION ALL
SELECT
    'Columnas' AS tipo,
    COUNT(*)   AS total_a_migrar
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA   = DATABASE()      -- <<< CAMBIAR
  AND COLLATION_NAME IS NOT NULL
  AND COLLATION_NAME <> 'utf8mb4_0900_ai_ci';


-- ============================================================
-- SECCIÓN 2: STORED PROCEDURE PRINCIPAL
-- ============================================================

DROP PROCEDURE IF EXISTS sp_migrate_collation;

DELIMITER $$

CREATE PROCEDURE sp_migrate_collation(
    IN  p_schema   VARCHAR(64),          -- nombre de la base de datos objetivo
    IN  p_dry_run  BOOLEAN               -- TRUE = solo imprime SQL, no ejecuta
)
BEGIN
    -- ── Variables de control ──────────────────────────────────
    DECLARE v_done          INT     DEFAULT 0;
    DECLARE v_table_name    VARCHAR(255);
    DECLARE v_sql           TEXT;
    DECLARE v_ok_count      INT     DEFAULT 0;
    DECLARE v_skip_count    INT     DEFAULT 0;
    DECLARE v_err_count     INT     DEFAULT 0;
    DECLARE v_last_error    TEXT    DEFAULT NULL;


    -- ── Cursor: tablas que necesitan conversión ───────────────
    -- CONVERT TO CHARACTER SET rehace también las columnas sin
    -- collation explícita; las columnas con collation propia
    -- se tratarán individualmente si difieren.
    DECLARE cur_tables CURSOR FOR
        SELECT TABLE_NAME
        FROM   information_schema.TABLES
        WHERE  TABLE_SCHEMA    = p_schema
          AND  TABLE_TYPE      = 'BASE TABLE'
          AND  TABLE_COLLATION <> 'utf8mb4_0900_ai_ci'
        ORDER BY TABLE_NAME;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    -- ── Handler de errores SQL ────────────────────────────────
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_last_error = MESSAGE_TEXT;
        SET v_err_count = v_err_count + 1;

        INSERT INTO collation_migration_log
            (schema_name, table_name, sql_text, status, error_msg)
        VALUES
            (p_schema, v_table_name, IFNULL(v_sql,''), 'ERROR', v_last_error);
    END;

    -- ── Tabla de log (se crea si no existe) ──────────────────
    CREATE TABLE IF NOT EXISTS collation_migration_log (
        id          INT AUTO_INCREMENT PRIMARY KEY,
        ts          DATETIME(3)   NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
        schema_name VARCHAR(64)   NOT NULL,
        table_name  VARCHAR(255)  NOT NULL,
        sql_text    TEXT          NOT NULL,
        status      VARCHAR(20)   NOT NULL,   -- 'DRY_RUN' | 'OK' | 'ERROR'
        error_msg   TEXT          DEFAULT NULL
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;    

    -- ─────────────────────────────────────────────────────────
    -- PASO 1: Convertir cada tabla con ALTER TABLE ... CONVERT TO
    -- Esto establece el DEFAULT CHARACTER SET + COLLATE de la
    -- tabla Y convierte todas las columnas sin collation explícita.
    -- ─────────────────────────────────────────────────────────
    OPEN cur_tables;

    loop_tables: LOOP
        FETCH cur_tables INTO v_table_name;
        IF v_done = 1 THEN
            LEAVE loop_tables;
        END IF;

        SET v_sql = CONCAT(
            'ALTER TABLE `', p_schema, '`.`', v_table_name, '` ',
            'CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci'
        );

        IF p_dry_run THEN
            -- Solo registra y muestra el SQL
            SELECT v_sql AS dry_run_sql;
            INSERT INTO collation_migration_log
                (schema_name, table_name, sql_text, status)
            VALUES
                (p_schema, v_table_name, v_sql, 'DRY_RUN');
        ELSE
            -- Ejecuta el ALTER
            SET @v_stmt = v_sql;
            PREPARE stmt FROM @v_stmt;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;

            IF v_last_error IS NULL THEN
                SET v_ok_count = v_ok_count + 1;
                INSERT INTO collation_migration_log
                    (schema_name, table_name, sql_text, status)
                VALUES
                    (p_schema, v_table_name, v_sql, 'OK');
            END IF;

            -- Resetear el error para la siguiente iteración
            SET v_last_error = NULL;
        END IF;

    END LOOP loop_tables;

    CLOSE cur_tables;

    -- ─────────────────────────────────────────────────────────
    -- PASO 2: Corregir columnas que aún tienen collation distinta
    -- (columnas con CHARACTER SET / COLLATE definidos explícitamente
    -- no cambian con CONVERT TO si ya tenían un charset explícito
    -- diferente, p.ej. latin1 forzado en columna individual)
    -- ─────────────────────────────────────────────────────────
    BEGIN
        DECLARE v_done2         INT     DEFAULT 0;
        DECLARE v_tbl           VARCHAR(255);
        DECLARE v_col           VARCHAR(255);
        DECLARE v_col_type      TEXT;
        DECLARE v_nullable      VARCHAR(10);
        DECLARE v_col_default   TEXT;
        DECLARE v_extra         VARCHAR(255);
        DECLARE v_comment       TEXT;

        DECLARE cur_cols CURSOR FOR
            SELECT
                c.TABLE_NAME,
                c.COLUMN_NAME,
                c.COLUMN_TYPE,
                c.IS_NULLABLE,
                c.COLUMN_DEFAULT,
                c.EXTRA,
                c.COLUMN_COMMENT
            FROM   information_schema.COLUMNS c
            WHERE  c.TABLE_SCHEMA   = p_schema
              AND  c.COLLATION_NAME IS NOT NULL
              AND  c.COLLATION_NAME <> 'utf8mb4_0900_ai_ci'
            ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done2 = 1;

        OPEN cur_cols;

        loop_cols: LOOP
            FETCH cur_cols INTO
                v_tbl, v_col, v_col_type,
                v_nullable, v_col_default, v_extra, v_comment;

            IF v_done2 = 1 THEN
                LEAVE loop_cols;
            END IF;

            SET v_table_name = v_tbl;   -- para el handler de errores

            -- Construir la cláusula NOT NULL / DEFAULT
            SET v_sql = CONCAT(
                'ALTER TABLE `', p_schema, '`.`', v_tbl, '` ',
                'MODIFY COLUMN `', v_col, '` ', v_col_type,
                ' CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci',
                IF(v_nullable = 'NO', ' NOT NULL', ' NULL'),
                IF(v_col_default IS NOT NULL,
                   CONCAT(' DEFAULT ', QUOTE(v_col_default)),
                   ''),
                IF(v_extra <> '' AND v_extra IS NOT NULL,
                   CONCAT(' ', v_extra),
                   ''),
                IF(v_comment <> '' AND v_comment IS NOT NULL,
                   CONCAT(' COMMENT ', QUOTE(v_comment)),
                   '')
            );

            IF p_dry_run THEN
                SELECT v_sql AS dry_run_sql;
                INSERT INTO collation_migration_log
                    (schema_name, table_name, sql_text, status)
                VALUES
                    (p_schema, v_tbl, v_sql, 'DRY_RUN');
            ELSE
                SET @v_stmt2 = v_sql;
                PREPARE stmt2 FROM @v_stmt2;
                EXECUTE stmt2;
                DEALLOCATE PREPARE stmt2;

                IF v_last_error IS NULL THEN
                    SET v_ok_count = v_ok_count + 1;
                    INSERT INTO collation_migration_log
                        (schema_name, table_name, sql_text, status)
                    VALUES
                        (p_schema, v_tbl, v_sql, 'OK');
                END IF;

                SET v_last_error = NULL;
            END IF;

        END LOOP loop_cols;

        CLOSE cur_cols;
    END;

    -- ─────────────────────────────────────────────────────────
    -- PASO 3: Cambiar DEFAULT del schema (no afecta objetos ya
    -- creados, pero sí las futuras CREATE TABLE sin charset)
    -- ─────────────────────────────────────────────────────────
    SET v_sql = CONCAT(
        'ALTER DATABASE `', p_schema, '` ',
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci'
    );

    IF p_dry_run THEN
        SELECT v_sql AS dry_run_sql;
    ELSE
        SET @v_stmt3 = v_sql;
        PREPARE stmt3 FROM @v_stmt3;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;
    END IF;

    -- ── Resumen final ─────────────────────────────────────────
    SELECT
        IF(p_dry_run, 'DRY RUN (sin cambios)', 'EJECUCIÓN REAL') AS modo,
        p_schema        AS base_de_datos,
        v_ok_count      AS alteraciones_ok,
        v_err_count     AS errores,
        v_skip_count    AS omitidas;

END$$

DELIMITER ;


-- ============================================================
-- SECCIÓN 3: EJECUCIÓN
-- ============================================================

-- ── 3a. DRY RUN (revisar primero) ────────────────────────────
CALL sp_migrate_collation(DATABASE(), TRUE);   -- <<< CAMBIAR settings_db

-- ── 3b. Revisión del log de dry run ──────────────────────────
SELECT
    ts,
    table_name,
    LEFT(sql_text, 120) AS sql_preview,
    status
FROM collation_migration_log
WHERE schema_name = DATABASE()                 -- <<< CAMBIAR
  AND status      = 'DRY_RUN'
ORDER BY id DESC;

-- ── 3c. EJECUCIÓN REAL (descomentar cuando esté validado) ────
CALL sp_migrate_collation(DATABASE(), FALSE);  -- <<< CAMBIAR


-- ============================================================
-- SECCIÓN 4: VERIFICACIÓN POST-MIGRACIÓN
-- ============================================================

-- 4a. Tablas que AÚN tienen collation distinta (debe estar vacío)
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_COLLATION
FROM information_schema.TABLES
WHERE TABLE_SCHEMA    = DATABASE()             -- <<< CAMBIAR
  AND TABLE_TYPE      = 'BASE TABLE'
  AND TABLE_COLLATION <> 'utf8mb4_0900_ai_ci';

-- 4b. Columnas que AÚN tienen collation distinta (debe estar vacío)
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CHARACTER_SET_NAME,
    COLLATION_NAME,
    COLUMN_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA   = DATABASE()              -- <<< CAMBIAR
  AND COLLATION_NAME IS NOT NULL
  AND COLLATION_NAME <> 'utf8mb4_0900_ai_ci'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- 4c. Log completo de la ejecución real
SELECT
    ts,
    table_name,
    LEFT(sql_text, 120) AS sql_preview,
    status,
    LEFT(error_msg, 200) AS error_msg
FROM collation_migration_log
WHERE schema_name = DATABASE()                 -- <<< CAMBIAR
  AND status     <> 'DRY_RUN'
ORDER BY id;

-- 4d. Resumen de errores (si hay alguno)
SELECT
    table_name,
    sql_text,
    error_msg
FROM collation_migration_log
WHERE schema_name = DATABASE()                 -- <<< CAMBIAR
  AND status      = 'ERROR';


-- ============================================================
-- SECCIÓN 5: LIMPIEZA (opcional, tras confirmar migración OK)
-- ============================================================

-- DROP PROCEDURE IF EXISTS sp_migrate_collation;
-- DROP TABLE   IF EXISTS collation_migration_log;
