/**
	PROCEDURE_TEST_rules_Account_deal.sql - Utiliza algoritmos de PROCEDURE_Snapshot_day_by_day_fact1_upd_from_dbd.sql

Descripción:
  Procedimiento TEST_rules_Account_deal.

Keys:
  Username_id = [valor]. Parámetro de entrada.

	**	Prueba el resultado tras un cambio de rules en `campaign_deal_gestor_prod_date`

   CALL TEST_rules_Account_deal(24);

   11.10.2024 v1     Version 1
   03.06.2025        Adecuación selección deal
   17.11.2026        Country no condiciona la selección del deal (alineado a fact1 v3.9.5)

*/

DROP PROCEDURE IF EXISTS TEST_rules_Account_deal;
-- -------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE TEST_rules_Account_deal(IN Username_id int)
COMMENT 'Test RULES deals Accounts'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

proc_label:BEGIN

SET @Version='v1 03.06.2025';
SET @DateFrom=LEFT(DATE_SUB(CURDATE(), INTERVAL 12 MONTH),7);
SET @Username_id=Username_id;
SET @Debug='NO';

IF @Debug!="NO" THEN SELECT  @DateFrom,@Username_id from dual; END IF;

SET @SQL=CONCAT('
WITH Fact1 as (
   SELECT
       Date
      ,Affiliate,Affiliate_id,Deal_Aff
      ,Username,Username_id,Deal
      ,Brand,Advertiser_id,`Publisher_id`
      ,MS_id,Product,Product_Real
      ,Country
      ,sum(Qualified_Players) AS CPA
   -- ,sum(Net_Revenue) AS Net_Revenue
   -- ,sum(Revenue_Share_Affiliate) AS Revenue_Share_Affiliate,sum(CPA_Value_Affiliate) AS CPA_Value_Affiliate
      ,Deal_Aff_id,Deal_Aff_CPA,Deal_Aff_Carry_Over,Deal_Aff_RS_Against_CPA,Deal_Aff_RS_Base,Deal_Aff_RS
      ,Deal_Aff_Valid_From
   -- ,sum(Revenue_Share_Gestor) AS Revenue_Share_Gestor,sum(CPA_Value_Gestor) AS CPA_Value_Gestor
      ,Deal_Ges_id,Deal_Ges_CPA,Deal_Ges_Carry_Over,Deal_Ges_RS_Against_CPA,Deal_Ges_RS_Base,Deal_Ges_RS
      ,Deal_Ges_Valid_From
      ,Data_Currency
   FROM Snapshot_day_by_day_fact1
   WHERE LEFT(DATE,7)>="',@DateFrom,'" AND Username_id=',@Username_id,' AND Qualified_Players<>0 and Origin=""
   GROUP BY LEFT(DATE,7),Username_id,Deal_Ges_id,Product
)
SELECT
    D.Date
   -- ,D.Brand
   ,D.Product
   ,D.Country
   ,D.CPA
   ,D.Deal_Ges_id
   ,D.Deal
   ,case when CDP.`Deal_id` is null then "No rule"
         when D.Deal_Ges_id!=CDP.`Deal_id` is null then "Change deal"
         else "--" end as `Changes`
   ,CDP.`Deal_id`     AS `Rule Deal`
   ,CDG.`Deal_Name`
   ,CDP.`id`          as `Rule Applied`
   ,case when CDP.`Product`="" then "Any" else CDP.`Product` end
                      as `Rule Prod`
   ,CDP.`Valid_From`
from Fact1 D

-- ----------------------------Seleccion de DEAL Account---------------------------------
LEFT JOIN LATERAL (
	SELECT * FROM (
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product
                                 ORDER BY Valid_From DESC,id DESC) AS RowNr
      FROM `campaign_deal_gestor_prod_date`
      WHERE `Username_id` = `D`.`Username_id`
        AND `is_active` = 1  AND `Valid_From` <= `D`.`Date`
        AND Product IN (IFNULL(D.Product,""),"")
	) AS CDP
   WHERE RowNr=1
   LIMIT 1
) AS CDP ON TRUE
-- --------------------------------------------------------------------------------------

LEFT JOIN `campaign_deal_gestor` CDG ON CDG.`id` = `CDP`.`Deal_id`

ORDER BY D.DATE DESC
;');

-- ----------------------------------------------------------------------------
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*

-- --------------------tests---------------------------------
CALL TEST_rules_Account_deal(24);

*/
