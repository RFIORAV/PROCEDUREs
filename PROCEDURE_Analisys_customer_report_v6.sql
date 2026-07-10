/*
PROCEDURE_Analisys_customer_report_v6.sql

Descripción:
  Procedimiento Analisys_customer_report_v6.

Keys:
p_SignUp = [valor]. Parámetro de entrada.

Tabla fuente: customer_report_API_4_analysis
Objetivo: Detectar jugadores con un único depósito que no supera el 50% del Baseline (CPA),
          con CPA procesado, dentro de un rango de Signup_Date por mes.
          Indicador de posible CPA farming: depósito mínimo único para disparar CPA.

Compatibilidad: MySQL 8.0.37 / 8.4

Parámetros:
  IN p_SignUp DATE — primer día del mes a analizar (default: primer día del mes actual)

Ejemplos:
  CALL Analisys_customer_report_v6(NULL);              -- mes actual
  CALL Analisys_customer_report_v6('2026-02-01');
  CALL Analisys_customer_report_v6('2026-01-01');

Version history:
  20.02.2026 v6.0  Detección de depósito único <= 50% del Baseline con CPA triggered
*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DROP PROCEDURE IF EXISTS Analisys_customer_report_v6;

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report_v6(IN p_SignUp DATE)
  COMMENT 'Jugadores con depósito único <= 50% Baseline y CPA triggered v6'
BEGIN
  DECLARE v_SignUp   DATE;
  DECLARE v_SignUpTo DATE;

  SET @Version = 'v6.0 20.02.2026';

  SET v_SignUp   = IFNULL(p_SignUp, DATE_FORMAT(CURDATE(), '%Y-%m-01'));
  SET v_SignUpTo = LAST_DAY(v_SignUp);

  SELECT Customer_ID,
        --  Customer_alias,
         Affiliate,
        --  Affiliate_id,
         Brand,
         MS_id,
         `Date`,
         Username,
         Username_id,
        --  Product,
         Country,
         Signup_Date,
         Reward_Plan,
         CPA_Value,
         RS_Percentage,
         Baseline,
         Tracker_Name,
         Tracker_id,
         Customer_Level,
         CPA_Processed_Date,
         Gross_Revenue,
         Deposits,
         Turnover,
         Payouts,
         Transactions,
         Total_Net_Revenue,
         Total_Net_Revenue_MTD,
         Deal_Aff_id
  FROM customer_report_API_4_analysis
  WHERE Deposits > 0
    AND Signup_Date BETWEEN v_SignUp AND v_SignUpTo
    AND CPA_Processed_Date IS NOT NULL
    AND CONCAT(Username_id, Customer_ID) IN (
      SELECT CONCAT(Username_id, Customer_ID)
      FROM customer_report_API_4_analysis
      WHERE Deposits > 0
        AND Signup_Date BETWEEN v_SignUp AND v_SignUpTo
        AND CPA_Processed_Date IS NOT NULL
      GROUP BY CONCAT(Username_id, Customer_ID)
      HAVING COUNT(*) = 1
         AND SUM(Deposits) <= MAX(Baseline) * 0.5
    )
  ORDER BY Affiliate, Brand, Customer_ID;

END$$
DELIMITER ;
