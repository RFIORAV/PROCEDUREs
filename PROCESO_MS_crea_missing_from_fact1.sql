/*
   PROCESO DE CREACIÓN DE MS EN BASE A MS DE FACT1 QUE no tienen afiliado asignado
   12.05.2025
   
   Buenas Don, acabo de hablar con 5stars y necesitarian asignar todas las sources que 
   aparecen en check procedure con username MRWORLDWIDE de entain y de betpartners 
   al afiliado Marcocommissioni (ciaosono marcio channel) con estos acuerdos:
 
   Entain : cpa100 bl10
   Betpartners: cpa85 bl10
 
   No hace falta crear el link de verdad, podemos poner google, meparece que usted tenia algo para hacerlo de forma rapida.

   09.04.2026 Modificado para crear las MS "missing" en fact1

*/

/* -- --------------------------------------------------
SET @Username_id        ="275"; -- Entain
SET @Username_id        ="276"; -- Entain
SET @Tracklink          ='https://www.google.it';
SET @Source             ='[]';
SET @Status_id          ="1";
SET @Affiliate_id       =171;
SET @Channel_id         =128;
SET @Deal_id            =173;
SET @Country_Deal       ="IT";
SET @Product_Deal       ='';
SET @Description        =CONCAT("Created ",CURDATE()," auto");
SET @Operator           ='20';                                                   
-- -------------------------------------------------- */
SET @Username_id        ="265"; 
SET @Tracklink          ='https://www.google.it';
SET @Source             ='[]';
SET @Status_id          ="1";
SET @Affiliate_id       =13; -- aff55
SET @Channel_id         =5;
SET @Deal_id            =501;
SET @Country_Deal       ="";
SET @Product_Deal       ='';
SET @Deal_Ges_Valid_From='2025-06-01';
SET @Description        =CONCAT("Created ",CURDATE()," auto from fact1");
SET @Operator           ='SysOp';                                                   
-- -------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
-- -------------------------------------------------

INSERT INTO `campaign_marketing_source` (
     `Tracklink`            
   , `Tracker_ID`           
   , `Tracker_Name`         
   , `Code_To_Affiliate` 
--    , `Code`
   , `Owner`                  
   , `Source`               
   , `Product`              
   , `Status_id`            
   , `Affiliate_id`         
   , `Advertiser_id`        
   , `Publisher_id`         
   , `Username_id`          
   , `Channel_id`           
   , `Deal_id`              
--    , `Country_Deal`         
   , `Deal_Valid_From`      
--    , `Product_Deal`          
   , `Description`          
   , `Operator`          
) 
;   
SELECT 
     CONCAT("https://wstc.lynmonkel.com/?mid=364418_",F.Tracker_ID) AS `Tracklink`
   , `Tracker_ID` 
   , CASE WHEN IFNULL(`Tracker_Name`,'')='' THEN `Tracker_ID` ELSE `Tracker_Name` END AS `Tracker_Name`  
   , `Tracker_Name`          AS `Code_To_Affiliate`
--    , `Tracker_ID`          AS `Code`
   , U.`Owner`  
   , @Source               AS `Source`   
   , F.`Product` 
   , @Status_id            AS `Status_id`
   , @Affiliate_id         AS `Affiliate_id`
   , F.`Advertiser_id` 
   , F.`Publisher_id`  
   , F.Username_id         AS `Username_id`   
   , @Channel_id           AS `Channel_id`
   , @Deal_id              AS `Deal_id`
--    , @Country_Deal         AS `Country_Deal`
   , @Deal_Ges_Valid_From  AS `Deal_Valid_From`
--    , F.Product             AS `Product_Deal`
   , @Description          AS `Description`
   , @Operator             AS `Operator`
FROM Snapshot_day_by_day_fact1 F
LEFT JOIN campaign_username U ON U.id=F.Username_id
WHERE DATE>="2026-01-01"
  AND Username_id=@Username_id
  AND IFNULL(`Tracker_ID`,'')>''
--   AND IFNULL(`Tracker_Name`,'')>''
  -- AND Affiliate='_Unassigned' 
  AND MS_id IS NULL
GROUP BY `Tracker_ID`, CASE WHEN IFNULL(`Tracker_Name`,'')='' THEN `Tracker_ID` ELSE `Tracker_Name` END
;

/* proceso habitual para enviar a Parking --------------------
INSERT INTO `campaign_marketing_source` (
     `Tracklink`            
   , `Tracker_ID`           
   , `Tracker_Name`         
   , `Code_To_Affiliate` 
--    , `Code`
   , `Owner`                  
   , `Source`               
   , `Product`              
   , `Status_id`            
--    , `Affiliate_id`         
   , `Advertiser_id`        
   , `Publisher_id`         
   , `Username_id`          
--    , `Channel_id`           
--    , `Deal_id`              
--    , `Country_Deal`         
--    , `Deal_Valid_From`      
--    , `Product_Deal`          
   , `Description`          
   , `Operator`          
   ) 
   
SELECT 
     @Tracklink            AS `Tracklink`
   , `Tracker_ID` 
   , CASE WHEN IFNULL(`Tracker_Name`,'')='' THEN `Tracker_ID` ELSE `Tracker_Name` END AS `Tracker_Name`  
   , `Tracker_ID`          AS `Code_To_Affiliate`
--    , `Tracker_ID`          AS `Code`
   , U.`Owner`  
   , @Source               AS `Source`   
   , F.`Product` 
   , @Status_id            AS `Status_id`
--    , @Affiliate_id         AS `Affiliate_id`
   , U.`Advertiser_id` 
   , U.`Publisher_id`  
   , F.Username_id         AS `Username_id`   
--    , @Channel_id           AS `Channel_id`
--    , @Deal_id              AS `Deal_id`
--    , @Country_Deal         AS `Country_Deal`
--    , @Deal_Ges_Valid_From  AS `Deal_Valid_From`
--    , F.Product             AS `Product_Deal`
   , @Description          AS `Description`
   , @Operator             AS `Operator`
FROM Snapshot_day_by_day_fact1 F
LEFT JOIN campaign_username U ON U.id=F.Username_id
WHERE DATE>="2026-01-01"
   -- Username_id=@Username_id AND
  AND IFNULL(`Tracker_ID`,'')>''
--   AND IFNULL(`Tracker_Name`,'')>''
  -- AND Affiliate='_Unassigned' 
  AND MS_id IS NULL
GROUP BY `Tracker_ID`, CASE WHEN IFNULL(`Tracker_Name`,'')='' THEN `Tracker_ID` ELSE `Tracker_Name` END
;
*/