/*
PROCEDURE_Report_Util_Settings_Update_v1.sql

Descripcion:
  Actualiza una fila de la tabla util_settings por id.

Parametros:
  InputCommLine con pares Key=Value, separados por coma.
  Keys:
    id        = id de la fila a actualizar (obligatorio)
    Value_01  = nuevo valor para Value_01 (opcional)
    Value_02  = nuevo valor para Value_02 (opcional)
    Value_03  = nuevo valor para Value_03 (opcional)
    User      = usuario/operador que realiza el cambio (opcional)
    Debug     = [NO | YES] opcional. Default NO.

Resultado:
  Devuelve una fila con:
    Status = 0  -> OK
    Status = 1  -> Error

Historial de versiones:
  24.04.2026 v1.0 Version inicial.
  27.04.2026      Se migra a util_settings y se agrega columna Show_enabled.

Uso:
  CALL Report_Util_Settings_Update('id=1,Value_01=A,Value_02=B,Value_03=C,User=admin,Debug=Yes');
  CALL Report_Util_Settings_Update('id=1,Value_01=Plan Premium,Value_02=Canal Web,Value_03=Activo,User=Juan Perez,Debug=Yes');
  CALL Report_Util_Settings_Update('id=1,Value_01="Plan Premium",Value_02=''Canal Web'',Value_03="Activo",User=''Juan Perez'',Debug=Yes');
  CALL Report_Util_Settings_Update('id=1,Value_01="Madrid, Centro",Value_02="EUR,USD",Value_03=''Con coma, interior'',User="Juan Perez",Debug=Yes');
*/


DROP PROCEDURE IF EXISTS Report_Util_Settings_Update;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Util_Settings_Update`(
   IN InputCommLine VARCHAR(250)
)
COMMENT 'v1.0 27.04.2026 - Update de util_settings por id'
SQL SECURITY DEFINER
proc_main:BEGIN

DECLARE v_Version VARCHAR(32);
DECLARE v_Status INT;
DECLARE v_Exists INT;
DECLARE v_InputLine VARCHAR(300);
DECLARE v_e INT;
DECLARE v_c INT;
DECLARE v_i INT;
DECLARE v_len INT;
DECLARE v_quote CHAR(1);
DECLARE v_ch CHAR(1);
DECLARE v_k VARCHAR(64);
DECLARE v_v VARCHAR(200);
DECLARE v_Debug VARCHAR(10);
DECLARE p_id INT;
DECLARE p_Value_01 VARCHAR(50);
DECLARE p_Value_02 VARCHAR(50);
DECLARE p_Value_03 VARCHAR(50);
DECLARE p_User VARCHAR(30);

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
   ROLLBACK;
   SELECT 1 AS `Status`;
END;

SET v_Version = 'v1.0 27.04.2026';
SET v_Status = 0;
SET v_Exists = 0;
SET v_e = 0;
SET v_c = 0;
SET v_i = 0;
SET v_len = 0;
SET v_quote = '';
SET v_ch = '';
SET v_k = '';
SET v_v = '';
SET v_Debug = 'NO';
SET p_id = 0;
SET p_Value_01 = '';
SET p_Value_02 = '';
SET p_Value_03 = '';
SET p_User = '';

SET v_InputLine = CONCAT(TRIM(IFNULL(InputCommLine,'')), ',');

parse_kv: WHILE INSTR(v_InputLine,'=') > 0 AND INSTR(v_InputLine,',') > 0 DO
   SET v_e = INSTR(v_InputLine,'=');
   SET v_len = CHAR_LENGTH(v_InputLine);
   SET v_c = 0;
   SET v_quote = '';
   SET v_i = v_e + 1;

   scan_value: WHILE v_i <= v_len DO
      SET v_ch = SUBSTRING(v_InputLine, v_i, 1);

      IF v_ch = '"' OR v_ch = "'" THEN
         IF v_quote = '' THEN
            SET v_quote = v_ch;
         ELSEIF v_quote = v_ch THEN
            SET v_quote = '';
         END IF;
      ELSEIF v_ch = ',' AND v_quote = '' THEN
         SET v_c = v_i;
         LEAVE scan_value;
      END IF;

      SET v_i = v_i + 1;
   END WHILE scan_value;

   IF v_c = 0 THEN
      SET v_c = v_len + 1;
   END IF;

   SET v_k = TRIM(SUBSTRING(v_InputLine,1,v_e-1));
   -- Se eliminan solo espacios de borde; se conservan espacios interiores.
   SET v_v = TRIM(SUBSTRING(v_InputLine,v_e+1,v_c-(v_e+1)));
   -- Si el valor viene entre comillas simples o dobles, quitar solo las comillas externas.
   IF (LEFT(v_v,1)='"' AND RIGHT(v_v,1)='"') OR (LEFT(v_v,1)="'" AND RIGHT(v_v,1)="'") THEN
      SET v_v = SUBSTRING(v_v,2,CHAR_LENGTH(v_v)-2);
      SET v_v = TRIM(v_v);
   END IF;
   SET v_InputLine = SUBSTRING(v_InputLine,v_c+1);

   IF LOWER(v_k)='id' THEN SET p_id = CAST(IFNULL(v_v,'0') AS UNSIGNED); END IF;
   IF LOWER(v_k)='value_01' THEN SET p_Value_01 = NULLIF(v_v,''); END IF;
   IF LOWER(v_k)='value_02' THEN SET p_Value_02 = NULLIF(v_v,''); END IF;
   IF LOWER(v_k)='value_03' THEN SET p_Value_03 = NULLIF(v_v,''); END IF;
   IF LOWER(v_k)='user' THEN SET p_User = NULLIF(v_v,''); END IF;
   IF LOWER(v_k)='debug' THEN SET v_Debug = UPPER(NULLIF(v_v,'')); END IF;
END WHILE parse_kv;

IF IFNULL(v_Debug,'NO') <> 'NO' THEN
   SELECT
      InputCommLine AS InputCommLine;

   SELECT
      p_id AS `id`,
      p_Value_01 AS `Value_01`,
      p_Value_02 AS `Value_02`,
      p_Value_03 AS `Value_03`,
      p_User AS `User`,
      v_Debug AS `Debug`;

   SELECT 0 AS `Status`;
   LEAVE proc_main;
END IF;

IF IFNULL(p_id, 0) <= 0 THEN
   SELECT 1 AS `Status`;
   LEAVE proc_main;
END IF;

START TRANSACTION;

SELECT COUNT(1)
  INTO v_Exists
  FROM util_settings
 WHERE id = p_id;

IF v_Exists = 0 THEN
   SET v_Status = 1;
ELSE
   UPDATE util_settings
      SET Value_01 = p_Value_01,
          Value_02 = p_Value_02,
          Value_03 = p_Value_03,
          Operator = p_User     
    WHERE id = p_id;

   IF ROW_COUNT() <> 1 THEN
      SET v_Status = 1;
   END IF;
END IF;

IF v_Status = 0 THEN
   COMMIT;
ELSE
   ROLLBACK;
END IF;

-- SELECT v_Status AS `Status`;

END$$
DELIMITER ;
