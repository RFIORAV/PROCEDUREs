/*
PROCEDURE_Report_Cashflow_v2.x.sql - Reporte cashflow por vencimiento (Due_Date)

Descripción:
  Procedimiento Report_Cashflow.

Observaciones:
Parametro unico de entrada estilo Key=Value separado por coma.

Keys:
Meta      =[No | Yes]. OPCIONAL. Columna 1 como METADATO total/data/setting. Default=Yes.
Filters   =[No | Yes]. OPCIONAL. Devuelve lista de filtros disponibles. Default=No.
Debug     =[No | Yes | KeyValues]. OPCIONAL. Default=No.
FromMonth =[AAAA-MM]. OPCIONAL. Mes inicial de la ventana de 12 meses. Default=CM-3.
Owner     =[ALL | Owner | Owner_id]. OPCIONAL. Default=ALL.
DebtSide  =[ALL | OnlyClients | OnlyAffilates   ]. OPCIONAL. Default=ALL.
InputCommLine = [valor]. Parámetro de entrada.

Version history:
26.02.2026 v2.0 Refactor para limpieza y mantenibilidad
10.04.2026 v2.1 Meta/datos: columna nombre publisher (grid) Publisher -> Operator

Usage:
CALL Report_Cashflow('');
CALL Report_Cashflow('frommonth=2026-01,debug=yes');
CALL Report_Cashflow('filters=yes');
CALL Report_Cashflow('debug=yes');
*/

DROP PROCEDURE IF EXISTS Report_Cashflow;

DELIMITER $$
CREATE PROCEDURE Report_Cashflow(
    IN InputCommLine VARCHAR(250)
)
COMMENT 'Reporte cashflow por Owner/Publisher con pivote mensual de 12 meses'
ProcedureBody: BEGIN

DECLARE v_Version        VARCHAR(30);
DECLARE v_Meta           VARCHAR(3);
DECLARE v_Filters        VARCHAR(3);
DECLARE v_Debug          VARCHAR(20);
DECLARE v_FromMonth      VARCHAR(7);
DECLARE v_Owner          VARCHAR(80);
DECLARE v_DebtSide       VARCHAR(30);
DECLARE v_StartMonth     DATE;
DECLARE v_InLine         VARCHAR(500);
DECLARE v_e              INT;
DECLARE v_c              INT;
DECLARE v_k              VARCHAR(80);
DECLARE v_v              VARCHAR(250);
DECLARE v_SQLcols        LONGTEXT;
DECLARE v_SQLmetaCols    LONGTEXT;
DECLARE v_SQLmeta        LONGTEXT;
DECLARE v_SQLtxt         LONGTEXT;
DECLARE v_SQLfilters     LONGTEXT;
DECLARE v_WhereOwner     TEXT;
DECLARE v_WhereDebtSide  TEXT;
DECLARE v_AffEstimated   DECIMAL(20,2);
DECLARE v_AffPayable     DECIMAL(20,2);
DECLARE v_AffDebtCurrent DECIMAL(20,2);
DECLARE v_AffDebtNext    DECIMAL(20,2);

SET v_Version   = 'v2.1 10.04.2026';
SET v_Meta      = 'YES';
SET v_Filters   = 'NO';
SET v_Debug     = 'NO';
SET v_FromMonth = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), '%Y-%m');
SET v_Owner     = 'ALL';
SET v_DebtSide  = 'ALL';

SET v_InLine = CONCAT(IFNULL(TRIM(InputCommLine), ''), ',');
SET v_InLine = REPLACE(v_InLine, '"', '');

WHILE v_InLine > ' ' AND INSTR(v_InLine, '=') > 0 DO
    SET v_e = INSTR(v_InLine, '=');
    SET v_c = INSTR(v_InLine, ',');
    SET v_k = TRIM(SUBSTRING(v_InLine, 1, v_e - 1));
    SET v_v = TRIM(SUBSTRING(v_InLine, v_e + 1, v_c - (v_e + 1)));
    SET v_InLine = SUBSTRING(v_InLine, v_c + 1);

    IF LOWER(v_k) = 'meta'      THEN SET v_Meta      = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'filters'   THEN SET v_Filters   = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'debug'     THEN SET v_Debug     = UPPER(v_v); END IF;
    IF LOWER(v_k) = 'frommonth' THEN SET v_FromMonth = v_v; END IF;
    IF LOWER(v_k) = 'owner'     THEN SET v_Owner     = v_v; END IF;
    IF LOWER(v_k) = 'debtside'  THEN SET v_DebtSide  = v_v; END IF;
END WHILE;

SET v_WhereOwner = '';
IF UPPER(IFNULL(v_Owner, 'ALL')) <> 'ALL' THEN
    SET v_WhereOwner = CONCAT(
        ' AND (IFNULL(I.Owner, '''') = ',
        QUOTE(v_Owner),
        ' OR CAST(IFNULL(I.Owner_id, 0) AS CHAR) = ',
        QUOTE(v_Owner),
        ') '
    );
END IF;

SET v_WhereDebtSide = '';
IF UPPER(IFNULL(v_DebtSide, 'ALL')) = 'ONLY CLIENTS' THEN
    SET v_WhereDebtSide = ' AND IFNULL(B.Owner, '''') <> ''~Affiliate Payables'' ';
END IF;
IF UPPER(IFNULL(v_DebtSide, 'ALL')) = 'ONLY AFFILATES' THEN
    SET v_WhereDebtSide = ' AND IFNULL(B.Owner, '''') = ''~Affiliate Payables'' ';
END IF;
IF UPPER(IFNULL(v_DebtSide, 'ALL')) = 'ONLYCLIENTS' THEN
    SET v_WhereDebtSide = ' AND IFNULL(B.Owner, '''') <> ''~Affiliate Payables'' ';
END IF;
IF UPPER(IFNULL(v_DebtSide, 'ALL')) = 'ONLYAFFILATES' THEN
    SET v_WhereDebtSide = ' AND IFNULL(B.Owner, '''') = ''~Affiliate Payables'' ';
END IF;

IF v_FromMonth REGEXP '^[0-9]{4}-[0-9]{2}$' THEN
    SET v_StartMonth = STR_TO_DATE(CONCAT(v_FromMonth, '-01'), '%Y-%m-%d');
ELSE
    SET v_StartMonth = STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 6 MONTH), '%Y-%m'), '-01'), '%Y-%m-%d');
END IF;

-- Obtiene saldos de proveedores en tmp_balance_by_affiliate
CALL Report_balance_by_affiliate('tmptable=yes,debug=no');

SELECT
    ROUND(
        IFNULL(
            COALESCE(MAX(CASE WHEN Meta = 'total' THEN Estimated END), SUM(Estimated)),
            0
        ),
        2
    ),
    ROUND(
        IF(
            DAY(CURDATE()) >= 20,
            IFNULL(
                COALESCE(MAX(CASE WHEN Meta = 'total' THEN Confirmed END), SUM(Confirmed)),
                0
            ),
            IFNULL(
                COALESCE(MAX(CASE WHEN Meta = 'total' THEN Confirmed21 END), SUM(Confirmed21)),
                0
            )
        ),
        2
    )
INTO v_AffEstimated, v_AffPayable
FROM tmp_balance_by_affiliate;

SET v_AffDebtCurrent = ROUND(-1 * v_AffPayable, 2);
SET v_AffDebtNext    = ROUND(-1 * (v_AffEstimated - v_AffPayable), 2);

SET SESSION group_concat_max_len = 100000;

WITH RECURSIVE MonthGrid AS (
    SELECT 0 AS n, DATE_FORMAT(v_StartMonth, '%Y-%m') AS MKey
    UNION ALL
    SELECT n + 1, DATE_FORMAT(DATE_ADD(v_StartMonth, INTERVAL n + 1 MONTH), '%Y-%m')
    FROM MonthGrid
    WHERE n < 11
)
SELECT GROUP_CONCAT(
           CONCAT(
               'ROUND(SUM(CASE WHEN DATE_FORMAT(B.Due_date_resolved, ''%Y-%m'') = ''',
               MKey,
               ''' THEN B.Ammount ELSE 0 END),2) AS `',
               MKey,
               '`'
           )
           ORDER BY n
           SEPARATOR ',\n    '
       )
INTO v_SQLcols
FROM MonthGrid;

WITH RECURSIVE MonthGrid AS (
    SELECT 0 AS n, DATE_FORMAT(v_StartMonth, '%Y-%m') AS MKey
    UNION ALL
    SELECT n + 1, DATE_FORMAT(DATE_ADD(v_StartMonth, INTERVAL n + 1 MONTH), '%Y-%m')
    FROM MonthGrid
    WHERE n < 11
)
SELECT GROUP_CONCAT(
           CONCAT(
               ',IF(',
               QUOTE(MKey),
               '=LEFT(CURDATE(),7), "width=100px,right=true,colorBg=green", "width=95px,right=true") AS `',
               MKey,
               '`'
           )
           ORDER BY n
           SEPARATOR '\n'
       )
INTO v_SQLmetaCols
FROM MonthGrid;

SET v_SQLmeta = CONCAT(
'SELECT
    "setting" AS Meta,
    "width=200px" AS `Owner`,
    "width=90px,right=true,omit=true" AS `Owner_id`,
    "width=200px" AS `Operator`,
    "width=95px,right=true,omit=true" AS `Publisher_id`,
    "width=200px,center=true" AS `PayDay`,
    "width=130px,right=true" AS `Client Exposure`',
v_SQLmetaCols,
'
WHERE ', QUOTE(v_Meta), ' = "YES"
UNION ALL
');

SET v_SQLtxt = CONCAT(
'WITH BaseInvoice AS (
    SELECT
        I.id,
        I.Owner,
        I.Owner_id,
        I.Publisher AS `Operator`,
        I.Publisher_id,
        P.Pay_Day,
        I.Category,
        I.Invoiced_Month,
        I.Ammount,
        I.Due_Date,
        CASE
            WHEN I.Due_Date IS NOT NULL THEN I.Due_Date
            WHEN I.Invoiced_Month REGEXP ''^[0-9]{4}-[0-9]{2}$'' THEN
                DATE_ADD(
                    LAST_DAY(CONCAT(I.Invoiced_Month, ''-01'')),
                    INTERVAL
                    CASE
                        WHEN INSTR(IFNULL(P.Pay_Day, ''''), ''+'') > 0
                            THEN CAST(SUBSTRING_INDEX(P.Pay_Day, ''+'', -1) AS UNSIGNED)
                        ELSE 0
                    END DAY
                )
            ELSE NULL
        END AS Due_date_resolved
    FROM campaign_publisher_invoice I
    LEFT JOIN campaign_publisher P ON P.id = I.Publisher_id
    WHERE I.Paymt_Date IS NULL
      ', v_WhereOwner, '
      AND NOT (
          UPPER(IFNULL(I.Category, '''')) = ''PROFORMA''
          AND EXISTS (
              SELECT 1
              FROM campaign_publisher_invoice X
              WHERE X.Publisher_id = I.Publisher_id
                AND X.Invoiced_Month = I.Invoiced_Month
                AND UPPER(IFNULL(X.Category, '''')) = ''INVOICE''
          )
      )
),
Filtered AS (
    SELECT *
    FROM BaseInvoice
    WHERE Due_date_resolved IS NOT NULL
      AND Due_date_resolved >= ''', DATE_FORMAT(v_StartMonth, '%Y-%m-%d'), '''
      AND Due_date_resolved < DATE_ADD(''', DATE_FORMAT(v_StartMonth, '%Y-%m-%d'), ''', INTERVAL 12 MONTH)

    UNION ALL
    SELECT
        NULL AS id,
        ''~Affiliate Payables'' AS Owner,
        0 AS Owner_id,
        ''Payables Due (Current Month)'' AS `Operator`,
        0 AS Publisher_id,
        '''' AS Pay_Day,
        ''SupplierDebt'' AS Category,
        DATE_FORMAT(CURDATE(), ''%Y-%m'') AS Invoiced_Month,
        ', v_AffDebtCurrent, ' AS Ammount,
        CURDATE() AS Due_Date,
        STR_TO_DATE(CONCAT(DATE_FORMAT(CURDATE(), ''%Y-%m''), ''-01''), ''%Y-%m-%d'') AS Due_date_resolved
    FROM DUAL
    WHERE ', v_AffDebtCurrent, ' <> 0

    UNION ALL
    SELECT
        NULL AS id,
        ''~Affiliate Payables'' AS Owner,
        0 AS Owner_id,
        ''Payables Due (Next Month)'' AS `Operator`,
        0 AS Publisher_id,
        '''' AS Pay_Day,
        ''SupplierDebt'' AS Category,
        DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ''%Y-%m'') AS Invoiced_Month,
        ', v_AffDebtNext, ' AS Ammount,
        DATE_ADD(CURDATE(), INTERVAL 1 MONTH) AS Due_Date,
        STR_TO_DATE(CONCAT(DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), ''%Y-%m''), ''-01''), ''%Y-%m-%d'') AS Due_date_resolved
    FROM DUAL
    WHERE ', v_AffDebtNext, ' <> 0
)
',
v_SQLmeta,
'
SELECT
    CASE
        WHEN GROUPING(B.Owner) = 1 THEN "total"
        WHEN GROUPING(B.`Operator`) = 1 THEN "total"
        ELSE "data"
    END AS Meta,
    CASE
        WHEN GROUPING(B.Owner) = 1 THEN ''Expected Collections''
        ELSE IFNULL(B.Owner, '''')
    END AS `Owner`,
    CASE
        WHEN GROUPING(B.Owner) = 1 THEN ""
        ELSE IFNULL(CAST(MAX(B.Owner_id) AS CHAR), "")
    END AS `Owner_id`,
    CASE
        WHEN GROUPING(B.Owner) = 1 THEN ''Expected Collections''
        WHEN GROUPING(B.`Operator`) = 1 THEN ''Total Owner''
        ELSE IFNULL(B.`Operator`, '''')
    END AS `Operator`,
    CASE
        WHEN GROUPING(B.`Operator`) = 1 THEN ""
        ELSE IFNULL(CAST(MAX(B.Publisher_id) AS CHAR), "")
    END AS `Publisher_id`,
    CASE
        WHEN GROUPING(B.`Operator`) = 1 THEN ""
        ELSE IFNULL(MAX(B.Pay_Day), "")
    END AS `Pay_Day`,
    ROUND(SUM(B.Ammount), 2) AS `Client Exposure`,
    ', v_SQLcols, '
FROM Filtered B
WHERE 1=1
  ', v_WhereDebtSide, '
GROUP BY B.Owner, B.`Operator` WITH ROLLUP
ORDER BY
    CASE
        WHEN Owner = ''Expected Collections'' THEN 2
        WHEN Owner = ''~Affiliate Payables'' THEN 1
        ELSE 0
    END,
    Owner,
    CASE WHEN `Operator` = ''Total Owner'' THEN 1 ELSE 0 END,
    `Operator`,
    Publisher_id;
');

SET v_SQLfilters =
'WITH RECURSIVE UltimosMeses AS (
    SELECT 0 AS n, DATE_FORMAT(CURDATE(), "%Y-%m") AS Mes
    UNION ALL
    SELECT n + 1, DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL n + 1 MONTH), "%Y-%m")
    FROM UltimosMeses
    WHERE n < 5
),
Owners AS (
    SELECT DISTINCT
        IFNULL(NULLIF(TRIM(Owner), ""), CAST(Owner_id AS CHAR)) AS OwnerValue
    FROM campaign_publisher_invoice
    WHERE IFNULL(TRIM(Owner), "") <> "" OR IFNULL(Owner_id, 0) <> 0
)
SELECT
    LPAD(n + 1, 2, "0") AS Korder,
    "Mes inicial" AS `Key`,
    Mes AS `Value`,
    "FromMonth" AS `CallKey`,
    Mes AS `CallValue`
FROM UltimosMeses
UNION ALL
SELECT
    "20" AS Korder,
    "Owner" AS `Key`,
    OwnerValue AS `Value`,
    "Owner" AS `CallKey`,
    OwnerValue AS `CallValue`
FROM Owners
UNION ALL
SELECT "30", "Debt Side", "All", "DebtSide", "ALL"
UNION ALL
SELECT "31", "Debt Side", "Only Clients", "DebtSide", "OnlyClients"
UNION ALL
SELECT "32", "Debt Side", "Only Affilates", "DebtSide", "OnlyAffilates"
ORDER BY Korder, `Value` DESC;';

IF v_Debug <> 'NO' THEN
    SELECT
        v_Version AS Version,
        v_Meta AS Meta,
        v_Filters AS Filters,
        v_Debug AS Debug,
        v_FromMonth AS FromMonth,
        v_Owner AS OwnerFilter,
        v_DebtSide AS DebtSideFilter,
        DATE_FORMAT(v_StartMonth, '%Y-%m-%d') AS StartMonth,
        v_AffEstimated AS AffEstimated,
        v_AffPayable AS AffPayable,
        v_AffDebtCurrent AS AffDebtCurrent,
        v_AffDebtNext AS AffDebtNext;
END IF;

IF v_Debug <> 'NO' THEN
    SELECT v_SQLtxt, v_SQLmeta, v_SQLfilters;
END IF;

IF v_Filters = 'YES' THEN
    SET @SQL_Report_Cashflow = v_SQLfilters;
ELSE
    SET @SQL_Report_Cashflow = v_SQLtxt;
END IF;

IF v_Debug <> 'YES' THEN
    PREPARE stmt1 FROM @SQL_Report_Cashflow;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;
END IF;

END;
$$
DELIMITER ;
