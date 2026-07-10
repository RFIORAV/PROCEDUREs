/*
PROCEDURE_DbD_data_to_history.sql 

Descripción:
  Procedimiento DbD_data_to_history.

Keys:
month_param = [valor]. Parámetro de entrada.
   
   - Pasa datos de Snapshot_day_by_day a Snapshot_day_by_day_YYYY
   - Se ejecuta cada mes y transfiere datos de 4 meses de antigüedad DEFAULT (depende de parametro Month en CALL)
   - Borra de la tabla original los que ha insertado en Snapshot_day_by_day_YYYY

Ejemplos:

   IF   DAY(NOW())=01 AND HOUR(NOW())=00 AND MINUTE(NOW())<30 
   CALL DbD_data_to_history ('');
   CALL DbD_data_to_history ('2024-12');

30.03.2025 v1     Primera versión operativa

*/
DROP PROCEDURE IF EXISTS DbD_data_to_history;

DELIMITER $$

CREATE PROCEDURE DbD_data_to_history(IN month_param VARCHAR(7))
   COMMENT 'Pasa datos de Snapshot_day_by_day a Snapshot_day_by_day_YYYY'
   LANGUAGE SQL
   
Proc_Main:BEGIN
-- Defaults
SET @Version         ='v1 30.03.2025';
SET @Month           =CASE WHEN month_param='' THEN LEFT(DATE_SUB(CURDATE(), INTERVAL 4 MONTH),7) ELSE month_param END;
SET @year_value      =SUBSTRING(@Month, 1, 4);
SET @first_month     =CONCAT(@year_value,"-01");

IF LEFT(@Month,4)  NOT BETWEEN "2020" AND "2040"  -- En el año 2040 hay que modificar este hard code! :)
OR RIGHT(@Month,2) NOT BETWEEN "01"   AND "12"
THEN
   Select 'Invalid Month' as '' from dual;
   LEAVE Proc_Main;
END IF;

-- Crear tabla anual si no existe
SET @create_table_sql = CONCAT('CREATE TABLE IF NOT EXISTS Snapshot_day_by_day_', @year_value, ' LIKE Snapshot_day_by_day');
PREPARE stmt FROM @create_table_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Insertar datos del mes específico y previos en la tabla anual
SET @insert_sql = CONCAT('INSERT INTO Snapshot_day_by_day_', @year_value, 
                        ' SELECT * FROM Snapshot_day_by_day 
                                   WHERE LEFT(Date, 7) BETWEEN "', @first_month,'" AND "',@Month,'"');
PREPARE stmt FROM @insert_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Eliminar datos del mes específico de la tabla original
SET @delete_sql = CONCAT('DELETE FROM Snapshot_day_by_day 
                                 WHERE LEFT(Date, 7) BETWEEN "', @first_month,'" AND "',@Month,'"');
PREPARE stmt FROM @delete_sql;
EXECUTE stmt; 
DEALLOCATE PREPARE stmt;

-- Mostrar mensaje de resumen
-- SELECT CONCAT('Datos del mes ', @Month, ' procesados correctamente. Movidos a Snapshot_day_by_day_', @year_value) AS Result;
-- SELECT @Month,@year_value,@create_table_sql,@insert_sql,@delete_sql;

END;
$$
DELIMITER ;
