/* PROCEDURE_Show_Diff_CPA_DbD_yesterday.sql - Check Raw Data: CPA missing from yesterday


Descripción:
  Procedimiento Show_Diff_CPA_DbD_yesterday.
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Action          =[View | SET | Debug | Notify]. Modifica datos o solo muestra. OPCIONAL. Default=VIEW.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

CALL Show_Diff_CPA_DbD_yesterday_dev('Action=VIEW');
CALL Show_Diff_CPA_DbD_yesterday('Action=VIEW');
CALL Show_Diff_CPA_DbD_yesterday('Action=SET'); -- ejecutado por EVENT a partir de las 23
CALL Show_Diff_CPA_DbD_yesterday_dev('Action=debug');
CALL Show_Diff_CPA_DbD_yesterday_dev('Action=notify');

Modificaciones:

25.09.2022 V1     Compara CPA Snapshot_day_by_day ayer con Snapshot_day_by_day_fact1 de hoy
                  Detecta CPA quitadas por MS/Afiliado
19.10.2022 V1.1   Columna Meta
01.11.2022 V1.2   Día 1 compara con mes anterior
23.02.2023        fix error en comparación
10.04.2023 V1.3   Karen. Incluye manejo standard de parámetros de entrada
28.03.2024 v1.3.1 Agregada columna MS_id en grid
28.05.2025 v1.3.2 Comparación basada en fact1 Origin=""
23.08.2025 v1.5   Agregada columna Diferencia y acumulación final
25.11.2025        Quitado group by Product
17.03.2026 v1.6   Agregada notificación de CPA missing
   
*/
DROP PROCEDURE IF EXISTS Show_Diff_CPA_DbD_yesterday;
-- DROP PROCEDURE IF EXISTS Show_Diff_CPA_DbD_yesterday_dev;

DELIMITER $$
CREATE PROCEDURE Show_Diff_CPA_DbD_yesterday(IN
   InputCommLine    VARCHAR(250)
   )  
   COMMENT 'Check Raw Data: CPA missing from yesterday'
   LANGUAGE SQL

proc_label:BEGIN

DECLARE v_Version       VARCHAR(30)  DEFAULT 'v1.6 17.03.2026';
DECLARE v_Action        VARCHAR(10)  DEFAULT 'VIEW';
DECLARE v_Meta          VARCHAR(10)  DEFAULT 'YES';
DECLARE v_Debug         VARCHAR(20)  DEFAULT 'NO';
DECLARE v_Filters       VARCHAR(10)  DEFAULT 'NO';
DECLARE v_Curr_Month    VARCHAR(7);
DECLARE v_InputCommLine VARCHAR(300);
DECLARE v_e             INT;
DECLARE v_c             INT;
DECLARE v_k             VARCHAR(100);
DECLARE v_v             VARCHAR(200);

SET v_InputCommLine = Concat(InputCommLine, ',');
SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');
IF v_Debug != 'NO' THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine > ' ' DO

   SET v_e = INSTR(v_InputCommLine, '=');
   SET v_c = INSTR(v_InputCommLine, ',');
   SET v_k = SUBSTRING(v_InputCommLine, 1, v_e - 1);
   SET v_v = SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1));
   SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);
   SET v_k = TRIM(v_k);
   SET v_v = TRIM(v_v);

   IF LOWER(v_k) = 'action' THEN SET v_Action = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'meta'   THEN SET v_Meta = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'debug'  THEN SET v_Debug = UPPER(v_v); END IF;

END WHILE;

IF v_Debug != 'NO' THEN SELECT v_Action, v_Meta, v_Debug, v_Filters; END IF;

IF DAY(CURDATE()) <= 3 THEN
   SET v_Curr_Month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7);
ELSE
   SET v_Curr_Month = LEFT(CURDATE(), 7);
END IF;

-- DROP TABLE IF EXISTS `Snapshot_day_by_day_diff`;
CREATE TABLE IF NOT EXISTS `Snapshot_day_by_day_diff` (
	`Month` VARCHAR(7) NULL DEFAULT NULL,
	`Brand` VARCHAR(50) NULL DEFAULT '0',
	`Username` VARCHAR(50) NULL DEFAULT '0',
   `Username_id` INT NULL DEFAULT 0,
   `MS_id` INT NULL DEFAULT 0,
	`Tracker_Name` VARCHAR(50) NULL DEFAULT NULL,
	`Tracker_id` VARCHAR(50) NULL DEFAULT NULL,
	`Product` VARCHAR(50) NULL DEFAULT NULL,
	`Qualified_Players` INT NULL DEFAULT '0',
	`Hour_Update` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`Creation_date` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
	UNIQUE INDEX `Month` (`Month`, `Brand`, `Username_id`, `MS_id`, `Tracker_Name`, `Tracker_id`, `Product`) USING BTREE
)
;
-- --------------------------------------------
IF v_Action = 'SET' THEN
   TRUNCATE Snapshot_day_by_day_diff;
   INSERT IGNORE INTO Snapshot_day_by_day_diff 
      SELECT left(DATE,7) as Month,Brand,Username,Username_id,ifnull(MS_id,0) AS MS_id,Tracker_Name,Tracker_id,Product,sum(Qualified_Players) AS CPA,Hour_Update,now()
      FROM  Snapshot_day_by_day_fact1 D
      WHERE left(DATE,7)=QUOTE(v_Curr_Month) AND Origin=''
      GROUP BY Brand,Username_id,ifnull(MS_id,0),Tracker_Name,Tracker_id,Product HAVING CPA<>0;
END IF;

-- Si Action='SET' finaliza proceso
IF v_Action = 'SET' THEN LEAVE proc_label; END IF;

-- --------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `tmp_Snapshot_day_by_day_diff_today`;

CREATE TEMPORARY TABLE `tmp_Snapshot_day_by_day_diff_today` AS

WITH Day_by_Day AS (
   SELECT LEFT(DATE,7) as Month,Brand,Username,Username_id,Affiliate,ifnull(MS_id,0) AS MS_id,Tracker_Name,Tracker_id,Product,sum(Qualified_Players) AS CPA,Hour_Update
   FROM  Snapshot_day_by_day_fact1 D
   WHERE LEFT(DATE,7)=v_Curr_Month AND Origin=''
   GROUP BY Brand,Username_id,ifnull(MS_id,0),Tracker_Name,Tracker_id -- ,Product 
   HAVING CPA<>0
),
Day_by_Day_Yesterday AS (
   SELECT Month,Brand,Username,Username_id,ifnull(MS_id,0) AS MS_id,Tracker_Name,Tracker_id,Product,sum(Qualified_Players) AS CPA,Hour_Update
   FROM  Snapshot_day_by_day_diff D
   WHERE Month=v_Curr_Month
   GROUP BY Brand,Username_id,ifnull(MS_id,0),Tracker_Name,Tracker_id -- ,Product 
   HAVING CPA<>0
)

   SELECT "data" as Meta,
     F.Month as 'Date',F.Brand as 'Brand'
    ,F.Username as Account
    ,F.Username_id
    ,D.Affiliate as Affiliate
    ,ifnull(F.MS_id,0) as MS_id,F.Tracker_id,F.Tracker_Name,F.Product
    ,F.CPA as 'CPA_yesterday',D.CPA as 'CPA_today'
    ,(IFNULL(D.CPA,0) - IFNULL(F.CPA,0)) as 'Missing'
   FROM Day_by_Day_Yesterday F
   LEFT JOIN Day_by_Day D on F.Username_id=D.Username_id 
      AND case when F.MS_id>0 then F.MS_id=D.MS_id else 1=1 end 
      AND F.Tracker_id=D.Tracker_id AND F.Tracker_Name=D.Tracker_Name-- AND F.Product=D.Product
   WHERE F.CPA>IFNULL(D.CPA,0)
;

-- ------------------------------------------------------------
DROP TEMPORARY TABLE IF EXISTS `tmp_Snapshot_day_by_day_diff_today_1`;
CREATE TEMPORARY TABLE `tmp_Snapshot_day_by_day_diff_today_1` AS
   SELECT * FROM tmp_Snapshot_day_by_day_diff_today;

IF v_Action = 'DEBUG' THEN   
   SELECT * FROM tmp_Snapshot_day_by_day_diff_today;
   SELECT QUOTE(v_Curr_Month),v_Curr_Month;
   LEAVE proc_label;
END IF;
-- ------------------------------------------------------------

IF v_Action = 'VIEW' THEN  
SELECT "total" as Meta,
     'TOTAL' as 'Date'
    ,'~~~~~' as Brand
    ,'~~~~~' as Account
    ,'~~~~~' as 'Accnt id'
    ,'~~~~~' as Affiliate
    ,'~~~~~' as 'MS_id'
    ,'~~~~~' as 'Tracker ID'
    ,'~~~~~' as 'Tracker Name'
    ,'~~~~~' as Product
    ,'~~~~~' AS 'CPA yesterday','~~~~~' AS 'CPA today'
    ,SUM(`Missing`) as 'CPA Missing'
FROM tmp_Snapshot_day_by_day_diff_today_1

UNION ALL 

SELECT
  "setting" as Meta
  ,"width=100px"            as DATE
  ,"width=150px"            as Brand
  ,"width=200px"            AS `Account`
  ,"width=100px"            AS `Account id`
  ,"width=200px"            AS `Affiliate`
  ,"width=80px,center=yes"  as `MS id`
  ,"width=100px"            AS `Tracker ID`
  ,"width=150px"            AS `Tracker Name`
  ,"width=150px"            as Product
  ,"width=100px,right=true" as 'CPA yesterday'
  ,"width=090px,right=true" as 'CPA today'
  ,"width=090px,right=true" as 'CPA Missing'
FROM DUAL WHERE v_Meta="YES"

UNION ALL 

SELECT * FROM tmp_Snapshot_day_by_day_diff_today

ORDER BY DATE DESC,Brand,Account,Affiliate,MS_id
;
END IF;

-- --------------------------------------------
-- Envía notificación si Action=NOTIFY
-- --------------------------------------------
IF v_Action = 'NOTIFY' THEN

INSERT INTO `account_notifications` (
        `id`, `Affiliate_id`, `Extra_id_1`, `Extra_id_2`, `Extra_id_3`,
        `Testo`, `FromUser`, `Type`, `Status`, `Status_id`,
        `Read_Status`, `Comm_Status`, `Date`, `Owner`, `Subtype`,
        `Detail`, `Action`, `Creation_Date`, `Last_Update`, `Operator`
)
SELECT
   NULL, '2', '', '', '',
   CONCAT('MISSING ',d.Missing,' CPA from ', d.Brand, ' - Affiliate: ', d.Affiliate),
   'System', 'Warning SysOp', 'Pending', '0',
   0, '', NOW(), '', '',
   '', '', NOW(), NOW(), 'SysOp'
FROM tmp_Snapshot_day_by_day_diff_today d
WHERE d.Meta="data"
GROUP BY Brand,Affiliate
;
END IF;

DROP TEMPORARY TABLE IF EXISTS `tmp_Snapshot_day_by_day_diff_today`;
DROP TEMPORARY TABLE IF EXISTS `tmp_Snapshot_day_by_day_diff_today_1`;

END$$
DELIMITER ;

/*
Test:

CALL Show_Diff_CPA_DbD_yesterday_dev('Action=VIEW');
CALL Show_Diff_CPA_DbD_yesterday_dev('Action=SET'); -- ejecutado por EVENT a partir de las 23

*/