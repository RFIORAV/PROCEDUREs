/*
PROCEDURE_DashTotalByMonth_v1.sql - Obtiene GRAND TOTAL por mes para un año

Descripción:
  Procedimiento DashTotalByMonth.

Keys:
p_start_month = [valor]. Parámetro de entrada.

Recibe como parámetro @start_month (formato YYYY-MM) y ejecuta call Dash_Gestor_TotalByAdvertiser ('Month=YYYY-MM') 
para ese mes y los siguientes 11 meses (total 12 meses).

El procedimiento se detiene automáticamente si el mes a procesar es posterior a la fecha actual.

Con el resultado de cada call guarda la línea de GRAND TOTAL en la tabla dash_total_by_month.

Parámetros:
@start_month - Mes de inicio en formato YYYY-MM (ej: '2024-03')

Ejemplos:
call DashTotalByMonth('2025-09');
call DashTotalByMonth('2024-01');
call DashTotalByMonth('2023-06');
call DashTotalByMonth('CM');
call DashTotalByMonth('LM');
call DashTotalByMonth('debug=yes');

2025-12-03 v1     Primera versión
06-03-2026 v1.1   Agregada opción para calcular GRAND TOTAL desde mes actual (CM) o mes anterior (LM)
12-04-2026 v1.1   v_Version; inicialización de variables locales con SET (sin DEFAULT en DECLARE, MySQL 8.0)
                  Adaptada a cambio de nombre de columna Publisher a Operator

*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DROP PROCEDURE IF EXISTS DashTotalByMonth;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `DashTotalByMonth`(
   IN p_start_month VARCHAR(7)
)
COMMENT 'Obtiene TOTALes Dashboard por mes desde el mes de inicio y los siguientes 11 meses (total 12 meses)'

BEGIN

DECLARE v_Version VARCHAR(32);
DECLARE v_counter INT;
DECLARE v_current_year INT;
DECLARE v_current_month INT;
DECLARE v_month_str VARCHAR(7);
DECLARE v_sql VARCHAR(1000);
DECLARE v_start_year INT;
DECLARE v_start_month INT;
DECLARE v_end_month VARCHAR(7);
DECLARE v_current_date_month VARCHAR(7);
DECLARE v_debug VARCHAR(10);

SET v_Version = 'v1.1 12-04-2026';
SET v_counter = 0;
SET v_current_date_month = LEFT(CURDATE(), 7);
SET v_debug = 'NO';

IF p_start_month='CM' THEN SET p_start_month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF p_start_month='LM' THEN SET p_start_month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- Crear tabla si no existe
CREATE TABLE IF NOT EXISTS `dash_total_by_month` (
   `id` INT AUTO_INCREMENT,
   `Year` INT NOT NULL,
   `Month` VARCHAR(7) NOT NULL,
   `Date` VARCHAR(22) DEFAULT NULL,
   `Owner_id` VARCHAR(150) DEFAULT NULL,
   `Owner` VARCHAR(100) DEFAULT NULL,
   `Publisher` VARCHAR(150) DEFAULT NULL,
   `Brand` VARCHAR(150) DEFAULT NULL,
   `StatusAdv` VARCHAR(30) DEFAULT NULL,
   `Account` VARCHAR(200) DEFAULT NULL,
   `Status` VARCHAR(30) DEFAULT NULL,
   `Curr` VARCHAR(11) DEFAULT NULL,
   `Cap/Used` VARCHAR(57) DEFAULT NULL,
   `Signup` INT DEFAULT NULL,
   `FTD` INT DEFAULT NULL,
   `CPA` INT DEFAULT NULL,
   `CPA_Value` DECIMAL(10,2) DEFAULT NULL,
   `Net_Rev` DECIMAL(10,2) DEFAULT NULL,
   `RS_Val` DECIMAL(10,2) DEFAULT NULL,
   `Tot_Comm` DECIMAL(10,2) DEFAULT NULL,
   `Profit` DECIMAL(10,2) DEFAULT NULL,
   `AfCurr` VARCHAR(11) DEFAULT NULL,
   `AfCom_cpa` DECIMAL(10,2) DEFAULT NULL,
   `AfCom_rs` DECIMAL(10,2) DEFAULT NULL,
   `AfCom_tot` DECIMAL(10,2) DEFAULT NULL,
   `AfCPA` VARCHAR(33) DEFAULT NULL,
   `AfRS` VARCHAR(33) DEFAULT NULL,
   `Area` VARCHAR(50) DEFAULT NULL,
   `RS COver Pend` VARCHAR(51) DEFAULT NULL,
   `Publisher_id` VARCHAR(11) DEFAULT NULL,
   `Created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_year_month_owner` (`Year`, `Month`, `Owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Extraer año y mes del parámetro de inicio
SET v_start_year = CAST(SUBSTRING(p_start_month, 1, 4) AS UNSIGNED);
SET v_start_month = CAST(SUBSTRING(p_start_month, 6, 2) AS UNSIGNED);

-- Inicializar variables para el bucle
SET v_current_year = v_start_year;
SET v_current_month = v_start_month;

-- Calcular el mes final (11 meses después del mes de inicio, total 12 meses)
SET v_end_month = DATE_FORMAT(DATE_ADD(STR_TO_DATE(CONCAT(p_start_month, '-01'), '%Y-%m-%d'), INTERVAL 11 MONTH), '%Y-%m');

-- Obtener el mes actual en formato YYYY-MM
-- SET v_current_date_month = DATE_FORMAT(CURDATE(), '%Y-%m');

-- Eliminar registros existentes para el rango de meses (opcional, para recalcular)
-- Eliminamos los 12 meses que vamos a procesar (desde p_start_month hasta v_end_month)
DELETE FROM dash_total_by_month 
WHERE `Month` >= p_start_month AND `Month` <= v_end_month;

-- Iterar sobre los 12 meses (mes de inicio + 11 meses siguientes)
month_loop: WHILE v_counter < 12 DO
   
   -- Formatear mes actual como YYYY-MM
   SET v_month_str = CONCAT(v_current_year, '-', LPAD(v_current_month, 2, '0'));
   
   -- Verificar si el mes a procesar es posterior a la fecha actual
   -- Si es así, salir del bucle
   IF v_month_str > v_current_date_month THEN
      LEAVE month_loop;
   END IF;
   
   -- Limpiar tabla temporal anterior si existe
   DROP TEMPORARY TABLE IF EXISTS campaign_log_dashboard_temp;
   
   -- Ejecutar Dash_Gestor_TotalByAdvertiser con Rec_log=NOW para crear tabla temporal
   -- Nota: Si el procedimiento se llama Dash_Gestor_TotalByAdvertiser_dev en desarrollo,
   -- cambiar a Dash_Gestor_TotalByAdvertiser en producción
   SET v_sql = CONCAT('call Dash_Gestor_TotalByAdvertiser(''Month=', v_month_str, ',Rec_log=NOW'')');
   
   -- Ejecutar el procedimiento
   SET @sql_stmt = v_sql;
   PREPARE stmt FROM @sql_stmt;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;
   
   -- Insertar la línea GRAND TOTAL en la tabla permanente
   -- La línea GRAND TOTAL tiene Brand = " GRAND TOTAL" (con espacio al inicio)
   -- Nota: Los campos numéricos pueden venir como INT o como VARCHAR con formato (con comas)
   INSERT INTO dash_total_by_month (
      `Year`, `Month`, `Date`, `Owner_id`, `Owner`, `Publisher`, `Brand`, 
      `StatusAdv`, `Account`, `Status`, `Curr`, `Cap/Used`, 
      `Signup`, `FTD`, `CPA`, `CPA_Value`, `Net_Rev`, `RS_Val`, `Tot_Comm`, `Profit`,
      `AfCurr`, `AfCom_cpa`, `AfCom_rs`, `AfCom_tot`, `AfCPA`, `AfRS`, 
      `Area`, `RS COver Pend`, `Publisher_id`
   )
   SELECT
      new_values.`Year`,
      new_values.`Month`,
      new_values.`Date`,
      new_values.`Owner_id`,
      new_values.`Owner`,
      new_values.`Publisher`,
      new_values.`Brand`,
      new_values.`StatusAdv`,
      new_values.`Account`,
      new_values.`Status`,
      new_values.`Curr`,
      new_values.`Cap/Used`,
      new_values.`Signup`,
      new_values.`FTD`,
      new_values.`CPA`,
      new_values.`CPA_Value`,
      new_values.`Net_Rev`,
      new_values.`RS_Val`,
      new_values.`Tot_Comm`,
      new_values.`Profit`,
      new_values.`AfCurr`,
      new_values.`AfCom_cpa`,
      new_values.`AfCom_rs`,
      new_values.`AfCom_tot`,
      new_values.`AfCPA`,
      new_values.`AfRS`,
      new_values.`Area`,
      new_values.`RS COver Pend`,
      new_values.`Publisher_id`
   FROM (
      SELECT
         v_current_year AS `Year`,
         v_month_str AS `Month`,
         src.`Date` AS `Date`,
         src.`Owner_id` AS `Owner_id`,
         src.`Owner` AS `Owner`,
         src.`Operator` AS `Publisher`,
         src.`Brand` AS `Brand`,
         src.`Status Brand` AS `StatusAdv`,
         src.`Account` AS `Account`,
         src.`Status Account` AS `Status`,
         src.`Curr` AS `Curr`,
         src.`CPA Cap` AS `Cap/Used`,
         -- Conversión de campos numéricos (pueden venir formateados con comas o como números)
         CASE
            WHEN src.`Signups` IS NULL OR TRIM(CAST(src.`Signups` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`Signups` AS CHAR) REGEXP '^[0-9,]+$' THEN CAST(REPLACE(CAST(src.`Signups` AS CHAR), ',', '') AS UNSIGNED)
            ELSE CAST(src.`Signups` AS UNSIGNED)
         END AS `Signup`,
         CASE
            WHEN src.`FTD` IS NULL OR TRIM(CAST(src.`FTD` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`FTD` AS CHAR) REGEXP '^[0-9,]+$' THEN CAST(REPLACE(CAST(src.`FTD` AS CHAR), ',', '') AS UNSIGNED)
            ELSE CAST(src.`FTD` AS UNSIGNED)
         END AS `FTD`,
         CASE
            WHEN src.`CPA` IS NULL OR TRIM(CAST(src.`CPA` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`CPA` AS CHAR) REGEXP '^[0-9,]+$' THEN CAST(REPLACE(CAST(src.`CPA` AS CHAR), ',', '') AS UNSIGNED)
            ELSE CAST(src.`CPA` AS UNSIGNED)
         END AS `CPA`,
         CASE
            WHEN src.`CPA_Value` IS NULL OR TRIM(CAST(src.`CPA_Value` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`CPA_Value` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`CPA_Value` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`CPA_Value` AS DECIMAL(10,2))
         END AS `CPA_Value`,
         CASE
            WHEN src.`Net_Rev` IS NULL OR TRIM(CAST(src.`Net_Rev` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`Net_Rev` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`Net_Rev` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`Net_Rev` AS DECIMAL(10,2))
         END AS `Net_Rev`,
         CASE
            WHEN src.`RS_Val` IS NULL OR TRIM(CAST(src.`RS_Val` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`RS_Val` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`RS_Val` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`RS_Val` AS DECIMAL(10,2))
         END AS `RS_Val`,
         CASE
            WHEN src.`Tot_Comm` IS NULL OR TRIM(CAST(src.`Tot_Comm` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`Tot_Comm` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`Tot_Comm` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`Tot_Comm` AS DECIMAL(10,2))
         END AS `Tot_Comm`,
         CASE
            WHEN src.`Profit` IS NULL OR TRIM(CAST(src.`Profit` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`Profit` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`Profit` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`Profit` AS DECIMAL(10,2))
         END AS `Profit`,
         src.`Aff Curr` AS `AfCurr`,
         CASE
            WHEN src.`AfCom_cpa` IS NULL OR TRIM(CAST(src.`AfCom_cpa` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`AfCom_cpa` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`AfCom_cpa` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`AfCom_cpa` AS DECIMAL(10,2))
         END AS `AfCom_cpa`,
         CASE
            WHEN src.`AfCom_rs` IS NULL OR TRIM(CAST(src.`AfCom_rs` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`AfCom_rs` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`AfCom_rs` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`AfCom_rs` AS DECIMAL(10,2))
         END AS `AfCom_rs`,
         CASE
            WHEN src.`AfCom_tot` IS NULL OR TRIM(CAST(src.`AfCom_tot` AS CHAR)) IN ('', '~~~~~') THEN NULL
            WHEN CAST(src.`AfCom_tot` AS CHAR) REGEXP '^-?[0-9]+([.,][0-9]+)?$'
               THEN CAST(REPLACE(REPLACE(CAST(src.`AfCom_tot` AS CHAR), ',', ''), '.', '.') AS DECIMAL(10,2))
            ELSE CAST(src.`AfCom_tot` AS DECIMAL(10,2))
         END AS `AfCom_tot`,
         src.`Aff CPA` AS `AfCPA`,
         src.`Aff RS` AS `AfRS`,
         src.`Area` AS `Area`,
         src.`RS COver Pend` AS `RS COver Pend`,
         src.`Publisher_id` AS `Publisher_id`
      FROM campaign_log_dashboard_temp AS src
      WHERE TRIM(src.`Brand`) IN ('GRAND TOTAL', 'TOTAL')
   ) AS new_values
   ON DUPLICATE KEY UPDATE
      `Date` = new_values.`Date`,
      `Owner_id` = new_values.`Owner_id`,
      `Owner` = new_values.`Owner`,
      `Publisher` = new_values.`Publisher`,
      `Brand` = new_values.`Brand`,
      `StatusAdv` = new_values.`StatusAdv`,
      `Account` = new_values.`Account`,
      `Status` = new_values.`Status`,
      `Curr` = new_values.`Curr`,
      `Cap/Used` = new_values.`Cap/Used`,
      `Signup` = new_values.`Signup`,
      `FTD` = new_values.`FTD`,
      `CPA` = new_values.`CPA`,
      `CPA_Value` = new_values.`CPA_Value`,
      `Net_Rev` = new_values.`Net_Rev`,
      `RS_Val` = new_values.`RS_Val`,
      `Tot_Comm` = new_values.`Tot_Comm`,
      `Profit` = new_values.`Profit`,
      `AfCurr` = new_values.`AfCurr`,
      `AfCom_cpa` = new_values.`AfCom_cpa`,
      `AfCom_rs` = new_values.`AfCom_rs`,
      `AfCom_tot` = new_values.`AfCom_tot`,
      `AfCPA` = new_values.`AfCPA`,
      `AfRS` = new_values.`AfRS`,
      `Area` = new_values.`Area`,
      `RS COver Pend` = new_values.`RS COver Pend`,
      `Publisher_id` = new_values.`Publisher_id`;
   
   -- Incrementar mes y año si es necesario
   SET v_counter = v_counter + 1;
   SET v_current_month = v_current_month + 1;
   
   -- Si el mes supera 12, pasar al siguiente año
   IF v_current_month > 12 THEN
      SET v_current_month = 1;
      SET v_current_year = v_current_year + 1;
   END IF;
   
END WHILE month_loop;

-- Limpiar tabla temporal final
DROP TEMPORARY TABLE IF EXISTS campaign_log_dashboard_temp;

-- Mostrar resumen de los meses procesados
IF v_debug = 'YES' THEN
SELECT 
   `Year`,
   `Month`,
   `Date`,
   `Owner`,
   `Brand`,
   `Signup`,
   `FTD`,
   `CPA`,
   `CPA_Value`,
   `Net_Rev`,
   `RS_Val`,
   `Tot_Comm`,
   `Profit`
FROM dash_total_by_month
WHERE `Month` >= p_start_month 
  AND `Month` <= v_end_month
ORDER BY `Year`, `Month`, `Owner`;
END IF;

END$$
DELIMITER ;

/*
Ejemplos de uso:

-- Calcular GRAND TOTAL desde marzo 2024 y los siguientes 11 meses (hasta febrero 2025)
-- Se detendrá automáticamente si algún mes es posterior a la fecha actual
call DashTotalByMonth('2024-03');

-- Calcular GRAND TOTAL desde enero 2024 y los siguientes 11 meses (hasta diciembre 2024)
call DashTotalByMonth('2024-01');

-- Calcular GRAND TOTAL desde junio 2023 y los siguientes 11 meses (hasta mayo 2024)
call DashTotalByMonth('2023-06');

-- Ver todos los GRAND TOTAL almacenados
SELECT * FROM dash_total_by_month ORDER BY `Year`, `Month`;

-- Ver un rango específico de meses
SELECT * FROM dash_total_by_month 
WHERE `Month` >= '2024-03' AND `Month` <= '2025-02' 
ORDER BY `Year`, `Month`;
*/

