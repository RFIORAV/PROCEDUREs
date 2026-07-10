/*
PROCEDURE_Dash_Notifications_v1.sql

Descripción:
 Devuelve las últimas 15 notificaciones no leídas de `account_notifications`,
 ordenadas por `Date` en forma descendente.
 El SP recibe un único string con formato `Key=Value` separado por comas.
 Actualmente `Month` y `Account_id` se parsean/validan para trazabilidad, pero no
 aplican filtro al `SELECT` final.

Formato de entrada:
 InputCommLine = 'Key=Value,Key=Value,...'
 Reglas:
 - Cada par Key=Value va separado por coma.
 - Las keys no distinguen mayúsculas/minúsculas.
 - Se eliminan comillas dobles si vienen en el input.

Keys:
 Month      = [YYYY-MM]. OPCIONAL. Default = mes actual (`CURDATE()`).
              Se valida formato y fecha.
 Account_id = [id de cuenta]. OPCIONAL. Default = ''.
              Actualmente no aplica filtro en el resultado.
 Debug      = [No | Yes | KeyValues]. OPCIONAL. Default = No.
              - No: devuelve notificaciones.
              - Yes: devuelve notificaciones + un segundo resultset con trazabilidad.
              - KeyValues: devuelve solo los parámetros parseados.

Resultado principal:
 - `id`: identificador de la notificación.
 - `title`: concatenación de `FromUser`, `Type` y `Subtype`.
 - `description`: contenido de `Testo`.
 - `status`: valor de `Status`.
 - `type`: valor de `Type`.
 - `date`: fecha de la notificación.
 - `read`: estado de lectura (`Read_Status`).

Parámetros:
 call Dash_Notifications('[Key=Value[,...]]');

Ejemplos:
 call Dash_Notifications('');
 call Dash_Notifications('Debug=No');
 call Dash_Notifications('Debug=Yes');
 call Dash_Notifications('Debug=KeyValues');
 call Dash_Notifications('Month=2026-05,Account_id=39,Debug=Yes');
 call Dash_Notifications('Month=2026-13'); -- Devuelve error por mes inválido

Log modificaciones:

14.05.2026 V1     Karen. Primera version

*/

DROP PROCEDURE IF EXISTS Dash_Notifications;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_Notifications`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Dash Notifications'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
    DECLARE v_Version VARCHAR(32);
    DECLARE v_InputCommLine VARCHAR(500);
    DECLARE v_Month VARCHAR(7);
    DECLARE v_Account_id VARCHAR(150);
    DECLARE v_Debug VARCHAR(20);
    DECLARE v_e INT;
    DECLARE v_c INT;
    DECLARE v_k VARCHAR(100);
    DECLARE v_v VARCHAR(250);

    SET v_Version = 'v1.0 14.05.2026';
    SET v_Month = LEFT(CURDATE(), 7);
    SET v_Account_id = '';
    SET v_Debug = 'NO';

    SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');

        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE proc_label;
        END IF;

        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'month' THEN SET v_Month = v_v; END IF;
        IF LOWER(v_k) = 'account_id' THEN SET v_Account_id = v_v; END IF;
        IF LOWER(v_k) = 'debug' THEN SET v_Debug = UPPER(v_v); END IF;
    END WHILE;

    IF CHAR_LENGTH(v_Month) <> 7
       OR SUBSTRING(v_Month, 5, 1) <> '-'
       OR STR_TO_DATE(CONCAT(v_Month, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT 'ERROR: Month invalido. Formato esperado YYYY-MM.' AS error_message;
        LEAVE proc_label;
    END IF;


    IF v_Debug = 'KEYVALUES' THEN
        SELECT 'Version' AS `Key`, v_Version AS `Value`
        UNION ALL SELECT 'Month', v_Month
        UNION ALL SELECT 'Account_id', IFNULL(v_Account_id, '')
        UNION ALL SELECT 'Debug', v_Debug;
        LEAVE proc_label;
    END IF;
    
		SELECT
			id,
			CONCAT_WS(
				' - ',
				NULLIF(FromUser, ''),
				NULLIF(Type, ''),
				NULLIF(Subtype, '')
			) AS title,
			Testo as description,
			`Status` as `status`,
			Type as type,
			`Date` as `date`,
			Read_Status as `read`
		FROM
			account_notifications
		WHERE
			Read_Status = 0
		ORDER BY `Date` DESC
		LIMIT 15;

    IF v_Debug = 'YES' THEN
        SELECT
            v_Version AS Version,
            v_Month AS Month,
            IFNULL(v_Account_id, '') AS Account_id;
    END IF;
    
END$$
DELIMITER ;

/* Testing
call Dash_Notifications('');
call Dash_Notifications('Debug=No');
call Dash_Notifications('Debug=Yes');
call Dash_Notifications('Debug=KeyValues');
call Dash_Notifications('Month=2026-05,Account_id=39,Debug=Yes');
call Dash_Notifications('Month=2026-13');
*/