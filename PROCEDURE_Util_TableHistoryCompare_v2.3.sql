/* PROCEDURE_Util_TableHistoryCompare.sql
   

Descripción:
  Procedimiento Util_TableHistoryCompare.
01.09.2022 V1     Compara el diseño de dos tablas en dos db distintas. 
                  Genera ALTER para que la TableName1 en DBbase1 quede igual que TableName2 en DBreference
20.09.2022 V2     Optimización
20.09.2022 V2.1   Omite campos Auditoría cuando no es necesario
22.09.2022 V2.2   Campos Auditoría desde modelo db_settings
15.01.2024 v2.3   Validación existencia tablas

Keys:
  TableName1 = [valor]. Parámetro de entrada.
   
   
Parametros (TableName1, DBbase1,TableName2, DBreference)
   
*/
DROP PROCEDURE IF EXISTS Util_TableHistoryCompare;

DELIMITER $$
CREATE PROCEDURE Util_TableHistoryCompare(IN
   TableName1   VARCHAR(50),
   DBbase1      VARCHAR(50)
   )
   COMMENT 'Compara tabla History con su tabla. Genera ALTER'
   LANGUAGE SQL
    
proc_label:BEGIN

-- Defaults
SET @Version         ='v2.3 15.01.2024';
SET @CurrentDay      =curdate();

SET @TableNameRef=TableName1;
SET @TableNameHis=CONCAT(TableName1,'_history');
SET @DBreference=DBbase1;

/*
SET @TableNameRef='super_accounting';
SET @TableNameHis=CONCAT(@TableNameRef,'_history');
SET @DBreference='euroaffiliati2';
SELECT @TableNameRef,@TableNameHis,@DBreference;
*/

-- Validación exitencia tablas
SET @ExistTableNameRef =0;
SET @ExistTableNameRef =(SELECT count(*) FROM `INFORMATION_SCHEMA`.`TABLES` 
                         WHERE TABLE_SCHEMA=@DBreference AND TABLE_NAME = @TableNameHis  AND TABLE_TYPE='BASE TABLE');

-- Select @ExistTableNameRef;

IF @ExistTableNameRef !="1"
THEN LEAVE proc_label;
END IF;

-- ---------------------------------------------------------------
WITH 
SetFieldsTableBase as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.ORDINAL_POSITION,A.COLUMN_DEFAULT,A.EXTRA
         ,IFNULL(B.ORDINAL_POSITION,0) as PREV_FLD_POSITION
         ,IF(B.COLUMN_NAME IS NULL,'FIRST',CONCAT('`',B.COLUMN_NAME,'`')) as PREV_FLD
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   LEFT JOIN `INFORMATION_SCHEMA`.`COLUMNS` B ON B.TABLE_SCHEMA=@DBreference AND B.TABLE_NAME = @TableNameRef 
         AND B.ORDINAL_POSITION=(A.ORDINAL_POSITION-1)
   WHERE A.TABLE_SCHEMA=@DBreference AND A.TABLE_NAME = @TableNameRef
   ORDER BY A.ORDINAL_POSITION
   ),
SetFieldsTableBaseLastRow as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.ORDINAL_POSITION
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   WHERE A.TABLE_SCHEMA=@DBreference AND A.TABLE_NAME = @TableNameRef
   ORDER BY A.ORDINAL_POSITION DESC LIMIT 1
   ),
SetFieldsTableHistory as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.ORDINAL_POSITION,A.COLUMN_DEFAULT,A.EXTRA
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   WHERE A.TABLE_SCHEMA=@DBreference AND A.TABLE_NAME = @TableNameHis -- AND A.COLUMN_NAME NOT LIKE 'Aud_%'
   ORDER BY A.ORDINAL_POSITION
   ),
SetFieldsTableAudit as (
   SELECT A.TABLE_SCHEMA,A.TABLE_NAME,A.COLUMN_NAME,A.COLUMN_TYPE,A.ORDINAL_POSITION,A.COLUMN_DEFAULT,A.EXTRA
   FROM `INFORMATION_SCHEMA`.`COLUMNS` A
   WHERE A.TABLE_SCHEMA='settings_db' AND A.TABLE_NAME ='audit_base_history'
   ORDER BY A.ORDINAL_POSITION
   )

SELECT ALTERCMD FROM (
(
SELECT -- H.COLUMN_NAME,B.COLUMN_NAME,B.COLUMN_TYPE,
	B.ORDINAL_POSITION,B.COLUMN_NAME,
	CONCAT('ALTER TABLE ',@TableNameHis,' ADD COLUMN `',B.COLUMN_NAME,'` ',B.COLUMN_TYPE,' NULL DEFAULT NULL '
	,IF(B.PREV_FLD_POSITION=0,'','AFTER '),B.PREV_FLD,';')  AS 'ALTERCMD'
FROM SetFieldsTableBase B
LEFT JOIN SetFieldsTableHistory H ON B.COLUMN_NAME=H.COLUMN_NAME
WHERE H.COLUMN_NAME IS NULL 
)       
UNION ALL -- Primera pasada
(
SELECT -- H.COLUMN_NAME,B.COLUMN_NAME,B.COLUMN_TYPE,
	B.ORDINAL_POSITION+800,B.COLUMN_NAME,
	CONCAT('ALTER TABLE ',@TableNameHis,' CHANGE COLUMN `',H.COLUMN_NAME,'` `',H.COLUMN_NAME,'` '
	,B.COLUMN_TYPE,' NULL DEFAULT NULL ',
	IF(B.PREV_FLD_POSITION=0,'','AFTER '),B.PREV_FLD,';')  AS ''
FROM SetFieldsTableHistory H
INNER JOIN SetFieldsTableBase B ON B.COLUMN_NAME=H.COLUMN_NAME AND (B.COLUMN_TYPE != H.COLUMN_TYPE OR B.ORDINAL_POSITION != H.ORDINAL_POSITION)
WHERE H.COLUMN_NAME NOT LIKE 'Aud_%'
ORDER BY B.ORDINAL_POSITION
)
UNION ALL -- Campos de Auditoria
(
SELECT -- H.COLUMN_NAME,B.COLUMN_NAME,B.COLUMN_TYPE,
	B.ORDINAL_POSITION+900,B.COLUMN_NAME,
	CONCAT('ALTER TABLE ',@TableNameHis,' CHANGE COLUMN `',H.COLUMN_NAME,'` `',H.COLUMN_NAME,'` '
	,B.COLUMN_TYPE,' NULL DEFAULT ',IFNULL(B.COLUMN_DEFAULT,'NULL'),' ',REPLACE(B.EXTRA,'DEFAULT_GENERATED',''),' AFTER `',L.COLUMN_NAME,'`;')  AS ''
FROM SetFieldsTableHistory H
INNER JOIN SetFieldsTableAudit B ON B.COLUMN_NAME=H.COLUMN_NAME AND B.COLUMN_TYPE != H.COLUMN_TYPE
LEFT JOIN SetFieldsTableBaseLastRow L ON TRUE
WHERE H.COLUMN_NAME LIKE 'Aud_%'
ORDER BY B.ORDINAL_POSITION
)
UNION ALL -- Campos quitados de la Tabla Base
(
SELECT 
   999 AS '',H.COLUMN_NAME,
	CONCAT('ALTER TABLE ',@TableNameHis,' CHANGE COLUMN `',H.COLUMN_NAME,'` `',H.COLUMN_NAME,'` '
	,H.COLUMN_TYPE,' NULL DEFAULT NULL AFTER `',L.COLUMN_NAME,'`;')  AS ''
FROM SetFieldsTableHistory H
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
call Util_TableHistoryCompare('campaign_username','euroaffiliati2');
call Util_TableHistoryCompare('forex_deal_gestor_prod','euroaffiliati2');
call Util_TableHistoryCompare('forex_deal_gestor_prod','euroaffiliati2');

ALTER TABLE account_account_files_history 
	CHANGE COLUMN `Aud_Date` `Aud_Date` datetime(6) NULL DEFAULT
	CURRENT_TIMESTAMP(6) on update CURRENT_TIMESTAMP(6) AFTER Last_Update;
ALTER TABLE `account_account`
	CHANGE COLUMN `Last_Update` `Last_Update1` DATETIME(6) NULL DEFAULT 
	CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) AFTER `Creation_Date`;
*/