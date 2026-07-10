/*
PROCEDURE_lite_Info_for_graph_v1.sql - Produce una grilla para gráficos LITE

Descripción:
  Procedimiento lite_Info_for_graph.

Observaciones:
Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value debe estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada

Keys:
Month         =[AAAA-MM]. OPCIONAL. Default=Current Month.
Advertiser_id =[ALL | Advertiser_id]. OPCIONAL. Default=ALL
Username_id   =[ALL | Username_id]. OPCIONAL. Default=ALL
Publisher_id  =[ALL | Publisher_id]. OPCIONAL. Default=ALL
InfoSource    =[Comms | MainData]. OPCIONAL. Default=Comms
InfoBy        =[Brand | Publisher | Username]. OPCIONAL. Default=Brand
Filters       =[Yes | No]. OPCIONAL. Default=No
Meta          =[No | Yes]. OPCIONAL. Default=Yes
Debug         =[No | Yes]. OPCIONAL. Default=No
InputCommLine = [valor]. Parámetro de entrada.

Ejemplos:
call lite_Info_for_graph('filters=yes,debug=ye');
call lite_Info_for_graph('filters=yes,InfoSource=MainData,debug=ye');
call lite_Info_for_graph('month=CM,InfoSource=Comms,info_by=Brand,meta=ye,debug=ye');
call lite_Info_for_graph('month=CM,InfoSource=MainData,info_by=Brand,meta=ye,debug=ye');

-- call lite_Info_for_graph('month=LM,info_by=Publisher,debug=ye');
-- call lite_Info_for_graph('month=LM,info_by=Username,debug=ye');

14.02.2026 v1     Primera versión
01.03.2026 v1.1   Cambio a variables locales para facilitar mantenimiento y mejorar performance 
10.04.2026 v1.2   Meta/grid/filtros: etiqueta nombre publisher -> Operator (CallValue InfoBy sigue Publisher)
*/

DROP PROCEDURE IF EXISTS lite_Info_for_graph;
-- DROP PROCEDURE IF EXISTS lite_Info_for_graph_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `lite_Info_for_graph`(IN
   InputCommLine    VARCHAR(250)
   )
   COMMENT 'LITE - Movimientos para graficos'
BEGIN
DECLARE v_Version           VARCHAR(30);
DECLARE v_Month             VARCHAR(7);
DECLARE v_InfoSource        VARCHAR(20);
DECLARE v_InfoBy            VARCHAR(20);
DECLARE v_Username_id       VARCHAR(100);
DECLARE v_Advertiser_id     VARCHAR(100);
DECLARE v_Publisher_id      VARCHAR(100);
DECLARE v_Filters           VARCHAR(3);
DECLARE v_Meta              VARCHAR(3);
DECLARE v_Debug             VARCHAR(3);
DECLARE v_InputCommLine     VARCHAR(260);
DECLARE v_e                 INT;
DECLARE v_c                 INT;
DECLARE v_k                 VARCHAR(100);
DECLARE v_v                 VARCHAR(250);
DECLARE v_WhereUsername_id  VARCHAR(200);
DECLARE v_WhereAdvertiser_id VARCHAR(200);
DECLARE v_WherePublisher_id VARCHAR(200);
DECLARE v_SQLbaseComms      LONGTEXT;
DECLARE v_SQLbaseMainData   LONGTEXT;
DECLARE v_SQL               LONGTEXT;
DECLARE v_SQLfiltersComms   LONGTEXT;
DECLARE v_SQLfiltersMainData LONGTEXT;
DECLARE v_SQLfilters        LONGTEXT;
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version            ='v1.2 10.04.2026'; 
SET v_Month              =LEFT(CURDATE(),7);
SET v_InfoSource         ='Comms';
SET v_InfoBy             ='Brand';
SET v_Username_id        ='ALL';
SET v_Advertiser_id      ='ALL';
SET v_Publisher_id       ='ALL';

SET v_Filters            ='NO';
SET v_Meta               ='NO';
SET v_Debug              ='NO';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;

-- Procesamiento de parámetros de entrada
-- Los parámetros multivalor se indican con ^ al inicio del nombre del parámetro
-- y los valores se separan con ^
WHILE v_InputCommLine>' ' DO
   -- Extracción de key=value
   SET v_e=INSTR(v_InputCommLine,'=');
   SET v_c=INSTR(v_InputCommLine,',');
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1);
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1));
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   -- Asignación de valores a variables según el parámetro
   IF lower(v_k)='month'         THEN SET v_Month        =UPPER(v_v); END IF;
   IF lower(v_k)='infosource'    THEN SET v_InfoSource   =UPPER(v_v); END IF;
   IF lower(v_k)='infoby'        THEN SET v_InfoBy       =UPPER(v_v); END IF;
   IF lower(v_k)='username_id'   THEN SET v_Username_id  =      v_v; END IF;
   IF lower(v_k)='advertiser_id' THEN SET v_Advertiser_id=      v_v; END IF;
   IF lower(v_k)='publisher_id'  THEN SET v_Publisher_id =      v_v; END IF;

   IF lower(v_k)='filters'       THEN SET v_Filters      =UPPER(v_v); END IF;
   IF lower(v_k)='meta'          THEN SET v_Meta         =UPPER(v_v); END IF;
   IF lower(v_k)='debug'         THEN SET v_Debug        =UPPER(v_v); END IF;
END WHILE;

IF  v_Month = "CM" THEN SET v_Month=LEFT(CURDATE(),7); END IF;
IF  v_Month = "LM" THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF v_Debug!="NO" THEN SELECT v_Month,v_InfoSource,v_InfoBy,v_Username_id,v_Advertiser_id,v_Publisher_id,v_Filters,v_Meta,v_Debug,InputCommLine; END IF;

SET v_WhereUsername_id='';
SET v_WhereAdvertiser_id='';
SET v_WherePublisher_id='';

IF v_Username_id  !="ALL" THEN SET v_WhereUsername_id=CONCAT(" AND D.Username_id = ",v_Username_id); END IF;
IF v_Advertiser_id!="ALL" THEN SET v_WhereAdvertiser_id=CONCAT(" AND D.Advertiser_id = ",v_Advertiser_id); END IF;
IF v_Publisher_id !="ALL" THEN SET v_WherePublisher_id=CONCAT(" AND D.Publisher_id = ",v_Publisher_id); END IF;

SET v_SQLbaseComms=concat('
WITH MainDataDetail AS (
SELECT
    D.Month                            AS `Month`
   ,D.Publisher_id                     AS `Publisher_id`
   ,D.Advertiser_id                    AS `Advertiser_id`
   ,D.Username_id                      AS `Username_id`
   ,P.Advertiser_Name                  AS `Operator`
   ,A.Advertiser_Name                  AS `Advertiser`
   ,U.Username                         AS `Username`
   ,sum(D.CPA)                         AS `CPA`
   ,sum(D.Net_Revenue)                 AS `Net_Revenue`
   ,sum(D.net_CPA_Val)                 AS `net_CPA_Val`
   ,sum(D.net_RS_Val)                  AS `net_RS_Val`
   ,sum(D.net_Total_comm)              AS `net_Total_comm`
FROM monthly_comms_gestor_v5 D
inner join campaign_advertiser A on D.Advertiser_id = A.id
inner join campaign_publisher P on D.Publisher_id = P.id
inner join campaign_username U on D.Username_id = U.id
WHERE D.Month = "',v_Month,'" '
   ,v_WhereUsername_id
   ,v_WhereAdvertiser_id
   ,v_WherePublisher_id
,'
GROUP BY 
    case when "',v_InfoBy,'"="Publisher" then D.Publisher_id else "" end,
    case when "',v_InfoBy,'"="Brand" then D.Advertiser_id else "" end,
    case when "',v_InfoBy,'"="Username" then D.Username_id else "" end
)
SELECT
   ',IF(v_Meta="YES","'setting' as `Meta`,",""),'   
    "width=90px"   as `Month`
   ,"width=90px"  as `Publisher_id`
   ,"width=90px"  as `Advertiser_id`
   ,"width=90px"  as `Username_id`
   ,"width=140px" as `Operator`
   ,"width=140px" as `Advertiser`
   ,"width=140px" as `Username`
   ,"width=100px,right=true"  as `CPA`
   ,"width=100px,right=true"  as `Net_Revenue`
   ,"width=100px,right=true"  as `net_CPA_Val`
   ,"width=100px,right=true"  as `net_RS_Val`
   ,"width=100px,right=true"  as `net_Total_comm`
FROM DUAL WHERE "',v_Meta,'"="YES"
UNION ALL
SELECT     
     ',IF(v_Meta="YES","'data' as `Meta`,",""),'
       Month, 
       Publisher_id, 
       Advertiser_id, 
       Username_id, 
       Operator, 
       Advertiser, 
       Username, 
       CPA, 
       Net_Revenue, 
       net_CPA_Val, 
       net_RS_Val, 
       net_Total_comm
FROM MainDataDetail
ORDER BY 
   case when "',v_InfoBy,'"="Publisher" then Operator else "" end, 
   case when "',v_InfoBy,'"="Brand" then Advertiser else "" end,
   case when "',v_InfoBy,'"="Username" then Username else "" end
;');

/**************************************************************************************************************/

SET v_SQLbaseMainData=concat('
WITH MainDataDetail AS (
SELECT
    Left(D.Date,7)                     AS `Month`
   ,D.Publisher_id                     AS `Publisher_id`
   ,D.Advertiser_id                    AS `Advertiser_id`
   ,D.Username_id                      AS `Username_id`
   ,P.Advertiser_Name                  AS `Operator`
   ,A.Advertiser_Name                  AS `Advertiser`
   ,U.Username                         AS `Username`
   ,sum(D.Qualified_Players)           AS `CPA`
   ,sum(D.First_Time_Deposit)          AS `FTD`
   ,sum(D.Signups)                     AS `Signups`
   ,sum(D.Clicks)                      AS `Clicks`
   ,sum(D.Deposits)                    AS `Deposits`
   ,sum(D.Net_Revenue)                 AS `NR`
   ,sum(D.CPA_Value_Gestor)            AS `CPA_Value`
   ,sum(D.Revenue_Share_Gestor)        AS `RS`
FROM Snapshot_day_by_day_fact1 D
inner join campaign_advertiser A on D.Advertiser_id = A.id
inner join campaign_publisher P on D.Publisher_id = P.id
inner join campaign_username U on D.Username_id = U.id
WHERE Left(D.Date,7) = "',v_Month,'" '
   ,v_WhereUsername_id
   ,v_WhereAdvertiser_id
   ,v_WherePublisher_id
,'
GROUP BY 
    case when "',v_InfoBy,'"="Publisher" then D.Publisher_id else "" end,
    case when "',v_InfoBy,'"="Brand" then D.Advertiser_id else "" end,
    case when "',v_InfoBy,'"="Username" then D.Username_id else "" end
)
SELECT
   ',IF(v_Meta="YES","'setting' as `Meta`,",""),'   
    "width=90px"   as `Month`
   ,"width=90px"  as `Publisher_id`
   ,"width=90px"  as `Advertiser_id`
   ,"width=90px"  as `Username_id`
   ,"width=140px" as `Operator`
   ,"width=140px" as `Advertiser`
   ,"width=140px" as `Username`
   ,"width=100px,right=true"  as `CPA`
   ,"width=100px,right=true"  as `FTD`
   ,"width=100px,right=true"  as `Signups`
   ,"width=100px,right=true"  as `Clicks`
   ,"width=100px,right=true"  as `Deposits`
   ,"width=100px,right=true"  as `NR`
   ,"width=100px,right=true"  as `CPA_Value`
   ,"width=100px,right=true"  as `RS`
FROM DUAL WHERE "',v_Meta,'"="YES"
UNION ALL
SELECT     
     ',IF(v_Meta="YES","'data' as `Meta`,",""),'
       Month, 
       Publisher_id, 
       Advertiser_id, 
       Username_id, 
       Operator, 
       Advertiser, 
       Username, 
       CPA, 
       FTD, 
       Signups, 
       Clicks, 
       Deposits, 
       NR, 
       CPA_Value, 
       RS
FROM MainDataDetail
ORDER BY 
   case when "',v_InfoBy,'"="Publisher" then Operator else "" end, 
   case when "',v_InfoBy,'"="Brand" then Advertiser else "" end,
   case when "',v_InfoBy,'"="Username" then Username else "" end
;');

/**************************************************************************************************************/

SET v_SQL=case when v_InfoSource="Comms" then v_SQLbaseComms 
               when v_InfoSource="MainData" then v_SQLbaseMainData end; 

-- -------------FILTERS----------------------------------------------
SET v_SQLfiltersComms=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
),
BaseCount AS (
SELECT
    D.Month                            AS `Month`
   ,D.Publisher_id                     AS `Publisher_id`
   ,D.Advertiser_id                    AS `Advertiser_id`
   ,D.Username_id                      AS `Username_id`
   ,A.Advertiser_Name                  AS `Advertiser`
   ,P.Advertiser_Name                  AS `Operator`
   ,U.Username                         AS `Username`
FROM monthly_comms_gestor_v5 D
inner join campaign_advertiser A on D.Advertiser_id = A.id
inner join campaign_publisher P on D.Publisher_id = P.id
inner join campaign_username U on D.Username_id = U.id
WHERE D.Month = "',v_Month,'" '
   ,v_WhereUsername_id
   ,v_WhereAdvertiser_id
   ,v_WherePublisher_id,'
GROUP BY 
    case when "',v_InfoBy,'"="Publisher" then P.Advertiser_Name else "" end,
    case when "',v_InfoBy,'"="Brand" then A.Advertiser_Name else "" end,
    case when "',v_InfoBy,'"="Username" then U.Username else "" end
)
(SELECT "01" as "Korder","Month" AS "Key",LEFT(`Date`,7) AS "Value","Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`,"" AS "Rows" FROM MonthFilter) UNION ALL
(SELECT "05","InfoSource","Commission","InfoSource","Comms"  ,"" as K FROM DUAL) UNION ALL
(SELECT "05","InfoSource","Main data","InfoSource","MainData"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Brand","InfoBy","Brand"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Operator","InfoBy","Publisher"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Username","InfoBy","Username"  ,"" as K FROM DUAL)
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3 ASC
;');           
-- -------------FILTERS----------------------------------------------
SET v_SQLfiltersMainData=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
),
BaseCount AS (
SELECT
    Left(D.Date,7)                     AS `Month`
   ,D.Publisher_id                     AS `Publisher_id`
   ,D.Advertiser_id                    AS `Advertiser_id`
   ,D.Username_id                      AS `Username_id`
   ,A.Advertiser_Name                  AS `Advertiser`
   ,P.Advertiser_Name                  AS `Operator`
   ,U.Username                         AS `Username`
FROM Snapshot_day_by_day_fact1 D
inner join campaign_advertiser A on D.Advertiser_id = A.id
inner join campaign_publisher P on D.Publisher_id = P.id
inner join campaign_username U on D.Username_id = U.id
WHERE D.Month = "',v_Month,'" '
   ,v_WhereUsername_id
   ,v_WhereAdvertiser_id
   ,v_WherePublisher_id,'
GROUP BY 
    case when "',v_InfoBy,'"="Publisher" then P.Advertiser_Name else "" end,
    case when "',v_InfoBy,'"="Brand" then A.Advertiser_Name else "" end,
    case when "',v_InfoBy,'"="Username" then U.Username else "" end
)
(SELECT "01" as "Korder","Month" AS "Key",LEFT(`Date`,7) AS "Value","Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`,"" AS "Rows" FROM MonthFilter) UNION ALL
(SELECT "05","InfoSource","Commission","InfoSource","Comms"  ,"" as K FROM DUAL) UNION ALL
(SELECT "05","InfoSource","Main data","InfoSource","MainData"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Brand","InfoBy","Brand"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Operator","InfoBy","Publisher"  ,"" as K FROM DUAL) UNION ALL
(SELECT "10","InfoBy","Username","InfoBy","Username"  ,"" as K FROM DUAL)
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3 ASC
;');                             

IF v_Debug!="NO" THEN SELECT v_InfoSource,v_InfoBy,v_SQLbaseComms,v_SQLbaseMainData,v_SQLfiltersComms,v_SQLfiltersMainData; END IF;

SET v_SQLfilters=case when v_InfoSource="Comms" then v_SQLfiltersComms 
                      when v_InfoSource="MainData" then v_SQLfiltersMainData end; 

IF v_Debug!="NO" THEN SELECT v_SQL; END IF;
IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug != "YES" THEN
   SET @v_SQL_exec = v_SQL;
   PREPARE stmt1 FROM @v_SQL_exec;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call lite_Info_for_graph('');
call lite_Info_for_graph('month=2026-02,affiliate_id=348,brand=sisal,debug=ye');
call lite_Info_for_graph('month=2025-122026-01,affiliate_id=39450');
*/
