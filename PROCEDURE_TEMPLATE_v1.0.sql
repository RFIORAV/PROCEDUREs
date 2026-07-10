/*
PROCEDURE_TEMPLATE_v1.1.sql

Descripción:
  Procedimiento Procedure_Template.

Observaciones:
 Plantilla base para crear Stored Procedures de reporte compatibles con MySQL 8.0.37
 Cada Key debe estar seguida de = y el valor deseado SIN comillas
 Cada par Key=Value debe ir seguido de una COMA
 El conjunto de pares debe ir entre '' (comillas simples) como unico parametro string

Keys:
 Debug = [No | Yes | KeyValues]. Controla modo de ejecucion. OPCIONAL. Default=No.
 Filters = [No | Yes]. Devuelve lista de filtros en lugar de datos. OPCIONAL. Default=No.
 Meta = [No | Yes]. Incluye fila de metadatos de renderizado. OPCIONAL. Default=Yes.
 Data_Month = [YYYY-MM]. Mes de datos. OPCIONAL. Default=mes actual.
 Brand = [ValorA ^ ValorB ^ ValorC]. Filtro multivalor separado por ^. OPCIONAL.
 InputCommLine = [valor]. Parámetro de entrada.

Parametros ('[Key=Value[,...]]')

Ejemplos:
 call Procedure_Template('Debug=Yes');
 call Procedure_Template('Data_Month=2026-04,Debug=No');
 call Procedure_Template('Brand=Sport^Casino,Meta=Yes,Filters=No');

11.03.2026 v1.0 Creacion de plantilla base
14.04.2026 v1.1 Adecuacion al estandar AGENTS.md (InputCommLine, Keys, Filters y Meta)
*/

SET NAMES 'utf8mb4';

DROP PROCEDURE IF EXISTS Procedure_Template;
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Procedure_Template`(IN InputCommLine VARCHAR(250))
COMMENT 'Plantilla base de SP de reporte con parseo Key=Value y soporte Debug/Filters/Meta'
SQL SECURITY DEFINER
proc_label:BEGIN
    DECLARE v_Version VARCHAR(32) DEFAULT 'v1.1 14.04.2026';
    DECLARE v_InputCommLine VARCHAR(400);
    DECLARE v_Debug VARCHAR(20) DEFAULT 'NO';
    DECLARE v_Filters VARCHAR(5) DEFAULT 'NO';
    DECLARE v_Meta VARCHAR(5) DEFAULT 'YES';
    DECLARE v_Data_Month CHAR(7) DEFAULT DATE_FORMAT(CURDATE(), '%Y-%m');
    DECLARE v_Brand VARCHAR(200) DEFAULT '';
    DECLARE v_e INT DEFAULT 0;
    DECLARE v_c INT DEFAULT 0;
    DECLARE v_k VARCHAR(80) DEFAULT '';
    DECLARE v_v VARCHAR(250) DEFAULT '';

    -- Normalizacion de entrada (Key=Value,Key=Value)
    SET v_InputCommLine = IFNULL(InputCommLine, '');
    SET v_InputCommLine = CONCAT(v_InputCommLine, ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

    -- Parseo case-insensitive de parametros
    WHILE v_InputCommLine > ' ' DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');

        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE;
        END IF;

        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = UPPER(TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1))));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        IF LOWER(v_k) = 'debug' THEN
            SET v_Debug = v_v;
        ELSEIF LOWER(v_k) = 'filters' THEN
            SET v_Filters = v_v;
        ELSEIF LOWER(v_k) = 'meta' THEN
            SET v_Meta = v_v;
        ELSEIF LOWER(v_k) = 'data_month' THEN
            SET v_Data_Month = LEFT(v_v, 7);
        ELSEIF LOWER(v_k) = 'brand' THEN
            SET v_Brand = v_v;
        END IF;
    END WHILE;

    -- Validaciones base de parametros
    IF CHAR_LENGTH(v_Data_Month) <> 7
       OR SUBSTRING(v_Data_Month, 5, 1) <> '-'
       OR STR_TO_DATE(CONCAT(v_Data_Month, '-01'), '%Y-%m-%d') IS NULL THEN
        SELECT CONCAT('ERROR: Data_Month invalido [', IFNULL(v_Data_Month, ''), ']. Formato esperado: YYYY-MM.') AS Mensaje;
        LEAVE proc_label;
    END IF;

    IF v_Debug = 'KEYVALUES' THEN
        SELECT 'Debug' AS `Key`, v_Debug AS `Value`
        UNION ALL SELECT 'Filters', v_Filters
        UNION ALL SELECT 'Meta', v_Meta
        UNION ALL SELECT 'Data_Month', v_Data_Month
        UNION ALL SELECT 'Brand', v_Brand
        UNION ALL SELECT 'Version', v_Version;
        LEAVE proc_label;
    END IF;

    -- Patron Filters: devolver lista de filtros disponibles
    IF v_Filters = 'YES' THEN
        SELECT '01' AS Korder, 'Data Month' AS `Key`, v_Data_Month AS `Value`, 'Data_Month' AS Caption, v_Data_Month AS id, '' AS extra
        UNION ALL
        SELECT '02', 'Brand', 'Sport', 'Brand', 'Sport', ''
        UNION ALL
        SELECT '02', 'Brand', 'Casino', 'Brand', 'Casino', ''
        ORDER BY Korder ASC, `Value` ASC;
        LEAVE proc_label;
    END IF;

    -- Patron Meta: setting / data / total
    SELECT * FROM (
        SELECT
            'setting' AS Meta,
            'width=110px' AS `Data Month`,
            'width=140px,tooltip=yes' AS `Brand`,
            'width=120px,right=true' AS `Gross Revenue`,
            'omit=yes' AS `Internal Id`
        FROM DUAL
        WHERE v_Meta = 'YES'

        UNION ALL

        SELECT
            'data' AS Meta,
            v_Data_Month AS `Data Month`,
            CASE WHEN v_Brand > '' THEN v_Brand ELSE 'ALL' END AS `Brand`,
            '0.00' AS `Gross Revenue`,
            '1' AS `Internal Id`

        UNION ALL

        SELECT
            'total' AS Meta,
            v_Data_Month AS `Data Month`,
            'TOTAL' AS `Brand`,
            '0.00' AS `Gross Revenue`,
            '' AS `Internal Id`
    ) AS Resultado;

    IF v_Debug = 'YES' THEN
        SELECT
            v_Version AS Version,
            v_Data_Month AS Data_Month,
            v_Brand AS Brand,
            v_Filters AS Filters,
            v_Meta AS Meta;
    END IF;
END$$
DELIMITER ;
