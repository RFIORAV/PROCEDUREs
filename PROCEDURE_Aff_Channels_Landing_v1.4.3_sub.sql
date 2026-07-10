/*
PROCEDURE_Aff_Channels_Landing.sql - ReportChannels (account_landing_pages)

Descripción:
  Procedimiento Aff_Channels_Landing.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | Affiliate_id ]. OPCIONAL. Default=ALL
Status_id       =[ALL | Status_id ]. OPCIONAL. Default=ALL
Stat_final      =[ALL | Stat* ]. OPCIONAL. Default=ALL. Stat* es el que se indica con *
Product         =[ALL | Product ]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Aff_Channels_Landing('affiliate_id=39,debug=no');   -- aff
call Aff_Channels_Landing('affiliate_id=829,debug=ye');  -- subaff
call Aff_Channels_Landing('affiliate_id=440,debug=ye');  -- masteraff

26.06.2023 V1     Karen
09.08.2023 v1.1   Karen. Fix CH.`Account_id`
03.05.2024 v1.2.1 Karen: Ahora en los ajustes de la grilla dinámica, se puede añadir la opción "link=yes" 
                  a los settings de los procedures, lo cual indica que el registro es un enlace externo que 
                  se abrirá en una nueva pestaña. 
                  (Solución al error comentado por Riccardo sobre channels en el grupal)
27.05.2024 v1.3   Tratamiento de Subafiliados
12.10.2024 v1.4   Eliminación uso campo account_landing_pages.`nation`
17.01.2025 v1.4.1 Incluye Comparator en url
04.02.2025 v1.4.2 Ajuste del width en la columna "Landing"
24.03.2025 v1.4.3 Karen: Ajuste del width en la columnas "Channel" y "Landing"
*/

DROP PROCEDURE IF EXISTS Aff_Channels_Landing;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Aff_Channels_Landing`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'AFFILIATES - Report Aff_Channels_Landing'
    
proc_label:BEGIN

SET @Version         ='v1.4.3 24.03.2025';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Affiliate_id    ='';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

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

   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =      @v;  END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Affiliate_id,@Debug,@Meta,InputCommLine; END IF;
										 
IF @Month='CM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

SET @Month_Report=@Month;

IF   @Affiliate_id IN ("","ALL")
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

-- Obtiene @Comparator desde tabla util_settings
SET @Comparator=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='Comparator');

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET @AffiliateGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=@Affiliate_id AND  group_id=6);
IF  @AffiliateGroup IS NULL THEN SET @AffiliateGroup=0; END IF;
/*---------------------------------------------------------------------------------*/
 
SET @WhereAffiliate_id='';

IF @Affiliate_id  !="ALL" THEN SET @WhereAffiliate_id=CONCAT(" AND CH.Account_id  =",@Affiliate_id);     END IF;

IF @Debug!="NO" THEN SELECT @WhereAffiliate_id; END IF;

/*---------------------------------------------------------------*/

-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    CH.`id`               
	,CH.`product`
	,CH.`landing_page_name`
   ,case when CH.`Status_id`!=CH.`Stat_aggreg` 
        then case when CH.`Status_id`=1
                  then CH.`Status`
                  else concat(CH.`Status`,"*")
                  end
        else concat(CH.`Status`,"*")
        end                         as `CHStatus`
	,CH.`landing_page_channel`
   ,CASE WHEN CH.`landing_page_url`>" " 
         THEN CONCAT(@Comparator,CH.`landing_page_url`)
         ELSE " " END as `landing_page_url`           -- K 03.05.2024 rf 17.01.2025
	,CH.`Account_id`                 -- 09.08.2023                                                              
FROM account_landing_pages CH
WHERE 1=1 '
   ,@WhereAffiliate_id 
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"omit=yes"                      as `id` 
	,"width=100px"                   as `Product`
	,"width=250px,tooltip=yes"       as `name`
   ,"width=100px"                   as `Status`                     
   ,"width=440px,action=1,link=yes" as `Channel`  -- K 24.03.2025
   ,"width=440px,action=1,link=yes" as `Landing`  -- K 24.03.2025  
   ,"omit=yes"                      as `aff_id`   -- 09.08.2023                                                      
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`
	,MT.* 
FROM Main_Table_Data MT
order by Channel
;');

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
IF  @AffiliateGroup=6 THEN
    SET @SQL=REPLACE(@SQL,"account_landing_pages","sub_account_landing_pages");
END IF;
/*---------------------------------------------------------------------------------*/

IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Aff_Channels_Landing('affiliate_id=39,debug=ye');   -- aff
call Aff_Channels_Landing('affiliate_id=829,debug=ye');  -- subaff
call Aff_Channels_Landing('affiliate_id=440,debug=ye');  -- masteraff

*/
