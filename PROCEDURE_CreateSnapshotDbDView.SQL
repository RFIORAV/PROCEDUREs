/*
-- Script MySQL 8 para crear la vista affiliateaccess.Snapshot_DbD_view

Descripción:
  Procedimiento CreateSnapshotDbDView.
--    y generar la tabla affiliateaccess.Snapshot_day_by_day
-- Combina datos de Snapshot_day_by_day y la tabla del año más reciente desde euroaffiliati2
-- Se utiliza al regenerar db affiliateaccess desde euroaffiliati2 
--    en REGENERA_db_AFFILIATEACCESS_desde_EUROAFFILIATI_v2.cmd

Keys:

25.09.2025 v1

*/

DELIMITER $$

DROP PROCEDURE IF EXISTS CreateSnapshotDbDView$$

CREATE PROCEDURE CreateSnapshotDbDView()
COMMENT 'Procedimiento CreateSnapshotDbDView.'

BEGIN
   DECLARE version        TEXT  DEFAULT 'v1 25.09.2025';
   DECLARE latest_year    INT   DEFAULT 0;
   DECLARE table_exists   INT   DEFAULT 0;
   DECLARE current_year   INT   DEFAULT YEAR(CURDATE());
   DECLARE sql_statement  TEXT  DEFAULT '';
   DECLARE done           INT   DEFAULT FALSE;
    
   SET latest_year=(
      SELECT CAST(SUBSTRING(TABLE_NAME, 21) AS UNSIGNED) as year_num
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_SCHEMA = 'euroaffiliati2'
        AND TABLE_NAME REGEXP 'Snapshot_day_by_day_[0-9]{4}$'
      ORDER BY year_num DESC
      LIMIT 1);
    
    DROP TABLE IF EXISTS affiliateaccess.Snapshot_day_by_day;
    
    -- Si no encontramos ninguna tabla por año, usar solo la tabla base
    IF latest_year = 0 THEN
       SET sql_statement = '
            CREATE OR REPLACE VIEW affiliateaccess.Snapshot_DbD_view AS 
            SELECT * FROM euroaffiliati2.Snapshot_day_by_day
            ORDER BY id';
        
    -- SELECT CONCAT('No se encontraron tablas por año válidas. Usando solo Snapshot_day_by_day') AS mensaje;
    ELSE
        -- Construir la consulta UNION con la tabla base y la del año más reciente
        SET sql_statement = CONCAT('
            CREATE OR REPLACE VIEW affiliateaccess.Snapshot_DbD_view AS 
            SELECT * FROM euroaffiliati2.Snapshot_day_by_day
            UNION ALL
            SELECT * FROM euroaffiliati2.Snapshot_day_by_day_', latest_year, '
            ORDER BY id');
        
    -- SELECT CONCAT('Vista creada combinando Snapshot_day_by_day y Snapshot_day_by_day_', latest_year) AS mensaje;
    END IF;
    
    -- Ejecutar la consulta dinámicamente
    SET @sql = sql_statement;
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    CREATE TABLE affiliateaccess.Snapshot_day_by_day LIKE euroaffiliati2.Snapshot_day_by_day;
    INSERT IGNORE INTO affiliateaccess.Snapshot_day_by_day
      SELECT * FROM affiliateaccess.Snapshot_DbD_view;
    
END$$

DELIMITER ;

/*
-- Ejecutar el procedimiento para crear la vista
CALL CreateSnapshotDbDView();

-- Opcional: Eliminar el procedimiento después de usarlo
-- DROP PROCEDURE IF EXISTS CreateSnapshotView;

-- Verificar que la vista se creó correctamente
SELECT 
    TABLE_NAME,
    VIEW_DEFINITION
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'affiliateaccess'
  AND TABLE_NAME = 'Snapshot_day_by_day';

-- Ejemplo de consulta para verificar los datos
-- SELECT COUNT(*) as total_records FROM Snapshot_DbD;
-- SELECT * FROM Snapshot_DbD LIMIT 10;
*/