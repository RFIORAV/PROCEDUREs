/*
PROCEDURE_Report_Campaigns.sql - Report_Campaigns (campaign_campaign)

Descripción:
  Procedimiento Report_Campaigns.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Advertiser_id   =[ALL | Advertiser_id ]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | Publisher_id ]. OPCIONAL. Default=ALL
Status_id       =[ALL | Status_id ]. OPCIONAL. Default=ALL
Product         =[ALL | Product ]. OPCIONAL. Default=ALL
Country         =[ALL | Country ]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Campaigns('debug=no');
call Report_Campaigns('debug=ye,filters=yes');
call Report_Campaigns('MS_id=130,debug=no');
call Report_Campaigns('debug=ye,filters=no,status=inactive');

12.04.2023 V1     Primera versión operativa
18.04.2023 V1.1   Publisher_id
10.04.2026 v1.1b  Meta/filtros: publisher (nombre) -> Operator; usuario (campo Operator) -> User
27.05.2026 v1.1c  Añadida opción colorBg=[Active:green;Inactive:red;Paused:orange] a columna Status
*/

DROP PROCEDURE IF EXISTS Report_Campaigns;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Campaigns`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.1c 27.05.2026 - Report Campaigns/Promos'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.1c 27.05.2026';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Advertiser_id   ='all';
SET @Country         ='all';
SET @Status_id       ='all';
SET @Stat_final      ='all';
SET @Product         ='all';
SET @Debug           ='NO';
SET @Filters         ='NO';
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

   IF lower(@k)='Advertiser_id'   THEN SET @Advertiser_id =      @v;  END IF;
   IF lower(@k)='Publisher_id'    THEN SET @Publisher_id  =      @v;  END IF;
   IF lower(@k)='Status_id'       THEN SET @Status_id     =      @v;  END IF;
   IF lower(@k)='product'         THEN SET @Product       =UPPER(@v); END IF;
   IF lower(@k)='country'         THEN SET @Country       =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@MS_id,@Advertiser_id,@Account_id
                     ,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereAdvertiser_id='';
SET @WherePublisher_id='';
SET @WhereStatus_id   ='';
SET @WhereProduct     ='';
SET @WhereCountry     ='';

IF @Publisher_id  !="ALL" THEN SET @WherePublisher_id =CONCAT(" AND A.Publisher_id   =",@Publisher_id);   END IF;
IF @Advertiser_id !="ALL" THEN SET @WhereAdvertiser_id=CONCAT(" AND CC.Advertiser_id =",@Advertiser_id);  END IF;
IF @Status_id     !="ALL" THEN SET @WhereStatus_id    =CONCAT(" AND CC.Status_id     ='",@Status_id,"'"); END IF;
IF @Product       !="ALL" THEN SET @WhereProduct      =CONCAT(" AND CC.Product       ='",@Product,"'");   END IF;
IF @Country       !="ALL" THEN SET @WhereCountry      =CONCAT(" AND CC.Country       ='",@Country,"'");   END IF;

IF @Debug!="NO" THEN SELECT @WhereAdvertiser_id,@WhereStatus_id,@WhereStat_final,@WhereProduct; END IF;

/**************************************************************************************************************/
/*
SELECT `id`,`Advertiser_id`,`Name_Campaign`,`Valid_Until`,`Status_id`,`MS_id`,`Owner`
,`Logo`,`Product`,`Status`,`Description`,`Title`,`Payment_Method`,`Country`,
`Valid_From`,`Creation_Date`,`Last_Update`,`Operator` 
FROM campaign_campaign
*/
SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    CC.`id`					as `Campaign_id`
   ,P.`Advertiser_Name` as `Operator`
   ,CC.`Advertiser_id`	as `Brand id`
   ,A.`Advertiser_Name` as `Brand`   
   ,CC.`Product`
   ,CC.`Country`       
   ,CC.`Name_Campaign`
   ,CC.`Valid_From`
   ,CC.`Valid_Until`
   ,CC.`Status_id`
   -- ,CC.`Status`
   ,(CASE CC.`Status_id`
        WHEN "0" THEN "Inactive"
        WHEN "1" THEN "Active"
        WHEN "4" THEN "Paused"
        ELSE "Other" END)     as `Status`
   ,ifnull(CC.`MS_id`,"all")  as `MS_id`
   ,CC.`Description`
   ,CC.`Title`
   ,CC.`Logo`
   ,CC.`Payment_Method`
   ,CC.`Creation_Date`
   ,left(CC.`Last_Update`,19) `Last_Update`
   ,CC.`Operator`        as `User`
   ,CC.`id` 
   ,CC.`Advertiser_id`   
   ,A.`Publisher_id`  
FROM campaign_campaign CC
LEFT JOIN `campaign_advertiser` `A` ON `A`.`id`  =  CC.`Advertiser_id`
LEFT JOIN `campaign_publisher`  `P` ON `P`.`id`  =  A.`Publisher_id`
WHERE 1=1 '
   ,@WherePublisher_id
   ,@WhereAdvertiser_id
   ,@WhereStatus_id   
--    ,@WhereStat_final 
   ,@WhereProduct     
   ,@WhereCountry     
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
	,"width=80px,action=2"     as `Action`
   ,"width=080px"             as `Camp id` 
   ,"width=150px"             as `Operator`
   ,"omit=yes"                as `Brand id`   
   ,"width=150px"             as `Brand`
   ,"width=100px"             as `Product`
   ,"width=090px"             as `Country`
   ,"width=200px,tooltip=yes" as `Campaign`
   ,"width=110px"             as `Valid From`
   ,"width=100px"             as `Valid Until`
   ,"omit=yes"                as `Status id`
   ,"width=100px,colorBg=[Active:green;Inactive:red;Paused:orange]" as `Status`
   ,"width=080px"             as `MS id`
   ,"width=300px,tooltip=yes" as `Description`
   ,"width=300px,tooltip=yes" as `Title`
   ,"omit=yes"                as `Logo`
   ,"omit=yes"                as `Payment_Method`
   ,"omit=yes"                as `Creation_Date`
   ,"width=130px,tooltip=yes" as `Last Update`
   ,"width=100px"             as `User`                            
   ,"omit=yes"                as `id`
   ,"omit=yes"                as `Advertiser_id`
   ,"omit=yes"                as `Publisher_id`
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

order by `Brand`,`Product`,`Country`,`Campaign`
;');

-- ------------------------------------------------------------
SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "01" as "Korder","Status" AS "Key",`Status` AS "Value","Status_id" AS `CallKey`,`Status_id` AS "CallValue",COUNT(*) AS "Rows"
                                                                                 FROM Main_Table_Data GROUP BY `Status`)                 UNION ALL
(SELECT "06","Brand"    ,`Brand`    ,"Advertiser_id",`Advertiser_id`,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Brand`,"")>"" GROUP BY IFNULL(`Brand`,""))     UNION ALL
(SELECT "07","Operator" ,`Operator` ,"Publisher_id" ,`Publisher_id` ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Operator`,"")>"" GROUP BY IFNULL(`Operator`,"")) UNION ALL
(SELECT "08","Product" 	,`Product`  ,"Product"      ,`Product`      ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Product`,"")>"" GROUP BY IFNULL(`Product`,""))   UNION ALL
(SELECT "08","Country" 	,`Country`  ,"Country"      ,`Country`      ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Country`,"")>"" GROUP BY IFNULL(`Country`,""))
ORDER BY 1,3
;');

IF @Filters="yes" THEN SET @SQL=@SQLfilters; END IF;

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
call Report_Campaigns('debug=ye,filters=yes');
call Report_Campaigns('debug=yes');
*/


/*
SELECT 
 CC.`id`
,CC.`Advertiser_id`
,CC.`Name_Campaign`
,CC.`Valid_Until`
,CC.`Status_id`
,CC.`MS_id`
,CC.`Owner`
,CC.`Logo`
,CC.`Product`
,CC.`Status`
,CC.`Description`
,CC.`Title`
,CC.`Payment_Method`
,CC.`Country`
,CC.`Valid_From`
,CC.`Creation_Date`
,CC.`Last_Update`
,CC.`Operator` 
FROM campaign_campaign CC
*/
