/*
PROCEDURE_referon_to_Snapshot_day_by_day_v1.0.sql

Descripción:
  Migra datos de gambling_day_by_day_referon a Snapshot_day_by_day para un mes,
  replicando Bot_Helper.gambling_referon_to_dbd y el post-proceso replace_username
  por cada publisher Referon presente en el mes.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  Data_Month = [YYYY-MM]. Mes a migrar. OPCIONAL. Default=mes calendario actual.
  Run = [No | Yes]. No=solo controles; Yes=DELETE+INSERT+replace_username. OPCIONAL. Default=No.
  Debug = [No | Yes | KeyValues]. OPCIONAL. Default=No.

Parámetros ('[Key=Value[,...]]')

Ejemplos:
  call referon_to_Snapshot_day_by_day('Data_Month=2026-05,Debug=KeyValues');
  call referon_to_Snapshot_day_by_day('Data_Month=2026-05,Run=No');
  call referon_to_Snapshot_day_by_day('Data_Month=2026-05,Run=Yes');

Publishers Referon (bots): 247Partners, 2rbo, Casombie, KNGPartners, MioMedia, 7Stars, WowPartners

22.05.2026 v1.0 Primera versión: carga Referon -> Snapshot_day_by_day + replace_username
*/

DROP PROCEDURE IF EXISTS referon_to_Snapshot_day_by_day;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `referon_to_Snapshot_day_by_day`(IN InputCommLine VARCHAR(250))
COMMENT 'Carga gambling_day_by_day_referon en Snapshot_day_by_day (mes) con replace_username'
SQL SECURITY DEFINER
proc_label:BEGIN
    DECLARE v_Version VARCHAR(32) DEFAULT 'v1.0 22.05.2026';
    DECLARE v_InputCommLine VARCHAR(300);
    DECLARE v_Debug VARCHAR(20) DEFAULT 'NO';
    DECLARE v_Run VARCHAR(5) DEFAULT 'NO';
    DECLARE v_Data_Month CHAR(7) DEFAULT DATE_FORMAT(CURDATE(), '%Y-%m');
    DECLARE v_DateFrom DATE;
    DECLARE v_DateTo DATE;
    DECLARE v_e INT DEFAULT 0;
    DECLARE v_c INT DEFAULT 0;
    DECLARE v_k VARCHAR(80) DEFAULT '';
    DECLARE v_v VARCHAR(250) DEFAULT '';
    DECLARE v_FilasOrigen INT DEFAULT 0;
    DECLARE v_FilasInsert INT DEFAULT 0;
    DECLARE v_InTransaction TINYINT DEFAULT 0;
    DECLARE v_Publisher_id INT DEFAULT 0;
    DECLARE v_Publisher_name VARCHAR(255) DEFAULT '';
    DECLARE v_done INT DEFAULT 0;

    DECLARE cur_publishers CURSOR FOR
        SELECT DISTINCT P.id, P.Advertiser_Name
        FROM gambling_day_by_day_referon R
        INNER JOIN campaign_username U ON U.id = R.Username_id
        INNER JOIN campaign_publisher P ON P.id = U.Publisher_id
        WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
          AND R.Username_id IS NOT NULL;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        IF v_InTransaction = 1 THEN
            ROLLBACK;
            SET v_InTransaction = 0;
        END IF;
        RESIGNAL;
    END;

    SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');
        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE proc_label;
        END IF;
        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = UPPER(TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1))));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'debug' THEN
            SET v_Debug = v_v;
        ELSEIF LOWER(v_k) = 'run' THEN
            SET v_Run = v_v;
        ELSEIF LOWER(v_k) = 'data_month' THEN
            SET v_Data_Month = LEFT(v_v, 7);
        END IF;
    END WHILE;

    IF LENGTH(v_Data_Month) <> 7 OR STR_TO_DATE(CONCAT(v_Data_Month, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT 'data' AS Meta, 'Data_Month inválido. Use formato YYYY-MM.' AS Mensaje;
        LEAVE proc_label;
    END IF;

    SET v_DateFrom = STR_TO_DATE(CONCAT(v_Data_Month, '-01'), '%Y-%m-%d');
    SET v_DateTo = LAST_DAY(v_DateFrom);

    IF v_Debug = 'KEYVALUES' THEN
        SELECT v_Version AS Version, v_Data_Month AS Data_Month, v_DateFrom AS DateFrom,
               v_DateTo AS DateTo, v_Run AS Run, v_Debug AS Debug;
        LEAVE proc_label;
    END IF;

    SELECT COUNT(*) INTO v_FilasOrigen
    FROM gambling_day_by_day_referon R
    WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
      AND R.Username_id IS NOT NULL;

    SELECT 'data' AS Meta, v_Data_Month AS Data_Month, v_DateFrom AS Desde, v_DateTo AS Hasta,
           v_FilasOrigen AS Filas_referon, v_Run AS Run;

    SELECT 'gambling_day_by_day_referon' AS Tabla,
           COUNT(*) AS Filas,
           COUNT(DISTINCT Username_id) AS Cuentas,
           MIN(`Date`) AS MinDate,
           MAX(`Date`) AS MaxDate
    FROM gambling_day_by_day_referon
    WHERE `Date` BETWEEN v_DateFrom AND v_DateTo;

    SELECT 'Snapshot_day_by_day (antes)' AS Tabla, COUNT(*) AS Filas
    FROM Snapshot_day_by_day S
    WHERE S.`Date` BETWEEN v_DateFrom AND v_DateTo
      AND S.Username IN (
            SELECT DISTINCT CAST(R.Username_id AS CHAR)
            FROM gambling_day_by_day_referon R
            WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
              AND R.Username_id IS NOT NULL
      );

    IF v_FilasOrigen = 0 THEN
        SELECT 'data' AS Meta, CONCAT('Sin datos en gambling_day_by_day_referon para ', v_Data_Month) AS Mensaje;
        LEAVE proc_label;
    END IF;

    IF v_Run <> 'YES' THEN
        SELECT 'data' AS Meta, 'Modo preview (Run=No). No se modificó Snapshot_day_by_day.' AS Mensaje;
        LEAVE proc_label;
    END IF;

    START TRANSACTION;
    SET v_InTransaction = 1;

    DELETE S
    FROM Snapshot_day_by_day S
    WHERE S.`Date` BETWEEN v_DateFrom AND v_DateTo
      AND S.Username IN (
            SELECT DISTINCT CAST(R.Username_id AS CHAR)
            FROM gambling_day_by_day_referon R
            WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
              AND R.Username_id IS NOT NULL
      );

    INSERT INTO Snapshot_day_by_day (
        `Date`,
        `Username`,
        `Brand`,
        `Tracker_ID`,
        `Tracker_Name`,
        `Clicks`,
        `Views`,
        `Signups`,
        `First_Time_Deposit`,
        `Deposits`,
        `Qualified_Players`,
        `Net_Revenue`,
        `Product`,
        `Hour_Update`
    )
    SELECT
        R.`Date`,
        CAST(R.Username_id AS CHAR) AS `Username`,
        REPLACE(R.Brand_Name, ' Wow', '') AS `Brand`,
        CAST(R.Marketing_Source_ID AS CHAR) AS `Tracker_ID`,
        R.Marketing_Source AS `Tracker_Name`,
        IFNULL(CAST(NULLIF(TRIM(R.Click_Count), '') AS SIGNED), 0) AS `Clicks`,
        IFNULL(CAST(NULLIF(TRIM(R.Banner_View_Count), '') AS SIGNED), 0) AS `Views`,
        IFNULL(R.Reg_Count, 0) AS `Signups`,
        IFNULL(R.FTD_Count, 0) AS `First_Time_Deposit`,
        IFNULL(CAST(R.Count_of_deposits AS DECIMAL(12,2)), 0.00) AS `Deposits`,
        IFNULL(R.CPA_count, 0) AS `Qualified_Players`,
        IFNULL(CAST(R.NGR AS DECIMAL(12,2)), 0.00) AS `Net_Revenue`,
        R.Rewarding_Plan AS `Product`,
        COALESCE(R.Hour_Update, CURRENT_TIMESTAMP) AS `Hour_Update`
    FROM gambling_day_by_day_referon R
    WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
      AND R.Username_id IS NOT NULL;

    SET v_FilasInsert = ROW_COUNT();

    SET v_done = 0;
    OPEN cur_publishers;
    pub_loop: LOOP
        FETCH cur_publishers INTO v_Publisher_id, v_Publisher_name;
        IF v_done = 1 THEN
            LEAVE pub_loop;
        END IF;

        UPDATE Snapshot_day_by_day T
        LEFT JOIN campaign_advertiser A ON A.Advertiser_Name = T.Brand
        LEFT JOIN campaign_username U ON U.id = T.Username
        LEFT JOIN campaign_username U1
            ON U1.Username = U.Username
           AND U1.Advertiser_id = A.id
           AND U1.Publisher_id = v_Publisher_id
        SET T.Username = U1.id
        WHERE U.Publisher_id = v_Publisher_id
          AND U1.id IS NOT NULL
          AND U1.id <> T.Username
          AND T.`Date` BETWEEN v_DateFrom AND v_DateTo;

        UPDATE Snapshot_day_by_day T
        LEFT JOIN campaign_advertiser A ON A.Advertiser_Name = T.Brand
        LEFT JOIN campaign_username U ON U.id = T.Username
        LEFT JOIN campaign_username U1
            ON U1.Username = U.Username
           AND U1.Advertiser_id = A.id
           AND U1.Publisher_id = v_Publisher_id
        SET T.Username = U1.id
        WHERE U.Publisher_id = v_Publisher_id
          AND U1.id IS NOT NULL
          AND U1.id <> T.Username
          AND T.`Date` BETWEEN v_DateFrom AND v_DateTo;
    END LOOP;
    CLOSE cur_publishers;

    COMMIT;
    SET v_InTransaction = 0;

    SELECT 'data' AS Meta,
           CONCAT('OK. Insertadas ', v_FilasInsert, ' filas. replace_username aplicado por publisher.') AS Mensaje;

    SELECT 'Snapshot_day_by_day (después)' AS Tabla,
           COUNT(*) AS Filas,
           SUM(Qualified_Players) AS CPA_Total,
           ROUND(SUM(Net_Revenue), 2) AS NR_Total
    FROM Snapshot_day_by_day S
    WHERE S.`Date` BETWEEN v_DateFrom AND v_DateTo
      AND S.Username IN (
            SELECT DISTINCT CAST(R.Username_id AS CHAR)
            FROM gambling_day_by_day_referon R
            WHERE R.`Date` BETWEEN v_DateFrom AND v_DateTo
              AND R.Username_id IS NOT NULL
      );

END$$
DELIMITER ;
