/*
PROCEDURE_DbD_fact_data_to_history_v1.1.sql

Descripción:
  Procedimiento DbD_fact_data_to_history.

Keys:
  month_param = [YYYY-MM | vacío]. Mes límite de antigüedad a archivar.
    Default (vacío): LEFT(DATE_SUB(CURDATE(), INTERVAL 24 MONTH), 7).

  - Pasa datos de Snapshot_day_by_day_fact1/2 a Snapshot_day_by_day_fact1_YYYY / fact2_YYYY
  - Transfiere del 01-01 del año indicado hasta month_param (inclusive)
  - Solo elimina del origen tras comprobar que cada fila existe en la tabla destino

Ejemplos:
   IF DAY(NOW())=01 AND HOUR(NOW())=00 AND MINUTE(NOW())<30
   CALL DbD_fact_data_to_history_dev('');
   CALL DbD_fact_data_to_history_dev('2022-12');

04.04.2025 v1     Primera versión operativa
28.06.2026 v1.1   Verificación previa al DELETE; transacción y rollback si la transferencia no está completa
                  Instalado para probar solo en AR

*/
DROP PROCEDURE IF EXISTS DbD_fact_data_to_history;
DROP PROCEDURE IF EXISTS DbD_fact_data_to_history_dev;

DELIMITER $$

CREATE PROCEDURE DbD_fact_data_to_history(IN month_param VARCHAR(7))
   COMMENT 'v1.1 28.06.2026 - Pasa datos de Snapshot_day_by_day_fact1/2 a Snapshot_day_by_day_fact1_YYYY / fact2_YYYY; Archiva fact1/2 a tablas anuales; elimina origen solo si la transferencia está verificada'
   LANGUAGE SQL

Proc_Main:BEGIN
DECLARE v_in_transaction TINYINT DEFAULT 0;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   IF v_in_transaction = 1 THEN
      ROLLBACK;
      SET v_in_transaction = 0;
   END IF;
   RESIGNAL;
END;

-- Defaults
SET @Version         = 'v1.1 28.06.2026';
SET @Month           = CASE WHEN month_param = '' THEN LEFT(DATE_SUB(CURDATE(), INTERVAL 24 MONTH), 7) ELSE month_param END;
SET @year_value      = SUBSTRING(@Month, 1, 4);
SET @first_month     = CONCAT(@year_value, '-01');
SET @date_filter     = CONCAT('LEFT(`Date`, 7) BETWEEN "', @first_month, '" AND "', @Month, '"');

IF LEFT(@Month, 4) NOT BETWEEN '2020' AND '2040'  -- En el año 2040 hay que modificar este hard code! :)
OR RIGHT(@Month, 2) NOT BETWEEN '01' AND '12'
THEN
   SELECT 'Invalid Month' AS '' FROM DUAL;
   LEAVE Proc_Main;
END IF;

-- FACT1 ------------------------
SET @create_table_sql = CONCAT('CREATE TABLE IF NOT EXISTS Snapshot_day_by_day_fact1_', @year_value, ' LIKE Snapshot_day_by_day_fact1');
PREPARE stmt FROM @create_table_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @count_src_sql = CONCAT('SELECT COUNT(*) INTO @v_src_cnt FROM Snapshot_day_by_day_fact1 WHERE ', @date_filter);
PREPARE stmt FROM @count_src_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

IF IFNULL(@v_src_cnt, 0) > 0 THEN
   START TRANSACTION;
   SET v_in_transaction = 1;

   SET @insert_sql = CONCAT(
      'INSERT INTO Snapshot_day_by_day_fact1_', @year_value,
      ' SELECT * FROM Snapshot_day_by_day_fact1 WHERE ', @date_filter
   );
   PREPARE stmt FROM @insert_sql;
   EXECUTE stmt;
   SET @v_ins_cnt = ROW_COUNT();
   DEALLOCATE PREPARE stmt;

   SET @verify_sql = CONCAT(
      'SELECT COUNT(*) INTO @v_missing_cnt FROM Snapshot_day_by_day_fact1 src WHERE ', @date_filter,
      ' AND NOT EXISTS (',
      '  SELECT 1 FROM Snapshot_day_by_day_fact1_', @year_value, ' dst',
      '  WHERE src.`Date` <=> dst.`Date`',
      '    AND src.`Username_id` <=> dst.`Username_id`',
      '    AND src.`Tracker_ID` <=> dst.`Tracker_ID`',
      '    AND src.`MS_id` <=> dst.`MS_id`',
      '    AND src.`Affiliate_id` <=> dst.`Affiliate_id`',
      '    AND src.`Owner` <=> dst.`Owner`',
      '    AND src.`Net_Revenue` <=> dst.`Net_Revenue`',
      '    AND src.`Qualified_Players` <=> dst.`Qualified_Players`',
      ' )'
   );
   PREPARE stmt FROM @verify_sql;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;

   IF IFNULL(@v_missing_cnt, 0) = 0 AND IFNULL(@v_ins_cnt, 0) = IFNULL(@v_src_cnt, 0) THEN
      SET @delete_sql = CONCAT('DELETE FROM Snapshot_day_by_day_fact1 WHERE ', @date_filter);
      PREPARE stmt FROM @delete_sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      COMMIT;
      SET v_in_transaction = 0;
   ELSE
      ROLLBACK;
      SET v_in_transaction = 0;
      SELECT CONCAT(
         'FACT1: transferencia no verificada (origen=', IFNULL(@v_src_cnt, 0),
         ', insertados=', IFNULL(@v_ins_cnt, 0),
         ', sin destino=', IFNULL(@v_missing_cnt, 0),
         '). No se eliminaron datos del origen.'
      ) AS Result;
   END IF;
END IF;

-- FACT2 ------------------------
SET @create_table_sql = CONCAT('CREATE TABLE IF NOT EXISTS Snapshot_day_by_day_fact2_', @year_value, ' LIKE Snapshot_day_by_day_fact2');
PREPARE stmt FROM @create_table_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @count_src_sql = CONCAT('SELECT COUNT(*) INTO @v_src_cnt FROM Snapshot_day_by_day_fact2 WHERE ', @date_filter);
PREPARE stmt FROM @count_src_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

IF IFNULL(@v_src_cnt, 0) > 0 THEN
   START TRANSACTION;
   SET v_in_transaction = 1;

   SET @insert_sql = CONCAT(
      'INSERT INTO Snapshot_day_by_day_fact2_', @year_value,
      ' SELECT * FROM Snapshot_day_by_day_fact2 WHERE ', @date_filter
   );
   PREPARE stmt FROM @insert_sql;
   EXECUTE stmt;
   SET @v_ins_cnt = ROW_COUNT();
   DEALLOCATE PREPARE stmt;

   SET @verify_sql = CONCAT(
      'SELECT COUNT(*) INTO @v_missing_cnt FROM Snapshot_day_by_day_fact2 src WHERE ', @date_filter,
      ' AND NOT EXISTS (',
      '  SELECT 1 FROM Snapshot_day_by_day_fact2_', @year_value, ' dst',
      '  WHERE src.`Date` <=> dst.`Date`',
      '    AND src.`Username_id` <=> dst.`Username_id`',
      '    AND src.`Tracker_ID` <=> dst.`Tracker_ID`',
      '    AND src.`MS_id` <=> dst.`MS_id`',
      '    AND src.`Affiliate_id` <=> dst.`Affiliate_id`',
      '    AND src.`Owner` <=> dst.`Owner`',
      '    AND src.`Net_Revenue` <=> dst.`Net_Revenue`',
      '    AND src.`Qualified_Players` <=> dst.`Qualified_Players`',
      ' )'
   );
   PREPARE stmt FROM @verify_sql;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;

   IF IFNULL(@v_missing_cnt, 0) = 0 AND IFNULL(@v_ins_cnt, 0) = IFNULL(@v_src_cnt, 0) THEN
      SET @delete_sql = CONCAT('DELETE FROM Snapshot_day_by_day_fact2 WHERE ', @date_filter);
      PREPARE stmt FROM @delete_sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
      COMMIT;
      SET v_in_transaction = 0;
   ELSE
      ROLLBACK;
      SET v_in_transaction = 0;
      SELECT CONCAT(
         'FACT2: transferencia no verificada (origen=', IFNULL(@v_src_cnt, 0),
         ', insertados=', IFNULL(@v_ins_cnt, 0),
         ', sin destino=', IFNULL(@v_missing_cnt, 0),
         '). No se eliminaron datos del origen.'
      ) AS Result;
   END IF;
END IF;

END;
$$
DELIMITER ;
