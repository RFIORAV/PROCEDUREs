/*
PROCEDURE_Report_DashTotalByMonth.sql - Report Dashboard Total By Month

Descripción:
  Procedimiento Report_DashTotalByMonth.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Year            =[ALL | Año]. OPCIONAL. Default=ALL
Month           =[ALL | Mes]. OPCIONAL. Default=ALL
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Misc            =[Refresh]. OPCIONAL. Refresca los datos. Default=NO 
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [Yes]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_DashTotalByMonth('debug=ye'); -- Devuelve todas las líneas
call Report_DashTotalByMonth('year=2026,owner=fullmt,debug=ye');
call Report_DashTotalByMonth('year=2026,month=01,owner=fullmt,debug=ye');
call Report_DashTotalByMonth('year=2026,filters=yes,debug=ye');

03.12.2025 V1     Primera versión operativa
28.02.2026 V1.1   Fix: eliminación de variables globales
15.04.2026 v1.2   Se agrega filtro funcional por Month y opción en Filters

*/

DROP PROCEDURE IF EXISTS Report_DashTotalByMonth;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_DashTotalByMonth`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Dashboard Total By Month'
    
proc_label:BEGIN
DECLARE v_Version         VARCHAR(30);
DECLARE v_CurrentDay      DATE;
DECLARE v_Year            VARCHAR(10);
DECLARE v_Owner           VARCHAR(100);
DECLARE v_Filters         VARCHAR(10);
DECLARE v_Meta            VARCHAR(10);
DECLARE v_Debug           VARCHAR(20);
DECLARE v_Month           VARCHAR(20);
DECLARE v_Misc            VARCHAR(50);
DECLARE v_InputCommLine   VARCHAR(500);
DECLARE v_e               INT;
DECLARE v_c               INT;
DECLARE v_k               VARCHAR(100);
DECLARE v_v               VARCHAR(250);
DECLARE v_WhereYear       TEXT;
DECLARE v_WhereOwner      TEXT;
DECLARE v_WhereMonth      TEXT;
DECLARE v_Count           INT;
DECLARE v_OwnerTotalLabel VARCHAR(100);
DECLARE v_CTE             LONGTEXT;
DECLARE v_SQLmeta         LONGTEXT;
DECLARE v_SQL             LONGTEXT;
DECLARE v_SQLfilters      LONGTEXT;

-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.2 15.04.2026';
SET v_CurrentDay      =curdate();
SET v_Year            =left(curdate(),4);
-- SET v_Owner           =case when database()='euroaffiliati2' then 'All Owners' else 'ALL' end;
SET v_Owner           ='ALL';
SET v_Filters         ='NO';
SET v_Meta            ='YES';
SET v_Debug           ='NO';
SET v_Month           ='ALL';
SET v_Misc            ='';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET v_InputCommLine=replace(v_InputCommLine,'"',''); -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
   SET v_e=INSTR(v_InputCommLine,'=');    				-- Posición del =
   SET v_c=INSTR(v_InputCommLine,','); 					-- Posición de la coma
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			-- Key
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); -- Value
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='year'            THEN SET v_Year            =      v_v;  END IF;
   IF lower(v_k)='owner'           THEN SET v_Owner           =replace(UPPER(v_v),"!"," ");  END IF;
   IF lower(v_k)='meta'            THEN SET v_Meta            =UPPER(v_v); END IF;
   IF lower(v_k)='debug'           THEN SET v_Debug           =UPPER(v_v); END IF;
   IF lower(v_k)='filters'         THEN SET v_Filters         =UPPER(v_v); END IF;
   IF lower(v_k)='month'           THEN SET v_Month           =UPPER(v_v); END IF;

END WHILE;

IF v_Debug!="NO" THEN SELECT v_Year,v_Month,v_Owner,v_Filters,v_Debug,v_Meta,v_Misc,InputCommLine; END IF;

SET v_WhereYear='';
SET v_WhereOwner='';
SET v_WhereMonth='';

IF v_Year !="ALL" THEN SET v_WhereYear =CONCAT(" AND T.`Year` =",v_Year); END IF;
IF v_Owner!="ALL" THEN SET v_WhereOwner=CONCAT(" AND T.`Owner`='",v_Owner,"'"); END IF;
IF v_Month!="ALL" THEN SET v_WhereMonth=CONCAT(" AND T.`Month`='",v_Month,"'"); END IF;

IF v_Debug!="NO" THEN SELECT v_WhereYear,v_WhereMonth,v_WhereOwner; END IF;

IF v_Misc="Refresh" THEN
   CALL DashTotalByMonth('LM');
END IF;

SET v_Count=0;
SET v_OwnerTotalLabel=IF(v_Owner!='ALL','Yearly Total',v_Owner);

/**************************************************************************************************************/

SET v_CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    T.`Year`
    ,T.`Month`
   ,T.`Owner_id`
   ,IFNULL(T.`Owner`,"none") as `Owner`
   ,format(SUM(IFNULL(T.`Signup`,0)),0) as `Signup`
   ,format(SUM(IFNULL(T.`FTD`,0)),0) as `FTD`
   ,format(SUM(IFNULL(T.`CPA`,0)),0) as `CPA`
   ,format(SUM(IFNULL(T.`CPA_Value`,0)),2) as `CPA_Value`
   ,format(SUM(IFNULL(T.`Net_Rev`,0)),2) as `Net_Rev`
   ,format(SUM(IFNULL(T.`RS_Val`,0)),2) as `RS_Val`
   ,format(SUM(IFNULL(T.`Tot_Comm`,0)),2) as `Tot_Comm`
   ,format(SUM(IFNULL(T.`Profit`,0)),2) as `Profit`
   ,format(SUM(IFNULL(T.`AfCom_cpa`,0)),2) as `AfCom_cpa`
   ,format(SUM(IFNULL(T.`AfCom_rs`,0)),2) as `AfCom_rs`
   ,format(SUM(IFNULL(T.`AfCom_tot`,0)),2) as `AfCom_tot`
FROM dash_total_by_month T
WHERE 1=1 and Date="TOTAL NOW" '
   ,v_WhereYear
   ,v_WhereMonth
   ,v_WhereOwner
,'
GROUP BY T.`Month`, T.`Owner`
),
Main_Table_Data_total as (
SELECT 
    T.`Year`
    ," " as `Month`
   ,"" as `Owner_id`
   ,',QUOTE(v_OwnerTotalLabel),' as `Owner`
   ,format(SUM(IFNULL(T.`Signup`,0)),0) as `Signup`
   ,format(SUM(IFNULL(T.`FTD`,0)),0) as `FTD`
   ,format(SUM(IFNULL(T.`CPA`,0)),0) as `CPA`
   ,format(SUM(IFNULL(T.`CPA_Value`,0)),2) as `CPA_Value`
   ,format(SUM(IFNULL(T.`Net_Rev`,0)),2) as `Net_Rev`
   ,format(SUM(IFNULL(T.`RS_Val`,0)),2) as `RS_Val`
   ,format(SUM(IFNULL(T.`Tot_Comm`,0)),2) as `Tot_Comm`
   ,format(SUM(IFNULL(T.`Profit`,0)),2) as `Profit`
   ,format(SUM(IFNULL(T.`AfCom_cpa`,0)),2) as `AfCom_cpa`
   ,format(SUM(IFNULL(T.`AfCom_rs`,0)),2) as `AfCom_rs`
   ,format(SUM(IFNULL(T.`AfCom_tot`,0)),2) as `AfCom_tot`
FROM dash_total_by_month T
WHERE 1=1 '
   ,v_WhereYear
   ,v_WhereMonth
   ,v_WhereOwner
,'
GROUP BY T.`Year`
)
');

IF v_Meta="YES" THEN
   SET v_SQLmeta='(
SELECT
   "setting" as Meta
   ,"width=050px"   as `Year`
   ,"width=080px"   as `Month`
   ,"omit=yes"      as `Owner_id`
   ,"width=150px"   as `Owner`
   ,"omit=yes"      as `Signup`
   ,"omit=yes"      as `FTD`
   ,"width=100px,right=true"   as `CPA`
   ,"width=120px,right=true"   as `CPA Volume`
   ,"omit=yes"      as `Net_Rev`
   ,"width=120px,right=true"   as `Rev Share Volume`
   ,"width=120px,right=true"   as `Tot_Comm`
   ,"width=120px,right=true"   as `Gross Margin`
   ,"omit=yes"      as `AfCom_cpa`
   ,"omit=yes"      as `AfCom_rs`
   ,"omit=yes"      as `AfCom_tot`
FROM DUAL)
UNION ALL ';
ELSE
   SET v_SQLmeta='';
END IF;

SET v_SQL=CONCAT(
v_CTE,
v_SQLmeta,
'
SELECT "total" as `Meta`,
   `Year`,
   `Month`,
   `Owner_id`,
   `Owner`,
   `Signup`,
   `FTD`,
   `CPA`,
   `CPA_Value`,
   `Net_Rev`,
   `RS_Val`,
   `Tot_Comm`,
   `Profit`,
   `AfCom_cpa`,
   `AfCom_rs`,
   `AfCom_tot`
FROM Main_Table_Data_total Tot
UNION ALL
SELECT "data" as `Meta`,
   `Year`,
   `Month`,
   `Owner_id`,
   `Owner`,
   `Signup`,
   `FTD`,
   `CPA`,
   `CPA_Value`,
   `Net_Rev`,
   `RS_Val`,
   `Tot_Comm`,
   `Profit`,
   `AfCom_cpa`,
   `AfCom_rs`,
   `AfCom_tot`
FROM Main_Table_Data
ORDER BY 
   CASE `Meta` 
      WHEN "total" THEN 1 
      WHEN "setting" THEN 2 
      WHEN "data" THEN 3 
      ELSE 4 
   END,
   `Year`, 
   `Month`,
   `Owner`
');

-- ------------------------------------------------------------
SET v_SQLfilters=CONCAT(v_CTE,'
(SELECT "01" as "Korder","Year" AS "Key",CAST(`Year` AS CHAR) AS "Value","Year" AS `CallKey`,CAST(`Year` AS CHAR) AS "CallValue",COUNT(*) AS "Rows"
                                                                                         FROM Main_Table_Data GROUP BY `Year`) UNION ALL
(SELECT "02","Month" ,`Month` ,"Month" ,`Month`,COUNT(*) AS K FROM Main_Table_Data GROUP BY `Month`) UNION ALL
(SELECT "03","Owner" ,`Owner` ,"Owner" ,replace(`Owner`," ","!"),COUNT(*) AS K FROM Main_Table_Data GROUP BY `Owner`) UNION ALL
(SELECT "04","Misc" ,"Refresh data" ,"Misc" ,"Refresh" ,"" AS K FROM DUAL)
ORDER BY 1,3
;');

IF v_Filters!="NO" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Debug != "YES" THEN
   SET @v_sql = v_SQL;
	PREPARE stmt1 FROM @v_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*

call Report_DashTotalByMonth('debug=yes'); -- Devuelve todas las líneas
call Report_DashTotalByMonth('year=2024,owner=ALL');
call Report_DashTotalByMonth('year=2024,month=01,owner=ALL');
call Report_DashTotalByMonth('year=2024,owner=1,filters=yes');
call Report_DashTotalByMonth('year=2024,filters=no');

*/

