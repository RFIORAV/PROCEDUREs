/*
PROCEDURE_Report_CPA_quitadas_v1.sql - CPA/Signup/FTD/Click - Matriz por Brand

Descripción:
  Procedimiento Report_CPA_quitadas_dev.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

View            =[viewAFF | viewGES | viewMAF]. Datos de Fact2/Fact1/Fact3 respectivamente. OBLIGATORIO.
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month día>=6. Last Month día<6
MatrixBy        =[CPA | Signup | FTD | Click | NR ]. OPCIONAL. Default=CPA
MasterAff_id    =[ MasterAff_id ]. SOLO PARA MODO viewMAF. Default=''
Affiliate_id    =[ALL | id del Affiliate_id | ALLdetail]. ALLdetail=All en secuencia continua
                  OPCIONAL para View=viewGES (Default=ALL).
                  OBLIGATORIO para View=viewAFF
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
LastMonths      =[No | Yes]. Info acumulada LastMonths. OPCIONAL. Default=No
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Total           =[Yes | No]. Incluye línea/s de Totales x OWNER/Currency. OPCIONAL. Default=Yes
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Keys no utilizadas:
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=Affiliate
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_CPA_quitadas(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call Report_CPA_quitadas_dev('View=VIEWGES');
call Report_CPA_quitadas_dev('View=VIEWGES,OrderBy=CPA,meta=yes,debug=YE');
call Report_CPA_quitadas_dev('View=ViewGES,Affiliate_id=39,Month=2022-08,debug=yes');
call Report_CPA_quitadas_dev('View=ViewGES,Affiliate_id=ALL,Month=2022-08,ByDay=yes');
call Report_CPA_quitadas_dev('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=2022-08,meta=yes');
call Report_CPA_quitadas('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999

call Report_CPA_quitadas('View=ViewAFF,Affiliate_id=39,ByDay=yes,debug=no');
call Report_CPA_quitadas('View=ViewGES,Owner=2,Month=2022-08');

04.09.2022 V1     Total_FACT1_AFFILIATE_CPAbyDay_BrandMatrix
08.09.2022 V2     FACT1/2 Como parámetro + Currency. Unifica acumulaciones de CPA
26.09.2022 V2.2   Optimización
26.09.2022 V3     Recodificacion de PROCEDURE_Report_CPA_quitadas.
                  Parámetros con Key=Value en un solo campo de entrada como CommandLine
07.10.2022 v3.2   Columna METAdatos
25.10.2022 v3.3   Nombres Columnas Brand Matrix Separados en las mayúsculas con Regex
02.11.2022        Retorna con mensaje cuando no hay CPAs en la selección
16.11.2022 v3.4   Agregado parámetro MatrixBy=[CPA | Signup | FTD | Click ]. OPCIONAL. Default=CPA
03.01.2023 v1.1   Filters
12.05.2023 v1.2   @Month='CM'/'LM'
12.05.2023 v1.3   Agregado NR
31.05.2023 v1.4   Karen - filtro por Advertiser_id
09.08.2023 v1.5   Agregado Total Comission a la matriz. Fixes en columna total
04.09.2023 v1.6   Karen. Se agregó variable setting cuando no existe resultados
16.01.2024 v1.7   Habilitada selección por Afiliado
27.05.2024 v1.8   Tratamiento de Subafiliados
                  Tratamiento de Master Affiliate
29.05.2024 v1.9   Opción LastMonths
06.08.2024 v2     Multi-currency
11.08.2024 v2.1   fix Multi-currency
13.09.2024 v2.2   No agrupa por Owner
26.11.2024 V2.3   Reporte por dia todos los afiliados. Parametro ALLdetail
06.03.2025 v2.3.1 Fix mostrando datos ByDay
08.04.2025        Fix: mostrar filters aunque no haya datos
17.03.2026 v1.1   Reemplazo de variables de sesión (@var) por variables locales (v_var)
*/

-- DROP PROCEDURE IF EXISTS Report_CPA_quitadas;
DROP PROCEDURE IF EXISTS Report_CPA_quitadas_dev;

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_CPA_quitadas_dev`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'CPA quitadas - Matriz por Brand'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Declaración de variables locales
DECLARE v_Version            VARCHAR(30);
DECLARE v_View               VARCHAR(20);
DECLARE v_Owner              VARCHAR(20);
DECLARE v_Month              VARCHAR(10);
DECLARE v_MatrixBy           VARCHAR(20);
DECLARE v_Affiliate_id       VARCHAR(20);
DECLARE v_MasterAff_id       VARCHAR(20);
DECLARE v_LastMonths         VARCHAR(10);
DECLARE v_Currency           VARCHAR(10);
DECLARE v_OrderBy            VARCHAR(20);
DECLARE v_Order              VARCHAR(10);
DECLARE v_Total              VARCHAR(10);
DECLARE v_TotLine            VARCHAR(10);
DECLARE v_Debug              VARCHAR(20);
DECLARE v_Meta               VARCHAR(10);
DECLARE v_ByDay              VARCHAR(10);
DECLARE v_Advertiser_id      VARCHAR(20);
DECLARE v_ByAccount          VARCHAR(10);
DECLARE v_Filters            VARCHAR(10);
DECLARE v_InputCommLine      VARCHAR(500);
DECLARE v_e                  INT;
DECLARE v_c                  INT;
DECLARE v_k                  VARCHAR(50);
DECLARE v_v                  VARCHAR(100);
DECLARE v_WhereOwner         VARCHAR(200);
DECLARE v_WhereAffiliate_id  VARCHAR(200);
DECLARE v_WhereAdvertiser_id VARCHAR(200);
DECLARE v_MultiCurrency      VARCHAR(10);
DECLARE v_PastMonths         VARCHAR(10);
DECLARE v_Month_Report       VARCHAR(10);
DECLARE v_Compare            VARCHAR(5);
DECLARE v_Currency_result    VARCHAR(10);
DECLARE v_Order_by           VARCHAR(200);
DECLARE v_Group_by           VARCHAR(200);
DECLARE v_FlagAll            VARCHAR(5);
DECLARE v_DataTable          VARCHAR(100);
DECLARE v_SQLbrands          TEXT;
DECLARE v_SQLmat             TEXT;
DECLARE v_SQLmet             TEXT;
DECLARE v_SQLmeta            TEXT;
DECLARE v_SQLwrkTotal        TEXT;
DECLARE v_SQLwrkDetail       TEXT;
DECLARE v_SQLcheckTotal      TEXT;
DECLARE v_SQLnodataTotal     TEXT;
DECLARE v_SQL                TEXT;
DECLARE v_SQL_Affiliate_list TEXT;
DECLARE v_SQLfilters         TEXT;
DECLARE v_M0                 VARCHAR(10);
DECLARE v_M1                 VARCHAR(10);
DECLARE v_M2                 VARCHAR(10);
DECLARE v_M3                 VARCHAR(10);
DECLARE v_M4                 VARCHAR(10);
DECLARE v_M5                 VARCHAR(10);
DECLARE v_M6                 VARCHAR(10);
DECLARE v_M7                 VARCHAR(10);

-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version      ='v1.2 17.03.2026';
SET v_View         ='VIEWGES';
SET v_Owner        ='ALL';
SET v_Month        =IF(DAY(CURDATE())<=5,LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),LEFT(CURDATE(),7));
-- SET v_Month        =LEFT(CURDATE(),7);
SET v_MatrixBy     ='CPA';
SET v_Affiliate_id ='ALL';
SET v_MasterAff_id ='';
SET v_LastMonths   ='NO';
SET v_Currency     ='EUR';
SET v_OrderBy      ='CPA';
SET v_Order        ='DESC';
SET v_Total        ='YES';
SET v_TotLine      ='FIRST';
SET v_Debug        ='NO';
SET v_Meta         ='YES';
SET v_ByDay        ='no';
SET v_Advertiser_id='ALL';
SET v_ByAccount    ='NO';
SET v_Filters      ='NO';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

-- IF v_Debug="YES" THEN SELECT v_Owner,v_Month,v_LastMonths,v_Currency,v_Advertiser_id,v_ByAccount,v_Debug,v_Total,v_TotLine,v_OrderBy,v_Order,v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit
-- v_InputCommLine: ----5----0----5----0----5----0----5----0--
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='owner'         THEN SET v_Owner        =UPPER(v_v); END IF;
   IF lower(v_k)='month'         THEN SET v_Month        =UPPER(v_v); END IF;
   IF lower(v_k)='matrixby'      THEN SET v_MatrixBy     =UPPER(v_v); END IF;
   IF lower(v_k)='masteraff_id'  THEN SET v_MasterAff_id =UPPER(v_v); END IF;
   IF lower(v_k)='lastmonths'    THEN SET v_LastMonths   =UPPER(v_v); END IF;
   IF lower(v_k)='advertiser_id' THEN SET v_Advertiser_id=UPPER(v_v); END IF;
   IF lower(v_k)='currency'      THEN SET v_Currency     =UPPER(v_v); END IF;
   IF lower(v_k)='byaccount'     THEN SET v_ByAccount    =UPPER(v_v); END IF;
   IF lower(v_k)='orderby'       THEN SET v_OrderBy      =UPPER(v_v); END IF;
   IF lower(v_k)='order'         THEN SET v_Order        =UPPER(v_v); END IF;
   IF lower(v_k)='total'         THEN SET v_Total        =UPPER(v_v); END IF;
   IF lower(v_k)='totline'       THEN SET v_TotLine      =UPPER(v_v); END IF;
   IF lower(v_k)='debug'         THEN SET v_Debug        =UPPER(v_v); END IF;
   IF lower(v_k)='view'          THEN SET v_View         =UPPER(v_v); END IF;
   IF lower(v_k)='affiliate_id'  THEN SET v_Affiliate_id =UPPER(v_v); END IF;
   IF lower(v_k)='byday'         THEN SET v_ByDay        =UPPER(v_v); END IF;
   IF lower(v_k)='meta'          THEN SET v_Meta         =UPPER(v_v); END IF;
   IF lower(v_k)='filters'       THEN SET v_Filters      =UPPER(v_v); END IF;

END WHILE;

IF v_Debug!="NO" THEN SELECT v_Owner,v_Month,v_LastMonths,v_Currency,v_Advertiser_id,v_ByAccount,v_Debug,v_Total,v_TotLine
                           ,v_OrderBy,v_Order,v_View, v_MatrixBy ,v_Affiliate_id,v_ByDay,InputCommLine; END IF;

-- IF v_Affiliate_id="ALL" THEN SET v_WhereAffiliate_id=' ';
-- ELSE SET v_Affiliate_id=CONCAT(" AND Affiliate_id='",v_Affiliate_id,"'"); END IF;

IF v_Owner="ALL" THEN SET v_WhereOwner=' ';
ELSE SET v_WhereOwner=CONCAT(" AND Owner='",v_Owner,"'"); END IF;

IF v_Month='CM' THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF v_Month='LM' THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- Obtiene v_MultiCurrency y v_Currency desde tabla util_settings
SET v_MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET v_Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

-- ----------------------------------------------------
-- TRATAMIENTO DE PERIODO DE REPORTE ------------------
-- ----------------------------------------------------
SET v_PastMonths=LEFT(DATE_SUB(CURDATE(), INTERVAL 6 MONTH),7);

IF   v_LastMonths='YES'
THEN SET v_Month_Report=v_PastMonths;
     SET v_Compare=">=";
ELSE SET v_Month_Report=v_Month;
     SET v_Compare="=";
END IF;
-- WHERE LEFT(DATE,7)="',v_Month_Report,
-- WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,
-- ----------------------------------------------------

IF lower(v_Currency)='original' THEN SET v_Currency_result='ALL'; ELSE SET v_Currency_result=UPPER(v_Currency); END IF;

-- ----------------------------------------------------
-- TRATAMIENTO DE TOTALES Y ORDER----------------------
-- ----------------------------------------------------
-- SET v_OrderByClause='';          -- Variable a aplicar
-- SET v_OrderByClauseEnd=' ORDER BY DATE,Affiliate ';

/**************************************************************************************************************/

-- --------------------------------------------------------------------------------------------
-- Validación
IF   v_Affiliate_id IN ("","ALL","ALLdetail") AND v_View='VIEWAFF'
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;

-- 31.05.2023 Karen
IF v_Advertiser_id="ALL" THEN
     SET v_WhereAdvertiser_id=' ';
ELSE SET v_WhereAdvertiser_id=CONCAT(' AND Advertiser_id=',v_Advertiser_id);
END IF;

-- ----------------------------------------------------
-- ----------------------------------------------------
SET v_Order_by=' ORDER BY Date ';
SET v_Group_by=' GROUP BY xDate ';
-- ----------------------------------------------------
IF v_View='VIEWGES' THEN
   IF v_Affiliate_id="ALLdetail"
   THEN SET v_Group_by=' GROUP BY xAffiliate,xDate ';
        SET v_ByDay='YES';
        SET v_Order_by=' ORDER BY Affiliate,Date ';
   END IF;
   IF v_Affiliate_id="ALL"
   THEN  SET v_Order_by=' ORDER BY Affiliate,Date ';
         IF v_ByDay='YES'                                            -- 06.03.2025
         THEN SET v_Group_by=' GROUP BY Date,xAffiliate ';           -- 06.03.2025
         ELSE SET v_Group_by=' GROUP BY LEFT(Date,7),xAffiliate ';   -- 06.03.2025
         END IF;                                                     -- 06.03.2025
   END IF;
END IF;

-- ----------------------------------------------------
SET v_FlagAll=if(v_Affiliate_id="ALL","1","0");
-- ----------------------------------------------------

/*---------------------------------------------------------------------------------*/

-- IF v_Debug!="NO" THEN SELECT v_Affiliate_id,v_MasterAff_id; END IF;

IF v_Affiliate_id in ("ALL","ALLdetail") 
THEN SET v_WhereAffiliate_id=""; 
ELSE SET v_WhereAffiliate_id=CONCAT(' AND Affiliate_id=',v_Affiliate_id);
END IF;

SET v_DataTable="Snapshot_day_by_day_fact2";

/*******************************************************************************/
-- IF v_Debug!="NO" THEN LEAVE proc_label; END IF;
/*******************************************************************************/
SET SESSION group_concat_max_len = 100000;

SET v_SQLbrands=CONCAT('
    SET @Check_Brands=(SELECT COUNT(DISTINCT Brand) FROM ',v_DataTable,'
    WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" ',v_WhereAffiliate_id,'
    AND Qualified_Players<0);'
);

IF v_Debug!="NO" THEN SELECT v_SQLbrands; END IF;

IF v_Debug!="YES" THEN
   SET @_sql = v_SQLbrands;
   PREPARE stmt1 FROM @_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

IF ifnull(@Check_Brands,0)=0 AND v_Filters="NO" THEN
    Select 'Not enough data to show' from dual;
    LEAVE proc_label;
END IF;

-- ----------------------------------------------------------------------------------------------------------

SET v_SQLmat=CONCAT('
    SET @SQLwrkMatrix=(
    SELECT GROUP_CONCAT(CONCAT("\r\nSUM(CASE WHEN Brand=\'", Brand,"\' THEN `Qualified_Players` ELSE 0 END) AS \'"
   ,REGEXP_REPLACE(Brand,"([A-Z]+)"," $1",4,0,"c"),"\'") ORDER BY Brand)
    FROM (
       SELECT DISTINCT `Brand` FROM ',v_DataTable,'
       WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" ',v_WhereAffiliate_id,'
       AND Qualified_Players<0
    ) AS xx);'
);

IF v_Debug!="NO" THEN SELECT v_SQLmat; END IF;

IF v_Debug!="YES" THEN
   SET @_sql = v_SQLmat;
   PREPARE stmt1 FROM @_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

-- ----------------------------------------------------------------------------------------------------------

SET v_SQLmet=CONCAT('
    SET @SQLwrkMatrixMeta=
    (SELECT GROUP_CONCAT("\'width=100px,right=true\'")
    FROM (
       SELECT DISTINCT Brand FROM ',v_DataTable,'
       WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" ',v_WhereAffiliate_id,'
       AND Qualified_Players<0
    ) AS xx);'
);

IF v_Debug!="YES" THEN
   SET @_sql = v_SQLmet;
   PREPARE stmt1 FROM @_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

-- ----------------------------------------------------------------------------------------------------------

IF v_Debug!="NO" THEN SELECT v_View,v_DataTable
                           ,v_MasterAff_id
                           ,v_WhereAffiliate_id
                           ,@Check_Brands,v_SQLbrands,v_SQLmat,v_SQLmet
                           ,@SQLwrkMatrix,@SQLwrkMatrixMeta; END IF;


-- ----------------------------------------------------------------------------------------------------------

SET v_SQLmeta=concat(
'(
SELECT
   "setting" as `Meta`
   ,"omit=true"                                          as `Owner`
   ,"width=100px"                                        as `Date`
   ,IF("',v_View,'"="VIEWGES","width=150px","omit=true") as `Affiliate`
   ,IF("',v_MultiCurrency,'"="YES","width=080px","omit=true") as `Op Curr`
   ,"width=120px,right=true"                             as `Total`,'
   ,@SQLwrkMatrixMeta,'
   ,"width=100px,omit=true"                              as Total1
   ,"omit=yes"                                           as `Affiliate_id`
	FROM DUAL WHERE "',v_Meta,'"="YES")'
);

SET v_SQLwrkTotal=CONCAT(
   '(
    SELECT '
    ,IF(v_Meta="YES","'total' as `Meta`,",""),'
    Owner
    ,""                                      as `Date`
    ," ~~TOTAL~~"                            as `Affiliate`
    ,Data_currency                           as `Op Curr`
   ,SUM(`Qualified_Players`)                 AS `Total CPA`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(`Qualified_Players`)           AS `Total CPA1` \r\n
   ,`Affiliate_id`
   FROM '
   ,v_DataTable,
   ' WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" AND Qualified_Players<0 '
   ,v_WhereOwner,v_WhereAffiliate_id,v_WhereAdvertiser_id,')\r\n' -- 31.05.2023
   );

SET v_SQLwrkDetail=CONCAT(
   '(
    SELECT '
    ,IF(v_Meta="YES","'data' as `Meta`,",""),'
    Owner
   ,IF("',v_ByDay,'"="YES",Date,LEFT(Date,7)) as `xDate`
   ,IF("',v_Affiliate_id,'"="ALL",if("',v_ByDay,'"="YES","ALL",F.Affiliate),F.Affiliate) as `xAffiliate`
   ,Data_currency                           as `Op Curr`
   ,SUM(`Qualified_Players`) AS `Total`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(`Qualified_Players`) AS `Total1` \r\n
   ,`Affiliate_id`
   FROM '
   ,v_DataTable
   ,' F WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" AND Qualified_Players<0 '
   ,v_WhereOwner,v_WhereAffiliate_id,v_WhereAdvertiser_id,'\r\n' -- 31.05.2023
   ,v_Group_by,' HAVING SUM(`Qualified_Players`)<>0
   )');
--
SET v_SQLcheckTotal=CONCAT(
   'SELECT SUM(Qualified_Players) INTO @Kreg FROM '
   ,v_DataTable,' WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" AND Qualified_Players<0 '
   ,v_WhereOwner,v_WhereAffiliate_id,v_WhereAdvertiser_id); -- 31.05.2023

SET v_SQLnodataTotal='SELECT "data" as `Meta`,"No data to show" as "" FROM DUAL
UNION ALL SELECT "setting" as `Meta`, "omit=true"  FROM DUAL';   -- 04.09.2023
--
IF v_Debug!="NO" THEN SELECT v_Debug,v_View,v_Month_Report,v_Affiliate_id
                           ,v_SQLmeta,v_SQLwrkTotal,v_SQLwrkDetail,v_SQLcheckTotal; END IF;

IF v_MatrixBy='SIGNUP' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Signups");
   SET v_SQLwrkDetail   =REPLACE(v_SQLwrkDetail,   "Qualified_Players","Signups");
   SET v_SQLwrkTotal    =REPLACE(v_SQLwrkTotal,    "Qualified_Players","Signups");
   SET v_SQLcheckTotal  =REPLACE(v_SQLcheckTotal,  "Qualified_Players","Signups");
   SET v_SQLwrkDetail   =REPLACE(v_SQLwrkDetail,   "Total CPA","Total Signups");
   SET v_SQLwrkTotal    =REPLACE(v_SQLwrkTotal,    "Total CPA","Total Signups");
   -- SET v_OrderByClauseEnd=REPLACE(v_OrderByClauseEnd,"Total CPA","Total Signups");
END IF;

-- ---------------------------------------------------------------

-- IF v_Debug != "YES" THEN
   SET @_sql = v_SQLcheckTotal;
	PREPARE stmt1 FROM @_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
-- END IF;
-- ---------------------------------------------------------------

IF v_Debug!="NO" THEN SELECT v_SQLcheckTotal, @Kreg; END IF;
IF v_Debug!="NO" THEN SELECT @SQLwrkMatrix; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLwrkDetail; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLwrkTotal;  END IF;

SET v_SQL = CONCAT(
    if(v_Total='YES' AND v_TotLine='FIRST',v_SQLwrkTotal,'')
   ,if(v_Total='YES' AND v_TotLine='FIRST',' UNION ALL ','')
   ,v_SQLwrkDetail
   ,if(v_Total='YES' AND v_TotLine!='FIRST',' UNION ALL ','')
   ,if(v_Total='YES' AND v_TotLine!='FIRST',v_SQLwrkTotal,'')
   ,IF(v_Meta='YES',' UNION ALL ','')
   ,IF(v_Meta='YES',v_SQLmeta,'')
   ,v_Order_By
   ,';');

-- IF @Kreg IS NULL OR @Kreg<1 THEN SET v_SQL=v_SQLnodataTotal; END IF;

SET v_M0=left(date_sub(curdate(), interval 0 month),7);
SET v_M1=left(date_sub(curdate(), interval 1 month),7);
SET v_M2=left(date_sub(curdate(), interval 2 month),7);
SET v_M3=left(date_sub(curdate(), interval 3 month),7);
SET v_M4=left(date_sub(curdate(), interval 4 month),7);
SET v_M5=left(date_sub(curdate(), interval 5 month),7);
SET v_M6=left(date_sub(curdate(), interval 6 month),7);
SET v_M7=left(date_sub(curdate(), interval 7 month),7);


SET v_SQL_Affiliate_list=CONCAT(
   'WITH Affiliate_list as (
    SELECT
       `Affiliate`
      ,`Affiliate_id`
      ,SUM(`Qualified_Players`) AS "CPA"
      ,count(*) AS "Rows"
      FROM '
   ,v_DataTable,'
    WHERE LEFT(DATE,7)',v_Compare,'"',v_Month_Report,'" AND Qualified_Players<0 '
   ,v_WhereOwner,v_WhereAffiliate_id,v_WhereAdvertiser_id,'\r\n' -- 31.05.2023
   ,'GROUP BY `Affiliate`,`Affiliate_id` HAVING SUM(`Qualified_Players`)<>0
   )');


SET v_SQLfilters=CONCAT(
v_SQL_Affiliate_list,'
(SELECT "7" as "Korder","Affiliate" AS "Key",`Affiliate`    AS "Value","Affiliate_id"    AS `CallKey`,`Affiliate_id` AS "CallValue","" AS "Rows"
  FROM Affiliate_list) UNION ALL
(SELECT "1","Month"   ,"',v_M0,'"              ,"Month"       ,"',v_M0,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M1,'"              ,"Month"       ,"',v_M1,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M2,'"              ,"Month"       ,"',v_M2,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M3,'"              ,"Month"       ,"',v_M3,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M4,'"              ,"Month"       ,"',v_M4,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M5,'"              ,"Month"       ,"',v_M5,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M6,'"              ,"Month"       ,"',v_M6,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"',v_M7,'"              ,"Month"       ,"',v_M7,'"   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"Last 6 months"  ,"LastMonths" ,"YES" ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "3","Criteria","Data By Day"    ,"ByDay"       ,"YES" ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "3","Criteria","ALL: detail by day","Affiliate_id","ALLdetail" ,"" AS "Rows" FROM DUAL where "',v_View,'"="VIEWGES")
-- (SELECT "5","Data"    ,v_Dat0            ,"MatrixBy"    ,v_Dat0 ,"" AS "Rows" FROM DUAL) UNION ALL
-- (SELECT "5","Data"    ,v_Dat1a           ,"MatrixBy"    ,v_Dat1 ,"" AS "Rows" FROM DUAL) UNION ALL
-- (SELECT "5","Data"    ,v_Dat2            ,"MatrixBy"    ,v_Dat2 ,"" AS "Rows" FROM DUAL) UNION ALL
-- (SELECT "5","Data"    ,v_Dat3a           ,"MatrixBy"    ,v_Dat3 ,"" AS "Rows" FROM DUAL) UNION ALL
-- (SELECT "5","Data"    ,v_Dat5a           ,"MatrixBy"    ,v_Dat5 ,"" AS "Rows" FROM DUAL)
ORDER BY 1, CASE WHEN `CallKey`="Affiliate_id"  THEN Value ELSE "1" END  ASC,
				CASE WHEN `CallKey`!="Affiliate_id" THEN Value ELSE "1" END  DESC
;');

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Debug != "YES" THEN
   SET @_sql = v_SQL;
	PREPARE stmt1 FROM @_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Report_CPA_quitadas(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call Report_CPA_quitadas('View=VIEWGES,debug=yes');
call Report_CPA_quitadas('View=VIEWGES,filters=yes,debug=ye');
call Report_CPA_quitadas('View=VIEWGES,Month=LM,debug=yes');
call Report_CPA_quitadas('View=ViewGES,Affiliate_id=all,Month=lm,ByDay=yes,filters=yes,debug=ye');
call Report_CPA_quitadas('View=ViewGES,Affiliate_id=ALL,Month=lm,ByDay=yes,filters=yes,debug=yeS');
call Report_CPA_quitadas('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=2022-08,meta=yes');
call Report_CPA_quitadas('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999
call Report_CPA_quitadas('View=ViewAFF,Month=2022-12,Affiliate_id=39,ByDay=yes,MatrixBy=cpa,meta=yes,filters=yes,debug=no');

call Report_CPA_quitadas('View=ViewAFF,Month=2023-07,Affiliate_id=39,ByDay=yes,MatrixBy=ftd,meta=yes,debug=no');
call Report_CPA_quitadas('View=ViewAFF,Month=2022-12,Affiliate_id=39,ByDay=yes,MatrixBy=click,meta=yes,debug=no');
call Report_CPA_quitadas('View=ViewGES,Month=LM,debug=yes');
call Report_CPA_quitadas('View=ViewGES,filters=yes,debug=non');
call Report_CPA_quitadas('View=ViewGES,Affiliate_id=512,filters=ye,debug=ye');
call Report_CPA_quitadas('View=ViewGES,Affiliate_id=39,LastMonths=YES,debug=ye');
call Report_CPA_quitadas('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=ftd,meta=yes,debug=ye');
call Report_CPA_quitadas('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=totcomm,meta=yes,debug=ye');
-- sub/mafcall Report_CPA_quitadas('View=ViewAFF,Month=LM,Affiliate_id=829,MatrixBy=totcomm,debug=ye');
call Report_CPA_quitadas('View=ViewMAF,Month=LM,debug=ye'); -- ERROR falta MasterAff_id
call Report_CPA_quitadas('View=ViewMAF,MasterAff_id=39,Month=LM,debug=ye'); -- ERROR MasterAff_id no es MAF
call Report_CPA_quitadas('View=ViewMAF,MasterAff_id=440,Month=LM,debug=ye');
call Report_CPA_quitadas('View=ViewMAF,MasterAff_id=440,Month=LM,filters=yes,debug=ye');
call Report_CPA_quitadas('View=ViewGES,MasterAff_id=440,Month=LM,filters=yes,debug=ye');
call Report_CPA_quitadas('View=ViewAFF,Affiliate_id=469,Month=lm,ByDay=yes,filters=ye,meta=YEs,debug=ye');

call Report_CPA_quitadas('View=ViewGES,Affiliate_id=all,Month=CM,filters=ye,meta=yes,debug=yes');
call Report_CPA_quitadas('View=ViewAFF,Month=lm,Affiliate_id=39,ByDay=yes,MatrixBy=totcomm,meta=yes,debug=ye');
*/
