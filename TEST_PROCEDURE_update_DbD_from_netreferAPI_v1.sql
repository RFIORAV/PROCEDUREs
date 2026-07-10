

SET @Month=LEFT(CURDATE(),7),@DB="affiliaterevolution",@Brand="Snai", @Username="124" ;

-- CREATE TABLE IF NOT EXISTS Snapshot_day_by_day_temp_NR_AR LIKE Snapshot_day_by_day;

-- INSERT IGNORE INTO Snapshot_day_by_day_temp_NR_AR
--    SELECT * FROM Snapshot_day_by_day
--             WHERE LEFT(DATE,7)=@Month AND Database()=@DB AND `Brand`=@Brand AND `Username`=@Username
-- ;            
-- DELETE FROM Snapshot_day_by_day_temp_NR_AR
DELETE FROM Snapshot_day_by_day
    WHERE LEFT(DATE,7)=@Month AND Database()=@DB AND `Brand`=@Brand AND `Username`=@Username
      AND `Portal`="SNAI deal adjust"
;
-- INSERT IGNORE INTO Snapshot_day_by_day_temp_NR_AR (
INSERT IGNORE INTO Snapshot_day_by_day (
   `Portal`
   ,`Date`
   ,`Hour_Update`
   ,`Brand`
   ,`Username`
   ,`Product`
   ,`Country`
   ,`Sign_Up_Offer`
   ,`Tracker_Name`
   ,`Tracker_ID`
   ,`Level_Reached`
   ,`Brand_Name`   
   ,`Qualified_Players`          
   ,`Signups`   
   ,`Deposits`             
   ,`Net_Revenue`
   ,`Turnover`               
)
SELECT
    -- "Old deal",
    "SNAI deal adjust" AS `Portal`,
    `Date`,
     CURRENT_TIMESTAMP(),
    `Brand`,
    `Username`,
    `Sign_Up_Offer` as `Product`,
    `Country`,
    `Sign_Up_Offer`,
    `Tracker_Name`,
    `Tracker_ID`,
    `Level_Reached`,
    `Brand_Name`,
    SUM(`Qualified_Players`) AS `Qualified_Players`,
    SUM(`Signups`) AS `Signups`,
    SUM(`Deposits`) AS `Deposits`,
    SUM(`Net_Revenue`) AS `Net_Revenue`,
    SUM(`Turnover`) AS `Turnover`
FROM Snapshot_day_by_day_temp_NR NR
WHERE LEFT(DATE,7)=@Month
  AND Database()=@DB AND `Brand`=@Brand AND `Username`=@Username
  AND NR.`Product` LIKE "%-20"
GROUP BY `Username`,`Tracker_ID`,`Tracker_Name`,NR.`Product`,`Sign_Up_Offer`

UNION ALL

-- Segunda fila con Net_Revenue cambiado de signo
SELECT
    -- "New deal",
    "SNAI deal adjust" AS `Portal`,    
    `Date`,
     CURRENT_TIMESTAMP(),    
    `Brand`,
    `Username`,
    REPLACE(`Product`,"-20","") AS `Productok`,
    `Country`,
    "" as `Sign_Up_Offer`,
    `Tracker_Name`,
    `Tracker_ID`,
    `Level_Reached`,
    `Brand_Name`,
    -SUM(`Qualified_Players`) AS `Qualified_Players`,
    -SUM(`Signups`) AS `Signups`,
    -SUM(`Deposits`) AS `Deposits`,
    -SUM(`Net_Revenue`) AS `Net_Revenue`,
    -SUM(`Turnover`) AS `Turnover`
FROM Snapshot_day_by_day_temp_NR NR
WHERE LEFT(DATE,7)=@Month
  AND Database()=@DB AND `Brand`=@Brand AND `Username`=@Username
  AND NR.`Product` LIKE "%-20"
GROUP BY `Username`,`Tracker_ID`,`Tracker_Name`,`Product`,`Sign_Up_Offer`

;