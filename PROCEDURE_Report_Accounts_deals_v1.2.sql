/*
PROCEDURE_Report_Accounts_deals.sql - Report Accounts (campaign_username)

Descripción:
  Procedimiento Report_Accounts_deals.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Accounts_deals('Account_id=2,debug=no');

09.02.2023 V1     Primera versión operativa
15.02.2023 V1.1   Karen. AgrEga campo T.id. Agrega switch=yes a Status
28.04.2023        Orden tatus desc/Product asc/Valid From desc
28.04.2023 v1.2   Fix gráfico status. Agregado texto status

*/

DROP PROCEDURE IF EXISTS Report_Accounts_deals;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Accounts_deals`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Accounts Deals'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.2 28.04.2023';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Account_id      ='ALL';
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

   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='account_id'      THEN SET @Account_id    =     (@v); END IF;

END WHILE;

-- Recupera espacios reemplazados en front end por caracter "\"
-- SET @Product      =replace(@Product,"!"," ");
-- SET @Platform     =replace(@Platform,"!"," ");
-- SET @Brand_Group  =replace(@Brand_Group,"!"," ");

-- IF @Debug!="NO" THEN SELECT @Product,@Platform,@Brand_Group; END IF;
--

-- IF @Mode!='GESTOR' THEN
   -- SET @Mode='AFFILIATE';
   -- SET @View='VIEWAFF';
-- END IF;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@OWNER,@OnlyOverCap,@Brand_Group,@Advertiser_id,@Affiliate_id,@Account_id
,@Channel_id,@Product,@DealbyProduct,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereAccount='';
-- SET @WhereArea='';
-- SET @WhereOwner='';
-- SET @WhereBrand ='';
-- SET @WherePublisher='';
-- SET @WhereProduct='';
-- SET @WhereStatus='';

IF @Account_id    !="ALL" THEN SET @WhereAccount       =CONCAT(" AND T.Username_id =",@Account_id );        END IF;
-- IF @Area          !="ALL" THEN SET @WhereArea          =CONCAT(" AND T.Area='",@Area,"'");                 END IF;
-- IF @Owner         !="ALL" THEN SET @WhereOwner         =CONCAT(" AND T.Owner=",@Owner);                    END IF;
-- IF @Advertiser_id !="ALL" THEN SET @WhereBrand         =CONCAT(" AND T.Advertiser_id  =",@Advertiser_id ); END IF;
-- IF @Publisher_id  !="ALL" THEN SET @WherePublisher     =CONCAT(" AND T.Publisher_id =",@Publisher_id );    END IF;
-- IF @Product       !="ALL" THEN SET @WhereProduct       =CONCAT(" AND T.`Product`      ='",@Product,"'");   END IF;
-- IF @Status        !="ALL" THEN SET @WhereStatus        =CONCAT(" AND T.`Status`       ='",@Status,"'");    END IF;

IF @Debug!="NO" THEN SELECT @WhereOwner,@WhereAdvertiser_id,@WhereAffiliate_id,@WhereAdv_Account_id,@WhereChannel_id,@WhereProduct,@WhereStatus,@WhereMS_id,@WhereSearch; END IF;

SET @Count=0;

/**************************************************************************************************************/
/*
SELECT `id`,`Advertiser_id`,`Username_id`,`Product`,`Country`,`Valid_From`,`Deal_id`,`is_active`
      ,`Creation_Date`,`Last_Update`,`Operator` 
FROM campaign_deal_gestor_prod_date
*/
SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT
    T.`id`             as `Rule`
   ,IF(IFNULL(T.`is_active`,0)=1,1,0) as `St`
   ,IF(IFNULL(T.`is_active`,0)=1,"Enabled","Disabled") as `St_text`
   ,CASE WHEN IFNULL(T.`Product`,"")>" " THEN  T.`Product` ELSE "Any" END as `Product`
   ,T.`Deal_id`        as `Deal_id`
   ,CDG.`Deal_Name`    as `Deal`
   ,CASE WHEN IFNULL(T.`Country`,"")>" " THEN  T.`Country` ELSE "Any" END as `Country`
   ,T.`Valid_From`     as `Valid From`
   -- ,IF(T.`is_active`=1,"Enabled","Disabled") as `Status`
   ,LEFT(IFNULL(T.`Last_Update`,""),16) `Last Update`
   ,T.`Operator` 
   ,T.`Advertiser_id`  as `Advertiser_id`
   ,T.`Username_id`    as `Username_id`
   ,T.`is_active`   
   ,T.`id`                                     -- 15.02.2023 Karen
FROM campaign_deal_gestor_prod_date T
LEFT JOIN `campaign_deal_gestor` `CDG` ON `CDG`.`id` = `T`.`Deal_id`
WHERE 1=1 '
   ,@WhereAccount
   -- ,@WhereOwner
   -- ,@WhereBrand
   -- ,@WherePublisher
   -- ,@WhereProduct
   -- ,@WhereStatus
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
	,"width=80px,action=2"     as `Action`
   ,"width=080px"             as `Rule`
   ,"width=080px,switch=yes"  as `Status`             -- 15.02.2023 Karen
   ,"width=080px"             as `Rule Status`
   ,"width=150px"             as `Product`
   ,"width=080px"             as `Deal id`
   ,"width=200px,tooltip=yes" as `Deal`
   ,"width=090px"             as `Country`
   ,"width=100px"             as `Valid From`
   -- ,"width=100px"             as `Rule Status`     -- 26.02.2023
   ,"width=130px"             as `Last Update`
   ,"width=100px"             as `Operator`    
   ,"omit=yes"                as `Advertiser_id`   
   ,"omit=yes,center=yes"     as `Username_id`
   ,"omit=yes"                as `is_active`        
   ,"omit=yes"                as `id`              -- 15.02.2023 Karen
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
order by `is_active` desc,`Product`,`Valid From` desc
;');

-- ------------------------------------------------------------
-- SET @SQLfilters=CONCAT(
-- @CTE,'
-- (SELECT "1" as "Korder","Status" AS "Key",`Status` AS "Value","Status" AS `CallKey`,`Status` AS "CallValue",COUNT(*) AS "Rows"
                                                                                          -- FROM Main_Table_Data GROUP BY `Status`       ) UNION ALL
-- (SELECT "3","Area" 	   ,`Area`     ,"Area"         ,`Area`          ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Area`,"")>""       GROUP BY IFNULL(`Area` ,"")) UNION ALL
-- (SELECT "5","Owner" 	   ,`Owner`    ,"Owner"        ,`Owner_id`      ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Owner_id`,"")>""   GROUP BY IFNULL(`Owner_id` ,"")) UNION ALL
-- (SELECT "7","Brand" 	   ,`Brand`    ,"Advertiser_id",`Advertiser_id` ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Brand`,"")>""      GROUP BY IFNULL(`Brand` ,"")) UNION ALL
-- (SELECT "9","Publisher" ,`Publisher`,"Publisher_id" ,`Publisher_id`  ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Publisher`,"")>""  GROUP BY IFNULL(`Publisher` ,""))
-- ORDER BY 1,3
-- ;');

-- IF @Filters!="NO" THEN SET @SQL=@SQLfilters; END IF;

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
call Report_Accounts_deals('Account_id=7,debug=non');
*/
