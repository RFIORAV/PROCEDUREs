/*
PROCEDURE_Check_Bot_Status_v2.sql - Comprobacion de ultima actualizacion y estado de bot

Descripción:
  Procedimiento Check_Bot_Status.

Observaciones:
Parámetro único de entrada estilo Key=Value separado por coma.

Keys:
Meta      =[No | Yes]. OPCIONAL. Columna 1 como METADATO total/data/setting. Default=Yes.
Filters   =[No | Yes]. OPCIONAL. Devuelve lista de filtros disponibles. Default=No.
Debug     =[No | Yes | KeyValues]. OPCIONAL. Default=No.
Notificar =[No | Yes]. OPCIONAL. Si Yes, muestra solo marcas con incidencia. Default=No.
WaitBot   =[numero]. OPCIONAL. Horas limite para BOT. Default=10.
InputCommLine = [valor]. Parámetro de entrada.

Version history:
24.03.2022 v2.0 Consulta inicial
23.02.2026 v2.1 Convertido a stored procedure usando CTE para consulta principal
23.02.2026 v2.2 Agrega meta, filters, debug y notificar con InputCommLine
                Inserta warning en account_notifications si BOT supera 10 horas
                Evita notificaciones duplicadas por marca en estado Pending
                Agrega parametro WaitBot para umbral de horas BOT

Usage:
CALL Check_Bot_Status('');
CALL Check_Bot_Status('debug=ye');
CALL Check_Bot_Status('meta=yes');
CALL Check_Bot_Status('notificar=yes');
CALL Check_Bot_Status('filters=yes,debug=YE');
CALL Check_Bot_Status('filters=yes');
*/

DROP PROCEDURE IF EXISTS Check_Bot_Status;

DELIMITER $$
CREATE PROCEDURE Check_Bot_Status(
    IN InputCommLine VARCHAR(250)
)
COMMENT 'Comprobacion de ultima actualizacion de datos y ejecucion de Bot'
ProcedureBody: BEGIN
DECLARE v_Version      VARCHAR(30);
DECLARE v_Meta         VARCHAR(3);
DECLARE v_Filters      VARCHAR(3);
DECLARE v_Debug        VARCHAR(20);
DECLARE v_Notificar    VARCHAR(3);
DECLARE v_WaitBot      INT;
DECLARE v_e            INT;
DECLARE v_c            INT;
DECLARE v_k            VARCHAR(80);
DECLARE v_v            VARCHAR(250);
DECLARE v_SQLmeta      LONGTEXT;
DECLARE v_SQLtxt       LONGTEXT;
DECLARE v_SQLfilters   LONGTEXT;

SET v_Version   ='v2.2 24.02.2026';
SET v_Meta      ='YES';
SET v_Filters   ='NO';
SET v_Debug     ='NO';
SET v_Notificar ='NO';
SET v_WaitBot   =10;

SET InputCommLine=IFNULL(InputCommLine,'');
SET InputCommLine=CONCAT(InputCommLine,',');
SET InputCommLine=REPLACE(InputCommLine,'"','');

WHILE InputCommLine>' ' AND INSTR(InputCommLine,'=')>0 DO
    SET v_e=INSTR(InputCommLine,'=');
    SET v_c=INSTR(InputCommLine,',');
    SET v_k=SUBSTRING(InputCommLine,1,v_e-1);
    SET v_v=SUBSTRING(InputCommLine,v_e+1,v_c-(v_e+1));
    SET InputCommLine=SUBSTRING(InputCommLine,v_c+1);
    SET v_k=TRIM(v_k);
    SET v_v=TRIM(v_v);

    IF LOWER(v_k)='meta'      THEN SET v_Meta      =UPPER(v_v); END IF;
    IF LOWER(v_k)='filters'   THEN SET v_Filters   =UPPER(v_v); END IF;
    IF LOWER(v_k)='debug'     THEN SET v_Debug     =UPPER(v_v); END IF;
    IF LOWER(v_k)='notificar' THEN SET v_Notificar =UPPER(v_v); END IF;
    IF LOWER(v_k)='waitbot'   THEN SET v_WaitBot   =IF(CAST(v_v AS SIGNED)>0,CAST(v_v AS SIGNED),v_WaitBot); END IF;
END WHILE;

SET v_SQLmeta=CONCAT('
SELECT
   "setting" as Meta
   ,"width=180px"             AS `Brand`
   ,"width=120px,center=true" AS `Last Day Data`
   ,"width=80px,right=true"   AS `Days Old`
   ,"width=100px,colorBg=[Paid:green;<< Check:red]" AS `Status API`  
   ,"width=150px,center=true" AS `Last Run Bot`
   ,"width=110px,center=true"  AS `Hours Since Last Run Bot`
   ,"width=100px,colorBg=[Paid:green;<< Check:red]" AS `Status BOT`  
   ,"width=120px,center=true" AS `Last Day CPA`
   ,"width=100px,right=true"  AS `Days Old CPA`
WHERE ',QUOTE(v_Meta),'="YES"   
UNION ALL
');

SET v_SQLtxt=CONCAT(
'WITH cte_data AS (
    SELECT
        Brand,
        MAX(Date) AS Last_Day_Data,
        DATEDIFF(MAX(Hour_Update), MAX(Date)) AS Days_OLD,
        CASE WHEN MAX(Date) < DATE_SUB(NOW(), INTERVAL 36 HOUR) THEN "<< Check" ELSE "" END AS Status_API,
        MAX(Hour_Update) AS Last_Run_Bot,
        TIMESTAMPDIFF(HOUR, MAX(Hour_Update), NOW()) AS Hours_Since_Last_Run_Bot,
        CASE WHEN TIMESTAMPDIFF(HOUR, MAX(Hour_Update), NOW())>=',v_WaitBot,' 
              AND Brand NOT IN ("bwin", "giocodigitale", "Sportingbet", "bet365", "PokerStars")
              THEN "<< Check" 
              ELSE "" 
        END AS Status_BOT
    FROM Snapshot_day_by_day
    WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY Brand
),
cte_cpa AS (
    SELECT
        Brand,
        MAX(Date) AS Last_Day_CPA,
        DATEDIFF(MAX(Hour_Update), MAX(Date)) AS Days_OLD_CPA
    FROM Snapshot_day_by_day
    WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND Qualified_Players <> 0
    GROUP BY Brand
)
',
v_SQLmeta,
'
SELECT
    "data" AS Meta,
    d.Brand AS `Brand`,
    d.Last_Day_Data AS `Last Day Data`,
    d.Days_OLD AS `Days Old`,
    d.Status_API AS `Status API`,
    d.Last_Run_Bot AS `Last Run Bot`,
    d.Hours_Since_Last_Run_Bot AS `Hours Since Last Run Bot`,
    d.Status_BOT AS `Status BOT`,
    IFNULL(c.Last_Day_CPA, ''>> 30+ dias <<'') AS `Last Day CPA`,
    c.Days_OLD_CPA AS `Days Old CPA`
FROM cte_data d
LEFT JOIN cte_cpa c ON c.Brand = d.Brand
ORDER BY Brand;
');

SET v_SQLfilters='
SELECT "01" AS Korder, "Options" AS `Key`, "Send Warning if BOT exceeds xx hours" AS `Value`, "Notificar" AS `CallKey`, "YES" AS `CallValue`
';

IF v_Debug!='NO' THEN
    SELECT v_Version, v_Meta, v_Filters, v_Debug, v_Notificar;
    SELECT v_SQLtxt,v_SQLmeta,v_SQLfilters;
END IF;


-- Envía notificación si Debug=NO y Notificar=YES
IF v_Debug='NO' AND v_Notificar='YES' THEN
    INSERT INTO `account_notifications`
    (
        `id`, `Affiliate_id`, `Extra_id_1`, `Extra_id_2`, `Extra_id_3`,
        `Testo`, `FromUser`, `Type`, `Status`, `Status_id`,
        `Read_Status`, `Comm_Status`, `Date`, `Owner`, `Subtype`,
        `Detail`, `Action`, `Creation_Date`, `Last_Update`, `Operator`
    )
    SELECT
        NULL, '2', '', '', '',
        CONCAT('Warning - Data download from ', d.Brand, ' too old'),
        'System', 'Warning SysOp', 'Pending', '0',
        0, '', NOW(), '', '',
        '', '', NOW(), NOW(), 'SysOp'
    FROM
    (
        SELECT
            Brand,
            TIMESTAMPDIFF(HOUR, MAX(Hour_Update), NOW()) AS Hours_Since_Last_Run_Bot
        FROM Snapshot_day_by_day
        WHERE Date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY Brand
    ) d
    WHERE d.Hours_Since_Last_Run_Bot > v_WaitBot
      AND d.Brand NOT IN ('bwin', 'giocodigitale', 'Sportingbet', 'bet365', 'PokerStars')
      AND NOT EXISTS
      (
          SELECT 1
          FROM account_notifications n
          WHERE n.Affiliate_id = '2'
            AND n.Type = 'Warning SysOp'
            AND n.Status = 'Pending'
            AND n.Testo = CONCAT('Warning - Data download from ', d.Brand, ' too old')
      );
END IF;

IF v_Filters='YES' THEN
    SET @SQL_Check_Bot_Status=v_SQLfilters;
ELSE    
    SET @SQL_Check_Bot_Status=v_SQLtxt;
END IF;

IF v_Debug!='YES' THEN
    PREPARE stmt1 FROM @SQL_Check_Bot_Status;
    EXECUTE stmt1;
    DEALLOCATE PREPARE stmt1;
END IF;

END;
$$
DELIMITER ;