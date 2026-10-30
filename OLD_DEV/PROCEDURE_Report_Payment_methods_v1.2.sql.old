/*
PROCEDURE_Report_payment_methods.sql - Report payment_methods (account_payment_methods)

Descripción:
  Procedimiento Report_payment_methods.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | Affiliate_id ]. OPCIONAL. Default=ALL
Status          =[ALL | Status_value ]. OPCIONAL. Filtro por campo Status. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_payment_methods('MS_id=130,debug=no');
call Report_payment_methods('Status=Active,debug=no');
call Report_payment_methods('Affiliate_id=123,Status=Active,filters=yes');

30.03.2023 V1     Primera versión operativa
04.07.2025 v1.1   Karen agregado campos PayPal_email
04.07.2025 v1.2   Agregado filtro por campo Status

*/

DROP PROCEDURE IF EXISTS Report_payment_methods;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_payment_methods`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report payment_methods'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.2 04.07.2025';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Affiliate_id    ='all';
SET @Status          ='all';
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

   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =      @v;  END IF;
   IF lower(@k)='status'          THEN SET @Status        =      @v;  END IF;
   IF lower(@k)='Status_id'       THEN SET @Status_id     =      @v;  END IF;
   IF lower(@k)='Stat_final'      THEN SET @Stat_final    =UPPER(@v); END IF;
   IF lower(@k)='product'         THEN SET @Product       =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@MS_id,@Affiliate_id,@Account_id
                     ,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereAffiliate_id='';
SET @WhereStatus      ='';
SET @WhereStatus_id   ='';
SET @WhereStat_final ='';
SET @WhereProduct     ='';

IF @Affiliate_id  !="ALL" THEN SET @WhereAffiliate_id=CONCAT(" AND PM.Account_id  =",@Affiliate_id);     END IF;
IF @Status        !="ALL" THEN SET @WhereStatus      =CONCAT(" AND PM.Status      ='",@Status,"'");      END IF;
-- IF @Status_id     !="ALL" THEN SET @WhereStatus_id   =CONCAT(" AND CH.Status_id   =",@Status_id);        END IF;
-- IF @Stat_final    !="ALL" THEN SET @WhereStat_final  =CONCAT(" AND `Stat_final`   ='",@Stat_final,"'");   END IF;
-- IF @Product       !="ALL" THEN SET @WhereProduct     =CONCAT(" AND CH.Product     ='",@Product,"'");     END IF;

IF @Debug!="NO" THEN SELECT @WhereAffiliate_id,@WhereStatus,@WhereStatus_id,@WhereStat_final,@WhereProduct; END IF;

/**************************************************************************************************************/
/*
SELECT `id`,`Account_id`,`email`,`Payment_Method`,`Card_Owner_Name`,`Card_Owner_Number`
,`Card_Expiry_Date`,`Card_CVV`,`Bank_Name`,`Bank_IBAN`,`Bank_Swift`,`Insert_Date`
,`Status`,`Owner_Address`,`Creation_Date`,`Last_Update`,`Operator` 
FROM account_payment_methods
*/
-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    PM.`id`                   as `Id`             
   ,PM.`Account_id`           as `Affiliate_id`
   ,A.`Username`              as `Affiliate`
   ,PM.`Payment_Method`          `Payment_Method`
   ,PM.`Card_Owner_Name`      as `Bearer`
   ,PM.`Bank_Name`               `Bank_Name`
   ,PM.`Bank_IBAN`               `Bank_IBAN`
   ,PM.`Bank_Swift`              `Bank_Swift`
   ,PM.`Status`                  `Status`
   ,PM.`Status_id` 
   ,PM.`Owner_Address`
   ,PM.`Crypto_Address`
   ,PM.`Crypto_Type`
   ,PM.`PayPal_email`
   ,PM.`Creation_Date`   
   ,left(ifnull(PM.`Last_Update`,""),16) `Last Update`
   ,IFNULL(U.`username`,PM.`Operator`) `User`
FROM account_payment_methods PM
LEFT JOIN `account_account` `A` ON `A`.`id`  =  PM.`Account_id`
LEFT JOIN account_account `U` ON `U`.`id`  =  PM.`Operator` 
WHERE 1=1 '
   ,@WhereAffiliate_id  
   ,@WhereStatus
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
    ,"width=80px,action=2"     as `Action`   
	 ,"omit=yes"                as `Id`            
    ,"width=100px"             as `Affiliate id`
    ,"width=150px"             as `Affiliate`
    ,"width=150px"             as `Payment Method`
    ,"width=250px"             as `Bearer`
    ,"width=250px"             as `Bank_Name`
    ,"width=250px"             as `Bank_IBAN`
    ,"width=150px"             as `Bank_Swift`
    ,"width=100px"             as `Status`
    ,"width=100px"             as `Status id`
    ,"width=100px"             as `Owner Address`
    ,"width=100px"             as `Crypto Address`
    ,"width=100px"             as `Crypto Type`
    ,"width=100px"             as `PayPal email`
    ,"omit=yes"                as `Creation_Date`
    ,"width=130px"             as `Last Update`
    ,"width=100px"             as `User`
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
WHERE 1=1 '
   ,@WhereStat_final,
')
order by Affiliate
;');

-- ------------------------------------------------------------
SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "03" as "Korder","Affiliate" AS "Key",`Affiliate` AS "Value","Affiliate_id" AS `CallKey`,`Affiliate_id` AS "CallValue",COUNT(*) AS "Rows"
                                                                                     FROM Main_Table_Data GROUP BY `Affiliate_id`)     UNION ALL
(SELECT "01","Status",`Status`,"Status" ,`Status`  ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`Status`,""))  -- UNION ALL
-- (SELECT "06","Affiliate"     ,`Affiliate`  ,"Affiliate_id",`Affiliate_id`,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`Affiliate`,""))   UNION ALL
-- (SELECT "07","Product" 	     ,`Product`    ,"Product"     ,`Product`     ,COUNT(*) AS K FROM Main_Table_Data GROUP BY IFNULL(`Product`,""))
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
call Report_payment_methods('debug=ye,filters=yes');
call Report_payment_methods('stat_final=active*,debug=ye');
*/
