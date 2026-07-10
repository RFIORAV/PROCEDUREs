/*
PROCEDURE_Aff_Channels.sql - Report Aff_Channel_DealMS

Descripción:
  Procedimiento Aff_Channel_DealMS.
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | Affiliate_id ]. OBLIGATORIO.
Channel_id      =[ALL | Channel_id ]. OBLIGATORIO.
DateLimitView   =[Fecha AAAA-MM-DD]. OPCIONAL. Default=CURDATE()
Mode            =[String]. OPCIONAL.
Month           =[String]. OPCIONAL. Default=LEFT(CURDATE(),7)
View            =[String]. OPCIONAL.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Aff_Channel_DealMS('affiliate_id=39,channel_id=1,debug=non');
call Aff_Channel_DealMS('affiliate_id=506,channel_id=264,debug=non');

26.07.2023 V1     Karen.
19.10.2023 v1.1   RF. Descripción Deal
19.01.2024 v1.2   Muestra Status efectivo en lugar del Status MS
13.03.2024 v1.3   No muestra MS que no están activas
18.03.2024 v1.3.1 Muestra Stat_effect en MStatus en lugar de Stat_aggreg
                  DateLimitView (para omitir deals futuros. Especificado RS)
27.05.2024 v1.4   Tratamiento de Subafiliados
08.08.2024 v1.5   Obtiene descripción deal de campaign_deal_affiliate
30.08.2024 v1.6   Fix: acumula CPA en Snapshot_day_by_day_fact2 por Code_To_Affiliate en lugar de MS_id
04.09.2024 v1.7   Versión que muestra menos datos (Riccardo)
18.02.2025 v1.8   Muestra Ads
25.02.2025        Karen: Fix cambio nombre Ads_code a Ad_code
20.03.2025 v1.8.1 Fix
03.04.2025        Fix MS no salían cuando había varias con mismo Cod_to_Affiliate
17.07.2025        Fix: acumula CPA en Snapshot_day_by_day_fact2 por Code_To_Affiliate en lugar de MS_id
12.05.2026 v1.8.3 Fix: solo muestra datos de Snapshot_day_by_day_fact2 del Affiliate_id especificado

*/

DROP PROCEDURE IF EXISTS Aff_Channel_DealMS;
-- DROP PROCEDURE IF EXISTS Aff_Channel_DealMS_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Aff_Channel_DealMS`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.8.3 12.05.2026 - Report Affiliate - Deals by Channel'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.8.3 12.05.2026';

SET @Affiliate_id    ='ALL';
SET @Channel_id      ='ALL';
SET @DateLimitView   =CURDATE();
SET @Month           =LEFT(CURDATE(),7);
SET @Filters         ='NO';
SET @Meta            ='NO';
SET @Debug           ='NO';

SET @DealbyProduct   ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
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

   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
   IF lower(@k)='channel_id'      THEN SET @Channel_id    =UPPER(@v); END IF;
   IF lower(@k)='datelimitview'   THEN SET @DateLimitView =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   -- IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='mode'            THEN SET @Mode          =UPPER(@v); END IF;
   IF lower(@k)='month'           THEN SET @Month         =UPPER(@v); END IF;
   IF lower(@k)='view'            THEN SET @View          =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@datelimitview,@View,@Filters,@OWNER,@Affiliate_id,@Channel_id,@Debug,@Meta,InputCommLine; END IF;

-- Valida datos obligatorios
IF   @Affiliate_id IN ("","ALL")
 OR  @Channel_id IN ("","ALL")
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET @AffiliateGroup=(SELECT group_id FROM account_account_groups
                     WHERE account_id=@Affiliate_id AND  group_id=6);
IF  @AffiliateGroup IS NULL THEN SET @AffiliateGroup=0; END IF;
/*---------------------------------------------------------------------------------*/

SET @WhereAffiliate_id  ='';
SET @WhereChannel_id    ='';
SET @WhereStatus        ='';

SET @WhereAffiliate_id  =CONCAT(" AND M1.Affiliate_id  =",@Affiliate_id  );
SET @WhereAffiliate_idX =CONCAT(" AND D.Affiliate_id  =",@Affiliate_id  );
SET @WhereChannel_id    =CONCAT(" AND M.Channel_id	  =",@Channel_id);
SET @WhereStatus        =CONCAT(" AND M.`Stat_aggreg`='1' ");                                  -- 13.03.2024
-- IF @Mode ='AFFILIATE' THEN SET @WhereStatus  =CONCAT(" AND M.`Status_id`<>9 ");  END IF;    -- 13.03.2024

/**************************************************************************************************************/

-- SET SESSION group_concat_max_len = 200000;

IF @Debug!="NO" THEN SELECT @WhereAffiliate_id,@WhereChannel_id, @WhereStatus; END IF;


SET @CTEJoinFactX='FactX as (
	SELECT
       D.Code_To_Affiliate
      ,D.MS_id
      ,D.`Product`
      ,ROUND(SUM(IFNULL(D.`Qualified_Players`  	    ,0)),0) AS `CPA`
      ,ROUND(SUM(IFNULL(D.`First_Time_Deposit`      ,0)),0) AS `FTD`
      ,ROUND(SUM(IFNULL(D.`Views`                   ,0)),0) AS `Views`
      ,ROUND(SUM(IFNULL(D.`Clicks`                  ,0)),0) AS `Clicks`
      ,ROUND(SUM(IFNULL(D.`Signups`                 ,0)),0) AS `Signups`
      ,ROUND(SUM(IFNULL(D.`Impressions`             ,0)),0) AS `Impress`
      ,ROUND(SUM(IFNULL(D.`Deposits`                ,0)),2) AS `Deposits`
      ,ROUND(SUM(IFNULL(D.`Depositing_Customers`    ,0)),0) AS `Dep Cust`
      ,ROUND(SUM(IFNULL(D.`Active_Customers`        ,0)),0) AS `Act Cust`
      ,ROUND(SUM(IFNULL(D.`New_Depositing_Customers`,0)),0) AS `New Dep Cust`
      ,ROUND(SUM(IFNULL(D.`New_Active_Customers`    ,0)),0) AS `New Act Cust`
      ,D.`Language`                                         AS `Country`
      ,D.`Deal_Aff`
      ,D.`Deal_Aff_id`
      ,D.`Deal_Aff_Valid_From`
      ,D.`Channel_id`
      ,D.`Affiliate_id`
   FROM Snapshot_day_by_day_fact2 D
   WHERE LEFT(D.DATE,7)=LEFT(CURDATE(),7) AND D.Channel_id=@Channel_id AND D.`Affiliate_id` = @Affiliate_id
   GROUP BY D.Code_To_Affiliate -- ,D.MS_id -- ,D.Product,D.Deal_Aff_id
   ORDER BY D.Code_To_Affiliate -- ,D.MS_id
)';

IF @DealbyProduct='NO' THEN
   SET @CTEJoinFactX=REPLACE(@CTEJoinFactX,"GROUP by D.MS_id,D.Product,D.Deal_Aff_id","GROUP by D.MS_id");
END IF;

SET @Count=0;

SET @Kforex=(
   SELECT COUNT(*) FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU` ON `CU`.`id` = `M`.`Username_id`
   WHERE CU.Area="forex"
);


SET @SQLmetaAff=concat(
'(
SELECT
   "setting" as Meta
   ,"width=100px,action=2" as `Logo`
   ,"omit=true"            as MS_id
   ,"width=120px"          as Brand
	-- ,if(@Product!="ALL","omit=true","width=100px") Product
	,"omit=true"            as Product
	,"width=100px"          AS `Country`
	,"width=100px"          AS `Operative Status`  -- 19.01.2024
	,"width=120px"          AS `Code`
	,"width=250px,action=1" as Shortlink
	,"omit=true"            AS `CPA Value`
	,"omit=true"            AS `Baseline`
	,"width=090px"          AS `CPA Current`
	,"width=090px,center=true" `CPA Limit`
	,"omit=true"            as `Deal From`
	,"width=250px"          as `Deal`
   ,"omit=true"            AS Affiliate_id
   ,"omit=true"            AS Channel_id
	,"omit=true"            as Account
	,"omit=true"            as `Username_id`
	,"omit=true"            as `MS_Product`
	,"omit=true"            as `Tracklink`
	,"omit=true"            as `bid_code`
	,"omit=true"            as `MS_Ad_Code`
	,"width=250px"          as `Landing page`
	,"width=100px"          as `Landing Valid to`
	,"omit=true"            as `ad code`
	,"width=150px,action=4" as `Other LP`  -- K 25.02.2025
	,"omit=true"            as `ad_id`     -- K 26.02.2025
	FROM DUAL WHERE @Meta="YES")'
);

SET @CTE=CONCAT('WITH ',
@CTEJoinFactX,'
,
mkt_source_deal_Code_To_Affiliate as (
SELECT ms.Code_To_Affiliate,AD.Advertiser_Name,msd.*
FROM `campaign_mkt_source_deal` msd
INNER JOIN campaign_marketing_source ms ON msd.`MS_id` = ms.id and ms.Stat_aggreg in (1,4,6)  -- 03.04.2025
LEFT JOIN `campaign_username` `CU`      ON `CU`.`id` = `ms`.`Username_id`
LEFT JOIN `campaign_advertiser` `AD`    ON `AD`.`id` = `CU`.`Advertiser_id`
WHERE msd.`Affiliate_id` = @Affiliate_id
  AND msd.`is_active` = 1
  AND msd.`Deal_Valid_From` <= "',@DateLimitView,'"
  AND ms.Channel_id=@Channel_id
GROUP BY AD.Advertiser_Name,ms.Code_To_Affiliate,msd.`Product`,msd.`Deal_Valid_From`,msd.`Deal_id`,msd.`Country`
ORDER BY AD.Advertiser_Name,ms.Code_To_Affiliate,msd.`Deal_Valid_From` DESC, msd.id DESC
)
-- SELECT * FROM FactX;
-- SELECT * FROM mkt_source_deal_Code_To_Affiliate;
,
campaign_marketing_source_updated AS (
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,'...' as `Action`,",""),'
    M.`id`                       AS MS_id
   ,AD.Advertiser_Name           as `Brand`
	,(case when M1.Product is null then "any"
	 		 when M1.Product=""		 then "any"
		    else M1.Product end)   AS `Product`
	,ifnull(D1.`Country`,"")
-- ,M.`Stat_aggreg`              as `MStatus`       -- 13.03.2024
	,M.`Stat_effect`              as `MStatus`       -- 18.03.2024
	,M.`Code_To_Affiliate`        as `Tracker Aff`
	,M.`Shortlink`
	,FORMAT(CDA.CPA_Value,2)      as `CPA Value`
	,FORMAT(CDA.Baseline,2)       as `BLine`
	,ifnull(D1.CPA,0)             as `CPA`
   ,M.`CPA_Limit`                -- `CPA Limit`
   ,M1.`Deal_Valid_From`
   ,CDA.`Deal_Name`
	,`M1`.`Affiliate_id`
	,`M`.`Channel_id`
	,CU.Username                  as `Account`
	,M.Username_id                as `Username_id`
	,M.Product                    as `MS_Product`
	,M.Tracklink                  as `Tracklink`
   ,CASE WHEN LOCATE("bid=",M.Tracklink)>0
         THEN SUBSTRING_INDEX(SUBSTRING(M.Tracklink,LOCATE("bid=",M.Tracklink) + 4), "&", 1)
         ELSE "" END             as `bid_code`
   ,IFNULL(M.Ad_Code,"")         as `MS_Ad_Code`
FROM `campaign_marketing_source` `M`
-- ---Seleccion de Product-------(tomado de Snapshot_day_by_day_fact1_upd_from_dbd)------
LEFT JOIN LATERAL (
	SELECT * FROM (
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr  -- 15.02.2023
      FROM `mkt_source_deal_Code_To_Affiliate` 
      WHERE `Code_To_Affiliate` = M.Code_To_Affiliate AND MS_id=M.id    -- 20.03.2025
	) AS DbP
   GROUP BY DbP.`Product`
-- 	ORDER BY DbP.`Product` DESC -- LIMIT 1
	ORDER BY DbP.`Deal_Valid_From` DESC  LIMIT 1
) AS M1 ON TRUE
LEFT JOIN FactX D1 								ON D1.Code_To_Affiliate  = M.Code_To_Affiliate
LEFT JOIN `account_account` `A`           ON `A`.`id`  = `M1`.`Affiliate_id`
LEFT JOIN `account_account` `OW`          ON `OW`.`id` = `M`.`Owner`
LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id`= `M1`.`Deal_id`
LEFT JOIN `account_landing_pages` `CH`    ON `CH`.`id` = `M`.`Channel_id`
LEFT JOIN `campaign_username` `CU`        ON `CU`.`id` = `M`.`Username_id`
LEFT JOIN `campaign_advertiser` `AD`      ON `AD`.`id` = `CU`.`Advertiser_id`
LEFT JOIN `campaign_publisher` `P`        ON `P`.`id`  = `CU`.`Publisher_id`
WHERE 1=1 -- and M.`Tracklink` > " "
'
   ,@WhereAffiliate_id
   ,@WhereChannel_id
   ,@WhereStatus
,')
,
MS_filtered AS (
SELECT ms.*
      ,CASE WHEN IFNULL(a.Ad_code,"") > "" THEN a.Title ELSE "Default" END AS `Landing`               -- K 25.02.2025
      ,CASE WHEN IFNULL(a.Ad_code,"") > "" THEN IFNULL(a.Valid_to,"Permanent") ELSE "" END AS `Valid` -- K 25.02.2025
      ,a.Ad_code																													-- K 25.02.2025
      ,CASE WHEN Other_Ads.`K`>0 THEN CONCAT(Other_Ads.`K`," more") ELSE "" END AS `Other LP`
      ,a.id                                                                                           -- K 26.02.2025
FROM campaign_marketing_source_updated ms
LEFT JOIN campaign_advertiser_ads_v2 a  ON ms.MS_Product=a.Product AND ms.Username_id=a.Account_id
                                       AND a.`Status_id`=1
                                       AND a.Valid_From <= CURDATE()
                                       AND (a.Valid_To > CURDATE() OR a.Valid_To IS NULL)
                                       AND ms.Tracklink NOT LIKE "%rebrand.ly%"
                                       AND ms.Tracklink NOT LIKE "%affly%"
                                       AND ms.Tracklink LIKE "%bid=%"
                                       AND a.ad_code = CASE WHEN ms.`MS_Ad_Code`>"" THEN ms.`MS_Ad_Code`
                                                            ELSE ms.`bid_code` END
LEFT JOIN LATERAL (
     SELECT COUNT(*) AS `K`
     FROM campaign_advertiser_ads_v2 b WHERE ms.MS_Product=b.Product AND ms.Username_id=b.Account_id
                                       AND b.`Status_id`=1
                                       AND b.Valid_From <= CURDATE()
                                       AND (b.Valid_To > CURDATE() OR b.Valid_To IS NULL)
                                       AND ms.Tracklink NOT LIKE "%rebrand.ly%"
                                       AND ms.Tracklink NOT LIKE "%affly%"
                                       AND ms.Tracklink LIKE "%bid=%"
                                       AND b.ad_code NOT IN (ms.`MS_Ad_Code`,ms.`bid_code`)
) AS Other_Ads ON TRUE

WHERE 1=1 )
');

SET @CloseQuery=';';

SET @SQL=concat(
@CTE,

IF(@Meta="YES",@SQLmetaAff,""),
IF(@Meta="YES"," UNION ALL ",""),'
(SELECT * FROM MS_filtered M
)
ORDER BY `Brand`,Account,MS_id',@CloseQuery)
;

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
IF  @AffiliateGroup=6 THEN
    SET @SQL=REPLACE(@SQL,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
    SET @SQL=REPLACE(@SQL,"campaign_marketing_source","sub_campaign_marketing_source");
    SET @SQL=REPLACE(@SQL,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
    SET @SQL=REPLACE(@SQL,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
    SET @SQL=REPLACE(@SQL,"account_landing_pages","sub_account_landing_pages");
END IF;
/*---------------------------------------------------------------------------------*/

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
call Aff_Channel_DealMS('affiliate_id=421,channel_id=132,meta=yes,debug=non');   -- Conversionmedia
call Aff_Channel_DealMS('affiliate_id=440,channel_id=162,debug=non');   -- enricobetipster
call Aff_Channel_DealMS('affiliate_id=39,channel_id=1,meta=yes,debug=non');      -- Anatriello
call Aff_Channel_DealMS('affiliate_id=527,channel_id=314,debug=non');   -- subaff

*/


