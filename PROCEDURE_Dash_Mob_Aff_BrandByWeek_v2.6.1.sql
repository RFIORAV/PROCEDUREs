/*
PROCEDURE_Dash_Mob_Aff_BrandByWeek_v2.6.1.sql - Dashboard Mobile Aff Performance Brand by week

Descripcion:
  Procedimiento Dash_Mob_Aff_BrandByWeek.
  Metricas semanales por Brand para un affiliate, con salida Classic, Classic_RS, AreaChart, AreaChartL4W o DonutChart.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como unico parametro string

Keys:
 Affiliate_id  = [id affiliate]. OBLIGATORIO. No admite ALL ni vacio.
 Month         = [YYYY-MM | CM | LM]. OPCIONAL. Default=mes actual (o mes anterior si dia<=5).
 Advertiser_id = [ALL | id]. OPCIONAL. Default=ALL.
 Brand         = [ALL | nombre Brand]. OBLIGATORIO. ALL acumula todas las marcas.
 Metric        = [CPA | FTD | Signups | CPA_PM | ALL | RS]. OPCIONAL. Default=CPA. ALL solo en AreaChart/AreaChartL4W. RS en Classic_RS (forzado), AreaChart y AreaChartL4W (RS=net_RS_Val y net_Total_comm desde monthly_comms_affiliate_v5).
 Style         = [Classic | Classic_RS | AreaChart | AreaChartL4W | DonutChart]. OPCIONAL. Default=Classic.
 Filters       = [Yes | No]. OPCIONAL. Default=No.
 Meta          = [No | Yes]. OPCIONAL. Default=No. Solo aplica a Style=Classic y Classic_RS.
 Debug         = [No | Yes | KeyValues]. OPCIONAL. Default=No.

Salidas por Style:
 Classic       - Todas las metricas en una fila por Brand/Week (formato tabular con Meta opcional).
 Classic_RS    - Columnas RS (net_RS_Val) y net_Total_comm desde monthly_comms_affiliate_v5, prorrateadas por semana. Metric=RS.
 AreaChart     - Columnas meta,label,series_name,value por periodo del mes (Days 1-7, Days 8-14, etc.). Metric=ALL devuelve todas las metricas como series. Metric=RS: series RS y Total Comm desde monthly_comms_affiliate_v5 prorrateadas por periodos de 7 dias.
 AreaChartL4W  - Igual que AreaChart pero datos de las 4 ultimas semanas desde hoy (Month ignorado). Metric=ALL igual que AreaChart. Metric=RS igual que AreaChart.
 DonutChart    - Columnas label,value con acumulado mensual de la metrica por Brand (Brand=ALL: una fila por Brand).

Parametros ('[Key=Value[,...]]')

Ejemplos:
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL');
 call Dash_Mob_Aff_BrandByWeek('Affiliate_id=450,Brand=GoldBet,Month=LM,Style=AreaChart,Metric=Signups');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=GoldBet,Month=LM,Style=AreaChart,Metric=Signups');
 call Dash_Mob_Aff_BrandByWeek('Affiliate_id=450,Brand=ALL,Style=AreaChart,Metric=ALL');
 call Dash_Mob_Aff_BrandByWeek('Affiliate_id=450,Brand=ALL,Style=AreaChartL4W,Metric=ALL');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Style=AreaChartL4W,Metric=ALL');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Month=LM,Style=DonutChart');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Style=Classic,debug=KeyValues');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Month=2026-06,Style=Classic_RS,Metric=RS,Meta=Yes');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=934,Brand=ALL,Style=Classic_RS,Metric=RS');
 call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Month=LM,Style=AreaChart,Metric=RS');

25.01.2024 V1     Primera version
27.01.2024        Karen: fix errors
27.01.2024 v1.1   Agrega columna CPA mes previo
11.06.2024 v1.2   Tratamiento de Subafiliados
18.06.2026 v2     Quita Owner; Affiliate_id obligatorio; Metric y Style (Classic/AreaChart/DonutChart)
18.06.2026 v2     Brand obligatorio; ALL acumula todas las marcas (Classic/AreaChart); DonutChart ALL desglosa por Brand; Metric default CPA; AreaChart Metric=ALL
22.06.2026 v2.1   AreaChart: etiquetas Days 1-7, Days 8-14, etc. en lugar de Week 1, Week 2
25.06.2026 v2.2   Karen: AreaChart: quita Views y Clicks
26.06.2026 v2.3   AreaChartL4W: igual que AreaChart con ventana rolling 4 semanas desde hoy
03.07.2026 v2.4   Classic_NR: Net_Revenue y net_Total_comm desde monthly_comms_affiliate_v5; Metric=NR
06.07.2026 v2.5   AreaChart/AreaChartL4W: Metric=NR desde monthly_comms_affiliate_v5 (Net Revenue y Total Comm)
08.07.2026 v2.6   AreaChart/AreaChartL4W: Metric=NR desde v_SnapshotTable acumulado por periodos de 7 dias
17.07.2026 v2.6.1 Elimina Clicks/Views; Metric NR→RS (net_RS_Val + net_Total_comm); Style Classic_RS
*/

DROP PROCEDURE IF EXISTS Dash_Mob_Aff_BrandByWeek;
-- DROP PROCEDURE IF EXISTS Dash_Mob_Aff_BrandByWeek_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_Mob_Aff_BrandByWeek`(IN InputCommLine VARCHAR(250))
COMMENT 'v2.6.1 17.07.2026 - Dashboard Mobile Aff Brand by week (Classic/Classic_RS/AreaChart/AreaChartL4W/DonutChart)'
SQL SECURITY DEFINER
proc_label:BEGIN
DECLARE v_Version VARCHAR(32) DEFAULT 'v2.6.1 17.07.2026';
DECLARE v_InputCommLine VARCHAR(500);
DECLARE v_Month VARCHAR(7);
DECLARE v_Month_Report VARCHAR(7);
DECLARE v_Prev_Month_Report VARCHAR(7);
DECLARE v_Affiliate_id VARCHAR(50) DEFAULT '';
DECLARE v_Advertiser_id VARCHAR(50) DEFAULT 'ALL';
DECLARE v_Brand VARCHAR(100) DEFAULT '';
DECLARE v_Metric VARCHAR(30) DEFAULT 'CPA';
DECLARE v_Style VARCHAR(30) DEFAULT 'CLASSIC';
DECLARE v_Filters VARCHAR(3) DEFAULT 'NO';
DECLARE v_Meta VARCHAR(3) DEFAULT 'NO';
DECLARE v_Debug VARCHAR(20) DEFAULT 'NO';
DECLARE v_AffiliateGroup INT DEFAULT 0;
DECLARE v_SnapshotTable VARCHAR(64) DEFAULT 'Snapshot_day_by_day_fact2';
DECLARE v_CommsTable VARCHAR(64) DEFAULT 'monthly_comms_affiliate_v5';
DECLARE v_MetricExpr VARCHAR(80) DEFAULT '';
DECLARE v_MetricLabel VARCHAR(30) DEFAULT '';
DECLARE v_MonthFilter VARCHAR(7) DEFAULT '';
DECLARE v_SQL LONGTEXT DEFAULT '';
DECLARE v_SQLmeta LONGTEXT DEFAULT '';
DECLARE v_WhereAffiliate_id VARCHAR(120) DEFAULT '';
DECLARE v_WhereAdvertiser_id VARCHAR(120) DEFAULT '';
DECLARE v_WhereBrand VARCHAR(200) DEFAULT '';
DECLARE v_BrandSelectExpr VARCHAR(80) DEFAULT 'Brand';
DECLARE v_GroupByClause VARCHAR(80) DEFAULT 'Brand,`Week`';
DECLARE v_CommsGroupByClause VARCHAR(120) DEFAULT 'Brand';
DECLARE v_WeekNumCase VARCHAR(600) DEFAULT '';
DECLARE v_WeekNumCasePM VARCHAR(600) DEFAULT '';
DECLARE v_DateFilter VARCHAR(200) DEFAULT '';
DECLARE v_DateFilterPM VARCHAR(200) DEFAULT '';
DECLARE v_WeekLabelWhen VARCHAR(300) DEFAULT '';
DECLARE v_e INT;
DECLARE v_c INT;
DECLARE v_k VARCHAR(100);
DECLARE v_v VARCHAR(250);
DECLARE v_RS_Status TINYINT DEFAULT 0;                                      

SET v_Month = IF(
    DAY(CURDATE()) <= 5,
    LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7),
    LEFT(CURDATE(), 7)
);

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

    IF LOWER(v_k) = 'month'         THEN SET v_Month         = v_v;        END IF;
    IF LOWER(v_k) = 'affiliate_id'  THEN SET v_Affiliate_id  = v_v;        END IF;
    IF LOWER(v_k) = 'advertiser_id' THEN SET v_Advertiser_id = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'brand'         THEN SET v_Brand         = TRIM(v_v);  END IF;
    IF LOWER(v_k) = 'metric'        THEN SET v_Metric        = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'style'         THEN SET v_Style         = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'filters'       THEN SET v_Filters       = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'meta'          THEN SET v_Meta          = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'debug'         THEN SET v_Debug         = UPPER(v_v); END IF;
END WHILE;

IF v_Affiliate_id = '' OR UPPER(v_Affiliate_id) = 'ALL' THEN
    SELECT 'ERROR: Affiliate_id obligatorio. No admite ALL ni vacio.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Affiliate_id NOT REGEXP '^[0-9]+$' THEN
    SELECT 'ERROR: Affiliate_id debe ser numerico.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Brand = '' THEN
    SELECT 'ERROR: Brand obligatorio. Informe ALL para acumular todas las marcas.' AS error_message;
    LEAVE proc_label;
END IF;

IF UPPER(v_Brand) <> 'ALL' THEN
    SET v_WhereBrand = CONCAT(' AND Brand = "', REPLACE(v_Brand, '"', '""'), '" ');
    SET v_BrandSelectExpr = 'Brand';
    SET v_GroupByClause = 'Brand,`Week`';
    SET v_CommsGroupByClause = 'Brand';
ELSE
    SET v_WhereBrand = '';
    SET v_BrandSelectExpr = "'ALL'                         as `Brand`";
    SET v_GroupByClause = '`Week`';
    SET v_CommsGroupByClause = 'Affiliate_id, `Month`';
END IF;

IF v_Style NOT IN ('CLASSIC', 'CLASSIC_RS', 'AREACHART', 'AREACHARTL4W', 'DONUTCHART') THEN
    SELECT 'ERROR: Style invalido. Valores permitidos: Classic, Classic_RS, AreaChart, AreaChartL4W, DonutChart.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Style = 'CLASSIC_RS' THEN
    SET v_Metric = 'RS';
END IF;

SET v_Month_Report = v_Month;
IF UPPER(v_Month) = 'CM' THEN
    SET v_Month_Report = LEFT(CURDATE(), 7);
ELSEIF UPPER(v_Month) = 'LM' THEN
    SET v_Month_Report = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7);
END IF;

IF CHAR_LENGTH(v_Month_Report) <> 7
    OR SUBSTRING(v_Month_Report, 5, 1) <> '-'
    OR STR_TO_DATE(CONCAT(v_Month_Report, '-01'), '%Y-%m-%d') IS NULL THEN
    SELECT 'ERROR: Month invalido. Formato esperado YYYY-MM (o alias CM / LM).' AS error_message;
    LEAVE proc_label;
END IF;

SET v_Prev_Month_Report = LEFT(DATE_SUB(CONCAT(v_Month_Report, '-01'), INTERVAL 1 DAY), 7);

IF v_Metric = 'ALL' AND v_Style NOT IN ('AREACHART', 'AREACHARTL4W') THEN
    SELECT 'ERROR: Metric=ALL solo aplica a Style=AreaChart o AreaChartL4W.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Metric = 'RS' AND v_Style NOT IN ('CLASSIC_RS', 'AREACHART', 'AREACHARTL4W') THEN
    SELECT 'ERROR: Metric=RS solo aplica a Style=Classic_RS, AreaChart o AreaChartL4W.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Style NOT IN ('CLASSIC_RS', 'AREACHART', 'AREACHARTL4W')
    AND v_Metric NOT IN ('CPA', 'FTD', 'SIGNUPS', 'CPA_PM', 'ALL') THEN
    SELECT 'ERROR: Metric invalido. Valores permitidos: CPA, FTD, Signups, CPA_PM, ALL.' AS error_message;
    LEAVE proc_label;
END IF;

IF v_Advertiser_id <> 'ALL' THEN
    SET v_WhereAdvertiser_id = CONCAT(' AND Advertiser_id = ', v_Advertiser_id, ' ');
END IF;

SELECT IFNULL(MAX(group_id), 0) INTO v_AffiliateGroup
FROM account_account_groups
WHERE account_id = CAST(v_Affiliate_id AS UNSIGNED)
    AND group_id = 6;

IF v_AffiliateGroup = 6 THEN
    SET v_SnapshotTable = 'sub_Snapshot_day_by_day_fact3';
    SET v_CommsTable = 'sub_monthly_comms_affiliate';
END IF;

SET v_WhereAffiliate_id = CONCAT(' AND Affiliate_id = ', v_Affiliate_id, ' ');

IF v_Debug = 'KEYVALUES' THEN
    SELECT
        v_Version             AS version,
        v_Month               AS month_input,
        v_Month_Report        AS month_report,
        v_Prev_Month_Report   AS prev_month_report,
        v_Affiliate_id        AS affiliate_id,
        v_Advertiser_id       AS advertiser_id,
        v_Brand               AS brand,
        v_Metric              AS metric,
        v_Style               AS style,
        v_AffiliateGroup      AS affiliate_group,
        v_SnapshotTable       AS snapshot_table,
        v_CommsTable          AS comms_table,
        v_Meta                AS meta,
        v_Debug               AS debug;
END IF;

IF v_Debug NOT IN ('NO', 'KEYVALUES') THEN
    SELECT
        v_Month_Report      AS month_report,
        v_Prev_Month_Report AS prev_month_report,
        v_Affiliate_id      AS affiliate_id,
        v_Style             AS style,
        v_Metric            AS metric,
        InputCommLine       AS input_comm_line;
END IF;

-- SET SESSION group_concat_max_len = 200000;

IF v_Style = 'CLASSIC' THEN
    SET v_SQLmeta = '
    SELECT
    "setting"
    ,"width=100px"                         `Affiliate_id`
    ,"width=100px"                         `Month`
    ,"width=100px"                         `Week`
    ,"width=110px,sortable=yes"            `Brand`
    ,"width=090px, right=true"             `CPA`
    ,"width=090px, right=true"             `FTD`
    ,"width=090px, right=true"             `Signups`
    ,"width=110px, right=true"             `CPA Prev Mth`
        FROM DUAL WHERE @MetaClassic = "YES"
    UNION ALL ';

    SET v_SQL = CONCAT('
    WITH
    Set_Acum_CM_LM as (
    SELECT
        Affiliate_id
        ,"', v_Month_Report, '"              as `Month`
        ,CASE
            WHEN DAY(DATE) BETWEEN 01 AND 07 THEN 1
            WHEN DAY(DATE) BETWEEN 08 AND 14 THEN 2
            WHEN DAY(DATE) BETWEEN 15 AND 21 THEN 3
            WHEN DAY(DATE) BETWEEN 22 AND 28 THEN 4
            ELSE 5 END                     as `Week`
        ,', v_BrandSelectExpr, '
        ,sum(IFNULL(Qualified_Players,0) ) AS `CPA`
        ,sum(IFNULL(First_Time_Deposit,0)) AS `FTD`
        ,sum(IFNULL(Signups,0)           ) AS `Signups`
        ,0                                 as `CPA PM`
    FROM ', v_SnapshotTable, '
    WHERE LEFT(DATE,7) ="', v_Month_Report, '" ', v_WhereAffiliate_id, v_WhereBrand, '
    GROUP BY ', v_GroupByClause, '
    UNION ALL
    SELECT
        Affiliate_id
        ,"', v_Month_Report, '"              as `Month`
        ,CASE
            WHEN DAY(DATE) BETWEEN 01 AND 07 THEN 1
            WHEN DAY(DATE) BETWEEN 08 AND 14 THEN 2
            WHEN DAY(DATE) BETWEEN 15 AND 21 THEN 3
            WHEN DAY(DATE) BETWEEN 22 AND 28 THEN 4
            ELSE 5 END                     as `Week`
        ,', v_BrandSelectExpr, '
        ,0                                 AS `CPA`
        ,0                                 AS `FTD`
        ,0                                 AS `Signups`
        ,sum(IFNULL(Qualified_Players,0) ) as `CPA PM`
    FROM ', v_SnapshotTable, '
    WHERE LEFT(DATE,7) ="', v_Prev_Month_Report, '" ', v_WhereAffiliate_id, v_WhereBrand, '
    GROUP BY ', v_GroupByClause, '
    ),
    Set_Acumulados as (
    SELECT
        Affiliate_id
        ,`Month`
        ,`Week`
        ,Brand
        ,sum(`CPA`)        AS `CPA`
        ,sum(`FTD`)        AS `FTD`
        ,sum(`Signups`)    AS `Signups`
        ,sum(`CPA PM`)     as `CPA PM`
    FROM Set_Acum_CM_LM
    GROUP BY ', v_GroupByClause, '
    ) ',
        IF(v_Meta = 'YES', v_SQLmeta, ' '),
        '
    SELECT "data",A.* FROM Set_Acumulados A
    ORDER BY Brand,`Week`
    ;');

    SET @MetaClassic = v_Meta;

    IF v_Debug = 'YES' THEN
        SELECT v_SQL AS generated_sql;
    ELSE
        SET @v_stmt_sql = v_SQL;
        PREPARE stmt1 FROM @v_stmt_sql;
        EXECUTE stmt1;
        DEALLOCATE PREPARE stmt1;
    END IF;

    LEAVE proc_label;
END IF;

IF v_Style = 'CLASSIC_RS' THEN
    SET v_SQLmeta = '
    SELECT
    "setting"
    ,"width=100px"                         `Affiliate_id`
    ,"width=100px"                         `Month`
    ,"width=100px"                         `Week`
    ,"width=110px,sortable=yes"            `Brand`
    ,"width=110px, right=true"             `RS`
    ,"width=110px, right=true"             `net_Total_comm`
        FROM DUAL WHERE @MetaClassicRS = "YES"
    UNION ALL ';

    SET v_SQL = CONCAT('
    WITH RECURSIVE MonthDays AS (
    SELECT STR_TO_DATE(CONCAT("', v_Month_Report, '","-01"), "%Y-%m-%d") AS `Date`
    UNION ALL
    SELECT `Date` + INTERVAL 1 DAY
    FROM MonthDays
    WHERE `Date` + INTERVAL 1 DAY < DATE_ADD(STR_TO_DATE(CONCAT("', v_Month_Report, '","-01"), "%Y-%m-%d"), INTERVAL 1 MONTH)
    ),
    MonthlyByBrand AS (
    SELECT
        Affiliate_id
        ,`Month`
        ,', v_BrandSelectExpr, '
        ,SUM(IFNULL(`net_RS_Val`,0))     AS `RS`
        ,SUM(IFNULL(`net_Total_comm`,0)) AS `net_Total_comm`
    FROM ', v_CommsTable, '
    WHERE `Month` ="', v_Month_Report, '" ', v_WhereAffiliate_id, v_WhereBrand, v_WhereAdvertiser_id, '
    GROUP BY Affiliate_id, `Month`', IF(v_CommsGroupByClause = 'Brand', ', Brand', ''), '
    ),
    Set_Acumulados AS (
    SELECT
        B.Affiliate_id
        ,B.`Month`
        ,CASE
            WHEN DAY(D.`Date`) BETWEEN 01 AND 07 THEN 1
            WHEN DAY(D.`Date`) BETWEEN 08 AND 14 THEN 2
            WHEN DAY(D.`Date`) BETWEEN 15 AND 21 THEN 3
            WHEN DAY(D.`Date`) BETWEEN 22 AND 28 THEN 4
            ELSE 5 END                     AS `Week`
        ,B.Brand
        ,ROUND(SUM(B.`RS`             / DAY(LAST_DAY(D.`Date`))), 2) AS `RS`
        ,ROUND(SUM(B.`net_Total_comm` / DAY(LAST_DAY(D.`Date`))), 2) AS `net_Total_comm`
    FROM MonthlyByBrand B
    CROSS JOIN MonthDays D
    GROUP BY B.Affiliate_id, B.`Month`, B.Brand, `Week`
    ) ',
        IF(v_Meta = 'YES', v_SQLmeta, ' '),
        '
    SELECT "data", A.* FROM Set_Acumulados A
    ORDER BY Brand, `Week`
    ;');

    SET @MetaClassicRS = v_Meta;

    IF v_Debug = 'YES' THEN
        SELECT v_SQL AS generated_sql;
    ELSE
        SET @v_stmt_sql = v_SQL;
        PREPARE stmt1rs FROM @v_stmt_sql;
        EXECUTE stmt1rs;
        DEALLOCATE PREPARE stmt1rs;
    END IF;

    LEAVE proc_label;
END IF;

IF v_Style IN ('AREACHART', 'AREACHARTL4W') THEN

    SET v_WeekNumCase = '
    WHEN DAY(`Date`) BETWEEN 01 AND 07 THEN 1
    WHEN DAY(`Date`) BETWEEN 08 AND 14 THEN 2
    WHEN DAY(`Date`) BETWEEN 15 AND 21 THEN 3
    WHEN DAY(`Date`) BETWEEN 22 AND 28 THEN 4
    ELSE 5';
    SET v_WeekNumCasePM = v_WeekNumCase;
    SET v_DateFilter = CONCAT('LEFT(`Date`, 7) = "', v_Month_Report, '"');
    SET v_DateFilterPM = CONCAT('LEFT(`Date`, 7) = "', v_Prev_Month_Report, '"');
    SET v_WeekLabelWhen = 'WHEN 1 THEN "Days 1-7" WHEN 2 THEN "Days 8-14" WHEN 3 THEN "Days 15-21" WHEN 4 THEN "Days 22-28" ELSE "Days 29-31"';

    IF v_Metric = 'ALL' THEN
        SET v_SQL = CONCAT('
        WITH WeeklyData AS (
            SELECT
                CASE', v_WeekNumCase, '
                END AS WeekNum,
                SUM(IFNULL(Qualified_Players,0))  AS CPA,
                SUM(IFNULL(First_Time_Deposit,0)) AS FTD,
                SUM(IFNULL(Signups,0))            AS Signups
            FROM ', v_SnapshotTable, '
            WHERE ', v_DateFilter, ' ', v_WhereAffiliate_id, v_WhereBrand, '
            GROUP BY WeekNum
        ),
        WeeklyDataPM AS (
            SELECT
                CASE', v_WeekNumCasePM, '
                END AS WeekNum,
                SUM(IFNULL(Qualified_Players,0)) AS CPA_PM
            FROM ', v_SnapshotTable, '
            WHERE ', v_DateFilterPM, ' ', v_WhereAffiliate_id, v_WhereBrand, '
            GROUP BY WeekNum
        )
        SELECT meta, label, series_name, value
        FROM (
            SELECT
                0 AS sort_order,
                0 AS week_num,
                0 AS series_order,
                "axisName" AS meta,
                "Days" AS label,
                "-" AS series_name,
                "" AS value
            UNION ALL
            SELECT 1, W.WeekNum, 1, "data", CASE W.WeekNum ', v_WeekLabelWhen, ' END, "CPA", W.CPA FROM WeeklyData W UNION ALL
            SELECT 1, W.WeekNum, 2, "data", CASE W.WeekNum ', v_WeekLabelWhen, ' END, "FTD", W.FTD FROM WeeklyData W UNION ALL
            SELECT 1, W.WeekNum, 5, "data", CASE W.WeekNum ', v_WeekLabelWhen, ' END, "Signups", W.Signups  FROM WeeklyData W UNION ALL
            SELECT 1, P.WeekNum, 6, "data", CASE P.WeekNum ', v_WeekLabelWhen, ' END, "CPA Prev Mth", P.CPA_PM  FROM WeeklyDataPM P
        ) chart_rows
        ORDER BY sort_order, week_num, series_order
        ;');
    ELSEIF v_Metric = 'RS' THEN
				SET v_RS_Status = Check_RS_affiliate(v_Affiliate_id);                                                         
        SET v_SQL = CONCAT('
        WITH RECURSIVE MonthDays AS (
            SELECT STR_TO_DATE(CONCAT("', v_Month_Report, '","-01"), "%Y-%m-%d") AS `Date`
            UNION ALL
            SELECT `Date` + INTERVAL 1 DAY
            FROM MonthDays
            WHERE `Date` + INTERVAL 1 DAY < DATE_ADD(STR_TO_DATE(CONCAT("', v_Month_Report, '","-01"), "%Y-%m-%d"), INTERVAL 1 MONTH)
        ),
        MonthlyRS AS (
            SELECT
                SUM(IFNULL(`net_RS_Val`,0))     AS `RS`
                ,SUM(IFNULL(`net_Total_comm`,0)) AS `net_Total_comm`
            FROM ', v_CommsTable, '
            WHERE `Month` ="', v_Month_Report, '" ', v_WhereAffiliate_id, v_WhereBrand, v_WhereAdvertiser_id, '
        ),
        WeeklyData AS (
            SELECT
                CASE', v_WeekNumCase, '
                END AS WeekNum,
                ROUND(SUM(M.`RS`             / DAY(LAST_DAY(D.`Date`))), 2) AS `RS`,
                ROUND(SUM(M.`net_Total_comm` / DAY(LAST_DAY(D.`Date`))), 2) AS `net_Total_comm`
            FROM MonthlyRS M
            CROSS JOIN MonthDays D
            GROUP BY WeekNum
        )
        SELECT meta, label, series_name, value
        FROM (
            SELECT
                0 AS sort_order,
                0 AS week_num,
                0 AS series_order,
                "axisName" AS meta,
                "Days" AS label,
                "-" AS series_name,
                "" AS value
            UNION ALL',
						IF(v_RS_Status = 1,CONCAT('
            SELECT 1, W.WeekNum, 1, "data", CASE W.WeekNum ', v_WeekLabelWhen, ' END, "RS", W.RS FROM WeeklyData W UNION ALL'),''),' 
            SELECT 1, W.WeekNum, 2, "data", CASE W.WeekNum ', v_WeekLabelWhen, ' END, "Total Comm", W.net_Total_comm FROM WeeklyData W
        ) chart_rows
        ORDER BY sort_order, week_num, series_order
        ;');
    ELSE
        SET v_MetricExpr = CASE v_Metric
            WHEN 'CPA'      THEN 'IFNULL(Qualified_Players,0)'
            WHEN 'FTD'      THEN 'IFNULL(First_Time_Deposit,0)'
            WHEN 'SIGNUPS'  THEN 'IFNULL(Signups,0)'
            WHEN 'CPA_PM'   THEN 'IFNULL(Qualified_Players,0)'
            ELSE '0'
        END;

        SET v_MetricLabel = CASE v_Metric
            WHEN 'CPA'      THEN 'CPA'
            WHEN 'FTD'      THEN 'FTD'
            WHEN 'SIGNUPS'  THEN 'Signups'
            WHEN 'CPA_PM'   THEN 'CPA Prev Mth'
            ELSE ''
        END;

        IF v_Metric = 'CPA_PM' THEN
            SET v_DateFilter = v_DateFilterPM;
            SET v_WeekNumCase = v_WeekNumCasePM;
        END IF;

        SET v_SQL = CONCAT('
            WITH WeeklyData AS (
                SELECT
                    CASE', v_WeekNumCase, '
                    END AS WeekNum,
                    SUM(', v_MetricExpr, ') AS metric_value
                FROM ', v_SnapshotTable, '
                WHERE ', v_DateFilter, ' ', v_WhereAffiliate_id, v_WhereBrand, '
                GROUP BY WeekNum
            )
            SELECT meta, label, series_name, value
            FROM (
                SELECT
                    0 AS sort_order,
                    0 AS week_num,
                    "axisName" AS meta,
                    "Days" AS label,
                    "-" AS series_name,
                    "" AS value
                UNION ALL
                SELECT
                    1 AS sort_order,
                    WeekNum AS week_num,
                    "data" AS meta,
                    CASE WeekNum ', v_WeekLabelWhen, ' END AS label,
                    "', v_MetricLabel, '" AS series_name,
                    metric_value AS value
                FROM WeeklyData
            ) chart_rows
            ORDER BY sort_order, week_num
            ;');
    END IF;

    IF v_Debug = 'YES' THEN
        SELECT v_SQL AS generated_sql;
    ELSE
        SET @v_stmt_sql = v_SQL;
        PREPARE stmt2 FROM @v_stmt_sql;
        EXECUTE stmt2;
        DEALLOCATE PREPARE stmt2;
    END IF;

    LEAVE proc_label;
END IF;

SET v_MetricExpr = CASE v_Metric
    WHEN 'CPA'      THEN 'IFNULL(Qualified_Players,0)'
    WHEN 'FTD'      THEN 'IFNULL(First_Time_Deposit,0)'
    WHEN 'SIGNUPS'  THEN 'IFNULL(Signups,0)'
    WHEN 'CPA_PM'   THEN 'IFNULL(Qualified_Players,0)'
    ELSE '0'
END;

SET v_MonthFilter = IF(v_Metric = 'CPA_PM', v_Prev_Month_Report, v_Month_Report);

IF v_Style = 'DONUTCHART' THEN
    SET v_SQL = CONCAT('
    SELECT
        Brand AS label,
        SUM(', v_MetricExpr, ') AS value
    FROM ', v_SnapshotTable, '
    WHERE LEFT(`Date`, 7) = "', v_MonthFilter, '" ', v_WhereAffiliate_id, v_WhereBrand, '
    GROUP BY Brand
    HAVING SUM(', v_MetricExpr, ') <> 0
    ORDER BY value DESC
    ;');

    IF v_Debug = 'YES' THEN
        SELECT v_SQL AS generated_sql;
    ELSE
        SET @v_stmt_sql = v_SQL;
        PREPARE stmt3 FROM @v_stmt_sql;
        EXECUTE stmt3;
        DEALLOCATE PREPARE stmt3;
    END IF;
END IF;

END$$
DELIMITER ;

/*
Ejemplos:

call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Meta=Yes');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=527,Brand=GoldBet,Month=CM,Style=AreaChart,Metric=Signups');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=527,Brand=ALL,Style=AreaChartL4W,Metric=ALL');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=39,Brand=ALL,Month=LM,Style=DonutChart,Metric=CPA');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=527,Brand=ALL,Style=Classic,debug=KeyValues');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Month=2026-06,Style=Classic_RS,Metric=RS,Meta=Yes');
call Dash_Mob_Aff_BrandByWeek_dev('Affiliate_id=450,Brand=ALL,Month=2026-06,Style=AreaChart,Metric=RS');
*/
