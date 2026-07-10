/**
	PROCEDURE_total_monthy_comm_aff_upd_v5.6.sql

Descripción:
  Procedimiento total_monthy_comm_aff_upd.
	**	Actualiza TABLA view_monthly_fact_aff4

Keys:
  p_month = [valor]. Parámetro de entrada.

   15.03.2023 v4     Utiliza PROCEDURE monthly_comms_affiliate
   11.01.2024 v4.1   Tratamiento de Referral/subaffiliates
   04.08.2024 v4.2   Pasa Data_Currency desde monthly_comms_affiliate_v5 a view_monthly_fact_aff4
   02.11.2024 v4.2.1 Adecua comision referrer sobre `net_Total_comm` (sin CPA ni RS) para pasar a logica de view_monthly_fact_aff4
   20.11.2024 v4.3   Adecuación a Owner en monthly_comms_affiliate_v5
   10.09.2025 v5.6   Agregado parámetro de entrada para mes específico en formato YYYY-MM
*/

DROP PROCEDURE IF EXISTS total_monthy_comm_aff_upd;
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE total_monthy_comm_aff_upd(IN p_month VARCHAR(7))
COMMENT 'TABLA view_monthly_fact_aff4 desde tabla monthly_comms_affiliate con parámetro de mes'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

BEGIN
-- Defaults
SET @Version         ='v5.6 10.09.2025';
SET @CurrentDay      =curdate();

-- Validar y establecer el mes a procesar
-- Si el parámetro viene informado y es válido (formato YYYY-MM), lo usa
-- Si no, usa CURDATE() como fallback
SET @LMonth = CASE 
    WHEN p_month IS NOT NULL 
         AND p_month REGEXP '^[0-9]{4}-[0-9]{2}$' 
         AND STR_TO_DATE(CONCAT(p_month, '-01'), '%Y-%m-%d') IS NOT NULL
    THEN p_month
    ELSE LEFT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH),7)
END;

IF CURDATE()<='2024-12-07' THEN
   DROP TABLE IF EXISTS `view_monthly_fact_aff4`; 
END IF;

CREATE TABLE IF NOT EXISTS `view_monthly_fact_aff4` (
   `Owner`                    VARCHAR(150)  NULL DEFAULT ''
   ,`Area`                    VARCHAR(150)  NULL DEFAULT 'gaming'
   ,`DATE`                    VARCHAR(7)    NULL DEFAULT '0000-00'
   ,`Affiliate`               VARCHAR(150)  NULL DEFAULT ''
   ,`Affiliate_id`            INT(10)       NULL DEFAULT '0'
   ,`Brand`                   VARCHAR(150)  NULL DEFAULT ''
   ,`Advertiser_id`           INT(10)       NULL DEFAULT '0'
   ,`Username`                VARCHAR(150)  NULL DEFAULT ''
   ,`Username_id`             INT(10)       NULL DEFAULT '0'
   ,`Channel_id`              INT(10)       NULL DEFAULT '0'
   ,`Channel`                 VARCHAR(150)  NULL DEFAULT ''
   ,`Channel_Name`            VARCHAR(150)  NULL DEFAULT ''
   ,`Product`                 VARCHAR(150)  NULL DEFAULT ''
   ,`Product_real`            VARCHAR(150)  NULL DEFAULT ''
   ,`Data_Currency`           VARCHAR(150)  NULL DEFAULT 'EUR'
   ,`CPA`                     DECIMAL(12,0) NULL DEFAULT '0'
   ,`CPA_Value`               DECIMAL(12,2) NULL DEFAULT '0'
   ,`Net_Revenue`             DECIMAL(12,2) NULL DEFAULT '0'
   ,`RS_Value`                DECIMAL(12,2) NULL DEFAULT '0'
   ,`RS_AJUST`                DECIMAL(12,2) NULL DEFAULT '0'
   ,`CPA_Val_AJ_RS`           DECIMAL(12,2) NULL DEFAULT '0'
   ,`net_Total_comm`          DECIMAL(12,2) NULL DEFAULT '0'
   ,`RS_carry_NCO`            DECIMAL(12,2) NULL DEFAULT '0'
   ,`Deal_Aff_RS_Against_CPA` DECIMAL(12,2) NULL DEFAULT '0'
   ,`Aff_CPA`                 DECIMAL(12,2) NULL DEFAULT '0'
   ,`Aff_RS`                  DECIMAL(12,2) NULL DEFAULT '0'
   ,`Sub_Affiliate`           VARCHAR(80)   NULL DEFAULT ''
	,`Sub_Affiliate_id`        INT(10)       NULL DEFAULT '0'
   ,`Last_Update`             TIMESTAMP      DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	INDEX `Date_Affiliate_id`  (`Date`, `Affiliate_id`)   USING BTREE,
	INDEX `Date_Brand`         (`Date`, `Advertiser_id`)  USING BTREE,
	INDEX `Date_Account_id`    (`Date`, `Username_id`)    USING BTREE
)
ENGINE=InnoDB
;

-- Llamar al procedimiento monthly_comms_affiliate con el parámetro de mes
CALL monthly_comms_affiliate_v5(@LMonth);

TRUNCATE TABLE view_monthly_fact_aff4;

INSERT IGNORE INTO view_monthly_fact_aff4 (
 `Owner`,`Area`
,`Username`,`Username_id`
,`DATE`
,`Affiliate`,`Affiliate_id`
,`Brand`,`Advertiser_id`
,`CPA`,`CPA_Value`,`Net_Revenue`,`RS_Value`,`RS_AJUST`,`CPA_Val_AJ_RS`
,`net_Total_comm`,`RS_carry_NCO`
,`Sub_Affiliate`,`Sub_Affiliate_id`
,`Product`
,`Product_real`
,`Channel`
,`Channel_id`
,`Data_Currency`
-- ,`Channel_Name`
-- ,`Deal_Aff_RS_Against_CPA`,`Aff_CPA`,`Aff_RS`
)
SELECT
 G.Owner
,ifnull(CU.`Area`,"")
,ifnull(CU.`Username`,"Obsolete")
,G.`Account_id`
,`Month`
,`Affiliate`,`Affiliate_id`
,`Brand`,G.`Advertiser_id`
,`CPA`,`gross_CPA_Val`,`Net_Revenue`,`gross_RS_Val`,`net_RS_Val`
,CASE WHEN `Sub_Affiliate_id`!=0 AND `net_CPA_Val`=0 AND `net_RS_Val`=0 THEN `net_Total_comm` ELSE `net_CPA_Val` 
      END  AS `net_CPA_Val` -- 02.11.2024
,`net_Total_comm`,`RS_carry_NCO`
,`Sub_Affiliate`,`Sub_Affiliate_id`
,G.`Product`
,G.`Product_Real`
,G.`Channel`
,G.`Channel_id`
,G.`Currency`
FROM monthly_comms_affiliate_v5 G
LEFT JOIN `campaign_username` CU ON CU.id=G.`Account_id`
-- LEFT JOIN LATERAL
--    (SELECT id as `Username_id`,Owner,Area,`Username`
--       FROM `campaign_username` CU
--       WHERE CU.`Advertiser_id`=G.`Advertiser_id`
--       LIMIT 1) AS CU ON TRUE
;

END;
//
DELIMITER ;

/* -----------------------------------------------------
CALL total_monthy_comm_aff_upd('2024-12');  -- Con mes específico
CALL total_monthy_comm_aff_upd(NULL);       -- Sin parámetro (usa mes actual)
-- -----------------------------------------------------
*/
