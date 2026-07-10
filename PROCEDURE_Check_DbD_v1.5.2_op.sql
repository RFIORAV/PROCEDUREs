/* PROCEDURE_Check_DbD.sql - Check Main Table vs Raw data table (fact1/DbD)


Descripción:
  Procedimiento Check_DbD.
   05.09.2022 V1     COMPARA Snapshot_day_by_day contra Snapshot_day_by_day_fact1. Devuelve diferencias
                     Mes corriente a partir de día 6. Antes del 6, Last Month
   19.10.2022 V1.1   Columna Meta
   23.10.2022        Traducción de mensajes. Warning por Deal_Aff=0
   07.12.2022 V1.2   Warning por Deal_Aff=0 & Deal_Ges=0. Check LM hasta día 20
   06.08.2023 v1.5   Incluye campo `Origin` en grid
   Parametros (none)
   10.01.2024 v1.5.1 Agrega campos al grid: Publisher_id,Advertiser_id,Publisher
   11.01.2024 v1.5.2 Karen: preparación para invocar alta missing MS
   10.04.2026 v1.5.3 Meta/grid: etiqueta columna nombre publisher -> Operator
   13.05.2026 v1.5.4 Agrega proyección de CPA a fin de mes con enfoque de regresión lineal simple.

Keys:
  Sin parámetros de entrada documentables.
*/

DROP PROCEDURE IF EXISTS Check_DbD;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE Check_DbD()
   COMMENT 'Check Main Table vs Raw data table (fact1/DbD)'
   LANGUAGE SQL

BEGIN

SET @Version='v1.5.3 10.04.2026';
SET @Meta="YES";

SET @DateCM=LEFT(CURDATE(),7);

IF DAY(CURDATE()) <= 20  
THEN SET @DateFrom=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
ELSE SET @DateFrom=LEFT(CURDATE(),7);
END IF;

-- ***********************************************************************************
 /* 
Proyección de CPA a fin de mes con enfoque de **regresión lineal simple**. La idea es calcular la "pendiente" (ritmo de crecimiento) de 
los últimos 6 meses para aplicarla a los días restantes del mes actual.

### Explicación de la lógica aplicada:

1. **`DailyAggregates`**: Consolida los datos. Si el día 10 de mayo tiene 5 registros, los suma para tener un solo punto de datos por día.
2. **`MonthlyStats`**: Es el motor estadístico. Calcula cuánto se ha acumulado en cada día del mes para los últimos 6 meses. Esto le enseña al modelo "cuánto suele crecer el número" a medida que pasan los días.
3. **`LinearRegression`**: Aplica la fórmula matemática de regresión lineal. La **pendiente (slope)** resultante representa el crecimiento promedio diario del acumulado.
* *Nota:* Se asume una relación lineal. Si tu negocio tiene picos muy fuertes a fin de mes, la regresión lo promediará.

4. **Cálculo Final**:
* Toma lo que llevas acumulado hoy.
* Calcula cuántos días faltan para terminar el mes: `DAYOFMONTH(LAST_DAY(CURDATE())) - current_day`.
* Multiplica esos días por la "velocidad" (pendiente) histórica.

### Consideraciones técnicas:

* **MySQL 8.4**: Utiliza funciones de ventana (`OVER`) que son altamente eficientes para cálculos acumulados.
* **Precisión**: Si no hay datos suficientes en los últimos 6 meses, el divisor en la CTE `LinearRegression` podría dar error de división por cero (aunque es poco probable con datos diarios).
* **Rendimiento**: Asegúrate de tener un índice en el campo ``Date`` para que el filtro de los últimos 6 meses sea instantáneo.

*/

SET @CPA_proyeccion = (
WITH DailyAggregates AS (
    -- 1. Agrupamos por día por si hay múltiples entradas para la misma fecha
    SELECT 
        `Date`,
        SUM(`Qualified_players`) AS daily_sum
    FROM Snapshot_day_by_day_fact1
    WHERE `Date` >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    GROUP BY `Date`
),
MonthlyStats AS (
    -- 2. Calculamos el acumulado por día relativo al inicio de cada mes
    -- 'day_of_month' actúa como nuestra variable X
    -- 'running_total' actúa como nuestra variable Y
    SELECT 
        DAYOFMONTH(`Date`) AS day_of_month,
        SUM(daily_sum) OVER(PARTITION BY LAST_DAY(`Date`) ORDER BY `Date`) AS running_total
    FROM DailyAggregates
),
LinearRegression AS (
    -- 3. Calculamos la pendiente (m) usando la fórmula de mínimos cuadrados:
    -- m = [n*Σ(xy) - Σx*Σy] / [n*Σ(x^2) - (Σx)^2]
    SELECT 
        (COUNT(*) * SUM(day_of_month * running_total) - SUM(day_of_month) * SUM(running_total)) / 
        (COUNT(*) * SUM(POW(day_of_month, 2)) - POW(SUM(day_of_month), 2)) AS slope
    FROM MonthlyStats
),
CurrentMonthProgress AS (
    -- 4. Obtenemos el acumulado real hasta el día de hoy
    SELECT 
        MAX(DAYOFMONTH(`Date`)) AS current_day,
        SUM(daily_sum) AS current_accumulated
    FROM DailyAggregates
    WHERE `Date` BETWEEN DATE_FORMAT(CURDATE(), '%Y-%m-01') AND CURDATE()
)
-- 5. Proyectamos: Acumulado actual + (Pendiente * Días restantes)
SELECT 
   --  p.current_accumulated AS valor_actual_hoy,
    ROUND(p.current_accumulated + (r.slope * (DAYOFMONTH(LAST_DAY(CURDATE())) - p.current_day)), 0) AS proyeccion_fin_de_mes
FROM CurrentMonthProgress p, LinearRegression r
);

-- ***********************************************************************************    
-- Difrerencias de CPA entre DbD y DbD_fact1
WITH Detail_Fact1 as (
  SELECT "" as Meta,
     'Fact1' as Tabla
     ,min(`Date`) as `Date`
     ,`Origin`
     ,Brand
     ,Username_id,Username,Affiliate
	  ,Tracker_ID,Tracker_Name
     ,Product
     ,IFNULL(MS_ID,'missing') as MS_ID -- 11/01/2024
	  ,CASE WHEN MS_ID IS NULL     
           THEN '<<MS missing' 
            ELSE CASE WHEN ifnull(Deal_Aff_id,0)=0 AND ifnull(Deal_Ges_id,0)=0 AND Affiliate NOT IN ('_Unassigned','Parking')
                        THEN '<<DEAL G&A missing. Check Prod/ Country'
                      WHEN ifnull(Deal_Aff_id,0)=0 AND Affiliate NOT IN ('_Unassigned','Parking')
                      	THEN '<<DEAL Aff missing. Check Prod/ Country'
                      WHEN ifnull(Deal_Ges_id,0)=0  
                        THEN '<<DEAL Ges missing. Check Prod/ Country'
            			 ELSE '' END
				END  as Warning
     ,Deal_Aff_id
     ,SUM(Qualified_Players) AS CPA
     ,SUM(Net_Revenue) AS NR
     ,D.Country
     ,D.Hour_Update
     ,P.Advertiser_name as `Operator` -- 10.01.2024
     ,D.Publisher_id                   -- 10.01.2024
     ,D.Advertiser_id                  -- 10.01.2024     
  FROM Snapshot_day_by_day_fact1 D
  LEFT JOIN campaign_publisher P ON P.id=D.Publisher_id     -- 10.01.2024
  WHERE LEFT(Date,7)>=@DateFrom 
      AND (MS_ID IS NULL OR ifnull(Deal_Ges_id,0)=0 
			OR (Affiliate!='_Unassigned' AND (ifnull(Deal_Aff_id,0)=0 AND Qualified_Players<>0)))
      AND (Qualified_Players<>0 OR Net_Revenue<>0)
  GROUP BY Brand,username,Tracker_ID,Tracker_Name,Product HAVING Warning!=''

  -- -----------------------------------------------------------------------
  ORDER BY Brand,Affiliate,Tracker_ID,Tracker_Name
  -- ,Country
),
 Tot_Fact1 as (
 SELECT "" as Meta
      -- ,'Fact1' as Tabla
     ,left(Date,7) `Month`,`Origin`,Brand,Username_id,Username,Affiliate
	  ,Tracker_ID,Tracker_Name
     ,Product
     ,Country 
     ,MS_ID
     -- ,CASE WHEN MS_ID IS NULL            THEN '<<MS missing' 
            -- WHEN MS_ID IS not NULL and ifnull(Deal_Aff_id,0)=0  THEN '<<DEAL Aff missing'
            -- WHEN MS_ID IS not NULL and ifnull(Deal_Ges_id,0)=0  THEN '<<DEAL Ges missing'
            -- ELSE '' END as Warning
     ,'' as Warning
     ,Deal_Aff_id
     ,SUM(Qualified_Players) AS CPA
     ,SUM(Net_Revenue) AS NR  
     ,MAX(Hour_Update) AS `Hour_Update`
     ," "       as `Operator`     -- 10.01.2024 
     ," "       as `Publisher_id`  -- 10.01.2024 
     ," "       as `Advertiser_id` -- 10.01.2024  
  FROM Snapshot_day_by_day_fact1
  WHERE left(Date,7)>=@DateFrom -- AND (Qualified_Players<>0)
  GROUP BY Month
)
(
SELECT "" as Meta
-- 	,Tabla
	 ,`Date`,`Origin`,Brand,Username_id,Username,Affiliate,Tracker_ID,Tracker_Name
    ,Product
    ,Country AS  `Ctry`
    ,MS_ID
    ,Warning
	,CPA AS 'CPAs'
	,NR AS 'NR'
	,Hour_Update
   ,`Operator`                    -- 10.01.2024
   ,Publisher_id                   -- 10.01.2024
   ,Advertiser_id                  -- 10.01.2024    
FROM Detail_Fact1
)
UNION ALL
(
SELECT "" as Meta
-- 	,Tabla
	,`Month`,`Origin`,'TOTAL Month' AS Brand
	,'-------' AS Username_id,'-------' AS Username,'-------' AS Affiliate
	,'-------' AS Tracker_ID ,'-------' AS Tracker_Name
	,'-------' AS MS_ID		 
   ,'-------' AS Product
   ,Country
   ,'-------' AS Warning
   -- ,'-------' AS  CPAs_DbD
	,ROUND(SUM(CPA),0) AS CPAs_Fa1
	,ROUND(SUM(NR),0) AS NR_Fa1
	,Hour_Update
   ," "       as `Operator`     -- 10.01.2024 
   ," "       as `Publisher_id`  -- 10.01.2024 
   ," "       as `Advertiser_id` -- 10.01.2024   
FROM Tot_Fact1 GROUP BY Month
)
UNION ALL
(
SELECT "" as Meta
-- 	,Tabla
	,`Month`,`Origin`,'Curr Month forecast' AS Brand
	,'-------' AS Username_id,'-------' AS Username,'-------' AS Affiliate
	,'-------' AS Tracker_ID,'-------' AS Tracker_Name
	,'-------' AS MS_ID
   ,'-------' AS Product
   ,Country
   ,'-------' AS Warning
   -- ,'-------' AS  CPAs_DbD
	-- ,ROUND(SUM(CPA)/DAY(curdate())*DAY(LAST_DAY(CURDATE())),0) AS CPAs_Fa1
	,@CPA_proyeccion AS CPAs_Fa1
   ,''
	,Hour_Update
   ," "       as `Operator`     -- 10.01.2024 
   ," "       as `Publisher_id`  -- 10.01.2024 
   ," "       as `Advertiser_id` -- 10.01.2024 
FROM Tot_Fact1 WHERE Month=LEFT(CURDATE(),7)
)
UNION ALL 
(
SELECT
  "setting" as Meta
  -- ,"width=80px,center=true" as Tabla
  ,"width=100px" as `Month`
  ,"width=80px" as `Origin`
  ,"width=120px" as Brand
  ,"width=80px"  as Username_id
  ,"width=120px" as Username
  ,"width=130px" as Affiliate
  ,"width=130px" as Tracker_ID
  ,"width=200px" as Tracker_Name
  ,"width=160px" as Product
  ,"width=100px" as Country
  ,"width=120px,action=3"  as MS_ID -- 11/01/2024
  ,"width=200px" as Warning
--   ,"width=80px" as CPAs_DbD
  ,"width=80px"  as CPAs_Fa1
  ,"width=80px"  as NR_Fa1
  ,"width=160px" as Hour_Update
  ,"omit=yes"    as `Operator`     -- 10.01.2024  
  ,"omit=yes"    as `Publisher_id`  -- 10.01.2024  
  ,"omit=yes"    as `Advertiser_id` -- 10.01.2024  
FROM DUAL WHERE @Meta="YES"
)
;

END$$
DELIMITER ;

-- TEST --------------
-- call Check_DbD();