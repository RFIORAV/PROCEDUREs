/*
PROCEDURE_Report_Util_Settings_v1.1.sql - Reporte de configuracion util_settings_v2

Descripción:
  Procedimiento Report_Util_Settings.

Listado de filas de util_settings_v2 con filtros de visibilidad y edicion.

Parametro compuesto Key=Value (sin comillas en valores), separado por comas.

Keys:
  Meta          = [No | Yes]                 OPCIONAL. Default Yes. Fila Meta=setting con anchos/grid; filas de datos Meta=data.
  EditableOnly  = [No | Yes]                 OPCIONAL. Default No. Si Yes, solo filas con Edit_enabled=1.
  Setting       = [Nombre exacto de setting] OPCIONAL. Si se informa, solo devuelve ese setting.
  Debug         = [No | Yes | KeyValues]     OPCIONAL. Default No.
  InputCommLine = [valor]. Parámetro de entrada.

Historial de versiones:
  09.04.2026 v1.0 Version inicial.
  20.04.2026 v1.1 Se migra a util_settings_v2 y se agregan filtros Show_enabled/EditableOnly.
  21.04.2026 v1.2 Se agrega filtro por nombre de setting (Setting=...).
  27.04.2026      Se migra a util_settings y se agrega columna Show_enabled.
  26.06.2026 v1.3 Se agrega columna Value_01_Options y edit_enabled.

Uso:
  CALL Report_Util_Settings_dev('');
  CALL Report_Util_Settings('Meta=No');
  CALL Report_Util_Settings_dev('EditableOnly=Yes');
  CALL Report_Util_Settings('Setting=Fact2_Date_Limit');
  CALL Report_Util_Settings('Debug=Yes');
*/

DROP PROCEDURE IF EXISTS Report_Util_Settings;
DROP PROCEDURE IF EXISTS Report_Util_Settings_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Util_Settings`(
   IN InputCommLine VARCHAR(250)
)
COMMENT 'v1.3 26.06.2026 - Report: configuracion util_settings'
SQL SECURITY DEFINER
BEGIN

DECLARE v_Version       VARCHAR(32);
DECLARE v_InputLine     VARCHAR(300);
DECLARE v_e             INT;
DECLARE v_c             INT;
DECLARE v_k             VARCHAR(64);
DECLARE v_v             VARCHAR(200);
DECLARE v_Meta          VARCHAR(10);
DECLARE v_EditableOnly  VARCHAR(10);
DECLARE v_Setting       VARCHAR(220);
DECLARE v_Debug         VARCHAR(20);

SET v_Version      = 'v1.3 26.06.2026';
SET v_e            = 0;
SET v_c            = 0;
SET v_k            = '';
SET v_v            = '';
SET v_Meta         = 'YES';
SET v_EditableOnly = 'NO';
SET v_Setting      = '';
SET v_Debug        = 'NO';

SET v_InputLine = CONCAT(REPLACE(TRIM(IFNULL(InputCommLine,'')),'"',''), ',');

parse_kv: WHILE INSTR(v_InputLine,'=') > 0 AND INSTR(v_InputLine,',') > 0 DO
   SET v_e = INSTR(v_InputLine,'=');
   SET v_c = INSTR(v_InputLine,',');
   SET v_k = TRIM(SUBSTRING(v_InputLine,1,v_e-1));
   SET v_v = TRIM(SUBSTRING(v_InputLine,v_e+1,v_c-(v_e+1)));
   SET v_InputLine = SUBSTRING(v_InputLine,v_c+1);

   IF LOWER(v_k)='meta'         THEN SET v_Meta         = UPPER(v_v); END IF;
   IF LOWER(v_k)='editableonly' THEN SET v_EditableOnly = UPPER(v_v); END IF;
   IF LOWER(v_k)='editable_only' THEN SET v_EditableOnly = UPPER(v_v); END IF;
   IF LOWER(v_k)='setting'      THEN SET v_Setting      = v_v; END IF;
   IF LOWER(v_k)='settingname'  THEN SET v_Setting      = v_v; END IF;
   IF LOWER(v_k)='setting_name' THEN SET v_Setting      = v_v; END IF;
   IF LOWER(v_k)='debug'        THEN SET v_Debug        = UPPER(v_v); END IF;
END WHILE parse_kv;

IF v_Debug != 'NO' THEN
   SELECT v_Version, v_Meta, v_EditableOnly, v_Setting, v_Debug, InputCommLine;
END IF;

(SELECT 'setting' AS `Meta`
      ,'omit=true,editkey=Report_Util_Settings_Update:id' AS `id` -- K 12.06.2026
      -- ,'width=220px,sortable=yes,tooltip=yes' AS `Setting`
      ,'width=350px,tooltip=yes' AS `Description`
      ,'width=260px,edit=Report_Util_Settings_Update:value_01,editOptions=value_01_options,editEnabled=edit_enabled' AS `Value 01` -- K 12.06.2026 25.06.2026
      ,'width=220px,tooltip=yes' AS `Value 02`
      ,'width=220px,tooltip=yes' AS `Value 03`
      ,'omit=true' AS `Creation_Date`
      ,'width=130px,sortable=yes,tooltip=yes' AS `Last Update`
      ,'width=100px,sortable=yes,tooltip=yes' AS `User`
      ,'omit=true' AS `value_01_options` -- K 25.06.2026
      ,'omit=true' AS `edit_enabled` -- K 25.06.2026
 FROM DUAL WHERE v_Meta='YES')
UNION ALL
(SELECT 'data' AS `Meta`
      ,U.`id`
      -- ,U.`Setting`
      ,U.`Description`
      ,U.`Value_01`
      ,U.`Value_02`
      ,U.`Value_03`
      ,U.`Creation_Date`
      ,LEFT(U.`Last_Update`,16) AS `Last Update`
      ,U.`Operator` AS `User`
      ,U.Value_01_Options -- K 25.06.2026
      ,U.Edit_enabled  -- K 25.06.2026
 FROM `util_settings` U
 WHERE IFNULL(U.`Show_enabled`,0) = 1
   AND (v_EditableOnly <> 'YES' OR IFNULL(U.`Edit_enabled`,0) = 1)
   AND (v_Setting = '' OR U.`Setting` = v_Setting))
ORDER BY CASE `Meta` WHEN 'setting' THEN 0 ELSE 1 END
       ,`id`;

END$$
DELIMITER ;

/*
CALL Report_Util_Settings('');
CALL Report_Util_Settings('Meta=No');
CALL Report_Util_Settings('EditableOnly=Yes');
CALL Report_Util_Settings('Setting=Fact2_Date_Limit');
CALL Report_Util_Settings('Debug=Yes');
*/
