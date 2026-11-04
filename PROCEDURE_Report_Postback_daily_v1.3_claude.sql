/*
PROCEDURE_Report_Postback_daily_v1.3.sql - Reporte diario de postbacks inbound

Descripción:
  Lista postbacks (postback_inbound_data) enriquecidos con MS / Account /
  Affiliate / Advertiser y metadatos de clic affly (IP enmascarada, país,
  OS, Dispositivo). Sin Snapshot_day_by_day ni Snapshot_day_by_day_pb.
  Filtros monovalor. Month limitado a los últimos 6 meses.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  Month          =[AAAA-MM | CM | LM | THISMONTH | THISMONT]. Si no hay Date ni Date_from:
                 OBLIGATORIO (default=mes actual). Date_from=inicio, Date_to=fin del mes.
                 THISMONTH/THISMONT/CM = mes corriente. LM = mes anterior. Últimos 6 meses en Filters.
  Date           =[AAAA-MM-DD | TODAY | YESTERDAY | FIRST15 | LAST15 | THISMONTH]. OPCIONAL.
                 Si se informa → Date_from=Date_to=Date (salvo atajos de rango).
                 TODAY=hoy; YESTERDAY=ayer; FIRST15=días 1-15 del mes corriente;
                 LAST15=últimos 15 días hasta hoy; THISMONTH=mes corriente (vía Month).
  Date_from      =[AAAA-MM-DD | FIRST15 | LAST15]. Si no hay Date: OBLIGATORIO (o se deriva de Month).
  Date_to        =[AAAA-MM-DD]. OPCIONAL. Si hay Date_from y no Date_to → Date_to=Date_from.
  Operator       =[ALL | origin postback]. OPCIONAL. Default=ALL.
  Tracker_ID     =[ALL | Tracker_ID]. OPCIONAL. Default=ALL.
  Account_id     =[ALL | id]. OPCIONAL. Default=ALL.
  Affiliate_id   =[ALL | id]. OPCIONAL. Default=ALL.
  Advertiser_ID  =[ALL | id]. OPCIONAL. Default=ALL.
  Op_Code        =[ALL | status postback]. OPCIONAL. Default=ALL.
  Mode           =[Aff | Ges]. No interactivo (no aparece en Filters). OPCIONAL. Default=Ges.
                 Aff: omite en Meta Operator/Account/MS id/Tracker_ID/Tracker Name;
                 no muestra filtros Account/Affiliate/Tracker_ID;
                 columna `Code to Affiliate` se etiqueta como `Marketing source`.
  Display        =[Normal | Transpose]. OPCIONAL. Default=Normal.
                 Normal: reporte detallado actual.
                 Transpose: fuerza Mode=Aff; columnas Date, Brand, Marketing source
                 + una columna por cada Op_Code distinto (conteo); primera fila = totales.
  Filters        =[Yes | No]. Lista de filtros. OPCIONAL. Default=No.
  Meta           =[Yes | No]. Fila setting. OPCIONAL. Default=Yes.
  Debug          =[No | Yes ]. OPCIONAL. Default=No.

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  call Report_Postback_daily('');
  call Report_Postback_daily_dev('debug=ye');
  call Report_Postback_daily('filters=yes');
  call Report_Postback_daily('Date=TODAY');
  call Report_Postback_daily('Date=YESTERDAY');
  call Report_Postback_daily('Date=FIRST15');
  call Report_Postback_daily('Date=LAST15');
  call Report_Postback_daily('Month=THISMONTH');
  call Report_Postback_daily('Mode=Aff');
  call Report_Postback_daily('Mode=Ges,month=2026-09');
  call Report_Postback_daily('month=2026-09,debug=ye');
  call Report_Postback_daily('month=2026-09,Date=2026-09-04,filters=yes');
  call Report_Postback_daily('Date_from=2026-09-01,Date_to=2026-09-15');
  call Report_Postback_daily('Date_from=2026-09-10');
  call Report_Postback_daily('month=2026-09');
  call Report_Postback_daily('Display=Transpose,Affiliate_id=11,month=2026-09');
  call Report_Postback_daily('Display=Transpose,Affiliate_id=11,Date_from=2026-09-01,Date_to=2026-09-15,debug=ye');
  call Report_Postback_daily('month=2026-09,Operator=VegasLegends,Op_Code=reg,filters=yes,debug=ye');
  call Report_Postback_daily('Operator=VegasLegends,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-08,Operator=ALL,tracker_id=ALL,account_id=ALL,affiliate_id=ALL,Op_Code=ALL,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-08,Operator=ALL,tracker_id=ALL,account_id=ALL,affiliate_id=ALL,Op_Code=ftd,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-09,Account_id=257,Tracker_ID=main');

22.09.2026 V1     Primera versión operativa — solo postback enriquecido (sin Snapshot/Diff);
                  filtros monovalor; Month últimos 6 meses
                  Mode=Aff|Ges (no interactivo); Aff omite columnas/filtros sensibles y
                  renombra Code to Affiliate → Marketing source
23.09.2026        Fila total al inicio (Meta=total): COUNT en Date, "TOTAL records" en Tracker_ID, resto "~~~~~"
01.10.2026 v1.1   Filtros Date_from / Date_to; normalización Date/Date_from/Date_to/Month;
                  Display=Normal|Transpose (Transpose: pivot Op_Code por Date/Brand/Marketing source)
02.10.2026 v1.2   Atajos Date/Month: TODAY, YESTERDAY, FIRST15, LAST15, THISMONTH/THISMONT;
                  aparecen en Filters=Yes (Period)
06.10.2026 v1.2.1 Karen: Si vienen dos Month, se usa el primero
28.10.2026 v1.2.2 Tracker_ID: extrae parte derecha de tracking_code cuando cumple formato dígitos_dígitos (^[0-9]+_[0-9]+$)
28.10.2026 v1.2.3 Tracker_ID: CTE agrupado de tracking_code dd_dd; si existe MS para el código completo, se respeta
29.10.2026 v1.3   Enriquecimiento con clics affly vinculados por click_id (solo MS con Shortlink affly.eu/):
                  IP con último octeto enmascarado (x.x.x.***), bandera emoji + país ISO-2, OS y Dispositivo
                  (derivados de user_agent). Fuente affly.shortener_clicks, respaldo affly.shortener_visits.
                  Columnas nuevas: IP, Country, OS, Device (visibles también en Mode=Aff)
                  Nota: postback_inbound_data.click_id informado desde 14.10.2026; antes las columnas quedan vacías
                  Vínculo affly solo si campaign_marketing_source.Shortlink_id LIKE affly.eu/ (si no, columnas NULL).
                  Rendimiento: filtros de fecha sargables sobre created_at; datos de clic se buscan después de
                  aplicar filtros (PE_base) y se omiten en Filters=Yes / Display=Transpose;
                  FORCE INDEX por click_id en clicks/visits (evita recorrido inverso por PRIMARY de visits)
30.10.2026 v1.4   Op_Code "Signup" → "REG" (dato, colorBg de Meta y orden de columnas en Transpose).
                  affly.shortener_clicks obsoleta: se elimina; única fuente de clic = affly.shortener_visits.
                  Visitas restringidas al origin de esta DB: affly.shortener_urls.origin = DATABASE()
                  (p.ej. "ritemood"), vía shortener_visits.url_key → shortener_urls.`key` dentro del LATERAL
                  (antes se cruzaba solo por click_id, sin distinguir la DB de origen).
*/

DROP PROCEDURE IF EXISTS Report_Postback_daily;
-- DROP PROCEDURE IF EXISTS Report_Postback_daily_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Postback_daily`(
   IN InputCommLine VARCHAR(550)
)
COMMENT 'v1.4 30.10.2026 Postbacks enriquecidos con MS y clics affly del origin de esta DB (IP, pais, OS, dispositivo)'
SQL SECURITY DEFINER
proc_label:BEGIN

DECLARE v_Version       VARCHAR(32)  DEFAULT 'v1.4 30.10.2026';
DECLARE v_InputCommLine VARCHAR(560);
DECLARE v_e             INT;
DECLARE v_c             INT;
DECLARE v_k             VARCHAR(64);
DECLARE v_v             VARCHAR(200);

DECLARE v_Month         VARCHAR(16)  DEFAULT '';
DECLARE v_Date          VARCHAR(16)  DEFAULT 'ALL';
DECLARE v_Date_from     VARCHAR(16)  DEFAULT 'ALL';
DECLARE v_Date_to       VARCHAR(16)  DEFAULT 'ALL';
DECLARE v_Operator      VARCHAR(100) DEFAULT 'ALL';
DECLARE v_Tracker_ID    VARCHAR(100) DEFAULT 'ALL';
DECLARE v_Account_id    VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Affiliate_id  VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Advertiser_ID VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Op_Code       VARCHAR(50)  DEFAULT 'ALL';
DECLARE v_Mode          VARCHAR(8)   DEFAULT 'GES';
DECLARE v_Display       VARCHAR(16)  DEFAULT 'NORMAL';
DECLARE v_Filters       VARCHAR(8)   DEFAULT 'NO';
DECLARE v_Meta          VARCHAR(8)   DEFAULT 'YES';
DECLARE v_Debug         VARCHAR(16)  DEFAULT 'NO';

DECLARE v_WhereDateFrom VARCHAR(80)  DEFAULT '';
DECLARE v_WhereDateTo   VARCHAR(80)  DEFAULT '';
DECLARE v_WhereOperator VARCHAR(200) DEFAULT '';
DECLARE v_WhereTracker  VARCHAR(200) DEFAULT '';
DECLARE v_WhereAccount  VARCHAR(80)  DEFAULT '';
DECLARE v_WhereAffiliate VARCHAR(80) DEFAULT '';
DECLARE v_WhereAdvertiser VARCHAR(80) DEFAULT '';
DECLARE v_WhereOpCode   VARCHAR(120) DEFAULT '';

DECLARE v_Month_set BOOLEAN DEFAULT FALSE; -- K 05.10.2026
DECLARE v_Affly_Origin  VARCHAR(64)  DEFAULT '';  -- v1.4 origin de affly.shortener_urls = DB actual

SET v_Month = LEFT(CURDATE(), 7);
-- v1.4 En un SP, DATABASE() devuelve el esquema donde está definido el procedimiento
SET v_Affly_Origin = IFNULL(DATABASE(), '');

SET v_InputCommLine=CONCAT(InputCommLine,',');      -- Coma de cierre
SET v_InputCommLine=REPLACE(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=REPLACE(v_InputCommLine,'"','');  -- Elimina comillas

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- v_InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);
		-- K 05.10.2026
		IF LOWER(v_k) = 'month' AND v_Month_set = FALSE THEN
			 SET v_Month     = UPPER(v_v);
			 SET v_Month_set = TRUE;
		END IF;
      -- IF LOWER(v_k) = 'month'         THEN SET v_Month         = UPPER(v_v); END IF;                                                                                  
      IF LOWER(v_k) = 'date'          THEN SET v_Date          = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'date_from'     THEN SET v_Date_from     = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'date_to'       THEN SET v_Date_to       = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'operator'      THEN SET v_Operator      = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'tracker_id'    THEN SET v_Tracker_ID    = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'account_id'    THEN SET v_Account_id    = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'affiliate_id'  THEN SET v_Affiliate_id  = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'advertiser_id' THEN SET v_Advertiser_ID = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'op_code'       THEN SET v_Op_Code       = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'mode'          THEN SET v_Mode          = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'display'       THEN SET v_Display       = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'filters'       THEN SET v_Filters       = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'meta'          THEN SET v_Meta          = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'debug'         THEN SET v_Debug         = UPPER(v_v); END IF;

END WHILE;

-- Atajos Month
IF v_Month IN ('CM', 'THISMONTH', 'THISMONT') THEN SET v_Month = LEFT(CURDATE(), 7); END IF;
IF v_Month = 'LM' THEN SET v_Month = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH), 7); END IF;

-- Atajos Date / Date_from
IF v_Date = 'TODAY' THEN
   SET v_Date = DATE_FORMAT(CURDATE(), '%Y-%m-%d');
ELSEIF v_Date = 'YESTERDAY' THEN
   SET v_Date = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 1 DAY), '%Y-%m-%d');
ELSEIF v_Date = 'FIRST15' THEN
   SET v_Date      = 'ALL';
   SET v_Date_from = CONCAT(LEFT(CURDATE(), 7), '-01');
   SET v_Date_to   = CONCAT(LEFT(CURDATE(), 7), '-15');
ELSEIF v_Date = 'LAST15' THEN
   SET v_Date      = 'ALL';
   SET v_Date_from = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 14 DAY), '%Y-%m-%d');
   SET v_Date_to   = DATE_FORMAT(CURDATE(), '%Y-%m-%d');
ELSEIF v_Date IN ('THISMONTH', 'THISMONT') THEN
   SET v_Date  = 'ALL';
   SET v_Month = LEFT(CURDATE(), 7);
END IF;

IF v_Date_from = 'FIRST15' THEN
   SET v_Date_from = CONCAT(LEFT(CURDATE(), 7), '-01');
   IF v_Date_to IN ('', 'ALL') THEN SET v_Date_to = CONCAT(LEFT(CURDATE(), 7), '-15'); END IF;
ELSEIF v_Date_from = 'LAST15' THEN
   SET v_Date_from = DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 14 DAY), '%Y-%m-%d');
   IF v_Date_to IN ('', 'ALL') THEN SET v_Date_to = DATE_FORMAT(CURDATE(), '%Y-%m-%d'); END IF;
END IF;

-- Normalización Date / Date_from / Date_to / Month
IF v_Date NOT IN ('', 'ALL') THEN
   SET v_Date_from = v_Date;
   SET v_Date_to   = v_Date;
ELSEIF v_Date_from NOT IN ('', 'ALL') THEN
   IF v_Date_to IN ('', 'ALL') THEN
      SET v_Date_to = v_Date_from;
   END IF;
ELSE
   -- Sin Date ni Date_from: Month obligatorio → rango del mes
   IF v_Month IN ('', 'ALL') THEN
      SELECT 'Error: informar Date, Date_from o Month' AS Error, v_Version AS Version;
      LEAVE proc_label;
   END IF;
   SET v_Date_from = CONCAT(v_Month, '-01');
   SET v_Date_to   = DATE_FORMAT(LAST_DAY(STR_TO_DATE(v_Date_from, '%Y-%m-%d')), '%Y-%m-%d');
END IF;

IF v_Mode NOT IN ('AFF', 'GES') THEN SET v_Mode = 'GES'; END IF;
IF v_Display NOT IN ('NORMAL', 'TRANSPOSE') THEN SET v_Display = 'NORMAL'; END IF;
IF v_Display = 'TRANSPOSE' THEN SET v_Mode = 'AFF'; END IF;
IF v_Mode IN ('AFF') AND v_Affiliate_id IN ("", "ALL") 
THEN LEAVE proc_label; 
END IF;

SET v_WhereDateFrom = CONCAT(" AND PE.`Date`>='", v_Date_from, "'");
SET v_WhereDateTo   = CONCAT(" AND PE.`Date`<='", v_Date_to, "'");
IF v_Operator      NOT IN ("", "ALL") THEN SET v_WhereOperator   = CONCAT(" AND PE.`Operator`='", v_Operator, "'"); END IF;
IF v_Tracker_ID    NOT IN ("", "ALL") THEN SET v_WhereTracker    = CONCAT(" AND PE.`Tracker_ID`='", v_Tracker_ID, "'"); END IF;
IF v_Account_id    NOT IN ("", "ALL") THEN SET v_WhereAccount    = CONCAT(" AND PE.`Account_id`=", v_Account_id); END IF;
IF v_Affiliate_id  NOT IN ("", "ALL") THEN SET v_Mode = 'AFF'; END IF;
IF v_Affiliate_id  NOT IN ("", "ALL") THEN SET v_WhereAffiliate  = CONCAT(" AND PE.`Affiliate_id`=", v_Affiliate_id); END IF;
IF v_Advertiser_ID NOT IN ("", "ALL") THEN SET v_WhereAdvertiser = CONCAT(" AND PE.`Advertiser_ID`=", v_Advertiser_ID); END IF;
IF v_Op_Code       NOT IN ("", "ALL") THEN SET v_WhereOpCode     = CONCAT(" AND PE.`Op_Code`='", v_Op_Code, "'"); END IF;

IF v_Debug != 'NO' THEN
   SELECT v_Version , v_Month , v_Date, v_Date_from, v_Date_to, v_Operator,v_Tracker_ID, v_Account_id, v_Affiliate_id, v_Advertiser_ID, v_Op_Code,
          v_Mode, v_Display, v_Filters, v_Meta, v_Affly_Origin, InputCommLine;
END IF;

SET @SQL_PB = CONCAT('
tracker_dd_ref AS (
   SELECT
       S.`tracking_code`
      ,S.`tracker_id`
      ,S.`origin`
      ,EXISTS (
          SELECT 1 FROM `campaign_marketing_source` MS
          WHERE MS.`Tracker_ID` = S.`tracking_code`
       ) AS exists_ms_trk_code
      ,EXISTS (
          SELECT 1 FROM `campaign_marketing_source` MS
          WHERE MS.`Tracker_ID` = S.`tracker_id`
       ) AS exists_ms_trk_id
   FROM (
      SELECT
          TRIM(IFNULL(`tracking_code`,"")) AS tracking_code
         ,TRIM(SUBSTRING(TRIM(IFNULL(`tracking_code`,"")), INSTR(TRIM(IFNULL(`tracking_code`,"")), "_") + 1)) AS tracker_id
         ,IFNULL(`origin`,"") AS `origin`
      FROM `postback_inbound_data`
      WHERE IFNULL(`status`,"") != "commission"
        AND `created_at` >= "', v_Date_from, '"
        AND `created_at` <  DATE_ADD("', v_Date_to, '", INTERVAL 1 DAY)
        AND TRIM(IFNULL(`tracking_code`,"")) REGEXP "^[0-9]+_[0-9]+$"
      GROUP BY 1, 3
   ) S
),
postback_inbound AS (
   SELECT
       CASE
            WHEN R.`exists_ms_trk_code` = 1 THEN P.`tracking_code`
            WHEN R.`tracking_code` IS NOT NULL THEN R.`tracker_id`
            ELSE P.`tracking_code`
       END AS Tracker_ID
      ,P.`created_at`
      ,TRIM(IFNULL(P.`click_id`,"")) AS Click_ID
      ,DATE(P.`created_at`) AS `Date`
      ,IFNULL(P.`currency`,"") AS Currency
      ,IFNULL(P.`origin`,"") AS Operator
      ,CASE UPPER(IFNULL(P.`status`,""))
         WHEN "FTD" THEN "FTD"
         WHEN "REG" THEN "REG"
         WHEN "CPA" THEN "CPA"
         ELSE ""
      END AS Op_Code
   FROM `postback_inbound_data` P
   LEFT JOIN tracker_dd_ref R
     ON R.`tracking_code` = TRIM(IFNULL(P.`tracking_code`,""))
    AND R.`origin` = IFNULL(P.`origin`,"")
   WHERE IFNULL(P.`status`,"") != "commission"
     AND P.`created_at` >= "', v_Date_from, '"
     AND P.`created_at` <  DATE_ADD("', v_Date_to, '", INTERVAL 1 DAY)
),
postback_enriched AS (
   SELECT
       D.`Date`
      ,D.`Operator`
      ,AD.`Advertiser_name` AS Brand
      ,CU.`Username`      AS Account
      ,A.`username`       AS Affiliate
      ,M.`id`             AS MS_id
      ,D.`Tracker_ID`
      ,D.`Op_Code`
      ,D.`created_at`
      ,D.`Currency`
      ,CU.`Advertiser_id` AS Advertiser_ID
      ,CU.`Publisher_id`  AS Operator_ID
      ,CU.`id`            AS Account_id
      ,M.`Tracker_name`   AS MS_Tracker_Name
      ,M.`Code_to_Affiliate` AS MS_Code_to_Affiliate
      ,M2.`Affiliate_id`  AS Affiliate_id
      ,D.`Click_ID`
      ,M.`Shortlink_id`   AS MS_Shortlink_id
   FROM postback_inbound D
   LEFT JOIN `campaign_marketing_source` M ON M.`Tracker_ID` = D.`Tracker_ID`
   LEFT JOIN `campaign_username` CU ON M.`Username_id` = CU.`id`
   LEFT JOIN `campaign_advertiser` AD ON CU.`Advertiser_id` = AD.`id`
   LEFT JOIN LATERAL (
      SELECT `Affiliate_id`
      FROM `campaign_mkt_source_deal`
      WHERE `MS_id` = M.`id`
        AND `is_active` = 1
        AND `Deal_Valid_From` <= D.`Date`
      ORDER BY `Deal_Valid_From` DESC, `id` DESC
      LIMIT 1
   ) AS M2 ON TRUE
   LEFT JOIN `account_account` A ON A.`id` = M2.`Affiliate_id`
),
-- Filtros aplicados ANTES del enriquecimiento affly (solo se buscan clics de las filas que se muestran)
PE_base AS (
   SELECT PE.* FROM postback_enriched PE
   WHERE 1=1
   ', v_WhereDateFrom, v_WhereDateTo, v_WhereOperator, v_WhereTracker,
      v_WhereAccount, v_WhereAffiliate, v_WhereAdvertiser, v_WhereOpCode, '
),
', IF(v_Filters = 'YES' OR v_Display = 'TRANSPOSE',
-- Filters / Transpose no usan datos de clic: se omite el acceso a affly
'PE AS (SELECT * FROM PE_base)
',
CONCAT('PE_click AS (
   SELECT B.*
      ,SV.`ip`         AS Click_IP
      ,SV.`country`    AS Click_Country
      ,SV.`user_agent` AS Click_UA
   FROM PE_base B
   -- Clic affly: solo si MS.Shortlink_id es affly.eu/ y el postback trae click_id; si no, NULL
   -- v1.4 Fuente única shortener_visits (shortener_clicks obsoleta), solo URLs con origin = DB actual (', v_Affly_Origin, ')
   LEFT JOIN LATERAL (
      SELECT V.`ip`, V.`country`, V.`user_agent`
      FROM `affly`.`shortener_visits` V FORCE INDEX (`idx_vis_click_id`)
      JOIN `affly`.`shortener_urls` U ON U.`key` = V.`url_key`
      WHERE B.`Click_ID` > ""
        AND IFNULL(B.`MS_Shortlink_id`,"") LIKE "%affly.eu/%"
        AND V.`click_id` = B.`Click_ID`
        AND U.`origin` = "', v_Affly_Origin, '"
      ORDER BY V.`id` DESC
      LIMIT 1
   ) AS SV ON TRUE
),
PE AS (
   SELECT PC.*
      -- IP: último octeto enmascarado
      ,CASE WHEN IFNULL(PC.`Click_IP`,"") = "" THEN NULL
            WHEN LENGTH(PC.`Click_IP`) - LENGTH(REPLACE(PC.`Click_IP`,".","")) = 3
            THEN CONCAT(SUBSTRING_INDEX(PC.`Click_IP`,".",3), ".***")
            ELSE "***" END AS Click_IP_Masked
      -- País: bandera emoji (indicadores regionales U+1F1E6..) + ISO-2
      ,CASE WHEN UPPER(TRIM(IFNULL(PC.`Click_Country`,""))) REGEXP "^[A-Z]{2}$"
            THEN CONCAT(
                  CONVERT(CHAR(127397 + ASCII(UPPER(SUBSTRING(TRIM(PC.`Click_Country`),1,1))) USING utf32) USING utf8mb4),
                  CONVERT(CHAR(127397 + ASCII(UPPER(SUBSTRING(TRIM(PC.`Click_Country`),2,1))) USING utf32) USING utf8mb4),
                  " ", UPPER(TRIM(PC.`Click_Country`)))
            ELSE NULLIF(TRIM(PC.`Click_Country`),"") END AS Click_Country_Flag
      -- Sistema operativo (orden de evaluación relevante)
      ,CASE WHEN IFNULL(PC.`Click_UA`,"") = "" THEN NULL
            WHEN PC.`Click_UA` LIKE "%Windows%" THEN "Windows"
            WHEN PC.`Click_UA` LIKE "%iPhone%" OR PC.`Click_UA` LIKE "%iPad%" OR PC.`Click_UA` LIKE "%iPod%" THEN "iOS"
            WHEN PC.`Click_UA` LIKE "%Android%" THEN "Android"
            WHEN PC.`Click_UA` LIKE "%CrOS%" THEN "ChromeOS"
            WHEN PC.`Click_UA` LIKE "%Macintosh%" OR PC.`Click_UA` LIKE "%Mac OS X%" THEN "macOS"
            WHEN PC.`Click_UA` LIKE "%Linux%" THEN "Linux"
            ELSE "Other" END AS Click_OS
      -- Dispositivo
      ,CASE WHEN IFNULL(PC.`Click_UA`,"") = "" THEN NULL
            WHEN PC.`Click_UA` LIKE "%bot/%" OR PC.`Click_UA` LIKE "%spider%" OR PC.`Click_UA` LIKE "%crawler%" THEN "Bot"
            WHEN PC.`Click_UA` LIKE "%iPad%" OR PC.`Click_UA` LIKE "%Tablet%"
              OR (PC.`Click_UA` LIKE "%Android%" AND PC.`Click_UA` NOT LIKE "%Mobi%") THEN "Tablet"
            WHEN PC.`Click_UA` LIKE "%Mobi%" OR PC.`Click_UA` LIKE "%iPhone%" OR PC.`Click_UA` LIKE "%iPod%" THEN "Mobile"
            ELSE "Desktop" END AS Click_Device
   FROM PE_click PC
)
')), '
');

SET @SQLfilters = CONCAT('
WITH RECURSIVE MonthFilter AS (
   SELECT CURDATE() AS `date`
   UNION ALL
   SELECT DATE_SUB(`date`, INTERVAL 1 MONTH) FROM MonthFilter
   WHERE DATE_SUB(`date`, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
),

', @SQL_PB, '
(SELECT "00" AS Korder, "Period" AS `Key`, "Today" AS Value, "Date" AS CallKey, "TODAY" AS CallValue, "" AS "Rows" FROM DUAL)
UNION ALL
(SELECT "00", "Period", "Yesterday", "Date", "YESTERDAY", "" FROM DUAL)
UNION ALL
(SELECT "00", "Period", "First 15 days", "Date", "FIRST15", "" FROM DUAL)
UNION ALL
(SELECT "00", "Period", "Last 15 days", "Date", "LAST15", "" FROM DUAL)
UNION ALL
(SELECT "00", "Period", "This month", "Month", "THISMONTH", "" FROM DUAL)
UNION ALL
(SELECT "00", "Period", "Custom", "CustomDateRange", "-", "" FROM DUAL)
UNION ALL
(SELECT "01", "Month", LEFT(`date`,7), "Month", LEFT(`date`,7), "" FROM MonthFilter GROUP BY LEFT(`date`,7))
UNION ALL
(SELECT "10", "Operator", Operator, "Operator", Operator, COUNT(*) FROM PE WHERE Operator IS NOT NULL GROUP BY PE.Operator)
UNION ALL
(SELECT "20", "Op_Code", Op_Code, "Op_Code", Op_Code, COUNT(*) FROM PE WHERE Op_Code IS NOT NULL GROUP BY PE.Op_Code)
UNION ALL
(SELECT "30", "Brand", Brand, "advertiser_id", Advertiser_ID, COUNT(*) FROM PE WHERE Advertiser_ID IS NOT NULL GROUP BY PE.Advertiser_ID)
', IF(v_Mode = 'AFF', '', '
UNION ALL
(SELECT "40", "Account", Account, "Account_id", Account_id, COUNT(*) FROM PE WHERE Account_id IS NOT NULL GROUP BY PE.Account_id)
UNION ALL
(SELECT "50", "Affiliate", Affiliate, "Affiliate_id", Affiliate_id, COUNT(*) FROM PE WHERE Affiliate_id IS NOT NULL GROUP BY PE.Affiliate_id)
UNION ALL
(SELECT "60", "Tracker_ID", Tracker_ID, "Tracker_ID", Tracker_ID, COUNT(*) FROM PE WHERE Tracker_ID IS NOT NULL GROUP BY PE.Tracker_ID)
'), '
ORDER BY Korder ASC,
         CASE WHEN Korder = "00" THEN FIELD(CallValue,"TODAY","YESTERDAY","FIRST15","LAST15","THISMONTH","-") END ASC,
         CASE WHEN Korder IN ("01") THEN Value END DESC,
         CASE WHEN Korder NOT IN ("00","01") THEN Value END ASC
');

SET @SQLmeta = CONCAT('
(
SELECT
   "setting" AS Meta
  ,"width=130px" AS Date
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=120px'), '" AS Operator
  ,"width=120px" AS Brand
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=140px,tooltip=yes'), '" AS Account
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=80px'), '" AS `MS id`
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=130px'), '" AS `Tracker_ID`
  ,"width=90px,colorBg=[CPA:green;FTD:orange;REG:yellow;Other:white]" AS `Op Code`
  ,"width=200px" AS `Created_at`
  ,"width=80px" AS Currency
  ,"width=120px" AS `IP`
  ,"width=80px" AS `Country`
  ,"width=90px" AS `OS`
  ,"width=90px" AS `Device`
  ,"omit=yes" AS Advertiser_ID
  ,"omit=yes" AS Operator_ID
  ,"omit=yes" AS Account_id
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=140px,tooltip=yes'), '" AS `Tracker Name`
  ,"width=150px" AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ,"omit=yes" AS Affiliate_id
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=150px,tooltip=yes'), '" AS Affiliate
FROM DUAL WHERE "', v_Meta, '"="YES")
');

SET @SQL = CONCAT('
WITH ', @SQL_PB,
 IF(v_Meta = 'YES', @SQLmeta, ''), '
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"total" AS Meta,', ''), '
   "~~~~~" AS `Date`
  ,"~~~~~" AS Operator
  ,"~~~~~" AS Brand
  ,"~~~~~" AS Account
  ,"~~~~~" AS `MS id`
  ,"TOTAL records" AS `Tracker_ID`
  ,CAST((SELECT COUNT(*) FROM PE) AS CHAR) AS `Op Code`
  ,"~~~~~" AS `Created_at`
  ,"~~~~~" AS Currency
  ,"~~~~~" AS `IP`
  ,"~~~~~" AS `Country`
  ,"~~~~~" AS `OS`
  ,"~~~~~" AS `Device`
  ,"~~~~~" AS Advertiser_ID
  ,"~~~~~" AS Operator_ID
  ,"~~~~~" AS Account_id
  ,"~~~~~" AS `Tracker Name`
  ,"~~~~~" AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ,"~~~~~" AS Affiliate_id
  ,"~~~~~" AS Affiliate
FROM DUAL
)
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"data" AS Meta,', ''), '
   PE.`Date`
  ,PE.`Operator`
  ,PE.`Brand`
  ,PE.`Account`
  ,PE.`MS_id`
  ,PE.`Tracker_ID`
  ,PE.`Op_Code`
  ,PE.`created_at`
  ,PE.`Currency`
  ,PE.`Click_IP_Masked`    AS `IP`
  ,PE.`Click_Country_Flag` AS `Country`
  ,PE.`Click_OS`           AS `OS`
  ,PE.`Click_Device`       AS `Device`
  ,PE.`Advertiser_ID`
  ,PE.`Operator_ID`
  ,PE.`Account_id`
  ,PE.`MS_Tracker_Name`
  ,PE.`MS_Code_to_Affiliate` AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ,PE.`Affiliate_id`
  ,PE.`Affiliate`
FROM PE
)
ORDER BY
  CASE WHEN ', IF(v_Meta = 'YES', 'Meta="setting"', '0=1'), ' THEN 0
       WHEN ', IF(v_Meta = 'YES', 'Meta="total"', 'Tracker_ID="TOTAL records"'), ' THEN 1
       ELSE 2 END,
  Operator, `Date` DESC, Tracker_ID, created_at DESC
');

-- DISPLAY=TRANSPOSE: pivot por Op_Code (Mode=Aff ya forzado)
IF v_Display = 'TRANSPOSE' AND v_Filters != 'YES' THEN
   SET @v_pivot_data = NULL;
   SET @v_pivot_meta = NULL;
   SET @sql_get_pivot = CONCAT(
'WITH ', @SQL_PB, '
SELECT
  GROUP_CONCAT(DISTINCT CONCAT(
    "SUM(CASE WHEN `Op_Code`=", CHAR(34), `Op_Code`, CHAR(34), " THEN 1 ELSE 0 END) AS `", `Op_Code`, "`"
  ) ORDER BY CASE `Op_Code` WHEN "REG" THEN 1 WHEN "FTD" THEN 2 WHEN "CPA" THEN 3 ELSE 9 END, `Op_Code` SEPARATOR ","),
  GROUP_CONCAT(DISTINCT CONCAT(
    CHAR(34), "width=90px,right=true", CHAR(34), " AS `", `Op_Code`, "`"
  ) ORDER BY CASE `Op_Code` WHEN "REG" THEN 1 WHEN "FTD" THEN 2 WHEN "CPA" THEN 3 ELSE 9 END, `Op_Code` SEPARATOR ",")
INTO @v_pivot_data, @v_pivot_meta
FROM PE
WHERE IFNULL(`Op_Code`,"") > ""'
   );
   PREPARE stmt_piv FROM @sql_get_pivot;
   EXECUTE stmt_piv;
   DEALLOCATE PREPARE stmt_piv;

   IF @v_pivot_data IS NULL THEN
      SET @v_pivot_data = '';
      SET @v_pivot_meta = '';
   END IF;

   SET @SQLmeta = CONCAT('
(
SELECT
   "setting" AS Meta
  ,"width=130px" AS `Date`
  ,"width=120px" AS Brand
  ,"width=150px" AS `Marketing source`',
  IF(@v_pivot_meta = '', '', CONCAT(',', @v_pivot_meta)), '
FROM DUAL WHERE "', v_Meta, '"="YES")
');

   SET @SQL = CONCAT('
WITH ', @SQL_PB,
 IF(v_Meta = 'YES', @SQLmeta, ''), '
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"total" AS Meta,', ''), '
   "~~~~~" AS `Date`
  ,"~~~~~" AS Brand
  ,"TOTAL" AS `Marketing source`',
  IF(@v_pivot_data = '', '', CONCAT(',', @v_pivot_data)), '
FROM PE
)
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"data" AS Meta,', ''), '
   PE.`Date`
  ,PE.`Brand`
  ,PE.`MS_Code_to_Affiliate` AS `Marketing source`',
  IF(@v_pivot_data = '', '', CONCAT(',', @v_pivot_data)), '
FROM PE
GROUP BY PE.`Date`, PE.`Brand`, PE.`MS_Code_to_Affiliate`
)
ORDER BY
  CASE WHEN ', IF(v_Meta = 'YES', 'Meta="setting"', '0=1'), ' THEN 0
       WHEN ', IF(v_Meta = 'YES', 'Meta="total"', '`Marketing source`="TOTAL"'), ' THEN 1
       ELSE 2 END,
  `Date` DESC, Brand, `Marketing source`
');
END IF;

IF v_Filters = 'YES' THEN SET @SQL = @SQLfilters; END IF;

IF v_Debug != 'NO' THEN
   SELECT @SQL AS Generated_SQL;
END IF;

IF v_Debug != 'YES' THEN
   SET @v_stmt_sql = @SQL;
   PREPARE stmt1 FROM @v_stmt_sql;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;
