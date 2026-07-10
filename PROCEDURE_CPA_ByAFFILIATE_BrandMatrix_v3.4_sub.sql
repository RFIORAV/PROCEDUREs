/* 
PROCEDURE_CPA_ByAFFILIATE_BrandMatrix.sql() - CPA x Affiliate - Matriz por Brand 

Descripción:
  Procedimiento CPA_ByAFFILIATE_BrandMatrix.

Observaciones: 

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.
   
Keys:
InputCommLine = [valor]. Parámetro de entrada.

View            =[viewAFF | viewGES ]. Info de Fact2 (viewAFF) o de Fact1 (viewGES). OBLIGATORIO.
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month día>=6. Last Month día<6
MasterAff_id    =[ MasterAff_id ]. SOLO PARA MAF EN MODO viewGES. Default=''
Affiliate_id    =[ALL | id del Affiliate_id]. 
                  OPCIONAL para View=viewGES (Default=ALL).
                  OBLIGATORIO para View=viewAFF (Default=999999)
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
Total           =[Yes | No]. Incluye línea/s de Totales x OWNER/Currency. OPCIONAL. Default=Yes
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No
                  
Keys no utilizadas:
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call CPA_ByAFFILIATE_BrandMatrix(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call CPA_ByAFFILIATE_BrandMatrix('View=VIEWGES');
call CPA_ByAFFILIATE_BrandMatrix('View=VIEWGES,OrderBy=CPA,meta=yes,debug=no');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=39,Month=2022-08,debug=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=ALL,Month=2022-08,ByDay=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=2022-08,meta=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999

call CPA_ByAFFILIATE_BrandMatrix('View=ViewAFF,Affiliate_id=39,ByDay=yes,debug=no');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Owner=2,Month=2022-08');

04.09.2022 V1     Total_FACT1_AFFILIATE_CPAbyDay_BrandMatrix
08.09.2022 V2     FACT1/2 Como parámetro + Currency. Unifica acumulaciones de CPA
26.09.2022 V2.2   Optimización
26.09.2022 V3     Recodificacion de PROCEDURE_CPA_ByAFFILIATE_BrandMatrix. 
                  Parámetros con Key=Value en un solo campo de entrada como CommandLine
07.10.2022 v3.2   Columna METAdatos
25.10.2022 v3.3   Nombres Columnas Brand Matrix Separados en las mayúsculas con Regex
02.11.2022        Retorna con mensaje cuando no hay CPAs en la selección
11.06.2024 v3.4   Tratamiento de Master/Sub Affiliate
13.09.2024        No agrupa por Owner 
*/

DROP PROCEDURE IF EXISTS CPA_ByAFFILIATE_BrandMatrix_test;
DROP PROCEDURE IF EXISTS CPA_ByAFFILIATE_BrandMatrix;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `CPA_ByAFFILIATE_BrandMatrix`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'CPA x [Affiliate/ALL] - Matriz por Brand'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v3.4 13.09.2024';
SET @Owner        ='ALL';
SET @Month        =IF(DAY(CURDATE())<=5,LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),LEFT(CURDATE(),7));
SET @MasterAff_id ='';
SET @Advertiser_id='ALL';
SET @Currency     ='EUR';
SET @ByAccount    ='NO';
SET @OrderBy      ='CPA';
SET @Order        ='DESC';
SET @Total        ='YES';
SET @TotLine      ='FIRST';
SET @Debug        ='NO';
SET @Meta         ='NO';
SET @View         ='VIEWAFF';
SET @Affiliate_id ='ALL';
SET @ByDay        ='NO';
SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
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
   IF lower(@k)='owner'         THEN SET @Owner        =UPPER(@v); END IF;
   IF lower(@k)='month'         THEN SET @Month        =UPPER(@v); END IF;
   IF lower(@k)='masteraff_id'  THEN SET @MasterAff_id =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id' THEN SET @Advertiser_id=UPPER(@v); END IF;
   IF lower(@k)='currency'      THEN SET @Currency     =UPPER(@v); END IF;
   IF lower(@k)='byaccount'     THEN SET @ByAccount    =UPPER(@v); END IF;
   IF lower(@k)='orderby'       THEN SET @OrderBy      =UPPER(@v); END IF;
   IF lower(@k)='order'         THEN SET @Order        =UPPER(@v); END IF;
   IF lower(@k)='total'         THEN SET @Total        =UPPER(@v); END IF;
   IF lower(@k)='totline'       THEN SET @TotLine      =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='view'          THEN SET @View         =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'  THEN SET @Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='byday'         THEN SET @ByDay        =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount
                           ,@Debug,@Total,@TotLine,@OrderBy,@Order,@View,@Affiliate_id,@ByDay,InputCommLine; END IF;


/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET @AffiliateGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=@Affiliate_id AND  group_id=6);
IF  @AffiliateGroup IS NULL THEN SET @AffiliateGroup=0; END IF;

/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET @MasterAffGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=@MasterAff_id AND  group_id=4);
IF  @MasterAffGroup IS NULL THEN SET @MasterAffGroup=0; END IF;

SET @Affiliate_list='';
IF  @MasterAffGroup=4 THEN
    CALL Master_Sub_Affiliate(@MasterAff_id,@Affiliate_list); 
END IF;

SET @WhereAffiliate_list='';
IF  @MasterAffGroup=4 THEN
    SET @WhereAffiliate_list=CONCAT(" AND Affiliate_id IN ",@Affiliate_list);
END IF;

IF @Debug!="NO" THEN SELECT @MasterAff_id,@MasterAffGroup,@WhereAffiliate_list; END IF;

/*---------------------------------------------------------------------------------*/

IF @Owner="ALL" THEN SET @WhereOwner=' ';
ELSE SET @WhereOwner=CONCAT(" AND Owner='",@Owner,"'"); END IF;

SET @Month_Report=@Month;
IF @Month='CM' THEN SET @Month_Report=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month_Report=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@Currency); END IF;

-- ----------------------------------------------------
-- TRATAMIENTO DE TOTALES Y ORDER----------------------
-- ----------------------------------------------------
SET @OrderByClause='';          -- Variable a aplicar

IF @Total='YES' THEN
   IF  @TotLine='LAST' THEN SET @OrderByClauseEnd=' ORDER BY Date DESC,'; 
   ELSE                     SET @OrderByClauseEnd=' ORDER BY Date,';   
   END IF;
ELSE                        SET @OrderByClauseEnd=' ORDER BY ';  
END IF;

IF  @OrderBy="CPA"        THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'convert(`Total`,unsigned) ',@Order);     END IF;
-- IF  @OrderBy="PROFIT"     THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`Profit` ',@Order);    END IF;
-- IF  @OrderBy="CPAVALUE"   THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`CPA_Value` ',@Order); END IF;
-- IF  @OrderBy="ADVERTISER" THEN SET @OrderByClauseEnd=CONCAT(@OrderByClauseEnd,'`Brand` ',@Order);     END IF;
   
/**************************************************************************************************************/

-- --------------------------------------------------------------------------------------------

-- En views de Afiliado impide pedir @Affiliate_id="ALL"
IF  @Affiliate_id="ALL" AND @View='VIEWAFF'  THEN  
    Select 'Affiliate_id mandatory in ViewAFF' from dual;
    LEAVE proc_label;
END IF; 
   
   
IF @View='VIEWGES' THEN
   IF   @MasterAffGroup=4 THEN
        SET @DataTable=" Snapshot_day_by_day_fact2 ";
   ELSE SET @DataTable=" Snapshot_day_by_day_fact1 ";
   END IF;
ELSE  -- @View='VIEWGES'
   IF   @AffiliateGroup=6 THEN
        SET @DataTable=" sub_Snapshot_day_by_day_fact3 ";
   ELSE SET @DataTable=" Snapshot_day_by_day_fact2 ";
   END IF;
END IF;   

IF @Affiliate_id="ALL" THEN 
     SET @WhereAffiliate_id=' ';
ELSE SET @WhereAffiliate_id=CONCAT(' AND Affiliate_id=',@Affiliate_id); 
END IF;
-- ----------------------------------------------------
IF @ByDay='YES' THEN SET @Group_by=' GROUP BY Date ';
ELSE SET @Group_by=' GROUP BY LEFT(Date,7),Affiliate ';
END IF;

SET @Order_by=' ORDER BY Date ';
-- ----------------------------------------------------
SET @FlagAll=if(@Affiliate_id="ALL","1","0");
-- ----------------------------------------------------

/******************************************************************************/
SET SESSION group_concat_max_len = 200000;

-- ----------------------------------------------------   
-- Check si hay CPAs en la selección para que haya al menos una columna Brand

SET @SQLCheck_CPA=CONCAT('
    SET @Check_CPA=(SELECT COUNT(DISTINCT Brand) FROM ',@DataTable,' 
    WHERE LEFT(DATE,7)=','"',@Month_Report,'" ',@WhereAffiliate_id,@WhereAffiliate_list,'
    AND Qualified_Players<>0);'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLCheck_CPA;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;                           

IF @Debug!="NO" THEN SELECT @SQLCheck_CPA,@Check_CPA; END IF;

IF ifnull(@Check_CPA,0)=0 THEN      
    Select 'Not enough data to show' from dual;
    LEAVE proc_label;
END IF; 

-- ----------------------------------------------------------------------------------------------------------
-- Check si hay CPAs en la selección para que haya al menos una columna Brand

-- SET @Check_CPA=(select count(distinct Brand) from Snapshot_day_by_day_fact1
--       where LEFT(DATE,7)=@Month_Report
--       AND Qualified_Players<>0
--       AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll));
-- 
-- IF @Check_CPA=0 THEN      
--     Select 'Not enough data to show' from dual;
--     LEAVE proc_label;
-- END IF; 
-- ----------------------------------------------------------------------------------------------------------

SET @SQLmat=CONCAT('
    SET @SQLwrkMatrix=(
    SELECT GROUP_CONCAT(CONCAT("\r\nSUM(CASE WHEN Brand=\'", Brand,"\' THEN `Qualified_Players` ELSE 0 END) AS \'"
   ,REGEXP_REPLACE(Brand,"([A-Z]+)"," $1",4,0,"c"),"\'") ORDER BY Brand)
    FROM (
       SELECT DISTINCT `Brand` FROM ',@DataTable,' 
       WHERE LEFT(DATE,7)=','"',@Month_Report,'" ',@WhereAffiliate_id,@WhereAffiliate_list,'
       AND Qualified_Players<>0
    ) AS xx);'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLmat;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;  

-- ---------------------------------------------------------------------------------------------------------
-- SET @SQLwrkMatrix=
--    (SELECT GROUP_CONCAT(CONCAT("\r\nSUM(CASE WHEN Brand='", Brand,"' THEN `Qualified_Players` ELSE 0 END) AS '"
--    ,REGEXP_REPLACE(Brand,"([A-Z]+)"," $1",4,0,"c"),"'") ORDER BY Brand)
--    FROM (select distinct Brand from Snapshot_day_by_day_fact1
--       where LEFT(DATE,7)=@Month_Report
--       AND Qualified_Players<>0
--       AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll)
--    ) AS xx);
--
-- ----------------------------------------------------------------------------------------------------------
   
SET @SQLmet=CONCAT('
    SET @SQLwrkMatrixMeta=
    (SELECT GROUP_CONCAT("\'width=100px,center=true\'")
    FROM (
       SELECT DISTINCT Brand FROM ',@DataTable,' 
       WHERE LEFT(DATE,7)=','"',@Month_Report,'" ',@WhereAffiliate_id,@WhereAffiliate_list,'
       AND Qualified_Players<>0
    ) AS xx);'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLmet;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;  

-- ----------------------------------------------------------------------------------------------------------

-- SET @SQLwrkMatrixMeta=
--    (SELECT GROUP_CONCAT("'width=100px,center=true'")
--    FROM (select distinct Brand from Snapshot_day_by_day_fact1
--       where LEFT(DATE,7)=@Month_Report
--       AND Qualified_Players<>0
--       AND (Affiliate_id=@Affiliate_id OR 1=@FlagAll)
--    ) AS xx);
--
-- IF @Debug!="YES" THEN SELECT @SQLwrkMatrixMeta; END IF;   
 
SET @SQLmeta=concat(
'( 
SELECT  
   "setting"
   ,"omit=true" as Owner
   ,"width=100px" as Date
   ,IF(@View="VIEWGES","width=150px","omit=true") as Affiliate
   ,"width=100px,center=true" as Total,'
   ,@SQLwrkMatrixMeta,
   ',"width=100px,omit=true" as Total1
	FROM DUAL WHERE @Meta="YES")'
);

-- 
IF @Debug!="NO" THEN SELECT @Debug,@View,@Month_Report,@Affiliate_id,@SQLwrkAffiliate_id,@SQLwrkAllAff; END IF;
IF @Debug!="NO" THEN SELECT @SQLCheck_CPA,@Check_CPA,@SQLmat,@SQLwrkMatrix,@SQLmet,@SQLwrkMatrixMeta; END IF;
--

SET @SQLwrkTotal=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'total' as `Meta`,",""),'
    Owner,LEFT(DATE,7) as `Date`," ~~TOTAL~~" as`Affiliate`
   ,SUM(Qualified_Players) AS `Total`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(Qualified_Players) AS `Total1` \r\n
    FROM ',@DataTable,'WHERE LEFT(DATE,7)="',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAffiliate_list,'\r\n)'
   );
   
SET @SQLwrkDetail=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'data' as `Meta`,",""),'
    Owner
   ,IF("',@ByDay,'"="YES",Date,LEFT(Date,7)) as `Date`
   ,IF("',@Affiliate_id,'"="ALL",if("',@ByDay,'"="YES","ALL",Affiliate),Affiliate) as`Affiliate`
   ,SUM(Qualified_Players) AS `Total`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(Qualified_Players) AS `Total1` \r\n 
    FROM ',@DataTable
   ,'WHERE LEFT(DATE,7)="',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAffiliate_list,'\r\n'
   ,@Group_by,' HAVING SUM(Qualified_Players)<>0
   )');
   
IF @Debug!="NO" THEN SELECT @SQLwrkMatrix,@SQLwrkDetail,@SQLwrkTotal; END IF;   
   
   SET @SQL = CONCAT(
    if(@Total='YES' AND @TotLine='FIRST',@SQLwrkTotal,'')
   ,if(@Total='YES' AND @TotLine='FIRST',' UNION ALL ','')  
   ,@SQLwrkDetail
   ,if(@Total='YES' AND @TotLine!='FIRST',' UNION ALL ','')    
   ,if(@Total='YES' AND @TotLine!='FIRST',@SQLwrkTotal,'')
   ,IF(@Meta='YES',' UNION ALL ','')
   ,IF(@Meta='YES',@SQLmeta,'')
   ,@OrderByClauseEnd
   ,';');

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
-- IF  @AffiliateGroup=6 THEN
--  SET @SQL=REPLACE(@SQL,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
--  SET @SQL=REPLACE(@SQL,"campaign_marketing_source","sub_campaign_marketing_source");
--  SET @SQL=REPLACE(@SQL,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
--  SET @SQL=REPLACE(@SQL,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
--  SET @SQL=REPLACE(@SQL,"account_landing_pages","sub_account_landing_pages");
--  SET @SQL=REPLACE(@SQL,"account_payment_methods","sub_account_payment_methods");
--  SET @SQL=REPLACE(@SQL,"account_account_bills","sub_account_account_bills");
--  SET @SQL=REPLACE(@SQL,"view_monthly_fact_aff4","sub_view_monthly_fact_aff4");
-- END IF;
/*---------------------------------------------------------------------------------*/
   
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN 
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;   
END IF;

END$$
DELIMITER ;

/*
call CPA_ByAFFILIATE_BrandMatrix(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call CPA_ByAFFILIATE_BrandMatrix('View=VIEWGES');
call CPA_ByAFFILIATE_BrandMatrix('View=VIEWGES,Month=CM,OrderBy=CPA,meta=yes,debug=non');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=39,Month=LM,debug=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=ALL,Month=LM,ByDay=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=LM,meta=yes');
call CPA_ByAFFILIATE_BrandMatrix('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999

call CPA_ByAFFILIATE_BrandMatrix('View=ViewAFF,Affiliate_id=39,ByDay=yes,meta=yes,debug=ye');

call CPA_ByAFFILIATE_BrandMatrix('View=ViewGES,Owner=2,Month=LM');

-- MAF/sub
call CPA_ByAFFILIATE_BrandMatrix_test('View=ViewGES,Month=LM,MasterAff_id=440,Affiliate_id=ALL,debug=ye');
call CPA_ByAFFILIATE_BrandMatrix_test('View=ViewGES,Month=LM,MasterAff_id=440,Affiliate_id=723,debug=ye');
call CPA_ByAFFILIATE_BrandMatrix_test('View=ViewAFF,Month=LM,Affiliate_id=829,debug=ye');

*/