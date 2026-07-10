/* 
PROCEDURE_Aff_Favorites_v1.1.sql - AFFILIATES - Dash Favorites

Descripción:
  Listado de favoritos del dashboard por affiliate, basado en el menú de auth (auth_menu).
  
Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[id del Affiliate_id]. Obligatorio en la práctica (se usa en el JOIN de favoritos).
Checked         =[YES | NO | ALL]. OPCIONAL. Default=ALL. YES filtra solo marcados (is_checked=1).
Groups          =[Gestor | otro valor]. OPCIONAL. Default=Gestor. Gestor→group_id=2; cualquier otro→group_id=3.
Procedures      =[Procedure | ALL ]. OPCIONAL. Default=ALL. SIN EFECTO en v1.1 (filtro comentado).
Meta            =[No | Yes]. Default [Yes] OPCIONAL. Columna Meta: setting/total/data
Filters         =[Yes | No]. OPCIONAL. Default=No. SIN IMPLEMENTAR en esta versión.
Debug           =[No | Yes | KeyValues]. [No] ejecuta query. [Yes] devuelve SQL sin ejecutar.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Salida (columnas):
  Meta, id, name, route, checked
  (v1.0 devolvía además `procedure`; eliminada al pasar a auth_menu)

Parámetros ('[Key=Value[,...]'])

Ejemplos:

Call Aff_Favorites('Affiliate_id=39,Groups=Gestor,Checked=yes');
Call Aff_Favorites('Affiliate_id=39,Groups=all,Checked=yes');  -- group_id=3 (no Gestor)

15.08.2023 V1.0  Karen. Primera version (dash_favorite + dash_favorite_account)
10.07.2026 v1.1  Karen. Migración a auth_menu/auth_group_menu; orden jerárquico (_sort_path LPAD);
                 Meta total/data según m.type; default Groups=Gestor; filtros Procedures/Groups SQL desactivados

*/

DROP PROCEDURE IF EXISTS Aff_Favorites;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Aff_Favorites`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.1 10.07.2026 Karen. AFFILIATES - Dash Favorites'
    
proc_label:BEGIN

SET @Version         ='v1.1 10.07.2026';
SET @Affiliate_id    ='';
SET @Checked         ='ALL';
SET @Procedures      ='ALL';
SET @Groups          ='Gestor';
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
   IF lower(@k)='checked'         THEN SET @Checked       =      @v;  END IF;
   IF lower(@k)='procedures'      THEN SET @Procedures    =      @v;  END IF;
   IF lower(@k)='groups'          THEN SET @Groups        =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Affiliate_id,@Checked,@Procedures,@Groups,@Debug,@Meta,@Filters,InputCommLine; END IF;

SET @WhereChecked = "";
IF @Checked = "YES" THEN SET @WhereChecked = " AND f.is_checked=1"; END IF;
/*
SET @WhereProcedures = "";
IF @Procedures != "ALL" THEN SET @WhereProcedures = CONCAT(" AND `Procedure` IN ('",@Procedures,"')"); END IF;

SET @WhereGroups = "";
IF @Groups != "ALL" THEN SET @WhereGroups = CONCAT(" AND `Group` IN ('",@Groups,"')"); END IF
*/

-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
         IF( m.type = 1, "total", "data" )     AS Meta
        ,m.id
        ,m.title                                as `name`
        ,m.path                                 as `route`
        ,IF(IFNULL(f.is_checked,0) = 1 , 1, 0) as `checked`
        -- Path de orden: LPAD para que el sort alfabético == numérico
        ,CASE
            -- Raíz (no tiene padre)
            WHEN parent.id IS NULL
                THEN LPAD(m.`order`, 4, "0")
            -- Hijo directo de raíz
            WHEN grandpa.id IS NULL
                THEN CONCAT(LPAD(parent.`order`, 4, "0"), ".", LPAD(m.`order`, 4, "0"))
            -- Nieto (hijo de hijo)
            ELSE
                CONCAT(LPAD(grandpa.`order`, 4, "0"), ".", LPAD(parent.`order`, 4, "0"), ".", LPAD(m.`order`, 4, "0"))
         END AS _sort_path
    FROM
        auth_menu m
        INNER JOIN auth_group_menu g ON m.id = g.menu_id
        LEFT JOIN dash_favorite_account f 
            ON m.id = f.favorite_id 
            AND f.Affiliate_id = ',@Affiliate_id,'
        LEFT JOIN auth_menu parent  
            ON parent.id = m.header_id
        LEFT JOIN auth_menu grandpa 
            ON grandpa.id = parent.header_id
    WHERE
        m.status_id = 1
        AND g.group_id = ',IF(@Groups="GESTOR",2,3),' ',
        @WhereChecked,'
)'
);

SET @SQL=CONCAT(
@CTE,',
Final AS (
    SELECT "setting" AS Meta, "omit=yes" AS id, "width=300px" AS `name`,
           "omit=yes" AS `route`, "omit=yes" AS checked, "" AS _sort_path
    FROM DUAL WHERE @Meta = "YES"
    UNION ALL
    SELECT Meta, id, `name`, `route`, checked, _sort_path
    FROM Main_Table_Data
)
SELECT Meta, id, `name`, `route`, checked
FROM Final
ORDER BY _sort_path ASC
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
Call Aff_Favorites('Affiliate_id=39,Procedures=ALL,Groups=all,Checked=yes');

*/