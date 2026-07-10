/*
PROCEDURE_Analisys_customer_report_genfile_v1.sql

Descripción:
  Procedimiento PROCEDURE_Analisys_customer_report_genfile_v1.

Keys:

Tabla destino: customer_report_API_4_analysis
Objetivo: Regenerar la tabla de análisis de customer report a partir de players_netrefer_API,
          cruzando con marketing sources, deals y affiliates.
          Sirve de tabla fuente para Analisys_customer_report().

Uso:
  CALL Analisys_customer_report_genfile();

Version history:
  20.02.2026 v1.0  Conversión a stored procedure del script CREATE TABLE original
  20.02.2026 v1.1  Convierte Signup_Date y CPA_Processed_Date de DD-MM-YYYY a YYYY-MM-DD (DATE)
*/

SET NAMES 'utf8mb4' ;

DROP PROCEDURE IF EXISTS Analisys_customer_report_genfile;

DELIMITER $$
CREATE PROCEDURE Analisys_customer_report_genfile()
  COMMENT 'Regenera customer_report_API_4_analysis desde players_netrefer_API + campaign data v1'
BEGIN
  SET @Version = 'v1.1 20.02.2026';

CREATE TABLE IF NOT EXISTS `customer_report_API_4_analysis` (
   `Date` DATE NULL DEFAULT NULL,
   `MS_id` INT NULL DEFAULT '0',
   `Affiliate` VARCHAR(100) NOT NULL DEFAULT '' ,
   `Affiliate_id` BIGINT NOT NULL DEFAULT '0',
   `Brand` VARCHAR(50) NULL DEFAULT NULL ,
   `Username` VARCHAR(50) NULL DEFAULT NULL ,
   `Username_id` INT NULL DEFAULT NULL,
   `Product` VARCHAR(50) NULL DEFAULT NULL ,
   `Customer_ID` VARCHAR(50) NULL DEFAULT NULL ,
   `Customer_alias` VARCHAR(50) NULL DEFAULT NULL ,
   `Country` VARCHAR(50) NULL DEFAULT NULL ,
   `Signup_Date` DATE NULL DEFAULT NULL,
   `Reward_Plan` VARCHAR(50) NULL DEFAULT NULL ,
   `Tracker_Name` VARCHAR(50) NULL DEFAULT NULL ,
   `Tracker_id` VARCHAR(50) NULL DEFAULT NULL ,
   `Customer_Level` VARCHAR(50) NULL DEFAULT NULL ,
   `CPA_Processed_Date` DATE NULL DEFAULT NULL,
   `Gross_Revenue` VARCHAR(50) NULL DEFAULT NULL ,
   `Deposits` VARCHAR(50) NULL DEFAULT NULL ,
   `Turnover` VARCHAR(50) NULL DEFAULT NULL ,
   `Payouts` VARCHAR(50) NULL DEFAULT NULL ,
   `Transactions` VARCHAR(50) NULL DEFAULT NULL ,
   `Total_Net_Revenue` VARCHAR(50) NULL DEFAULT NULL ,
   `Total_Net_Revenue_MTD` VARCHAR(50) NULL DEFAULT NULL ,
   `Deal_Aff_id` INT NULL DEFAULT '0',
   `CPA_Value` DECIMAL(12,2) NULL DEFAULT '0.00',
   `RS_Percentage` DECIMAL(12,2) NULL DEFAULT '0.00',
   `Baseline` INT NULL DEFAULT '20',
   INDEX `Signup_Date` (`Signup_Date`) USING BTREE,
   INDEX `CPA_Processed_Date` (`CPA_Processed_Date`) USING BTREE,
   INDEX `Username` (`Username`) USING BTREE,
   INDEX `Customer_ID` (`Customer_ID`) USING BTREE
)
ENGINE=InnoDB
;
  TRUNCATE TABLE customer_report_API_4_analysis;
  ALTER TABLE `customer_report_API_4_analysis` DISABLE KEYS;

  INSERT IGNORE INTO customer_report_API_4_analysis
  SELECT
    `Date`,
    M.id AS MS_id,
    IFNULL(`A`.`username`, '_Unassigned') AS `Affiliate`,
    IFNULL(`A`.`id`, 1)                   AS `Affiliate_id`,
    D.`Advertiser`                          AS `Brand`,
    D.`Username`,
    D.`Username_id`,
    D.`Prodotto`                            AS Product,
    D.`Customer_Reference_ID`               AS `Customer_ID`,
    D.`Alias`                               AS `Customer_alias`,
    D.`Country`,
    CASE WHEN D.`Signup_Date` REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
         THEN STR_TO_DATE(D.`Signup_Date`, '%d-%m-%Y') END AS `Signup_Date`,
    D.`Reward_Plan`,
    D.`Marketing_Source_Name`               AS Tracker_Name,
    D.`Marketing_Source_ID`                 AS Tracker_id,
    D.`Customer_Level`,
    CASE WHEN D.`CPA_Processed_Date` REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
         THEN STR_TO_DATE(D.`CPA_Processed_Date`, '%d-%m-%Y') END AS `CPA_Processed_Date`,
    D.`Gross_Revenue`,
    D.`Deposits`,
    D.`Turnover`,
    D.`Payouts`,
    D.`Transactions`,
    D.`Total_Net_Revenue`,
    D.`Total_Net_Revenue_MTD`,
    CDA.`id`            AS `Deal_Aff_id`,
    CDA.`CPA_Value`     AS `CPA_Value`,
    CDA.`RS_Percentage` AS `RS_Percentage`,
    CDA.`Baseline`      AS `Baseline`
  FROM players_netrefer_API D
  /* ---- Selección MS ---- */
  LEFT JOIN LATERAL (
    SELECT
      CASE WHEN M.Tracker_ID = Marketing_Source_ID AND M.Tracker_Name = Marketing_Source_Name THEN 4
           WHEN M.Tracker_ID = Marketing_Source_ID THEN 3
           WHEN M.Tracker_Name = Marketing_Source_Name THEN 2
           ELSE 1
      END AS MatchValue,
      M.*
    FROM campaign_marketing_source M
    WHERE M.Username_id = D.Username_id
      AND (Marketing_Source_ID   IN (M.Tracker_ID, M.Tracker_Name)
        OR Marketing_Source_Name IN (M.Tracker_ID, M.Tracker_Name))
    ORDER BY MatchValue DESC
    LIMIT 1
  ) AS M ON TRUE
  /* ---- Selección de Affiliate ---- */
  LEFT JOIN LATERAL (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY MS_id
                                 ORDER BY Deal_Valid_From DESC, id DESC) AS RowNr
    FROM `campaign_mkt_source_deal`
    WHERE `MS_id` = M.id
      AND `is_active` = 1
      AND `Deal_Valid_From` <= CURDATE()
    ORDER BY RowNr
    LIMIT 1
  ) AS M2 ON TRUE
  LEFT JOIN `account_account` `A`          ON `A`.`id`   = `M2`.`Affiliate_id`
  LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id` = M.`Deal_id`
  
  WHERE RIGHT(`Signup_Date`,4) >= '2025' 
  ;

  ALTER TABLE `customer_report_API_4_analysis` ENABLE KEYS;

END$$
DELIMITER ;

/*

ALTER TABLE `customer_report_API_4_analysis`
   ADD INDEX `Username_id` (`Username_id`),
   ADD INDEX `Customer_ID` (`Customer_ID`),
   ADD INDEX `Signup_Date` (`Signup_Date`),
   ADD INDEX `CPA_Processed_Date` (`CPA_Processed_Date`);
*/
