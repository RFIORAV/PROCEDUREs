/*
PROCEDURE_Analisys_customer_report_v2.sql - Reporte de jugadores con comportamiento compatible con fraude de afiliados

Descripción:
  Procedimiento Analisys_customer_report_v2.

Keys:
InputParams = [valor]. Parámetro de entrada.

Tabla fuente: customer_report_API_4_analysis (esquema: Affiliate, Affiliate_id, Tracker_Name, Tracker_id, MS_id, Date, Customer_ID, Signup_Date, CPA_Processed_Date, Deposits, Payouts, Turnover, ...)
Objetivo: Detectar patrones F1, F2, F3 que sugieren fraude por parte de afiliados (no por jugadores).

Patrones detectados:
  F1: CPA Triggered y Deposits < umbral en el mismo mes, y Signup_Date del mismo mes o del mes anterior
  F2: CPA Triggered y Deposits = Payouts
  F3: CPA Triggered y Deposits < umbral y no hay más actividad en los meses siguientes

CPA Triggered: CPA_Processed_Date informado (no NULL ni vacío).
Recomendación de índice para tablas grandes: (Date, Affiliate_id, Customer_ID).

Datos: la tabla puede cargarse desde el dump en dump/customer_report_API_4_analysis-*.sql
  (ej. customer_report_API_4_analysis-2026-02-16 12_31_18-12.31.sql). Incluye Signup_Date/CPA_Processed_Date en DD-MM-YYYY.

Compatible: MySQL 8.0.37 / 8.4

Parámetros (Key=Value, separados por coma):
  MinDeposit=40       — umbral de depósito bajo para F1 y F3 (default 50)
  Signup_Month=YYYY-MM — solo considerar Customer_ID con CPA Trigger y cuya fecha de signup sea >= este mes (opcional; si se omite, se incluyen todos)

Uso:
  CALL Analisys_customer_report_v2('');
  CALL Analisys_customer_report_v2('MinDeposit=40');
  CALL Analisys_customer_report_v2('Signup_Month=2025-01');
  CALL Analisys_customer_report_v2('Signup_Month=2025-02,MinDeposit=40');

v2 2025-02 — Esquema según prompt (Affiliate_id, Tracker_Name, Tracker_id, MS_id); salida ordenada por Affiliate_id.
*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS Analisys_customer_report_v2;
-- -----------------------------------------------------

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report_v2(IN InputParams VARCHAR(250))
  COMMENT 'Reporte de jugadores con comportamiento compatible con fraude de afiliados (esquema API 4)'
BEGIN
  DECLARE v_MinDeposit   DECIMAL(20,2) DEFAULT 50;
  DECLARE v_SignupMonth  VARCHAR(7) DEFAULT NULL;
  DECLARE v_Param        VARCHAR(100);
  DECLARE v_Key          VARCHAR(64);
  DECLARE v_Val          VARCHAR(64);
  DECLARE v_pos          INT;

  -- Parámetros: MinDeposit=40, Signup_Month=YYYY-MM
  SET InputParams = CONCAT(TRIM(IFNULL(InputParams,'')), ',');
  SET InputParams = REPLACE(REPLACE(InputParams, '"', ''), '''', '');
  WHILE InputParams != '' DO
    SET v_pos = LOCATE(',', InputParams);
    SET v_Param = TRIM(LEFT(InputParams, v_pos - 1));
    SET InputParams = SUBSTRING(InputParams, v_pos + 1);
    IF v_Param != '' THEN
      SET v_Key = TRIM(LOWER(SUBSTRING_INDEX(v_Param, '=', 1)));
      SET v_Val = TRIM(SUBSTRING(v_Param, LOCATE('=', v_Param) + 1));
      IF v_Key = 'mindeposit' AND v_Val REGEXP '^[0-9]+\\.?[0-9]*$' THEN
        SET v_MinDeposit = CAST(v_Val AS DECIMAL(20,2));
      END IF;
      IF v_Key = 'signup_month' AND v_Val REGEXP '^[0-9]{4}-[0-9]{2}$' THEN
        SET v_SignupMonth = v_Val;
      END IF;
    END IF;
  END WHILE;

  -- Reporte: una fila por jugador sospechoso (Customer_ID + afiliado/tracker) con F1, F2, F3; solo cuando al menos un flag
  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v2;
  CREATE TEMPORARY TABLE tmp_fraud_detail_v2 AS
  WITH normalized AS (
    SELECT
      r.`Date`,
      r.Affiliate,
      r.Affiliate_id,
      r.Brand,
      r.Tracker_Name,
      r.Tracker_id,
      r.MS_id,
      r.Customer_ID,
      r.Customer_alias,
      r.Signup_Date,
      r.CPA_Processed_Date,
      COALESCE(r.Deposits, 0)     AS dep,
      COALESCE(r.Payouts, 0)      AS pay,
      COALESCE(r.Turnover, 0)     AS turn,
      (CASE WHEN NULLIF(TRIM(r.CPA_Processed_Date), '') IS NOT NULL THEN 1 ELSE 0 END) AS cpa_triggered,
      CASE
        WHEN r.Signup_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 10), '%Y-%m-%d')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d-%m-%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d/%m/%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS signup_date_parsed
    FROM customer_report_API_4_analysis r
  ),
  with_months AS (
    SELECT
      *,
      DATE_FORMAT(`Date`, '%Y-%m') AS report_month,
      DATE_FORMAT(signup_date_parsed, '%Y-%m') AS signup_month
    FROM normalized
  ),
  -- Solo Customer_ID con signup_month >= Signup_Month (cuando se informa); así el reporte incluye únicamente quienes produjeron CPA y cumplen ese criterio de signup
  filtered_by_signup AS (
    SELECT * FROM with_months
    WHERE (v_SignupMonth IS NULL OR signup_month >= v_SignupMonth)
  ),
  -- Filas con CPA Trigger dentro del conjunto filtrado por signup (solo estos Customer_ID entran al reporte)
  cpa_months AS (
    SELECT
      Customer_ID,
      Customer_alias,
      Affiliate,
      Affiliate_id,
      Brand,
      Tracker_Name,
      Tracker_id,
      MS_id,
      report_month,
      dep,
      pay,
      turn,
      signup_month,
      Signup_Date,
      CPA_Processed_Date
    FROM filtered_by_signup
    WHERE cpa_triggered = 1
  ),
  has_later_activity AS (
    SELECT
      c.Customer_ID,
      c.Affiliate_id,
      c.report_month,
      MAX(CASE WHEN w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d')) THEN 1 ELSE 0 END) AS has_later
    FROM cpa_months c
    LEFT JOIN filtered_by_signup w
      ON w.Customer_ID = c.Customer_ID
     AND w.Affiliate_id = c.Affiliate_id
     AND w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d'))
    GROUP BY c.Customer_ID, c.Affiliate_id, c.report_month
  ),
  fraud_flags AS (
    SELECT
      c.Customer_ID,
      c.Customer_alias,
      c.Affiliate,
      c.Affiliate_id,
      c.Brand,
      c.Tracker_Name,
      c.Tracker_id,
      c.MS_id,
      c.Signup_Date,
      c.CPA_Processed_Date,
      c.dep,
      c.pay,
      c.turn,
      c.report_month,
      (CASE WHEN c.dep < v_MinDeposit
            AND (c.signup_month = c.report_month
                 OR c.signup_month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(c.report_month,'-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m'))
            THEN 1 ELSE 0 END) AS flag_f1,
      (CASE WHEN c.dep = c.pay AND c.dep > 0 THEN 1 ELSE 0 END) AS flag_f2,
      (CASE WHEN c.dep < v_MinDeposit AND COALESCE(h.has_later, 0) = 0 THEN 1 ELSE 0 END) AS flag_f3
    FROM cpa_months c
    LEFT JOIN has_later_activity h
      ON h.Customer_ID = c.Customer_ID
     AND h.Affiliate_id = c.Affiliate_id
     AND h.report_month = c.report_month
  ),
  per_player AS (
    SELECT
      Affiliate_id,
      MS_id,
      Customer_ID,
      ANY_VALUE(Customer_alias)   AS Customer_alias,
      ANY_VALUE(Affiliate)        AS Affiliate,
      ANY_VALUE(Tracker_Name)     AS Tracker_Name,
      ANY_VALUE(Tracker_id)       AS Tracker_id,
      ANY_VALUE(Brand)            AS Brand,
      ANY_VALUE(Signup_Date)      AS Signup_Date,
      ANY_VALUE(CPA_Processed_Date) AS CPA_Processed_Date,
      SUM(dep)   AS Deposits,
      SUM(turn)  AS Turnover,
      SUM(pay)   AS Payouts,
      MAX(flag_f1) AS F1,
      MAX(flag_f2) AS F2,
      MAX(flag_f3) AS F3
    FROM fraud_flags
    GROUP BY Affiliate_id, MS_id, Customer_ID
  )
  SELECT
    Affiliate_id,
    MS_id,
    Customer_ID,
    Affiliate,
    Brand,
    Signup_Date,
    CPA_Processed_Date,
    Deposits,
    Turnover,
    Payouts,
    F1,
    F2,
    F3,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM per_player
  WHERE (F1 + F2 + F3) >= 1;

  -- Salida según prompt: orden Affiliate_id; columnas Affiliate, Affiliate_id, Brand, MS_id, Customer_ID, Signup_Date, CPA_Processed_Date, Deposits, Turnover, Payouts, F1, F2, F3, Tracker_id, Tracker_Name, Customer_alias
  SELECT
    Affiliate,
    Affiliate_id,
    Brand,
    MS_id,
    Customer_ID,
    Signup_Date,
    CPA_Processed_Date,
    Deposits,
    Turnover,
    Payouts,
    F1,
    F2,
    F3,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM tmp_fraud_detail_v2
  ORDER BY Affiliate_id, MS_id, Customer_ID;

  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v2;

END$$
DELIMITER ;
