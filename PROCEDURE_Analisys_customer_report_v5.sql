/*
PROCEDURE_Analisys_customer_report_v5.sql

Descripción:
  Procedimiento Analisys_customer_report.

Keys:
InputParams = [valor]. Parámetro de entrada.

Tabla fuente: customer_report_API_4_analysis
Objetivo: Detectar jugadores con comportamiento compatible con fraude de afiliados.

Patrones de fraude detectados (todos requieren CPA Triggered):
  F1: Deposit-withdrawal cycling — Payouts >= Deposits + Turnover <= Deposits
      Ref: "bonus abuse networks" que reclaman bonos, cumplen playthrough mínimo y retiran
  F2: Jugador fantasma — Deposits < MinDeposit + sin actividad en meses siguientes
      Ref: fake players / incentivized users que hacen un depósito mínimo y desaparecen
  F3: Minimal engagement — Transactions <= MinTransactions + Deposits > 0
      Ref: CPA farming con mínima interacción real
  F4: Multi-geo anomaly — País del jugador distinto al país principal del afiliado
      Ref: geo-spoofing, fake KYC, redes de cuentas en múltiples jurisdicciones
  F5: Deposit-to-threshold match — Depósito total cercano al umbral mínimo de CPA
      Ref: depósito mínimo exacto para disparar CPA sin intención real de juego
  F6: High CPA velocity — Afiliado disparó más de MaxCPAperMonth CPAs en el mismo mes
      Ref: CPA farming organizado, tráfico falso o incentivado en lotes
  F7: Depósito sin juego — Deposits > 0 pero Turnover = 0
      Ref: deposita solo para activar CPA, sin ninguna actividad de juego real

  Score: suma de F1..F7 como indicador de riesgo global

Compatibilidad: MySQL 8.0.37 / 8.4

Parámetros (Key=Value, separados por coma):
  MinDeposit=50          — umbral de depósito bajo para F2 y F5 (default 50)
  MaxDeposit=100         — excluye jugadores con Deposits > MaxDeposit (default 100)
  Signup_Month=YYYY-MM   — solo Customer_ID con signup >= este mes
  MinTransactions=2      — umbral de transacciones para F3 (default 2)
  MaxCPAperMonth=10      — umbral de CPAs por afiliado/mes para F6 (default 10)
  DepositMargin=1.2      — factor sobre MinDeposit para F5: dep <= MinDeposit * factor (default 1.2)

Ejemplos:
  CALL Analisys_customer_report('');
  CALL Analisys_customer_report('MinDeposit=40');
  CALL Analisys_customer_report('Signup_Month=2025-01');
  CALL Analisys_customer_report('Signup_Month=2025-02,MinDeposit=40');
  CALL Analisys_customer_report('MinTransactions=3,MaxCPAperMonth=8');
  CALL Analisys_customer_report('Signup_Month=2025-01,MinDeposit=40,MaxDeposit=150,MinTransactions=3,MaxCPAperMonth=15');

Version history:
  v3 02.2025  F1 (low dep+recent signup), F2 (cycling), F3 (fantasma)
  v4 02.2026  F4 (minimal engagement), F5 (negative value), F6 (rapid CPA trigger);
              agrega Transactions y Total_Net_Revenue a la salida
  v5 17.02.2026  Elimina F1-v4 (no documentado como fraude), F4-v4 (negative value),
              F5-v4 (rapid CPA trigger); renumera flags F1..F7;
              agrega F4 (multi-geo), F5 (deposit-to-threshold), F6 (CPA velocity),
              F7 (depósito sin juego); agrega Score, Country, Reward_Plan a la salida;
              nuevos parámetros MaxCPAperMonth, DepositMargin, MaxDeposit;
              excluye jugadores con Deposits > MaxDeposit;
              recalcula F3 a nivel agregado de jugador
*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DROP PROCEDURE IF EXISTS Analisys_customer_report;

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report(IN InputParams VARCHAR(500))
  COMMENT 'Reporte de señales de posible fraude de afiliados sobre customer_report_API_4_analysis v5'
BEGIN
  DECLARE v_MinDeposit        DECIMAL(20,2) DEFAULT 50;
  DECLARE v_MaxDeposit        DECIMAL(20,2) DEFAULT 100;
  DECLARE v_SignupMonth       VARCHAR(7)    DEFAULT NULL;
  DECLARE v_MinTransactions   INT           DEFAULT 2;
  DECLARE v_MaxCPAperMonth    INT           DEFAULT 10;
  DECLARE v_DepositMargin     DECIMAL(5,2)  DEFAULT 1.20;
  DECLARE v_Param             VARCHAR(100);
  DECLARE v_Key               VARCHAR(64);
  DECLARE v_Val               VARCHAR(64);
  DECLARE v_pos               INT;

  SET @Version = 'v5 17.02.2026';

  /* -----------------------------------------------------------------------
     Parseo de parámetros: Key=Value separados por coma
     ----------------------------------------------------------------------- */
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

      IF v_Key = 'maxdeposit' AND v_Val REGEXP '^[0-9]+\\.?[0-9]*$' THEN
        SET v_MaxDeposit = CAST(v_Val AS DECIMAL(20,2));
      END IF;

      IF v_Key = 'signup_month' AND v_Val REGEXP '^[0-9]{4}-[0-9]{2}$' THEN
        SET v_SignupMonth = v_Val;
      END IF;

      IF v_Key = 'mintransactions' AND v_Val REGEXP '^[0-9]+$' THEN
        SET v_MinTransactions = CAST(v_Val AS SIGNED);
      END IF;

      IF v_Key = 'maxcpapermonth' AND v_Val REGEXP '^[0-9]+$' THEN
        SET v_MaxCPAperMonth = CAST(v_Val AS SIGNED);
      END IF;

      IF v_Key = 'depositmargin' AND v_Val REGEXP '^[0-9]+\\.?[0-9]*$' THEN
        SET v_DepositMargin = CAST(v_Val AS DECIMAL(5,2));
      END IF;
    END IF;
  END WHILE;

  /* -----------------------------------------------------------------------
     CTE principal: normalización, flags, agregación
     ----------------------------------------------------------------------- */
  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v5;
  CREATE TEMPORARY TABLE tmp_fraud_detail_v5 AS
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
      COALESCE(r.Deposits,          0) AS dep,
      COALESCE(r.Turnover,          0) AS turn,
      COALESCE(r.Payouts,           0) AS pay,
      COALESCE(r.Total_Net_Revenue, 0) AS tnr,
      COALESCE(r.Transactions,      0) AS txn,
      (CASE WHEN NULLIF(TRIM(r.CPA_Processed_Date), '') IS NOT NULL THEN 1 ELSE 0 END) AS cpa_triggered,
      CASE
        WHEN r.Signup_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 10), '%Y-%m-%d')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d-%m-%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.Signup_Date), '%d/%m/%Y')
        WHEN r.Signup_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}'   THEN STR_TO_DATE(LEFT(TRIM(r.Signup_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS signup_date_parsed,
      CASE
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN STR_TO_DATE(LEFT(TRIM(r.CPA_Processed_Date), 10), '%Y-%m-%d')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}' THEN STR_TO_DATE(TRIM(r.CPA_Processed_Date), '%d-%m-%Y')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}' THEN STR_TO_DATE(TRIM(r.CPA_Processed_Date), '%d/%m/%Y')
        WHEN r.CPA_Processed_Date REGEXP '^[0-9]{4}[0-9]{2}[0-9]{2}'   THEN STR_TO_DATE(LEFT(TRIM(r.CPA_Processed_Date), 8), '%Y%m%d')
        ELSE NULL
      END AS cpa_date_parsed
    FROM customer_report_API_4_analysis r
    WHERE r.`Date`<DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
  ),
  with_months AS (
    SELECT
      n.*,
      DATE_FORMAT(n.`Date`,             '%Y-%m') AS report_month,
      DATE_FORMAT(n.signup_date_parsed, '%Y-%m') AS signup_month
    FROM normalized n
  ),
  filtered AS (
    SELECT *
    FROM with_months
    WHERE cpa_triggered = 1
      AND (v_SignupMonth IS NULL OR signup_month >= v_SignupMonth)
  ),

  /* --- Actividad posterior al mes del reporte (para F2) --- */
  has_later_activity AS (
    SELECT
      c.Customer_ID,
      c.Affiliate_id,
      c.MS_id,
      c.report_month,
      MAX(
        CASE
          WHEN w.`Date` > LAST_DAY(STR_TO_DATE(CONCAT(c.report_month, '-01'), '%Y-%m-%d'))
           AND (COALESCE(w.dep, 0) > 0 OR COALESCE(w.pay, 0) > 0
                OR COALESCE(w.turn, 0) > 0 OR COALESCE(w.tnr, 0) <> 0)
          THEN 1 ELSE 0
        END
      ) AS has_later
    FROM filtered c
    LEFT JOIN with_months w
      ON  w.Customer_ID  = c.Customer_ID
      AND w.Affiliate_id = c.Affiliate_id
      AND w.MS_id        = c.MS_id
    GROUP BY c.Customer_ID, c.Affiliate_id, c.MS_id, c.report_month
  ),

  /* --- País principal por afiliado (para F4) --- */
  aff_primary_country AS (
    SELECT
      Affiliate_id,
      Country AS primary_country
    FROM (
      SELECT
        Affiliate_id,
        Country,
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (PARTITION BY Affiliate_id ORDER BY COUNT(*) DESC) AS rn
      FROM customer_report_API_4_analysis
      WHERE Country IS NOT NULL AND Country <> ''
      GROUP BY Affiliate_id, Country
    ) ranked
    WHERE rn = 1
  ),

  /* --- Conteo de CPAs por afiliado y mes (para F6) --- */
  cpa_velocity AS (
    SELECT
      f.Affiliate_id,
      DATE_FORMAT(f.cpa_date_parsed, '%Y-%m') AS cpa_month,
      COUNT(DISTINCT f.Customer_ID) AS cpa_count
    FROM filtered f
    WHERE f.cpa_date_parsed IS NOT NULL
    GROUP BY f.Affiliate_id, DATE_FORMAT(f.cpa_date_parsed, '%Y-%m')
  ),

  /* --- Flags a nivel de fila --- */
  fraud_flags AS (
    SELECT
      c.Affiliate,
      c.Affiliate_id,
      c.Brand,
      c.MS_id,
      c.Customer_ID,
      c.Customer_alias,
      c.Country,
      c.Signup_Date,
      c.Reward_Plan,
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
      c.signup_date_parsed,

      /* F1: Deposit-withdrawal cycling (Payouts >= Deposits, Turnover <= Deposits)
         Bonus abuse networks: reclaman bono, cumplen playthrough mínimo, retiran */
      CASE
        WHEN c.pay >= c.dep
         AND c.turn <= c.dep
         AND c.dep > 0
        THEN 1 ELSE 0
      END AS F1,

      /* F2: Jugador fantasma — depósito bajo + sin actividad posterior
         Fake players / incentivized users que depositan mínimo y desaparecen */
      CASE
        WHEN c.dep < v_MinDeposit
         AND COALESCE(h.has_later, 0) = 0
        THEN 1 ELSE 0
      END AS F2,

      /* F4: Multi-geo anomaly — país del jugador distinto al país principal del afiliado */
      CASE
        WHEN c.Country IS NOT NULL AND c.Country <> ''
         AND pc.primary_country IS NOT NULL
         AND c.Country <> pc.primary_country
        THEN 1 ELSE 0
      END AS F4,

      /* F6: High CPA velocity — afiliado disparó más de MaxCPAperMonth en un mismo mes */
      CASE
        WHEN cv.cpa_count > v_MaxCPAperMonth
        THEN 1 ELSE 0
      END AS F6,

      /* F7: Depósito sin juego — Deposits > 0 pero Turnover = 0 */
      CASE
        WHEN c.dep > 0 AND c.turn = 0
        THEN 1 ELSE 0
      END AS F7

    FROM filtered c
    LEFT JOIN has_later_activity h
      ON  h.Customer_ID  = c.Customer_ID
      AND h.Affiliate_id = c.Affiliate_id
      AND h.MS_id        = c.MS_id
      AND h.report_month = c.report_month
    LEFT JOIN aff_primary_country pc
      ON  pc.Affiliate_id = c.Affiliate_id
    LEFT JOIN cpa_velocity cv
      ON  cv.Affiliate_id = c.Affiliate_id
      AND cv.cpa_month    = DATE_FORMAT(c.cpa_date_parsed, '%Y-%m')
  ),

  /* --- Agregación a nivel de jugador (Affiliate_id, MS_id, Customer_ID) --- */
  per_player AS (
    SELECT
      Affiliate_id,
      MS_id,
      Customer_ID,
      ANY_VALUE(Affiliate)          AS Affiliate,
      ANY_VALUE(Brand)              AS Brand,
      ANY_VALUE(Country)            AS Country,
      ANY_VALUE(Signup_Date)        AS Signup_Date,
      ANY_VALUE(Reward_Plan)        AS Reward_Plan,
      ANY_VALUE(CPA_Processed_Date) AS CPA_Processed_Date,
      SUM(dep)                      AS Deposits,
      SUM(turn)                     AS Turnover,
      SUM(pay)                      AS Payouts,
      SUM(txn)                      AS Transactions,
      SUM(tnr)                      AS Total_Net_Revenue,

      MAX(F1)  AS F1,
      MAX(F2)  AS F2,
      /* F3 recalculado: pocas transacciones globales (CPA farming) */
      CASE WHEN SUM(txn) <= v_MinTransactions AND SUM(dep) > 0 THEN 1 ELSE 0 END AS F3,
      MAX(F4)  AS F4,
      /* F5 recalculado: depósito total cercano al umbral (deposit-to-threshold) */
      CASE WHEN SUM(dep) > 0 AND SUM(dep) <= v_MinDeposit * v_DepositMargin THEN 1 ELSE 0 END AS F5,
      MAX(F6)  AS F6,
      /* F7 recalculado: depósito total > 0 pero turnover global = 0 */
      CASE WHEN SUM(dep) > 0 AND SUM(turn) = 0 THEN 1 ELSE 0 END AS F7,

      ANY_VALUE(Tracker_id)         AS Tracker_id,
      ANY_VALUE(Tracker_Name)       AS Tracker_Name,
      ANY_VALUE(Customer_alias)     AS Customer_alias
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
    F1, F2, F3, F4, F5, F6, F7,
    (F1 + F2 + F3 + F4 + F5 + F6 + F7) AS Score,
    Country,
    Reward_Plan,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM per_player
  WHERE (F1 + F2 + F3 + F4 + F5 + F6 + F7) >= 1
    AND Deposits <= v_MaxDeposit;

  /* -----------------------------------------------------------------------
     Resultado final: ordenado por Affiliate_id, agrupado lógicamente
     ----------------------------------------------------------------------- */
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
    F1, F2, F3, F4, F5, F6, F7,
    Score,
    Country,
    Reward_Plan,
    Tracker_id,
    Tracker_Name,
    Customer_alias
  FROM tmp_fraud_detail_v5
  ORDER BY Affiliate, Brand, MS_id, Customer_ID;

  DROP TEMPORARY TABLE IF EXISTS tmp_fraud_detail_v5;
END$$
DELIMITER ;
