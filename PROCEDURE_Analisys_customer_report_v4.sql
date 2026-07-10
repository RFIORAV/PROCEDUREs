/*
PROCEDURE_Analisys_customer_report_v4.sql

Descripción:
  Procedimiento Analisys_customer_report_v4.

Keys:
InputParams = [valor]. Parámetro de entrada.

Tabla fuente: customer_report_API_4_analysis
Objetivo: Detectar jugadores con comportamiento compatible con fraude de afiliados.

Patrones:
  F1: CPA Triggered + Deposits < MinDeposit + Signup_Date del mismo mes o mes anterior
  F2: CPA Triggered + Payouts >= Deposits + Turnover <= Deposits
  F3: CPA Triggered + Deposits < MinDeposit + sin actividad en meses siguientes
  F4: CPA Triggered + Transactions <= MinTransactions (minimal engagement / CPA farming)
  F5: CPA Triggered + Total_Net_Revenue < 0 (negative value player / bonus abuse)
  F6: CPA Triggered en el mismo mes calendario que Signup (rapid CPA trigger)

Compatibilidad: MySQL 8.0.37 / 8.4

Parámetros (Key=Value, separados por coma):
  MinDeposit=50          — umbral de depósito bajo para F1 y F3 (default 50)
  Signup_Month=YYYY-MM   — solo Customer_ID con signup >= este mes (opcional)
  MinTransactions=2      — umbral de transacciones para F4 (default 2)

Ejemplos:
  CALL Analisys_customer_report_v4('');
  CALL Analisys_customer_report_v4('MinDeposit=40');
  CALL Analisys_customer_report_v4('Signup_Month=2025-01');
  CALL Analisys_customer_report_v4('Signup_Month=2025-02,MinDeposit=40');
  CALL Analisys_customer_report_v4('MinTransactions=3');
  CALL Analisys_customer_report_v4('Signup_Month=2025-01,MinDeposit=40,MinTransactions=3');

v3 2025-02  F1, F2, F3
v4 2026-02  F4 (minimal engagement), F5 (negative value), F6 (rapid CPA trigger);
            agrega Transactions y Total_Net_Revenue a la salida
*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DROP PROCEDURE IF EXISTS Analisys_customer_report_v4;

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report_v4(IN InputParams VARCHAR(250))
  COMMENT 'Reporte de señales de posible fraude de afiliados sobre customer_report_API_4_analysis v4'
BEGIN
  DECLARE v_MinDeposit      DECIMAL(20,2) DEFAULT 50;
  DECLARE v_SignupMonth      VARCHAR(7) DEFAULT NULL;
  DECLARE v_MinTransactions  INT DEFAULT 2;
  DECLARE v_Param            VARCHAR(100);
  DECLARE v_Key              VARCHAR(64);
  DECLARE v_Val              VARCHAR(64);
  DECLARE v_pos              INT;

  -- Parseo de parámetros: MinDeposit=40, Signup_Month=YYYY-MM, MinTransactions=3
  SET InputParams = CONCAT(TRIM(IFNULL(InputParams, '')), ',');
  SET InputParams = REPLACE(REPLACE(InputParams, '"', ''), '''', '');
  WHILE InputParams <> '' DO
    SET v_pos = LOCATE(',', InputParams);
    SET v_Param = TRIM(LEFT(InputParams, v_pos - 1));
    SET InputParams = SUBSTRING(InputParams, v_pos + 1);

    IF v_Param <> '' THEN
      SET v_Key = TRIM(LOWER(SUBSTRING_INDEX(v_Param, '=', 1)));
      SET v_Val = TRIM(SUBSTRING(v_Param, LOCATE('=', v_Param) + 1));

      IF v_Key = 'mindeposit' AND v_Val REGEXP '^[0-9]+\\.?[0-9]*$' THEN
        SET v_MinDeposit = CAST(v_Val AS DECIMAL(20,2));
      END IF;

      IF v_Key = 'signup_month' AND v_Val REGEXP '^[0-9]{4}-[0-9]{2}$' THEN
        SET v_SignupMonth = v_Val;
      END IF;

      IF v_Key = 'mintransactions' AND v_Val REGEXP '^[0-9]+$' THEN
        SET v_MinTransactions = CAST(v_Val AS SIGNED);
      END IF;
    END IF;
  END WHILE;

  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v4;
  CREATE TEMPORARY TABLE tmp_fraud_detail_v4 AS
  WITH normalized AS (
    SELECT
      r.`Date`,
      r.Affiliate,
      r.Affiliate_id,
      r.Brand,
      r.Username,
      r.Username_id,
      r.Product,
      r.Customer_ID,
      r.Customer_alias,
      r.Country,
      r.Signup_Date,
      r.Reward_Plan,
      r.Tracker_Name,
      r.Tracker_id,
      r.Customer_Level,
      r.CPA_Processed_Date,
      r.MS_id,
      COALESCE(r.Deposits, 0) AS dep,
      COALESCE(r.Turnover, 0) AS turn,
      COALESCE(r.Payouts, 0) AS pay,
      COALESCE(r.Total_Net_Revenue, 0) AS tnr,
      COALESCE(r.Transactions, 0) AS txn,
      (CASE WHEN NULLIF(TRIM(r.CPA_Processed_Date), '') IS NOT NULL THEN 1 ELSE 0 END) AS cpa_triggered,
      CASE
        WHEN r.Signup_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 10), '%Y-%m-%d')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d-%m-%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d/%m/%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS signup_date_parsed,
      CASE
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.CPA_Processed_Date), 10), '%Y-%m-%d')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(TRIM(r.CPA_Processed_Date), '%d-%m-%Y')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.CPA_Processed_Date), '%d/%m/%Y')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.CPA_Processed_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS cpa_date_parsed
    FROM customer_report_API_4_analysis r
  ),
  with_months AS (
    SELECT
      *,
      DATE_FORMAT(`Date`, '%Y-%m') AS report_month,
      DATE_FORMAT(signup_date_parsed, '%Y-%m') AS signup_month
    FROM normalized
  ),
  filtered AS (
    SELECT *
    FROM with_months
    WHERE cpa_triggered = 1
      AND (v_SignupMonth IS NULL OR signup_month >= v_SignupMonth)
  ),
  has_later_activity AS (
    SELECT
      c.Customer_ID,
      c.Affiliate_id,
      c.MS_id,
      c.report_month,
      MAX(
        CASE
          WHEN w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month, '-01'), '%Y-%m-%d'))
           AND (COALESCE(w.dep, 0) > 0 OR COALESCE(w.pay, 0) > 0 OR COALESCE(w.turn, 0) > 0 OR COALESCE(w.tnr, 0) <> 0)
          THEN 1 ELSE 0
        END
      ) AS has_later
    FROM filtered c
    LEFT JOIN with_months w
      ON w.Customer_ID = c.Customer_ID
     AND w.Affiliate_id = c.Affiliate_id
     AND w.MS_id = c.MS_id
    GROUP BY c.Customer_ID, c.Affiliate_id, c.MS_id, c.report_month
  ),
  fraud_flags AS (
    SELECT
      c.Affiliate,
      c.Affiliate_id,
      c.Brand,
      c.MS_id,
      c.Customer_ID,
      c.Customer_alias,
      c.Signup_Date,
      c.CPA_Processed_Date,
      c.dep,
      c.turn,
      c.pay,
      c.tnr,
      c.txn,
      c.report_month,
      c.signup_month,
      c.Tracker_id,
      c.Tracker_Name,
      c.cpa_date_parsed,
      -- F1: CPA + depósito bajo + signup reciente
      CASE
        WHEN c.dep < v_MinDeposit
         AND (
              c.signup_month = c.report_month
              OR c.signup_month = DATE_FORMAT(
                                   DATE_SUB(STR_TO_DATE(CONCAT(c.report_month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH),
                                   '%Y-%m'
                                 )
             )
        THEN 1 ELSE 0
      END AS F1,
      -- F2: CPA + cycling deposit-withdrawal
      CASE
        WHEN c.pay >= c.dep
         AND c.turn <= c.dep
         AND c.dep > 0
        THEN 1 ELSE 0
      END AS F2,
      -- F3: CPA + depósito bajo + sin actividad posterior
      CASE
        WHEN c.dep < v_MinDeposit
         AND COALESCE(h.has_later, 0) = 0
        THEN 1 ELSE 0
      END AS F3,
      -- F4: CPA + pocas transacciones (minimal engagement / CPA farming)
      CASE
        WHEN c.txn <= v_MinTransactions
         AND c.dep > 0
        THEN 1 ELSE 0
      END AS F4,
      -- F5: CPA + net revenue negativo (bonus abuse / matched betting)
      CASE
        WHEN c.tnr < 0
         AND c.dep > 0
        THEN 1 ELSE 0
      END AS F5,
      -- F6: CPA procesado en el mismo mes que signup (rapid CPA trigger)
      CASE
        WHEN c.cpa_date_parsed IS NOT NULL
         AND c.signup_date_parsed IS NOT NULL
         AND DATE_FORMAT(c.cpa_date_parsed, '%Y-%m') = c.signup_month
        THEN 1 ELSE 0
      END AS F6
    FROM filtered c
    LEFT JOIN has_later_activity h
      ON h.Customer_ID = c.Customer_ID
     AND h.Affiliate_id = c.Affiliate_id
     AND h.MS_id = c.MS_id
     AND h.report_month = c.report_month
  ),
  per_player AS (
    SELECT
      Affiliate_id,
      MS_id,
      Customer_ID,
      ANY_VALUE(Affiliate) AS Affiliate,
      ANY_VALUE(Brand) AS Brand,
      ANY_VALUE(Signup_Date) AS Signup_Date,
      ANY_VALUE(CPA_Processed_Date) AS CPA_Processed_Date,
      SUM(dep) AS Deposits,
      SUM(turn) AS Turnover,
      SUM(pay) AS Payouts,
      SUM(txn) AS Transactions,
      SUM(tnr) AS Total_Net_Revenue,
      MAX(F1) AS F1,
      MAX(F2) AS F2,
      MAX(F3) AS F3,
      CASE WHEN SUM(txn) <= v_MinTransactions AND SUM(dep) > 0 THEN 1 ELSE 0 END AS F4,
      CASE WHEN SUM(tnr) < 0 AND SUM(dep) > 0 THEN 1 ELSE 0 END AS F5,
      MAX(F6) AS F6,
      ANY_VALUE(Tracker_id) AS Tracker_id,
      ANY_VALUE(Tracker_Name) AS Tracker_Name,
      ANY_VALUE(Customer_alias) AS Customer_alias
    FROM fraud_flags
    GROUP BY Affiliate_id, MS_id, Customer_ID
  )
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
    Transactions,
    Total_Net_Revenue,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM per_player
  WHERE (F1 + F2 + F3 + F4 + F5 + F6) >= 1;

  -- Resultado final ordenado por Affiliate_id y agrupado por Affiliate_id, MS_id, Customer_ID.
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
    Transactions,
    Total_Net_Revenue,
    F1,
    F2,
    F3,
    F4,
    F5,
    F6,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM tmp_fraud_detail_v4
  ORDER BY Affiliate_id, MS_id, Customer_ID;

  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v4;
END$$
DELIMITER ;
