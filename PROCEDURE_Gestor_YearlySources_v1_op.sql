/*
PROCEDURE_Gestor_YearlySources.sql - Reporte multimodo de las MS de un año

Descripción:
  Procedimiento Gestor_YearlySources.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.
 
Data            =[CPA | NR | CPA_Val | RS_Val | CPA_Val_Aff | RS_Val_Aff]. OPCIONAL. Default=CPA.
Affiliate_id    =[ALL | id del Affiliate]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | id del Publisher]. OPCIONAL. Default=ALL
Brand           =[ALL | Name del Brand]. OPCIONAL. Default=ALL
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
ProductMS       =[ALL | Product]. Producto original de la MS. OPCIONAL. Default=ALL
GroupByMS       =[Yes | No]. Agrupa Product by MS. OPCIONAL. Default=No
Total           =[Yes | No]. Incluye línea/s de Totales. OPCIONAL. Default=Yes
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Meta            =[No | Yes]. [No] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Search          =[(dato a buscar]. OPCIONAL. Busca string en Tracker_ID/Tracker_Name/Code_To_Affiliate/MS_id
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Keys no utilizadas:
MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Product         =[ALL | Product]. Producto según Publisher. OPCIONAL. Default=ALL
Platform        =[ALL | Platform]. OPCIONAL. Default=ALL
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
OnlyOverCap     =[Yes | No]. Solo muestra los que exceden el CPA_Limit. Default=No (fuerza GroupByMS=yes)
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Account         =[ALL | nombre del Adv_Account. OPCIONAL. Default=ALL
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Area            =[ALL | gaming / forex]. OPCIONAL. Default=ALL
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month.
Brand_Group     =[ALL | Brand_Group]. OPCIONAL. Default=ALL
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
View            =[viewAFF | viewGES]. Info de Fact2 (viewAFF) o de Fact1 (viewGES). OPCIONAL. Default=viewAFF
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Gestor_YearlySources(''); -- Todos los valores de selección por default
call Gestor_YearlySources('meta=yes'); -- Todos los valores de selección por default usando _fact2

05.09.2023 V1     Primera versión operativa. Base: PROCEDURE_Gestor_MonthlySources_v2.7.7.sql
10.04.2026 v1.1   Meta: etiqueta de columna Publisher -> Operator en fila setting
10.04.2026 v1.2   Filtros: clave visible Publisher -> Operator

*/
 
DROP PROCEDURE IF EXISTS Gestor_YearlySources;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Gestor_YearlySources`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Gestor_YearlySources'
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.2 10.04.2026';
SET @Month           =left(curdate(),7);
SET @Data            ='CPA';
SET @MS_id           ='ALL';
SET @Area            ='ALL';
SET @Owner           ='ALL';
SET @Brand           ='ALL';
SET @Affiliate_id    ='ALL';
SET @Account_id      ='ALL';
SET @Account         ='ALL';
SET @Channel_id      ='ALL';
SET @Product         ='ALL';
SET @ProductMS       ='ALL';
SET @Platform        ='ALL';
SET @Brand_Group     ='ALL';
SET @Publisher_id    ='ALL';
SET @Currency        ='EUR';
SET @Total           ='YES';
SET @Filters         ='NO';
SET @TotLine         ='FIRST';
SET @Meta            ='YES';
SET @Debug           ='NO';
SET @View            ='VIEWGES';
SET @GroupByMS       ='yes';
SET @OnlyOverCap     ='NO';
SET @Search          ='';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
--  @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- @InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);  
   
   IF lower(@k)='month'           THEN SET @Month         =UPPER(@v); END IF;
   IF lower(@k)='ms_id'           THEN SET @MS_id         =UPPER(@v); END IF;
   IF lower(@k)='area'            THEN SET @Area          =lower(@v); END IF;
   IF lower(@k)='data'            THEN SET @Data          =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id'   THEN SET @Advertiser_id =UPPER(@v); END IF;
   IF lower(@k)='brand'           THEN SET @Brand         =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
   IF lower(@k)='account_id'      THEN SET @Account_id    =UPPER(@v); END IF;
   IF lower(@k)='Publisher_id'    THEN SET @Publisher_id  =UPPER(@v); END IF;
   IF lower(@k)='account'         THEN SET @Account       =UPPER(@v); END IF;
   IF lower(@k)='channel_id'      THEN SET @Channel_id    =UPPER(@v); END IF;
   IF lower(@k)='currency'        THEN SET @Currency      =UPPER(@v); END IF;
   IF lower(@k)='total'           THEN SET @Total         =UPPER(@v); END IF;
   IF lower(@k)='totline'         THEN SET @TotLine       =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='view'            THEN SET @View          =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='groupbyms'       THEN SET @GroupByMS     =UPPER(@v); END IF;
   IF lower(@k)='onlyovercap'     THEN SET @OnlyOverCap   =UPPER(@v); END IF;
   IF lower(@k)='product'         THEN SET @Product       =      @v;  END IF;
   IF lower(@k)='productms'       THEN SET @ProductMS     =      @v;  END IF;
   IF lower(@k)='platform'        THEN SET @Platform      =      @v;  END IF;
   IF lower(@k)='brand_group'     THEN SET @Brand_Group   =      @v;  END IF;
   IF lower(@k)='search'          THEN SET @Search        =     (@v); END IF;

END WHILE;

-- Recupera espacios reemplazados en front end por caracter "!"
IF @Product       !="ALL" THEN SET @Product      =replace(@Product,"!"," ");     END IF;
IF @Brand         !="ALL" THEN SET @Brand        =replace(@Brand,"!"," ");       END IF;
IF @Account       !="ALL" THEN SET @Account      =replace(@Account,"!"," ");     END IF;

-- Check month para caso 2023-1 en lugar de 2023-01
IF CHAR_LENGTH(@Month)=6 THEN SET @Month=CONCAT(LEFT(@Month,5),'0',RIGHT(@Month,1)); END IF;

IF @Debug!="NO" THEN SELECT @Month,@View,@Filters,@OWNER,@OnlyOverCap,@Brand_Group,@Publisher_id
                           ,@Brand,@Affiliate_id,@Account_id,@Account,@Channel_id,@Product
                           ,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;                                       

SET @WhereMS_id='';
SET @WhereOwner='';    
SET @WhereArea='';     
SET @WhereBrand ='';
SET @WherePublisher_id  ='';
SET @WhereAffiliate_id  ='';
SET @WhereAdv_Account_id='';
SET @WhereAdv_Account   ='';
SET @WhereChannel_id    ='';
SET @WhereStatus        ='';
SET @WhereProduct       ='';
SET @WhereProductMS     ='';
SET @WherePlatform      ='';
SET @WhereBrand_Group   ='';
SET @WhereSearch        ='';

IF @MS_id             !="ALL" THEN SET @WhereMS_id=CONCAT(" AND D.MS_id=",@MS_id);     
ELSE                  
   IF @Owner          !="ALL"   THEN SET @WhereOwner           =CONCAT(" AND D.Owner=",@Owner);                               END IF;
   IF @Area           !="ALL"   THEN SET @WhereArea            =CONCAT(" AND D.Area='",@Area,"'");                            END IF;   
   IF @Brand          !="ALL"   THEN SET @WhereBrand           =CONCAT(" AND IFNULL(D.Brand        ,'')='",@Brand,"'");       END IF;
   IF @Affiliate_id   !="ALL"   THEN SET @WhereAffiliate_id    =CONCAT(" AND IFNULL(D.Affiliate_id ,'')=",@Affiliate_id  );   END IF;
   IF @Account_id     !="ALL"   THEN SET @WhereAdv_Account_id  =CONCAT(" AND IFNULL(D.Username_id  ,'')=",@Account_id);       END IF;
   IF @Account        !="ALL"   THEN SET @WhereAdv_Account     =CONCAT(" AND IFNULL(D.Username     ,'')='",@Account,"'");     END IF;
   IF @Channel_id     !="ALL"   THEN SET @WhereChannel_id      =CONCAT(" AND IFNULL(D.Channel_id	 ,'')=",@Channel_id);      END IF;
   IF @Product        !="ALL"   THEN SET @WhereProduct         =CONCAT(" AND IFNULL(D.Product      ,'')='",@Product,"'");  	END IF;
   IF @ProductMS      !="ALL"   THEN SET @WhereProductMS       =CONCAT(" AND IFNULL(M.Product      ,'')='",@ProductMS,"'");  	END IF;
   IF @Platform       !="ALL"   THEN SET @WherePlatform        =CONCAT(" AND IFNULL(D.Portal     	 ,'')='",@Platform,"'"); 	END IF;
   IF @Publisher_id   !="ALL"   THEN SET @WherePublisher_id    =CONCAT(" AND IFNULL(D.Publisher_id  ,'')=",@Publisher_id);    END IF;
   IF @Brand_Group    !="ALL"   THEN SET @WhereBrand_Group     =CONCAT(" AND IFNULL(D.Brand_Group  ,'')='",@Brand_Group,"'"); END IF;
   IF @Search         !=""      THEN SET @WhereSearch          =@SearchClause; END IF;
END IF;

IF @OnlyOverCap ="YES" 
THEN SET @WhereOnlyOverCap   =CONCAT(" AND (CPA_Limit>0 AND CPA/CPA_Limit>0.8)");
     SET @GroupByMS="YES";                                -- fuerza agrupación por ms para ver OverCap
ELSE SET @WhereOnlyOverCap   =' ';  END IF;

IF @GroupByMS="YES" AND @Product="ALL"
THEN SET @GroupBySeleccBase='';
ELSE SET @GroupBySeleccBase=' ,ifnull(D.Product,"") ';  END IF;

IF @TotLine="FIRST" THEN SET @PositionTotLine=" Asc"; ELSE SET @PositionTotLine=" Desc"; END IF;

IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@Currency); END IF;

-- IF @View="VIEWAFF" THEN
     -- SET @FromTable='," " as Platform FROM Snapshot_day_by_day_fact2 ';
     -- SET @FilterFromTable='," " as Platform FROM Snapshot_day_by_day_fact2 ';
     -- SET @AcumGesOnly='';
     -- SET @TotGesOnly='';
     -- SET @Meta='';
-- ELSE
	  -- SET @FromTable=",Brand_Group,Portal as Platform,Deal_Ges_CPA as `Ge_CPA`,Deal_Ges_RS as `Ge_RS` FROM Snapshot_day_by_day_fact1 ";
	  -- SET @FilterFromTable=",Portal as Platform FROM Snapshot_day_by_day_fact1 ";
     -- SET @AcumGesOnly=',Ge_CPA,Ge_RS ';
     -- SET @TotGesOnly=',"~~~~~","~~~~~"';
-- END IF;

SET @MonthFrom=LEFT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH),7);

IF @Debug!="NO" THEN SELECT @OnlyOverCap,@GroupByMS,@Product,@GroupBySeleccBase,@View,@WhereOnlyOverCap,@Search,@MS_id; END IF;
IF @Debug!="NO" THEN SELECT @WhereMS_id,@WhereArea,@WhereOwner,@WhereBrand,@WhereAffiliate_id,@WhereAdv_Account_id,@WherePublisher_id
                           ,@WhereAdv_Account,@WhereChannel_id,@WhereProduct,@WherePlatform,@WhereBrand_Group,@WhereSearch; END IF;

SET @Kforex=(
   SELECT COUNT(*) FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU` ON `CU`.`id` = `M`.`Username_id`
   WHERE CU.Area="forex"
);
IF @Debug!="NO" THEN SELECT @Kforex FROM DUAL; END IF;

/**************************************************************************************************************/
SET @SQLmeta=concat(
' UNION ALL (
SELECT
   "setting" as Meta
   ,"width=100px,omit=true" as date
   -- ,if(@Area!="ALL" OR @Kforex=0,"omit=true","width=80px") as Area
   -- ,if(@Owner!="ALL","omit=true","width=80px") as Owner_id
   ,if(@Publisher_id!="ALL" OR @Account_id!="ALL" OR @Affiliate_id!="ALL","omit=true","width=110px") as Operator
   -- ,if(@Platform!="ALL" OR @Publisher_id!="ALL" OR @Account_id!="ALL" OR @Brand!="ALL" OR @Affiliate_id!="ALL","omit=true","width=100px") as Platform
   ,if(@Brand="ALL","width=120px","width=120px,omit=true") as Brand
   -- ,if(@Account_id="ALL","width=160px","width=160px,omit=true") as Account
   ,if(@Affiliate_id="ALL","width=160px","width=160px,omit=true") as Affiliate
   ,"width=090px,center=true" as MS_id
   ,"width=090px" as MS_Status
   -- ,"width=100px,center=true" as Cap
   -- ,"width=130px" as Tracker_ID
   -- ,if(@Product!="ALL" OR @GroupByMS="YES","omit=true","minWidth:100px,maxWidth=400px,width=150px") Product
   ,if(@Product!="ALL","omit=true","width=090px") ProductMS
   ,"width=150px" -- ,tooltip=yes" Channel
   ,"width=80px,right=true" cpa
   ,"width=90px,right=true" nr
   ,"width=90px,right=true" Ge_sum_CPA
   ,"width=90px,right=true" Ge_sum_RS
   ,"width=90px,right=true" `Gross profit`
   ,"width=90px,right=true" AS `@Tot00`
   ,"width=90px,right=true" AS `@Mes01`
   ,"width=90px,right=true" AS `@Mes02`
   ,"width=90px,right=true" AS `@Mes03`
   ,"width=90px,right=true" AS `@Mes04`
   ,"width=90px,right=true" AS `@Mes05`
   ,"width=90px,right=true" AS `@Mes06`
   ,"width=90px,right=true" AS `@Mes07`
   ,"width=90px,right=true" AS `@Mes08`
   ,"width=90px,right=true" AS `@Mes09`
   ,"width=90px,right=true" AS `@Mes10`
   ,"width=90px,right=true" AS `@Mes11`
   ,"width=90px,right=true" AS `@Mes12`
   ,"width=90px,right=true" Af_sum_CPA
   ,"width=90px,right=true" Af_sum_RS
   ,"width=80px,right=true" Ge_cpa
   ,"width=80px,right=true" Ge_rs
   ,if(@GroupByMS="YES","omit=true","width=80px,right=true") Af_cpa
   ,if(@GroupByMS="YES","omit=true","width=80px,right=true") Af_rs
   -- ,"width=150px" -- ,tooltip=yes" Tracker_name
   -- ,"width=100px" as Cod2Aff
-- ,`FTD`,`Views`,`Clicks`,`Signups`,`Impr`,`Deposits`,`DepCust`,`ActCust`
   -- ,"width=90px,right=true","width=90px,right=true","width=90px,right=true","width=90px,right=true"
   -- ,"width=90px,right=true","width=110px,right=true","width=90px,right=true","width=90px,right=true"
	FROM DUAL WHERE @Meta="YES")'
);
-- IF @Debug!="NO" THEN SELECT @SQLmeta; END IF;
/**************************************************************************************************************/

SET SESSION group_concat_max_len = 200000;

/**/
SET @Tot00="Total CPA";
SET @Mes01=LEFT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH),7);
SET @Mes02=LEFT(DATE_SUB(CURDATE(), INTERVAL 10 MONTH),7);
SET @Mes03=LEFT(DATE_SUB(CURDATE(), INTERVAL  9 MONTH),7);
SET @Mes04=LEFT(DATE_SUB(CURDATE(), INTERVAL  8 MONTH),7);
SET @Mes05=LEFT(DATE_SUB(CURDATE(), INTERVAL  7 MONTH),7);
SET @Mes06=LEFT(DATE_SUB(CURDATE(), INTERVAL  6 MONTH),7);
SET @Mes07=LEFT(DATE_SUB(CURDATE(), INTERVAL  5 MONTH),7);
SET @Mes08=LEFT(DATE_SUB(CURDATE(), INTERVAL  4 MONTH),7);
SET @Mes09=LEFT(DATE_SUB(CURDATE(), INTERVAL  3 MONTH),7);
SET @Mes10=LEFT(DATE_SUB(CURDATE(), INTERVAL  2 MONTH),7);
SET @Mes11=LEFT(DATE_SUB(CURDATE(), INTERVAL  1 MONTH),7);
SET @Mes12=LEFT(DATE_SUB(CURDATE(), INTERVAL  0 MONTH),7);

SET @SQLwrkMatrix=CONCAT (
   "\r\n,SUM(                                         `Qualified_Players`           ) AS `@Tot00`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes01,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes01`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes02,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes02`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes03,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes03`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes04,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes04`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes05,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes05`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes06,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes06`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes07,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes07`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes08,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes08`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes09,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes09`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes10,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes10`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes11,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes11`",
   "\r\n,SUM(CASE WHEN LEFT(DATE,7)='",@Mes12,"' THEN `Qualified_Players` ELSE 0 END) AS `@Mes12`"  
   )
;
/*
SELECT @SQLwrkMatrix;
--
SET @M0="CPA";
SET @M1="NR";
SET @M2="CPA_Val";
SET @M3="RS_Val";
SET @M4="CPA_Val_Aff";
SET @M5="RS_Val_Aff";
--
*/
-- -----------------------------------------------------------------------------------------------------------
IF @Data="CPA"             THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Total CPA")      ;   END IF;
IF @Data="NR"              THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Total NR")       ;   END IF;
IF @Data="CPA_Val"         THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Total CPA Val")  ;   END IF;
IF @Data="RS_Val"          THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Total RS Val")   ;   END IF;
IF @Data="CPA_Val_Aff"     THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Tot CPA Val Aff");   END IF;
IF @Data="RS_Val_Aff"      THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Tot RS Val Aff") ;   END IF;
IF @Data="Profit"          THEN SET @Tot00= REPLACE(@Tot00,"Total CPA","Tot Gross profit");  END IF;

IF @Data="CPA"             THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","Qualified_Players")      ;  END IF;
IF @Data="NR"              THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","Net_Revenue")            ;  END IF;
IF @Data="CPA_Val"         THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","CPA_Value_Gestor")       ;  END IF;
IF @Data="RS_Val"          THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","Revenue_Share_Gestor")   ;  END IF;
IF @Data="CPA_Val_Aff"     THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","CPA_Value_Affiliate")    ;  END IF;
IF @Data="RS_Val_Aff"      THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"Qualified_Players","Revenue_Share_Affiliate");  END IF;
IF @Data="Profit"          THEN SET @SQLwrkMatrix=REPLACE(@SQLwrkMatrix,"`Qualified_Players`","(CPA_Value_Gestor+Revenue_Share_Gestor-CPA_Value_Affiliate-Revenue_Share_Affiliate)");  END IF;
-- ------------------------------------------------------------------------------------------------------------

SET @SQL=concat('
WITH Seleccion_base as (
SELECT LEFT(D.Date,7) as Date,D.Area,D.Owner
   ,D.Brand,D.Username as Account,D.Affiliate
   ,ifnull(D.MS_id,"missing")    AS MS_id
   ,if(D.MS_id IS NULL,"unknown",M.Status) AS MS_Status
   ,lower(D.Tracker_ID)          as `Tracker_ID`
   ,lower(D.Tracker_Name)        as `Tracker_Name`
   ,D.Code_To_Affiliate          as `Cod2Aff`
   ,lower(D.Product)             as `Product`
   ,lower(M.Product)             as `ProductMS`
	,D.Channel
   ,D.CPA_Limit
   ,sum(D.Qualified_Players)     as `CPA`
   ,sum(D.Net_Revenue)           as `NetRev`
	,SUM(D.`Revenue_Share_Gestor`   ) AS `Ge_sum_RS` 
	,SUM(D.`Revenue_Share_Affiliate`) AS `Af_sum_RS`
	,SUM(D.`CPA_Value_Gestor`       ) AS `Ge_sum_CPA`    
	,SUM(D.`CPA_Value_Affiliate`    ) AS `Af_sum_CPA`    
   ,D.Deal_Aff_CPA                as `Af_CPA`
   ,D.Deal_Aff_RS                 as `Af_RS`
   ,D.Deal_Ges_CPA                as `Ge_CPA`
   ,D.Deal_Ges_RS                 as `Ge_RS` 
   ,sum(D.`First_Time_Deposit`)   as `FTD`
   ,sum(D.`Views`)                as `Views`
   ,sum(D.`Clicks`)               as `Clicks`
   ,sum(D.`Signups`)              as `Signups`
   ,sum(D.`Impressions`)          as `Impr`
   ,sum(D.`Deposits`)             as `Deposits`
   ,sum(D.`Depositing_Customers`) as `DepCust`
   ,sum(D.`Active_Customers`)     as `ActCust`
   -- ,D.Brand_Group
   ,D.Publisher_id
   ,P.Advertiser_Name             as `Publisher`
   ,D.Portal                      as `Platform`'
   ,@SQLwrkMatrix,
'
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`id` = D.`MS_id` AND D.MS_id is not null
LEFT JOIN campaign_publisher            P ON P.id=D.Publisher_id
WHERE LEFT(DATE,7)>="',@MonthFrom,'" '
   ,@WhereMS_id
   ,@WhereArea
   ,@WhereOwner
   ,@WhereBrand
   ,@WherePublisher_id
   ,@WhereAffiliate_id
   ,@WhereAdv_Account_id
   ,@WhereAdv_Account
   ,@WhereChannel_id
   ,@WhereProduct
   ,@WhereProductMS
   ,@WherePlatform
   -- ,@WhereBrand_Group
   ,@WhereSearch
   ,'
GROUP BY D.Publisher_id,D.Brand,ifnull(MS_id,0)',@GroupBySeleccBase,'
ORDER BY P.Advertiser_Name,D.Brand,D.Affiliate,MS_id
)
(
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
   Date
   -- ,Area,Owner
   ,Publisher
   -- ,Platform
   ,Brand
   -- ,Account
   ,Affiliate
   ,MS_id
   ,MS_Status AS Status
   -- ,CASE CPA_Limit>0
         -- WHEN CPA/CPA_Limit>=0.8 THEN concat(CPA_Limit,"/",ROUND(CPA/CPA_Limit*100,0),"%")
         -- ELSE "" END  as `Cap/Used`
   -- ,Tracker_ID
   -- ,Product
   ,ProductMS as `Product MS`
   ,Channel
   ,CPA
   ,NetRev
   ,Ge_sum_CPA   `Ge_CPA Total`
   ,Ge_sum_RS    `Ge_RS Total`
   ,(Ge_sum_CPA+Ge_sum_RS-Af_sum_CPA-Af_sum_RS) as `Gross profit`
   ,`@Tot00` AS "',@Tot00,'"
   ,`@Mes01` AS "',@Mes01,'"
   ,`@Mes02` AS "',@Mes02,'"
   ,`@Mes03` AS "',@Mes03,'"
   ,`@Mes04` AS "',@Mes04,'"
   ,`@Mes05` AS "',@Mes05,'"
   ,`@Mes06` AS "',@Mes06,'"
   ,`@Mes07` AS "',@Mes07,'"
   ,`@Mes08` AS "',@Mes08,'"
   ,`@Mes09` AS "',@Mes09,'"
   ,`@Mes10` AS "',@Mes10,'"
   ,`@Mes11` AS "',@Mes11,'"
   ,`@Mes12` AS "',@Mes12,'"
   ,Af_sum_CPA   `Af_CPA Total`
   ,Af_sum_RS    `Af_RS Total`
   ,Ge_CPA       `Ge_CPA Deal`
   ,Ge_RS        `Ge_RS Deal`
   ,Af_CPA       `Af_CPA Deal`
   ,Af_RS        `Af_RS Deal`
   -- ,Tracker_Name,Cod2Aff
   -- ,`FTD`
   -- ,`Views`
   -- ,`Clicks`
   -- ,`Signups`
   -- ,`Impr`
   -- ,`Deposits`
   -- ,`DepCust`
   -- ,`ActCust`
FROM Seleccion_base where 1=1',@WhereOnlyOverCap,'
)
UNION ALL
(
SELECT
--  Date,Owner,Publisher,Platform,Advertiser,Account,Affiliate
  ',IF(@Meta="YES","'total' as `Meta`,",""),'
   " ~~~~~"
   -- ,"~~~~~"
   -- ,"~~~~~"
   -- ,"~~~~~"
   -- ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~TOTALS~~~~~"
   ,"~~~~~"
-- ,MS_id,Tracker_ID,Product
   -- ,"~~~~~"
   -- ,"~~~~~"
   -- ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,SUM(CPA)
   ,sum(NetRev)
   ,SUM(Ge_sum_CPA)
   ,SUM(Ge_sum_RS )
   ,(SUM(Ge_sum_CPA)+SUM(Ge_sum_RS)-SUM(Af_sum_CPA)-SUM(Af_sum_RS )) as `Gross profit`
   ,SUM(`@Tot00`) AS `@Tot00`
   ,SUM(`@Mes01`) AS `@Mes01`
   ,SUM(`@Mes02`) AS `@Mes02`
   ,SUM(`@Mes03`) AS `@Mes03`
   ,SUM(`@Mes04`) AS `@Mes04`
   ,SUM(`@Mes05`) AS `@Mes05`
   ,SUM(`@Mes06`) AS `@Mes06`
   ,SUM(`@Mes07`) AS `@Mes07`
   ,SUM(`@Mes08`) AS `@Mes08`
   ,SUM(`@Mes09`) AS `@Mes09`
   ,SUM(`@Mes10`) AS `@Mes10`
   ,SUM(`@Mes11`) AS `@Mes11`
   ,SUM(`@Mes12`) AS `@Mes12`
   ,SUM(Af_sum_CPA)
   ,SUM(Af_sum_RS )
-- ,Af_CPA,Af_RS
   ,"~~~~~"
   ,"~~~~~"
-- ,Ge_CPA,Ge_RS
   ,"~~~~~","~~~~~"
-- ,Channel,Tracker_Name,Cod2Aff
   -- ,"~~~~~"
   -- ,"~~~~~"
   -- ,sum(`FTD`) as FTD,sum(`Views`) as Views,sum(`Clicks`) as Clicks,sum(`Signups`) as Signups
   -- ,sum(`Impr`) as Impr,sum(`Deposits`) as Deposits,sum(`DepCust`) as DepCust,sum(`ActCust`) as ActCust
FROM Seleccion_base
WHERE @Total="YES"'
,@WhereOnlyOverCap,'
-- GROUP BY Date
)'
,IF(@Meta="YES",@SQLmeta,""),'
ORDER BY Date',@PositionTotLine,',convert(`CPA`,signed) DESC;');

/* FILTERING -------------------------------------------------------*/

SET @M0="CPA"         ,@M0t="CPA"           ;
SET @M1="NR"          ,@M1t="NR"            ;
SET @M2="CPA_Val"     ,@M2t="CPA Value"     ;
SET @M3="RS_Val"      ,@M3t="RS Value"      ;
SET @M4="CPA_Val_Aff" ,@M4t="Aff CPA Value" ;
SET @M5="RS_Val_Aff"  ,@M5t="Aff RS Value"  ;
SET @M6="Profit"      ,@M6t="Gross profit"  ;


SET @SQLfilters=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
),
BaseCount AS (
SELECT LEFT(Date,7) as Date,Area,D.Owner
   ,Brand
   ,Username as Account
   ,Affiliate
   ,ifnull(MS_id,"missing") AS MS_id
	,D.Tracker_ID
	,D.Tracker_Name
	,D.Code_To_Affiliate as Cod2Aff
	,D.Channel
   ,if(@Product!="ALL" OR @GroupByMS="YES","All",D.Product) as `Product`
   ,lower(M.Product)             as `ProductMS`
   -- ,sum(Qualified_Players) as CPA,sum(Net_Revenue) as NetRev,Deal_Aff_CPA as `Af_CPA`,Deal_Aff_RS as `Af_RS`
   ,D.Username_id,D.Affiliate_id
   ,D.Advertiser_id 
   ,IFNULL(D.`Channel_id`,"") as `Channel_id`
   ,IFNULL(D.`Publisher_id`,"") as `Publisher_id`
   ,IFNULL(P.`Advertiser_Name`,"") as `Publisher`
   ,IFNULL(Portal,"") as Platform
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`id` = D.`MS_id` AND D.MS_id is not null
LEFT JOIN campaign_publisher P ON P.id=D.Publisher_id
where LEFT(DATE,7)>="',@MonthFrom,'" '
   ,@WhereMS_id
   ,@WhereArea
   ,@WhereOwner
   ,@WhereBrand
   ,@WherePublisher_id
   ,@WhereAffiliate_id
   ,@WhereAdv_Account_id
   ,@WhereAdv_Account
   ,@WhereChannel_id
   ,@WhereProduct
   ,@WhereProductMS   
   ,@WherePlatform
   -- ,@WhereBrand_Group
   ,@WhereSearch
   ,'
GROUP BY ifnull(D.Publisher_id,""),ifnull(D.Brand,""),ifnull(MS_id,0)',@GroupBySeleccBase,
',ifnull(D.Affiliate,""),ifnull(D.CHANNEL,"")   
)
-- SELECT LEFT(DATE,7) AS month_year FROM MonthFilter ORDER BY DATE desc;

(SELECT "01a" as "Korder","Data in MATRIX" AS "Key","',@M0t,'"  AS "Value","Data" AS `CallKey`,"',@M0,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01b" as "Korder","Data in MATRIX" AS "Key","',@M1t,'"  AS "Value","Data" AS `CallKey`,"',@M1,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01c" as "Korder","Data in MATRIX" AS "Key","',@M2t,'"  AS "Value","Data" AS `CallKey`,"',@M2,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01d" as "Korder","Data in MATRIX" AS "Key","',@M3t,'"  AS "Value","Data" AS `CallKey`,"',@M3,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01f" as "Korder","Data in MATRIX" AS "Key","',@M4t,'"  AS "Value","Data" AS `CallKey`,"',@M4,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01g" as "Korder","Data in MATRIX" AS "Key","',@M5t,'"  AS "Value","Data" AS `CallKey`,"',@M5,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "01e" as "Korder","Data in MATRIX" AS "Key","',@M6t,'"  AS "Value","Data" AS `CallKey`,"',@M6,'"  AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL

(SELECT "05","Brand" 	  ,`Brand` 	    ,"Brand"        ,replace(Brand," ","!")     
                                                                         ,COUNT(*) AS K FROM BaseCount WHERE `Brand` >" "      GROUP BY IFNULL(`Brand` ,""))      UNION ALL  
(SELECT "07","Affiliate"  ,`Affiliate`  ,"Affiliate_id" ,`Affiliate_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Affiliate`  >" " GROUP BY IFNULL(`Affiliate`  ,"")) UNION ALL
(SELECT "09","Operator"  ,`Publisher`  ,"Publisher_id" ,`Publisher_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Publisher`  >" " GROUP BY IFNULL(`Publisher`  ,"")) UNION ALL
(SELECT "20","Channel"    ,`Channel`    ,"Channel_id"   ,`Channel_id`    ,COUNT(*) AS K FROM BaseCount WHERE `Channel`    >" " GROUP BY IFNULL(`Channel`    ,"")) UNION ALL
(SELECT "22","ProductMS"  ,`ProductMS`  ,"ProductMS"    ,`ProductMS`     ,COUNT(*) AS K FROM BaseCount WHERE `ProductMS`  >" " GROUP BY IFNULL(`ProductMS`  ,"")) 
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3
;');

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Gestor_YearlySources(''); -- Todos los valores de selección por default
call Gestor_YearlySources('meta=yes'); -- Todos los valores de selección por default usando _fact2

call Gestor_YearlySources('Filters=yes,data=nr,meta=yes,debug=ye');
call Gestor_YearlySources('meta=yes,data=profit,debug=ye'); 
*/


