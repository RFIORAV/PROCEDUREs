/*
PROCEDURE_Optimize_tables_v1.sql

Descripción:
  En la base de datos activa, ejecuta TRUNCATE TABLE sobre cada tabla BASE
  sin registros, para liberar espacio asignado y reiniciar AUTO_INCREMENT
  (last_record).

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string
  Solo procesa TABLE_TYPE = BASE TABLE de DATABASE()
  Vacía se determina con COUNT(*) = 0 en cada tabla (no se usa TABLE_ROWS)

Keys:
  Debug   = [No | Yes | KeyValues]. OPCIONAL. Default=No.
            Yes        → lista el SQL generado sin ejecutarlo
            KeyValues  → muestra parámetros parseados
  Execute = [Yes | No]. OPCIONAL. Default=Yes.
            No → solo informa tablas vacías candidatas, sin TRUNCATE

Parámetros ('[Key=Value[,...]]')

Ejemplos:
  CALL Optimize_tables('');
  CALL Optimize_tables('Execute=No');
  CALL Optimize_tables('Debug=Yes');
  CALL Optimize_tables('Debug=KeyValues');

16.07.2026 v1 Primera versión operativa
*/

SET NAMES 'utf8mb4';

DROP PROCEDURE IF EXISTS Optimize_tables;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Optimize_tables`(IN InputCommLine VARCHAR(250))
COMMENT 'v1 16.07.2026 - TRUNCATE de tablas vacías en la DB activa (libera espacio y reinicia AUTO_INCREMENT)'
SQL SECURITY DEFINER
proc_label:BEGIN
    DECLARE v_Version       VARCHAR(32)  DEFAULT 'v1 16.07.2026';
    DECLARE v_InputCommLine VARCHAR(400) DEFAULT '';
    DECLARE v_Debug         VARCHAR(20)  DEFAULT 'NO';
    DECLARE v_Execute       VARCHAR(5)   DEFAULT 'YES';
    DECLARE v_Schema        VARCHAR(64)  DEFAULT '';
    DECLARE v_TableName     VARCHAR(64)  DEFAULT '';
    DECLARE v_RowCount      BIGINT       DEFAULT 0;
    DECLARE v_Done          INT          DEFAULT 0;
    DECLARE v_Truncated     INT          DEFAULT 0;
    DECLARE v_Skipped       INT          DEFAULT 0;
    DECLARE v_Tables        INT          DEFAULT 0;
    DECLARE v_Empty         INT          DEFAULT 0;
    DECLARE v_e             INT          DEFAULT 0;
    DECLARE v_c             INT          DEFAULT 0;
    DECLARE v_k             VARCHAR(80)  DEFAULT '';
    DECLARE v_v             VARCHAR(250) DEFAULT '';
    DECLARE v_SQL           TEXT;
    DECLARE v_FK_saved      INT          DEFAULT 1;

    DECLARE cur_tables CURSOR FOR
        SELECT t.TABLE_NAME
        FROM information_schema.TABLES t
        WHERE t.TABLE_SCHEMA = v_Schema
          AND t.TABLE_TYPE = 'BASE TABLE'
        ORDER BY t.TABLE_NAME;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = 1;

    SET FOREIGN_KEY_CHECKS = 0;

    SET v_InputCommLine = IFNULL(InputCommLine, '');
    SET v_InputCommLine = CONCAT(v_InputCommLine, ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' AND INSTR(v_InputCommLine, '=') > 0 DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');
        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'debug' THEN
            SET v_Debug = UPPER(v_v);
        ELSEIF LOWER(v_k) = 'execute' THEN
            SET v_Execute = UPPER(v_v);
        END IF;
    END WHILE;

    SET v_Schema = DATABASE();
    IF v_Schema IS NULL OR v_Schema = '' THEN
        SELECT 'ERROR: no hay base de datos activa. USE <schema>; antes de llamar Optimize_tables.' AS Mensaje;
        LEAVE proc_label;
    END IF;

    IF v_Debug = 'KEYVALUES' THEN
        SELECT 'Schema'  AS `Key`, v_Schema  AS `Value`
        UNION ALL SELECT 'Debug',   v_Debug
        UNION ALL SELECT 'Execute', v_Execute
        UNION ALL SELECT 'Version', v_Version;
        LEAVE proc_label;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_optimize_tables_log;
    CREATE TEMPORARY TABLE tmp_optimize_tables_log (
        Korder      INT          NOT NULL AUTO_INCREMENT,
        Table_name  VARCHAR(64)  NOT NULL,
        Accion      VARCHAR(40)  NOT NULL,
        Detalle     VARCHAR(250) NOT NULL DEFAULT '',
        PRIMARY KEY (Korder)
    ) ENGINE=MEMORY;

    SET v_FK_saved = @@SESSION.foreign_key_checks;
    SET SESSION foreign_key_checks = 0;

    OPEN cur_tables;
    read_loop: LOOP
        FETCH cur_tables INTO v_TableName;
        IF v_Done = 1 THEN
            LEAVE read_loop;
        END IF;

        SET v_Tables = v_Tables + 1;

        SET v_SQL = CONCAT(
            'SELECT COUNT(*) INTO @opt_row_cnt FROM `',
            REPLACE(v_Schema, '`', '``'), '`.`',
            REPLACE(v_TableName, '`', '``'), '`'
        );
        SET @v_stmt_sql = v_SQL;
        PREPARE stmt_cnt FROM @v_stmt_sql;
        EXECUTE stmt_cnt;
        DEALLOCATE PREPARE stmt_cnt;
        SET v_RowCount = IFNULL(@opt_row_cnt, -1);

        IF v_RowCount <> 0 THEN
            SET v_Skipped = v_Skipped + 1;
            ITERATE read_loop;
        END IF;

        SET v_Empty = v_Empty + 1;

        SET v_SQL = CONCAT(
            'TRUNCATE TABLE `',
            REPLACE(v_Schema, '`', '``'), '`.`',
            REPLACE(v_TableName, '`', '``'), '`'
        );

        IF v_Debug = 'YES' THEN
            INSERT INTO tmp_optimize_tables_log (Table_name, Accion, Detalle)
            VALUES (v_TableName, 'DEBUG_SQL', v_SQL);
            ITERATE read_loop;
        END IF;

        IF v_Execute <> 'YES' THEN
            INSERT INTO tmp_optimize_tables_log (Table_name, Accion, Detalle)
            VALUES (v_TableName, 'CANDIDATA', 'COUNT(*)=0; Execute=No — sin TRUNCATE');
            ITERATE read_loop;
        END IF;

        SET @v_stmt_sql = v_SQL;
        PREPARE stmt_tr FROM @v_stmt_sql;
        EXECUTE stmt_tr;
        DEALLOCATE PREPARE stmt_tr;

        SET v_Truncated = v_Truncated + 1;
        INSERT INTO tmp_optimize_tables_log (Table_name, Accion, Detalle)
        VALUES (v_TableName, 'TRUNCATED', 'COUNT(*)=0; espacio liberado; AUTO_INCREMENT reiniciado');
    END LOOP;
    CLOSE cur_tables;

    SET SESSION foreign_key_checks = v_FK_saved;

    SELECT
        v_Schema    AS `Schema`,
        v_Tables    AS Tablas_revisadas,
        v_Empty     AS Vacias_COUNT_0,
        v_Truncated AS Truncated,
        v_Skipped   AS Con_registros,
        v_Execute   AS Execute_flag,
        v_Debug     AS Debug_flag,
        v_Version   AS Version;

    SELECT Table_name, Accion, Detalle
    FROM tmp_optimize_tables_log
    ORDER BY Korder;

    DROP TEMPORARY TABLE IF EXISTS tmp_optimize_tables_log;

END$$
DELIMITER ;
