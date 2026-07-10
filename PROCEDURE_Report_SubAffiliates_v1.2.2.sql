/*
PROCEDURE_Report_SubAffiliates.sql - Report Sub Afiliates - Deals

Descripción:
  Procedimiento Report_SubAffiliates.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id     =[id de Afiliado]
Filters          =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta             =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug            =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_SubAffiliates('Affiliate_id=442,debug=ye');

26.02.2024 V1     Karen. Primera versión operativa
19.09.2024 v1.1   RF. Agregado nombre completo sub afiliado y Advertiser
22.09.2024            Agregada columna Status (omit=yes)
04.10.2024        KF. Agregado campo a grid
12.03.2025 V1.2   KF. Mostrar sub afiliados aunque no tengan deal asignado
13.03.2025 V1.2.1 RF. Mostrar sub afiliados en base a referral_id, referral_id_origin
                      y según tabla master_affiliate_deals_per_affiliate
13.03.2025 V1.2.2 KF. Agregado campos necesarios para edit/add cuando no tiene nada
12.06.2026 V1.2.3 KF. Agregado campo cambio de título de Advertiser_Name a Brand
*/

DROP PROCEDURE IF EXISTS Report_SubAffiliates;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_SubAffiliates`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.2.3 12.06.2026 - Report Sub Afiliates - Deals'

proc_label:BEGIN

SET @Version         ='v1.2.3 12.06.2026';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Affiliate_id    ='';
SET @Debug           ='NO';
SET @Meta            ='YES';

-- ----------------------------------------------------------------------------
SET @InputCommLine=Concat(InputCommLine ,',');
SET @InputCommLine=replace(@InputCommLine,'"','');
IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
   SET @e=INSTR(@InputCommLine,'=');
   SET @c=INSTR(@InputCommLine,',');
   SET @k=SUBSTRING(@InputCommLine,1,@e-1);
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1));
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='Affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
END WHILE;
IF @Debug!="NO" THEN SELECT @Month,@Affiliate_id,@Debug,@Meta,InputCommLine; END IF;
-- ----------------------------------------------------------------------------

SET @WhereAffiliate_id =CONCAT(" AND a.id =", @Affiliate_id); -- 12-03-2025
SET @WhereAffiliate_id1=CONCAT(" AND a.Master_Affiliate_id =", @Affiliate_id); -- 12-03-2025

-- ----------------------------------------------------------------------------

SET @CTE_by_referral_id_origin=CONCAT('
SELECT
	 ar.id as Sub_Affiliate_id
	,ar.username as `Sub Affiliate`
   ,CONCAT(ar.last_name,", ",ar.first_name) AS `LongName`
   ,ifnull(AD.Advertiser_Name,"Any") as Advertiser_Name
	,case when DxA.Status_id = "1" then "Active" else "Disabled" end as `Status`
	,DxA.Deal_id
	,IF(DxA.Master_Affiliate_id IS NULL, "No deal assigned", d.Deal_Name) as Deal_Name
	,DxA.Valid_From
	,DxA.Valid_To
	,if(ifnull(d.CPA_Value,0)=0,"--",d.CPA_Value)                           AS `CPA_Value`
	,if(ifnull(d.RS_Percentage,0)=0,"--",d.RS_Percentage)                   as `RS_Percentage`
	,if(ifnull(d.Commissions_Percentage,0)=0,"--",d.Commissions_Percentage) as `Commissions_Percentage`
   ,LEFT(IFNULL(DxA.`Last_Update`,""),16) as `Last Update`
   ,IFNULL(o.`Username`,"SysOp")        as `Operator`
	,DxA.id
	,a.id as Master_Affiliate_id -- KF 13.03.2025                                             
FROM account_account a
INNER JOIN account_account                      ar  ON a.referral_id = ar.referral_id_origin
LEFT  JOIN master_affiliate_deals_per_affiliate DxA ON a.id = DxA.Master_Affiliate_id and ar.id=DxA.Sub_Affiliate_id and DxA.Status_id = 1
LEFT  JOIN master_affiliate_deals               d   ON DxA.Deal_id = d.id
LEFT  JOIN account_account                      o   ON DxA.Operator = o.id
LEFT  JOIN `campaign_advertiser`                AD  on DxA.Advertiser_id=AD.id
WHERE 1=1 '
   ,@WhereAffiliate_id
);  -- 12-03-2025

SET @CTE_by_master_affiliate_deals_per_affiliate=CONCAT('
UNION ALL
SELECT
	 a.Sub_Affiliate_id
	,ac.username as `Sub Affiliate`
   ,CONCAT(ac.last_name,", ",ac.first_name) AS `LongName`
   ,ifnull(AD.Advertiser_Name,"Any") as Advertiser_Name
	,case when a.Status_id = "1" then "Active" else "Disabled" end as `Status`
	,a.Deal_id
	,d.Deal_Name
	,a.Valid_From
	,a.Valid_To
	,if(ifnull(d.CPA_Value,0)=0,"--",d.CPA_Value)                           AS `CPA_Value`
	,if(ifnull(d.RS_Percentage,0)=0,"--",d.RS_Percentage)                   as `RS_Percentage`
	,if(ifnull(d.Commissions_Percentage,0)=0,"--",d.Commissions_Percentage) as `Commissions_Percentage`
   ,LEFT(IFNULL(a.`Last_Update`,""),16) as `Last Update`   
   ,IFNULL(o.`Username`,"SysOp")        as `Operator` 
	,a.id                                                   -- KF 30.09.2024                      
	,a.Master_Affiliate_id	                                -- KF 13.03.2025				                                                                                
FROM 	master_affiliate_deals_per_affiliate a 
INNER JOIN master_affiliate_deals d ON a.Deal_id = d.id
INNER JOIN account_account ac       ON a.Sub_Affiliate_id = ac.id
LEFT  JOIN account_account o        ON a.Operator = o.id
LEFT  JOIN `campaign_advertiser` AD on a.Advertiser_id=AD.id
WHERE
	a.Status_id = 1 '
   ,@WhereAffiliate_id1
);

SET @CTE=CONCAT('
WITH Table_Data as (
',@CTE_by_referral_id_origin
 ,@CTE_by_master_affiliate_deals_per_affiliate
 ,
'),
Main_Table_Data as (
   SELECT * FROM Table_Data
   GROUP BY id,Sub_Affiliate_id,Advertiser_Name,Valid_From
)
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"width=80px,action=2"     as `Action`
   ,"width=060px"             as `id `
   ,"width=150px"             as `Sub Affiliate`
   ,"width=200px"             as `SubAff name`
   ,"width=150px"             as `Brand`        -- K 11.06.2026
   ,"width=100px,omit=yes"    as `Status`
   ,"width=060px"             as `Deal id`
   ,"width=300px,tooltip=yes" as `Deal`
   ,"width=100px"             as `Valid From`
   ,"width=100px"             as `Valid To`
   ,"width=090px"             as `Value over CPA`
   ,"width=090px"             as `% over RS`
   ,"width=090px"             as `% over Comm`
   ,"width=150px"             as `Updated on`
   ,"width=100px"             as `User`
	,"omit=yes"                as `id`                  -- KF 30.09.2024
	,"omit=yes"                as `Master_Affiliate_id` -- KF 13.03.2025                                                                     
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
order by `Sub Affiliate`,`Valid From` desc
;');

-- ----------------------------------------------------------------------------
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
Ejemplos:

call Report_SubAffiliates('Affiliate_id=440,debug=ye');

*/