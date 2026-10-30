/*
PROCEDURE_Check_RS_affiliate_v1.sql

Descripción:
  Indica si un afiliado tiene al menos un Marketing Source con Stat_aggreg
  en (1,4,6) y Deal con RS_Percentage > 0. Devuelve RS_Status = 1/0.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  Affiliate_id = [id]. Id del afiliado a comprobar. OBLIGATORIO.
  Debug        = [No | Yes | KeyValues]. OPCIONAL. Default=No.

Parámetros ('[Key=Value[,...]]')

Ejemplos:
  CALL Check_RS_affiliate('Affiliate_id=39');
  CALL Check_RS_affiliate('Affiliate_id=39,Debug=KeyValues');

16.07.2026 v1 Primera versión operativa
*/

SET NAMES 'utf8mb4';

DROP PROCEDURE IF EXISTS Check_RS_affiliate;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Check_RS_affiliate`(IN InputCommLine VARCHAR(250))
COMMENT 'v1 16.07.2026 - Devuelve RS_Status 0/1 si el afiliado tiene MS con Revenue Share activo'
SQL SECURITY DEFINER
proc_label:BEGIN
    DECLARE v_Version       VARCHAR(32)  DEFAULT 'v1 16.07.2026';
    DECLARE v_InputCommLine VARCHAR(400) DEFAULT '';
    DECLARE v_Debug         VARCHAR(20)  DEFAULT 'NO';
    DECLARE v_Affiliate_id  INT          DEFAULT NULL;
    DECLARE v_RS_Status     TINYINT      DEFAULT 0;
    DECLARE v_e             INT          DEFAULT 0;
    DECLARE v_c             INT          DEFAULT 0;
    DECLARE v_k             VARCHAR(80)  DEFAULT '';
    DECLARE v_v             VARCHAR(250) DEFAULT '';

    SET v_InputCommLine = IFNULL(InputCommLine, '');
    SET v_InputCommLine = CONCAT(v_InputCommLine, ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' AND INSTR(v_InputCommLine, '=') > 0 DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');
        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'affiliate_id' THEN
            SET v_Affiliate_id = CAST(NULLIF(v_v, '') AS SIGNED);
        ELSEIF LOWER(v_k) = 'debug' THEN
            SET v_Debug = UPPER(v_v);
        END IF;
    END WHILE;

    IF v_Affiliate_id IS NULL OR v_Affiliate_id <= 0 THEN
        SELECT CONCAT('ERROR: Affiliate_id obligatorio y debe ser > 0. Recibido: [',
                      IFNULL(InputCommLine, ''), '].') AS Mensaje;
        LEAVE proc_label;
    END IF;

    IF v_Debug = 'KEYVALUES' THEN
        SELECT 'Affiliate_id' AS `Key`, CAST(v_Affiliate_id AS CHAR) AS `Value`
        UNION ALL SELECT 'Debug', v_Debug
        UNION ALL SELECT 'Version', v_Version;
        LEAVE proc_label;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM `campaign_marketing_source` m
        INNER JOIN `campaign_deal_affiliate` d ON d.id = m.Deal_id
        WHERE m.Affiliate_id = v_Affiliate_id
          AND m.Stat_aggreg IN ('6', '1', '4')
          AND IFNULL(d.RS_Percentage, 0) > 0
    ) INTO v_RS_Status;

    SELECT
        v_Affiliate_id AS Affiliate_id,
        v_RS_Status    AS RS_Status;
        
END$$
DELIMITER ;
