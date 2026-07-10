/**
	PROCEDURE_sub_Snapshot_day_by_day_fact3_upd.sql

Descripción:
  Procedimiento sub_Snapshot_day_by_day_fact3_upd.

Keys:
  Curr_Last_Month = [valor]. Parámetro de entrada.

	**	Actualiza tabla sub_Snapshot_day_by_day_fact3 desde Snapshot_day_by_day_fact2
	**	Se lanza desde EVENT

06.07.2024 v1

*/

DROP PROCEDURE IF EXISTS sub_Snapshot_day_by_day_fact3_upd;
-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE sub_Snapshot_day_by_day_fact3_upd(IN Curr_Last_Month varchar(7))
COMMENT 'Actualiza FACT3 desde fact2 - Last Month y Cte / AAAA-MM'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

proc_label:BEGIN

SET @Version='v1 06.07.2024';
SET @DateFrom=LEFT(CURDATE(),7);    -- Asume Curr Month por defecto

IF UPPER(Curr_Last_Month)='CM' THEN SET @DateFrom=LEFT(CURDATE(),7); END IF;
IF UPPER(Curr_Last_Month)='LM' THEN SET @DateFrom=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- Cuando se pide reproceso general de todo, limita a MES de movimiento más antiguo DbD
SET   @MinDateFromDbD=(SELECT MIN(LEFT(DATE,7)) FROM sub_Snapshot_day_by_day_fact3 WHERE DATE IS NOT NULL);
IF    UPPER(Curr_Last_Month)='ALLALL'
THEN  SET @DateFrom=@MinDateFromDbD;
END IF;

SELECT  Curr_Last_Month,@MinDateFromDbD,@DateFrom from dual;

-- Valida fecha
IF    LEFT(Curr_Last_Month,3)='202'
THEN
      IF   SUBSTRING(Curr_Last_Month,6,2) IN ('01','02','03','04','05','06','07','08','09','10','11','12')
      THEN SET @DateFrom=LEFT(Curr_Last_Month,7);
      ELSE SELECT "Invalid Month parameter" from dual;
           LEAVE proc_label;
      END IF;
END IF;

-- Valida que se haya pedido un mes dentro del rango de datos de DbD
IF    @DateFrom < @MinDateFromDbD OR @DateFrom > LEFT(CURDATE(),7)
THEN  SELECT "Month out of range DbD data" from dual;
      LEAVE proc_label;
END IF;

-- ----------------------------------------------------------------------------

DELETE FROM sub_Snapshot_day_by_day_fact3 WHERE LEFT(DATE,7)=@DateFrom
                                             OR '1'=IF(UPPER(Curr_Last_Month)='ALLALL','1','0')
;
-- --------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------
/*
SELECT `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
      ,`Advertiser_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
      ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
      ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
      ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
      ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
      ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
      ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`
FROM Snapshot_day_by_day_fact2

DROP TABLE IF EXISTS sub_Snapshot_day_by_day_fact3;
CREATE TABLE if NOT EXISTS sub_Snapshot_day_by_day_fact3 LIKE Snapshot_day_by_day_fact2;
ALTER TABLE `sub_Snapshot_day_by_day_fact3` CHANGE COLUMN `MS_id` `MS_id` VARCHAR(50) NULL DEFAULT NULL ;
*/

INSERT IGNORE INTO sub_Snapshot_day_by_day_fact3 (
      `id`,`Area`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
      ,`Advertiser_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
      ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
      ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
      ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
      ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
      ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
      ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`)
-- ; 
-- SET @DateFrom="2024-06";
SELECT
    D.`id`
   ,D.`Area`
   ,D.`Owner`
   ,A.`username`
   ,M2.`Affiliate_id`
   ,D.`Deal_Aff`
   ,D.`Date`
   ,D.`Username`
   ,D.`Username_id`
   ,D.`Brand`
   ,D.`Advertiser_id`
   ,D.`Tracker_ID`
   ,D.`Code_To_Affiliate` as `MS_id`  
   ,D.`Tracker_Name`
   ,D.`Code_To_Affiliate`
   ,D.`Product`
   ,D.`Product_Real`  
   ,D.`Qualified_Players`
   ,D.`Qualified_Players_Adjusted`
   ,D.`First_Time_Deposit`
   ,D.`Views`
   ,D.`Clicks`
   ,D.`Signups`
   ,D.`Impressions`
   ,D.`Sign_Up_Offer`
   ,D.`Type`
   ,D.`Language`
   ,D.`Deposits`
   ,D.`Depositing_Customers`
   ,D.`Active_Customers`
   ,D.`New_Depositing_Customers`
   ,D.`New_Active_Customers`
   ,D.`First_Time_Active_Customers`
   ,D.`Turnover`
   ,D.`Net_Revenue`
   ,D.`CPA_Limit`
   ,`lp`.`id`                             AS `Channel_id`
   ,`lp`.`landing_page_name`              AS `Channel`
   ,ROUND(((Net_Revenue * IFNULL(`CDA`.`RS_Percentage`, 0)) / 100), 2)  AS `Revenue_Share_Affiliate`
   ,ROUND((Qualified_Players * IFNULL(`CDA`.`CPA_Value`, 0)), 0)        AS `CPA_Value_Affiliate`
   ,IFNULL(`CDA`.`id`, 0) 				      AS `Deal_Aff_id`
   ,IFNULL(`CDA`.`CPA_Value`, 0) 		   AS `Deal_Aff_CPA`
   ,IFNULL(`CDA`.`Carry_Over`, 0) 	      AS `Deal_Aff_Carry_Over`
   ,IFNULL(`CDA`.`RS_Against_CPA`, 0)     AS `Deal_Aff_RS_Against_CPA`
   ,IFNULL(`CDA`.`RS_Base`, 0) 		      AS `Deal_Aff_RS_Base`
   ,IFNULL(`CDA`.`RS_Percentage`, 0)      AS `Deal_Aff_RS`
   ,IFNULL(`M1`.`Deal_Valid_From`, 0)     AS `Deal_Aff_Valid_From`  
   ,D.`Data_Currency`
   ,D.`TimeGen`
FROM Snapshot_day_by_day_fact2 D

-- Solo datos MAF y subafiliados
INNER JOIN `account_account_groups` `AG` ON `AG`.`account_id` = D.`Affiliate_id` AND AG.`group_id` IN (4, 6)

-- ----------------------------Seleccion MS----------------------------------------------
LEFT JOIN `sub_campaign_marketing_source` `M` ON `M`.`id` = `D`.`Code_To_Affiliate`
-- ----------------------------Seleccion de Affiliate------------------------------------
LEFT JOIN LATERAL (
	SELECT *,ROW_NUMBER() OVER(PARTITION BY MS_id ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr
	FROM `sub_campaign_mkt_source_deal`
   WHERE `MS_id` = M.id AND `is_active` = 1 AND `Deal_Valid_From` <= `D`.`Date`
	ORDER BY RowNr LIMIT 1
) AS M2 ON TRUE
-- ----------------------------Seleccion de producto/deal--------------------------------
LEFT JOIN LATERAL (
	SELECT * FROM (
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr
      FROM `sub_campaign_mkt_source_deal`
      WHERE `MS_id` = M.id AND Affiliate_id=M2.Affiliate_id
       AND `is_active` = 1 AND `Deal_Valid_From` <= `D`.`Date`
	) AS DbP
	WHERE RowNr=1 AND
		(
		    TRIM(IFNULL(DbP.`Product`,'')) IN (TRIM(IFNULL(D.Product, '')),'')  -- coincide Product regla o catch all
		OR (IFNULL(DbP.`Product`,'')=TRIM(IFNULL(M.Product, ''))
			 AND TRIM(IFNULL(D.Product, ''))='')                                 -- Product regla=Product MS cuando Product entrada vacio
		)
	ORDER BY DbP.`Product` DESC LIMIT 1
) AS M1 ON TRUE
-- --------------------------------------------------------------------------------------

LEFT JOIN `account_account` `A` ON `A`.`id` = `M2`.`Affiliate_id`
LEFT JOIN `sub_campaign_deal_affiliate` `CDA` ON `CDA`.`id` = `M1`.`Deal_id`
LEFT JOIN `sub_account_landing_pages` `lp` ON `lp`.`id` = `M2`.`Channel_id`

WHERE LEFT(`D`.`Date`,7)=@DateFrom
      -- OR '1'=IF(UPPER(Curr_Last_Month)='ALLALL','1','0')
;

END;
//
DELIMITER ;

/*
-- -----------------------------------------------------
CALL sub_Snapshot_day_by_day_fact3_upd('CM');
CALL sub_Snapshot_day_by_day_fact3_upd('LM');

CALL sub_Snapshot_day_by_day_fact3_upd('');        -- asume CM
CALL sub_Snapshot_day_by_day_fact3_upd('ENERO');   -- asume CM
CALL sub_Snapshot_day_by_day_fact3_upd('ALLALL');

CALL sub_Snapshot_day_by_day_fact3_upd('2022-05'); -- error si no hay datos
CALL sub_Snapshot_day_by_day_fact3_upd('2022-15'); -- error
-- -----------------------------------------------------
*/