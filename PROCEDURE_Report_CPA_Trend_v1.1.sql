/*
PROCEDURE_Report_CPA_Trend_v1.1.sql  Tendencia del acumulado de CPA a fin de mes

Descripción:
Este procedimiento calcula y muestra la tendencia del CPA (Cost Per Acquisition) 
incluyendo valores diarios, acumulados mensuales y proyección a fin de mes.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id de Affiliate]. OPCIONAL. Default=ALL.
Month           =[AAAA-MM | LM]. OPCIONAL. Default=Current Month.
                  [AAAA-MM] Año y mes específico
                  [LM] Last Month - Mes anterior al corriente

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_CPA_Trend('debug=ye'); -- Devuelve todas las MS
call Report_CPA_Trend('debug=ye,filters=yes');
call Report_CPA_Trend('debug=ye,filters=no,month=lm');
call Report_CPA_Trend('');

Historial de Versiones:
02.03.2025 V1     Primera versión operativa
03.06.2025 V1.1   Versión cursor-claude

*/

DROP PROCEDURE IF EXISTS Report_CPA_Trend;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_CPA_Trend`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report CPA Trend - Análisis de tendencias CPA (Versión desarrollo)'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Inicialización de variables y configuración de valores por defecto
SET @Version         ='v1.1 03.06.2025';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Affiliate_id    ='ALL';

SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

-- Preparación de la línea de comandos para el parsing
SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre para facilitar el parsing
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas para uniformizar formato

-- Debug inicial si está activado
IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;

-- Parser de parámetros de entrada
WHILE @InputCommLine>' ' DO
   SET @e=INSTR(@InputCommLine,'=');    				   
   SET @c=INSTR(@InputCommLine,','); 					   
   SET @k=TRIM(SUBSTRING(@InputCommLine,1,@e-1)); 			   
   SET @v=TRIM(SUBSTRING(@InputCommLine,@e+1,@c-(@e+1))); 	
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);

   -- Asignación de valores usando CASE para mejor rendimiento
   CASE LOWER(@k)
       WHEN 'month'         THEN SET @Month         = UPPER(@v);
       WHEN 'affiliate_id'  THEN SET @Affiliate_id  = UPPER(@v);
       WHEN 'debug'         THEN SET @Debug         = UPPER(@v);
       WHEN 'filters'       THEN SET @Filters       = UPPER(@v);
       WHEN 'meta'          THEN SET @Meta          = UPPER(@v);
       ELSE SET @k = @k;  -- No hacer nada con parámetros no reconocidos
   END CASE;
END WHILE;

-- Procesamiento especial para month=LM (Last Month)
IF @Month = 'LM' THEN SET @Month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7); END IF;

-- Configuración de fechas y filtros
SET @Start_date=CONCAT(@Month,"-01");
SET @End_date=LAST_DAY(@Start_date);

-- Optimización: Solo agregar la condición WHERE si es necesaria
SET @WhereAffiliate=IF(@Affiliate_id!="ALL", CONCAT(" AND D.Affiliate_id=",@Affiliate_id), "");

IF @Debug!="NO" THEN SELECT @Start_date,@End_date,@WhereAffiliate; END IF;

/**************************************************************************************************************
SET @Month="2025-02";
SET @Start_date=CONCAT(@Month,"-01");
SET @End_date=LAST_DAY(@Start_date);
SELECT @Month,@Start_date,@End_date;

SELECT 
    D.Date,
    SUM(D.Qualified_players) AS CPA,
    SUM(SUM(D.Qualified_players)) OVER (
        PARTITION BY YEAR(D.Date), MONTH(D.Date) 
        ORDER BY D.Date
    ) AS Acum,
--     DAY(D.Date) AS dia_actual,
--     DAY(LAST_DAY(D.Date)) AS dias_en_mes,
    ROUND(
    (SUM(SUM(D.Qualified_players)) OVER (
        PARTITION BY YEAR(D.Date), MONTH(D.Date) 
        ORDER BY D.Date
    ) / DAY(D.Date)) * DAY(LAST_DAY(D.Date)),0) AS proyeccion_fin_mes,
        REPEAT('*', FLOOR(
        ((SUM(SUM(D.Qualified_players)) OVER (
            PARTITION BY YEAR(D.Date), MONTH(D.Date) 
            ORDER BY D.Date
        ) / DAY(D.Date)) * DAY(LAST_DAY(D.Date))) / 100
    )) AS grafico_asteriscos
FROM Snapshot_day_by_day_fact1 D
WHERE D.Date BETWEEN @Start_date AND @End_date
GROUP BY D.Date
ORDER BY D.Date
;
**************************************************************************************************************/

SET @CTE_main=CONCAT('
-- CTE principal para cálculos de CPA
WITH Main_Table_Data as (
SELECT
    -- Campos de identificación
    Affiliate_id
   ,Affiliate
   ,D.Date
    -- Métricas base
   ,SUM(D.Qualified_players) AS CPA
    -- Cálculo de acumulados usando ventana por mes
   ,SUM(SUM(D.Qualified_players)) OVER (
        PARTITION BY YEAR(D.Date), MONTH(D.Date) 
        ORDER BY D.Date
    ) AS Acum
    -- Proyección a fin de mes basada en tendencia actual
   ,ROUND(
    (SUM(SUM(D.Qualified_players)) OVER (
        PARTITION BY YEAR(D.Date), MONTH(D.Date) 
        ORDER BY D.Date
    ) / DAY(D.Date)) * DAY(LAST_DAY(D.Date))
    ,0) AS proyeccion_fin_mes
    -- Visualización gráfica de la proyección
   ,REPEAT("*", 
        GREATEST(1,
            FLOOR(
                (SUM(SUM(D.Qualified_players)) OVER (
                    PARTITION BY YEAR(D.Date), MONTH(D.Date) 
                    ORDER BY D.Date
                ) / DAY(D.Date)) * DAY(LAST_DAY(D.Date)) / 100
            )
        )
    ) grafico_asteriscos
FROM Snapshot_day_by_day_fact1 D
WHERE D.Date BETWEEN @Start_date AND @End_date '
   ,@WhereAffiliate,
'
GROUP BY D.Date
)');

-- Definición de metadatos para la presentación
SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   -- Configuración de visualización de columnas
   ,"omit=yes"              as `Affiliate_id`
   ,IF(@Affiliate_id="ALL","omit=yes","width=150px") as `Affiliate`
   ,"width=100px"           as `Date`
   ,"width=100px"           as `CPA day`
   ,"width=100px"           as `CPA Acum`
   ,"width=100px"           as `End Month Trend`
   ,"width=300px"           as `--`
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

-- Query final combinando datos y metadatos
SET @SQL=CONCAT(
@CTE_main,
@SQLmeta,
'
SELECT "data" as `Meta`,
   MT.*
FROM Main_Table_Data MT
ORDER BY Date
;'
);

-- Definición del query para filtros
SET @Month_INI=left(DATE_SUB(CURDATE(), INTERVAL 12 MONTH),7);

SET @SQLfilters=CONCAT('
-- CTEs para generar filtros dinámicos
WITH RECURSIVE MonthFilter AS (
  -- Genera serie de meses para filtrado
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) 
  FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
),
Main_Table_Data AS (
  -- Datos agregados para filtros
  SELECT
      Affiliate_id
     ,Affiliate
     ,SUM(D.Qualified_players) AS CPA
  FROM Snapshot_day_by_day_fact1 D
  WHERE D.Date BETWEEN @Start_date AND @End_date
  GROUP BY Affiliate_id, D.Date 
  HAVING CPA>0
)

-- Unión de filtros disponibles
(SELECT 
    "01" as "Korder"
    ,"Date" AS "Key"
    ,LEFT(`Date`,7) AS "Value"
    ,"Month" AS `CallKey`
    ,LEFT(`Date`,7) AS `CallValue`
    ,"" AS "Rows" 
FROM MonthFilter)
UNION ALL
(SELECT 
    "03" as "Korder"
    ,"Affiliate" AS "Key"
    ,`Affiliate` AS "Value"
    ,"Affiliate_id" AS `CallKey`
    ,`Affiliate_id` AS "CallValue"
    ,COUNT(*) AS "Rows"
FROM Main_Table_Data 
GROUP BY `Affiliate_id`)
ORDER BY 1, 
    CASE WHEN `CallKey`="Month" THEN `CallValue` ELSE "" END DESC, 
    3
;');

-- Lógica de ejecución según parámetros
IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug!="NO" THEN 
    -- Mostrar queries generados en modo debug
    SELECT @SQLfilters; 
    SELECT @SQL; 
END IF;

IF @Debug != "YES" THEN
    -- Ejecutar el query final
    PREPARE stmt1 FROM @SQL;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
-- Ejemplos de uso:
call Report_CPA_Trend('month=2025-02,debug=ye'); -- Muestra el query generado
call Report_CPA_Trend('month=2025-02,debug=ye,filters=yeS'); -- Muestra filtros disponibles
call Report_CPA_Trend('month=2025-02,affiliate_id=39,debug=ye'); -- Query filtrado por afiliado
call Report_CPA_Trend('debug=ye,filters=no,Affiliate_id=2');
*/