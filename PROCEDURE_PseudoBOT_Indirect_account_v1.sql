/*
PROCEDURE_PseudoBOT_Indirect_account.sql -  ACTUALIZAR Snapshot_day_by_day from dbOrigen.Snapshot_day_by_day_fact2

Descripción:
  Procedimiento PseudoBOT_Indirect_account.

Keys:

10.12.2024 v1
30.04.2025     IF(Deal_Aff_RS>0,`Net_Revenue`,0) No pasa NR si no hay RS en el deal
               Product_Real as "Product"

*/

DROP PROCEDURE IF EXISTS PseudoBOT_Indirect_account;

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE PseudoBOT_Indirect_account()
    COMMENT 'Update Snapshot_day_by_day from dbOrigen.Snapshot_day_by_day_fact2'

proc_label:BEGIN

DECLARE Version              VARCHAR(20)  DEFAULT 'v1 30.04.2025';
DECLARE Month                VARCHAR(07)  DEFAULT LEFT(CURDATE(),7);
DECLARE CMonth               VARCHAR(07)  DEFAULT LEFT(CURDATE(),7);
DECLARE LMonth               VARCHAR(07)  DEFAULT LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);

DECLARE id                   INT          DEFAULT 0;
DECLARE Username             VARCHAR(255) DEFAULT "";
DECLARE Advertiser_id        INT          DEFAULT 0;
DECLARE Advertiser_Name      VARCHAR(255) DEFAULT "";
DECLARE db_indirect          VARCHAR(255) DEFAULT "";
DECLARE Affiliate_indirect   VARCHAR(255) DEFAULT "";

DECLARE Debug                VARCHAR(03)  DEFAULT 'NO';
DECLARE done                 INT          DEFAULT FALSE;

DECLARE cursor_indirect_accounts CURSOR FOR
  SELECT u.id,u.Username,u.Advertiser_id,a.Advertiser_Name,lower(u.db_indirect),u.Affiliate_indirect
  FROM campaign_username u
  LEFT JOIN campaign_advertiser a ON a.id=u.Advertiser_id
  WHERE u.is_indirect = "1" AND IFNULL(u.db_indirect  ,"")>"";

-- id;   Username;      Advertiser_id; Advertiser_Name;  db_indirect;         Affiliate_indirect
-- 189;  Fran;          123;           WilliamHill;      AffiliateRevolution; Fran
-- 190;  Fran;          124;           Rabona;           AffiliateRevolution; Fran
-- 191;  Fran;          126;           Casino Midas;     mymonsteraffiliates; Fran
-- 192;  Fran;          125;           JackMillion;      mymonsteraffiliates; Fran
-- 194;  Fran;          128;           LibraBet;         freedom_legacy;      Fran
-- 195;  Fran;          127;           Rabona;           freedom_legacy;      Fran
-- 243;  EuroAffiliati; 165;           Snai;             AffiliateRevolution; EuroAffiliati

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

-- Hasta día 15, proceso incluye LM
-- IF DAY(CURDATE())<=15 THEN SET Month=LMonth; END IF;

-- proceso SIEMPRE incluye LM
SET Month=LMonth;

OPEN cursor_indirect_accounts;

read_loop: LOOP
   FETCH cursor_indirect_accounts INTO id,Username,Advertiser_id,Advertiser_Name,db_indirect,Affiliate_indirect;

   -- Comprueba si existe db Origen
   SET @ExisteDbD =(SELECT count(*) FROM `information_schema`.`SCHEMATA` WHERE `SCHEMA_NAME`=db_indirect);

   IF Debug!="NO" THEN SELECT Month,Debug,@ExisteDbD,id,Username,Advertiser_id,Advertiser_Name,db_indirect,Affiliate_indirect; END IF;

   IF done THEN LEAVE read_loop; END IF; -- Fin de Loop

   IF @ExisteDbD=0 THEN ITERATE read_loop; END IF; -- skip loop porque db no existe

   SET @DeleteTableDbD = CONCAT('DELETE FROM Snapshot_day_by_day WHERE LEFT(Date,7)>="',Month,'" AND Username="',id,'"');

   SET @insertDataQuery = CONCAT('
       INSERT IGNORE INTO Snapshot_day_by_day (
          `Date`,`Username`
          ,`Portal`,`Brand`,`Tracker_ID`,`Tracker_Name`,`Product`
          ,`Qualified_Players`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`,`Impressions`
          ,`Sign_Up_Offer`,`Type`,`Country`,`Deposits`,`Depositing_Customers`,`Active_Customers`
          ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`
          ,`Turnover`,`Net_Revenue`,`Revenue_Share_Gestor`,`CPA_Value_Gestor`
          )');

   SET @insertDataQuerySelect = CONCAT('
       SELECT
          Date,"',id,'"
          ,"DirectAccess",Brand,Code_To_Affiliate,Code_To_Affiliate
          ,Product_Real as "Product"
          ,Qualified_Players,First_Time_Deposit,Views,Clicks,Signups,Impressions
          ,Sign_Up_Offer,Type,Language,Deposits,Depositing_Customers,Active_Customers
          ,New_Depositing_Customers,New_Active_Customers,First_Time_Active_Customers
          ,Turnover
          ,IF(Deal_Aff_RS>0,`Net_Revenue`,0) AS `Net_Revenue`  -- 30.04.2025
          ,Revenue_Share_Affiliate
          ,CPA_Value_Affiliate
       FROM ',db_indirect,'.Snapshot_day_by_day_fact2
       WHERE LEFT(Date,7)>="',Month,'" AND Affiliate = "',Affiliate_indirect,'"
         AND Brand = "',Advertiser_Name,'";'
   );
   SET @insertDataQueryFull = CONCAT(@insertDataQuery,@insertDataQuerySelect);

   /******************** Sólo en modo Debug **********************/
   IF Debug!="NO" THEN 
      CREATE TABLE IF NOT EXISTS Snapshot_day_by_day_temp_TEST LIKE Snapshot_day_by_day_temp;  
      SET @DeleteTableDbD     =REPLACE(@DeleteTableDbD,     "Snapshot_day_by_day ","Snapshot_day_by_day_temp_TEST ");     
      SET @insertDataQueryFull=REPLACE(@insertDataQueryFull,"Snapshot_day_by_day ","Snapshot_day_by_day_temp_TEST ");
      SELECT @DeleteTableDbD;
      SELECT @insertDataQueryFull;  
   END IF;
   /**************************************************************/

   IF Debug != "YES" THEN
      PREPARE stmt1 FROM @DeleteTableDbD;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;

      PREPARE stmt1 FROM @insertDataQueryFull;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   ELSE
      PREPARE stmt1 FROM @insertDataQuerySelect;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;

END LOOP;

CLOSE cursor_indirect_accounts;

END //

DELIMITER ;

/*
CALL PseudoBOT_Indirect_account();

*/

