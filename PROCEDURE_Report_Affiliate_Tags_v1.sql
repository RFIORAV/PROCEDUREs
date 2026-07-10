/*
PROCEDURE_Report_Affiliate_Tags_v1.sql - Reporte de Tags de Affiliates

Descripción:
  Procedimiento Report_Affiliate_Tags.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value debe estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.
 
Affiliate_id    =[ALL | id del Affiliate]. OPCIONAL. Default=ALL.
Status          =[ALL | Active | Inactive]. OPCIONAL. Default=ALL.
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=No.
Meta            =[No | Yes]. [No] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Affiliate_Tags_dev(''); -- Todos los valores de selección por default
call Report_Affiliate_Tags('meta=yes'); -- Todos los valores de selección por default con metadata
call Report_Affiliate_Tags('Affiliate_id=123,status=Active,debug=yes'); 
call Report_Affiliate_Tags('Filters=yes,meta=yes,debug=no'); -- Filtros disponibles
call Report_Affiliate_Tags('Affiliate_id=123,status=Active,meta=yes,debug=no'); 

01.11.2025 v1     Karen. Primera versión operativa
10.04.2026 v1.1   Meta: renombre de label Operator a User
*/

DROP PROCEDURE IF EXISTS Report_Affiliate_Tags;
-- DROP PROCEDURE IF EXISTS Report_Affiliate_Tags_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Affiliate_Tags`(
   IN `InputCommLine` VARCHAR(250)
)
COMMENT 'Report_Tags'
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.1 10.04.2026';
SET @CurrentDay      =curdate();
SET @Affiliate_id    ='ALL';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Status          ='ALL';
SET @Mode            ='gestor';
SET @Meta            ='YES';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
--  @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Affiliate_id,@Status,@Filters,@Debug,@Meta,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Affiliate_id=123,status=Active,meta=yes,Filter=yes
-- @InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET @e=INSTR(@InputCommLine,'=');    				   -- Posición del signo =
   SET @c=INSTR(@InputCommLine,','); 					   -- Posición de la coma
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Key (ej: Affiliate_id)
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- Value (ej: 123)
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);   
	
   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
   IF lower(@k)='status'          THEN SET @Status        =      @v;  END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;
 
IF @Debug!="NO" THEN SELECT @Affiliate_id,@Status,@Filters,@Debug,@Meta,InputCommLine; END IF;

-- --------------------------------------------------------------------------------------------
-- Construcción de condiciones WHERE
SET @WhereStatus     ='';
SET @WhereAffiliate  ='';

IF @Affiliate_id  !="ALL" THEN SET @WhereAffiliate     =CONCAT(" AND t.Affiliate_id   =",@Affiliate_id );  END IF;
IF @Status        !="ALL" THEN SET @WhereStatus        =CONCAT(" AND t.`Status`       ='",@Status,"'");    END IF;

IF @Debug!="NO" THEN SELECT @WhereStatus,@WhereAffiliate; END IF;

-- --------------------------------------------------------------------------------------------
-- Construcción del CTE (Common Table Expression) con los datos principales
SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    t.`id`
   ,l.`Tag`
   ,IF(t.`Status`=1, "Active", "Inactive") as `Status`
   ,t.`Status` as `Status_id`
   ,left(ifnull(t.`Last_Update`,""),19) `Last_Update`
   ,ifnull(t.User,"") as `Operator`  
FROM account_account_tags t
INNER JOIN account_account_tags_list l on t.Tag_id=l.id
WHERE 1=1 '
   ,@WhereAffiliate
   ,@WhereStatus
,')
');

-- --------------------------------------------------------------------------------------------
-- Construcción de metadata para columnas (anchos, acciones, etc.)
SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta,"width=80px,action=2" as Action
   ,"width=050px"   as id
   ,"width=150px"   as Tag
   ,"width=080px"   as Status
   ,"omit=yes"      as Status_id
   ,"width=150px"   as "Last Update"
   ,"width=100px"   as "User"
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

-- --------------------------------------------------------------------------------------------
-- Construcción del SQL principal con datos
SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`,"..." as `Action`,
   MT.* 
FROM Main_Table_Data MT
');

-- --------------------------------------------------------------------------------------------
-- Construcción del SQL para filtros disponibles
SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "1" as "Korder","Status" AS "Key",`Status` AS "Value","Status" AS `CallKey`,`Status_id` AS "CallValue",COUNT(*) AS "Rows" FROM Main_Table_Data GROUP BY `Status`)
;');

IF @Filters!="NO" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

-- --------------------------------------------------------------------------------------------
-- Ejecución del query
IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Report_Affiliate_Tags(''); -- Todos los valores de selección por default
call Report_Affiliate_Tags('meta=yes'); -- Todos los valores de selección por default con metadata
call Report_Affiliate_Tags('Affiliate_id=123,status=Active,debug=yes'); 
call Report_Affiliate_Tags('Filters=yes,meta=yes,debug=no'); -- Filtros disponibles
call Report_Affiliate_Tags('Affiliate_id=123,status=Active,meta=yes,debug=no'); 
*/