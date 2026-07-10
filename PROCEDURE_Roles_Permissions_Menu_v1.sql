/*
PROCEDURE_Roles_Permissions_Menu_v1.sql - Roles_Permissions_Menu

Descripción:
  Procedimiento Roles_Permissions_Menu.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Group_id        =[ Group_id ]. OBLIGATORIO. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Roles_Permissions_Menu('Group_id=2,debug=yes');

07.09.2023 V1     Karen: Primera versión operativa

*/

DROP PROCEDURE IF EXISTS Roles_Permissions_Menu;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Roles_Permissions_Menu`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Roles Permissions Menu'
    
proc_label:BEGIN
-- Defaults
SET @Version         ='v1.0 07.09.2023';
SET @Group_id    		='';
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

   IF lower(@k)='group_id'        THEN SET @Group_id      =@v;        END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@View,@Group_id,@Debug,@Meta,InputCommLine; END IF;

/**************************************************************************************************************/

SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
     ath.`id`   
	 ,ath.`icon` 
	 ,ath.`title`
	 ,IF(ath.`status_id` IS NULL, 0, ath.`status_id`)
	 ,header_id
FROM `auth_menu` ath
INNER JOIN auth_group_menu m ON ath.id = m.menu_id
WHERE type=0 and group_id=' ,@Group_id,' )'
);

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"omit=yes"                as `id` 
	,"width=40px,action=2"     as `...`
	,"width=300px"             as `Menu`
	,"omit=yes"                as `checked`
	,"omit=yes"                as `order`
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
order by CAST(`order` AS SIGNED)
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
call Roles_Permissions_Menu('Group_id=2,debug=ye');
*/
