/*
PROCEDURE_Fra_info_.sql - Info FRA

Descripción:
  Procedimiento Fra_info.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value debe estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                 [No] NO EJECUTA QUERY y devuelve el código del Query.
                 [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
InputCommLine = [valor]. Parámetro de entrada.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

CALL  Fra_info('');
CALL  Fra_info('debug=YE');

20.02.2026 v1.0  Versión inicial

*/
SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';

-- -----------------------------------------------------
-- DROP PROCEDURE IF EXISTS Fra_info_;
DROP PROCEDURE IF EXISTS Fra_info;
-- -----------------------------------------------------

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Fra_info`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Info FRA'

ProcedureBody: BEGIN
-- --------------------------------------------------------------------------------------------
DECLARE v_Version       VARCHAR(30);
DECLARE v_CurrentDay    DATE;
DECLARE v_LMonth        VARCHAR(7);
DECLARE v_Month         VARCHAR(7);

DECLARE v_Debug         VARCHAR(20);
DECLARE v_Currency      VARCHAR(10);
DECLARE v_InputCommLine VARCHAR(300);

DECLARE v_e             INT;
DECLARE v_c             INT;
DECLARE v_k             VARCHAR(100);
DECLARE v_v             VARCHAR(200);

DECLARE v_Meta          VARCHAR(255);
DECLARE v_Affiliate     VARCHAR(255);
DECLARE v_Curr          VARCHAR(10);
DECLARE v_Estimated     VARCHAR(255);
DECLARE v_Confirmed     VARCHAR(255);
DECLARE v_Confirmed21   VARCHAR(255);

-- Defaults
SET v_Version         ='v1.0 18.03.2026';
SET v_CurrentDay      =curdate();
SET v_LMonth          =left(DATE_SUB(v_CurrentDay, INTERVAL 1 MONTH),7);
SET v_Month           =left(v_CurrentDay,7);

SET v_Debug           ='NO';
SET v_Currency        ='EUR';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

WHILE v_InputCommLine>' ' DO
   SET v_e=INSTR(v_InputCommLine,'=');
   SET v_c=INSTR(v_InputCommLine,',');
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1);
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1));
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='debug'            THEN SET v_Debug           =UPPER(v_v); END IF;

END WHILE;

IF v_Debug!="NO" THEN SELECT v_LMonth,v_Month,v_Debug,v_InputCommLine; END IF;

/********************************************************************
DROP TEMPORARY TABLE IF EXISTS `tmp_balance_by_affiliate`;
CREATE TEMPORARY TABLE IF NOT EXISTS `tmp_balance_by_affiliate` (
   `Meta`               VARCHAR(5) NOT NULL DEFAULT '',
   `Affiliate_id`       INT NOT NULL DEFAULT 0,
   `Affiliate`          VARCHAR(100) NULL DEFAULT NULL,
   `Currency`           VARCHAR(16) NULL DEFAULT NULL,
   `estimated_CM`       DECIMAL(20,2) NULL DEFAULT NULL,
   `Confirmed`          DECIMAL(20,2) NULL DEFAULT NULL,
   `Confirmed21`        DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_CM`       DECIMAL(20,2) NULL DEFAULT NULL,
   `Financial Currency` VARCHAR(16) NULL DEFAULT NULL,
   `Financial Confirmed` DECIMAL(20,2) NULL DEFAULT NULL,
   `Latest_op`          VARCHAR(9) NOT NULL DEFAULT '',
   `Curr`               VARCHAR(3) NULL DEFAULT NULL,
   `Withdraw`           VARCHAR(36) NULL DEFAULT NULL,
   `Status`             VARCHAR(6) NOT NULL DEFAULT '',
   `last_login`         VARCHAR(16) NULL DEFAULT NULL,
   `Estimated`          DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_today`    DECIMAL(20,2) NULL DEFAULT NULL,
   `confirmed_days`     DECIMAL(20,2) NULL DEFAULT NULL,
   INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE
   )
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
**********************************************************/

DROP TABLE IF EXISTS `tmp_balance_by_affiliate`;

CALL Report_balance_by_affiliate('tmptable=yes');

SELECT
   "setting" as Meta
   ,"width=090px,center=true" `Affiliate id`
   ,"width=150px,tooltip=yes" `Affiliate`
   ,"width=100px,tooltip=yes" `First Name`
   ,"width=100px,tooltip=yes" `Last Name`
   ,"width=200px,tooltip=yes" `Email`
   ,"width=150px"             `Phone`
   ,"width=200px,tooltip=yes" `Address`
   ,"width=100px,tooltip=yes" `City`
   ,"width=100px"            `Country`
   ,"width=100px"            `Status`

   -- ,"width=90px"             `Curr`
   ,"width=110px,right=true" `Estimated commision Curr Mnth`
   ,"width=110px,right=true" `Balance Confirmed today`
   ,"width=110px,right=true" `Balance Confirmed Day 20`
   ,"width=110px,right=true" `Balance Confirmed this Month`
   ,"width=110px,center=true" `Latest operation`
   ,"width=50px"              `Cr`
   ,"width=120px,right=true"  `Withdraw last 30 days`
FROM DUAL

union all

SELECT "data" as Meta
      ,a.id as Affiliate_id
      ,a.username as `Affiliate`
      ,a.first_name as `First Name`
      ,a.last_name as `Last Name`
      ,a.email as `Email`
      ,a.phone as `Phone`
      ,a.address as `Address`
      ,a.city as `City`
      ,a.nation as `Country`
      ,a.status as `Status`
      -- ,b.`Currency`
      ,SUM(b.`estimated_CM`) as `estimated_CM`
      ,SUM(b.`Confirmed`) as `Confirmed`
      ,SUM(b.`Confirmed21`) as `Confirmed21`
      ,SUM(b.`confirmed_CM`) as `confirmed_CM`
      ,b.`Latest_op`
      ,b.`Curr`
      ,SUM(b.`Withdraw`) as `Withdraw`
FROM `tmp_balance_by_affiliate` b
INNER JOIN account_account a on b.Affiliate_id=a.id
GROUP BY b.Affiliate_id
ORDER BY `Affiliate` ASC
;

-- SELECT v_Meta AS `Meta`, v_Affiliate AS `Affiliate`, v_Curr AS `Curr`, v_Estimated AS `Estimated`, v_Confirmed AS `Confirmed`, v_Confirmed21 AS `Confirmed21`;

-- SELECT "account_financial_movement","Pending",`Currency`,  SUM(getCurrencyConversion(Amount_Debit,Currency,v_Currency)) AS `Amount_Debit`
-- FROM `account_financial_movement` 
-- WHERE `Status`="0"
-- GROUP BY `Currency`
-- ORDER BY `Currency` ASC;



-- SET v_SQL=CONCAT('
-- SELECT * FROM `tmp_balance_by_affiliate`
-- ;');

-- IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

-- IF v_Debug != "YES" THEN
-- 	PREPARE stmt1 FROM v_SQL;
-- 	EXECUTE stmt1;
-- 	DEALLOCATE PREPARE stmt1;
-- END IF;

END;
$$
DELIMITER ;

-- -----------------------------------------------------
-- -----------------------------------------------------
/*
CALL  Fra_info_('');
CALL  Fra_info_('debug=YE');
*/
