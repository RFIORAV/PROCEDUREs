/**
	PROCEDURE_total_monthy_comm_ges_upd_v5.6.sql

Descripción:
  Procedimiento total_monthy_comm_ges_upd.
	**	Actualiza tabla total_monthy_comm_ges desde tabla monthly_comms_gestor_v5
   ** 
	**	Recibe parámetro de entrada YYYY-MM para invocar monthly_comms_gestor
	**	Si el parámetro es inválido o inexistente, usa MES de CURDATE()
	02.10.2022 V1   Materializa view_monthly_fact_gestor3 por performance (Est 0.6" a 0.1")
   28.11.2022      Agrega nuevos campos de view is_indirect,Advertiser_indirect_id,Advertiser_indirect
   31.01.2023 v1.1 Area
   15.03.2023 v4   Utiliza PROCEDURE_monthly_comms_gestor_v4.1_COver.sql
   17.05.2024 v5   Adaptación a cambios en PROCEDURE y tabla monthly_comms_gestor_v5
   11.09.2025 v5.6 Agrega parámetro de entrada YYYY-MM para monthly_comms_gestor

Keys:
  p_month = [valor]. Parámetro de entrada.
*/

DROP PROCEDURE IF EXISTS total_monthy_comm_ges_upd;
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE total_monthy_comm_ges_upd(IN p_month VARCHAR(7))
COMMENT 'total_monthy_comm_ges desde tabla monthly_comms_gestor_v5 con parámetro YYYY-MM'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

BEGIN
-- Defaults
SET @Version         ='v5.6 11.09.2025';
SET @CurrentDay      =curdate();
SET @InputMonth      =p_month;
SET @ValidMonth      =NULL;

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

IF CURDATE()<='2024-08-03' THEN DROP TABLE IF EXISTS `total_monthy_comm_ges`; END IF;

CREATE TABLE IF NOT EXISTS `total_monthy_comm_ges` (
	`Owner`                 VARCHAR(150)  NULL DEFAULT '',
	`Area`                  VARCHAR(150)  NULL DEFAULT 'gaming',
   `Date`                  VARCHAR(7)    NULL DEFAULT '0000-00',
	`Publisher`             VARCHAR(150)  NULL DEFAULT '',
	`Brand`                 VARCHAR(150)  NULL DEFAULT '',
	`Username`              VARCHAR(150)  NULL DEFAULT '',
	`Publisher_id`          INT(10)       NULL DEFAULT '0',
	`Advertiser_id`         INT(10)       NULL DEFAULT '0',
	`Username_id`           INT(10)       NULL DEFAULT '0',
	`CPA`                   DECIMAL(12,0) NULL DEFAULT '0',
	`CPA_Value`             DECIMAL(12,2) NULL DEFAULT '0',
	`Net_Revenue`           DECIMAL(12,2) NULL DEFAULT '0',
	`RS_Value`              DECIMAL(12,2) NULL DEFAULT '0',
	`RS_AJUST`              DECIMAL(12,2) NULL DEFAULT '0',
	`CPA_Val_AJ_RS`         DECIMAL(12,2) NULL DEFAULT '0',
	`Total_Commission`      DECIMAL(12,2) NULL DEFAULT '0',
	`RS_carry_NCO`          DECIMAL(12,2) NULL DEFAULT '0',
	`Data_Currency`         VARCHAR(150)  NULL DEFAULT 'EUR',
   -- Campos sin contenido - Solo para compatibilidad
	`Product`               VARCHAR(150)  NULL DEFAULT '',
	`is_indirect`           TINYINT(1)    NULL DEFAULT '0',    -- 28.11.2022
	`Advertiser_indirect_id` INT(10)      NULL DEFAULT '0',    -- 28.11.2022
	`Advertiser_indirect`   VARCHAR(150)  NULL DEFAULT '',     -- 28.11.2022
	`Ges_id_Deal`           INT(10)       NULL DEFAULT '0',
	`Ges_CPA`               DECIMAL(12,2) NULL DEFAULT '0',
	`Ges_Carry_Over`        VARCHAR(150)  NULL DEFAULT '0',
	`Ges_RS_Against_CPA`    INT(10)       NULL DEFAULT '0',
	`Ges_RS_Base`           VARCHAR(150)  NULL DEFAULT '',
	`Ges_RS`                DECIMAL(12,2) NULL DEFAULT '0',
	`Ges_Valid_From`        VARCHAR(150)  NULL DEFAULT '',
   --
   `Last_Update`           TIMESTAMP     NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	INDEX `Date_Publisher_id`  (`Date`, `Publisher_id`)   USING BTREE,
	INDEX `Date_Brand`         (`Date`, `Advertiser_id`)  USING BTREE,
	INDEX `Date_Account_id`    (`Date`, `Username_id`)    USING BTREE
)
ENGINE=InnoDB
;

-- ---------------------------------------------
-- Invocar monthly_comms_gestor con el mes validado
CALL monthly_comms_gestor(@LMonth);
-- ---------------------------------------------

TRUNCATE TABLE total_monthy_comm_ges;

INSERT IGNORE INTO total_monthy_comm_ges (
`Owner`,`Area`,`Data_Currency`
,`Date`,`Publisher`,`Brand`,`Username`,`Publisher_id`,`Advertiser_id`,`Username_id`,`CPA`
,`CPA_Value`,`Net_Revenue`,`RS_Value`,`RS_AJUST`,`CPA_Val_AJ_RS`,`Total_Commission`
,`RS_carry_NCO`
)
SELECT 
`Owner`,`Area`,`Data_Currency`
,`Month`,`Publisher`,`Brand`,`Username`,`Publisher_id`,`Advertiser_id`,`Username_id`,`CPA`
,`gross_CPA_Val`,`Net_Revenue`,`gross_RS_Val`,`net_RS_Val`,`net_CPA_Val`,`net_Total_comm`
,`RS_CarryOver_Pend` 
FROM monthly_comms_gestor_v5
WHERE `Month` = @ValidMonth
;

END;
//
DELIMITER ;
	
-- -----------------------------------------------------
-- Ejemplos de uso:
-- CALL total_monthy_comm_ges_upd('2024-05');
-- CALL total_monthy_comm_ges_upd('2024-12');
-- CALL total_monthy_comm_ges_upd(NULL);  -- Usará mes actual
-- CALL total_monthy_comm_ges_upd('');    -- Usará mes actual
-- CALL total_monthy_comm_ges_upd('2025-01'); -- Usará mes actual (fecha futura)
-- -----------------------------------------------------

