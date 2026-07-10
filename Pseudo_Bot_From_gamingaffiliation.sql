/* Pseudo_Bot_From_gamingaffiliation
   18.11.2022 V1
   
*/
    
IF DAY(CURDATE()) <= 3 THEN
     SET @MesCorriente = LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
ELSE SET @MesCorriente = LEFT(CURDATE(),7);
END IF;

DELETE FROM euroaffiliati2.Snapshot_day_by_day WHERE LEFT(DATE,7)>=@MesCorriente 
      AND Username in ('133','134'); -- Brand='eurobet','GiocoDigitale'
    
INSERT IGNORE INTO Snapshot_day_by_day (
`Date`,`Username`
,`Portal`,`Brand`,`Tracker_ID`,`Tracker_Name`,`Code_To_Affiliate`,`Product`
`Qualified_Players`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`,`Impressions`
,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`
,`Turnover`,`Net_Revenue`,`Revenue_Share_Gestor`,`CPA_Value_Gestor` 
FROM table
)
SELECT
Date
,(CASE Brand
   WHEN 'eurobet' THEN '133'
   WHEN 'GiocoDigitale' THEN '134'
   ELSE 'ERROR' END) AS Username
,'DirectAccess',Brand,Tracker_ID,Tracker_Name,Code_To_Affiliate,Product
,Qualified_Players,First_Time_Deposit,Views,Clicks,Signups,Impressions
,Sign_Up_Offer,Type,Language,Deposits,Depositing_Customers,Active_Customers
,New_Depositing_Customers,New_Active_Customers,First_Time_Active_Customers
,Turnover,Net_Revenue,Revenue_Share_Affiliate,CPA_Value_Affiliate
FROM gamingaffiliation.Snapshot_day_by_day_fact1
WHERE left(DATE,7)>=@MesCorriente AND Affiliate_id='345'
;

