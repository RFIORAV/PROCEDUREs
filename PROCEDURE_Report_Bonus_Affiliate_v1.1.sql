/*
PROCEDURE_Report_Bonus_Affiliate.sql - Report Reglas Bonus Affiliate

Descripción:
  Procedimiento Report_Bonus_Affiliate.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id del Advertiser]. OPCIONAL. Default=ALL
Brand           =[ALL | Brand]. OPCIONAL. Default=ALL.
Status_bonus    =[ALL | valid | expired ]. OPCIONAL. Default=ALL.
Status_id       =[ALL | 1 | 0]. OPCIONAL. Default=ALL. 1=Active 0=Inactive
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Key no utilizadas:

Mode            =[Affiliate | Gestor]. OPCIONAL. Default=affiliate
MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Affiliate_id    =[ALL | id del Affiliate]. OBLIGATORIO. Default=''
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
DealbyProduct   =[No | Yes]. Devuelve último deal activo por cada Product. OPCIONAL. Default=no.
Search          =[(dato a buscar]. OPCIONAL. Busca string en Tracker_ID/Tracker_Name/Code_To_Affiliate/MS_id/MS_id/affiliate/Channel

Ejemplos:

call Report_Bonus_Affiliate('debug=yes'); -- Devuelve todas las MS
call Report_Bonus_Affiliate('debug=ye,filters=yes');
call Report_Bonus_Affiliate('debug=ye,filters=no,status=0');

02.12.2024 V1     Primera versión operativa
08.01.2025 v1.1   Fitro por Status_bonus=Expired/Valid

*/

DROP PROCEDURE IF EXISTS Report_Bonus_Affiliate;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Bonus_Affiliate`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Bonus Affiliate'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.1 08.01.2025';
SET @CurrentDay      =curdate();

SET @Affiliate_id    ='ALL';
SET @Brand           ='ALL';
SET @Status_bonus    ='ALL';
SET @Status_id       ='ALL';

SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';


SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Publisher_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

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
   IF lower(@k)='Status_bonus'    THEN SET @Status_bonus  =UPPER(@v); END IF;
   IF lower(@k)='status_id'       THEN SET @Status_id     =UPPER(@v); END IF;
   IF lower(@k)='brand'           THEN SET @Brand         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;


IF @Debug!="NO" THEN SELECT @Filters,@Status_id,@Status_bonus,@Brand,@Affiliate_id,@Debug,@Meta,InputCommLine; END IF;

SET @WhereAffiliate_id  ='';
SET @WhereStatus        ='';
SET @WhereBrand         ='';

IF @Affiliate_id  !="ALL" THEN SET @WhereAffiliate_id  =CONCAT(" AND Affiliate_id =",@Affiliate_id ); END IF;
IF @Brand         !="ALL" THEN SET @WhereBrand         =CONCAT(" AND UPPER(TRIM(`Brand`))='",@Brand,"'"); END IF;
IF @Status_id     !="ALL" THEN SET @WhereStatus        =CONCAT(" AND B.`Status_id`=",@Status_id);       END IF;

CASE lower(@Status_bonus)
   WHEN "expired" THEN SET @WhereStatus_bonus=' AND CURDATE()> IFNULL(`Date_Valid_to`,"9999-12-31") ';
   WHEN "valid"   THEN SET @WhereStatus_bonus=' AND CURDATE()<=IFNULL(`Date_Valid_to`,"9999-12-31") ';
   ELSE SET @WhereStatus_bonus  ='';
END CASE;
   
IF @Debug!="NO" THEN SELECT @WhereAffiliate_id,@WhereBrand,@WhereStatus,@WhereStatus_bonus; END IF;

/**************************************************************************************************************/
CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_bonus` (
   `id`                 INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id`       INT NULL DEFAULT NULL,
   `Brand`              VARCHAR(50) NULL DEFAULT ' ' ,
   `Code_to_Affiliate`  VARCHAR(50) NULL DEFAULT ' ' ,
   `Description`        VARCHAR(100) NULL DEFAULT ' ' ,
   `Date_Valid_From`    DATE NULL DEFAULT NULL,
   `Date_Valid_to`      DATE NULL DEFAULT NULL,
   `Bonus_Value`        DECIMAL(10,0) NULL DEFAULT '0',
   `Currency`           VARCHAR(5) NULL DEFAULT 'EUR' ,
   `Conditions`         VARCHAR(30) NULL DEFAULT 'ANY' COMMENT 'Any/All condition' ,
   `CPA_min`            INT NULL DEFAULT '0',
   `NR_min`             INT NULL DEFAULT '0',
   `FTD_min`            INT NULL DEFAULT '0',
   `Status_id`          SMALLINT NULL DEFAULT '1',
   `Status`             VARCHAR(30) NULL DEFAULT NULL ,
   `Creation_Date`      DATETIME NULL DEFAULT (now()),
   `Last_Update`        DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`           VARCHAR(30) NULL DEFAULT ' ' ,
   PRIMARY KEY (`id`) USING BTREE
)
;

/**************************************************************************************************************/

-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    B.`id`               
   ,B.`Status`            
   ,B.`Affiliate_id`     
   ,IFNULL(A.`username`,"ALL")   as `Affiliate`   
   ,B.`Brand`            
   ,CASE WHEN IFNULL(B.`Code_to_Affiliate`,"")="" THEN "-Any-" ELSE B.`Code_to_Affiliate` END AS `Code_to_Affiliate`
   ,B.`Description`      
   ,B.`Date_Valid_From`  
   ,IFNULL(B.`Date_Valid_to`,"undefined") AS `Date_Valid_to`
   ,B.`Bonus_Value`      
   ,B.`Currency`         
   ,B.`Conditions`       
   ,B.`CPA_min`          
   ,B.`NR_min`           
   ,B.`FTD_min`          
   ,B.`Status_id`        
   ,LEFT(IFNULL(B.`Creation_Date`,""),19) `Creation_Date`      
   ,LEFT(IFNULL(B.`Last_Update`,""),19)   `Last_Update`      
   ,A1.`username`  as `Operator`         
FROM campaign_deal_affiliate_bonus B
LEFT JOIN `account_account` `A`  ON `A`.`id` = `B`.`Affiliate_id`
LEFT JOIN `account_account` `A1` ON `A1`.`id` = `B`.`Operator`
WHERE 1=1 '
   ,@WhereAffiliate_id
   ,@WhereStatus      
   ,@WhereStatus_bonus      
   ,@WhereBrand       
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"width=80px,action=2" as `Action`
   ,"omit=true"     as `id`               
   ,"width=100px"   as `Status`            
   ,"omit=true"     as `Affiliate_id`     
   ,"width=130px"   as `Affiliate`     
   ,"width=130px"   as `Brand`            
   ,"width=100px"   as `Code to Aff (MS)`
   ,"width=300px,tooltip=yes"   as `Description`      
   ,"width=100px"   as `Valid From`  
   ,"width=100px"   as `Valid Until`    
   ,"width=100px,right=true"   as `Bonus Value`      
   ,"width=080px"   as `Currcy`         
   ,"omit=true"     as `Conditions to satisfy`       
   ,"width=110px,right=true"   as `CPA minimum`          
   ,"width=110px,right=true"   as `NR  minimum`           
   ,"omit=true"     as `FTD minimum`          
   ,"omit=true"     as `Status_id`        

   ,"omit=true"     as `Creation`
   ,"width=150px"   as `Last Update`
   ,"width=100px"   as `User`    
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`
   ,"..." as `Action`,
   MT.* 
FROM Main_Table_Data MT
ORDER BY `Affiliate`
');

-- ------------------------------------------------------------
SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "3" as "Korder","Status" AS "Key",`Status` AS "Value","Status_id" AS `CallKey`,`Status_id` AS "CallValue",COUNT(*) AS "Rows"
                                                                                 FROM Main_Table_Data GROUP BY `Status_id` ) UNION ALL
(SELECT "1","Status Bonus","Expired"  ,"Status_bonus","expired"     ,"" AS K     FROM DUAL) UNION ALL
(SELECT "1","Status Bonus","Valid this month","Status_bonus","valid","" AS K     FROM DUAL) UNION ALL
(SELECT "5","Brand",`Brand`,"Brand",TRIM(`Brand`)                 ,COUNT(*) AS K FROM Main_Table_Data GROUP BY TRIM(IFNULL(`Brand` ,""))) UNION ALL
(SELECT "7","Affiliate",`Affiliate`,"Affiliate_id",`Affiliate_id` ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`Affiliate` ,"")) 
ORDER BY 1,3
;');

IF @Filters!="NO" THEN SET @SQL=@SQLfilters; END IF;

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

call Report_Bonus_Affiliate('debug=ye'); -- Devuelve todas las MS
call Report_Bonus_Affiliate('debug=ye,filters=yes');
call Report_Bonus_Affiliate('debug=ye,filters=no,status_id=0');

*/

/* 
SELECT CONCAT_WS(" ","Bonus of"
   ,B.Bonus_Value,B.Currency
   ,"to"
   ,case when B.Affiliate_id=0 then "ALL Aff" ELSE A.username END
   ,"ON",B.Brand
   ,case when B.Code_to_Affiliate="" then "ALL MS" ELSE CONCAT("Tracker ",B.Code_to_Affiliate) END
   ,"Valid from", Left(B.Date_Valid_From,7)
   ,case when B.Date_Valid_to IS null then "" ELSE CONCAT("until end of ",Left(B.Date_Valid_to,7)) END
   ,"Conditions:"
   ,case when B.CPA_min>0 then CONCAT("CPA > ",B.CPA_min) ELSE "" END 
   ,case when B.CPA_min>0 AND B.NR_min<>0  THEN CONCAT("AND NetRev > ",B.NR_min) 
         when B.CPA_min=0 AND B.NR_min<>0 THEN CONCAT("NetRev > ",B.NR_min) 
         ELSE "" END  
   ) AS `DESCRIPTION`
FROM campaign_deal_affiliate_bonus B
LEFT JOIN account_account A ON B.Affiliate_id=A.id

;
*/