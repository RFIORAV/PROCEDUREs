/* PROCEDURE_Show_Diff_CPA_DbD_90days_v2.0.sql - Check Raw Data: CPA missing from 90 days comparison
D:\Reinaldo\_FRA\db\PROCEDUREs\PROCEDURE_Show_Diff_CPA_DbD_90days_v2.x.sql

Descripción:
  Procedimiento Show_Diff_CPA_DbD_90days_v2.

Características principales:
1. Acumulación de 90 días
   Crea una nueva tabla Snapshot_day_by_day_diff_90days que almacena datos diarios
   Incluye campo Date para rastrear cada día individualmente
   Mantiene automáticamente solo los últimos 90 días de datos
2. Parámetro LAPSE
   Nuevo parámetro LAPSE que controla cuántos días mostrar en las columnas
   Valor por defecto: 5 días
   Máximo: 90 días
   Se ajusta automáticamente si no hay suficientes días disponibles
3. Funcionalidad SET
   Cuando @Action='SET':
      - Elimina datos del día actual si existen (para evitar duplicados)
      - Inserta los datos del día actual en la tabla de acumulación
      - Elimina datos más antiguos de 90 días
      - Finaliza el proceso
4. Funcionalidad VIEW con tabla temporal
   Cuando @Action='VIEW':
      - Verifica si existen datos del día actual
      - Si no existen, los crea automáticamente
      - Elimina datos más antiguos de 90 días
      - Crea una tabla temporal con columnas para cada día
      - Compara columnas adyacentes para calcular diferencias
      - Filtra según OnlyNegative y descarta filas sin diferencias
5. Reporte de comparación
   - Muestra filas por cada combinación que tenga diferencias
   - Columnas dinámicas que representan cada día según el parámetro LAPSE
   - Cada columna muestra la diferencia con respecto al día anterior
   - Ordenado por la diferencia más significativa

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Action          =[View | SET]. Modifica datos o solo muestra. OPCIONAL. Default=VIEW.
LAPSE           =[1-90]. Número de días para mostrar en columnas. OPCIONAL. Default=días del mes.
OnlyNegative    =[0 | 1]. Si es 1, muestra solo diferencias negativas. OPCIONAL. Default=0.
OnlyNegativeColumns=[0 | 1]. Si es 1, muestra solo columnas que tengan al menos un valor negativo. OPCIONAL. Default=0.
Month           =[YYYY-MM | CM | LM]. Mes a mostrar. CM=mes actual, LM=mes anterior. Si es mes actual, llega hasta hoy; si no, muestra el mes completo. OPCIONAL. Default=mes actual.
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. [Yes] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,month=LM,debug=non'); 
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,Debug=KEYVALUES');
CALL Show_Diff_CPA_DbD_90days_v2('Action=SET,debug=no'); -- ejecutado por EVENT a partir de las 23
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,filters=yes,debug=ye'); 
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,OnlyNegative=1,debug=ye'); -- muestra solo diferencias negativas
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,OnlyNegative=0,debug=non'); -- muestra todas las diferencias en 10 días
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,Month=LM,OnlyNegativeColumns=0,debug=ye'); -- mes específico y solo columnas con negativos

Modificaciones:

25.09.2022 V1     Compara CPA Snapshot_day_by_day ayer con Snapshot_day_by_day_fact1 de hoy
                  Detecta CPA quitadas por MS/Afiliado
19.10.2022 V1.1
01.07.2025 V1.2   Agregada auto-creación de datos para VIEW y eliminación de duplicados para SET
02.01.2025 V2.0   Nueva estrategia: tabla temporal con columnas por día y comparación adyacente
02.03.2026 V2.1   Fix: eliminación de variables globales
02.03.2026 V2.2   Filtro por Month, columnas del mes completo/hasta hoy, OnlyNegativeColumns y Row Total
08.05.2026 V2.3   Fix: ampliado group_concat_max_len antes de generar columnas dinámicas
   
*/
DROP PROCEDURE IF EXISTS Show_Diff_CPA_DbD_90days_v2;

DELIMITER $$
CREATE PROCEDURE Show_Diff_CPA_DbD_90days_v2(IN
   InputCommLine    VARCHAR(250)
   )  
   COMMENT 'Check Raw Data: CPA missing from 90 days comparison - V2 with column-based comparison'
   LANGUAGE SQL

proc_label:BEGIN

DECLARE v_Version              VARCHAR(30);
DECLARE v_CurrentDay           DATE;
DECLARE v_Action               VARCHAR(10);
DECLARE v_LAPSE                INT UNSIGNED;
DECLARE v_Filters              VARCHAR(10);
DECLARE v_Meta                 VARCHAR(10);
DECLARE v_Debug                VARCHAR(20);
DECLARE v_OnlyNegative         TINYINT UNSIGNED;
DECLARE v_OnlyNegativeColumns  TINYINT UNSIGNED;
DECLARE v_InputCommLine        VARCHAR(500);
DECLARE v_e                    INT;
DECLARE v_c                    INT;
DECLARE v_k                    VARCHAR(100);
DECLARE v_v                    VARCHAR(250);
DECLARE v_Curr_Month           VARCHAR(7);
DECLARE v_ViewMonth            VARCHAR(7);
DECLARE v_MonthStart           DATE;
DECLARE v_MonthEnd             DATE;
DECLARE v_today_data_exists    INT;
DECLARE v_MaxDaysAvailable     INT;
DECLARE v_limited_count        INT;
DECLARE v_temp_dates_count     INT;
DECLARE v_sql_create_temp      LONGTEXT;
DECLARE v_sql_columns          LONGTEXT;
DECLARE v_sql_having           LONGTEXT;
DECLARE v_sql_create_diff      LONGTEXT;
DECLARE v_sql_diff_columns     LONGTEXT;
DECLARE v_sql_create_final     LONGTEXT;
DECLARE v_sql_where_condition  LONGTEXT;
DECLARE v_sql_headers          LONGTEXT;
DECLARE v_sql_diff_select      LONGTEXT;
DECLARE v_sql_total_expr       LONGTEXT;
DECLARE v_sql_total_agg_expr   LONGTEXT;
DECLARE v_sql_total_line_columns LONGTEXT;
DECLARE v_sql_negative_columns LONGTEXT;
DECLARE v_sql_filters          LONGTEXT;
DECLARE v_first_day_number     INT;
DECLARE v_sql_final            LONGTEXT;

SET v_Version         ='v2.3 08.05.2026';
SET v_CurrentDay      =CURDATE();
SET v_Action          ='VIEW';
SET v_LAPSE           =7;
SET v_Filters         ='NO';
SET v_Meta            ='YES';
SET v_Debug           ='NO';
SET v_OnlyNegative    =0;
SET v_OnlyNegativeColumns =0;
SET v_ViewMonth       =LEFT(v_CurrentDay,7);

SET v_InputCommLine=Concat(InputCommLine ,',');      
SET v_InputCommLine=replace(v_InputCommLine,'"','');  
IF  v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO

   SET v_e=INSTR(v_InputCommLine,'=');    				   
   SET v_c=INSTR(v_InputCommLine,','); 					   
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);   

   IF lower(v_k)='action'         THEN SET v_Action        =UPPER(v_v); END IF;
   IF lower(v_k)='lapse'          THEN SET v_LAPSE         =v_v;        END IF;
   IF lower(v_k)='filters'        THEN SET v_Filters       =UPPER(v_v); END IF;
   IF lower(v_k)='meta'           THEN SET v_Meta          =UPPER(v_v); END IF; 
   IF lower(v_k)='debug'          THEN SET v_Debug         =UPPER(v_v); END IF;
   IF lower(v_k)='onlynegative'   THEN SET v_OnlyNegative  =CAST(v_v AS UNSIGNED); END IF;
   IF lower(v_k)='month'          THEN SET v_ViewMonth     =LEFT(v_v,7); END IF;
   IF lower(v_k)='onlynegativecolumns' THEN SET v_OnlyNegativeColumns =CAST(v_v AS UNSIGNED); END IF;

END WHILE;

-- --------------------------------------------
-- Resolver rango del mes solicitado:
-- - Mes actual: desde día 1 hasta hoy
-- - Mes histórico: mes completo
IF v_ViewMonth='CM' THEN SET v_ViewMonth=LEFT(CURDATE(),7); END IF;
IF v_ViewMonth='LM' THEN SET v_ViewMonth=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;
SET v_MonthStart = STR_TO_DATE(CONCAT(v_ViewMonth, '-01'), '%Y-%m-%d');
IF v_MonthStart IS NULL THEN
   SELECT CONCAT('Formato de Month inválido: ', v_ViewMonth, '. Use YYYY-MM') AS Error;
   LEAVE proc_label;
END IF;

SET v_MonthEnd = IF(v_ViewMonth = LEFT(v_CurrentDay,7), v_CurrentDay, LAST_DAY(v_MonthStart));

-- Validar LAPSE
-- IF v_LAPSE > 90 THEN SET v_LAPSE = 90; END IF;
-- IF v_LAPSE < 1 THEN SET v_LAPSE = 5; END IF;

IF  v_Debug!="NO" THEN SELECT v_Action,v_LAPSE,v_Filters,v_Meta,v_Debug,v_OnlyNegative,v_ViewMonth,v_OnlyNegativeColumns; END IF;

-- Devolver filtros disponibles y salir (método/estructura compatible con Report_Snapshots_Dashboards)
IF v_Filters = 'YES' THEN
   SET v_sql_filters = CONCAT('
WITH RECURSIVE MonthFilter AS (
   SELECT DATE_FORMAT(CURDATE(), "%Y-%m-01") AS date
   UNION ALL
   SELECT DATE_SUB(date, INTERVAL 1 MONTH)
   FROM MonthFilter
   WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(DATE_FORMAT(CURDATE(), "%Y-%m-01"), INTERVAL 5 MONTH)
)
(SELECT "03" as "Korder","OnlyNegative" AS "Key","OnlyNegative" AS "Value","OnlyNegative" AS `CallKey`,"1" AS `CallValue`,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "04" as "Korder","OnlyNegativeColumns" AS "Key","OnlyNegativeColumns" AS "Value","OnlyNegativeColumns" AS `CallKey`,"1" AS `CallValue`,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "07" as "Korder","Month" AS "Key",DATE_FORMAT(`date`,"%Y-%m") AS "Value","Month" AS `CallKey`,DATE_FORMAT(`date`,"%Y-%m") AS `CallValue`,"" AS "Rows" FROM MonthFilter)
ORDER BY 1, CASE WHEN `CallKey`="Month" THEN `CallValue` ELSE "" END DESC,3;');

   IF v_Debug!="NO" THEN SELECT v_sql_filters; END IF;
   SET @stmt = v_sql_filters;
   PREPARE stmt FROM @stmt;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;

   LEAVE proc_label;
END IF;

IF   DAY(v_CurrentDay)<=3 THEN SET v_Curr_Month=LEFT(DATE_SUB(v_CurrentDay, INTERVAL 1 MONTH),7);
ELSE SET v_Curr_Month=left(v_CurrentDay,7); END IF;

-- DROP TABLE IF EXISTS `Snapshot_day_by_day_diff_90days`;
CREATE TABLE IF NOT EXISTS `Snapshot_day_by_day_diff_90days` (
	`Date` DATE NULL DEFAULT NULL,
	`Month` VARCHAR(7) NULL DEFAULT NULL,
	`Brand` VARCHAR(50) NULL DEFAULT '0',
	`Username` VARCHAR(50) NULL DEFAULT '0',
   `Username_id` INT NULL DEFAULT 0,
   `MS_id` INT NULL DEFAULT 0,
	`Tracker_Name` VARCHAR(50) NULL DEFAULT NULL,
	`Tracker_id` VARCHAR(50) NULL DEFAULT NULL,
	`Product` VARCHAR(50) NULL DEFAULT NULL,
	`Qualified_Players` INT NULL DEFAULT '0',
	`Hour_Update` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`Creation_date` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
	UNIQUE INDEX `Date_MS_Product` (`Date`, `Brand`, `Username_id`, `MS_id`, `Tracker_Name`, `Tracker_id`, `Product`) USING BTREE,
	INDEX `idx_date` (`Date`) USING BTREE
)
;

-- --------------------------------------------
IF v_Action='SET' THEN
   -- Eliminar datos del día actual si existen (para evitar duplicados)
   DELETE FROM Snapshot_day_by_day_diff_90days 
   WHERE Date = v_CurrentDay;
   
   -- Insertar datos del día actual
   INSERT INTO Snapshot_day_by_day_diff_90days 
      SELECT 
         v_CurrentDay as Date,
         left(v_CurrentDay,7) as Month,
         Brand,
         Username,
         Username_id,
         ifnull(MS_id,0) AS MS_id,
         Tracker_Name,
         Tracker_id,
         Product,
         sum(Qualified_Players) AS Qualified_Players,
         Hour_Update,
         now()
      FROM  Snapshot_day_by_day_fact1 D
      WHERE left(D.DATE,7)=v_Curr_Month AND Origin=''      
      GROUP BY Brand,Username_id,ifnull(MS_id,0),Tracker_Name,Tracker_id,Product HAVING sum(Qualified_Players)<>0;
   
   -- Eliminar datos más antiguos de 90 días
   DELETE FROM Snapshot_day_by_day_diff_90days 
   WHERE Date < DATE_SUB(v_CurrentDay, INTERVAL 90 DAY);
END IF;

-- Si Action='SET' finaliza proceso
IF v_Action='SET' THEN LEAVE proc_label; END IF;

-- --------------------------------------------
-- Para Action='VIEW', verificar si existen datos del día actual
-- Si no existen, crearlos automáticamente
SET v_today_data_exists = (
   SELECT COUNT(*) 
   FROM Snapshot_day_by_day_diff_90days 
   WHERE Date = v_CurrentDay
);

IF v_today_data_exists = 0 THEN
   -- Insertar datos del día actual automáticamente
   INSERT INTO Snapshot_day_by_day_diff_90days 
      SELECT 
         v_CurrentDay as Date,
         left(v_CurrentDay,7) as Month,
         Brand,
         Username,
         Username_id,
         ifnull(MS_id,0) AS MS_id,
         Tracker_Name,
         Tracker_id,
         Product,
         sum(Qualified_Players) AS Qualified_Players,
         Hour_Update,
         now()
      FROM  Snapshot_day_by_day_fact1 D
      WHERE left(D.DATE,7)=v_Curr_Month AND Origin=''      
      GROUP BY Brand,Username_id,ifnull(MS_id,0),Tracker_Name,Tracker_id,Product HAVING sum(Qualified_Players)<>0;
   
   -- Eliminar datos más antiguos de 90 días
   DELETE FROM Snapshot_day_by_day_diff_90days 
   WHERE Date < DATE_SUB(v_CurrentDay, INTERVAL 90 DAY);
   
   IF v_Debug != 'NO' THEN
      SELECT CONCAT('Datos del día ', v_CurrentDay, ' creados automáticamente') as Info;
   END IF;
END IF;


DROP TEMPORARY TABLE IF EXISTS temp_dates;
CREATE TEMPORARY TABLE temp_dates AS
WITH RECURSIVE month_dates AS (
   SELECT v_MonthStart AS Date
   UNION ALL
   SELECT DATE_ADD(Date, INTERVAL 1 DAY)
   FROM month_dates
   WHERE Date < v_MonthEnd
)
SELECT Date FROM month_dates;

-- Debug: Verificar tabla temporal
IF v_Debug != 'NO' THEN
   -- SELECT COUNT(*) as Temp_Dates_Count FROM temp_dates;
   SELECT * FROM temp_dates;
END IF;

-- Verificar si la tabla temporal tiene datos
SET v_temp_dates_count = (SELECT COUNT(*) FROM temp_dates);

IF v_temp_dates_count = 0 THEN
   SELECT 'No hay fechas disponibles en el rango especificado' as Error;
   LEAVE proc_label;
END IF;

-- Crear tabla temporal con columnas para cada día
DROP TEMPORARY TABLE IF EXISTS temp_data_with_columns;
SET v_sql_create_temp = CONCAT('CREATE TEMPORARY TABLE temp_data_with_columns AS
SELECT 
   Brand,
   Username,
   Username_id,
   MS_id,
   Tracker_Name,
   Tracker_id,
   Product');

-- Agregar columnas para cada día usando DAY-0, DAY-1, DAY-2, etc.
-- Crear tabla temporal con números de día
DROP TEMPORARY TABLE IF EXISTS temp_dates_with_numbers;
CREATE TEMPORARY TABLE temp_dates_with_numbers AS
SELECT 
   Date,
   DAY(Date) as day_number
FROM temp_dates;

-- Las cadenas dinámicas de un mes completo superan el límite default de GROUP_CONCAT (1024).
SET SESSION group_concat_max_len = 100000;

SELECT GROUP_CONCAT(
   CONCAT(', SUM(CASE WHEN Date = "', Date, '" THEN Qualified_Players ELSE 0 END) AS Day_', day_number)
   ORDER BY Date
   SEPARATOR ' '
) INTO v_sql_columns
FROM temp_dates_with_numbers;

-- Verificar que se generaron las columnas
IF v_sql_columns IS NULL THEN
   SELECT 'Error: No se pudieron generar las columnas dinámicas' as Error;
   LEAVE proc_label;
END IF;

SET v_sql_create_temp = CONCAT(v_sql_create_temp, v_sql_columns, '
FROM Snapshot_day_by_day_diff_90days
WHERE Date IN (SELECT Date FROM temp_dates)
GROUP BY Brand, Username_id, MS_id, Tracker_Name, Tracker_id, Product
HAVING ');

-- Agregar condición HAVING para filtrar registros con al menos un valor no cero
SELECT GROUP_CONCAT(
   CONCAT('SUM(CASE WHEN Date = "', Date, '" THEN Qualified_Players ELSE 0 END) <> 0')
   ORDER BY Date
   SEPARATOR ' OR '
) INTO v_sql_having
FROM temp_dates;

-- Verificar que se generó la condición HAVING
IF v_sql_having IS NULL THEN
   SELECT 'Error: No se pudo generar la condición HAVING' as Error;
   LEAVE proc_label;
END IF;

SET v_sql_create_temp = CONCAT(v_sql_create_temp, v_sql_having, ';');

-- Debug: Mostrar el SQL generado para verificar sintaxis
IF v_Debug != 'NO' THEN SELECT v_sql_create_temp ,v_sql_columns,v_sql_having; END IF;

-- Ejecutar la creación de la tabla temporal
SET @stmt = v_sql_create_temp;
PREPARE stmt FROM @stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Debug: Verificar tabla temporal creada
-- IF @Debug != 'NO' THEN
--    SELECT COUNT(*) as Temp_Data_Count FROM temp_data_with_columns;
--    SELECT * FROM temp_data_with_columns LIMIT 3;
-- END IF;

-- Crear tabla temporal con las diferencias calculadas
DROP TEMPORARY TABLE IF EXISTS temp_data_with_diffs;
SET v_sql_create_diff = 'CREATE TEMPORARY TABLE temp_data_with_diffs AS
SELECT 
   Brand,
   Username,
   Username_id,
   MS_id,
   Tracker_Name,
   Tracker_id,
   Product';

-- Agregar columnas de diferencias entre días adyacentes del mismo mes
DROP TEMPORARY TABLE IF EXISTS temp_dates_with_prev;
CREATE TEMPORARY TABLE temp_dates_with_prev AS
SELECT 
   Date,
   LAG(Date) OVER (ORDER BY Date) as prev_date
FROM temp_dates;

-- Generar columnas de diferencias usando DAY-0, DAY-1, DAY-2, etc.
-- Crear tabla temporal con fechas y números de día usando una sola consulta
DROP TEMPORARY TABLE IF EXISTS temp_dates_with_prev_numbers;
CREATE TEMPORARY TABLE temp_dates_with_prev_numbers AS
SELECT 
   t1.Date,
   t1.prev_date,
   DAY(t1.Date) as current_day_number,
   DAY(t1.prev_date) as prev_day_number
FROM temp_dates_with_prev t1
WHERE t1.prev_date IS NOT NULL;

-- Debug: Verificar tabla temp_dates_with_prev_numbers
-- IF @Debug != 'NO' THEN
--    SELECT 'VERIFICANDO temp_dates_with_prev_numbers:' as Label;
--    SELECT COUNT(*) as Count_prev_numbers FROM temp_dates_with_prev_numbers;
--    SELECT * FROM temp_dates_with_prev_numbers LIMIT 3;
--    SELECT '--- VERIFICACION END ---' as `Separator`;
-- END IF;

SET SESSION group_concat_max_len = 32000;
SELECT GROUP_CONCAT(
   CONCAT(', (Day_', current_day_number, ' - Day_', prev_day_number, ') as Diff_', current_day_number)
   ORDER BY Date
   SEPARATOR ' '
) INTO v_sql_diff_columns
FROM temp_dates_with_prev_numbers;

-- Debug: Verificar las columnas generadas
-- IF @Debug != 'NO' THEN
--    SELECT 'COLUMNAS GENERADAS:' as Label;
--    SELECT @sql_diff_columns as Generated_Columns;
--    SELECT '--- COLUMNAS END ---' as `Separator`;
-- END IF;

-- Verificar que se generaron las columnas de diferencias
IF v_sql_diff_columns IS NULL THEN
   SELECT 'Error: No se pudieron generar las columnas de diferencias' as Error;
   LEAVE proc_label;
END IF;

-- Construir el SQL final de diferencias
SET v_sql_create_diff = CONCAT(v_sql_create_diff, v_sql_diff_columns, '
FROM temp_data_with_columns;');

-- Debug: Verificar el SQL final
-- IF @Debug != 'NO' THEN
--    SELECT 'SQL FINAL:' as Label;
--    SELECT @sql_create_diff as Final_SQL;
--    SELECT '--- END DEBUG ---' as `Separator`;
-- END IF;

-- Debug: Mostrar el SQL de diferencias generado
IF v_Debug != 'NO' THEN SELECT v_sql_create_diff ,v_sql_diff_columns; END IF;

-- Ejecutar la creación de la tabla de diferencias
SET @stmt = v_sql_create_diff;
PREPARE stmt FROM @stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Crear tabla final filtrada según OnlyNegative
DROP TEMPORARY TABLE IF EXISTS temp_final_data;
SET v_sql_create_final = 'CREATE TEMPORARY TABLE temp_final_data AS
SELECT * FROM temp_data_with_diffs WHERE ';

-- Construir condición WHERE para filtrar según OnlyNegative
SELECT GROUP_CONCAT(
   CONCAT('Diff_', current_day_number, ' ', 
          IF(v_OnlyNegative = 1, '< 0', '!= 0'))
   ORDER BY Date
   SEPARATOR ' OR '
) INTO v_sql_where_condition
FROM temp_dates_with_prev_numbers;

-- Verificar que se generó la condición WHERE
IF v_sql_where_condition IS NULL THEN
   SELECT 'Error: No se pudo generar la condición WHERE' as Error;
   LEAVE proc_label;
END IF;

SET v_sql_create_final = CONCAT(v_sql_create_final, v_sql_where_condition, ';');

-- Debug: Mostrar el SQL de tabla final
IF v_Debug != 'NO' THEN SELECT v_sql_create_final; END IF;

-- Ejecutar la creación de la tabla final
SET @stmt = v_sql_create_final;
PREPARE stmt FROM @stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Debug: Verificar tabla final
IF v_Debug != 'NO' THEN SELECT * FROM temp_final_data LIMIT 3; END IF;

-- Si OnlyNegativeColumns=1, detectar qué columnas tienen al menos un valor negativo
DROP TEMPORARY TABLE IF EXISTS temp_negative_columns;
IF v_OnlyNegativeColumns = 1 THEN
   SELECT GROUP_CONCAT(
      CONCAT(
         'SELECT ',
         current_day_number,
         ' AS current_day_number FROM temp_final_data HAVING MIN(Diff_',
         current_day_number,
         ') < 0'
      )
      ORDER BY Date
      SEPARATOR ' UNION ALL '
   ) INTO v_sql_negative_columns
   FROM temp_dates_with_prev_numbers;

   IF v_sql_negative_columns IS NULL THEN
      SELECT 'No hay columnas de diferencias para evaluar' AS Error;
      LEAVE proc_label;
   END IF;

   SET @stmt = CONCAT('CREATE TEMPORARY TABLE temp_negative_columns AS ', v_sql_negative_columns);
   PREPARE stmt FROM @stmt;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;
END IF;

-- Construir columnas del reporte final (headers + select + suma de fila)
IF v_OnlyNegativeColumns = 1 THEN
   SELECT GROUP_CONCAT(
      CONCAT('"width=100px,right=true" as `', UPPER(DATE_FORMAT(t.Date, '%d-%b')), '`')
      ORDER BY t.Date
      SEPARATOR ', '
   ) INTO v_sql_headers
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;

   SELECT GROUP_CONCAT(
      CONCAT(', Diff_', t.current_day_number, ' as `', UPPER(DATE_FORMAT(t.Date, '%d-%b')), '`')
      ORDER BY t.Date
      SEPARATOR ' '
   ) INTO v_sql_diff_select
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;

   SELECT GROUP_CONCAT(
      CONCAT('IFNULL(Diff_', t.current_day_number, ',0)')
      ORDER BY t.Date
      SEPARATOR ' + '
   ) INTO v_sql_total_expr
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;

   SELECT GROUP_CONCAT(
      CONCAT('IFNULL(SUM(Diff_', t.current_day_number, '),0)')
      ORDER BY t.Date
      SEPARATOR ' + '
   ) INTO v_sql_total_agg_expr
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;

   SELECT GROUP_CONCAT(
      CONCAT(', IFNULL(SUM(Diff_', t.current_day_number, '),0) as `', UPPER(DATE_FORMAT(t.Date, '%d-%b')), '`')
      ORDER BY t.Date
      SEPARATOR ' '
   ) INTO v_sql_total_line_columns
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;

   SELECT MIN(t.current_day_number) INTO v_first_day_number
   FROM temp_dates_with_prev_numbers t
   INNER JOIN temp_negative_columns n ON n.current_day_number = t.current_day_number;
ELSE
   SELECT GROUP_CONCAT(
      CONCAT('"width=100px,right=true" as `', UPPER(DATE_FORMAT(Date, '%d-%b')), '`')
      ORDER BY Date
      SEPARATOR ', '
   ) INTO v_sql_headers
   FROM temp_dates_with_prev_numbers;

   SELECT GROUP_CONCAT(
      CONCAT(', Diff_', current_day_number, ' as `', UPPER(DATE_FORMAT(Date, '%d-%b')), '`')
      ORDER BY Date
      SEPARATOR ' '
   ) INTO v_sql_diff_select
   FROM temp_dates_with_prev_numbers;

   SELECT GROUP_CONCAT(
      CONCAT('IFNULL(Diff_', current_day_number, ',0)')
      ORDER BY Date
      SEPARATOR ' + '
   ) INTO v_sql_total_expr
   FROM temp_dates_with_prev_numbers;

   SELECT GROUP_CONCAT(
      CONCAT('IFNULL(SUM(Diff_', current_day_number, '),0)')
      ORDER BY Date
      SEPARATOR ' + '
   ) INTO v_sql_total_agg_expr
   FROM temp_dates_with_prev_numbers;

   SELECT GROUP_CONCAT(
      CONCAT(', IFNULL(SUM(Diff_', current_day_number, '),0) as `', UPPER(DATE_FORMAT(Date, '%d-%b')), '`')
      ORDER BY Date
      SEPARATOR ' '
   ) INTO v_sql_total_line_columns
   FROM temp_dates_with_prev_numbers;

   SELECT MIN(current_day_number) INTO v_first_day_number
   FROM temp_dates_with_prev_numbers;
END IF;

-- Verificar que se generaron los headers
IF v_sql_headers IS NULL OR v_sql_diff_select IS NULL OR v_sql_total_expr IS NULL OR v_sql_total_agg_expr IS NULL OR v_sql_total_line_columns IS NULL OR v_first_day_number IS NULL THEN
   SELECT 'No hay columnas disponibles con los filtros seleccionados' as Error;
   LEAVE proc_label;
END IF;

-- Evita "Can't reopen table: temp_final_data" en UNION:
-- materializa la fila TOTAL GENERAL en una temporal separada
DROP TEMPORARY TABLE IF EXISTS temp_final_totals;
SET @stmt = CONCAT(
'CREATE TEMPORARY TABLE temp_final_totals AS
SELECT
   "total" as Meta,
   "TOTAL GENERAL" as Brand,
   "" as `Account Name`,
   "" as `Account id`,
   "" as MS_id,
   "" as `Tracker ID`,
   "" as `Tracker Name`,
   "" as `Affiliate`,
   (', v_sql_total_agg_expr, ') as `Row Total`,
   0 as CPA_Today
   ', v_sql_total_line_columns, ',
   999999999 as sort_order
FROM temp_final_data');
PREPARE stmt FROM @stmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Construir la consulta final
SET v_sql_final = CONCAT('
SELECT * FROM (
   SELECT 
      "setting" as Meta,
      "width=150px" as Brand,
      "width=200px" AS `Account Name`,
      "width=100px" AS `Account id`,
      "width=80px,center=yes" as MS_id,
      "width=100px" AS `Tracker ID`,
      "width=150px" AS `Tracker Name`,
      "width=180px" as `Affiliate`,
      "width=120px,right=true" as `Row Total`,
      "omit=yes"    as `CPA Today`,
      ', v_sql_headers, ',
      "omit=yes"    as sort_order
   FROM DUAL WHERE "', v_Meta, '"="YES"
   
   UNION ALL

   SELECT * FROM temp_final_totals
   
   UNION ALL
   
   SELECT 
      "" as Meta,
      T.Brand,
      T.Username,
      T.Username_id,
      T.MS_id,
      T.Tracker_id,
      T.Tracker_Name,
      IFNULL(A.username, "") as `Affiliate`,
      (', v_sql_total_expr, ') as `Row Total`,
      0 as CPA_Today
      ', v_sql_diff_select, ',
      T.Diff_', v_first_day_number, ' as sort_order
   FROM temp_final_data T
   LEFT JOIN campaign_marketing_source C ON C.id = T.MS_id
   LEFT JOIN account_account A ON A.id = C.Affiliate_id
) final_result
ORDER BY sort_order DESC
');

-- Ejecutar la consulta final
IF v_Debug != 'NO' THEN SELECT v_sql_final,v_sql_columns, v_sql_diff_columns,v_sql_where_condition,v_sql_diff_select,v_sql_total_expr; END IF;

IF v_Debug != 'YES' THEN
   SET @stmt = v_sql_final;
   PREPARE stmt FROM @stmt;
   EXECUTE stmt;
   DEALLOCATE PREPARE stmt;
END IF;

END$$
DELIMITER ;

/*
Test:

CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,debug=non');
CALL Show_Diff_CPA_DbD_90days_v2('Action=SET'); -- ejecutado por EVENT a partir de las 23
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,LAPSE=7'); -- muestra 7 días de comparación
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,LAPSE=3,Debug=KEYVALUES'); -- muestra query generado
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,OnlyNegative=1'); -- muestra solo diferencias negativas
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,OnlyNegative=0'); -- muestra todas las diferencias
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,Month=2026-02,debug=non'); -- muestra todo el mes 2026-02
CALL Show_Diff_CPA_DbD_90days_v2('Action=VIEW,Month=2026-03,OnlyNegativeColumns=1'); -- mes y solo columnas con negativos
CALL Show_Diff_CPA_DbD_90days_v2('month=LM,Filters=YE,Debug=YES');

Nueva estrategia implementada en v2.0:
1. Crea tabla temporal con columnas para cada día (temp_data_with_columns)
2. Calcula diferencias entre columnas adyacentes (temp_data_with_diffs)
3. Filtra según OnlyNegative y descarta filas sin diferencias (temp_final_data)
4. Genera reporte final con las diferencias calculadas

Ventajas de la nueva estrategia:
- Más eficiente al procesar datos en columnas en lugar de filas
- Comparación directa entre días adyacentes
- Filtrado automático de filas sin diferencias relevantes
- Mejor rendimiento para grandes volúmenes de datos

*/ 