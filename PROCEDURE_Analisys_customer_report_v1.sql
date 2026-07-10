/*
PROCEDURE_Analisys_customer_report_v1.sql - Análisis de jugadores con comportamiento compatible con fraude de afiliados

Descripción:
  Procedimiento Analisys_customer_report_v1.

Keys:
InputParams = [valor]. Parámetro de entrada.

Tabla fuente: customer_report_API_4_analysis
Objetivo: Detectar patrones que sugieren fraude por parte de afiliados (no por jugadores),
          como tráfico falso, cuentas incentivadas para disparar CPA, o lavado de comisiones.

Patrones detectados (entre otros):
1. CPA disparado + Deposits<50 en el mismo mes + Signup_Date en el mismo mes o mes anterior
2. CPA disparado + Deposits = Payouts (posible wash / auto-referido)
3. CPA disparado + Deposits<50 y sin actividad en los meses siguientes (churn-and-burn)
4. Afiliado con muchos jugadores sospechosos (umbral configurable) — resumen por afiliado

Referencia: Fraude afiliados iGaming (fake traffic, CPA abuse, bot sign-ups, low LTV post-CPA).
Compatible: MySQL 8.0.37 / 8.4

Parámetros (Key=Value, separados por coma):
  MinDeposit=40                    — umbral depósito bajo (default 50)
  MinSuspiciousPerAffiliate=10     — umbral para flag "muchos sospechosos" por afiliado (default 5)
  IncludeAllFlags=Yes              — incluir en detalle jugadores con 0 flags
  Output=Both|SummaryOnly|DetailOnly — Both = resumen + detalle; SummaryOnly = solo resumen; DetailOnly = solo detalle (default Both)

Uso:
  CALL Analisys_customer_report_v1('');
  CALL Analisys_customer_report_v1('MinDeposit=40');
  CALL Analisys_customer_report_v1('Output=SummaryOnly');
  CALL Analisys_customer_report_v1('MinSuspiciousPerAffiliate=10,Output=Both');

v1 2025-02 | v1.1 resumen por afiliado + flag muchos sospechosos
*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS Analisys_customer_report_v1;
-- -----------------------------------------------------

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report_v1(IN InputParams VARCHAR(250))
  COMMENT 'Reporte de jugadores con comportamiento compatible con fraude de afiliados'
BEGIN
  DECLARE v_MinDeposit       DECIMAL(20,2) DEFAULT 50;
  DECLARE v_MinSuspicious    INT UNSIGNED  DEFAULT 5;
  DECLARE v_IncludeAll       VARCHAR(10)   DEFAULT 'No';
  DECLARE v_Output           VARCHAR(20)   DEFAULT 'Both';
  DECLARE v_Param            VARCHAR(100);
  DECLARE v_Key              VARCHAR(64);
  DECLARE v_Val              VARCHAR(64);
  DECLARE v_pos              INT;

  -- Parámetros: MinDeposit=40, MinSuspiciousPerAffiliate=10, IncludeAllFlags=Yes, Output=SummaryOnly|DetailOnly|Both
  SET InputParams = CONCAT(TRIM(IFNULL(InputParams,'')), ',');
  SET InputParams = REPLACE(InputParams, '"', '');
  SET InputParams = REPLACE(InputParams, '''', '');

  WHILE InputParams != '' DO
    SET v_pos = LOCATE(',', InputParams);
    SET v_Param = TRIM(LEFT(InputParams, v_pos - 1));
    SET InputParams = SUBSTRING(InputParams, v_pos + 1);
    IF v_Param != '' THEN
      SET v_Key = TRIM(LOWER(SUBSTRING_INDEX(v_Param, '=', 1)));
      SET v_Val = TRIM(SUBSTRING(v_Param, LOCATE('=', v_Param) + 1));
      IF v_Key = 'mindeposit' AND v_Val REGEXP '^[0-9]+\.?[0-9]*$' THEN
        SET v_MinDeposit = CAST(v_Val AS DECIMAL(20,2));
      END IF;
      IF v_Key = 'minsuspiciousperaffiliate' AND v_Val REGEXP '^[0-9]+$' THEN
        SET v_MinSuspicious = CAST(v_Val AS UNSIGNED);
      END IF;
      IF v_Key = 'includeallflags' AND LOWER(v_Val) IN ('yes','1','true') THEN
        SET v_IncludeAll = 'Yes';
      END IF;
      IF v_Key = 'output' AND LOWER(v_Val) IN ('both','summaryonly','detailonly') THEN
        SET v_Output = LOWER(v_Val);
      END IF;
    END IF;
  END WHILE;

  -- Detalle con flags de fraude en tabla temporal (CTE único)
  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail;
  CREATE TEMPORARY TABLE tmp_fraud_detail AS
  WITH normalized AS (
    SELECT
      r.`Date`,
      r.Username_id,
      r.Customer_ID,
      r.Customer_alias,
      r.AffiliateID,
      r.Country,
      r.Signup_Date,
      r.Reward_Plan,
      r.Marketing_Source_Name,
      r.Marketing_Source_ID,
      r.CPA_Processed_Date,
      r.Brand,
      r.Customer_Signup_Source,
      CAST(NULLIF(TRIM(r.Gross_Revenue), '') AS DECIMAL(20,2)) AS Gross_Revenue,
      CAST(NULLIF(TRIM(r.Deposits), '') AS DECIMAL(20,2))     AS Deposits,
      CAST(NULLIF(TRIM(r.Turnover), '') AS DECIMAL(20,2))     AS Turnover,
      CAST(NULLIF(TRIM(r.Payouts), '') AS DECIMAL(20,2))       AS Payouts,
      CAST(NULLIF(TRIM(r.Total_Net_Revenue), '') AS DECIMAL(20,2)) AS Total_Net_Revenue,
      (CASE WHEN NULLIF(TRIM(r.CPA_Processed_Date), '') IS NOT NULL THEN 1 ELSE 0 END) AS cpa_triggered,
      CASE
        WHEN r.Signup_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 10), '%Y-%m-%d')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d/%m/%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS signup_date_parsed
    FROM customer_report_API_4_analysis r
  ),
  safe_numeric AS (
    SELECT *, COALESCE(Deposits, 0) AS dep, COALESCE(Payouts, 0) AS pay, COALESCE(Turnover, 0) AS turn FROM normalized
  ),
  with_months AS (
    SELECT *, DATE_FORMAT(`Date`, '%Y-%m') AS report_month, DATE_FORMAT(signup_date_parsed, '%Y-%m') AS signup_month FROM safe_numeric
  ),
  cpa_months AS (
    SELECT Customer_ID, Customer_alias, AffiliateID, Username_id, report_month, dep, pay, turn, cpa_triggered, signup_month, `Date`, Country, Brand, Reward_Plan, Marketing_Source_Name, Total_Net_Revenue, Gross_Revenue
    FROM with_months WHERE cpa_triggered = 1
  ),
  has_later_activity AS (
    SELECT c.Customer_ID, c.AffiliateID, c.report_month,
      MAX(CASE WHEN w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d')) THEN 1 ELSE 0 END) AS has_later
    FROM cpa_months c
    LEFT JOIN with_months w ON w.Customer_ID = c.Customer_ID AND w.AffiliateID = c.AffiliateID AND w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d'))
    GROUP BY c.Customer_ID, c.AffiliateID, c.report_month
  ),
  fraud_flags AS (
    SELECT c.Customer_ID, c.Customer_alias, c.AffiliateID, c.Username_id, c.report_month, c.dep, c.pay, c.turn, c.Country, c.Brand, c.Reward_Plan, c.Marketing_Source_Name, c.Total_Net_Revenue, c.Gross_Revenue,
      (CASE WHEN c.dep < v_MinDeposit AND (c.signup_month = c.report_month OR c.signup_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')) THEN 1 ELSE 0 END) AS flag_low_deposit_same_or_prev_month,
      (CASE WHEN c.dep = c.pay AND c.dep > 0 THEN 1 ELSE 0 END) AS flag_deposits_equals_payouts,
      (CASE WHEN c.dep < v_MinDeposit AND COALESCE(h.has_later, 0) = 0 THEN 1 ELSE 0 END) AS flag_no_activity_after_cpa
    FROM cpa_months c
    LEFT JOIN has_later_activity h ON h.Customer_ID = c.Customer_ID AND h.AffiliateID = c.AffiliateID AND h.report_month = c.report_month
  )
  SELECT *, (flag_low_deposit_same_or_prev_month + flag_deposits_equals_payouts + flag_no_activity_after_cpa) AS total_flags FROM fraud_flags;

  -- Resumen por afiliado (jugadores con CPA, sospechosos, conteos por flag, "muchos sospechosos")
  DROP TEMPORARY TABLE IF EXISTS tmp_affiliate_summary;
  CREATE TEMPORARY TABLE tmp_affiliate_summary AS
  SELECT
    AffiliateID,
    COUNT(DISTINCT Customer_ID) AS total_players_with_cpa,
    COUNT(DISTINCT CASE WHEN total_flags >= 1 THEN Customer_ID END) AS suspicious_players,
    COUNT(DISTINCT CASE WHEN flag_low_deposit_same_or_prev_month = 1 THEN Customer_ID END) AS players_f1,
    COUNT(DISTINCT CASE WHEN flag_deposits_equals_payouts = 1 THEN Customer_ID END) AS players_f2,
    COUNT(DISTINCT CASE WHEN flag_no_activity_after_cpa = 1 THEN Customer_ID END) AS players_f3,
    (CASE WHEN COUNT(DISTINCT CASE WHEN total_flags >= 1 THEN Customer_ID END) >= v_MinSuspicious THEN 1 ELSE 0 END) AS many_suspicious_flag
  FROM tmp_fraud_detail
  GROUP BY AffiliateID;

  -- Result set 1: Resumen por afiliado (si se pide)
  IF v_Output IN ('Both', 'SummaryOnly') THEN
    SELECT
      AffiliateID,
      total_players_with_cpa   AS Jugadores_con_CPA,
      suspicious_players      AS Jugadores_sospechosos,
      players_f1              AS Con_F1_bajo_dep_mismo_ant_mes,
      players_f2              AS Con_F2_Dep_igual_Payouts,
      players_f3              AS Con_F3_sin_actividad_posterior,
      many_suspicious_flag     AS F4_muchos_sospechosos
    FROM tmp_affiliate_summary
    ORDER BY suspicious_players DESC, total_players_with_cpa DESC;
  END IF;

  -- Result set 2: Detalle de jugadores (si se pide), con columnas de resumen del afiliado
  IF v_Output IN ('Both', 'DetailOnly') THEN
    SELECT
      d.Customer_ID,
      d.Customer_alias,
      d.AffiliateID,
      d.Username_id,
      d.report_month     AS Mes_reporte,
      d.dep              AS Deposits,
      d.pay              AS Payouts,
      d.turn             AS Turnover,
      d.Country,
      d.Brand,
      d.Reward_Plan,
      d.Marketing_Source_Name,
      d.Total_Net_Revenue,
      d.Gross_Revenue,
      d.flag_low_deposit_same_or_prev_month AS F1_CPA_bajo_dep_mismo_ant_mes,
      d.flag_deposits_equals_payouts       AS F2_Dep_igual_Payouts,
      d.flag_no_activity_after_cpa         AS F3_Sin_actividad_posterior,
      d.total_flags      AS Total_flags,
      s.suspicious_players AS Afiliado_jugadores_sospechosos,
      s.many_suspicious_flag AS Afiliado_F4_muchos_sospechosos
    FROM tmp_fraud_detail d
    LEFT JOIN tmp_affiliate_summary s ON s.AffiliateID = d.AffiliateID
    WHERE (v_IncludeAll = 'Yes') OR d.total_flags >= 1
    ORDER BY s.suspicious_players DESC, d.total_flags DESC, d.report_month, d.AffiliateID, d.Customer_ID;
  END IF;

  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail;
  DROP TEMPORARY TABLE IF EXISTS tmp_affiliate_summary;

END$$
DELIMITER ;
