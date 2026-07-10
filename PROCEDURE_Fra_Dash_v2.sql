/*
PROCEDURE_Fra_Dash_v2.sql

Descripción:
  Responde a dos preguntas de negocio sobre el período Month_from..mes corriente:
  (1) ¿Cuánto beneficio representa un Publisher_id?  → Mode=Publisher.
  (2) ¿Cuánto beneficio aporta un Afiliado?         → Mode=Affiliate, con matriz por Publisher.
      Detalle por par Publisher/Afiliado            → Mode=Detail.

  Beneficio publisher = net_Total_comm gestor - comisiones pagadas (incl. ajustes manuales
  con IncludeInProfitCalculation=1) agregadas por Publisher.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas.
  Cada par Key=Value debe ir seguido de una COMA.
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string.

Keys:
  Month_from = [YYYY-MM]. Inicio del período (inclusive). OPCIONAL. Default=mes corriente - 11 meses.
  Mode = [Publisher | Affiliate | Detail]. OPCIONAL. Default=Publisher.
         Publisher: una fila por Publisher_id; Beneficio = beneficio del client.
         Affiliate: matriz por Affiliate_id y Publisher.
         Detail: fila por par Publisher_id/Affiliate_id.
  SubMode = [Amount | Percentage]. OPCIONAL. Default=Amount. Solo aplica a Mode=Affiliate.
            Amount muestra importes/valores absolutos; Percentage muestra participación por Publisher.
  Data_Type = [CPA | net_CPA_Val | net_RS_Val | net_Total_comm | Profit]. OPCIONAL. Default=Profit.
             Solo aplica a Mode=Affiliate.
  Debug = [No | Yes | KeyValues]. OPCIONAL. Default=No.
  Filters = [No | Yes]. OPCIONAL. Default=No. Si Yes: resultset con Korder, Key, Value, CallKey, CallValue, Rows.
  Meta = [No | Yes]. OPCIONAL. Default=Yes.

Parámetros ('[Key=Value[,...]]')

Ejemplos:
  CALL Fra_Dash('');  -- últimos 12 meses hasta el mes corriente
  CALL Fra_Dash('Month_from=2025-06,Mode=Publisher,Meta=Yes');
  CALL Fra_Dash('Month_from=2025-06,Mode=Affiliate,Data_Type=Profit,SubMode=Amount');
  CALL Fra_Dash('Month_from=2025-06,Mode=Affiliate,Data_Type=net_Total_comm,SubMode=Percentage');
  CALL Fra_Dash('Mode=Detail,Month_from=2025-01');
  CALL Fra_Dash('Filters=Yes');

Notas:
  - Nombre de publisher: Advertiser_Name en campaign_publisher.
  - Ajustes manuales: Amount_Credit con IncludeInProfitCalculation=1 (y Status 1,2), repartidos
    entre publishers del afiliado en proporción a net_Total_comm por par.
  - Mode=Affiliate / Data_Type=Profit usa atribución proporcional:
    pago_a_p / T_p * (G_p - T_p). La suma por afiliado coincide con el beneficio aportado.
  - Publisher_id en comisiones afiliado: COALESCE(campaign_username.Publisher_id por Account_id,
    campaign_advertiser.Publisher_id por Advertiser_id).

03.05.2026 v1.0 Creación según especificación Fra_Dash
03.05.2026 v1.0.1 Publisher_id afiliado vía campaign_username; redondeo monetario
03.05.2026 v1.0.2 DECLARE sin DEFAULT; SET de inicialización
03.05.2026 v1.1.0 Modos Publisher / Affiliate / Detail; columna Data_Type
03.05.2026 v1.1.1 Detail: Publisher_id en Meta; COALESCE publisher vía advertiser
03.05.2026 v1.1.2 Filters: Korder, Key, Value, CallKey, CallValue, Rows
03.05.2026 v1.1.3 Default Month_from/Month_until = enero y diciembre del año corriente
04.05.2026 v1.1.4 Meta: Data_Type/Pct_Data_Type y Publisher_id visible en Detail
04.05.2026 v2.0.0 Mode=Affiliate como matriz por Publisher con SubMode y DateType
04.05.2026 v2.1.0 Defaults a últimos 12 meses y eliminación de aliases en parámetros
04.05.2026 v2.1.1 SubMode=Amount para valores absolutos
04.05.2026 v2.1.2 Data_Type reemplaza DateType
04.05.2026 v2.1.3 Mode=Publisher omite columna Affiliate en Meta
04.05.2026 v2.1.4 Filters: Month_from desde período inicial hasta mes corriente y opción Last_Year
04.05.2026 v2.1.5 Eliminado Month_until como parámetro de entrada
04.05.2026 v2.1.6 Filters: SubMode solo visible en Mode Publisher o Affiliate
04.05.2026 v2.1.7 Filters: Data_Type solo visible en Mode Affiliate
04.05.2026 v2.1.8 Fila total antes que filas data
*/

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

DROP PROCEDURE IF EXISTS Fra_Dash;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Fra_Dash`(IN InputCommLine VARCHAR(250))
COMMENT 'Fra_Dash: beneficio por Publisher y matriz de aporte por Afiliado; período configurable'
SQL SECURITY DEFINER
fra_dash_label:BEGIN

    DECLARE v_Version VARCHAR(32) DEFAULT 'v2.1.8 04.05.2026';
    DECLARE v_InputCommLine VARCHAR(400);
    DECLARE v_Month_from CHAR(7);
    DECLARE v_Month_until CHAR(7);
    DECLARE v_Mode VARCHAR(20);
    DECLARE v_SubMode VARCHAR(20);
    DECLARE v_Data_Type VARCHAR(30);
    DECLARE v_Debug VARCHAR(20);
    DECLARE v_Filters VARCHAR(5);
    DECLARE v_Meta VARCHAR(5);
    DECLARE v_e INT;
    DECLARE v_c INT;
    DECLARE v_k VARCHAR(80);
    DECLARE v_v VARCHAR(250);
    DECLARE v_stmt LONGTEXT;
    DECLARE v_Pivot_cols LONGTEXT;
    DECLARE v_Pivot_total_cols LONGTEXT;
    DECLARE v_Setting_cols LONGTEXT;

    SET v_Version = 'v2.1.8 04.05.2026';
    SET v_Month_from = LEFT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH), 7);
    SET v_Month_until = LEFT(CURDATE(), 7);
    SET v_Mode = 'PUBLISHER';
    SET v_SubMode = 'AMOUNT';
    SET v_Data_Type = 'PROFIT';
    SET v_Debug = 'NO';
    SET v_Filters = 'NO';
    SET v_Meta = 'YES';
    SET v_e = 0;
    SET v_c = 0;
    SET v_k = '';
    SET v_v = '';
    SET v_stmt = '';
    SET v_Pivot_cols = '';
    SET v_Pivot_total_cols = '';
    SET v_Setting_cols = '';

    SET v_InputCommLine = IFNULL(InputCommLine, '');
    SET v_InputCommLine = CONCAT(v_InputCommLine, ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    parse_loop:WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');
        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE parse_loop;
        END IF;
        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'month_from' THEN
            IF LOWER(TRIM(v_v)) = 'last_year' THEN
                SET v_Month_from = LEFT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH), 7);
            ELSE
                SET v_Month_from = UPPER(LEFT(v_v, 7));
            END IF;
        ELSEIF LOWER(v_k) = 'mode' THEN
            IF LOWER(TRIM(v_v)) = 'detail' THEN
                SET v_Mode = 'DETAIL';
            ELSEIF LOWER(TRIM(v_v)) = 'affiliate' THEN
                SET v_Mode = 'AFFILIATE';
            ELSEIF LOWER(TRIM(v_v)) = 'publisher' THEN
                SET v_Mode = 'PUBLISHER';
            ELSE
                SET v_Mode = 'PUBLISHER';
            END IF;
        ELSEIF LOWER(v_k) = 'submode' THEN
            IF LOWER(TRIM(v_v)) = 'percentage' THEN
                SET v_SubMode = 'PERCENTAGE';
            ELSE
                SET v_SubMode = 'AMOUNT';
            END IF;
        ELSEIF LOWER(v_k) = 'data_type' THEN
            IF LOWER(TRIM(v_v)) = 'cpa' THEN
                SET v_Data_Type = 'CPA';
            ELSEIF LOWER(TRIM(v_v)) = 'net_cpa_val' THEN
                SET v_Data_Type = 'NET_CPA_VAL';
            ELSEIF LOWER(TRIM(v_v)) = 'net_rs_val' THEN
                SET v_Data_Type = 'NET_RS_VAL';
            ELSEIF LOWER(TRIM(v_v)) = 'net_total_comm' THEN
                SET v_Data_Type = 'NET_TOTAL_COMM';
            ELSE
                SET v_Data_Type = 'PROFIT';
            END IF;
        ELSEIF LOWER(v_k) = 'debug' THEN
            SET v_Debug = UPPER(TRIM(v_v));
        ELSEIF LOWER(v_k) = 'filters' THEN
            SET v_Filters = UPPER(TRIM(v_v));
        ELSEIF LOWER(v_k) = 'meta' THEN
            SET v_Meta = UPPER(TRIM(v_v));
        END IF;
    END WHILE;

    IF v_Month_from NOT REGEXP '^[0-9]{4}-(0[1-9]|1[0-2])$'
       OR STR_TO_DATE(CONCAT(v_Month_from, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT CONCAT('ERROR: Month_from inválido [', v_Month_from, ']. Use YYYY-MM.') AS Mensaje;
        LEAVE fra_dash_label;
    END IF;

    IF v_Month_from > v_Month_until THEN
        SELECT 'ERROR: Month_from no puede ser mayor que el mes corriente.' AS Mensaje;
        LEAVE fra_dash_label;
    END IF;

    IF v_Debug = 'KEYVALUES' THEN
        SELECT 'Month_from' AS `Key`, v_Month_from AS `Value`
        UNION ALL SELECT 'Mode', v_Mode
        UNION ALL SELECT 'SubMode', v_SubMode
        UNION ALL SELECT 'Data_Type', v_Data_Type
        UNION ALL SELECT 'Debug', v_Debug
        UNION ALL SELECT 'Filters', v_Filters
        UNION ALL SELECT 'Meta', v_Meta
        UNION ALL SELECT 'Version', v_Version;
        LEAVE fra_dash_label;
    END IF;

    IF v_Filters = 'YES' THEN
        WITH RECURSIVE month_from_options AS (
            SELECT STR_TO_DATE(CONCAT(v_Month_from, '-01'), '%Y-%m-%d') AS month_date
            FROM DUAL
            WHERE v_Month_from <= LEFT(CURDATE(), 7)
            UNION ALL
            SELECT DATE_ADD(month_date, INTERVAL 1 MONTH)
            FROM month_from_options
            WHERE month_date < STR_TO_DATE(CONCAT(LEFT(CURDATE(), 7), '-01'), '%Y-%m-%d')
        )
        SELECT u.Korder, u.`Key`, u.`Value`, u.CallKey, u.CallValue, u.`Rows`
        FROM (
            SELECT '01' AS Korder, 'Month_from' AS `Key`, 'Last_Year' AS `Value`, 'Month_from' AS CallKey, 'Last_Year' AS CallValue, '' AS `Rows` FROM DUAL
            UNION ALL
            SELECT '01' AS Korder, 'Month_from' AS `Key`, DATE_FORMAT(month_date, '%Y-%m') AS `Value`, 'Month_from' AS CallKey, DATE_FORMAT(month_date, '%Y-%m') AS CallValue, '' AS `Rows`
            FROM month_from_options
            UNION ALL
            SELECT '03' AS Korder, 'Mode' AS `Key`, 'Operators' AS `Value`, 'Mode' AS CallKey, 'Publisher' AS CallValue, '' AS `Rows` FROM DUAL
            UNION ALL
            SELECT '04' AS Korder, 'Mode' AS `Key`, 'Affiliates' AS `Value`, 'Mode' AS CallKey, 'Affiliate' AS CallValue, '' AS `Rows` FROM DUAL
            UNION ALL
            SELECT '05' AS Korder, 'Mode' AS `Key`, 'Aff Detail' AS `Value`, 'Mode' AS CallKey, 'Detail' AS CallValue, '' AS `Rows` FROM DUAL
            UNION ALL
            SELECT '06' AS Korder, 'SubMode' AS `Key`, 'Absolute Amount' AS `Value`, 'SubMode' AS CallKey, 'Amount' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode IN ('AFFILIATE') and v_SubMode!='Amount'
            UNION ALL
            SELECT '07' AS Korder, 'SubMode' AS `Key`, 'Percentage' AS `Value`, 'SubMode' AS CallKey, 'Percentage' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode IN ('AFFILIATE')
            UNION ALL
            SELECT '08' AS Korder, 'Data_Type' AS `Key`, 'Profit' AS `Value`, 'Data_Type' AS CallKey, 'Profit' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode = 'AFFILIATE'
            UNION ALL
            SELECT '09' AS Korder, 'Data_Type' AS `Key`, 'CPA' AS `Value`, 'Data_Type' AS CallKey, 'CPA' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode = 'AFFILIATE'
            UNION ALL
            SELECT '10' AS Korder, 'Data_Type' AS `Key`, 'CPA Value' AS `Value`, 'Data_Type' AS CallKey, 'net_CPA_Val' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode = 'AFFILIATE'
            UNION ALL
            SELECT '11' AS Korder, 'Data_Type' AS `Key`, 'RS Value' AS `Value`, 'Data_Type' AS CallKey, 'net_RS_Val' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode = 'AFFILIATE'
            UNION ALL
            SELECT '12' AS Korder, 'Data_Type' AS `Key`, 'Total Commission' AS `Value`, 'Data_Type' AS CallKey, 'net_Total_comm' AS CallValue, '' AS `Rows` FROM DUAL
            WHERE v_Mode = 'AFFILIATE'
        ) u
        ORDER BY 1 ASC, 3 DESC;
        LEAVE fra_dash_label;
    END IF;

    SET SESSION group_concat_max_len = 200000;

    IF v_Mode = 'AFFILIATE' THEN
        SELECT
            IFNULL(GROUP_CONCAT(CONCAT(
                'ROUND(SUM(CASE WHEN mv.Publisher_id = ', p.Publisher_id,
                ' THEN mv.cell_value ELSE 0 END), 2) AS `',
                REPLACE(p.Publisher_name, '`', '``'), '`'
            ) ORDER BY p.Publisher_name, p.Publisher_id SEPARATOR ',
    '), '')
        INTO v_Pivot_cols
        FROM (
            SELECT DISTINCT
                COALESCE(u.Publisher_id, ad.Publisher_id, 0) AS Publisher_id,
                TRIM(cp.Advertiser_Name) AS Publisher_name
            FROM monthly_comms_affiliate_v5 a
            LEFT JOIN campaign_username u ON u.id = a.Account_id
            LEFT JOIN campaign_advertiser ad ON ad.id = a.Advertiser_id
            LEFT JOIN campaign_publisher cp ON cp.id = COALESCE(u.Publisher_id, ad.Publisher_id, 0)
            WHERE a.`Month` BETWEEN v_Month_from AND v_Month_until
        ) p;

        SELECT
            IFNULL(GROUP_CONCAT(CONCAT(
                'ROUND(SUM(CASE WHEN mv.Publisher_id = ', p.Publisher_id,
                ' THEN mv.cell_value ELSE 0 END), 2) AS `',
                REPLACE(p.Publisher_name, '`', '``'), '`'
            ) ORDER BY p.Publisher_name, p.Publisher_id SEPARATOR ',
    '), '')
        INTO v_Pivot_total_cols
        FROM (
            SELECT DISTINCT
                COALESCE(u.Publisher_id, ad.Publisher_id, 0) AS Publisher_id,
                TRIM(cp.Advertiser_Name) AS Publisher_name
            FROM monthly_comms_affiliate_v5 a
            LEFT JOIN campaign_username u ON u.id = a.Account_id
            LEFT JOIN campaign_advertiser ad ON ad.id = a.Advertiser_id
            LEFT JOIN campaign_publisher cp ON cp.id = COALESCE(u.Publisher_id, ad.Publisher_id, 0)
            WHERE a.`Month` BETWEEN v_Month_from AND v_Month_until
        ) p;

        SELECT
            IFNULL(GROUP_CONCAT(CONCAT(
                '"width=110px,right=true,sortable=yes" AS `',
                REPLACE(p.Publisher_name, '`', '``'), '`'
            ) ORDER BY p.Publisher_name, p.Publisher_id SEPARATOR ',
    '), '')
        INTO v_Setting_cols
        FROM (
            SELECT DISTINCT
                COALESCE(u.Publisher_id, ad.Publisher_id, 0) AS Publisher_id,
                TRIM(cp.Advertiser_Name) AS Publisher_name
            FROM monthly_comms_affiliate_v5 a
            LEFT JOIN campaign_username u ON u.id = a.Account_id
            LEFT JOIN campaign_advertiser ad ON ad.id = a.Advertiser_id
            LEFT JOIN campaign_publisher cp ON cp.id = COALESCE(u.Publisher_id, ad.Publisher_id, 0)
            WHERE a.`Month` BETWEEN v_Month_from AND v_Month_until
        ) p;

        SET v_stmt = CONCAT(
'WITH
params AS (
  SELECT "', v_Month_from, '" AS mf, "', v_Month_until, '" AS mu,
         "', v_SubMode, '" AS submode_flag,
         "', v_Data_Type, '" AS data_type_flag
),
ges AS (
  SELECT g.Publisher_id,
         SUM(IFNULL(g.net_Total_comm, 0)) AS net_total_comm_ges
  FROM monthly_comms_gestor_v5 g
  CROSS JOIN params p
  WHERE g.`Month` BETWEEN p.mf AND p.mu
  GROUP BY g.Publisher_id
),
comm_pa AS (
  SELECT COALESCE(u.Publisher_id, ad.Publisher_id, 0) AS Publisher_id,
         a.Affiliate_id,
         SUM(IFNULL(a.CPA, 0)) AS cpa_aff,
         SUM(IFNULL(a.net_CPA_Val, 0)) AS net_cpa_val_aff,
         SUM(IFNULL(a.net_RS_Val, 0)) AS net_rs_val_aff,
         SUM(IFNULL(a.net_Total_comm, 0)) AS net_total_comm_aff
  FROM monthly_comms_affiliate_v5 a
  LEFT JOIN campaign_username u ON u.id = a.Account_id
  LEFT JOIN campaign_advertiser ad ON ad.id = a.Advertiser_id
  CROSS JOIN params p
  WHERE a.`Month` BETWEEN p.mf AND p.mu
  GROUP BY COALESCE(u.Publisher_id, ad.Publisher_id, 0), a.Affiliate_id
),
comm_a_tot AS (
  SELECT Affiliate_id,
         SUM(net_total_comm_aff) AS tot_net_aff
  FROM comm_pa
  GROUP BY Affiliate_id
),
aff_pub_cnt AS (
  SELECT Affiliate_id, COUNT(DISTINCT Publisher_id) AS pub_cnt
  FROM comm_pa
  GROUP BY Affiliate_id
),
man AS (
  SELECT m.Affiliate_id,
         SUM(IFNULL(m.Amount_Credit, 0)) AS adj_raw
  FROM account_manual_adjustments m
  CROSS JOIN params p
  WHERE IFNULL(m.IncludeInProfitCalculation, 0) = 1
    AND IFNULL(m.Status, 0) IN (1, 2)
    AND LEFT(m.`Date`, 7) BETWEEN p.mf AND p.mu
  GROUP BY m.Affiliate_id
),
comm_pa_adj AS (
  SELECT
    c.Publisher_id,
    c.Affiliate_id,
    c.cpa_aff,
    c.net_cpa_val_aff,
    c.net_rs_val_aff,
    c.net_total_comm_aff,
    ROUND(c.net_total_comm_aff + IFNULL(m.adj_raw, 0) * (
      CASE
        WHEN IFNULL(t.tot_net_aff, 0) <> 0 THEN c.net_total_comm_aff / t.tot_net_aff
        WHEN IFNULL(apc.pub_cnt, 0) > 0 THEN 1.0 / apc.pub_cnt
        ELSE 0
      END
    ), 2) AS net_total_comm_aff_incl_adj
  FROM comm_pa c
  LEFT JOIN comm_a_tot t ON t.Affiliate_id = c.Affiliate_id
  LEFT JOIN man m ON m.Affiliate_id = c.Affiliate_id
  LEFT JOIN aff_pub_cnt apc ON apc.Affiliate_id = c.Affiliate_id
),
pub_paid_tot AS (
  SELECT Publisher_id,
         SUM(net_total_comm_aff_incl_adj) AS t_pay_pub
  FROM comm_pa_adj
  GROUP BY Publisher_id
),
matrix_values AS (
  SELECT
    x.Publisher_id,
    x.Affiliate_id,
    IFNULL(TRIM(af.username), "") AS Affiliate_username,
    CASE p.data_type_flag
      WHEN "CPA" THEN x.cpa_aff
      WHEN "NET_CPA_VAL" THEN x.net_cpa_val_aff
      WHEN "NET_RS_VAL" THEN x.net_rs_val_aff
      WHEN "NET_TOTAL_COMM" THEN x.net_total_comm_aff_incl_adj
      ELSE ROUND(CASE
        WHEN IFNULL(pt.t_pay_pub, 0) > 0
        THEN x.net_total_comm_aff_incl_adj * (IFNULL(g.net_total_comm_ges, 0) - pt.t_pay_pub) / pt.t_pay_pub
        ELSE 0
      END, 2)
    END AS metric_value
  FROM comm_pa_adj x
  LEFT JOIN account_account af ON af.id = x.Affiliate_id
  LEFT JOIN ges g ON g.Publisher_id = x.Publisher_id
  LEFT JOIN pub_paid_tot pt ON pt.Publisher_id = x.Publisher_id
  CROSS JOIN params p
),
publisher_totals AS (
  SELECT Publisher_id, SUM(metric_value) AS total_pub
  FROM matrix_values
  GROUP BY Publisher_id
),
global_tot AS (
  SELECT SUM(metric_value) AS global_total
  FROM matrix_values
),
matrix_ready AS (
  SELECT
    mv.Publisher_id,
    mv.Affiliate_id,
    mv.Affiliate_username,
    mv.metric_value,
    CASE
      WHEN p.submode_flag = "PERCENTAGE"
      THEN ROUND(100 * mv.metric_value / NULLIF(pt.total_pub, 0), 2)
      ELSE ROUND(mv.metric_value, 2)
    END AS cell_value
  FROM matrix_values mv
  LEFT JOIN publisher_totals pt ON pt.Publisher_id = mv.Publisher_id
  CROSS JOIN params p
)
SELECT * FROM (
',
IF(v_Meta = 'YES', CONCAT(
'SELECT "setting" AS Meta,
    "width=80px,right=true,sortable=yes" AS `Affiliate ID`,
    "width=220px,sortable=yes" AS Affiliate,
    "width=110px,right=true,sortable=yes" AS `Total`',
IF(v_Setting_cols <> '', CONCAT(',
    ', v_Setting_cols), ''),
'
FROM DUAL
UNION ALL
'), ''),
'SELECT
    "data" AS Meta,
    mv.Affiliate_id,
    mv.Affiliate_username AS Affiliate,
    CASE
      WHEN p.submode_flag = "PERCENTAGE"
      THEN ROUND(100 * SUM(mv.metric_value) / NULLIF(gt.global_total, 0), 2)
      ELSE ROUND(SUM(mv.metric_value), 2)
    END AS `Total`',
IF(v_Pivot_cols <> '', CONCAT(',
    ', v_Pivot_cols), ''),
'
FROM matrix_ready mv
CROSS JOIN params p
CROSS JOIN global_tot gt
GROUP BY mv.Affiliate_id, mv.Affiliate_username, p.submode_flag, gt.global_total
',
IF(v_Meta = 'YES', CONCAT(
'UNION ALL
SELECT
    "total" AS Meta,
    NULL AS Affiliate_id,
    "TOTAL" AS Affiliate,
    CASE
      WHEN COUNT(mv.Affiliate_id) = 0 THEN 0
      WHEN p.submode_flag = "PERCENTAGE" THEN 100
      ELSE ROUND(IFNULL(SUM(mv.metric_value), 0), 2)
    END AS `Total`',
IF(v_Pivot_total_cols <> '', CONCAT(',
    ', v_Pivot_total_cols), ''),
'
FROM params p
LEFT JOIN matrix_ready mv ON 1 = 1
GROUP BY p.submode_flag
'), ''),
') z
ORDER BY
  CASE z.Meta WHEN "setting" THEN 0 WHEN "total" THEN 1 ELSE 2 END,
  CASE WHEN z.Meta = "data" THEN CAST(z.`Total` AS DECIMAL(20, 4)) END DESC;');

    ELSE
        SET v_stmt = CONCAT(
'WITH
params AS (
  SELECT "', v_Month_from, '" AS mf, "', v_Month_until, '" AS mu,
         "', v_Mode, '" AS mode_flag
),
ges AS (
  SELECT g.Publisher_id,
         SUM(IFNULL(g.CPA, 0)) AS cpa_ges,
         SUM(IFNULL(g.net_CPA_Val, 0)) AS net_cpa_val_ges,
         SUM(IFNULL(g.net_RS_Val, 0)) AS net_rs_val_ges,
         SUM(IFNULL(g.net_Total_comm, 0)) AS net_total_comm_ges
  FROM monthly_comms_gestor_v5 g
  CROSS JOIN params p
  WHERE g.`Month` BETWEEN p.mf AND p.mu
  GROUP BY g.Publisher_id
),
comm_pa AS (
  SELECT COALESCE(u.Publisher_id, ad.Publisher_id, 0) AS Publisher_id,
         a.Affiliate_id,
         SUM(IFNULL(a.CPA, 0)) AS cpa_aff,
         SUM(IFNULL(a.net_CPA_Val, 0)) AS net_cpa_val_aff,
         SUM(IFNULL(a.net_RS_Val, 0)) AS net_rs_val_aff,
         SUM(IFNULL(a.net_Total_comm, 0)) AS net_total_comm_aff
  FROM monthly_comms_affiliate_v5 a
  LEFT JOIN campaign_username u ON u.id = a.Account_id
  LEFT JOIN campaign_advertiser ad ON ad.id = a.Advertiser_id
  CROSS JOIN params p
  WHERE a.`Month` BETWEEN p.mf AND p.mu
  GROUP BY COALESCE(u.Publisher_id, ad.Publisher_id, 0), a.Affiliate_id
),
comm_a_tot AS (
  SELECT a.Affiliate_id,
         SUM(IFNULL(a.net_Total_comm, 0)) AS tot_net_aff
  FROM monthly_comms_affiliate_v5 a
  CROSS JOIN params p
  WHERE a.`Month` BETWEEN p.mf AND p.mu
  GROUP BY a.Affiliate_id
),
aff_pub_cnt AS (
  SELECT Affiliate_id, COUNT(DISTINCT Publisher_id) AS pub_cnt
  FROM comm_pa
  GROUP BY Affiliate_id
),
man AS (
  SELECT m.Affiliate_id,
         SUM(IFNULL(m.Amount_Credit, 0)) AS adj_raw
  FROM account_manual_adjustments m
  CROSS JOIN params p
  WHERE IFNULL(m.IncludeInProfitCalculation, 0) = 1
    AND IFNULL(m.Status, 0) IN (1, 2)
    AND LEFT(m.`Date`, 7) BETWEEN p.mf AND p.mu
  GROUP BY m.Affiliate_id
),
comm_pa_adj AS (
  SELECT
    c.Publisher_id,
    c.Affiliate_id,
    c.cpa_aff,
    c.net_cpa_val_aff,
    c.net_rs_val_aff,
    c.net_total_comm_aff,
    ROUND(IFNULL(m.adj_raw, 0) * (
      CASE
        WHEN IFNULL(t.tot_net_aff, 0) <> 0 THEN c.net_total_comm_aff / t.tot_net_aff
        WHEN IFNULL(apc.pub_cnt, 0) > 0 THEN 1.0 / apc.pub_cnt
        ELSE 0
      END
    ), 2) AS manual_adj_alloc,
    ROUND(c.net_total_comm_aff + IFNULL(m.adj_raw, 0) * (
      CASE
        WHEN IFNULL(t.tot_net_aff, 0) <> 0 THEN c.net_total_comm_aff / t.tot_net_aff
        WHEN IFNULL(apc.pub_cnt, 0) > 0 THEN 1.0 / apc.pub_cnt
        ELSE 0
      END
    ), 2) AS net_total_comm_aff_incl_adj
  FROM comm_pa c
  LEFT JOIN comm_a_tot t ON t.Affiliate_id = c.Affiliate_id
  LEFT JOIN man m ON m.Affiliate_id = c.Affiliate_id
  LEFT JOIN aff_pub_cnt apc ON apc.Affiliate_id = c.Affiliate_id
),
aff_by_pub AS (
  SELECT Publisher_id,
         SUM(cpa_aff) AS cpa_aff,
         SUM(net_cpa_val_aff) AS net_cpa_val_aff,
         SUM(net_rs_val_aff) AS net_rs_val_aff,
         SUM(net_total_comm_aff) AS net_total_comm_aff,
         SUM(manual_adj_alloc) AS manual_adj_alloc,
         SUM(net_total_comm_aff_incl_adj) AS net_total_comm_aff_incl_adj
  FROM comm_pa_adj
  GROUP BY Publisher_id
),
base_aff AS (
  SELECT
    x.Publisher_id,
    IFNULL(cp.Advertiser_Name, "") AS Publisher_name,
    x.Affiliate_id,
    IFNULL(TRIM(af.username), "") AS Affiliate_username,
    IFNULL(g.cpa_ges, 0) AS cpa_ges,
    IFNULL(g.net_cpa_val_ges, 0) AS net_cpa_val_ges,
    IFNULL(g.net_rs_val_ges, 0) AS net_rs_val_ges,
    IFNULL(g.net_total_comm_ges, 0) AS net_total_comm_ges,
    x.cpa_aff,
    x.net_cpa_val_aff,
    x.net_rs_val_aff,
    x.net_total_comm_aff,
    x.manual_adj_alloc,
    x.net_total_comm_aff_incl_adj,
    ROUND(IFNULL(g.net_total_comm_ges, 0) - x.net_total_comm_aff_incl_adj, 2) AS Beneficio
  FROM comm_pa_adj x
  LEFT JOIN ges g ON g.Publisher_id = x.Publisher_id
  LEFT JOIN campaign_publisher cp ON cp.id = x.Publisher_id
  LEFT JOIN account_account af ON af.id = x.Affiliate_id
  CROSS JOIN params p
  WHERE p.mode_flag = "DETAIL"
),
base_pub AS (
  SELECT
    g.Publisher_id,
    cp.Advertiser_Name AS Publisher_name,
    NULL AS Affiliate_id,
    "" AS Affiliate_username,
    g.cpa_ges,
    g.net_cpa_val_ges,
    g.net_rs_val_ges,
    g.net_total_comm_ges,
    IFNULL(a.cpa_aff, 0) AS cpa_aff,
    IFNULL(a.net_cpa_val_aff, 0) AS net_cpa_val_aff,
    IFNULL(a.net_rs_val_aff, 0) AS net_rs_val_aff,
    IFNULL(a.net_total_comm_aff, 0) AS net_total_comm_aff,
    IFNULL(a.manual_adj_alloc, 0) AS manual_adj_alloc,
    IFNULL(a.net_total_comm_aff_incl_adj, 0) AS net_total_comm_aff_incl_adj,
    ROUND(g.net_total_comm_ges - IFNULL(a.net_total_comm_aff_incl_adj, 0), 2) AS Beneficio
  FROM ges g
  LEFT JOIN aff_by_pub a ON a.Publisher_id = g.Publisher_id
  LEFT JOIN campaign_publisher cp ON cp.id = g.Publisher_id
  CROSS JOIN params p
  WHERE p.mode_flag = "PUBLISHER"
),
unioned AS (
  SELECT b.* FROM base_pub b
  CROSS JOIN params p WHERE p.mode_flag = "PUBLISHER"
  UNION ALL
  SELECT b.* FROM base_aff b
  CROSS JOIN params p WHERE p.mode_flag = "DETAIL"
),
den AS (
  SELECT
    (SELECT IFNULL(SUM(g2.cpa_ges), 0) FROM ges g2) AS t_cpa_ges,
    (SELECT IFNULL(SUM(g2.net_cpa_val_ges), 0) FROM ges g2) AS t_net_cpa_ges,
    (SELECT IFNULL(SUM(g2.net_rs_val_ges), 0) FROM ges g2) AS t_net_rs_ges,
    (SELECT IFNULL(SUM(g2.net_total_comm_ges), 0) FROM ges g2) AS t_net_tot_ges,
    (SELECT IFNULL(SUM(u2.cpa_aff), 0) FROM unioned u2) AS t_cpa_aff,
    (SELECT IFNULL(SUM(u2.net_cpa_val_aff), 0) FROM unioned u2) AS t_net_cpa_aff,
    (SELECT IFNULL(SUM(u2.net_rs_val_aff), 0) FROM unioned u2) AS t_net_rs_aff,
    (SELECT IFNULL(SUM(u2.net_total_comm_aff_incl_adj), 0) FROM unioned u2) AS t_net_tot_aff,
    (SELECT IFNULL(SUM(u2.Beneficio), 0) FROM unioned u2) AS t_beneficio
  FROM DUAL
),
numbered AS (
  SELECT u.*,
         d.t_cpa_ges, d.t_net_cpa_ges, d.t_net_rs_ges, d.t_net_tot_ges,
         d.t_cpa_aff, d.t_net_cpa_aff, d.t_net_rs_aff, d.t_net_tot_aff,
         d.t_beneficio
  FROM unioned u
  CROSS JOIN den d
),
data_rows AS (
  SELECT
    "data" AS Meta,
    n.Publisher_id,
    n.Publisher_name,
    n.Affiliate_id,
    n.Affiliate_username,
    n.cpa_ges,
    n.net_cpa_val_ges,
    n.net_rs_val_ges,
    n.net_total_comm_ges,
    n.cpa_aff,
    n.net_cpa_val_aff,
    n.net_rs_val_aff,
    n.net_total_comm_aff,
    n.manual_adj_alloc,
    n.net_total_comm_aff_incl_adj,
    n.Beneficio,
    ROUND(100 * n.cpa_ges / NULLIF(n.t_cpa_ges, 0), 2) AS Pct_ges_CPA,
    ROUND(100 * n.net_cpa_val_ges / NULLIF(n.t_net_cpa_ges, 0), 2) AS Pct_ges_net_CPA_Val,
    ROUND(100 * n.net_rs_val_ges / NULLIF(n.t_net_rs_ges, 0), 2) AS Pct_ges_net_RS_Val,
    ROUND(100 * n.net_total_comm_ges / NULLIF(n.t_net_tot_ges, 0), 2) AS Pct_ges_net_Total_comm,
    ROUND(100 * n.cpa_aff / NULLIF(n.t_cpa_aff, 0), 2) AS Pct_aff_CPA,
    ROUND(100 * n.net_cpa_val_aff / NULLIF(n.t_net_cpa_aff, 0), 2) AS Pct_aff_net_CPA_Val,
    ROUND(100 * n.net_rs_val_aff / NULLIF(n.t_net_rs_aff, 0), 2) AS Pct_aff_net_RS_Val,
    ROUND(100 * n.net_total_comm_aff_incl_adj / NULLIF(n.t_net_tot_aff, 0), 2) AS Pct_aff_net_Total_comm,
    ROUND(100 * n.Beneficio / NULLIF(n.t_beneficio, 0), 2) AS Pct_Beneficio
  FROM numbered n
)
SELECT * FROM (
',
IF(v_Meta = 'YES', CONCAT(
'SELECT "setting" AS Meta,
  "', IF(v_Mode = 'DETAIL', 'width=90px,right=true,sortable=yes', 'omit=yes'), '" AS `Operator ID`,
  "width=220px,sortable=yes" AS Operator,
  "omit=yes"    AS Affiliate_id,
  "', IF(v_Mode = 'PUBLISHER', 'omit=yes', 'width=160px,sortable=yes'), '" AS Affiliate,
  "width=80px,right=true,sortable=yes"  AS CPA,
  "width=100px,right=true,sortable=yes" AS `CPA Value`,
  "width=100px,right=true,sortable=yes" AS `RS Value`,
  "width=110px,right=true,sortable=yes" AS `Total Commiss`,
  "width=80px,right=true,sortable=yes"  AS `CPA Aff`,
  "width=100px,right=true,sortable=yes" AS `CPA Value Aff`,
  "width=100px,right=true,sortable=yes" AS `RS Value Aff`,
  "width=100px,right=true,sortable=yes" AS `Total Commiss Aff`,
  "width=100px,right=true,sortable=yes" AS `Manual Adj`,
  "width=120px,right=true,sortable=yes" AS `Total Comm Aff + Adj`,
  "width=110px,right=true,sortable=yes" AS `Gross Margin`,
  "width=70px,right=true,sortable=yes" AS `Pct CPA`,
  "width=90px,right=true,sortable=yes" AS `Pct CPA Value`,
  "width=90px,right=true,sortable=yes" AS `Pct RS Value`,
  "width=90px,right=true,sortable=yes" AS `Pct Total Commiss`,
  "width=70px,right=true,sortable=yes" AS `Pct CPA Aff`,
  "width=90px,right=true,sortable=yes" AS `Pct CPA Value Aff`,
  "width=90px,right=true,sortable=yes" AS `Pct RS Value Aff`,
  "width=90px,right=true,sortable=yes" AS `Pct Total Commiss Aff`,
  "width=80px,right=true,sortable=yes" AS `Pct Gross Margin`
 FROM DUAL
UNION ALL
'), ''),
'SELECT * FROM data_rows
',
IF(v_Meta = 'YES',
'UNION ALL
SELECT
  "total" AS Meta,
  NULL AS Publisher_id,
  "TOTAL" AS Publisher_name,
  NULL AS Affiliate_id,
  "" AS Affiliate_username,
  (SELECT IFNULL(SUM(g3.cpa_ges), 0) FROM ges g3) AS cpa_ges,
  (SELECT IFNULL(SUM(g3.net_cpa_val_ges), 0) FROM ges g3) AS net_cpa_val_ges,
  (SELECT IFNULL(SUM(g3.net_rs_val_ges), 0) FROM ges g3) AS net_rs_val_ges,
  (SELECT IFNULL(SUM(g3.net_total_comm_ges), 0) FROM ges g3) AS net_total_comm_ges,
  (SELECT IFNULL(SUM(d.cpa_aff), 0) FROM data_rows d) AS cpa_aff,
  (SELECT IFNULL(SUM(d.net_cpa_val_aff), 0) FROM data_rows d) AS net_cpa_val_aff,
  (SELECT IFNULL(SUM(d.net_rs_val_aff), 0) FROM data_rows d) AS net_rs_val_aff,
  (SELECT IFNULL(SUM(d.net_total_comm_aff), 0) FROM data_rows d) AS net_total_comm_aff,
  (SELECT IFNULL(SUM(d.manual_adj_alloc), 0) FROM data_rows d) AS manual_adj_alloc,
  (SELECT IFNULL(SUM(d.net_total_comm_aff_incl_adj), 0) FROM data_rows d) AS net_total_comm_aff_incl_adj,
  ROUND(
    (SELECT IFNULL(SUM(g3.net_total_comm_ges), 0) FROM ges g3)
    - (SELECT IFNULL(SUM(d.net_total_comm_aff_incl_adj), 0) FROM data_rows d),
    2
  ) AS Beneficio,
  100 AS Pct_ges_CPA,
  100 AS Pct_ges_net_CPA_Val,
  100 AS Pct_ges_net_RS_Val,
  100 AS Pct_ges_net_Total_comm,
  100 AS Pct_aff_CPA,
  100 AS Pct_aff_net_CPA_Val,
  100 AS Pct_aff_net_RS_Val,
  100 AS Pct_aff_net_Total_comm,
  100 AS Pct_Beneficio
FROM DUAL
', ''),
') z
ORDER BY
  CASE z.Meta WHEN "setting" THEN 0 WHEN "total" THEN 1 ELSE 2 END;');
    END IF;

    IF v_Debug = 'YES' THEN
        SELECT v_stmt AS Sql_generado;
        LEAVE fra_dash_label;
    END IF;

    SET @fra_dash_sql = v_stmt;
    PREPARE stmt_fra_dash FROM @fra_dash_sql;
    EXECUTE stmt_fra_dash;
    DEALLOCATE PREPARE stmt_fra_dash;

END$$
DELIMITER ;
