/* PROCEDURE_Util_TableCompareFields_v2.4.sql

Descripción:
  Procedimiento Util_TableCompareFields.
  Compara el diseño de dos tablas (referencia vs destino) y genera ALTER para
  que TableName2 en DBtable2 quede igual que TableName1 en DBtable1.
  Detecta: columnas de más o de menos, tipo, NULL, DEFAULT, EXTRA y orden.

Parámetros:
  TableName1 = Tabla de referencia (modelo a imitar).
  DBtable1   = Base de datos de la tabla de referencia.
  TableName2 = Tabla a ajustar.
  DBtable2   = Base de datos de la tabla a ajustar.

Ejemplos:
  call Util_TableCompareFields('campaign_marketing_source','euroaffiliati2','campaign_marketing_source','affiliaterevolution');

25.01.2023 V1     Compara el diseño de dos tablas en la misma o distinta db.
06.02.2023 v2     Compara tablas de distinta DB
15.02.2023 v2.1   Tratamiento de los defaults
28.02.2023 v2.2
14.01.2024 v2.3   Validación existencia tablas
23.06.2026 v2.4   Detección completa: tipo, NULL, DEFAULT, EXTRA y columnas de más/menos
*/
DROP PROCEDURE IF EXISTS Util_TableCompareFields;

DELIMITER $$
CREATE PROCEDURE Util_TableCompareFields(IN
   TableName1   VARCHAR(50),
   DBtable1     VARCHAR(50),
   TableName2   VARCHAR(50),
   DBtable2     VARCHAR(50)
   )
   COMMENT 'v2.4 23.06.2026 Compara estructura de tablas. Genera ALTER'
   LANGUAGE SQL

proc_label:BEGIN

-- Defaults
SET @Version         ='v2.4 23.06.2026';
SET @CurrentDay      =curdate();

SET @TableNameRef=TableName1;
SET @TableNameComp=TableName2;
SET @DBref=DBtable1;
SET @DBcomp=DBtable2;

-- Validación existencia tablas
SET @ExistTableNameRef =0;
SET @ExistTableNameComp=0;
SET @ExistTableNameRef =(SELECT count(*) FROM `INFORMATION_SCHEMA`.`TABLES`
                         WHERE TABLE_SCHEMA=@DBref  AND TABLE_NAME = @TableNameRef  AND TABLE_TYPE='BASE TABLE');
SET @ExistTableNameComp=(SELECT count(*) FROM `INFORMATION_SCHEMA`.`TABLES`
                         WHERE TABLE_SCHEMA=@DBcomp AND TABLE_NAME = @TableNameComp AND TABLE_TYPE='BASE TABLE');

IF @ExistTableNameRef !="1" OR @ExistTableNameComp !="1"
THEN LEAVE proc_label;
END IF;

-- ---------------------------------------------------------------------------
WITH
SetFieldsTableBase as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.DATA_TYPE,A.ORDINAL_POSITION,A.COLUMN_DEFAULT,A.IS_NULLABLE,A.EXTRA
         ,IFNULL(B.ORDINAL_POSITION,0) as PREV_FLD_POSITION
         ,IF(B.COLUMN_NAME IS NULL,'FIRST',CONCAT('`',B.COLUMN_NAME,'`')) as PREV_FLD
         ,CASE WHEN A.IS_NULLABLE="YES" THEN ' NULL'  ELSE ' NOT NULL' END AS `Nullable`
         ,CASE
            WHEN A.COLUMN_DEFAULT IS NOT NULL THEN
               CASE WHEN A.DATA_TYPE IN ('varchar','char','text','tinytext','mediumtext','longtext','enum','set')
                    THEN CONCAT(" DEFAULT '",REPLACE(A.COLUMN_DEFAULT,"'","''"),"' ")
                    ELSE CONCAT(" DEFAULT ",A.COLUMN_DEFAULT," ")
               END
            WHEN A.IS_NULLABLE = 'YES' THEN ' DEFAULT NULL '
            ELSE ''
          END as `ColDefault`
         ,CASE WHEN IFNULL(A.EXTRA,'')='' THEN '' ELSE CONCAT(REPLACE(A.EXTRA,'DEFAULT_GENERATED',''),' ') END
               AS `ColDefaultExtra`
         ,CASE
            WHEN A.COLUMN_DEFAULT IS NOT NULL THEN CONCAT('D:', LOWER(TRIM(A.COLUMN_DEFAULT)))
            WHEN A.IS_NULLABLE = 'YES' THEN 'D:__IMPLICIT_NULL__'
            ELSE 'D:__NONE__'
          END AS DefNorm
         ,LOWER(TRIM(REPLACE(REPLACE(IFNULL(A.EXTRA,''),'DEFAULT_GENERATED',''),'  ',' '))) AS ExtraNorm
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   LEFT JOIN `INFORMATION_SCHEMA`.`COLUMNS` B ON B.TABLE_SCHEMA=@DBref AND B.TABLE_NAME = @TableNameRef
         AND B.ORDINAL_POSITION=(A.ORDINAL_POSITION-1)
   WHERE A.TABLE_SCHEMA=@DBref AND A.TABLE_NAME = @TableNameRef
   ORDER BY A.ORDINAL_POSITION
   ),
SetFieldsTableBaseLastRow as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.ORDINAL_POSITION
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   WHERE A.TABLE_SCHEMA=@DBref AND A.TABLE_NAME = @TableNameRef
   ORDER BY A.ORDINAL_POSITION DESC LIMIT 1
   ),
SetFieldsTableComp as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.DATA_TYPE,A.ORDINAL_POSITION,A.COLUMN_DEFAULT,A.IS_NULLABLE,A.EXTRA
         ,IFNULL(B.ORDINAL_POSITION,0) as PREV_FLD_POSITION
         ,IF(B.COLUMN_NAME IS NULL,'FIRST',CONCAT('`',B.COLUMN_NAME,'`')) as PREV_FLD
         ,CASE WHEN A.IS_NULLABLE="YES" THEN ' NULL'  ELSE ' NOT NULL' END AS `Nullable`
         ,CASE
            WHEN A.COLUMN_DEFAULT IS NOT NULL THEN
               CASE WHEN A.DATA_TYPE IN ('varchar','char','text','tinytext','mediumtext','longtext','enum','set')
                    THEN CONCAT(" DEFAULT '",REPLACE(A.COLUMN_DEFAULT,"'","''"),"' ")
                    ELSE CONCAT(" DEFAULT ",A.COLUMN_DEFAULT," ")
               END
            WHEN A.IS_NULLABLE = 'YES' THEN ' DEFAULT NULL '
            ELSE ''
          END as `ColDefault`
         ,CASE WHEN IFNULL(A.EXTRA,'')='' THEN '' ELSE CONCAT(REPLACE(A.EXTRA,'DEFAULT_GENERATED',''),' ') END
               AS `ColDefaultExtra`
         ,CASE
            WHEN A.COLUMN_DEFAULT IS NOT NULL THEN CONCAT('D:', LOWER(TRIM(A.COLUMN_DEFAULT)))
            WHEN A.IS_NULLABLE = 'YES' THEN 'D:__IMPLICIT_NULL__'
            ELSE 'D:__NONE__'
          END AS DefNorm
         ,LOWER(TRIM(REPLACE(REPLACE(IFNULL(A.EXTRA,''),'DEFAULT_GENERATED',''),'  ',' '))) AS ExtraNorm
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   LEFT JOIN `INFORMATION_SCHEMA`.`COLUMNS` B ON B.TABLE_SCHEMA=@DBref AND B.TABLE_NAME = @TableNameRef
         AND B.ORDINAL_POSITION=(A.ORDINAL_POSITION-1)
   WHERE A.TABLE_SCHEMA=@DBcomp AND A.TABLE_NAME = @TableNameComp
   ORDER BY A.ORDINAL_POSITION
   )

SELECT ALTERCMD as `-- ALTERCMD` FROM (
(
-- Columnas presentes en referencia y ausentes en destino
SELECT
   B.ORDINAL_POSITION,B.COLUMN_NAME,
   CONCAT('ALTER TABLE ',@DBcomp,'.',@TableNameComp,' ADD COLUMN `',B.COLUMN_NAME,'` ',B.COLUMN_TYPE
   ,B.`Nullable`,B.`ColDefault`,B.`ColDefaultExtra`
   ,IF(B.PREV_FLD_POSITION=0,'','AFTER '),B.PREV_FLD,';')  AS 'ALTERCMD'
FROM SetFieldsTableBase B
LEFT JOIN SetFieldsTableComp H ON B.COLUMN_NAME=H.COLUMN_NAME
WHERE H.COLUMN_NAME IS NULL
)
UNION ALL
(
-- Columnas existentes en ambas con diferencias de tipo, NULL, DEFAULT, EXTRA u orden
SELECT
   B.ORDINAL_POSITION+800,B.COLUMN_NAME,
   CONCAT('ALTER TABLE ',@DBcomp,'.',@TableNameComp,' CHANGE COLUMN `',H.COLUMN_NAME,'` `',H.COLUMN_NAME,'` '
   ,B.COLUMN_TYPE
   ,B.`Nullable`,B.`ColDefault`,B.`ColDefaultExtra`
   ,IF(B.PREV_FLD_POSITION=0,'','AFTER '),B.PREV_FLD,';')  AS ''
FROM SetFieldsTableComp H
INNER JOIN SetFieldsTableBase B ON B.COLUMN_NAME=H.COLUMN_NAME
   AND (
        B.COLUMN_TYPE   != H.COLUMN_TYPE
     OR B.IS_NULLABLE  != H.IS_NULLABLE
     OR B.DefNorm       != H.DefNorm
     OR B.ExtraNorm     != H.ExtraNorm
     OR B.ORDINAL_POSITION != H.ORDINAL_POSITION
   )
WHERE H.COLUMN_NAME NOT LIKE 'Aud_%'
ORDER BY B.ORDINAL_POSITION
)
UNION ALL
(
-- Columnas en destino que no existen en referencia
SELECT
   999 AS '',H.COLUMN_NAME,
   CONCAT('ALTER TABLE ',@DBcomp,'.',@TableNameComp,' DROP COLUMN `',H.COLUMN_NAME,'`;')  AS ''
FROM SetFieldsTableComp H
LEFT JOIN SetFieldsTableBase B ON B.COLUMN_NAME=H.COLUMN_NAME
LEFT JOIN SetFieldsTableBaseLastRow L ON TRUE
WHERE B.COLUMN_NAME IS NULL AND H.COLUMN_NAME NOT LIKE 'Aud_%'
)
) AS X ORDER BY ORDINAL_POSITION,COLUMN_NAME
;

END$$
DELIMITER ;

/*
-- TEST --------------
call Util_TableCompareFields('campaign_advertiser'       ,'euroaffiliati2','forex_advertiser'        ,'hubaffiliations');
call Util_TableCompareFields('campaign_username'         ,'euroaffiliati2','campaign_username',		  'hubaffiliations');
call Util_TableCompareFields('campaign_campaign'         ,'euroaffiliati2','forex_campaign'          ,'hubaffiliations');
call Util_TableCompareFields('campaign_deal_affiliate'   ,'euroaffiliati2','forex_deal_affiliate'    ,'hubaffiliations');
call Util_TableCompareFields('campaign_deal_marketplace' ,'euroaffiliati2','forex_deal_marketplace'  ,'hubaffiliations');
call Util_TableCompareFields('campaign_marketing_source' ,'euroaffiliati2','forex_marketing_source'  ,'affiliaterevolution');
call Util_TableCompareFields('campaign_marketing_source' ,'euroaffiliati2','campaign_marketing_source'  ,'affiliaterevolution');
*/
