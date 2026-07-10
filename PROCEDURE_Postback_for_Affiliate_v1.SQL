/*
PROCEDURE_Postback_for_Affiliate_v1.sql - Crea los registros para hacer postback

Descripción:
  Procedimiento Postback_for_Affiliate.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month           =[AAAA-MM]. OPCIONAL. Default=Current Month.

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Postback_for_Affiliate(''); 
call Postback_for_Affiliate('debug=yes');
call Postback_for_Affiliate('Month=2025-02,debug=ye');

02.03.2025 V1     Primera versión operativa
06.04.2025        Fix cuando no hay urls en postback_outbound_url
*/

DROP PROCEDURE IF EXISTS Postback_for_Affiliate;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Postback_for_Affiliate`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Create data for Postback to Affiliate'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 30.03.2025';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);

SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

-- --------------------------------------------------------------------------
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
	IF lower(@k)='Month'           THEN SET @Month         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;
-- --------------------------------------------------------------------------
SET @temp_account_ids='';
    
-- Extraer los Account_ids únicos y componerlos en un string
SELECT GROUP_CONCAT(DISTINCT account_id SEPARATOR ', ')
INTO @temp_account_ids
FROM postback_outbound_url
WHERE account_id IS NOT NULL;

IF @temp_account_ids IS NULL THEN SET @temp_account_ids='""'; END IF;

-- --------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `postback_from_DbD_fact2` (
   `id`                          INT           NOT NULL AUTO_INCREMENT,
   `Hour_Update`                 DATETIME      NULL DEFAULT (CURRENT_TIMESTAMP),
   `Affiliate`                   VARCHAR(30)   NULL DEFAULT NULL ,
   `Affiliate_id`                INT           NULL DEFAULT NULL,
   `Date`                        DATE          NULL DEFAULT NULL,
   `Brand`                       VARCHAR(55)   NULL DEFAULT NULL ,
   `Code_To_Affiliate`           VARCHAR(50)   NULL DEFAULT NULL ,
   `Qualified_Players`           INT           NULL DEFAULT NULL,
   `First_Time_Deposit`          INT           NULL DEFAULT '0',
   `Views`                       INT           NULL DEFAULT NULL,
   `Clicks`                      INT           NULL DEFAULT NULL,
   `Signups`                     INT           NULL DEFAULT NULL,
   `Deposits`                    DECIMAL(12,2) NULL DEFAULT '0.00',
   `Depositing_Customers`        INT           NULL DEFAULT NULL,
   `Active_Customers`            INT           NULL DEFAULT NULL,
   `New_Depositing_Customers`    INT           NULL DEFAULT NULL,
   `New_Active_Customers`        INT           NULL DEFAULT NULL,
   `First_Time_Active_Customers` INT           NULL DEFAULT NULL,
   `Turnover`                    DECIMAL(12,2) NULL DEFAULT '0.00',
   `Net_Revenue`                 DECIMAL(12,2) NULL DEFAULT '0.00',
   `CPA_Value_Affiliate`         DECIMAL(12,2) NULL DEFAULT '0.00',
   `Data_Currency`               VARCHAR(10)   NULL DEFAULT 'EUR' ,
   `Post_send_status`            TINYINT       NULL DEFAULT '0',

PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `Snapshot_day_by_day_fact2_4Postback` (
   `Hour_Update`                 DATETIME      NULL DEFAULT (CURRENT_TIMESTAMP),
   `Affiliate`                   VARCHAR(30)   NULL DEFAULT NULL ,
   `Affiliate_id`                INT           NULL DEFAULT NULL,
   `Date`                        DATE          NULL DEFAULT NULL,
   `Brand`                       VARCHAR(55)   NULL DEFAULT NULL ,
   `Code_To_Affiliate`           VARCHAR(50)   NULL DEFAULT NULL ,
   `Qualified_Players`           INT           NULL DEFAULT NULL,
   `First_Time_Deposit`          INT           NULL DEFAULT '0',
   `Views`                       INT           NULL DEFAULT NULL,
   `Clicks`                      INT           NULL DEFAULT NULL,
   `Signups`                     INT           NULL DEFAULT NULL,
   `Deposits`                    DECIMAL(12,2) NULL DEFAULT '0.00',
   `Depositing_Customers`        INT           NULL DEFAULT NULL,
   `Active_Customers`            INT           NULL DEFAULT NULL,
   `New_Depositing_Customers`    INT           NULL DEFAULT NULL,
   `New_Active_Customers`        INT           NULL DEFAULT NULL,
   `First_Time_Active_Customers` INT           NULL DEFAULT NULL,
   `Turnover`                    DECIMAL(12,2) NULL DEFAULT '0.00',
   `Net_Revenue`                 DECIMAL(12,2) NULL DEFAULT '0.00',
   `CPA_Value_Affiliate`         DECIMAL(12,2) NULL DEFAULT '0.00',
   `Data_Currency`               VARCHAR(10)   NULL DEFAULT 'EUR' 
);
    
-- Insertar en Postback_5stars las diferencias para el mes actual y Affiliate_id 909
SET @SQL_insert_postback = CONCAT( '
INSERT INTO postback_from_DbD_fact2 (
    Hour_Update,
    Affiliate,
    Affiliate_id,
    Date,
    Brand,
    Code_To_Affiliate,
    Qualified_Players,
    First_Time_Deposit,
    Views,
    Clicks,
    Signups,
    Deposits,
    Depositing_Customers,
    Active_Customers,
    New_Depositing_Customers,
    New_Active_Customers,
    First_Time_Active_Customers,
    Turnover,
    Net_Revenue,
    CPA_Value_Affiliate,
    Data_Currency
)
WITH DbD_fact2 as (
SELECT  
    `Affiliate`
   ,`Affiliate_id`
   ,`Date`
   ,`Brand`
   ,`Code_To_Affiliate`
   ,SUM(IFNULL(`Qualified_Players`          ,0)) as `Qualified_Players`                   
   ,SUM(IFNULL(`First_Time_Deposit`         ,0)) as `First_Time_Deposit`                  
   ,SUM(IFNULL(`Views`                      ,0)) as `Views`                               
   ,SUM(IFNULL(`Clicks`                     ,0)) as `Clicks`                              
   ,SUM(IFNULL(`Signups`                    ,0)) as `Signups`                             
   ,SUM(IFNULL(`Deposits`                   ,0)) as `Deposits`                            
   ,SUM(IFNULL(`Depositing_Customers`       ,0)) as `Depositing_Customers`                
   ,SUM(IFNULL(`Active_Customers`           ,0)) as `Active_Customers`                    
   ,SUM(IFNULL(`New_Depositing_Customers`   ,0)) as `New_Depositing_Customers`            
   ,SUM(IFNULL(`New_Active_Customers`       ,0)) as `New_Active_Customers`                
   ,SUM(IFNULL(`First_Time_Active_Customers`,0)) as `First_Time_Active_Customers`         
   ,SUM(IFNULL(`Turnover`                   ,0)) as `Turnover`                            
   ,SUM(IFNULL(`Net_Revenue`                ,0)) as `Net_Revenue`                         
   ,SUM(IFNULL(`CPA_Value_Affiliate`        ,0)) as `CPA_Value_Affiliate`                 
   ,`Data_Currency`                       
FROM Snapshot_day_by_day_fact2
-- WHERE Affiliate_id = @Affiliate_id AND LEFT(DATE,7)=@Month
WHERE Affiliate_id IN (',@temp_account_ids,') AND LEFT(DATE,7)=@Month
GROUP BY Date,Brand,Code_To_Affiliate
)
SELECT 
    CURRENT_TIMESTAMP
   ,s.`Affiliate`
   ,s.`Affiliate_id`
   ,s.`Date`
   ,s.`Brand`
   ,s.`Code_To_Affiliate`
   ,s.`Qualified_Players`           - IFNULL(p.`Qualified_Players`          ,0)     
   ,s.`First_Time_Deposit`          - IFNULL(p.`First_Time_Deposit`         ,0)     
   ,s.`Views`                       - IFNULL(p.`Views`                      ,0)     
   ,s.`Clicks`                      - IFNULL(p.`Clicks`                     ,0)     
   ,s.`Signups`                     - IFNULL(p.`Signups`                    ,0)    
   ,s.`Deposits`                    - IFNULL(p.`Deposits`                   ,0)        
   ,s.`Depositing_Customers`        - IFNULL(p.`Depositing_Customers`       ,0)        
   ,s.`Active_Customers`            - IFNULL(p.`Active_Customers`           ,0)        
   ,s.`New_Depositing_Customers`    - IFNULL(p.`New_Depositing_Customers`   ,0)        
   ,s.`New_Active_Customers`        - IFNULL(p.`New_Active_Customers`       ,0)        
   ,s.`First_Time_Active_Customers` - IFNULL(p.`First_Time_Active_Customers`,0)        
   ,s.`Turnover`                    - IFNULL(p.`Turnover`                   ,0)        
   ,s.`Net_Revenue`                 - IFNULL(p.`Net_Revenue`                ,0)        
   ,s.`CPA_Value_Affiliate`         - IFNULL(p.`CPA_Value_Affiliate`        ,0)
   ,s.`Data_Currency`

FROM DbD_fact2 s
LEFT JOIN Snapshot_day_by_day_fact2_4Postback p ON s.Affiliate_id = p.Affiliate_id 
                                               AND s.Code_To_Affiliate=p.Code_To_Affiliate
                                               AND s.Date = p.Date

-- WHERE s.Affiliate_id = @Affiliate_id AND LEFT(s.Date,7)=@Month
WHERE s.Affiliate_id IN (',@temp_account_ids,') AND LEFT(s.DATE,7)=@Month
  AND (
      s.`Qualified_Players`  != IFNULL(p.`Qualified_Players` ,0)                 
   OR s.`First_Time_Deposit` != IFNULL(p.`First_Time_Deposit`,0)                                               
   OR s.`Signups`            != IFNULL(p.`Signups`           ,0)
    )
;');
 
-- Borrar datos existentes en la tabla temporal
-- TRUNCATE TABLE Snapshot_day_by_day_fact2_4Postback;
SET @SQL_delete_mirror_fact2 = CONCAT( '
DELETE FROM Snapshot_day_by_day_fact2_4Postback WHERE Affiliate_id IN (',@temp_account_ids,') AND LEFT(DATE,7)=@Month;
');


-- Copiar los datos actuales de Snapshot_day_by_day_fact2 a la tabla temporal
SET @SQL_insert_mirror_fact2 = CONCAT( '
INSERT INTO Snapshot_day_by_day_fact2_4Postback
SELECT 
    CURRENT_TIMESTAMP 
   ,`Affiliate`
   ,`Affiliate_id`
   ,`Date`
   ,`Brand`
   ,`Code_To_Affiliate`
   ,SUM(IFNULL(`Qualified_Players`          ,0)) as `Qualified_Players`                   
   ,SUM(IFNULL(`First_Time_Deposit`         ,0)) as `First_Time_Deposit`                  
   ,SUM(IFNULL(`Views`                      ,0)) as `Views`                               
   ,SUM(IFNULL(`Clicks`                     ,0)) as `Clicks`                              
   ,SUM(IFNULL(`Signups`                    ,0)) as `Signups`                             
   ,SUM(IFNULL(`Deposits`                   ,0)) as `Deposits`                            
   ,SUM(IFNULL(`Depositing_Customers`       ,0)) as `Depositing_Customers`                
   ,SUM(IFNULL(`Active_Customers`           ,0)) as `Active_Customers`                    
   ,SUM(IFNULL(`New_Depositing_Customers`   ,0)) as `New_Depositing_Customers`            
   ,SUM(IFNULL(`New_Active_Customers`       ,0)) as `New_Active_Customers`                
   ,SUM(IFNULL(`First_Time_Active_Customers`,0)) as `First_Time_Active_Customers`         
   ,SUM(IFNULL(`Turnover`                   ,0)) as `Turnover`                            
   ,SUM(IFNULL(`Net_Revenue`                ,0)) as `Net_Revenue`                         
   ,SUM(IFNULL(`CPA_Value_Affiliate`        ,0)) as `CPA_Value_Affiliate`                 
   ,`Data_Currency`                       
FROM Snapshot_day_by_day_fact2
-- WHERE Affiliate_id = @Affiliate_id AND LEFT(DATE,7)=@Month
WHERE Affiliate_id IN (',@temp_account_ids,') AND LEFT(DATE,7)=@Month
GROUP BY Date,Brand,Code_To_Affiliate;'
);

IF @Debug!="NO" THEN SELECT @Month,@temp_account_ids; END IF;
IF @Debug!="NO" THEN SELECT @SQL_insert_postback;     END IF;
IF @Debug!="NO" THEN SELECT @SQL_delete_mirror_fact2; END IF;
IF @Debug!="NO" THEN SELECT @SQL_insert_mirror_fact2; END IF;

IF @Debug != "YES" THEN

	PREPARE stmt1 FROM @SQL_insert_postback;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

	PREPARE stmt1 FROM @SQL_delete_mirror_fact2;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

	PREPARE stmt1 FROM @SQL_insert_mirror_fact2;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

END IF;
    
END $$

DELIMITER ;

/*
Por favor, escribir un stored procedure (que va a ejecutarse periódicamente) que tenga en cuenta lo siguiente:
1) Los datos de origen están en `Snapshot_day_by_day_fact2`
2) El proceso se aplica a `Date` correspondiente al mes actual y `Affiliate_id`=909
3) La tarea consiste en insertar en la tabla Postback_5stars la diferencia de aquellos datos que hayan cambiado en `Snapshot_day_by_day_fact2` desde la última vez que se ha ejecutado el proceso
4) Si es necesario crea una tabla adicional y espejo de `Snapshot_day_by_day_fact2` con los datos de la ejecución anterior para basar la comparación con los datos actuales.
5) Los datos cuya diferencia deben considerarse son: `Qualified_Players`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`,`Deposits`,`Depositing_Customers`,`Active_Customers`,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`,`CPA_Value_Affiliate`
6) La estructura de las tablas es:


Por favor, escribir un escribir un stored procedure mysql 8 que extraiga los distintos Account_id de la tabla `postback_outbound_url`
y componga un string con con todos los Account_id separados por coma y entre paréntesis como en la sentencia IN (...)

CREATE TABLE `postback_outbound_url` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `account_id` INT NULL DEFAULT NULL,
   `url` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `created_at` DATETIME(6) NULL DEFAULT NULL,
   `last_update` DATETIME(6) NULL DEFAULT NULL,
   `is_active` TINYINT(1) NOT NULL,
   `type` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
)
;
*/