/* PROCEDURE_Compare_DbD_DbD_lm.sql


Descripción:
  Procedimiento Compare_DbD_DbD_lm.
   05.09.2022 V1 COMPARA Snapshot_day_by_day contra Snapshot_day_by_day_lm. Devuelve diferencias
   10.09.2022 v2 Identifica Afiliado
   21.09.2022 v2.1 INSERT por la diferencia y también para reemplazar todos los registros de la cuenta
              v2.2 Hour_Update
              v2.3 Invoca call Sync_MS_DbD_DbD_lm('view');
   Parametros (none)
   05.11.2024 v2.4 No se ejecuta si no hay datos de last month en Snapshot_day_by_day_lm

Keys:
   
*/

DROP PROCEDURE IF EXISTS Compare_DbD_DbD_lm;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE Compare_DbD_DbD_lm()
   COMMENT 'COMPARA Snapshot_day_by_day vs Snapshot_day_by_day_lm'
   LANGUAGE SQL

BEGIN

SET @Version         ='v2.4 05.11.2024';

SET @DatosLM=(SELECT COUNT(*) FROM Snapshot_day_by_day_lm WHERE LEFT(Date,7)=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7));

IF @DatosLM>200
THEN    
	call Sync_MS_DbD_DbD_lm('view');
ELSE
   SELECT "setting" as Meta, "width=100px" as `Last Month`,  "width=500px" as `Remarks` FROM DUAL UNION ALL 
   SELECT "data" as Meta, LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7) as `Month`, "The publisher\'s validated data from last month is not yet available." as `Remarks`  FROM DUAL; 
END IF;   

END$$
DELIMITER ;

-- TEST --------------
-- call Compare_DbD_DbD_lm();
