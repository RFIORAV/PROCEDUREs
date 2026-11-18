/*
PROCEDURE_Report_Postback_daily_v1.7.sql - Reporte diario de postbacks inbound

Descripción:
  Lista postbacks (postback_inbound_data) enriquecidos con MS / Account /
  Affiliate / Advertiser y metadatos de clic affly (IP enmascarada, país,
  OS, Dispositivo). Sin Snapshot_day_by_day ni Snapshot_day_by_day_pb.
  Filtros monovalor. Month limitado a los últimos 6 meses.
  Cuentas indirectas: además de la tabla local se leen los postbacks de
  cada db_indirect cuyo esquema tenga postback_inbound_data en este servidor,
  solo para los Tracker_ID de esas cuentas. El origin affly incluye el de
  esas bases (nombre actual e histórico).

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
  Display        =[Normal | Flat | Transpose | Transposed]. OPCIONAL. Default=Normal.
                 Normal/Flat: reporte detallado actual (Flat = alias de Normal).
                 Transpose/Transposed: columnas Date, Brand, [Affiliate solo en Mode=Ges], Marketing source
                 + una columna por cada Op_Code distinto (conteo); primera fila = totales.
                 En Mode=Ges y Mode=Aff aparece en Filters=Yes como Options: Display=Flat/Transposed.
                 En Mode=Aff, si no se informa Display, es Flat.
                 Con Transposed se oculta el filtro Op_Code.
                 Mode=Ges + Transposed admite Affiliate_id=ALL.
                 Mode=Aff exige un único Affiliate_id (ALL no se procesa).
                 Informar Affiliate_id ya NO fuerza Mode=Aff.
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
  call Report_Postback_daily('Display=Transpose,Affiliate_id=13,month=2026-10');
  call Report_Postback_daily('Display=Transpose,Affiliate_id=11,Date_from=2026-09-01,Date_to=2026-09-15,debug=ye');
  call Report_Postback_daily('Mode=Ges,Display=Transposed,Affiliate_id=ALL,month=2026-10');
  call Report_Postback_daily('Mode=Aff,Affiliate_id=13,filters=yes');
  call Report_Postback_daily('Mode=Aff,Affiliate_id=13,Display=Flat,filters=yes');
  call Report_Postback_daily('Mode=Aff,Affiliate_id=13,Display=Transposed');
  call Report_Postback_daily('Mode=Ges,Display=Flat,filters=yes');
  call Report_Postback_daily('Mode=Ges,Display=Transposed,filters=yes');
  call Report_Postback_daily('month=2026-09,Operator=VegasLegends,Op_Code=reg,filters=yes,debug=ye');
  call Report_Postback_daily('Operator=VegasLegends,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-08,Operator=ALL,tracker_id=ALL,account_id=ALL,affiliate_id=ALL,Op_Code=ALL,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-08,Operator=ALL,tracker_id=ALL,account_id=ALL,affiliate_id=ALL,Op_Code=ftd,filters=yes,debug=ye');
  call Report_Postback_daily('month=2026-09,Account_id=257,Tracker_ID=main');
  call Report_Postback_daily_dev('Month=2026-11,Tracker_ID=02dat1');
  call Report_Postback_daily_dev('Month=2026-11,Affiliate_id=998,Mode=AFF,Display=TRANSPOSED');

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
                  Restricción de visitas affly por origin en affly.shortener_urls correspondiente a DATABASE()
                  (contemplando nombres actuales e históricos en shortener_urls.origin);
                  Fuente única affly.shortener_visits (shortener_clicks obsoleta) vía shortener_visits.url_key = shortener_urls.key;
                  Corrección vínculo affly: usar campaign_marketing_source.Shortlink LIKE "%affly.eu/%" (Shortlink_id contiene solo el slug/id);
                  Operator completado con campaign_publisher.Advertiser_Name cuando origin está vacío;
                  Columna Click_ID agregada a la derecha y Created_at movida al final derecho;
                  Currency oculta (omit=yes); MS id y Tracker_ID a continuación de Affiliate; "TOTAL records" en Account;
                  Relleno de totales con blancos en lugar de "~~~~~"
03.11.2026 v1.5   Filters=Yes en Mode=Ges: grupo "Options" con Display=Flat / Transposed (Korder 01);
                  Mode=Aff: Options (Flat/Transposed) igual que Ges; sin Display explícito sigue en Transpose;
                  Display acepta alias FLAT (=NORMAL) y TRANSPOSED (=TRANSPOSE);
                  Display=Transposed: se oculta el filtro Op_Code en Filters=Yes;
                  Display=Transposed ya no fuerza Mode=Aff; Mode=Ges + Transposed admite Affiliate_id=ALL;
                  Mode=Aff solo procesa un afiliado (Affiliate_id obligatorio, ALL → sin resultado);
                  Affiliate_id informado ya NO fuerza Mode=Aff (el modo lo decide solo el parámetro Mode);
                  Transposed en Mode=Ges: columna Affiliate entre Brand y Marketing source (agrupa por afiliado)
                  Filters=Yes: Korder Options=01, Period=03, Month=05; Month solo últimos 4 meses (incl. corriente) en orden DESC;
                  Rows en todos los grupos según la combinación de filtros aplicada: Period/Month cuentan cada periodo
                  con el resto de filtros (sin el de fecha); Options/Custom y demás grupos cuentan el periodo seleccionado
04.11.2026 v1.6   Mode=Aff: si no se informa Display, el default es Flat (ya no Transpose)
14.11.2026 v1.7   Postbacks de cuentas indirectas: UNION con postback_inbound_data de cada
                  db_indirect presente en el servidor (no solo mymonsteraffiliates), limitado
                  a sus Tracker_ID y sin duplicar filas ya existentes en la tabla local.
                  Filtro affly.shortener_urls.origin ampliado con el origin actual e histórico
                  de esas bases. Aplica en cualquier esquema que ejecute el procedure.
*/

DROP PROCEDURE IF EXISTS Report_Postback_daily;
DROP PROCEDURE IF EXISTS Report_Postback_daily_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Postback_daily`(
   IN InputCommLine VARCHAR(550)
)
COMMENT 'v1.7 14.11.2026 Postbacks locales y de db_indirect; clics affly de esos origin; Ges y Aff: Flat/Transposed'
SQL SECURITY DEFINER
proc_label:BEGIN

DECLARE v_Version       VARCHAR(32)  DEFAULT 'v1.7 14.11.2026';
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

DECLARE v_Month_set     BOOLEAN      DEFAULT FALSE; -- K 05.10.2026
DECLARE v_DB            VARCHAR(64)  DEFAULT '';
DECLARE v_OriginFilter  VARCHAR(2000) DEFAULT '';
DECLARE v_OriginList    VARCHAR(2000) DEFAULT '';
DECLARE v_IndirectList  VARCHAR(1000) DEFAULT '';
DECLARE v_IndirectUsed  VARCHAR(500)  DEFAULT '';
DECLARE v_IndirectUnion MEDIUMTEXT;
DECLARE v_OneDb         VARCHAR(64)   DEFAULT '';
DECLARE v_OneOrigins    VARCHAR(300)  DEFAULT '';
DECLARE v_SchemaReal    VARCHAR(64)   DEFAULT '';
DECLARE v_DbExists      INT           DEFAULT 0;
DECLARE v_IndPos        INT           DEFAULT 0;
DECLARE v_Scan_from     VARCHAR(16)  DEFAULT ''; -- v1.5 rango de lectura de postback_inbound_data
DECLARE v_Scan_to       VARCHAR(16)  DEFAULT '';

SET v_Month = LEFT(CURDATE(), 7);
SET v_DB    = LOWER(IFNULL(DATABASE(), ''));

-- Mapeo de esquema actual a valores de affly.shortener_urls.origin (actuales e históricos pre-mayo 2026).
-- v1.7: la lista se amplía, tras resolver el periodo, con los origin de cada db_indirect.
-- El mismo CASE se repite al incorporar cada base indirecta: mantener ambos alineados.
SET v_OriginList = CASE v_DB
   WHEN 'euroaffiliati2'      THEN '"euroaffiliati2","EuroAffiliati"'
   WHEN 'euroaffiliati_dev'   THEN '"euroaffiliati_dev","euroaffiliati2","EuroAffiliati"'
   WHEN 'deally'              THEN '"deally","Deally"'
   WHEN 'affiliaterevolution' THEN '"affiliaterevolution","AffiliateRevolution"'
   WHEN 'mymonsteraffiliates' THEN '"mymonsteraffiliates","MyMonsterAffiliates"'
   WHEN 'fivestars'           THEN '"fivestars","FivestarsAffiliates"'
   WHEN 'gamingaffiliation'   THEN '"gamingaffiliation","GamingAffiliation"'
   WHEN 'brasiliacon'         THEN '"brasiliacon","BrasiliaConnect"'
   ELSE CONCAT('"', REPLACE(v_DB, '"', '""'), '"')
END;

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
IF v_Display = 'FLAT'       THEN SET v_Display = 'NORMAL';    END IF; -- v1.5 alias
IF v_Display = 'TRANSPOSED' THEN SET v_Display = 'TRANSPOSE'; END IF; -- v1.5 alias
IF v_Display NOT IN ('NORMAL', 'TRANSPOSE') THEN SET v_Display = 'NORMAL'; END IF;
-- v1.5: Transposed ya no fuerza Mode=Aff (Mode=Ges + Transposed admite Affiliate_id=ALL)
-- v1.6: Mode=Aff sin Display queda en Flat (NORMAL, default). Transposed solo si se informa.
-- Mode=Aff: solo un afiliado (Affiliate_id obligatorio).
IF v_Mode IN ('AFF') AND v_Affiliate_id IN ("", "ALL")
THEN LEAVE proc_label; 
END IF;

SET v_WhereDateFrom = CONCAT(" AND PE.`Date`>='", v_Date_from, "'");
SET v_WhereDateTo   = CONCAT(" AND PE.`Date`<='", v_Date_to, "'");
IF v_Operator      NOT IN ("", "ALL") THEN SET v_WhereOperator   = CONCAT(" AND PE.`Operator`='", v_Operator, "'"); END IF;
IF v_Tracker_ID    NOT IN ("", "ALL") THEN SET v_WhereTracker    = CONCAT(" AND PE.`Tracker_ID`='", v_Tracker_ID, "'"); END IF;
IF v_Account_id    NOT IN ("", "ALL") THEN SET v_WhereAccount    = CONCAT(" AND PE.`Account_id`=", v_Account_id); END IF;
-- v1.5: Affiliate_id ya no fuerza Mode=Aff
IF v_Affiliate_id  NOT IN ("", "ALL") THEN SET v_WhereAffiliate  = CONCAT(" AND PE.`Affiliate_id`=", v_Affiliate_id); END IF;
IF v_Advertiser_ID NOT IN ("", "ALL") THEN SET v_WhereAdvertiser = CONCAT(" AND PE.`Advertiser_ID`=", v_Advertiser_ID); END IF;
IF v_Op_Code       NOT IN ("", "ALL") THEN SET v_WhereOpCode     = CONCAT(" AND PE.`Op_Code`='", v_Op_Code, "'"); END IF;

-- v1.5 Filters=Yes: se leen los últimos 4 meses (o más si el periodo elegido es anterior) para contar Period/Month;
-- el filtro de fecha se aplica después, en PE
SET v_Scan_from = v_Date_from;
SET v_Scan_to   = v_Date_to;
IF v_Filters = 'YES' THEN
   SET v_Scan_from     = LEAST(v_Date_from, DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%Y-%m-01'));
   SET v_Scan_to       = GREATEST(v_Date_to, DATE_FORMAT(CURDATE(), '%Y-%m-%d'));
   SET v_WhereDateFrom = '';
   SET v_WhereDateTo   = '';
END IF;

-- v1.7: cada cuenta indirecta guarda sus postbacks en <db_indirect>.postback_inbound_data
-- y sus shortlinks affly llevan el origin de esa base. Vale para cualquier esquema actual
-- y cualquier db_indirect (mymonsteraffiliates, fivestars, euroaffiliati2, etc.).
SET v_IndirectUnion = '';
SET v_IndirectUsed  = '';
SELECT IFNULL(GROUP_CONCAT(DISTINCT LOWER(TRIM(`db_indirect`)) ORDER BY LOWER(TRIM(`db_indirect`)) SEPARATOR '^'), '')
INTO v_IndirectList
FROM `campaign_username`
WHERE `is_indirect` = 1
  AND IFNULL(TRIM(`db_indirect`), '') > ''
  AND LOWER(TRIM(`db_indirect`)) <> v_DB;

WHILE v_IndirectList > '' DO
   SET v_IndPos = INSTR(CONCAT(v_IndirectList, '^'), '^');
   SET v_OneDb  = LOWER(TRIM(SUBSTRING(v_IndirectList, 1, v_IndPos - 1)));
   SET v_IndirectList = SUBSTRING(v_IndirectList, v_IndPos + 1);

   IF v_OneDb REGEXP '^[a-z0-9_]+$' AND v_OneDb <> v_DB THEN
      SET v_OneOrigins = CASE v_OneDb
         WHEN 'euroaffiliati2'      THEN '"euroaffiliati2","EuroAffiliati"'
         WHEN 'euroaffiliati_dev'   THEN '"euroaffiliati_dev","euroaffiliati2","EuroAffiliati"'
         WHEN 'deally'              THEN '"deally","Deally"'
         WHEN 'affiliaterevolution' THEN '"affiliaterevolution","AffiliateRevolution"'
         WHEN 'mymonsteraffiliates' THEN '"mymonsteraffiliates","MyMonsterAffiliates"'
         WHEN 'fivestars'           THEN '"fivestars","FivestarsAffiliates"'
         WHEN 'gamingaffiliation'   THEN '"gamingaffiliation","GamingAffiliation"'
         WHEN 'brasiliacon'         THEN '"brasiliacon","BrasiliaConnect"'
         ELSE CONCAT('"', v_OneDb, '"')
      END;
      IF INSTR(v_OriginList, v_OneOrigins) = 0 THEN
         SET v_OriginList = CONCAT(v_OriginList, ',', v_OneOrigins);
      END IF;

      SET v_DbExists = 0;
      SELECT COUNT(*) INTO v_DbExists
      FROM `information_schema`.`TABLES`
      WHERE CONVERT(`TABLE_SCHEMA` USING utf8mb4) = v_OneDb
        AND `TABLE_NAME` = 'postback_inbound_data';

      IF v_DbExists > 0 THEN
         SET v_SchemaReal = '';
         SELECT `TABLE_SCHEMA` INTO v_SchemaReal
         FROM `information_schema`.`TABLES`
         WHERE CONVERT(`TABLE_SCHEMA` USING utf8mb4) = v_OneDb
           AND `TABLE_NAME` = 'postback_inbound_data'
         LIMIT 1;

         SET v_IndirectUsed = CONCAT(v_IndirectUsed, IF(v_IndirectUsed = '', '', '^'), v_SchemaReal);
         SET v_IndirectUnion = CONCAT(v_IndirectUnion, '
   UNION ALL
   SELECT P.`tracking_code`, P.`created_at`, P.`click_id`, P.`currency`, P.`origin`, P.`status`
   FROM `', REPLACE(v_SchemaReal, '`', '``'), '`.`postback_inbound_data` P
   WHERE IFNULL(P.`status`,"") != "commission"
     AND P.`created_at` >= "', v_Scan_from, '"
     AND P.`created_at` <  DATE_ADD("', v_Scan_to, '", INTERVAL 1 DAY)
     AND EXISTS (
        SELECT 1
        FROM `campaign_marketing_source` M
        INNER JOIN `campaign_username` CU ON CU.`id` = M.`Username_id`
        WHERE M.`Tracker_ID` = TRIM(IFNULL(P.`tracking_code`,""))
          AND CU.`is_indirect` = 1
          AND LOWER(TRIM(IFNULL(CU.`db_indirect`,""))) = "', v_OneDb, '"
     )
     AND NOT EXISTS (
        SELECT 1
        FROM `postback_inbound_data` L
        WHERE L.`created_at` = P.`created_at`
          AND TRIM(IFNULL(L.`tracking_code`,"")) = TRIM(IFNULL(P.`tracking_code`,""))
          AND IFNULL(L.`status`,"") = IFNULL(P.`status`,"")
          AND IFNULL(L.`click_id`,"") = IFNULL(P.`click_id`,"")
          AND IFNULL(L.`origin`,"") = IFNULL(P.`origin`,"")
     )');
      END IF;
   END IF;
END WHILE;

SET v_OriginFilter = CONCAT('U.`origin` IN (', v_OriginList, ')');

IF v_Debug != 'NO' THEN
   SELECT v_Version , v_Month , v_Date, v_Date_from, v_Date_to, v_Operator,v_Tracker_ID, v_Account_id, v_Affiliate_id, v_Advertiser_ID, v_Op_Code,
          v_Mode, v_Display, v_Filters, v_Meta, v_DB, v_OriginFilter, v_IndirectUsed, v_Scan_from, v_Scan_to, InputCommLine;
END IF;

SET @SQL_PB = CONCAT('
raw_postback_inbound AS (
   SELECT `tracking_code`, `created_at`, `click_id`, `currency`, `origin`, `status`
   FROM `postback_inbound_data`
   WHERE IFNULL(`status`,"") != "commission"
     AND `created_at` >= "', v_Scan_from, '"
     AND `created_at` <  DATE_ADD("', v_Scan_to, '", INTERVAL 1 DAY)
   ', v_IndirectUnion, '
),
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
      FROM raw_postback_inbound
      WHERE TRIM(IFNULL(`tracking_code`,"")) REGEXP "^[0-9]+_[0-9]+$"
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
   FROM raw_postback_inbound P
   LEFT JOIN tracker_dd_ref R
     ON R.`tracking_code` = TRIM(IFNULL(P.`tracking_code`,""))
    AND R.`origin` = IFNULL(P.`origin`,"")
),
postback_enriched AS (
   SELECT
       D.`Date`
      ,COALESCE(NULLIF(TRIM(D.`Operator`),""), P.`Advertiser_Name`, "") AS Operator
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
      ,M.`Shortlink`      AS MS_Shortlink
   FROM postback_inbound D
   LEFT JOIN `campaign_marketing_source` M ON M.`Tracker_ID` = D.`Tracker_ID`
   LEFT JOIN `campaign_username` CU ON M.`Username_id` = CU.`id`
   LEFT JOIN `campaign_publisher` P ON CU.`Publisher_id` = P.`id`
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
', IF(v_Filters = 'YES',
-- Filters no usa datos de clic; PE = periodo seleccionado, PE_base = últimos 4 meses (para contar Period/Month)
CONCAT('PE AS (SELECT * FROM PE_base WHERE `Date`>="', v_Date_from, '" AND `Date`<="', v_Date_to, '")
'),
IF(v_Display = 'TRANSPOSE',
-- Transpose no usa datos de clic: se omite el acceso a affly
'PE AS (SELECT * FROM PE_base)
',
CONCAT('PE_click AS (
   SELECT B.*
      ,SV.`ip`         AS Click_IP
      ,SV.`country`    AS Click_Country
      ,SV.`user_agent` AS Click_UA
   FROM PE_base B
   -- Clic affly (shortener_visits): solo si MS.Shortlink es affly.eu/, el postback trae click_id y la URL pertenece al origin de esta DB o de una db_indirect
   LEFT JOIN LATERAL (
      SELECT V.`ip`, V.`country`, V.`user_agent`
      FROM `affly`.`shortener_visits` V FORCE INDEX (`idx_vis_click_id`)
      INNER JOIN `affly`.`shortener_urls` U ON U.`key` = V.`url_key`
      WHERE B.`Click_ID` > ""
        AND IFNULL(B.`MS_Shortlink`,"") LIKE "%affly.eu/%"
        AND V.`click_id` = B.`Click_ID`
        AND ', v_OriginFilter, '
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
'))), '
');

SET @SQLfilters = CONCAT('
WITH RECURSIVE MonthFilter AS (
   SELECT CURDATE() AS `date`
   UNION ALL
   SELECT DATE_SUB(`date`, INTERVAL 1 MONTH) FROM MonthFilter
   WHERE DATE_SUB(`date`, INTERVAL 1 MONTH) >= DATE_SUB(DATE_FORMAT(CURDATE(), "%Y-%m-01"), INTERVAL 3 MONTH)
),

', @SQL_PB, '
(SELECT "03" AS Korder, "Period" AS `Key`, "Today" AS Value, "Date" AS CallKey, "TODAY" AS CallValue,
        (SELECT COUNT(*) FROM PE_base WHERE `Date` = CURDATE()) AS "Rows" FROM DUAL)
UNION ALL
(SELECT "03", "Period", "Yesterday", "Date", "YESTERDAY",
        (SELECT COUNT(*) FROM PE_base WHERE `Date` = DATE_SUB(CURDATE(), INTERVAL 1 DAY)) FROM DUAL)
UNION ALL
(SELECT "03", "Period", "First 15 days", "Date", "FIRST15",
        (SELECT COUNT(*) FROM PE_base WHERE `Date` BETWEEN DATE_FORMAT(CURDATE(), "%Y-%m-01") AND DATE_FORMAT(CURDATE(), "%Y-%m-15")) FROM DUAL)
UNION ALL
(SELECT "03", "Period", "Last 15 days", "Date", "LAST15",
        (SELECT COUNT(*) FROM PE_base WHERE `Date` BETWEEN DATE_SUB(CURDATE(), INTERVAL 14 DAY) AND CURDATE()) FROM DUAL)
UNION ALL
(SELECT "03", "Period", "This month", "Month", "THISMONTH",
        (SELECT COUNT(*) FROM PE_base WHERE `Date` >= DATE_FORMAT(CURDATE(), "%Y-%m-01") AND `Date` <= CURDATE()) FROM DUAL)
UNION ALL
(SELECT "03", "Period", "Custom", "CustomDateRange", "-", (SELECT COUNT(*) FROM PE) FROM DUAL)
UNION ALL
(SELECT "05", "Month", LEFT(MF.`date`,7), "Month", LEFT(MF.`date`,7),
        (SELECT COUNT(*) FROM PE_base WHERE LEFT(`Date`,7) = LEFT(MF.`date`,7)) FROM MonthFilter MF)
UNION ALL
(SELECT "01", "Options", "Stacked", "Display", "FLAT", (SELECT COUNT(*) FROM PE) FROM DUAL)
UNION ALL
(SELECT "01", "Options", "Split by OpCode", "Display", "TRANSPOSED", (SELECT COUNT(*) FROM PE) FROM DUAL)
UNION ALL
(SELECT "10", "Operator", Operator, "Operator", Operator, COUNT(*) FROM PE WHERE Operator IS NOT NULL GROUP BY PE.Operator)
', IF(v_Display = 'TRANSPOSE', '', '
UNION ALL
(SELECT "20", "Op_Code", Op_Code, "Op_Code", Op_Code, COUNT(*) FROM PE WHERE Op_Code IS NOT NULL GROUP BY PE.Op_Code)
'), '
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
         CASE WHEN Korder = "01" THEN FIELD(CallValue,"FLAT","TRANSPOSED") END ASC,
         CASE WHEN Korder = "03" THEN FIELD(CallValue,"TODAY","YESTERDAY","FIRST15","LAST15","THISMONTH","-") END ASC,
         CASE WHEN Korder = "05" THEN Value END DESC,
         CASE WHEN Korder NOT IN ("01","03","05") THEN Value END ASC
');

SET @SQLmeta = CONCAT('
(
SELECT
   "setting" AS Meta
  ,"width=130px" AS Date
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=120px'), '" AS Operator
  ,"width=120px" AS Brand
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=140px,tooltip=yes'), '" AS Account
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=150px,tooltip=yes'), '" AS Affiliate
  ,"width=90px,colorBg=[CPA:green;FTD:orange;REG:yellow;Other:white],datatip=`Please note: Today', CHAR(39), 's and yesterday', CHAR(39), 's CPA data is provisional (based on real-time postbacks). Official reconciliation and final validation take place after the operator', CHAR(39), 's API sync (24–48h)`" AS `Op Code`
  ,"omit=yes" AS Advertiser_ID
  ,"omit=yes" AS Operator_ID
  ,"omit=yes" AS Account_id
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=140px,tooltip=yes'), '" AS `Tracker Name`
  ,"width=150px" AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ,"omit=yes" AS Affiliate_id
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=80px'), '" AS `MS id`
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=130px'), '" AS `Tracker_ID`
  ,"omit=yes" AS Currency
  ,"width=120px" AS `IP`
  ,"width=80px" AS `Country`
  ,"width=90px" AS `OS`
  ,"width=90px" AS `Device`
  ,"', IF(v_Mode = 'AFF', 'omit=yes', 'width=190px,tooltip=yes'), '" AS `Click_ID`
  ,"width=200px" AS `Created_at`
FROM DUAL WHERE "', v_Meta, '"="YES")
');

SET @SQL = CONCAT('
WITH ', @SQL_PB,
 IF(v_Meta = 'YES', @SQLmeta, ''), '
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"total" AS Meta,', ''), '
   " " AS `Date`
  ," " AS Operator
  ," " AS Brand
  ,"TOTAL records" AS Account
  ," " AS Affiliate
  ,CAST((SELECT COUNT(*) FROM PE) AS CHAR) AS `Op Code`
  ," " AS Advertiser_ID
  ," " AS Operator_ID
  ," " AS Account_id
  ," " AS `Tracker Name`
  ," " AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ," " AS Affiliate_id
  ," " AS `MS id`
  ," " AS `Tracker_ID`
  ," " AS Currency
  ," " AS `IP`
  ," " AS `Country`
  ," " AS `OS`
  ," " AS `Device`
  ," " AS `Click_ID`
  ," " AS `Created_at`
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
  ,PE.`Affiliate`
  ,PE.`Op_Code`
  ,PE.`Advertiser_ID`
  ,PE.`Operator_ID`
  ,PE.`Account_id`
  ,PE.`MS_Tracker_Name`
  ,PE.`MS_Code_to_Affiliate` AS `', IF(v_Mode = 'AFF', 'Marketing source', 'Code to Affiliate'), '`
  ,PE.`Affiliate_id`
  ,PE.`MS_id`
  ,PE.`Tracker_ID`
  ,PE.`Currency`
  ,PE.`Click_IP_Masked`    AS `IP`
  ,PE.`Click_Country_Flag` AS `Country`
  ,PE.`Click_OS`           AS `OS`
  ,PE.`Click_Device`       AS `Device`
  ,NULLIF(PE.`Click_ID`,"") AS `Click_ID`
  ,PE.`created_at`         AS `Created_at`
FROM PE
)
ORDER BY
  CASE WHEN ', IF(v_Meta = 'YES', 'Meta="setting"', '0=1'), ' THEN 0
       WHEN ', IF(v_Meta = 'YES', 'Meta="total"', 'Account="TOTAL records"'), ' THEN 1
       ELSE 2 END,
  CASE WHEN IFNULL(Operator,"") = "" THEN 1 ELSE 0 END,
  Operator, `Date` DESC, Tracker_ID, `Created_at` DESC
');

-- DISPLAY=TRANSPOSE: pivot por Op_Code (Mode=Aff con un afiliado, o Mode=Ges con Affiliate_id=ALL)
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
    CHAR(34), "width=90px,right=true",
    IF(`Op_Code`="CPA", CONCAT(",datatip=`Please note: Today", CHAR(39), "s and yesterday", CHAR(39), "s CPA data is provisional (based on real-time postbacks). Official reconciliation and final validation take place after the operator", CHAR(39), "s API sync (24–48h)`"), ""),
    CHAR(34), " AS `", `Op_Code`, "`"
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
  ,"width=120px" AS Brand', IF(v_Mode = 'GES', '
  ,"width=150px,tooltip=yes" AS Affiliate', ''), '
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
   " " AS `Date`
  ," " AS Brand', IF(v_Mode = 'GES', '
  ," " AS Affiliate', ''), '
  ,"TOTAL" AS `Marketing source`',
  IF(@v_pivot_data = '', '', CONCAT(',', @v_pivot_data)), '
FROM PE
)
UNION ALL
(
SELECT
   ', IF(v_Meta = 'YES', '"data" AS Meta,', ''), '
   PE.`Date`
  ,PE.`Brand`', IF(v_Mode = 'GES', '
  ,PE.`Affiliate`', ''), '
  ,PE.`MS_Code_to_Affiliate` AS `Marketing source`',
  IF(@v_pivot_data = '', '', CONCAT(',', @v_pivot_data)), '
FROM PE
GROUP BY PE.`Date`, PE.`Brand`', IF(v_Mode = 'GES', ', PE.`Affiliate_id`, PE.`Affiliate`', ''), ', PE.`MS_Code_to_Affiliate`
)
ORDER BY
  CASE WHEN ', IF(v_Meta = 'YES', 'Meta="setting"', '0=1'), ' THEN 0
       WHEN ', IF(v_Meta = 'YES', 'Meta="total"', '`Marketing source`="TOTAL"'), ' THEN 1
       ELSE 2 END,
  `Date` DESC, Brand', IF(v_Mode = 'GES', ', Affiliate', ''), ', `Marketing source`
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
