/*
PROCEDURE_Report_MS_deals.sql - Report MS deals (campaign_mkt_source_deal)

Descripción:
  Procedimiento Report_MS_deals.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Mode            =[Affiliate | Gestor | MAF]. OPCIONAL. Default=affiliate
MS_id      		 =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_MS_deals('MS_id=130,debug=no');

09.02.2023 V1     Primera versión operativa
15.02.2023 V1.1   Karen. Agrega campo T.id. Agrega switch=yes a Status
25.02.2023 V1.1	Copiada y adaptada desde Report_Account_deals
24.03.2023 V1.2	Switch enable/disable
28.04.2023     	Karen - Fix Switch enable/disable
19.06.2024 v1.3   Opción master afiliado (MODE = MAF)
23.09.2026 v1.4   Agrega tooltip a Product / Reward plan
*/

DROP PROCEDURE IF EXISTS Report_MS_deals;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_MS_deals`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.4 23.09.2026 Report MS Deals'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.4 23.09.2026';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Mode            ='affiliate';
SET @MS_id           ='0';
SET @Debug           ='NO';
SET @Meta            ='YES';

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

   IF lower(@k)='Mode'            THEN SET @Mode          =UPPER(@v); END IF;
   IF lower(@k)='MS_id'           THEN SET @MS_id         =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@MS_id,@Affiliate_id,@Account_id
                     ,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereMS_id='';

SET @WhereMS_id=CONCAT(' AND T.MS_id="',@MS_id,'" ');

SET @Count=0;

/**************************************************************************************************************/
/*
SELECT `id`,`Advertiser_id`,`Username_id`,`Product`,`Country`,`Valid_From`,`Deal_id`,`is_active`
      ,`Creation_Date`,`Last_Update`,`Operator`
FROM campaign_deal_gestor_prod_date
*/
-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT
    T.`id`             as `Rule`
   ,IF(T.`is_active`=1,"Enabled","Disabled") as `Status`
   ,IF(T.`is_active`=1, 1 , 0)               as `Sw`     -- 28.04.2023 Karen
   ,A.`Username`                             as `Affiliate`
   ,CASE WHEN IFNULL(T.`Product`,"")>" " THEN  T.`Product` ELSE "Any" END as `Product`
   ,T.`Deal_id`                              as `Deal_id`
   ,CDA.`Deal_Name`                          as `Deal`
   ,CASE WHEN IFNULL(T.`Country`,"")>" " THEN  T.`Country` ELSE "Any" END as `Country`
   ,T.`Deal_Valid_From`                      as `Valid From`
   ,IFNULL(A1.`Username`,"SysOp")            as `Operator`
   ,LEFT(IFNULL(T.`Last_Update`,""),16)      as `Last Update`
   ,T.`Affiliate_id`                         as `Affiliate_id`
   ,T.`is_active`
   ,T.`id`                                     -- 15.02.2023 Karen
FROM campaign_mkt_source_deal T
LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id`  = `T`.`Deal_id`
LEFT JOIN `account_account`         `A`   ON `A`.`id`    = `T`.`Affiliate_id`
LEFT JOIN `account_account`         `A1`  ON `A1`.`id`   = `T`.`Operator`
WHERE 1=1 '
   ,@WhereMS_id
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
	,"width=80px,action=2"     as `Action`
   ,"width=080px"             as `Rule`
   ,"width=080px"             as `Rule Status`       -- Hasta que se habilite el Switch=yes
   ,"width=100px,switch=yes"  as `Switch`            -- 15.02.2023 Karen
   ,"width=150px"             as `Affiliate`
   ,"width=180px,tooltip=yes" as `Product / Reward plan`
   ,"width=080px"             as `Deal id`
   ,"width=200px,tooltip=yes" as `Deal`
   ,"width=090px"             as `Country`
   ,"width=100px"             as `Valid From`
   ,"width=100px"             as `User`
   ,"width=150px"             as `Updated on`
   ,"omit=yes"                as `Affiliate_id`
   ,"omit=yes"                as `is_active`
   ,"omit=yes"                as `id`                -- 15.02.2023 Karen
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`
	,"..." as `Action`
	,MT.*
FROM Main_Table_Data MT
order by `is_active` desc,`Valid From` desc,`Rule` desc
;');

-- ------------------------------------------------------------
/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
IF  @Mode="MAF" THEN
    -- SET @SQL=REPLACE(@SQL,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
    -- SET @SQL=REPLACE(@SQL,"campaign_marketing_source","sub_campaign_marketing_source");
    SET @SQL=REPLACE(@SQL,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
    SET @SQL=REPLACE(@SQL,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
    -- SET @SQL=REPLACE(@SQL,"account_landing_pages","sub_account_landing_pages");
    -- SET @SQL=REPLACE(@SQL,"account_payment_methods","sub_account_payment_methods");
    -- SET @SQL=REPLACE(@SQL,"account_account_bills","sub_account_account_bills");
    -- SET @SQL=REPLACE(@SQL,"view_monthly_fact_aff4","sub_view_monthly_fact_aff4");
END IF;
/*---------------------------------------------------------------------------------*/

-- IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Report_MS_deals('MS_id=130,debug=ye');
call Report_MS_deals('mode=maf,MS_id=n5h1ti,debug=ye');
*/
