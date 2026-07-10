/* 
PROCEDURE_Dash_ChannelMatrix.sql() - CPA/Signup/FTD/Click - Matriz por Channel 

Descripción:
  Procedimiento Dash_ChannelMatrix.

Observaciones: 

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.
   
Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month           =[AAAA-MM]. OPCIONAL. Default=Current Month día>=6. Last Month día<6
MatrixBy        =[CPA | Signup | FTD | Click | NR ]. OPCIONAL. Default=CPA
Affiliate_id    =[ALL | id del Affiliate_id]. 
                  OBLIGATORIO
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Dash_ChannelMatrix(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call Dash_ChannelMatrix('View=VIEWGES');
call Dash_ChannelMatrix('View=VIEWGES,OrderBy=CPA,meta=yes,debug=no');
call Dash_ChannelMatrix('View=ViewGES,Affiliate_id=39,Month=2022-08,debug=yes');
call Dash_ChannelMatrix('View=ViewGES,Affiliate_id=ALL,Month=2022-08,ByDay=yes');
call Dash_ChannelMatrix('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=2022-08,meta=yes');
call Dash_ChannelMatrix('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999

call Dash_ChannelMatrix('View=ViewAFF,Affiliate_id=39,ByDay=yes,debug=no');
call Dash_ChannelMatrix('View=ViewGES,Owner=2,Month=2022-08');

07.06.2023 V1     Primera versión. Adaptación de Dash_BrandMatrix
12.06.2023 V1.1   Detalle por Brand
*/

DROP PROCEDURE IF EXISTS Dash_ChannelMatrix;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_ChannelMatrix`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'CPA/Reg/FTD/Global/NR - Matriz por Channel'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v1.1 12.06.2023';
SET @Month        =LEFT(CURDATE(),7);
SET @MatrixBy     ='CPA';
SET @Affiliate_id ='';
SET @Debug        ='NO';
SET @Meta         ='NO';
SET @ByDay        ='NO';
SET @Filters      ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit
-- @InputCommLine: ----5----0----5----0----5----0----5----0--
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);   

   IF lower(@k)='Month'         THEN SET @Month        =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id' THEN SET @Advertiser_id=UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'  THEN SET @Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='byday'         THEN SET @ByDay        =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;
   IF lower(@k)='matrixby'      THEN SET @MatrixBy     =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;

END WHILE;

IF @Month='CM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

SET @Month_Report=@Month;

SET @OrderByClauseEnd=' ORDER BY convert(`Total CPA`,unsigned) desc';
SET @OrderByClauseEnd=' ORDER BY Date ';

-- IF  @OrderBy="PROFIT"     THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`Profit` ',@Order);    END IF;
-- IF  @OrderBy="CPAVALUE"   THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`CPA_Value` ',@Order); END IF;
-- IF  @OrderBy="ADVERTISER" THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`Channel` ',@Order);     END IF;
   
/**************************************************************************************************************/
-- En views de Afiliado impide pedir @Affiliate_id="ALL"  
IF   @Affiliate_id IN ("","ALL")
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

SET @DataTable=" FROM Snapshot_day_by_day_fact2 ";

SET @WhereAffiliate_id=CONCAT(' AND Affiliate_id=',@Affiliate_id); 

-- ----------------------------------------------------
IF @ByDay='YES' THEN SET @Group_by=' GROUP BY Date,Brand ';
ELSE SET @Group_by=' GROUP BY LEFT(Date,7),Brand ';
END IF;

SET SESSION group_concat_max_len = 200000;

-- ----------------------------------------------------   
      
SET @Check_CPA=(SELECT COUNT(DISTINCT Channel) FROM Snapshot_day_by_day_fact2
   WHERE LEFT(DATE,7)=@Month_Report AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll)
   AND (Qualified_Players<>0 OR Signups<>0 OR First_Time_Deposit<>0 OR Net_Revenue<>0));      

IF @Debug!="NO" THEN SELECT @Month,@Month_Report,@MatrixBy,@Affiliate_id,@ByDay; END IF;

IF @Check_CPA=0 THEN      
    Select 'Not enough data to show' from dual;
    LEAVE proc_label;
END IF; 

SET @SQLwrkMatrix=
(SELECT GROUP_CONCAT(CONCAT("\r\nSUM(CASE WHEN Channel='", Channel,"' THEN `Qualified_Players` ELSE 0 END) AS '"
,REGEXP_REPLACE(Channel,"([A-Z]+)"," $1",4,0,"c"),"'") ORDER BY Channel)
FROM (
   SELECT DISTINCT Channel FROM Snapshot_day_by_day_fact2
   WHERE LEFT(DATE,7)=@Month_Report AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll)
   AND (Qualified_Players<>0 OR Signups<>0 OR First_Time_Deposit<>0 OR Net_Revenue<>0)
) AS xx);

SET @SQLwrkMatrixMeta=
(SELECT GROUP_CONCAT('"width=150px,center=true"')
FROM (
   SELECT DISTINCT Channel FROM Snapshot_day_by_day_fact2
   WHERE LEFT(DATE,7)=@Month_Report AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll)
   AND (Qualified_Players<>0 OR Signups<>0 OR First_Time_Deposit<>0 OR Net_Revenue<>0)
) AS xx);

--
 
SET @SQLmeta=concat(
'( 
SELECT  
   "setting"  as `Meta`
   ,"width=100px" as Date
   -- ,"width=150px" as Affiliate
   ,"width=150px" as Brand
   ,"width=100px,center=true" as Total, '
   ,@SQLwrkMatrixMeta
   ,' FROM DUAL WHERE "',@Meta,'"="YES")'
);
IF @Debug!="NO" THEN SELECT @SQLmeta,@SQLwrkMatrixMeta; END IF;

--

SET @SQLwrkTotal=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'total' as `Meta`,",""),'
     LEFT(DATE,7) as `Date`
    -- ," ~~~~~~~~~" as `Affiliate`
    ," ~~TOTAL~~" as `Brand`
   ,SUM(Qualified_Players) AS `Total CPA`,'
   ,@SQLwrkMatrix
   ,'\r\n'
   ,@DataTable,'WHERE LEFT(DATE,7)="',@Month_Report,'"'
   ,@WhereAffiliate_id,'\r\n'
   ,'
   )');
   
SET @SQLwrkDetail=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'data' as `Meta`,",""),'
    IF("',@ByDay,'"="YES",Date,LEFT(Date,7)) as `Date`
   -- ,Affiliate as              `Affiliate`
   ,Brand     as              `Brand`
   ,SUM(Qualified_Players) AS `Total`,'
   ,@SQLwrkMatrix
   ,' \r\n'
   ,@DataTable
   ,'WHERE LEFT(DATE,7)="',@Month_Report,'"'
   ,@WhereAffiliate_id,'\r\n'
   ,@Group_by,' HAVING SUM(Qualified_Players)<>0
   )');
-- 
SET @SQLcheckTotal=CONCAT(
   'SELECT SUM(Qualified_Players) INTO @Kreg '
   ,@DataTable,'WHERE LEFT(DATE,7)="',@Month_Report,'"'
   ,@WhereAffiliate_id,'\r\n'); 

IF @Debug!="NO"  THEN SELECT @SQLwrkMatrix,@SQLwrkMatrixMeta; END IF;   
IF @Debug!="NO" THEN SELECT @Debug,@View,@Month_Report,@Affiliate_id,@SQLwrkAffiliate_id,@SQLwrkAllAff; END IF;

SET @SQLnodataTotal='SELECT "data" as `Meta`,"No data to show" as "" FROM DUAL ';

IF @MatrixBy='SIGNUP' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Signups");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Signups");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Signups");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Signups");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total Signups");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total Signups");
   SET @OrderByClauseEnd=REPLACE(@OrderByClauseEnd,"Total CPA","Total Signups");
END IF;

IF @MatrixBy='FTD' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","First_Time_Deposit");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total FTD");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total FTD");
   SET @OrderByClauseEnd=REPLACE(@OrderByClauseEnd,"Total CPA","Total FTD");
END IF;

IF @MatrixBy='CLICK' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Clicks");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Clicks");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Clicks");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Clicks");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total Clicks");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total Clicks");
   SET @OrderByClauseEnd=REPLACE(@OrderByClauseEnd,"Total CPA","Total Clicks");
END IF;

-- IF @MatrixBy='NR' THEN
   -- SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Net_Revenue");
   -- SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Net_Revenue");
   -- SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Net_Revenue");
   -- SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Net_Revenue");
   -- SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Net_Revenue");
   -- SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Net_Revenue");
   -- SET @OrderByClauseEnd=REPLACE(@OrderByClauseEnd,"Total CPA","Affiliate");
-- END IF;
-- ---------------------------------------------------------------

-- IF @Debug != "YES" THEN 
	PREPARE stmt1 FROM @SQLcheckTotal;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;   
-- END IF;
-- ---------------------------------------------------------------

IF @Debug!="NO" THEN SELECT @SQLcheckTotal, @Kreg; END IF;
IF @Debug!="NO" THEN SELECT @SQLwrkMatrix; END IF;   
IF @Debug!="NO" THEN SELECT @SQLwrkDetail; END IF;   
IF @Debug!="NO" THEN SELECT @SQLwrkTotal; END IF;   
   
SET @SQL = CONCAT(
 @SQLwrkTotal ,'\r\n UNION ALL \r\n'
,@SQLwrkDetail,'\r\n UNION ALL \r\n'
,@SQLmeta,'\r\n'
,@OrderByClauseEnd
,';');

IF @Kreg IS NULL OR @Kreg<1 THEN SET @SQL=@SQLnodataTotal; END IF;

SET @M0=left(date_sub(curdate(), interval 0 month),7);
SET @M1=left(date_sub(curdate(), interval 1 month),7);
SET @M2=left(date_sub(curdate(), interval 2 month),7);
SET @M3=left(date_sub(curdate(), interval 3 month),7);
SET @M4=left(date_sub(curdate(), interval 4 month),7);
SET @M5=left(date_sub(curdate(), interval 5 month),7);
SET @M6=left(date_sub(curdate(), interval 6 month),7);
SET @M7=left(date_sub(curdate(), interval 7 month),7);
SET @M2=left(date_sub(curdate(), interval 2 month),7);
SET @Dat0='CPA';
SET @Dat1='Signup';
SET @Dat2='FTD';
SET @Dat3='Click';
SET @Dat4='NR';

SET @SQLfilters=CONCAT(
'
(SELECT "1" as "Korder","Month" AS "Key",@M0   AS "Value","Month"    AS `CallKey`,@M0   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M1   AS "Value","Month"    AS `CallKey`,@M1   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M2   AS "Value","Month"    AS `CallKey`,@M2   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M3   AS "Value","Month"    AS `CallKey`,@M3   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M4   AS "Value","Month"    AS `CallKey`,@M4   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M5   AS "Value","Month"    AS `CallKey`,@M5   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M6   AS "Value","Month"    AS `CallKey`,@M6   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M7   AS "Value","Month"    AS `CallKey`,@M7   AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "2" as "Korder","Data"  AS "Key",@Dat0 AS "Value","MatrixBy" AS `CallKey`,@Dat0 AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "2" as "Korder","Data"  AS "Key",@Dat1 AS "Value","MatrixBy" AS `CallKey`,@Dat1 AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "2" as "Korder","Data"  AS "Key",@Dat2 AS "Value","MatrixBy" AS `CallKey`,@Dat2 AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "2" as "Korder","Data"  AS "Key",@Dat3 AS "Value","MatrixBy" AS `CallKey`,@Dat3 AS "CallValue","" AS "Rows" FROM DUAL) 
ORDER BY 1,3 desc
;');

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;   
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN 
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;   
END IF;

END$$
DELIMITER ;

/*
call Dash_ChannelMatrix(' ');                                                                               --  ERROR Affiliate_id=ALL
call Dash_ChannelMatrix('Affiliate_id=ALL,ByDay=yes');                                                      --  ERROR Affiliate_id=ALL
call Dash_ChannelMatrix('Month=LM,Affiliate_id=39,ByDay=yes,MatrixBy=cpa,meta=yes,filters=yes,debug=no');
call Dash_ChannelMatrix('Month=lm,Affiliate_id=421,ByDay=yes,MatrixBy=CPA,meta=yes,debug=YE');
call Dash_ChannelMatrix('Month=LM,Affiliate_id=39,ByDay=yes,MatrixBy=ftd,filters=yes,meta=yes,debug=non');
call Dash_ChannelMatrix('Month=CM,Affiliate_id=39,ByDay=yes,MatrixBy=click,meta=yes,debug=no');
call Dash_ChannelMatrix('Month=LM');                                                                        --  ERROR Affiliate_id=ALL

*/