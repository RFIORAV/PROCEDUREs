/*
PROCEDURE_Cap_excess_by_level_Set_Status_v1.sql

Descripción:
  Acumula Qualified_Players (CPA) del mes corriente desde Snapshot_day_by_day_fact1
  (excluye filas con Origin='manual') y pone Status_id='6' (Paused auto NM) en cada
  nivel cuyo acumulado alcance o supere el 89% de su CPA_Limit.

  Niveles procesados (MS excluido — se gestiona en Cap_excess_to_DbD_manual):
    Operator  → campaign_publisher   (Publisher_id)
    Brand     → campaign_advertiser  (Advertiser_id)
    Account   → campaign_username    (Username_id)
    Affiliate → account_account      (Affiliate_id)

  Cada Key debe estar seguida de = y el valor deseado SIN comillas.
  Cada par Key=Value debe ir seguido de una COMA.
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string.

Keys:
  Debug = [No | Yes | KeyValues]. Modo depuración. OPCIONAL. Default=No.
          Yes       → devuelve registros que se pausarían SIN ejecutar UPDATE.
          KeyValues → devuelve parámetros parseados y ejecuta normalmente.

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  call Cap_excess_by_level_Set_Status('');
  call Cap_excess_by_level_Set_Status('Debug=Yes');
  call Cap_excess_by_level_Set_Status('Debug=KeyValues');

12.06.2026 v1  Primera versión operativa
*/

DROP PROCEDURE IF EXISTS Cap_excess_by_level_Set_Status;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Cap_excess_by_level_Set_Status`(IN InputCommLine VARCHAR(250))
COMMENT 'v1 12.06.2026 - Pausa automática (Status_id=6) por exceso de CPA a nivel Operator/Brand/Account/Affiliate'
SQL SECURITY DEFINER

proc_label:BEGIN

  DECLARE v_Version        VARCHAR(32)  DEFAULT 'v1 12.06.2026';
  DECLARE v_Month          VARCHAR(7)   DEFAULT '';
  DECLARE v_Debug          VARCHAR(20)  DEFAULT 'NO';
  DECLARE v_EnforceCapCPA  VARCHAR(20)  DEFAULT 'NO';
  DECLARE v_Margen_Limit   DECIMAL(4,2) DEFAULT 0.89;
  DECLARE v_InputCommLine  VARCHAR(252) DEFAULT '';
  DECLARE v_e              INT          DEFAULT 0;
  DECLARE v_c              INT          DEFAULT 0;
  DECLARE v_k              VARCHAR(100) DEFAULT '';
  DECLARE v_v              VARCHAR(100) DEFAULT '';
  DECLARE v_Error          INT          DEFAULT 0;
  DECLARE v_Msg            VARCHAR(250) DEFAULT '';

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_Msg = MESSAGE_TEXT;
    SET v_Error = 1;
    SELECT v_Version AS Version, v_Error AS Error, v_Msg AS Message;
  END;

  -- ── Mes corriente (fijo) ──────────────────────────────────────────────────────
  SET v_Month = LEFT(CURDATE(), 7);

  -- ── Parseo InputCommLine ──────────────────────────────────────────────────────
  SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
  SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

  WHILE v_InputCommLine > ' ' DO
    SET v_e = INSTR(v_InputCommLine, '=');
    SET v_c = INSTR(v_InputCommLine, ',');
    SET v_k = UPPER(TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1)));
    SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
    SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

    IF LOWER(v_k) = 'debug' THEN
      SET v_Debug = UPPER(v_v);
    END IF;
  END WHILE;

  IF v_Debug = 'KEYVALUES' THEN
    SELECT
      v_Version   AS Version,
      InputCommLine,
      v_Month     AS Month,
      v_Debug     AS Debug;
  END IF;

  -- ── Control global de Cap CPA ─────────────────────────────────────────────────
  SET v_EnforceCapCPA = (SELECT IFNULL(`Value_01`, 'NO') FROM `util_settings` WHERE Setting = 'EnforceCapCPA');

  IF v_EnforceCapCPA = 'NO' THEN
    LEAVE proc_label;
  END IF;

  -- ── Vista previa sin UPDATE ───────────────────────────────────────────────────
  IF v_Debug = 'YES' THEN
    WITH cpa_operator AS (
      SELECT
        F.Publisher_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(P.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_publisher` P ON P.id = F.Publisher_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Publisher_id, P.CPA_Limit
    ),
    cpa_brand AS (
      SELECT
        F.Advertiser_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(B.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_advertiser` B ON B.id = F.Advertiser_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Advertiser_id, B.CPA_Limit
    ),
    cpa_account AS (
      SELECT
        F.Username_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        IFNULL(U.CPA_Limit, 0) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_username` U ON U.id = F.Username_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Username_id, U.CPA_Limit
    ),
    cpa_affiliate AS (
      SELECT
        F.Affiliate_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(A.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `account_account` A ON A.id = F.Affiliate_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Affiliate_id, A.CPA_Limit
    )
    SELECT
      'Operator' AS Nivel,
      C.Publisher_id AS Entity_id,
      P.Advertiser_Name AS Entity_name,
      C.CPA_acum,
      C.CPA_Limit,
      P.Status_id AS Status_id_actual
    FROM cpa_operator C
    INNER JOIN `campaign_publisher` P ON P.id = C.Publisher_id
    WHERE C.CPA_Limit > 0
      AND ROUND(C.CPA_Limit * v_Margen_Limit, 0) <= C.CPA_acum
      AND P.Status_id = '1'

    UNION ALL

    SELECT
      'Brand' AS Nivel,
      C.Advertiser_id AS Entity_id,
      B.Advertiser_Name AS Entity_name,
      C.CPA_acum,
      C.CPA_Limit,
      B.Status_id AS Status_id_actual
    FROM cpa_brand C
    INNER JOIN `campaign_advertiser` B ON B.id = C.Advertiser_id
    WHERE C.CPA_Limit > 0
      AND ROUND(C.CPA_Limit * v_Margen_Limit, 0) <= C.CPA_acum
      AND B.Status_id = '1'

    UNION ALL

    SELECT
      'Account' AS Nivel,
      C.Username_id AS Entity_id,
      U.Username AS Entity_name,
      C.CPA_acum,
      C.CPA_Limit,
      U.Status_id AS Status_id_actual
    FROM cpa_account C
    INNER JOIN `campaign_username` U ON U.id = C.Username_id
    WHERE C.CPA_Limit > 0
      AND ROUND(C.CPA_Limit * v_Margen_Limit, 0) <= C.CPA_acum
      AND U.Status_id = '1'

    UNION ALL

    SELECT
      'Affiliate' AS Nivel,
      C.Affiliate_id AS Entity_id,
      A.username AS Entity_name,
      C.CPA_acum,
      C.CPA_Limit,
      A.Status_id AS Status_id_actual
    FROM cpa_affiliate C
    INNER JOIN `account_account` A ON A.id = C.Affiliate_id
    WHERE C.CPA_Limit > 0
      AND ROUND(C.CPA_Limit * v_Margen_Limit, 0) <= C.CPA_acum
      AND A.Status_id = '1'
    ORDER BY Nivel, Entity_id;

  ELSE
    START TRANSACTION;

    UPDATE `campaign_publisher` P
    INNER JOIN (
      SELECT
        F.Publisher_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(P2.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_publisher` P2 ON P2.id = F.Publisher_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Publisher_id, P2.CPA_Limit
      HAVING CPA_Limit > 0 AND ROUND(CPA_Limit * v_Margen_Limit, 0) <= CPA_acum
    ) C ON C.Publisher_id = P.id
    SET P.Status_id = '6'
    WHERE P.Status_id = '1';

    UPDATE `campaign_advertiser` B
    INNER JOIN (
      SELECT
        F.Advertiser_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(B2.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_advertiser` B2 ON B2.id = F.Advertiser_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Advertiser_id, B2.CPA_Limit
      HAVING CPA_Limit > 0 AND ROUND(CPA_Limit * v_Margen_Limit, 0) <= CPA_acum
    ) C ON C.Advertiser_id = B.id
    SET B.Status_id = '6'
    WHERE B.Status_id = '1';

    UPDATE `campaign_username` U
    INNER JOIN (
      SELECT
        F.Username_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        IFNULL(U2.CPA_Limit, 0) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `campaign_username` U2 ON U2.id = F.Username_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Username_id, U2.CPA_Limit
      HAVING CPA_Limit > 0 AND ROUND(CPA_Limit * v_Margen_Limit, 0) <= CPA_acum
    ) C ON C.Username_id = U.id
    SET U.Status_id = '6'
    WHERE U.Status_id = '1';

    UPDATE `account_account` A
    INNER JOIN (
      SELECT
        F.Affiliate_id,
        SUM(IFNULL(F.Qualified_Players, 0)) AS CPA_acum,
        CAST(IFNULL(A2.CPA_Limit, 0) AS UNSIGNED) AS CPA_Limit
      FROM `Snapshot_day_by_day_fact1` F
      INNER JOIN `account_account` A2 ON A2.id = F.Affiliate_id
      WHERE LEFT(F.`Date`, 7) = v_Month
        AND IFNULL(F.Origin, '') <> 'manual'
        AND IFNULL(F.Affiliate_id, 0) > 1
      GROUP BY F.Affiliate_id, A2.CPA_Limit
      HAVING CPA_Limit > 0 AND ROUND(CPA_Limit * v_Margen_Limit, 0) <= CPA_acum
    ) C ON C.Affiliate_id = A.id
    SET A.Status_id = '6'
    WHERE A.Status_id = '1';

    IF v_Error = 0 THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
  END IF;

END$$
DELIMITER ;

/*
call Cap_excess_by_level_Set_Status('');
call Cap_excess_by_level_Set_Status('Debug=Yes');
call Cap_excess_by_level_Set_Status('Debug=KeyValues');
*/
