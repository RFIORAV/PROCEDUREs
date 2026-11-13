/*
PROCEDURE_Affiliate_Monthly_Sources_v1.6.9_mov.sql - Detailed Reports Affiliate

Descripción:
  Procedimiento Affiliate_Monthly_Sources.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id     =[id de affiliate]
Month            =[CM | LM | AAAA-MM]. OPCIONAL. Default=CM. Se ignora si Date_from y Date_to vienen informados.
Date_from        =[AAAA-MM-DD | AAAA.MM.DD]. OPCIONAL. Inicio del rango Custom. Si falta y hay Date_to, Date_from=Date_to.
Date_to          =[AAAA-MM-DD | AAAA.MM.DD]. OPCIONAL. Fin del rango Custom. Si falta y hay Date_from, Date_to=Date_from.
                 Si el rango queda informado, GroupByMonth=No y filtra por fecha en lugar de Month.
Channel_id       =[ALL | id de Channel. OPCIONAL.] Default=ALL
Product          =[ALL | Product. OPCIONAL.] Default=ALL
Brand_id         =[ALL | id de Brand. OPCIONAL.] Default=ALL
Tracker_id       =[ALL | Code_To_Affiliate. OPCIONAL.] Default=ALL
GroupTrackers    =[No | Yes]. OPCIONAL. Acumula por MS. Default [No]
Mode             =[ | Stat]. OPCIONAL. Default en blanco. Stat oculta Product, Deal, Currcy, CPA Value, Rev Share y Total Commis. y fuerza GroupByMonth=No.
Filters          =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta             =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug            =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Affiliate_Monthly_Sources('Affiliate_id=469,debug=ye'); 
call Affiliate_Monthly_Sources('debug=ye'); -- Todos los valores de selección por default usando _fact2
call Affiliate_Monthly_Sources('Affiliate_id=469,FILTERS=YES,meta=yes,debug=ye');
call Affiliate_Monthly_Sources('Affiliate_id=469,month=cM,FILTERS=YE,meta=yes,debug=ye');
call Affiliate_Monthly_Sources('Affiliate_id=469,Mode=Stat,meta=yes,debug=ye');
call Affiliate_Monthly_Sources('Affiliate_id=469,Date_from=2026-09-01,Date_to=2026-09-15,filters=yes,debug=ye');
call Affiliate_Monthly_Sources('Affiliate_id=469,Date_from=2026-09-10,debug=ye');

01.08.2023 V1     Karen. Primera versión operativa
                  Cambios para mostrar Deal
08.08.2023 V1.2   Agregado totales     
11.10.2023 v1.3   Agregado filtro por Tracker_id (Code_To_Affiliate)
08.03.2024 v1.4   Agregada: Opción GroupTrackers
27.05.2024 v1.5   Tratamiento de Subafiliados
06.08.2024 v1.6   Multi-currency
18.11.2024 v1.6.1 Fix suma (restaba)
19.12.2025 v1.6.2 Agregada: Opción GroupByMonth para agrupar por mes
07.03.2026 v1.6.3 Agregada: Opción ShowDepositsAff en util_settings para mostrar/ocultar columna Deposits
07.03.2026 v1.6.4 Conversión a variables locales
07.03.2026 v1.6.5 Ocultar columna Device. Mostrar GroupTrackers y GroupByMonth en Source y Product.
20.07.2026 v1.6.6 Columnas CPA_Value_Affiliate y Revenue_Share_Affiliate si RS_Status=1 (omit=yes por defecto)
23.09.2026 v1.6.7 Parámetro Mode=Stat (oculta Product/Deal/Currcy/CPA Value/Rev Share/Total Commis.) y filtro OnlyStats
25.09.2026 v1.6.8 Fix comillas en Meta de Deposit (ShowDepositsAff)
03.11.2026 v1.6.9 Totales: "~" reemplazado por blanco. Filtro Period/Custom (Date_from/Date_to);
                  si el rango queda informado, GroupByMonth=No y reemplaza el filtro Month
*/

DROP PROCEDURE IF EXISTS Affiliate_Monthly_Sources_dev;
DROP PROCEDURE IF EXISTS Affiliate_Monthly_Sources;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Affiliate_Monthly_Sources`(IN
   InputCommLine    VARCHAR(500)
   )
    COMMENT 'v1.6.9 03.11.2026 Detailed Reports - Affiliate. Custom Date_from/Date_to'
proc_label:BEGIN

DECLARE v_Version         VARCHAR(30)  DEFAULT 'v1.6.9 03.11.2026';
DECLARE v_Month           VARCHAR(7)   DEFAULT LEFT(CURDATE(),7);
DECLARE v_Date_from       VARCHAR(16)  DEFAULT '';
DECLARE v_Date_to         VARCHAR(16)  DEFAULT '';
DECLARE v_Affiliate_id    VARCHAR(30)  DEFAULT '';
DECLARE v_Channel_id      VARCHAR(30)  DEFAULT 'ALL';
DECLARE v_Product         VARCHAR(100) DEFAULT 'ALL';
DECLARE v_Brand_id        VARCHAR(30)  DEFAULT 'ALL';
DECLARE v_Tracker_id      VARCHAR(150) DEFAULT 'ALL';
DECLARE v_GroupTrackers   VARCHAR(3)   DEFAULT 'NO';
DECLARE v_GroupByMonth    VARCHAR(3)   DEFAULT 'YES';
DECLARE v_Mode            VARCHAR(10)  DEFAULT '';
DECLARE v_Debug           VARCHAR(20)  DEFAULT 'NO';
DECLARE v_Meta            VARCHAR(3)   DEFAULT 'YES';
DECLARE v_Filters         VARCHAR(3)   DEFAULT 'NO';
DECLARE v_InputCommLine   VARCHAR(500);
DECLARE v_e               INT;
DECLARE v_c               INT;
DECLARE v_k               VARCHAR(100);
DECLARE v_v               VARCHAR(200);
DECLARE v_Month_Report    VARCHAR(7);
DECLARE v_MultiCurrency   VARCHAR(10);
DECLARE v_Currency        VARCHAR(10);
DECLARE v_ShowDepositsAff VARCHAR(10);
DECLARE v_WhereChannel_id TEXT;
DECLARE v_WhereTracker_id TEXT;
DECLARE v_WhereProduct    TEXT;
DECLARE v_WhereBrand_id   TEXT;
DECLARE v_WhereAffiliate_id TEXT;
DECLARE v_WhereMonth      TEXT;
DECLARE v_AffiliateGroup  INT;
DECLARE v_Affiliate_RS_Status INT;
DECLARE v_SQLmeta         LONGTEXT;
DECLARE v_SQLTable        LONGTEXT;
DECLARE v_SQLdetail       LONGTEXT;
DECLARE v_SQL             LONGTEXT;
DECLARE v_SQLfilters      LONGTEXT;

SET v_InputCommLine=Concat(InputCommLine ,',');      

SET v_InputCommLine=replace(v_InputCommLine,'"','');  

WHILE v_InputCommLine>' ' DO

   SET v_e=INSTR(v_InputCommLine,'=');    				   
   SET v_c=INSTR(v_InputCommLine,','); 					   
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);   

   IF lower(v_k)='month'         THEN SET v_Month        =UPPER(v_v); END IF;
   IF lower(v_k)='date_from'     THEN SET v_Date_from    =v_v; END IF;
   IF lower(v_k)='date_to'       THEN SET v_Date_to      =v_v; END IF;
   IF lower(v_k)='affiliate_id'  THEN SET v_Affiliate_id =UPPER(v_v); END IF;
	IF lower(v_k)='channel_id'    THEN SET v_Channel_id   =UPPER(v_v); END IF;
	IF lower(v_k)='tracker_id'    THEN SET v_Tracker_id   =UPPER(v_v); END IF;
   IF lower(v_k)='product'       THEN SET v_Product      =UPPER(v_v); END IF;
	IF lower(v_k)='brand_id'      THEN SET v_Brand_id     =UPPER(v_v); END IF;
	IF lower(v_k)='grouptrackers' THEN SET v_GroupTrackers=UPPER(v_v); END IF;
   IF lower(v_k)='groupbymonth'  THEN SET v_GroupByMonth =UPPER(v_v); END IF;
   IF lower(v_k)='mode'          THEN SET v_Mode         =UPPER(v_v); END IF;
   IF lower(v_k)='debug'         THEN SET v_Debug        =UPPER(v_v); END IF;
   IF lower(v_k)='filters'       THEN SET v_Filters      =UPPER(v_v); END IF;
   IF lower(v_k)='meta'          THEN SET v_Meta         =UPPER(v_v); END IF;

END WHILE;

IF v_Mode='STAT' THEN SET v_GroupByMonth='NO'; END IF;

IF v_Month='CM' THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF v_Month='LM' THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- Rango Custom: AAAA-MM-DD o AAAA.MM.DD. Si falta uno, copia el otro.
SET v_Date_from=REPLACE(v_Date_from,'.','-');
SET v_Date_to  =REPLACE(v_Date_to,  '.','-');
IF v_Date_from NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET v_Date_from=''; END IF;
IF v_Date_to   NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN SET v_Date_to='';   END IF;
IF v_Date_from!='' AND STR_TO_DATE(v_Date_from,'%Y-%m-%d') IS NULL THEN SET v_Date_from=''; END IF;
IF v_Date_to  !='' AND STR_TO_DATE(v_Date_to,  '%Y-%m-%d') IS NULL THEN SET v_Date_to='';   END IF;
IF v_Date_from!='' AND v_Date_to='' THEN SET v_Date_to=v_Date_from; END IF;
IF v_Date_to  !='' AND v_Date_from='' THEN SET v_Date_from=v_Date_to; END IF;
IF v_Date_from!='' AND v_Date_from>v_Date_to THEN
   SET v_v=v_Date_from; SET v_Date_from=v_Date_to; SET v_Date_to=v_v;
END IF;
-- Con rango informado se detalla por día y se ignora Month
IF v_Date_from!='' AND v_Date_to!='' THEN SET v_GroupByMonth='NO'; END IF;

SET v_Month_Report=v_Month;

IF   v_Affiliate_id IN ("","ALL") THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

-- Obtiene v_MultiCurrency, v_Currency y v_ShowDepositsAff desde tabla util_settings
SET v_MultiCurrency=  (SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET v_Currency=       (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');
SET v_ShowDepositsAff=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='ShowDepositsAff');
-- ---------------------------------------------------------------------------------------------------
SET v_Affiliate_RS_Status = IFNULL((SELECT Check_RS_affiliate(CAST(v_Affiliate_id AS SIGNED))), 0);
-- ---------------------------------------------------------------------------------------------------

SET v_WhereChannel_id ='';
SET v_WhereTracker_id ='';
SET v_WhereProduct ='';
SET v_WhereBrand_id ='';

SET v_WhereAffiliate_id=CONCAT(' AND `Affiliate_id`=',v_Affiliate_id);
IF v_Date_from!='' AND v_Date_to!='' THEN
   SET v_WhereMonth=CONCAT(' AND `Date`>="',v_Date_from,'" AND `Date`<="',v_Date_to,'"');
ELSE
   SET v_WhereMonth=CONCAT(' AND LEFT(`Date`,7)="',v_Month,'"');
END IF; 

IF v_Channel_id !="ALL" THEN SET v_WhereChannel_id=CONCAT(' AND Channel_id=',v_Channel_id); END IF;
IF v_Tracker_id !="ALL" THEN SET v_WhereTracker_id=CONCAT(' AND Code_To_Affiliate="',v_Tracker_id,'"'); END IF;
IF v_Product    !="ALL" THEN SET v_WhereProduct   =CONCAT(' AND Product_Real="',v_Product,'"'); END IF;
IF v_Brand_id   !="ALL" THEN SET v_WhereBrand_id  =CONCAT(' AND Advertiser_id=',v_Brand_id);  END IF;

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET v_AffiliateGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=v_Affiliate_id AND  group_id=6);
IF  v_AffiliateGroup IS NULL THEN SET v_AffiliateGroup=0; END IF;
/*---------------------------------------------------------------------------------*/

IF v_Debug!="NO" THEN SELECT v_AffiliateGroup,v_Month,v_Date_from,v_Date_to,v_GroupByMonth,v_WhereAffiliate_id,v_WhereMonth,v_WhereChannel_id,v_WhereProduct
                           ,v_WhereBrand_id,v_WhereTracker_id; END IF;

-- SET SESSION group_concat_max_len = 200000;
      
/* ------------------------------------------------------------------- */

SET v_SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"width=100px" as              `Date`
	,"width=120px,action=2" as     `Logo`
   ,"width=120px" as              `Brand`    
   ,if("',v_GroupTrackers,'"="YES" or "',v_GroupByMonth,'"="YE","omit=true","width=120px") as `Source`
   ,if("',v_Mode,'"="STAT" or "',v_GroupTrackers,'"="YES" or "',v_GroupByMonth,'"="YE","omit=true","width=100px") as `Product`
   ,if("',v_Mode,'"="STAT" or "',v_GroupTrackers,'"="YES" or "',v_GroupByMonth,'"="YE","omit=true","width=250px,tooltip=yes") as `Deal`
   ,"width=090px,right=true" as   `CPA`
   ,if("',v_Mode,'"="STAT","omit=true","width=090px,right=true") as `Currcy`
   ,if("',v_Mode,'"!="STAT" and ',IFNULL(v_Affiliate_RS_Status,0),'=1,"width=090px,right=true","omit=true") as `CPA Value`
   ,if("',v_Mode,'"!="STAT" and ',IFNULL(v_Affiliate_RS_Status,0),'=1,"width=090px,right=true","omit=true") as `Rev Share`
	,if("',v_Mode,'"="STAT","omit=true","width=090px,right=true") as `Total Commis.`
   ,"width=080px,right=true" as   `FTD`
   ,"width=080px,right=true" as   `Views`
   ,"width=080px,right=true" as   `Clicks`
   ,"width=090px,right=true" as   `Signups`
   ,"omit=true"              as   `Impress.`
   ,if("',v_Mode,'"!="STAT" and "',IFNULL(v_ShowDepositsAff,"NO"),'"="YES","width=090px,right=true","omit=true") as `Deposit`
   ,"omit=true" as                `Device`
   ,if("',v_Mode,'"="STAT","omit=true","width=300px") as `Channel`
   -- ,"omit=yes"    as              `id`                                     
FROM DUAL WHERE "',v_Meta,'"="YES")
'
);

SET v_SQLTable = CONCAT(
' Snapshot_day_by_day_fact2 f
   LEFT JOIN campaign_deal_affiliate d on d.id=f.Deal_Aff_id
   WHERE 1=1 AND (`Qualified_Players`<>0 OR `CPA_Value_Affiliate`<>0 OR `Revenue_Share_Affiliate`<>0  
   OR `First_Time_Deposit`<>0 OR `Views`<>0 OR `Clicks`<>0 OR `Signups`<>0 OR `Deposits`<>0) 
    '
     ,v_WhereAffiliate_id,
      v_WhereMonth,
      v_WhereChannel_id,
      v_WhereTracker_id,
      v_WhereProduct,
      v_WhereBrand_id);

SET v_SQLdetail=CONCAT(
' UNION ALL (
 SELECT
   "data"  Meta
   ,IF("',v_GroupByMonth,'"="YES",LEFT(DATE,7),DATE) as `Date`
	,"" as logo
   ,`Brand`
   ,`Code_To_Affiliate`
   ,`Product_Real`            as `Product`
   ,d.Deal_Name            -- Deal_Aff
   ,sum(`Qualified_Players`) as `CPA`
   ,Data_Currency            as `Currency` 
   ,sum(`CPA_Value_Affiliate`) as `CPA Value`
   ,sum(`Revenue_Share_Affiliate`) as `Rev Share`
   -- ,SUM(
      -- getCurrencyConversion(CPA_Value_Affiliate,Data_Currency,v_Currency)+
      -- getCurrencyConversion(ifnull(`Revenue_Share_Affiliate`,0),Data_Currency,v_Currency)
      -- )  as `Tot_Comm`    
   ,sum(`CPA_Value_Affiliate`+`Revenue_Share_Affiliate`) as `Tot_Comm`
   ,sum(`First_Time_Deposit`) as `First_Time_Deposit`
   ,sum(`Views`             ) as `Views`             
   ,sum(`Clicks`            ) as `Clicks`            
   ,sum(`Signups`           ) as `Signups`           
   ,sum(`Impressions`       ) as `Impressions`       
   ,sum(`Deposits`          ) as `Deposits`       
   ,`Type`     
   ,`Channel`
	-- ,`id` 
	FROM'
 ,v_SQLTable,
 '
 	GROUP BY ',
   IF(v_GroupByMonth="YES","LEFT(DATE,7),","DATE,"),
   '`Brand`',
   IF(v_GroupTrackers="YES","",",`Code_To_Affiliate`,`Product_Real`,Deal_Aff_id"),
   '
 ) 
  UNION ALL (
 SELECT
   "total"  Meta
   ,"      " as `Date`
	,""  	    as `logo`
   ,"     "  as `Brand`
   ,"     "  as `Code_To_Affiliate`
   ,"     "  as `Product_Real`
   ,"     "  as `Deal_Aff`
   ,sum(`Qualified_Players`) as `CPA`
   ,Data_Currency  as `Currency`
   ,sum(`CPA_Value_Affiliate`) as `CPA Value`
   ,sum(`Revenue_Share_Affiliate`) as `Rev Share`
   -- ,SUM(
      -- getCurrencyConversion(CPA_Value_Affiliate,Data_Currency,v_Currency)+
      -- getCurrencyConversion(ifnull(`Revenue_Share_Affiliate`,0),Data_Currency,v_Currency)
      -- )  as `Tot_Comm`   
   ,sum(`CPA_Value_Affiliate`+Revenue_Share_Affiliate) as `Tot_Comm`   -- 18.11.2024
   ,sum(`First_Time_Deposit`) as `First_Time_Deposit`
   ,sum(`Views`             ) as `Views`             
   ,sum(`Clicks`            ) as `Clicks`            
   ,sum(`Signups`           ) as `Signups`           
   ,sum(`Impressions`       ) as `Impressions`       
   ,sum(`Deposits`          ) as `Deposits`          
   ,"     "  as `Type`     
   ,"     "  as `Channel`
	-- ,"~~~~~"  as `id` 
	FROM'
 ,v_SQLTable,'
 GROUP BY Data_Currency)
 ORDER BY `Date`,`Brand`,`Source` '
);
   
SET v_SQL = CONCAT(
   v_SQLmeta,
   v_SQLdetail
,';');

/* FILTERING -------------------------------------------------------*/

SET v_SQLfilters=CONCAT(   
'
WITH RECURSIVE months_cte AS (
  SELECT 0 AS month_offset, LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH), 7) AS month_value
  UNION ALL
  SELECT month_offset + 1, LEFT(DATE_SUB(CURDATE(), INTERVAL (month_offset + 1) MONTH), 7)
  FROM months_cte
  WHERE month_offset < 7
)
(SELECT "00" as "Korder","Period" AS "Key","Custom" AS "Value","CustomDateRange" AS `CallKey`,"-" AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01" as "Korder", "Month" AS "Key", month_value AS "Value", "Month" AS `CallKey`, month_value AS "CallValue", "" AS "Rows"
FROM months_cte) UNION ALL

(SELECT "03" as "Korder","Additional Options" AS "Key","Detail by day"   AS "Value","GroupByMonth" AS `CallKey`,"NO" AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "03" as "Korder","Additional Options" AS "Key","Group trackers"  AS "Value","GroupTrackers" AS `CallKey`,"yes" AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "03" as "Korder","Additional Options" AS "Key","Only Stats"       AS "Value","Mode" AS `CallKey`,"STAT" AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "05" as "Korder","Brand"   AS "Key",`Brand`        AS "Value" ,"Brand_id"    AS `CallKey`,`Advertiser_id`  AS "CallValue" ,COUNT(*) AS "Rows" FROM ',v_SQLTable,' GROUP BY Advertiser_id) UNION ALL
(SELECT "07" as "Korder","Product" AS "Key",`Product_Real` AS "Value" ,"Product"     AS `CallKey`,`Product_Real`   AS "CallValue" ,COUNT(*) AS "Rows" FROM ',v_SQLTable,' and  IFNULL(Product_Real,"")>"" GROUP BY Product_Real) UNION ALL
(SELECT "09" as "Korder","Channel" AS "Key",`Channel`      AS "Value" ,"Channel_id"  AS `CallKey`,`Channel_id`     AS "CallValue" ,COUNT(*) AS "Rows" FROM ',v_SQLTable,' GROUP BY Channel_id) UNION ALL
(SELECT "11" as "Korder","Tracker" AS "Key",`Code_To_Affiliate` AS "Value" ,"Tracker_id"  AS `CallKey`,`Code_To_Affiliate` AS "CallValue" ,COUNT(*) AS "Rows" FROM ',v_SQLTable,' GROUP BY Code_To_Affiliate)
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3 asc
;');

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
IF  v_AffiliateGroup=6 THEN
    SET v_SQL=REPLACE(v_SQL,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
--  SET v_SQL=REPLACE(v_SQL,"campaign_marketing_source","sub_campaign_marketing_source");
--  SET v_SQL=REPLACE(v_SQL,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
--  SET v_SQL=REPLACE(v_SQL,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
--  SET v_SQL=REPLACE(v_SQL,"account_landing_pages","sub_account_landing_pages");
--  SET v_SQL=REPLACE(v_SQL,"account_payment_methods","sub_account_payment_methods");
--  SET v_SQL=REPLACE(v_SQL,"account_account_bills","sub_account_account_bills");
--  SET v_SQL=REPLACE(v_SQL,"view_monthly_fact_aff4","sub_view_monthly_fact_aff4");
END IF;
/*---------------------------------------------------------------------------------*/
IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;   
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Debug != "YES" THEN 
   SET @SQL_Affiliate_Monthly_Sources=v_SQL;
	PREPARE stmt1 FROM @SQL_Affiliate_Monthly_Sources;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;   
END IF;

END$$
DELIMITER ;

/* Test

CALL Affiliate_Monthly_Sources_dev('Affiliate_id=190,month=cm,filters=ye,debug=yes');
CALL Affiliate_Monthly_Sources_dev('Affiliate_id=506,month=2023-09,filters=yes,debug=ye');
CALL Affiliate_Monthly_Sources_dev('Affiliate_id=39,month=lm,GroupTrackers=no,meta=yes,filters=ye,debug=ye');

call Affiliate_Monthly_Sources_dev('Affiliate_id=39,Month=LM,filters=ye,debug=ye');  -- sub aff

WITH RECURSIVE MonthFilter AS (
  SELECT CURDATE() AS date_begin
  UNION ALL
  SELECT left(date_sub(date_begin, interval 1 month),7)
  SELECT "01" as "Korder","Month" AS "Key",v_M0   AS "Value","Month"    AS `CallKey`,v_M0   AS "CallValue","" AS "Rows" FROM DUA
)
SELECT * FROM numbers;
*/