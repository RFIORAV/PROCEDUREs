/*
PROCEDURE_Report_Comm_Groups.sql - Reports Communication Groups

Descripción:
  Procedimiento Report_Comm_Groups.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Type_content     =[tipo de contenido]
Type_via         =[tipo de vía]
Status           =[status]
Filters          =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta             =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug            =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Comm_Groups('filters=yes,Mode=Gestor');


17.02.2024 V1     Karen. Primera versión operativa
*/

DROP PROCEDURE IF EXISTS Report_Comm_Groups;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Comm_Groups`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Communication Groups'
proc_label:BEGIN


SET @Version         ='v1.0 17.02.2024';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Type_content    ='all';
SET @Type_via        ='all';
SET @Status_id       ='all';
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

   IF lower(@k)='Type_content'    THEN SET @Type_content  =      @v;  END IF;
   IF lower(@k)='Type_via'        THEN SET @Type_via      =      @v;  END IF;
   IF lower(@k)='Status'          THEN SET @Status_id     =      @v;  END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@Type_content,@Type_via,@Status_id,@Debug,@Meta,InputCommLine; END IF;

SET @WhereTypeContent ='';
SET @WhereTypeVia     ='';
SET @WhereStatus      ='';

IF @Type_content  !="ALL" THEN SET @WhereTypeContent =CONCAT(" AND g.Type_Content =",@Type_content); END IF;

IF @Type_via      !="ALL" THEN SET @WhereTypeVia=CONCAT(" AND g.Type_Via =",@Type_via); END IF;

IF @Status_id     !="ALL" THEN SET @WhereStatus    =CONCAT(" AND g.Status ='",@Status_id,"'"); END IF;

IF @Debug!="NO" THEN SELECT @WhereTypeContent,@WhereTypeVia,@WhereStatus; END IF;



SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT
	 g.id
	,g.`Name`
	,c.`Name` as content
	,v.`Name` as via
	,count(gc.id) as participants
	,g.`Status`
	,g.Type_Via
	,g.Type_Content
FROM comm_group g
LEFT JOIN comm_group_channel gc ON g.id = gc.Group_id and gc.`Status`="Active"
INNER JOIN comm_type_via v ON g.Type_Via = v.id
INNER JOIN comm_type_content c ON g.Type_Content = c.id
WHERE 1=1 '
   ,@WhereTypeVia
   ,@WhereTypeContent
   ,@WhereStatus 
,' GROUP BY g.id )');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta
	,"width=80px,action=2"     as `Action`
   ,"width=50px"              as `id` 
   ,"width=150px,tooltip=yes" as `Group Name`
   ,"width=150px"             as `Type Content`   
   ,"width=150px"             as `Type Via`
   ,"width=120px"             as `Participants`
   ,"width=90px"              as `Status`
	,"omit=yes"               as `id_Type_Content`
	,"omit=yes"               as `id_Type_Via`
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

order by id DESC
;');


SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "01" as "Korder","Status" AS "Key",`Status` AS "Value","Status" AS `CallKey`,`Status` AS "CallValue",COUNT(*) AS "Rows" FROM Main_Table_Data GROUP BY `Status`)UNION ALL
(SELECT "02","Type Content"    ,`content`    ,"Type_content",`Type_content`,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Type_content`,"")>"" GROUP BY IFNULL(`Type_content`,"")) UNION ALL
(SELECT "03","Type Via"    ,`via`    ,"Type_via",`Type_via`,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Type_via`,"")>"" GROUP BY IFNULL(`Type_via`,"")) 
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