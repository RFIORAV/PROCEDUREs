/*
PROCEDURE_Aff_MarketingSources_v2.sql - Reporte multimodo de las MS de un mes

Descripción:
  Procedimiento Aff_MarketingSources.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.
 
Affiliate_id    =[ALL | id del Affiliate]. OBLIGATORIO.
MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Area            =[ALL | gaming / forex]. OPCIONAL. Default=ALL
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month.
Brand           =[ALL | Name del Brand]. OPCIONAL. Default=ALL
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
Product         =[ALL | Product]. Producto según Publisher. OPCIONAL. Default=ALL
ProductMS       =[ALL | Product]. Producto original de la MS. OPCIONAL. Default=ALL
GroupByMS       =[Yes | No]. Agrupa Product by MS. OPCIONAL. Default=No
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. [No] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Keys no utilizadas:
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | id del Publisher]. OPCIONAL. Default=ALL
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Account         =[ALL | nombre del Adv_Account. OPCIONAL. Default=ALL
Platform        =[ALL | Platform]. OPCIONAL. Default=ALL
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
OnlyOverCap     =[Yes | No]. Solo muestra los que exceden el CPA_Limit. Default=No (fuerza GroupByMS=yes)
Total           =[Yes | No]. Incluye línea/s de Totales. OPCIONAL. Default=Yes
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Brand_Group     =[ALL | Brand_Group]. OPCIONAL. Default=ALL
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
View            =[viewAFF | viewGES]. Info de Fact2 (viewAFF) o de Fact1 (viewGES). OPCIONAL. Default=viewAFF
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Gestor_MonthlySources(''); -- Todos los valores de selección por default
call Gestor_MonthlySources('meta=yes'); -- Todos los valores de selección por default usando _fact2
call Gestor_MonthlySources('meta=yes,search=1587,debug=ye'); 
call Gestor_MonthlySources('meta=yes,ms_id=1587,debug=ye'); 
call Gestor_MonthlySources('Month=2022-10,meta=no,OnlyOverCap=yes,debug=no'); 
call Gestor_MonthlySources('Filters=yes,meta=yes,debug=no'); -- Filtros current month
call Gestor_MonthlySources('Month=2022-10,Filters=no,search=yuh,debug=ye');
call Gestor_MonthlySources('Month=2022-10,search=80');
call Gestor_MonthlySources('Account_id=102,Product=Sports!-!Exchange,Filters=yes,GroupByMS=no,debug=no,meta=yes');

12.06.2023 v2  Adaptado de PROCEDURE_Gestor_MonthlySources_v2.7.6
*/
 
DROP PROCEDURE IF EXISTS Aff_MarketingSources;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Aff_MarketingSources`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Aff_MarketingSources'
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v2 12.06.2023';
SET @Month           =left(curdate(),7);
SET @MS_id           ='ALL';
SET @Area            ='ALL';
SET @Brand           ='ALL';
SET @Affiliate_id    ='ALL';
SET @Channel_id      ='ALL';
SET @Product         ='ALL';
SET @ProductMS       ='ALL';
SET @Currency        ='EUR';
SET @Filters         ='NO';
SET @Meta            ='YES';
SET @Debug           ='NO';
SET @GroupByMS       ='NO';
SET @OnlyOverCap     ='NO';

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
   IF lower(@k)='owner'           THEN SET @Owner         =UPPER(@v); END IF;
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

IF @Area           !="ALL"   THEN SET @WhereArea            =CONCAT(" AND D.Area='",@Area,"'");                            END IF;   
IF @Brand          !="ALL"   THEN SET @WhereBrand           =CONCAT(" AND IFNULL(D.Brand        ,'')='",@Brand,"'");       END IF;
IF @Affiliate_id   !="ALL"   THEN SET @WhereAffiliate_id    =CONCAT(" AND IFNULL(D.Affiliate_id ,'')=",@Affiliate_id  );   END IF;
IF @Channel_id     !="ALL"   THEN SET @WhereChannel_id      =CONCAT(" AND IFNULL(D.Channel_id	 ,'')=",@Channel_id);      END IF;
IF @Product        !="ALL"   THEN SET @WhereProduct         =CONCAT(" AND IFNULL(D.Product      ,'')='",@Product,"'");  	END IF;
IF @ProductMS      !="ALL"   THEN SET @WhereProductMS       =CONCAT(" AND IFNULL(M.Product      ,'')='",@ProductMS,"'");  	END IF;

IF @OnlyOverCap ="YES" 
THEN SET @WhereOnlyOverCap   =CONCAT(" AND (CPA_Limit>0 AND CPA/CPA_Limit>0.8)");
     SET @GroupByMS="YES";                                -- fuerza agrupación por ms para ver OverCap
ELSE SET @WhereOnlyOverCap   =' ';  END IF;

IF @GroupByMS="YES" AND @Product="ALL"
THEN SET @GroupBySeleccBase='';
ELSE SET @GroupBySeleccBase=' ,ifnull(D.Product,"") ';  END IF;

IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@Currency); END IF;

IF @Debug!="NO" THEN SELECT @OnlyOverCap,@GroupByMS,@Product,@GroupBySeleccBase,@View,@WhereOnlyOverCap,@Search,@MS_id; END IF;
IF @Debug!="NO" THEN SELECT @WhereMS_id,@WhereArea,@WhereOwner,@WhereBrand,@WhereAffiliate_id,@WhereAdv_Account_id,@WherePublisher_id
                           ,@WhereAdv_Account,@WhereChannel_id,@WhereProduct,@WherePlatform,@WhereBrand_Group,@WhereSearch; END IF;

/**************************************************************************************************************/
SET @SQLmeta=concat(
'SELECT
   "setting" as Meta
   ,"width=100px,omit=true"                                as `Month`
   ,if(@Brand="ALL","width=120px","width=120px,omit=true") as `Brand`
   ,"width=100px"             as Cod2Aff
   ,"width=100px"             as MS_Status
   ,"width=100px,center=true" as Cap
   ,"width=130px"             as Tracker_ID
   ,"width=80px,right=true"      cpa
   ,"width=90px,right=true"      Af_sum_CPA
   ,"width=150px,tooltip=yes"    Channel
-- ,`FTD`,`Views`,`Clicks`,`Signups`,`Impr`,`Deposits`,`DepCust`,`ActCust`
   ,"width=90px,right=true","width=90px,right=true","width=90px,right=true","width=90px,right=true"
   ,"width=90px,right=true","width=110px,right=true","width=90px,right=true","width=90px,right=true"
	FROM DUAL WHERE @Meta="YES")'
);
-- IF @Debug!="NO" THEN SELECT @SQLmeta; END IF;
/**************************************************************************************************************/

SET SESSION group_concat_max_len = 200000;

/*

*/

SET @SQL=concat('
WITH Seleccion_base as (
SELECT LEFT(D.Date,7)            as `Month`
   ,D.Brand                      as `Brand`
   ,M.Status                     AS `Status`
   ,M.Code_To_Affiliate          as `Tracker_ID`
   ,lower(M.Product)             as `Product`
	,D.Channel,D.CPA_Limit
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

FROM Snapshot_day_by_day_fact2 D
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`id` = D.`MS_id` AND D.MS_id is not null
LEFT JOIN campaign_publisher            P ON P.id=D.Publisher_id
WHERE LEFT(DATE,7)="',@Month,'" '
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
GROUP BY LEFT(Date,7),D.Area,D.Publisher_id,D.Brand,D.Username,ifnull(MS_id,0),D.Tracker_ID,D.Tracker_Name',@GroupBySeleccBase,'
ORDER BY LEFT(Date,7),D.Area,P.Advertiser_Name,D.Brand,MS_id
)',
@SQLmeta,
'
UNION ALL
(
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
   Date,Area,Owner,Publisher,Platform,Brand,Account,Affiliate
   ,MS_id
   ,MS_Status AS Status
   ,CASE CPA_Limit>0
         WHEN CPA/CPA_Limit>=0.8 THEN concat(CPA_Limit,"/",ROUND(CPA/CPA_Limit*100,0),"%")
         ELSE "" END  as `Cap/Used`
   ,Tracker_ID,Product,ProductMS as `Product MS`
   ,CPA,NetRev
   ,Ge_sum_CPA   `Ge_CPA Total`
   ,Ge_sum_RS    `Ge_RS Total`
   ,Af_sum_CPA   `Af_CPA Total`
   ,Af_sum_RS    `Af_RS Total`
   ,Ge_CPA       `Ge_CPA Deal`
   ,Ge_RS        `Ge_RS Deal`
   ,Af_CPA       `Af_CPA Deal`
   ,Af_RS        `Af_RS Deal`
   ,Channel,Tracker_Name,Cod2Aff
   ,`FTD`,`Views`,`Clicks`,`Signups`,`Impr`,`Deposits`,`DepCust`,`ActCust`
FROM Seleccion_base where 1=1',@WhereOnlyOverCap,'
)
UNION ALL
(
SELECT
--  Date,Owner,Publisher,Platform,Advertiser,Account,Affiliate
  ',IF(@Meta="YES","'total' as `Meta`,",""),'
   " ~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~TOTALS~~~~~"
   ,"~~~~~"
-- ,MS_id,Tracker_ID,Product
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,SUM(CPA),sum(NetRev)
   ,SUM(Ge_sum_CPA)
   ,SUM(Ge_sum_RS )
   ,SUM(Af_sum_CPA)
   ,SUM(Af_sum_RS )
-- ,Af_CPA,Af_RS
   ,"~~~~~"
   ,"~~~~~"
-- ,Ge_CPA,Ge_RS
   ,"~~~~~","~~~~~"
-- ,Channel,Tracker_Name,Cod2Aff
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,sum(`FTD`) as FTD,sum(`Views`) as Views,sum(`Clicks`) as Clicks,sum(`Signups`) as Signups
   ,sum(`Impr`) as Impr,sum(`Deposits`) as Deposits,sum(`DepCust`) as DepCust,sum(`ActCust`) as ActCust
FROM Seleccion_base
WHERE @Total="YES"'
,@WhereOnlyOverCap,'
-- GROUP BY Date
)'
,IF(@Meta="YES",@SQLmeta,""),'
ORDER BY Date',@PositionTotLine,',convert(`CPA`,signed) DESC;');

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
where LEFT(DATE,7)="',@MONTH,'" '
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
GROUP BY LEFT(Date,7),ifnull(D.Owner,""),ifnull(D.Publisher_id,""),ifnull(Platform,""),ifnull(D.Brand,"")
,ifnull(D.Username,""),ifnull(MS_id,0),ifnull(D.Tracker_ID,""),ifnull(D.Tracker_Name,"")',@GroupBySeleccBase,
',ifnull(D.Affiliate,""),ifnull(D.CHANNEL,"")   
)
-- SELECT LEFT(DATE,7) AS month_year FROM MonthFilter ORDER BY DATE desc;

(SELECT "01" as "Korder","Date" AS "Key",LEFT(`Date`,7) AS "Value"
                                       ,"Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`
                                                                         ,"" AS "Rows" FROM MonthFilter) UNION ALL
(SELECT "02","Option"     ,"Group by MS","GroupByMS"    ,"yes"           ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "03","Area"       ,`Area`       ,"Area"         ,`Area`          ,"" AS K       FROM BaseCount WHERE @Kforex>0 AND `Area`>" " GROUP BY IFNULL(`Area`,"")) UNION ALL
(SELECT "09","Publisher"  ,`Publisher`  ,"Publisher_id" ,`Publisher_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Publisher`  >" " GROUP BY IFNULL(`Publisher`  ,"")) UNION ALL
(SELECT "13","Brand" 	  ,`Brand` 	    ,"Brand"        ,`Brand`         ,COUNT(*) AS K FROM BaseCount WHERE `Brand` >" "      GROUP BY IFNULL(`Brand` ,""))      UNION ALL
(SELECT "16","Account"    ,`Account`    ,"Account_id"   ,`Username_id`   ,COUNT(*) AS K FROM BaseCount WHERE `Account`    >" " GROUP BY IFNULL(`Account`    ,"")) UNION ALL
(SELECT "19","Affiliate"  ,`Affiliate`  ,"Affiliate_id" ,`Affiliate_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Affiliate`  >" " GROUP BY IFNULL(`Affiliate`  ,"")) UNION ALL
(SELECT "20","Channel"    ,`Channel`    ,"Channel_id"   ,`Channel_id`    ,COUNT(*) AS K FROM BaseCount WHERE `Channel`    >" " GROUP BY IFNULL(`Channel`    ,"")) UNION ALL
(SELECT "22","ProductMS"  ,`ProductMS`  ,"ProductMS"    ,`ProductMS`     ,COUNT(*) AS K FROM BaseCount WHERE `ProductMS`  >" " GROUP BY IFNULL(`ProductMS`  ,"")) UNION ALL
(SELECT "23","Product"    ,`Product`    ,"Product"      ,`Product`       ,COUNT(*) AS K FROM BaseCount WHERE `Product`    >" " GROUP BY IFNULL(`Product`    ,"")) UNION ALL
(SELECT "28","Platform"   ,`Platform`   ,"Platform"     ,`Platform`      ,COUNT(*) AS K FROM BaseCount WHERE `Platform`   >" " GROUP BY IFNULL(`Platform`   ,"")) UNION ALL
(SELECT "30","Owner"      ,`Owner`      ,"Owner"        ,`Owner`         ,COUNT(*) AS K FROM BaseCount WHERE `Owner`      >" " GROUP BY IFNULL(`Owner`      ,""))
-- ORDER BY 1,3
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
call Aff_MarketingSources(''); -- Todos los valores de selección por default
call Aff_MarketingSources('meta=yes'); -- Todos los valores de selección por default usando _fact2
call Aff_MarketingSources('meta=yes,search=1587,debug=ye'); 
call Aff_MarketingSources('meta=yes,ms_id=1587,debug=ye'); 
call Aff_MarketingSources('Month=2023-01,meta=no,OnlyOverCap=NO,debug=noN'); 
call Aff_MarketingSources('Month=2023-01,Filters=ye,meta=yes,debug=ye');
call Aff_MarketingSources('Month=2022-10,Filters=no,search=yuh,debug=ye');
call Aff_MarketingSources('Month=2022-10,search=80');
 
call Aff_MarketingSources('Account_id=102,Product=Sports!-!Exchange,Filters=yes,GroupByMS=no,debug=no,meta=yes');
call Aff_MarketingSources('Account_id=102,Product=Sports - Exchange,Filters=yes,GroupByMS=no,debug=no,meta=yes');

call Aff_MarketingSources('Account_id=102,Filters=no,GroupByMS=yes,debug=no');

call Aff_MarketingSources('Filters=yes,meta=yes,debug=yes,Username=GamingAffiliation');
call Aff_MarketingSources('Filters=yes,Month=2023-01,meta=yes,debug=yes');
call Aff_MarketingSources('Filters=yes,Month=2023-01,meta=yes,debug=ye');
call Aff_MarketingSources('Month=2023-01,filters=ye,Advertiser_id=52,Account_id=107,debug=noN'); 

call Aff_MarketingSources('Filters=ye,meta=yes,debug=ye');
*/
