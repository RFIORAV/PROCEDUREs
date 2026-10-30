/*
FUNCTION_Check_RS_affiliate.sql

Descripción:
  Indica si un afiliado tiene al menos un Marketing Source con Stat_aggreg
  en (1,4,6) y Deal con RS_Percentage > 0. Devuelve 1/0.

Parámetros:
  Affiliate_id - Id del afiliado a comprobar. OBLIGATORIO (> 0).

Ejemplos:
  SELECT Check_RS_affiliate(39);
  SELECT Check_RS_affiliate(39) AS RS_Status;

20.07.2026 v1 Primera versión operativa (desde Check_RS_affiliate SP)
*/

DROP FUNCTION IF EXISTS Check_RS_affiliate;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` FUNCTION `Check_RS_affiliate`(Affiliate_id INT) RETURNS INT
   COMMENT 'v1 20.07.2026 - Devuelve 0/1 si el afiliado tiene MS con Revenue Share activo'
   LANGUAGE SQL
   READS SQL DATA
   SQL SECURITY DEFINER
BEGIN
    DECLARE v_Version   VARCHAR(32) DEFAULT 'v1 20.07.2026';
    DECLARE v_RS_Status INT         DEFAULT 0;

    IF Affiliate_id IS NULL OR Affiliate_id <= 0 THEN
        RETURN 0;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM `campaign_marketing_source` m
        INNER JOIN `campaign_deal_affiliate` d ON d.id = m.Deal_id
        WHERE m.Affiliate_id = Affiliate_id
          AND m.Stat_aggreg IN ('6', '1', '4')
          AND IFNULL(d.RS_Percentage, 0) > 0
    ) INTO v_RS_Status;

    RETURN v_RS_Status;
END$$

DELIMITER ;
