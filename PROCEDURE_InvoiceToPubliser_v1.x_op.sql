/*
PROCEDURE_InvoiceToPubliser_v1.sql - Report: Invoicing to Publisher

Descripción:
  Procedimiento InvoiceToPubliser.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Month           =[AAAA-MM].            OPCIONAL. Default=Current Month.
Area            =[ALL | forex | gaming ]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | Publisher_id]. OPCIONAL. Default=ALL
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
Brand           =[ALL | NOMBRE de Brand]. OPCIONAL. Default=ALL
Currency        =[EUR | Original].     Moneda a la que se convierten los resultados. Original  No hace conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
HideDetails     =[No | Yes]. OPCIONAL. Default=No
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query. [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call InvoiceToPubliser(' '); -- Asumirá todos los defaults
call InvoiceToPubliser('meta=yes'); -- Asumirá todos los defaults

call InvoiceToPubliser('Debug=KeyValues');
call InvoiceToPubliser('Debug=yes');
call InvoiceToPubliser('Currency=original,Debug=KeyValues');

23.05.2024 V1
29.05.2024 v1.1   Bonus/fee
09.01.2025 V1.2   Filtro por todos los meses (RS)
10.04.2026 v1.3   Meta/filtros: etiqueta Publisher -> Operator; ORDER BY alinea nombre de columna
05.11.2026 v1.4   Meta/filtros: etiqueta total -> subtotal

*/
DROP PROCEDURE IF EXISTS InvoiceToPubliser;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `InvoiceToPubliser`(IN
   InputCommLine    VARCHAR(250)
   )

COMMENT 'v1.4 05.11.2026 Report: Invoicing to Publisher'

BEGIN

DECLARE v_Version           VARCHAR(30);
DECLARE v_Owner             VARCHAR(50);
DECLARE v_Month             VARCHAR(20);
DECLARE v_Advertiser_id     VARCHAR(50);
DECLARE v_Brand             VARCHAR(100);
DECLARE v_Area              VARCHAR(50);
DECLARE v_Publisher_id      VARCHAR(50);
DECLARE v_Currency          VARCHAR(20);
DECLARE v_HideDetails       VARCHAR(10);
DECLARE v_Debug             VARCHAR(20);
DECLARE v_Meta              VARCHAR(10);
DECLARE v_Filters           VARCHAR(10);
DECLARE v_InputCommLine     VARCHAR(500);
DECLARE v_e                 INT;
DECLARE v_c                 INT;
DECLARE v_k                 VARCHAR(100);
DECLARE v_v                 VARCHAR(200);
DECLARE v_WherePublisher_id TEXT;
DECLARE v_WhereAdvertiserID TEXT;
DECLARE v_WhereBrand        TEXT;
DECLARE v_WhereOwner        TEXT;
DECLARE v_WhereArea         TEXT;
DECLARE v_Currency_result   VARCHAR(20);
DECLARE v_Month_Report      VARCHAR(20);
DECLARE v_Kforex            INT;
DECLARE v_SQLmeta           LONGTEXT;
DECLARE v_SQL               LONGTEXT;
DECLARE v_SQLfilters        LONGTEXT;

-- Defaults
SET v_Version      ='v1.4 05.11.2026';
SET v_Owner        ='all';
SET v_Month        =LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET v_Advertiser_id='ALL';
SET v_Brand        ='ALL';
SET v_Area         ='ALL';
SET v_Publisher_id ='ALL';
SET v_Currency     ='EUR';
SET v_HideDetails  ='NO';
SET v_Debug        ='NO';
SET v_Meta         ='YES';
SET v_Filters      ='NO';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

-- IF v_Debug="YES" THEN SELECT v_Owner,v_Month,v_Currency,v_Advertiser_id,v_HideDetails,v_Debug,v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,HideDetails=yes,OrderBy=Profit
-- @InputCommLine: ----5----0----5----0----5----0----5----0--
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='owner'         THEN SET v_Owner        =UPPER(v_v); END IF;
   IF lower(v_k)='month'         THEN SET v_Month        =UPPER(v_v); END IF;
   IF lower(v_k)='area'          THEN SET v_Area         =UPPER(v_v); END IF;
   IF lower(v_k)='publisher_id'  THEN SET v_Publisher_id =UPPER(v_v); END IF;
   IF lower(v_k)='advertiser_id' THEN SET v_Advertiser_id=UPPER(v_v); END IF;
   IF lower(v_k)='brand'         THEN SET v_Brand        =UPPER(v_v); END IF;
   IF lower(v_k)='currency'      THEN SET v_Currency     =UPPER(v_v); END IF;
   IF lower(v_k)='hidedetails'   THEN SET v_HideDetails  =UPPER(v_v); END IF;
   IF lower(v_k)='filters'       THEN SET v_Filters      =UPPER(v_v); END IF;
   IF lower(v_k)='debug'         THEN SET v_Debug        =UPPER(v_v); END IF;
   IF lower(v_k)='meta'          THEN SET v_Meta         =UPPER(v_v); END IF;

END WHILE;

IF v_Debug!="NO" THEN SELECT v_Owner,v_Month,v_Publisher_id,v_Currency,v_Advertiser_id,v_Brand,v_HideDetails,v_Filters,v_Debug,v_Meta,InputCommLine; END IF;

/**************************************************************************************************************/

-- -------------------------------------------------------
SET v_WherePublisher_id='';
SET v_WhereAdvertiserID='';
SET v_WhereBrand='';
SET v_WhereOwner='';
SET v_WhereArea='';

IF v_Owner        !="ALL" THEN SET v_WhereOwner=CONCAT(" AND G.Owner='",v_Owner,"'");                        END IF;
IF v_Area         !="ALL" THEN SET v_WhereArea=CONCAT(" AND G.Area='",v_Area,"'");                           END IF;
IF v_Publisher_id !="ALL" THEN SET v_WherePublisher_id=CONCAT(" AND G.Publisher_id='",v_Publisher_id,"'");   END IF;
IF v_Advertiser_id!="ALL" THEN SET v_WhereAdvertiserID=CONCAT(" AND G.Advertiser_id='",v_Advertiser_id,"'"); END IF;
IF v_Brand        !="ALL" THEN SET v_WhereBrand=CONCAT(" AND G.Brand='",v_Brand,"'");                        END IF;

IF lower(v_Currency)='original' THEN SET v_Currency_result='ALL'; ELSE SET v_Currency_result=UPPER(v_Currency); END IF;

SET v_Month_Report=v_Month;
IF  v_Month = "CM" THEN SET v_Month_Report=LEFT(CURDATE(),7); END IF;                             -- K 16.03.2023
IF  v_Month = "LM" THEN SET v_Month_Report=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF; -- K 16.03.2023

SET v_Kforex=(
   SELECT COUNT(*) FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU` ON `CU`.`id` = `M`.`Username_id`
   WHERE CU.Area="forex"
);
IF v_Debug!="NO" THEN SELECT v_Kforex FROM DUAL; END IF;

-- -----------------------------------------------------------------------------------------------------

-- SET SESSION group_concat_max_len = 200000;

SET v_SQLmeta=CONCAT(
'(
SELECT
   "setting" `Meta`
   ,"width=100px"                         `Date`
   ,"width=100px,omit=true"               `Owner_id`
   ,"width=100px"                         `Owner`
   ,"width=80px,right=true,omit=true"     `Area`
   ,"width=110px,sortable=yes"            `Operator`
   ,"width=100px,omit=true"               `Publisher_id`
   ,"width=110px,sortable=yes"            `Brand`
   ,"width=100px,omit=true"               `Advertiser_id`
   ,"width=200px,sortable=yes"            `Account`
   ,"width=100px,omit=true"               `Username_id`
   ,"width=060px"                         `Curr`
   ,"width=080px,right=true"              `CPA`
   ,"width=100px,right=true"              `CPA Value`
   ,"width=100px,right=true"              `Net Revenue`
   ,"width=100px,right=true"              `RS Value`
   ,"width=120px,right=true"              `Total Commission`
   ,"width=130px"                         `Commission type`
   ,"width=100px,right=true"              `Carry Over`
   ,"width=100px"                         `RS Base`
   ,"width=100px"                         `Product`
   ,"width=100px,right=true"              `RS Carry Over Pend`
   ,"width=100px,right=true"              `RS before CO`
   -- ,"width=100px,omit=true"               `RateExch`

	FROM DUAL WHERE "',v_Meta,'"="YES")'
);
-- -------------------------------
SET v_SQL=CONCAT('
WITH
SetConverted as (
   SELECT
       G.Month          AS Date
      ,G.Owner          as Owner_id
      ,AC.username      as `Owner`
      ,G.Area
      ,G.Publisher
      ,G.Publisher_id
      ,G.Brand          as `Brand`
      ,G.Advertiser_id
      ,G.`Username`
      ,G.Username_id
      ,',IF(v_Currency_result="ALL","G.Data_Currency",CONCAT("'",v_Currency_result,"'")),' as `Data_Currency`
      ,sum(G.CPA)                              as `CPA`
   -- ,sum(getCurrencyConversion(Amount_Credit,Currency,',QUOTE(v_Currency),')) AS Amount      
      ,round(sum(getCurrencyConversion(net_CPA_Val,G.Data_Currency,',QUOTE(v_Currency),')),2)  as `CPA_Value`
      ,round(sum(getCurrencyConversion(Net_Revenue,G.Data_Currency,',QUOTE(v_Currency),')),2)  as `Net_Revenue`
      ,round(sum(getCurrencyConversion(net_RS_Val,G.Data_Currency,',QUOTE(v_Currency),')),2)  as `net_RS_Val`
      ,round(sum(getCurrencyConversion(net_Total_comm,G.Data_Currency,',QUOTE(v_Currency),')),2)  as `Total_Commission`
      ,G.`Comm_type`
      ,case when G.CarryOver="1" then "Yes"   ELSE "" END AS `CarryOver`
      ,case when G.CarryOver="1" then RS_Base ELSE "" END AS `RS_Base`
      ,case when G.CarryOver="1" then Product ELSE "" END AS `Product`
      ,case when G.CarryOver="1" then round(sum(getCurrencyConversion(RS_CarryOver_Pend,G.Data_Currency,',QUOTE(v_Currency),')),2) ELSE "" END as `Pending CO`
      ,case when G.CarryOver="1" then round(sum(getCurrencyConversion(gross_RS_Val,G.Data_Currency,',QUOTE(v_Currency),')),2)      ELSE "" END as `RS before CO`
      -- ,xx.Coef as `RateExch`
      FROM monthly_comms_gestor_v5 G
      LEFT JOIN account_account     AC    ON AC.id=G.Owner
      WHERE G.Month =',CONCAT("'",v_Month_Report,"' ")
         ,v_WhereAdvertiserID
         ,v_WhereBrand
         ,v_WherePublisher_id
         ,v_WhereArea
         ,v_WhereOwner,'
      GROUP BY G.Owner,G.Data_Currency,Publisher_id,Brand,Username_id,CarryOver,RS_Base,Product,`Comm_type`
         having `Total_Commission`<>0 or `Pending CO`<>0
),
SetConverted_total_parcial as (
   SELECT
       ',IF(v_HideDetails="YES",'"data"','"subtotal"'),' as `Meta`,
       Date
      ,Owner_id
      ,`Owner`
      ,"z_tot" as Area -- Para orden de presentacion en grid
      ,Publisher
      ,Publisher_id
      ,"~~~~~"   as Brand
      ,Advertiser_id
      ,"~~~~~"   as `Username`
      ,Username_id
      ,`Data_Currency`
      ,sum(CPA)                         as `CPA`
      ,round(sum(`CPA_Value`),2)        as `CPA_Value`
      ,round(sum(`Net_Revenue`),2)      as `Net_Revenue`
      ,round(sum(`net_RS_Val`),2)       as `net_RS_Val`
      ,round(sum(`Total_Commission`),2) as `Total_Commission`
      ,"~~~~~"     as `a18`
      ,"~~~~~"     as `a12`
      ,"~~~~~"     as `a13`
      ,"~~~~~"     as `a14`
      ,"~~~~~"     as `a15`
      ,"~~~~~"     as `a16`
      -- ,"~~~~~"     as `a17`
      FROM SetConverted G
      GROUP BY G.Owner,G.Data_Currency,Publisher_id -- ,Brand,Username_id,CarryOver,RS_Base,Product,`Comm_type`
         -- having `Total_Commission`<>0 or `Pending CO`<>0
)
,
SetConverted_total_global as (
   SELECT
       "total" as `Meta`,
       "~~~~~"   as `a02`
      ,"~~~~~"   as `a03`
      ,"TOTAL"   as `a04`
      ,"~~~~~"   as `a05`
      ,"~~~~~"   as `a06`
      ,"~~~~~"   as `a07`
      ,"~~~~~"   as `a08`
      ,Advertiser_id
      ,"~~~~~"   as `a09`
      ,Username_id
      ,`Data_Currency`
      ,sum(CPA)                         as `CPA`
      ,round(sum(`CPA_Value`),2)        as `CPA_Value`
      ,round(sum(`Net_Revenue`),2)      as `Net_Revenue`
      ,round(sum(`net_RS_Val`),2)       as `net_RS_Val`
      ,round(sum(`Total_Commission`),2) as `Total_Commission`
      ,"~~~~~"     as `a18`
      ,"~~~~~"     as `a12`
      ,"~~~~~"     as `a13`
      ,"~~~~~"     as `a14`
      ,"~~~~~"     as `a15`
      ,"~~~~~"     as `a16`
      -- ,"~~~~~"     as `a17`
      FROM SetConverted G '
      ,IF(v_Currency_result="ALL","GROUP BY `Data_Currency`",""),'
)
',v_SQLmeta,
'
UNION ALL
(SELECT
   "data" as `Meta`,
   S.*
   FROM SetConverted S
   WHERE "',v_HideDetails,'"!="YES"
   )
UNION ALL (SELECT * FROM SetConverted_total_parcial)
UNION ALL (SELECT * FROM SetConverted_total_global)
ORDER BY `Operator`, Area , Brand, `Account`, Date, `Carry Over`,`RS Base`,Product;'
);
/*
-- Filtros------------------------------------------------------------------------------------
*/
SET v_SQLfilters=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
),
MonthFilterAll AS (
  SELECT  G.Month AS date
   FROM monthly_comms_gestor_v5 G
   GROUP BY G.Month
   ORDER BY G.Month DESC
),  
BaseCount AS (
   SELECT G.*,AC.username AS `Owner_name`
   FROM monthly_comms_gestor_v5 G
   LEFT JOIN account_account     AC    ON AC.id=G.Owner
      WHERE G.Month =',CONCAT("'",v_Month_Report,"' ")
         ,v_WhereAdvertiserID
         ,v_WhereBrand
         ,v_WherePublisher_id
         ,v_WhereArea
         ,v_WhereOwner,'
      GROUP BY G.Owner,G.Data_Currency,Publisher_id,Brand,Username_id,CarryOver,RS_Base,Product
         having `net_Total_comm`<>0 or `RS_CarryOver_Pend`<>0
)

(SELECT "01" as "Korder","Date" AS "Key",LEFT(`Date`,7) AS `Value`
                                       ,"Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`
                                                                         ,"" AS "Rows" FROM MonthFilterAll) UNION ALL
(SELECT "02","Criteria"   ,"Original Currency" ,"Currency","original"    ,"" AS K       FROM DUAL) UNION ALL
(SELECT "03","Criteria"   ,"Hide Accounts","HideDetails","yes"           ,"" AS K       FROM DUAL) UNION ALL
(SELECT "09","Operator"  ,`Publisher`  ,"Publisher_id" ,`Publisher_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Publisher`  >" " GROUP BY IFNULL(`Publisher`  ,"")) UNION ALL
(SELECT "13","Brand" 	  ,`Brand` 	    ,"Advertiser_id",`Advertiser_id` ,COUNT(*) AS K FROM BaseCount WHERE `Brand` >" "      GROUP BY IFNULL(`Brand` ,""))      UNION ALL
(SELECT "18","Area"       ,`Area`       ,"Area"         ,`Area`          ,"" AS K       FROM BaseCount WHERE ',v_Kforex,'>0 AND `Area`>" " GROUP BY IFNULL(`Area`,"")) UNION ALL
(SELECT "05","Owner"      ,`Owner_name` ,"Owner"        ,`Owner`         ,COUNT(*) AS K FROM BaseCount WHERE `Owner`      >" " GROUP BY IFNULL(`Owner`      ,""))
-- ORDER BY 1,3
ORDER BY 1, CASE WHEN `CallKey`!="Month" THEN `Value` ELSE NULL END ASC
          , CASE WHEN `CallKey` ="Month" THEN `Value` ELSE NULL END DESC
;');
 
IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug!="YES" THEN
	SET @v_sql_exec=v_SQL;
	PREPARE stmt1 FROM @v_sql_exec;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
Ejemplos:

call InvoiceToPubliser(''); 			-- Asumirá todos los defaults
call InvoiceToPubliser('month=lm,HideDetails=yes,Currency=original,filters=ye,Debug=ye');
call InvoiceToPubliser('Publisher_id=13,filters=ye,Debug=yes');
call InvoiceToPubliser('filters=yes,Debug=ye');
call InvoiceToPubliser('owner=2,filters=ye,HideDetails=ye,Currency=original,Debug=ye');
*/
