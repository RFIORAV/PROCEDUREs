/*
PROCEDURE_economics_by_affiliate_v2.sql - GENERACION DE RESUMEN ECONOMICS - SOLO SE USA INVOCADO DESDE DJANGO

Descripción:
  Procedimiento economics_by_affiliate.

Keys:
  AffiliateID = [valor]. Parámetro de entrada.

01.03.2022 v1
11.01.2024 v2     Utiliza view_monthly_fact_aff4
04.08.2024 v2.1   CALL economics_by_affiliate1
04.09.2024        Meta=yes en lugar de Meta=no
*/
-- -----------------------------------------------------
DROP PROCEDURE IF EXISTS economics_by_affiliate;
-- -----------------------------------------------------

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `economics_by_affiliate`(
	IN `AffiliateID` INT
)
    COMMENT 'RESUMEN [Affiliate_id] de Comisiones, Pagos, Ajustes (CALL economics_by_affiliate1)'

ProcedureBody: BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v2.1 04.09.2024';
SET @CurrentDay      =CURDATE();

CALL  economics_by_affiliate1(CONCAT('Affiliate_id=',AffiliateID,',Meta=yes'));

END;
$$
DELIMITER ;

-- -----------------------------------------------------
-- -----------------------------------------------------
/*

CALL  economics_by_affiliate(39);

*/
