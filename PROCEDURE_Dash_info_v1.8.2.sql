/*
PROCEDURE_Dash_info_v1.8.2.sql

Descripción:
  Procedimiento Dash_info.

Observaciones:
 Devuelve currentValue y trendValue para una metrica puntual del dashboard mensual.
 No utiliza columna Meta.
 Cada Key debe estar seguida de = y el valor deseado SIN comillas.
 Cada par Key=Value debe ir seguido de una COMA.
 El conjunto de pares debe ir entre '' (comillas simples) como unico parametro string.

Keys:
 Month    = [YYYY-MM | CM | LM]. OPCIONAL. Default=mes actual.
             CM = mes corriente, LM = mes anterior.
 Metric   = [CPA | CPA_Value | RS_Val | Tot_Comm | CPA_Profit | Profit]. OPCIONAL. Default=CPA.
 Debug    = [No | Yes | KeyValues]. OPCIONAL. Default=No.

Parametros ('[Key=Value[,...]]')

Ejemplos:
 call Dash_info_dev('Metric=CPA');
 call Dash_info_dev('Metric=CPA,debug=yes');
 call Dash_info('Metric=CPA,debug=yes');
 call Dash_info('Month=LM,Metric=CPA,debug=yes');
 call Dash_info_dev('Month=LM,Metric=CPA,debug=yes');
 call Dash_info('Month=2026-02,Metric=CPA,debug=yes');
 call Dash_info_dev('Month=2026-02,Metric=CPA,debug=yes');
 call Dash_info_dev('Month=2026-01,Metric=Profit,debug=yes');
 call Dash_info_dev('Month=CM,Metric=CPA,debug=yes');
 call Dash_info_dev('Month=LM,Metric=Tot_Comm,debug=yes');
 call Dash_info_dev('Debug=KeyValues');

15.04.2026 v1.0 Primera version operativa
15.04.2026 v1.1 Se migra a InputCommLine y se agregan defaults Month actual y Owner_id=ALL
15.04.2026 v1.2 Owner_id informado se traduce a username desde account_account; sin Owner_id usa Owner=All Owners
28.04.2026 v1.3 trendValue pasa a porcentaje de variacion contra mes anterior
22.05.2026 v1.4 Si Month=mes corriente, trendValue compara acumulado a la misma fecha del mes anterior; fix filtro Date en meses distintos al corriente
29.05.2026 v1.5 Fix filtro por Owner en dash_total_by_month y campaign_log_dashboard
04.06.2026 v1.6 Fix extraccion de fecha en Owner_id de campaign_log_dashboard (SUBSTR 9,10 en lugar de RIGHT 16); comparacion con <= v_CompareDay para usar snapshot mas reciente disponible; se elimina fallback incorrecto al total completo del mes anterior
08.06.2026 v1.6.1 Month acepta alias CM (mes corriente) y LM (mes anterior)
09.06.2026 v1.7 Acceso a campaign_log_dashboard via CTE con MID(Owner_id,9,16) como Datetime_retrieval; PrevCompareDate = mismo dia del mes anterior (mes corriente) o LAST_DAY(mes anterior) (mes pasado); unica rama de calculo para ambos casos
20.06.2026 v1.8 Fix filtro Owner en campaign_log_dashboard: siempre v_Owner; Check_Owner con COUNT(DISTINCT) y fallback desde campaign_log_dashboard; debug solo tras calculo
21.06.2026 v1.8.1 Si Month=mes corriente, se usa campaign_log_dashboard_now si existe y es reciente; si no, se recupera campaign_log_dashboard
22.06.2026 v1.8.2 Se eliminan parametros y logica de Owner y Owner_id
*/

DROP PROCEDURE IF EXISTS Dash_info;
DROP PROCEDURE IF EXISTS Dash_info_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_info`(IN InputCommLine VARCHAR(250))
COMMENT 'v1.8.2 22.06.2026 - Obtiene currentValue y trendValue por metrica desde campaign_log_dashboard'
SQL SECURITY DEFINER

proc_label:BEGIN
    DECLARE v_Version VARCHAR(32) DEFAULT 'v1.8.2 22.06.2026';
    DECLARE v_InputCommLine VARCHAR(500);
    DECLARE v_Month VARCHAR(7);
    DECLARE v_PrevMonth VARCHAR(7);
    DECLARE v_Metric VARCHAR(30);
    DECLARE v_Debug VARCHAR(20);
    DECLARE v_CurrentValue DECIMAL(16,2) DEFAULT 0;
    DECLARE v_PrevValue DECIMAL(16,2);
    DECLARE v_e INT;
    DECLARE v_c INT;
    DECLARE v_k VARCHAR(100);
    DECLARE v_v VARCHAR(250);
    DECLARE v_Percent_Month DECIMAL(16,2) DEFAULT 0;

    SET v_Month = LEFT(CURDATE(), 7);
    SET v_Metric = 'CPA';
    SET v_Debug = 'NO';

    SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');

        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE proc_label;
        END IF;

        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'month'    THEN SET v_Month    = v_v;        END IF;
        IF LOWER(v_k) = 'metric'   THEN SET v_Metric   = UPPER(v_v); END IF;
        IF LOWER(v_k) = 'debug'    THEN SET v_Debug    = UPPER(v_v); END IF;
    END WHILE;

    -- Traduccion de alias de mes: CM = mes corriente, LM = mes anterior
    IF UPPER(v_Month) = 'CM' THEN
        SET v_Month = LEFT(CURDATE(), 7);
    ELSEIF UPPER(v_Month) = 'LM' THEN
        SET v_Month = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), '%Y-%m');
    END IF;

    IF CHAR_LENGTH(v_Month) <> 7
       OR SUBSTRING(v_Month, 5, 1) <> '-'
       OR STR_TO_DATE(CONCAT(v_Month, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT 'ERROR: Month invalido. Formato esperado YYYY-MM (o alias CM / LM).' AS error_message;
        LEAVE proc_label;
    END IF;

    IF v_Metric NOT IN ('CPA', 'CPA_VALUE', 'RS_VAL', 'TOT_COMM', 'CPA_PROFIT', 'PROFIT') THEN
        SELECT 'ERROR: Metric invalido. Valores permitidos: CPA, CPA_Value, RS_Val, Tot_Comm, CPA_Profit, Profit.' AS error_message;
        LEAVE proc_label;
    END IF;

/**************************************************************************************************************/

SET v_PrevMonth = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(v_Month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH),'%Y-%m');

-- Calculo del porcentaje de dias transcurridos del mes corriente
IF v_Month = LEFT(CURDATE(), 7) THEN
    SET v_Percent_Month = DAY(CURDATE()) / DAY(LAST_DAY(CURDATE())); -- dia de hoy del mes corriente / dias del mes
ELSE
    SET v_Percent_Month = 1;
END IF;
    

/**************************************************************************************************************/

SET @K_dashboard_now=(SELECT count(*) FROM campaign_log_dashboard_now 
    WHERE `DashMonth`=v_Month AND TIMESTAMPDIFF(MINUTE, `Date_gen`, NOW()) < 20);
IF @K_dashboard_now=0 THEN call Dash_Gestor_TotalByAdvertiser(concat('Month=',v_Month,',Rec_log=DASH')); END IF;

SET @K_dashboard_now=(SELECT count(*) FROM campaign_log_dashboard_now 
    WHERE `DashMonth`=v_PrevMonth AND TIMESTAMPDIFF(MINUTE, `Date_gen`, NOW()) < 20);
IF @K_dashboard_now=0 THEN call Dash_Gestor_TotalByAdvertiser(concat('Month=',v_PrevMonth,',Rec_log=DASH')); END IF;

/**************************************************************************************************************/
-- -----------------------------------------------------------------
    IF v_Debug <> 'NO' THEN
        SELECT
            v_Version        ,
            v_Month          ,
            v_PrevMonth      ,
            v_Metric         ,
            v_CurrentValue   ,
            @K_dashboard_now ,
            v_Percent_Month  ,
            v_PrevValue      ;
    END IF;
-- -----------------------------------------------------------------
    -- Valor acumulado del mes solicitado
    WITH cld_current AS (
    SELECT
        NOW() AS Datetime_retrieval,
        CAST(CPA AS DECIMAL(15,0)) AS CPA,
        CAST(CPA_Value AS DECIMAL(15,2)) AS CPA_Value,
        CAST(RS_Val AS DECIMAL(15,2)) AS RS_Val,
        CAST(Tot_Comm AS DECIMAL(15,2)) AS Tot_Comm,
        CAST(Profit AS DECIMAL(15,2)) AS Profit,
        CAST(AfCom_cpa AS DECIMAL(15,2)) AS AfCom_cpa 
    FROM campaign_log_dashboard_now
        WHERE v_Month = DashMonth
        LIMIT 1
    )
    SELECT IFNULL(
        CASE v_Metric
            WHEN 'CPA'        THEN IFNULL(`CPA`, 0)
            WHEN 'CPA_VALUE'  THEN IFNULL(`CPA_Value`, 0)
            WHEN 'RS_VAL'     THEN IFNULL(`RS_Val`, 0)
            WHEN 'TOT_COMM'   THEN IFNULL(`Tot_Comm`, 0)
            WHEN 'CPA_PROFIT' THEN IFNULL(`CPA_Value`, 0) - IFNULL(`AfCom_cpa`, 0)
            WHEN 'PROFIT'     THEN IFNULL(`Profit`, 0)
            ELSE 0
        END, 0) INTO v_CurrentValue
    FROM cld_current
    ;
    -- ORDER BY Datetime_retrieval DESC
    -- LIMIT 1;

    -- Toma el snapshot del mes anterior desde campaign_log_dashboard_now.
    -- Si no existe snapshot disponible, v_PrevValue queda NULL -> trendValue = 0.
    SET v_PrevValue = NULL;

    WITH cld AS (
    SELECT
        NOW() AS Datetime_retrieval,
        CAST(CPA AS DECIMAL(15,0)) AS CPA,
        CAST(CPA_Value AS DECIMAL(15,2)) AS CPA_Value,
        CAST(RS_Val AS DECIMAL(15,2)) AS RS_Val,
        CAST(Tot_Comm AS DECIMAL(15,2)) AS Tot_Comm,
        CAST(Profit AS DECIMAL(15,2)) AS Profit,
        CAST(AfCom_cpa AS DECIMAL(15,2)) AS AfCom_cpa 
    FROM campaign_log_dashboard_now
        WHERE v_PrevMonth = DashMonth
        LIMIT 1
    )
    SELECT
        CASE v_Metric
            WHEN 'CPA'        THEN IFNULL(`CPA`, 0)
            WHEN 'CPA_VALUE'  THEN IFNULL(`CPA_Value`, 0)
            WHEN 'RS_VAL'     THEN IFNULL(`RS_Val`, 0)
            WHEN 'TOT_COMM'   THEN IFNULL(`Tot_Comm`, 0)
            WHEN 'CPA_PROFIT' THEN IFNULL(`CPA_Value`, 0) - IFNULL(`AfCom_cpa`, 0)
            WHEN 'PROFIT'     THEN IFNULL(`Profit`, 0)
            ELSE 0
        END INTO v_PrevValue
    FROM cld
    ;

    SET v_PrevValue = IFNULL(v_PrevValue, 0);

    SELECT
        CASE WHEN v_Metric = 'CPA' THEN FORMAT(v_CurrentValue, 0) ELSE FORMAT(v_CurrentValue, 2) END AS currentValue,
        CASE
            WHEN v_PrevValue = 0 THEN 0
            ELSE ROUND(((v_CurrentValue - (v_PrevValue * v_Percent_Month)) / (v_PrevValue * v_Percent_Month)) * 100, 1)
        END AS trendValue;

    IF v_Debug <> 'NO' THEN
        SELECT
            v_Version        ,
            v_Month          ,
            v_PrevMonth      ,
            v_Metric         ,
            v_CurrentValue   ,
            @K_dashboard_now ,
            v_Percent_Month  ,
            v_PrevValue      ;
    END IF;
    
END$$
DELIMITER ;

/*
-- Crear tabla si no existe PROCEDURE_DashTotalByMonth_v1.sql
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
 */
