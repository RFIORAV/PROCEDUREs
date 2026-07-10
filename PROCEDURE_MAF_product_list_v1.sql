/*
PROCEDURE_MAF_product_list.sql - Lista de productos para Deals

Descripción:
  Procedimiento MAF_product_list.
   Obtiene la lista de productos utilizados en sub_Snapshot_day_by_day_fact3

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

MasterAff_id    =[MasterAff_id]. Default=''
Brand           =[ALL | NOMBRE de Brand]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call MAF_product_list('MasterAff_id=440');

26.06.2024 v1     Primera versión operativa

*/

DROP PROCEDURE IF EXISTS MAF_product_list;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `MAF_product_list`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'MAF product list'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 26.06.2024';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Mode            ='';
SET @MasterAff_id    ='';
SET @Brand           ='ALL';

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

   IF lower(@k)='MasterAff_id'    THEN SET @MasterAff_id    = @v;       END IF;
   IF lower(@k)='Brand'           THEN SET @Brand           =UPPER(@v); END IF;

   IF lower(@k)='filters'         THEN SET @Filters         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta            =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug           =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @MasterAff_id,@Brand,@Month,@Debug,@Meta,InputCommLine; END IF;
                     
-- MasterAff_id OBLIGATORIO 
IF  @MasterAff_id IN ("","ALL") THEN
    Select 'data' as Meta,'MasterAff_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET @MasterAffGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=@MasterAff_id AND group_id=4);
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

-- MasterAff_id OBLIGATORIO 
IF  @MasterAffGroup=0 THEN
    Select 'data' as Meta,CONCAT(@MasterAff_id,' is not Master Aff') as '' from dual;
    LEAVE proc_label;
END IF; 

SET @WhereBrand='';  
IF @Brand NOT IN ("ALL","") THEN 
   SET @WhereBrand=CONCAT(' AND Brand="',@Brand,'" ');
END IF; 

/**************************************************************************************************************/

SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
   Product,Product_real
FROM sub_Snapshot_day_by_day_fact3 F
WHERE Product>"" '
   ,@WhereAffiliate_list
   ,@WhereBrand,
'
GROUP BY Product_real,Product)
');

SET @SQL=CONCAT(
@CTE,
'
SELECT Product,Product_real
FROM Main_Table_Data MT
ORDER BY Product_real,Product
;');

IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call MAF_product_list('MasterAff_id=440,brand=all,debug=ye');
call MAF_product_list('MasterAff_id=440,brand=BetClic,debug=ye');

call MAF_product_list('debug=ye');                     -- error: MasterAff_id obligatorio
call MAF_product_list('MasterAff_id=2,debug=ye');      -- error: MasterAff_id incorrecto


*/
