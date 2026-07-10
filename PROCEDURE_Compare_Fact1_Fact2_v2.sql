/* PROCEDURE_Compare_Fact1_Fact2.sql - Check data: Main Table Vs Main Aff Table (Fact1/Fact2)


Descripción:
  Procedimiento Compare_Fact1_Fact2_dev.
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month           =[AAAA-MM]. OPCIONAL. Default=Current Month.
Affiliate_id    =[ALL | id del Affiliate]. OPCIONAL. Default=ALL
Advertiser_id   =[ALL | id del Advertiser]. OPCIONAL. Default=ALL
Mode            =[UPDATE | VIEW]. OPCIONAL. Default=VIEW
                  [UPDATE] Actualiza los datos de la tabla Snapshot_day_by_day_fact2
                  [VIEW] Devuelve el resultado de la consulta sin actualizar los datos
CPA_Diff        =[ALL | >0 | <0]. OPCIONAL. Filtra por CPA DIFF positivo o negativo. Default=ALL
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [yes]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

 Version history:
 19.03.2024 v1   Creación
 13.03.2026 v2   Variables de sesión convertidas a locales (v_)
                 Filtro CPA_Diff (>0 / <0)
                 Filtro Advertiser_id

Ejemplos:

call Compare_Fact1_Fact2('month=LM,FILTERS=yes,debug=YES');
call Compare_Fact1_Fact2('month=LM,advertiser_id=68,mode=updat,debug=ye,meta=yes');
call Compare_Fact1_Fact2('month=LM,debug=yes');
call Compare_Fact1_Fact2('month=LM,Mode=UPDATE,debug=YES');

*/

DROP PROCEDURE IF EXISTS Compare_Fact1_Fact2;
-- DROP PROCEDURE IF EXISTS Compare_Fact1_Fact2_dev;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Compare_Fact1_Fact2`(IN
   InputCommLine    VARCHAR(250)
   )
   LANGUAGE SQL
   COMMENT 'v2.2 13.05.2026 Check/Sync data: Main Table Vs Main Aff Table (Fact1/Fact2)'

proc_label:BEGIN

DECLARE v_Version           VARCHAR(50);
DECLARE v_Month             VARCHAR(20);
DECLARE v_MS_id             VARCHAR(50);
DECLARE v_Area              VARCHAR(50);
DECLARE v_Owner             VARCHAR(50);
DECLARE v_Brand             VARCHAR(100);
DECLARE v_Affiliate_id      VARCHAR(50);
DECLARE v_Advertiser_id     VARCHAR(50);
DECLARE v_Meta              VARCHAR(10);
DECLARE v_Filters           VARCHAR(10);
DECLARE v_Debug             VARCHAR(20);
DECLARE v_InputCommLine     VARCHAR(500);
DECLARE v_e                 INT;
DECLARE v_c                 INT;
DECLARE v_k                 VARCHAR(100);
DECLARE v_v                 VARCHAR(250);
DECLARE v_WhereMS_id        VARCHAR(200);
DECLARE v_WhereOwner        VARCHAR(200);
DECLARE v_WhereArea         VARCHAR(200);
DECLARE v_WhereBrand        VARCHAR(200);
DECLARE v_WhereAffiliate_id VARCHAR(200);
DECLARE v_WhereAdvertiser_id VARCHAR(200);
DECLARE v_CPA_Diff          VARCHAR(10);
DECLARE v_WhereCPA_Diff     VARCHAR(100);
DECLARE v_COMILLA           CHAR(1);
DECLARE v_CTE_tmp_file      TEXT;
DECLARE v_SQL               TEXT;
DECLARE v_CTE_filter        TEXT;
DECLARE v_SQLfilters        TEXT;
DECLARE v_SQLdelete         TEXT;
DECLARE v_SQLinsert         TEXT;
DECLARE v_SQLinsertFrom     TEXT;
DECLARE v_SQLupdate         TEXT;
DECLARE v_Mode              VARCHAR(10);

SET v_Version='v2.2 13.05.2026';

SET v_Month           ='LM';
SET v_MS_id           ='ALL';
SET v_Area            ='ALL';
SET v_Owner           ='ALL';
SET v_Brand           ='ALL';
SET v_Affiliate_id    ='ALL';
SET v_Meta            ="YES";
SET v_CPA_Diff        ='ALL';
SET v_Filters         ='NO';
SET v_Debug           ='NO';
SET v_Mode            ='VIEW';

-- --------------------------------------------------------------------
SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
--  v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
   SET v_e=INSTR(v_InputCommLine,'=');
   SET v_c=INSTR(v_InputCommLine,',');
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1);
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1));
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='month'           THEN SET v_Month         =UPPER(v_v); END IF;
   IF lower(v_k)='mode'            THEN SET v_Mode          =UPPER(v_v); END IF;
   IF lower(v_k)='ms_id'           THEN SET v_MS_id         =UPPER(v_v); END IF;
   IF lower(v_k)='area'            THEN SET v_Area          =lower(v_v); END IF;
   IF lower(v_k)='owner'           THEN SET v_Owner         =UPPER(v_v); END IF;
   IF lower(v_k)='advertiser_id'   THEN SET v_Advertiser_id =UPPER(v_v); END IF;
   IF lower(v_k)='brand'           THEN SET v_Brand         =UPPER(v_v); END IF;
   IF lower(v_k)='affiliate_id'    THEN SET v_Affiliate_id  =UPPER(v_v); END IF;
   IF lower(v_k)='cpa_diff'        THEN SET v_CPA_Diff      =UPPER(v_v); END IF;
   IF lower(v_k)='Filters'         THEN SET v_Filters       =UPPER(v_v); END IF;
   IF lower(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF lower(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;

END WHILE;

IF  v_Month = "CM" THEN SET v_Month=LEFT(CURDATE(),7); END IF;
IF  v_Month = "LM" THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF v_Debug!="NO" THEN SELECT v_Month,v_Mode,v_Filters,v_Owner,v_Brand,v_Affiliate_id ,v_Debug,v_Meta,InputCommLine; END IF;

SET v_WhereMS_id='';
SET v_WhereOwner='';
SET v_WhereArea='';
SET v_WhereBrand ='';
SET v_WhereAffiliate_id  ='';
SET v_WhereAdvertiser_id ='';
SET v_WhereCPA_Diff      ='';

SET v_COMILLA="'";

IF v_CPA_Diff='>0' THEN SET v_WhereCPA_Diff=' WHERE `CPA DIFF` > 0'; END IF;
IF v_CPA_Diff='<0' THEN SET v_WhereCPA_Diff=' WHERE `CPA DIFF` < 0'; END IF;

IF v_MS_id             !="ALL" THEN SET v_WhereMS_id           =CONCAT(" AND D.MS_id=",v_MS_id);                               END IF;
IF v_Owner             !="ALL" THEN SET v_WhereOwner           =CONCAT(" AND D.Owner=",v_Owner);                               END IF;
IF v_Area              !="ALL" THEN SET v_WhereArea            =CONCAT(" AND D.Area='",v_Area,"'");                            END IF;
IF v_Brand             !="ALL" THEN SET v_WhereBrand           =CONCAT(" AND IFNULL(D.Brand        ,'')='",v_Brand,"'");       END IF;
IF v_Affiliate_id      !="ALL" THEN SET v_WhereAffiliate_id    =CONCAT(" AND IFNULL(D.Affiliate_id ,'')=",v_Affiliate_id  );   END IF;
IF v_Advertiser_id     !="ALL" THEN SET v_WhereAdvertiser_id   =CONCAT(" AND IFNULL(D.Advertiser_id ,'')=",v_Advertiser_id);   END IF;
-- ----------------------------------------------------------------------------------------------------
-- SET SESSION group_concat_max_len = 200000;

DROP TABLE IF EXISTS tmp_diff_fact1_fact2;

SET v_CTE_tmp_file=CONCAT('
CREATE TABLE tmp_diff_fact1_fact2 AS
WITH DbD_fact1 as (
SELECT
	 `Owner`
	,LEFT(DATE,7) `Date`
	,`Brand`
	,`Username`
	,`Username_id`
	,`Affiliate`
	,`Affiliate_id`
   ,`Advertiser_id`
	,SUM(`Qualified_Players_Adjusted`)        AS `CPA` -- 07.08.2023
	,SUM(IF(Deal_Aff_RS>0,`Net_Revenue`,0))   AS `NR`
	,`Tracker_Name`,`Tracker_ID`
   ,ifnull(MS_id,0) AS MS_id
   ,Deal_Aff_id
   ,Count(*) as `K`
FROM
	`Snapshot_day_by_day_fact1` D
WHERE Affiliate!="_Unassigned" AND LEFT(DATE,7)="',v_Month,'"
'
   ,v_WhereMS_id
   ,v_WhereOwner
   ,v_WhereArea
   ,v_WhereBrand
   ,v_WhereAffiliate_id
   ,v_WhereAdvertiser_id
,'
GROUP BY ifnull(MS_id,0)'
   ,IF(v_Filters="YES",",Brand,Affiliate_id",""),
'),

DbD_fact2 as (
SELECT
	 `Owner`
	,LEFT(DATE,7) `Date`
	,`Brand`
	,`Username`
	,`Username_id`
	,`Affiliate`
	,`Affiliate_id`
   ,`Advertiser_id`
	,SUM(`Qualified_Players`)                 AS `CPA`
	,SUM(IF(Deal_Aff_RS>0,`Net_Revenue`,0))   AS `NR`
	,`Tracker_Name`,`Tracker_ID`
   ,ifnull(MS_id,0) AS MS_id
   ,Deal_Aff_id
   ,Count(*) as `K`
FROM
	`Snapshot_day_by_day_fact2` D
WHERE Affiliate!="_Unassigned" AND LEFT(DATE,7)="',v_Month,'"
'
   ,v_WhereMS_id
   ,v_WhereOwner
   ,v_WhereArea
   ,v_WhereBrand
   ,v_WhereAffiliate_id
   ,v_WhereAdvertiser_id
,'
GROUP BY ifnull(MS_id,0)',
--    ,IF(v_Filters="YES",",Brand,Affiliate_id",""),
'),

DIFF_Fact1_vs_Fact2 as (
SELECT "data" as Meta,
	 CASE WHEN IFNULL(F2.CPA,0)>IFNULL(F1.CPA,0) THEN "CPAs in Excess in Affiliate"
         WHEN IFNULL(F1.CPA,0)>IFNULL(F2.CPA,0) THEN "CPAs Missing in Affiliate"
         WHEN IFNULL(F2.NR ,0)>IFNULL(F1.NR ,0) THEN "Update Net Rev"
         WHEN IFNULL(F1.NR ,0)>IFNULL(F2.NR ,0) THEN "Update Net Rev"
         END AS Result
	,F1.`Owner`
   ,left(F1.DATE,7) AS Month
   ,F1.Brand,F1.Affiliate
   ,F1.Affiliate_id
   ,F1.Advertiser_id
	,F1.Tracker_Name as `Tracker Name`
   ,F1.Tracker_ID as `Tracker ID`
   ,F1.MS_id as `MS ID`
	,IFNULL(F2.CPA,0)                   AS `CPA in Affiliate`
   ,IFNULL(F1.CPA,0)                   AS `CPA in Main`
	,IFNULL(F2.CPA,0)-IFNULL(F1.CPA,0)  AS `CPA DIFF`
	,IFNULL(F2.NR ,0)-IFNULL(F1.NR ,0)  AS `NR DIFF`
	,round(IFNULL(F2.NR,0),2)           AS `NR in Affiliate`
   ,round(IFNULL(F1.NR,0),2)           AS `NR in Main`
   -- ,CASE WHEN F1.MS_id=0 THEN "" ELSE
      --  CASE WHEN IFNULL(F2.CPA,0)<>IFNULL(F1.CPA,0) OR (
      --            IFNULL(F2.CPA,0)= IFNULL(F1.CPA,0) AND
      --            IFNULL(F2.NR ,0)<>IFNULL(F1.NR ,0))
      --       THEN CONCAT("Sync_MS_Fact1_Fact2_lm(",',v_COMILLA,',"ms_id=",F1.MS_id,',v_COMILLA,',")")
      --       ELSE "" END
      --    END as "CALL TO SYNC this MS"
FROM DbD_fact1 F1
LEFT JOIN DbD_fact2 F2 ON IFNULL(F1.MS_id,0)=IFNULL(F2.MS_id,0)
WHERE F1.MS_id>0 AND (IFNULL(F1.CPA,0)!=IFNULL(F2.CPA,0) OR IFNULL(F1.NR,0)!=IFNULL(F2.NR,0))
)

(SELECT * FROM DIFF_Fact1_vs_Fact2 ',v_WhereCPA_Diff,'
ORDER BY CASE WHEN `CPA DIFF`=0 THEN 0 ELSE 1 END DESC
	,CAST(`CPA DIFF` AS SIGNED) DESC
LIMIT 999999)
UNION ALL
(
SELECT
   "setting" as Meta          -- "data" as Meta,
   ,"width=200px,tooltip=yes" as `1`      -- "DELETE CPA from Affiliate" AS Result
   ,"omit=yes"    as `2`      -- ,F1.`Owner`
   ,"width=80px"  as `3`      -- ,left(F1.DATE,7) AS Month
   ,"width=130px,tooltip=yes" as `4`      -- ,F1.Brand
   ,"width=130px,tooltip=yes" as `5`      -- ,F1.Affiliate
   ,"omit=yes"    as `5a`     -- ,F1.Affiliate_id
   ,"omit=yes"    as `5c`     -- ,F1.Advertiser_id
   ,"Width=120px,tooltip=yes" as `6`      -- ,F1.Tracker_Name
   ,"width=100px" as `7`      -- ,F1.Tracker_ID
   ,"width=90px"  as `8`      -- ,F1.MS_id
   ,"width=90px"  as `9`      -- ,IFNULL(F2.CPA,0)                   AS `CPA in F2`
   ,"width=90px"  as `10`     -- ,IFNULL(F1.CPA,0)                   AS `CPA in F1`
   ,"width=90px"  as `11`     -- ,IFNULL(F2.CPA,0)-IFNULL(F1.CPA,0)  AS `CPA DIFF`
   ,"width=90px"  as `12`     -- ,IFNULL(F2.NR ,0)-IFNULL(F1.NR ,0)  AS `NR DIFF`
   ,"width=90px"  as `13`     -- ,round(IFNULL(F2.NR,0),2)           AS `NR in F2`
   ,"width=90px"  as `14`     -- ,round(IFNULL(F1.NR,0),2)           AS `NR in F1`
-- ,"omit=yes"    as `16`     -- CALL TO SYNC this MS
FROM DUAL WHERE "',v_Meta,'"="YES" AND "',v_Filters,'"="NO"
)
;');

-- SET v_CTE_filter=REPLACE(v_CTE,"WITH","");

SET v_SQLfilters=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
  		and DATE_SUB(date, INTERVAL 1 MONTH) >= "2022-01-01"
)

(SELECT "01" as "Korder","Date" AS "Key",LEFT(`Date`,7) AS "Value","Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`
                                                                        ,"" AS "Rows","no" AS "TypeAction","" AS "MsgAction" FROM MonthFilter) UNION ALL
(SELECT "02","Option"     ,"CPA Diff > 0","CPA_Diff"    ,">0"           ,"" AS "Rows","no" AS "TypeAction","" AS "MsgAction" FROM DUAL) UNION ALL
(SELECT "02","Option"     ,"CPA Diff < 0","CPA_Diff"    ,"<0"           ,"" AS "Rows","no" AS "TypeAction","" AS "MsgAction" FROM DUAL) UNION ALL
(SELECT "13","Brand" 	  ,`Brand` 	    ,"Advertiser_id",`Advertiser_id`,COUNT(*) AS K,"no" AS "TypeAction","" AS "MsgAction" FROM tmp_diff_fact1_fact2 WHERE `Brand` >" "      GROUP BY IFNULL(`Brand` ,""))      UNION ALL
(SELECT "19","Affiliate"  ,`Affiliate`  ,"Affiliate_id" ,`Affiliate_id` ,COUNT(*) AS K,"no" AS "TypeAction","" AS "MsgAction" FROM tmp_diff_fact1_fact2 WHERE `Affiliate`  >" " GROUP BY IFNULL(`Affiliate`  ,"")) UNION ALL
(SELECT "03","SYNC selected Affiliate with Main data","CONFIRM UPDATE on Affiliate data","Mode","UPDATE","" AS "Rows","yes" AS "TypeAction","Update data OK" AS "MsgAction" FROM DUAL)
-- ORDER BY 1,3
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3
;'); 
/*
(SELECT "05" as "Korder","Export to invoices\' file" AS "Key","EXPORT" AS "Value","EXPORT" AS `CallKey`,"yes" AS "CallValue","" AS "Rows" 
                                                                        ,"yes" AS "TypeAction","Exported OK" AS "MsgAction"
                                                                        FROM DUAL) UNION ALL   
*/

SET v_SQL="SELECT * FROM tmp_diff_fact1_fact2";

IF v_Debug!="NO" THEN SELECT v_CTE_tmp_file; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug != "YES" THEN
	SET @_exec_sql = v_CTE_tmp_file;
	PREPARE stmt1 FROM @_exec_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

IF v_Debug != "YES" AND v_Mode!="UPDATE" THEN
	SET @_exec_sql = v_SQL;
	PREPARE stmt1 FROM @_exec_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

   -- IF v_Filters!="YES" AND v_Mode!="UPDATE" THEN
      -- SELECT * FROM tmp_diff_fact1_fact2;
   -- END IF;

-- IF v_Debug!="NO" and v_Filters!="YES" THEN SELECT * FROM tmp_diff_fact1_fact2; END IF;

-- ----------------------------------------------------------------------------------------------------

SET v_SQLdelete=CONCAT('
   DELETE D FROM Snapshot_day_by_day_fact2 D
      INNER JOIN tmp_diff_fact1_fact2 td ON td.`MS ID`=D.MS_id and td.Month=LEFT(D.`Date`,7)
      WHERE LEFT(D.`Date`,7)="',v_Month,'";');

SET v_SQLinsert=CONCAT('
INSERT IGNORE INTO Snapshot_day_by_day_fact2 (
   `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
   ,`Advertiser_id`,`Publisher_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
   ,`Qualified_Players`,`Qualified_Players_Adjusted`
	,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
   ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
   ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
   ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
   ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
   ,`Deal_Aff_Valid_From`,`Data_Currency`
)');

SET v_SQLinsertFrom=CONCAT('
SELECT
    D.id,D.`Area`,D.Owner,D.Affiliate,D.Affiliate_id,D.Deal_Aff,D.Date,D.Username,D.Username_id,D.Brand
   ,D.Advertiser_id,D.`Publisher_id`,D.Tracker_ID,D.MS_id,D.Tracker_Name,D.Code_To_Affiliate,D.Product,D.Product_Real
   ,sum(Qualified_Players_Adjusted) AS Qualified_Players,sum(Qualified_Players) AS Qualified_Players_Adjusted
	,sum(First_Time_Deposit) AS First_Time_Deposit,sum(Views) AS Views,sum(Clicks) AS Clicks,sum(Signups) AS Signups
   ,sum(Impressions) AS Impressions,Sign_Up_Offer,Type,Language,sum(Deposits) AS Deposits,sum(Depositing_Customers) AS Depositing_Customers,sum(Active_Customers) AS Active_Customers
   ,sum(New_Depositing_Customers) AS New_Depositing_Customers,sum(New_Active_Customers) AS New_Active_Customers,sum(First_Time_Active_Customers) AS First_Time_Active_Customers,sum(Turnover) AS Turnover,sum(Net_Revenue) AS Net_Revenue
   ,CPA_Limit,Channel_id,Channel,sum(Revenue_Share_Affiliate) AS Revenue_Share_Affiliate,sum(CPA_Value_Affiliate) AS CPA_Value_Affiliate,Deal_Aff_id
   ,Deal_Aff_CPA,Deal_Aff_Carry_Over,Deal_Aff_RS_Against_CPA,Deal_Aff_RS_Base,Deal_Aff_RS
   ,Deal_Aff_Valid_From,Data_Currency
FROM Snapshot_day_by_day_fact1 D
INNER JOIN tmp_diff_fact1_fact2 td ON td.`MS ID`=D.MS_id and td.Month=LEFT(D.`Date`,7)
WHERE LEFT(D.`Date`,7)="',v_Month,'" AND D.Affiliate!="_Unassigned" 
GROUP BY ifnull(D.MS_id,0),D.Date,D.Affiliate_id,D.Product,D.Deal_Aff_id
;');

SET v_SQLupdate=CONCAT(v_SQLinsert,v_SQLinsertFrom);

IF v_Debug!="NO" THEN SELECT v_SQLdelete,v_SQLinsert,v_SQLinsertFrom,v_SQLupdate; END IF;

IF v_Debug != "YES" AND v_Mode="UPDATE" THEN
	SET @_exec_sql = v_SQLdelete;
	PREPARE stmt1 FROM @_exec_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

	SET @_exec_sql = v_SQLupdate;
	PREPARE stmt2 FROM @_exec_sql;
	EXECUTE stmt2;
	DEALLOCATE PREPARE stmt2;
END IF;

-- DROP TABLE IF EXISTS tmp_diff_fact1_fact2;

END$$
DELIMITER ;

/* -- TEST --------------
call Compare_Fact1_Fact2_dev('month=LM,FILTERS=yes,debug=YE');
call Compare_Fact1_Fact2_dev('month=LM,Brand=Sisal,debug=ye');
call Compare_Fact1_Fact2_dev('month=LM,CPA_Diff=>0');
call Compare_Fact1_Fact2_dev('month=LM,CPA_Diff=<0');

*/
