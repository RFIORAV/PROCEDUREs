/*
PROCEDURE_Report_Reversed_CPA_v1.1.sql

Descripción:
  Procedimiento Report_Reversed_CPA.
  Muestra matriz diaria de CPA reversadas por MS para el mes seleccionado.

Observaciones:
 Cada Key debe estar seguida de = y el valor deseado SIN comillas
 Cada par Key=Value debe ir seguido de una COMA
 El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
 Month     = [YYYY-MM | CM | LM]. Mes de datos. OPCIONAL. Default=LM.
 Brand     = [ALL | Brand | Brand^Brand]. Filtro por Brand. OPCIONAL. Default=ALL.
 Username  = [ALL | Username_id | Username | valor^valor]. Filtro por cuenta. OPCIONAL. Default=ALL.
 Publisher = [ALL | Publisher_id | Operator | valor^valor]. Filtro por Publisher/Operator. OPCIONAL. Default=ALL.
 Owner     = [ALL | Owner_id | Owner | valor^valor]. Filtro por Owner. OPCIONAL. Default=ALL.
 Affiliate = [ALL | Affiliate_id | Affiliate | valor^valor]. Filtro por Affiliate. OPCIONAL. Default=ALL.
 Filters   = [Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=No.
 Meta      = [Yes | No]. Incluye fila de metadatos de renderizado. OPCIONAL. Default=Yes.
 Debug     = [No | Yes | KeyValues]. Devuelve parámetros parseados. OPCIONAL. Default=No.

Parámetros ('[Key=Value[,...]]')

Ejemplos:
 call Report_Reversed_CPA('');
 call Report_Reversed_CPA('Month=2026-04');
 call Report_Reversed_CPA('Month=2026-04,Brand=Betsson,Publisher=10');
 call Report_Reversed_CPA('Month=LM,Filters=Yes');
 call Report_Reversed_CPA('Debug=KeyValues');

08.05.2026 v1.0 Primera versión operativa
08.05.2026 v1.1 Salida en matriz diaria por MS (columnas por día y total mensual)
*/

SET NAMES 'utf8mb4';

DROP PROCEDURE IF EXISTS Report_Reversed_CPA;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Reversed_CPA`(IN InputCommLine VARCHAR(250))
COMMENT 'v1.1 13.05.2026 Reporte de CPA reversadas por mes en matriz diaria por MS'
SQL SECURITY DEFINER
proc_label:BEGIN
    DECLARE v_Version VARCHAR(32);
    DECLARE v_InputCommLine VARCHAR(500);
    DECLARE v_Debug VARCHAR(20);
    DECLARE v_Filters VARCHAR(5);
    DECLARE v_Meta VARCHAR(5);
    DECLARE v_Month VARCHAR(20);
    DECLARE v_Brand VARCHAR(500);
    DECLARE v_Username VARCHAR(500);
    DECLARE v_Publisher VARCHAR(500);
    DECLARE v_Owner VARCHAR(500);
    DECLARE v_Affiliate VARCHAR(500);
    DECLARE v_MonthStart DATE;
    DECLARE v_MonthEnd DATE;
    DECLARE v_e INT;
    DECLARE v_c INT;
    DECLARE v_k VARCHAR(80);
    DECLARE v_v VARCHAR(250);
    DECLARE v_SqlCreateMatrix LONGTEXT;
    DECLARE v_SqlFinal LONGTEXT;
    DECLARE v_DayColumns LONGTEXT;
    DECLARE v_SettingDayColumns LONGTEXT;
    DECLARE v_DataDayColumns LONGTEXT;
    DECLARE v_TotalDayColumns LONGTEXT;
    DECLARE v_SelectDayColumns LONGTEXT;

    SET v_Version   = 'v1.1 13.05.2026';
    SET v_Debug     = 'NO';
    SET v_Filters   = 'NO';
    SET v_Meta      = 'YES';
    SET v_Month     = LEFT(CURDATE(),7);
    SET v_Brand     = 'ALL';
    SET v_Username  = 'ALL';
    SET v_Publisher = 'ALL';
    SET v_Owner     = 'ALL';
    SET v_Affiliate = 'ALL';

    SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');

        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            SET v_InputCommLine = '';
        ELSE
            SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
            SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
            SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

            IF LOWER(v_k) = 'month' THEN
                SET v_Month = LEFT(v_v, 7);
            ELSEIF LOWER(v_k) = 'brand' THEN
                SET v_Brand = v_v;
            ELSEIF LOWER(v_k) = 'username' THEN
                SET v_Username = v_v;
            ELSEIF LOWER(v_k) = 'username_id' THEN
                SET v_Username = v_v;
            ELSEIF LOWER(v_k) = 'publisher' THEN
                SET v_Publisher = v_v;
            ELSEIF LOWER(v_k) = 'publisher_id' THEN
                SET v_Publisher = v_v;
            ELSEIF LOWER(v_k) = 'operator' THEN
                SET v_Publisher = v_v;
            ELSEIF LOWER(v_k) = 'owner' THEN
                SET v_Owner = v_v;
            ELSEIF LOWER(v_k) = 'owner_id' THEN
                SET v_Owner = v_v;
            ELSEIF LOWER(v_k) = 'affiliate' THEN
                SET v_Affiliate = v_v;
            ELSEIF LOWER(v_k) = 'affiliate_id' THEN
                SET v_Affiliate = v_v;
            ELSEIF LOWER(v_k) = 'filters' THEN
                SET v_Filters = UPPER(v_v);
            ELSEIF LOWER(v_k) = 'meta' THEN
                SET v_Meta = UPPER(v_v);
            ELSEIF LOWER(v_k) = 'debug' THEN
                SET v_Debug = UPPER(v_v);
            END IF;
        END IF;
    END WHILE;

    IF UPPER(v_Month) = 'CM' THEN
        SET v_Month = LEFT(CURDATE(), 7);
    END IF;

    IF UPPER(v_Month) = 'LM' THEN
        SET v_Month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7);
    END IF;

    IF CHAR_LENGTH(v_Month) <> 7
       OR SUBSTRING(v_Month, 5, 1) <> '-'
       OR STR_TO_DATE(CONCAT(v_Month, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT CONCAT('ERROR: Month inválido [', IFNULL(v_Month, ''), ']. Formato esperado: YYYY-MM, CM o LM.') AS Mensaje;
        LEAVE proc_label;
    END IF;

    SET v_MonthStart = STR_TO_DATE(CONCAT(v_Month, '-01'), '%Y-%m-%d');
    IF v_Month = LEFT(CURDATE(), 7) THEN
        SET v_MonthEnd = CURDATE();
    ELSE
        SET v_MonthEnd = LAST_DAY(v_MonthStart);
    END IF;

    IF v_Debug IN ('YES', 'KEYVALUES') THEN
        SELECT 'Version' AS `Key`, v_Version AS `Value`
        UNION ALL SELECT 'Month', v_Month
        UNION ALL SELECT 'MonthStart', CAST(v_MonthStart AS CHAR)
        UNION ALL SELECT 'MonthEnd', CAST(v_MonthEnd AS CHAR)
        UNION ALL SELECT 'Brand', v_Brand
        UNION ALL SELECT 'Username', v_Username
        UNION ALL SELECT 'Publisher', v_Publisher
        UNION ALL SELECT 'Owner', v_Owner
        UNION ALL SELECT 'Affiliate', v_Affiliate
        UNION ALL SELECT 'Filters', v_Filters
        UNION ALL SELECT 'Meta', v_Meta
        UNION ALL SELECT 'Debug', v_Debug;
        LEAVE proc_label;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_rev_base;
    CREATE TEMPORARY TABLE tmp_rev_base AS
    SELECT
        LEFT(D.`Date`, 7) AS `Month`,
        DAY(D.`Date`) AS `DayNum`,
        IFNULL(P.`Advertiser_Name`, '') AS `Operator`,
        IFNULL(D.`Brand`, '') AS `Brand`,
        IFNULL(D.`Username`, '') AS `Account`,
        IFNULL(D.`Affiliate`, '') AS `Affiliate`,
        IFNULL(D.`MS_id`, 0) AS `MS_id`,
        IFNULL(D.`Tracker_Name`, '') AS `Tracker_Name`,
        IFNULL(D.`Tracker_id`, '') AS `Tracker_id`,
        SUM(IFNULL(D.`Qualified_players`, 0)) AS `CPA`
    FROM `Snapshot_day_by_day_fact1` D
    LEFT JOIN `campaign_publisher` P ON P.`id` = D.`Publisher_id`
    LEFT JOIN `account_account` AO ON AO.`id` = D.`Owner`
    WHERE D.`Date` BETWEEN v_MonthStart AND v_MonthEnd
      AND IFNULL(D.`Qualified_players`, 0) < 1
      AND IFNULL(D.`Origin`, '') = ''
      AND (UPPER(v_Brand) = 'ALL' OR FIND_IN_SET(D.`Brand`, REPLACE(v_Brand, '^', ',')) > 0)
      AND (UPPER(v_Username) = 'ALL'
           OR FIND_IN_SET(CAST(D.`Username_id` AS CHAR), REPLACE(v_Username, '^', ',')) > 0
           OR FIND_IN_SET(D.`Username`, REPLACE(v_Username, '^', ',')) > 0)
      AND (UPPER(v_Publisher) = 'ALL'
           OR FIND_IN_SET(CAST(D.`Publisher_id` AS CHAR), REPLACE(v_Publisher, '^', ',')) > 0
           OR FIND_IN_SET(IFNULL(P.`Advertiser_Name`, ''), REPLACE(v_Publisher, '^', ',')) > 0)
      AND (UPPER(v_Owner) = 'ALL'
           OR FIND_IN_SET(CAST(IFNULL(D.`Owner`, 0) AS CHAR), REPLACE(v_Owner, '^', ',')) > 0
           OR FIND_IN_SET(IFNULL(AO.`username`, ''), REPLACE(v_Owner, '^', ',')) > 0)
      AND (UPPER(v_Affiliate) = 'ALL'
           OR FIND_IN_SET(CAST(D.`Affiliate_id` AS CHAR), REPLACE(v_Affiliate, '^', ',')) > 0
           OR FIND_IN_SET(D.`Affiliate`, REPLACE(v_Affiliate, '^', ',')) > 0)
    GROUP BY
        LEFT(D.`Date`, 7),
        DAY(D.`Date`),
        IFNULL(P.`Advertiser_Name`, ''),
        IFNULL(D.`Brand`, ''),
        IFNULL(D.`Username`, ''),
        IFNULL(D.`Affiliate`, ''),
        IFNULL(D.`MS_id`, 0),
        IFNULL(D.`Tracker_Name`, ''),
        IFNULL(D.`Tracker_id`, '')
    HAVING `CPA` <> 0;

    IF v_Filters = 'YES' THEN
        DROP TEMPORARY TABLE IF EXISTS tmp_rev_base_operator;
        CREATE TEMPORARY TABLE tmp_rev_base_operator AS
        SELECT `Operator` FROM tmp_rev_base;

        DROP TEMPORARY TABLE IF EXISTS tmp_rev_base_brand;
        CREATE TEMPORARY TABLE tmp_rev_base_brand AS
        SELECT `Brand` FROM tmp_rev_base;

        DROP TEMPORARY TABLE IF EXISTS tmp_rev_base_account;
        CREATE TEMPORARY TABLE tmp_rev_base_account AS
        SELECT `Account` FROM tmp_rev_base;

        DROP TEMPORARY TABLE IF EXISTS tmp_rev_base_affiliate;
        CREATE TEMPORARY TABLE tmp_rev_base_affiliate AS
        SELECT `Affiliate` FROM tmp_rev_base;

        WITH RECURSIVE MonthFilter AS (
            SELECT DATE_FORMAT(CURDATE(), '%Y-%m-01') AS DateMonth
            UNION ALL
            SELECT DATE_SUB(DateMonth, INTERVAL 1 MONTH)
            FROM MonthFilter
            WHERE DATE_SUB(DateMonth, INTERVAL 1 MONTH) >= DATE_SUB(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 4 MONTH)
        )
        SELECT *
        FROM (
            SELECT '01' AS `Korder`, 'Month' AS `Key`, DATE_FORMAT(`DateMonth`, '%Y-%m') AS `Value`, 'Month' AS `CallKey`, DATE_FORMAT(`DateMonth`, '%Y-%m') AS `CallValue`, '' AS `Rows` FROM MonthFilter
            UNION ALL
            SELECT '10', 'Operator', `Operator`, 'Publisher', `Operator`, COUNT(*) AS `Rows` FROM tmp_rev_base_operator WHERE IFNULL(`Operator`, '') > '' GROUP BY `Operator`
            UNION ALL
            SELECT '20', 'Brand', `Brand`, 'Brand', `Brand`, COUNT(*) AS `Rows` FROM tmp_rev_base_brand WHERE IFNULL(`Brand`, '') > '' GROUP BY `Brand`
            UNION ALL
            SELECT '30', 'Account', `Account`, 'Username', `Account`, COUNT(*) AS `Rows` FROM tmp_rev_base_account WHERE IFNULL(`Account`, '') > '' GROUP BY `Account`
            UNION ALL
            SELECT '40', 'Affiliate', `Affiliate`, 'Affiliate', `Affiliate`, COUNT(*) AS `Rows` FROM tmp_rev_base_affiliate WHERE IFNULL(`Affiliate`, '') > '' GROUP BY `Affiliate`
        ) F
        ORDER BY `Korder`, CASE WHEN `CallKey` = 'Month' THEN `CallValue` ELSE '' END DESC, `Value` ASC;
        LEAVE proc_label;
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_days;
    CREATE TEMPORARY TABLE tmp_days (`DayNum` INT NOT NULL PRIMARY KEY);
    INSERT INTO tmp_days (`DayNum`)
    WITH RECURSIVE d AS (
        SELECT 1 AS DayNum
        UNION ALL
        SELECT DayNum + 1 FROM d WHERE DayNum < DAY(v_MonthEnd)
    )
    SELECT DayNum FROM d;

    SET SESSION group_concat_max_len = 1000000;

    SELECT GROUP_CONCAT(CONCAT('SUM(CASE WHEN DayNum=', `DayNum`, ' THEN CPA ELSE 0 END) AS `[', LPAD(`DayNum`, 2, '0'), ']`') ORDER BY `DayNum` SEPARATOR ',')
      INTO v_DayColumns
    FROM tmp_days;

    SELECT GROUP_CONCAT(CONCAT('''width=70px,right=true'' AS `[', LPAD(`DayNum`, 2, '0'), ']`') ORDER BY `DayNum` SEPARATOR ',')
      INTO v_SettingDayColumns
    FROM tmp_days;

    SELECT GROUP_CONCAT(CONCAT('CAST(`[', LPAD(`DayNum`, 2, '0'), ']` AS CHAR) AS `[', LPAD(`DayNum`, 2, '0'), ']`') ORDER BY `DayNum` SEPARATOR ',')
      INTO v_DataDayColumns
    FROM tmp_days;

    SELECT GROUP_CONCAT(CONCAT('CAST(SUM(`[', LPAD(`DayNum`, 2, '0'), ']`) AS CHAR) AS `[', LPAD(`DayNum`, 2, '0'), ']`') ORDER BY `DayNum` SEPARATOR ',')
      INTO v_TotalDayColumns
    FROM tmp_days;

    SELECT GROUP_CONCAT(CONCAT('`[', LPAD(`DayNum`, 2, '0'), ']`') ORDER BY `DayNum` SEPARATOR ',')
      INTO v_SelectDayColumns
    FROM tmp_days;

    DROP TEMPORARY TABLE IF EXISTS tmp_rev_matrix;

    SET v_SqlCreateMatrix = CONCAT(
        'CREATE TEMPORARY TABLE tmp_rev_matrix AS ',
        'SELECT `Month`, `Operator`, `Brand`, `Account`, `Affiliate`, `MS_id`, `Tracker_Name`, `Tracker_id`, ',
        v_DayColumns, ', ',
        'SUM(`CPA`) AS `Month_CPA` ',
        'FROM tmp_rev_base ',
        'GROUP BY `Month`, `Operator`, `Brand`, `Account`, `Affiliate`, `MS_id`, `Tracker_Name`, `Tracker_id` ',
        'HAVING SUM(`CPA`) <> 0;'
    );

    SET @stmt_create = v_SqlCreateMatrix;
    PREPARE stmt_create FROM @stmt_create;
    EXECUTE stmt_create;
    DEALLOCATE PREPARE stmt_create;

    DROP TEMPORARY TABLE IF EXISTS tmp_rev_matrix_total;
    CREATE TEMPORARY TABLE tmp_rev_matrix_total AS
    SELECT * FROM tmp_rev_matrix;

    SET v_SqlFinal = CONCAT(
        'SELECT `Meta`,`Month`,`Operator`,`Brand`,`Account`,`Affiliate`,`MS_id`,`Tracker_Name`,`Tracker_id`,`Month CPA`,', v_SelectDayColumns, ' ',
        'FROM (',
        '  SELECT 0 AS SortMeta, "" AS SortMonth, "total" AS `Meta`, "" AS `Month`, "-----" AS `Operator`, "-----" AS `Brand`, "-----" AS `Account`, "TOTAL" AS `Affiliate`, "-----" AS `MS_id`, "-----" AS `Tracker_Name`, "-----" AS `Tracker_id`, ',
            'CAST(IFNULL(SUM(`Month_CPA`),0) AS CHAR) AS `Month CPA`, ', v_TotalDayColumns, ' ',
        '  FROM tmp_rev_matrix_total ',
        '  UNION ALL ',
        '  SELECT 1 AS SortMeta
            ,"" AS SortMonth
            ,"setting"                 AS `Meta`
            ,"omit=yes"                AS `Month`
            ,"width=150px,tooltip=yes" AS `Operator`
            ,"width=120px,tooltip=yes" AS `Brand`
            ,"width=140px,tooltip=yes" AS `Account`
            ,"width=140px,tooltip=yes" AS `Affiliate`
            ,"width=90px,right=true"   AS `MS_id`
            ,"width=170px,tooltip=yes" AS `Tracker_Name`
            ,"omit=yes"                AS `Tracker_id`
            ,"width=90px,right=true"   AS `Month_CPA`
            , ', v_SettingDayColumns, ' ',
        '  FROM DUAL WHERE ', QUOTE(v_Meta), ' = "YES" ',
        '  UNION ALL ',
        '  SELECT 2 AS SortMeta, `Month` AS SortMonth, "data" AS `Meta`, `Month`, `Operator`, `Brand`, `Account`, `Affiliate`, CAST(`MS_id` AS CHAR) AS `MS_id`, `Tracker_Name`, `Tracker_id`, ',
            'CAST(`Month_CPA` AS CHAR) AS `Month_CPA`, ', v_DataDayColumns, ' ',
        '  FROM tmp_rev_matrix ',
        ') R ORDER BY SortMeta, SortMonth DESC, `Operator`, `Brand`, `Account`, `Affiliate`, CAST(`MS_id` AS UNSIGNED);'
    );

    IF v_Debug = 'YES' THEN
        SELECT v_SqlCreateMatrix AS SQL_CreateMatrix, v_SqlFinal AS SQL_Final;
    END IF;

    SET @stmt_final = v_SqlFinal;
    PREPARE stmt_final FROM @stmt_final;
    EXECUTE stmt_final;
    DEALLOCATE PREPARE stmt_final;
END$$
DELIMITER ;
