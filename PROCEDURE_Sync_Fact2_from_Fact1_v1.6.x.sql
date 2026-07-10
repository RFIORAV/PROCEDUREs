/*
PROCEDURE_Sync_Fact2_from_Fact1() - Sync one/all MS for a given month and/of affiliate_id
   REEMPLAZA A: Sync_MS_Fact1_Fact2_lm

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:

Mode            =[View | Run]. OPCIONAL. Default=View
Month           =[AAAA-MM | CM | LM]. OPCIONAL. Default=CM=Current Month (Curr Month implica MS_id=ALL)
DB              =[ database name ]. Default=Current DB. OBLIGATORIO para MS_id=AllAll
Affiliate_id    =[ALL | id del Affiliate]. OPCIONAL. Default='all'
MS_id           =[ALL | id de la MS]. OBLIGATORIO.
						MS_id=ALL: SOLO VALIDO PARA MES CORRIENTE
						MS_id=ALLALL: VALIDO PARA CUALQUIER OTRO MES (OBLIGATORIO informar DB)
Debug           =[No | Yes | Other value ]. OPCIONAL. Default=No
                  [No]  EJECUTA QUERY y devuelve resultado.
                  [Yes] NO EJECUTA QUERY y devuelve el código del Query.
                  [Other value] EJECUTA QUERY y devuelve el código del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Sync_Fact2_from_Fact1('');  -- Sync all curr month
call Sync_Fact2_from_Fact1('MS_id=1581,debug=yes');  -- asume curr month
call Sync_Fact2_from_Fact1('month=2025-10,Affiliate_id=39,MS_id=allall,debug=YE');  -- error: falta db
call Sync_Fact2_from_Fact1('month=2026-01,Affiliate_id=39,MS_id=allall,db=euroaffiliati_dev,debug=YE');  -- MS_id debe ser AllAll
call Sync_Fact2_from_Fact1('month=2022-10,Affiliate_id=39,MS_id=allall,db=euroaffiliati2,debug=YES');
call Sync_Fact2_from_Fact1('month=2022-10,MS_id=1581,debug=yes');
call Sync_Fact2_from_Fact1('month=2022-12,Affiliate_id=all,debug=YE');
call Sync_Fact2_from_Fact1('month=2022-10,MS_id=all,debug=YES'); 		-- error MS_id=ALL Only for Curr Month
call Sync_Fact2_from_Fact1('month=2022-10,MS_id=allall,debug=YEs');  	-- error: falta db
call Sync_Fact2_from_Fact1('mode=run,month=LM,Affiliate_id=ALL,MS_id=ALLALL,db=euroaffiliati_dev,debug=ye');

07.12.2022 V1.1   Complementa y reemplaza a PROCEDURE_Sync_Fact2_from_Fact1_lm_v1.1.sql
14.12.2022 v1.2   Incluye totales
31.01.2023 v1.3   `Area`
07.08.2023 v1.4   Toma campo Qualified_Players_Adjusted como CPA
21.11.2023 v1.4.1 Agregado más campos a mostrar en debug
06.01.2024        ES INVOCADA DESDE Sync_MS_Fact1_Fact2_lm para que los procesos de 
                  sincronizacion f1 y f2 queden unificados en este proc
12.04.2024 v1.5   Agregada opción Month=ALLALL para permitir reproceso total db demo
29.07.2024 v1.5.1 Group fact1 por Deal_Aff_id en lugar de Deal_Aff_CPA,Deal_Aff_RS
01.08.2024 v1.6   Agregado Publisher_id a fact2
12.02.2026 v1.6.1 Agregado Límite de proceso para datos afiliado
28.02.2026 v1.6.2 Fix: eliminación de variables globales
16.06.2026 v1.6.3 Producto en lugar de Product
*/

DROP PROCEDURE IF EXISTS Sync_Fact2_from_Fact1;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Sync_Fact2_from_Fact1`(IN
   InputCommLine    VARCHAR(250)
   )
   COMMENT 'Version 1.6.3 16.06.2026: Sync one/all MS for a given month and/of affiliate_id'

proc_label:BEGIN
DECLARE v_Version           VARCHAR(30);
DECLARE v_CurrentDay        DATE;
DECLARE v_CurrentMonth      CHAR(7);
DECLARE v_LastMonth         CHAR(7);

DECLARE v_Mode              VARCHAR(10);
DECLARE v_Month             VARCHAR(10);
DECLARE v_MS_id             VARCHAR(30);
DECLARE v_DB                VARCHAR(128);
DECLARE v_Affiliate_id      VARCHAR(30);
DECLARE v_Debug             VARCHAR(10);

DECLARE v_InputCommLine     VARCHAR(300);
DECLARE v_e                 INT;
DECLARE v_c                 INT;
DECLARE v_k                 VARCHAR(100);
DECLARE v_v                 VARCHAR(250);

DECLARE v_Fact2_Date_Switch VARCHAR(10);
DECLARE v_Fact2_Date_Limit  DATE;
DECLARE v_exists            VARCHAR(128);

DECLARE v_Where_Clause      LONGTEXT;
DECLARE v_SQLdelete         LONGTEXT;
DECLARE v_SQLinsert         LONGTEXT;
DECLARE v_SQLselect         LONGTEXT;
DECLARE v_SQLpreview        LONGTEXT;
DECLARE v_SQLrun            LONGTEXT;

-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.6.3 16.06.2026';
SET v_CurrentDay      =CURDATE();
SET v_CurrentMonth    =LEFT(CURDATE(),7);
SET v_LastMonth       =LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);

SET v_Mode            ='view';
SET v_Month           =LEFT(CURDATE(),7);
SET v_MS_id           ='ALL';
SET v_DB              ='';
SET v_Affiliate_id    ='ALL';
SET v_Debug           ='NO';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas
-- SET v_InputCommLine=replace(v_InputCommLine,"'","");  -- Elimina apóstrofos
-- SET v_InputCommLine=replace(v_InputCommLine,'`','');  -- Elimina ticks
-- SET v_InputCommLine=replace(v_InputCommLine,'(','');  -- Elimina parentesis
-- SET v_InputCommLine=replace(v_InputCommLine,')','');  -- Elimina parentesis

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

   IF lower(v_k)='mode'         THEN SET v_Mode          =UPPER(v_v); END IF;
   IF lower(v_k)='month'        THEN SET v_Month         =UPPER(v_v); END IF;
   IF lower(v_k)='ms_id'        THEN SET v_MS_id         =UPPER(v_v); END IF;
   IF lower(v_k)='affiliate_id' THEN SET v_Affiliate_id  =UPPER(v_v); END IF;
   IF lower(v_k)='db'           THEN SET v_DB            =LOWER(v_v); END IF;
   IF lower(v_k)='debug'        THEN SET v_Debug         =LOWER(v_v); END IF;
END WHILE;

IF UPPER(v_Month)='CM'      THEN SET v_Month=v_CurrentMonth; END IF;
IF UPPER(v_Month)='LM'      THEN SET v_Month=v_LastMonth;    END IF;
IF UPPER(v_Month)='ALLALL'  THEN SET v_Month='2020-12';      END IF;

-- Obtiene Límite de proceso para datos afiliado
SET v_Fact2_Date_Switch=(SELECT COALESCE(`Value_01`,'NO')      FROM `util_settings` WHERE Setting='Fact2_Date_Limit');
SET v_Fact2_Date_Limit =(SELECT COALESCE(`Value_02`,CURDATE()) FROM `util_settings` WHERE Setting='Fact2_Date_Limit');

-- IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;
IF v_Debug!="NO" THEN SELECT v_Mode,v_Month,v_MS_id,v_DB,v_Affiliate_id,v_Fact2_Date_Switch,v_Fact2_Date_Limit,v_Debug,InputCommLine; END IF;

-- Validaciones ----------------------------------------------------
IF v_DB!='' THEN
   SET v_exists=(SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME=v_DB);
   IF  v_exists IS NULL THEN SET v_DB=''; END IF;
END IF;

IF v_MS_id='ALL' AND v_Month!=v_CurrentMonth AND v_Mode="RUN"           -- Solo Current Month excepto en Modo=view
THEN  SELECT CONCAT('Wrong parameter: [Month=',v_Month,',MS_id=',v_MS_id,'] - MS_id=ALL Only for Curr Month - MS_id=AllAll for Other than curr Month') from dual;
      SELECT v_Mode,v_Month,v_MS_id,v_DB,v_Affiliate_id,v_Debug,InputCommLine from dual;
      LEAVE proc_label;
END IF;

IF v_MS_id='ALLALL' AND v_Affiliate_id='ALL' AND v_DB='' AND v_Mode="RUN"  -- Solo informando Db excepto en Modo=view
THEN  SELECT CONCAT('Missing or Wrong parameter DB: [Month=',v_Month,',DB=???,MS_id=',v_MS_id,']') from dual;
      SELECT v_Mode,v_Month,v_MS_id,v_DB,v_Affiliate_id,v_Debug,InputCommLine from dual;
      LEAVE proc_label;
END IF;
-- --------------------------------- -------------------------------

-- Default implicados ----------------------------------------------
IF v_Month=v_CurrentMonth AND v_MS_id=''
                        THEN SET v_MS_id='ALL';   END IF;
IF v_DB=''               THEN SET v_DB=DATABASE(); END IF;
-- --------------------------------- -------------------------------

IF v_Debug!="NO" THEN SELECT InputCommLine; END IF;

SET v_Where_Clause=CONCAT('LEFT(DATE,7)="',v_Month,'" ');

IF v_Month='2020-12'  -- caso especial de proceso de TODA la db
THEN SET v_Where_Clause=CONCAT('LEFT(DATE,7)>="',v_Month,'" ');
END IF;

IF v_MS_id!='ALL' AND v_MS_id!='ALLALL'
THEN SET v_Where_Clause=CONCAT(v_Where_Clause,' AND MS_id=',v_MS_id);
END IF;

IF v_Affiliate_id!='ALL'
THEN SET v_Where_Clause=CONCAT(v_Where_Clause,' AND Affiliate_id="',v_Affiliate_id,'"');
END IF;

-- IF v_MS_id='ALL' OR v_MS_id='ALLALL'
-- THEN SET v_Where_Clause=CONCAT('LEFT(DATE,7)="',v_Month,'"');
-- ELSE SET v_Where_Clause=CONCAT('LEFT(DATE,7)="',v_Month,'" AND MS_id=',v_MS_id);
-- END IF;

IF v_Month='2020-12'  -- caso especial de proceso de TODA la db
THEN SET v_SQLdelete=CONCAT('TRUNCATE ',v_DB,'.Snapshot_day_by_day_fact2;');
ELSE SET v_SQLdelete=CONCAT('DELETE FROM ',v_DB,'.Snapshot_day_by_day_fact2 WHERE ',v_Where_Clause,';');
END IF;

IF v_Debug!="NO" THEN SELECT v_Mode,v_Month,v_MS_id,v_Affiliate_id,v_DB,v_Where_Clause,v_SQLdelete; END IF;

SET v_SQLinsert=CONCAT('
INSERT IGNORE INTO ',v_DB,'.Snapshot_day_by_day_fact2 (
   `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
   ,`Advertiser_id`,`Publisher_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
   ,`Qualified_Players`,`Qualified_Players_Adjusted`
	,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
   ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
   ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
   ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
   ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
   ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`
)');
SET v_SQLselect=CONCAT('
SELECT
   id,`Area`,Owner,Affiliate,Affiliate_id,Deal_Aff,Date,Username,Username_id,Brand
   ,Advertiser_id,`Publisher_id`,Tracker_ID,MS_id,Tracker_Name,Code_To_Affiliate,Product_Real as Producto,Product_Real
   ,sum(Qualified_Players_Adjusted) AS Qualified_Players,sum(Qualified_Players) AS Qualified_Players_Adjusted
	,sum(First_Time_Deposit) AS First_Time_Deposit,sum(Views) AS Views,sum(Clicks) AS Clicks,sum(Signups) AS Signups
   ,sum(Impressions) AS Impressions,Sign_Up_Offer,Type,Language,sum(Deposits) AS Deposits,sum(Depositing_Customers) AS Depositing_Customers,sum(Active_Customers) AS Active_Customers
   ,sum(New_Depositing_Customers) AS New_Depositing_Customers,sum(New_Active_Customers) AS New_Active_Customers,sum(First_Time_Active_Customers) AS First_Time_Active_Customers,sum(Turnover) AS Turnover,sum(Net_Revenue) AS Net_Revenue
   ,CPA_Limit,Channel_id,Channel,sum(Revenue_Share_Affiliate) AS Revenue_Share_Affiliate,sum(CPA_Value_Affiliate) AS CPA_Value_Affiliate,Deal_Aff_id
   ,Deal_Aff_CPA,Deal_Aff_Carry_Over,Deal_Aff_RS_Against_CPA,Deal_Aff_RS_Base,Deal_Aff_RS
   ,Deal_Aff_Valid_From,Data_Currency,NOW() as TimeGen
FROM ',v_DB,'.Snapshot_day_by_day_fact1
WHERE ',v_Where_Clause,' AND MS_id IS NOT NULL AND Affiliate!="_Unassigned" 
                        AND IF("',v_Fact2_Date_Switch,'"="YES",`Date` <= "',DATE_FORMAT(v_Fact2_Date_Limit,'%Y-%m-%d'),'",1=1)
GROUP BY Owner,Date,Affiliate_id,ifnull(MS_id,0),Tracker_ID,Tracker_Name,Product,Deal_Aff_id  -- Deal_Aff_CPA,Deal_Aff_RS -- 29.07.2024
        ,`Username_id`                                                                        -- 01.08.2024
;');

SET v_SQLpreview=CONCAT('
WITH fact1 AS (
SELECT
    Owner,`Area`,Date,Brand,Username,Affiliate,MS_id,Tracker_ID,Product,Affiliate_id,Username_id
    ,sum(Qualified_Players_Adjusted) AS CPA,sum(Net_Revenue) AS NR,sum(Revenue_Share_Affiliate) AS RS_Aff
    ,sum(CPA_Value_Affiliate) AS CPA_Val_Aff
FROM ',v_DB,'.Snapshot_day_by_day_fact1 F1
WHERE ',v_Where_Clause,' AND Affiliate!="_Unassigned" AND IF("',v_Fact2_Date_Switch,'"="YES",`Date` <= "',DATE_FORMAT(v_Fact2_Date_Limit,'%Y-%m-%d'),'",1=1)
GROUP BY Owner,Brand,Affiliate_id,Username_id,ifnull(MS_id,0) -- ,Tracker_ID,Product
), fact2 AS (
SELECT
   Owner,`Area`,Date,Brand,Username,Affiliate,MS_id,Tracker_ID,Product,Affiliate_id,Username_id
   ,sum(Qualified_Players) AS CPA,sum(Net_Revenue) AS NR,sum(Revenue_Share_Affiliate) AS RS_Aff
   ,sum(CPA_Value_Affiliate) AS CPA_Val_Aff
FROM ',v_DB,'.Snapshot_day_by_day_fact2 F2
WHERE ',v_Where_Clause,' AND Affiliate!="_Unassigned" 
GROUP BY Owner,Brand,Username_id,Affiliate_id,ifnull(MS_id,0) -- ,Tracker_ID,Product
)
SELECT
    F1.Owner,F1.`Area`
   ,LEFT(F1.DATE,7) as Date
   ,F1.Brand
   ,F1.Username   -- ,F1.Username_id  ,F2.Username   ,F2.Username_id
   ,F1.Affiliate  -- ,F1.Affiliate_id ,F2.Affiliate  ,F2.Affiliate_id
   ,F1.MS_id
   ,F1.Tracker_ID
   -- ,F1.Product
   ,IFNULL(F1.CPA,0)          AS `CPA`
   ,IFNULL(F2.CPA,0)          AS `f2 CPA`
   ,IFNULL(F1.NR,0)           AS `NR`
   ,IFNULL(F2.NR,0)           AS `f2 NR`
   ,IFNULL(F1.RS_Aff,0)       AS `RS`
   ,IFNULL(F2.RS_Aff,0)       AS `f2 RS`
   ,IFNULL(F1.CPA_Val_Aff,0)  AS `CPA Val`
   ,IFNULL(F2.CPA_Val_Aff,0)  AS `f2 CPA Val`
FROM fact1 F1
LEFT JOIN fact2 F2 ON F1.MS_id=F2.MS_id AND F1.Affiliate_id=F2.Affiliate_id -- AND F1.Product=F2.Product
WHERE F1.CPA!=IFNULL(F2.CPA,0) -- OR F1.NR!=IFNULL(F2.NR,0)
   OR F1.RS_Aff!=IFNULL(F2.RS_Aff,0)
   OR F1.CPA_Val_Aff!=IFNULL(F2.CPA_Val_Aff,0)
UNION ALL
SELECT
    F2.Owner,F2.`Area`
   ,LEFT(F2.DATE,7) as Date
   ,F2.Brand
   ,F2.Username
   ,F2.Affiliate
   ,F2.MS_id
   ,F2.Tracker_ID
   -- ,F2.Product
   ,IFNULL(F1.CPA,0)         AS `CPA`
   ,IFNULL(F2.CPA,0)         AS `f2 CPA`
   ,IFNULL(F1.NR,0)          AS `NR`
   ,IFNULL(F2.NR,0)          AS `f2 NR`
   ,IFNULL(F1.RS_Aff,0)      AS `RS`
   ,IFNULL(F2.RS_Aff,0)      AS `f2 RS`
   ,IFNULL(F1.CPA_Val_Aff,0) AS `CPA Val`
   ,IFNULL(F2.CPA_Val_Aff,0) AS `f2 CPA Val`
FROM fact2 F2
LEFT JOIN fact1 F1 ON F1.MS_id=F2.MS_id AND F1.Affiliate_id=F2.Affiliate_id -- AND F1.Product=F2.Product
WHERE F2.MS_id IS NOT NULL AND F1.MS_id IS NULL
UNION ALL
SELECT
    F1.Owner
   ," ~~~~~"
   ," ~~~~~"
   ,"~~Total~~"
   ,"~~ f1 vs f2 ~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   -- ,"~~~~~"
   ,SUM(IFNULL(F1.CPA,0)        )  AS `CPA`
   ,SUM(IFNULL(F2.CPA,0)        )  AS `f2 CPA`
   ,SUM(IFNULL(F1.NR,0)         )  AS `NR`
   ,SUM(IFNULL(F2.NR,0)         )  AS `f2 NR`
   ,SUM(IFNULL(F1.RS_Aff,0)     )  AS `RS`
   ,SUM(IFNULL(F2.RS_Aff,0)     )  AS `f2 RS`
   ,SUM(IFNULL(F1.CPA_Val_Aff,0))  AS `CPA Val`
   ,SUM(IFNULL(F2.CPA_Val_Aff,0))  AS `f2 CPA Val`
FROM fact1 F1
LEFT JOIN fact2 F2 ON F1.MS_id=F2.MS_id AND F1.Affiliate_id=F2.Affiliate_id -- AND F1.Product=F2.Product
WHERE F1.CPA!=IFNULL(F2.CPA,0) -- OR F1.NR!=IFNULL(F2.NR,0)
   OR F1.RS_Aff!=IFNULL(F2.RS_Aff,0)
   OR F1.CPA_Val_Aff!=IFNULL(F2.CPA_Val_Aff,0)
GROUP BY F1.Owner
UNION ALL
SELECT
    F2.Owner
   ," ~~~~~"
   ," ~~~~~"
   ,"~~Total~~"
   ,"~~ Not anymore in f1 ~~"
   ,"~~~~~"             -- F2.Affiliate
   ,"~~~~~"             -- F2.MS_id
   ,"~~~~~"             -- F2.Tracker_ID
   -- ,"~~~~~"
   ,SUM(IFNULL(F1.CPA,0)        )  AS `CPA`
   ,SUM(IFNULL(F2.CPA,0)        )  AS `f2 CPA`
   ,SUM(IFNULL(F1.NR,0)         )  AS `NR`
   ,SUM(IFNULL(F2.NR,0)         )  AS `f2 NR`
   ,SUM(IFNULL(F1.RS_Aff,0)     )  AS `RS`
   ,SUM(IFNULL(F2.RS_Aff,0)     )  AS `f2 RS`
   ,SUM(IFNULL(F1.CPA_Val_Aff,0))  AS `CPA Val`
   ,SUM(IFNULL(F2.CPA_Val_Aff,0))  AS `f2 CPA Val`
FROM fact2 F2
LEFT JOIN fact1 F1 ON F1.MS_id=F2.MS_id AND F1.Affiliate_id=F2.Affiliate_id -- AND F1.Product=F2.Product
WHERE F2.MS_id IS NOT NULL AND F1.MS_id IS NULL
GROUP BY F2.Owner -- ,F2.Affiliate_id

ORDER BY Owner,Brand,Username,Affiliate,MS_id
;');

IF v_Mode="RUN"
THEN SET v_SQLrun=CONCAT(v_SQLinsert,v_SQLselect);
ELSE SET v_SQLrun=v_SQLpreview;
END IF;

IF v_Debug!="NO" THEN SELECT v_SQLdelete; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLinsert; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLselect; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLpreview; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLrun; 	 END IF;

IF v_Debug!="YES" THEN
	IF v_Mode="RUN" THEN
      SET @v_SQLexec = v_SQLdelete;
      PREPARE stmt1 FROM @v_SQLexec;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;
   SET @v_SQLexec = v_SQLrun;
   PREPARE stmt1 FROM @v_SQLexec;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Sync_Fact2_from_Fact1('');  -- Sync view all curr month
call Sync_Fact2_from_Fact1('month=LM,debug=ye');  -- Sync view all LM
call Sync_Fact2_from_Fact1('MS_id=1581,debug=ye');  -- asume curr month
call Sync_Fact2_from_Fact1('Affiliate_id=all,mode=run,debug=yes');  -- asume curr month
call Sync_Fact2_from_Fact1('month=2022-10,Affiliate_id=39,MS_id=allall,debug=YE');
call Sync_Fact2_from_Fact1('month=2022-10,Affiliate_id=39,MS_id=all,db=euroaffiliati2,debug=YES');  -- MS_id debe ser AllAll
call Sync_Fact2_from_Fact1('mode=view,month=2022-10,Affiliate_id=39,MS_id=allall,db=euroaffiliati2,debug=YES');
call Sync_Fact2_from_Fact1('mode=view,month=2022-10,MS_id=1581,debug=yes');
call Sync_Fact2_from_Fact1('mode=run,month=2022-12,Affiliate_id=all,debug=YE');
call Sync_Fact2_from_Fact1('mode=run,month=2022-10,MS_id=all,debug=YES'); 		-- error MS_id=ALL Only for Curr Month
call Sync_Fact2_from_Fact1('mode=view,month=2022-10,MS_id=allall,debug=YEs');  	-- error: falta db
call Sync_Fact2_from_Fact1('mode=run,month=2022-09,MS_id=allall,db=gamingaffiliation,debug=yes');
call Sync_Fact2_from_Fact1('mode=view,month=LM,MS_id=allall,db=gamingaffiliation,debug=no');
call Sync_Fact2_from_Fact1('mode=run,month=2022-09,MS_id=allall,db=gamingaffiliation,debug=no');

call Sync_Fact2_from_Fact1('mode=run,month=allall,MS_id=allall,affiliate_id=all,debug=yes,db=affiliateaccess');
call Sync_Fact2_from_Fact1('mode=run,month=LM,MS_id=allall,db=euroaffiliati_dev,debug=YE');
*/