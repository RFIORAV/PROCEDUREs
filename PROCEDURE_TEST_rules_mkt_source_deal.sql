/**
	PROCEDURE_TEST_rules_mkt_source_deal.sql - Utiliza algoritmos de PROCEDURE_Snapshot_day_by_day_fact1_upd_from_dbd.sql

Descripción:
  Procedimiento TEST_rules_mkt_source_deal.

Keys:
  MS_id = [valor]. Parámetro de entrada.

	**	Prueba el resultado tras un cambio de rules en `campaign_deal_gestor_prod_date`

   CALL TEST_rules_mkt_source_deal(1747);

   10.10.2024 v1     Version 1
   03.06.2025        Adecuación selección deal
*/
SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;

DROP PROCEDURE IF EXISTS TEST_rules_mkt_source_deal;
-- -------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE TEST_rules_mkt_source_deal(IN MS_id int)
COMMENT 'Test RULES deals Marketing Sources'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

proc_label:BEGIN

SET @Version='v1 03.06.2025';
SET @DateFrom=LEFT(DATE_SUB(CURDATE(), INTERVAL 12 MONTH),7);
SET @MS_id=MS_id;
SET @Debug='NO';

IF @Debug!="NO" THEN SELECT  @DateFrom,@MS_id from dual; END IF;

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
   WHERE LEFT(DATE,7)>="',@DateFrom,'" AND MS_id=',@MS_id,' AND Qualified_Players<>0 and Origin=""
   GROUP BY LEFT(DATE,7),MS_id,Product,Country,Deal_Aff_id
)
   SELECT
       D.Date
--    ,D.MS_id
--    ,D.Brand
      ,D.Product
      ,D.Country
      ,D.CPA
      ,D.Deal_Aff_id
      ,D.Deal_Aff
      ,D.Affiliate
--    ,D.Affiliate_id
      ,case when M1.`Deal_id` is null              then "No rule"
            when D.Affiliate_id!=M2.`Affiliate_id` then "Change aff"
            when D.Deal_Aff_id!=M1.`Deal_id`       then "Change deal"
            else "--" end   as `Changes`
      ,M1.`id`              as `Rule Applied`
--    ,M2.`Affiliate_id`    AS `Rule Aff_id`
      ,A.username           AS `Rule Aff`
--    ,M1.`Deal_id`         AS `Rule Deal`
      ,CDA.`Deal_Name`      AS `Rule Deal`
      ,case when M1.`Product`="" then "Any" else M1.`Product` end
                            as `Rule Prod`
      ,M1.`Deal_Valid_From`

   from Fact1 D

   -- ----------------------------Seleccion de Affiliate------------------------------------
   LEFT JOIN LATERAL (
   	SELECT *,ROW_NUMBER() OVER(PARTITION BY MS_id
                                   ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr
   	FROM `campaign_mkt_source_deal` WHERE `MS_id` = `D`.`MS_id` AND `is_active` = 1
                                        AND `Deal_Valid_From` <= `D`.`Date`
   	ORDER BY Deal_Valid_From DESC LIMIT 1
   ) AS M2 ON TRUE
   -- -------------------------Seleccion de DEAL Affiliate/MS por producto/pais-------------
   LEFT JOIN LATERAL (
      SELECT * FROM (
         SELECT *,ROW_NUMBER() OVER(PARTITION BY Product
                                    ORDER BY Deal_Valid_From DESC,Country DESC,id DESC) AS RowN
         FROM `campaign_mkt_source_deal`
         WHERE `MS_id` = `D`.`MS_id`
           AND Affiliate_id=M2.Affiliate_id
           AND `is_active` = 1
           AND `Deal_Valid_From` <= `D`.`Date`
           AND Product IN (IFNULL(D.Product, ""),""," ")
           AND Country IN (IFNULL(D.Country,""),"")
      ) AS DbP
      where RowNr=1
      LIMIT 1
   ) AS M1 ON TRUE
   -- --------------------------------------------------------------------------------------

   LEFT JOIN `account_account` `A` ON `A`.`id` = `M2`.`Affiliate_id`
   LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id` = `M1`.`Deal_id`

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
CALL TEST_rules_mkt_source_deal(1747);

SET @D_MS_id=1747,@D_Date='2024-09-15',@M2_Affiliate_id=44,@D_Product='Customer Account';

   	SELECT *,ROW_NUMBER() OVER(PARTITION BY MS_id
                                   ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr
   	FROM `campaign_mkt_source_deal` WHERE `MS_id` = @D_MS_id AND `is_active` = 1
                                        AND `Deal_Valid_From` <= @D_Date
   	-- ORDER BY Deal_Valid_From DESC
      LIMIT 1
;
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product
                                   ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr
      FROM `campaign_mkt_source_deal` WHERE `MS_id` = @D_MS_id AND Affiliate_id=@M2_Affiliate_id
                                        AND `Product` IN (IFNULL(@D_Product, ''),'',' ')
                                        AND `is_active` = 1
                                        AND `Deal_Valid_From` <= @D_Date
      -- ORDER BY `Deal_Valid_From` DESC
      LIMIT 1

*/