with Monthly_Data as (
   SELECT `Date`,`Advertiser`,`Username`,`Username_id`,`Prodotto`,`Customer_Reference_ID`,`Alias`
         ,`Country`,`Signup_Date`,`Reward_Plan`,`Marketing_Source_Name`,`URL`,`Expiry_Date`
         ,`Customer_Type`,`CPA_Processed_Date`,`Brand`,`Customer_Signup_Source`,`Deposits`
         ,`Adj_(Chargebacks)`,`Total_Net_Revenue`,`Total_Net_Revenue_MTD`,`Turnover`
         ,`Details`
         ,(case when LEFT(`Date`,7)=DATE_FORMAT(STR_TO_DATE(CPA_Processed_Date, '%d-%m-%Y'), '%Y-%m')
               then 1 else 0 end) as `CPA`
   FROM players_netrefer
   WHERE DATE BETWEEN '2023-09-01' AND '2023-09-30'
)
SELECT `Date`,`Advertiser`,`Username`,`Username_id`
		,IFNULL(`Prodotto`,'') AS `Prodotto`
		,`Country`
		,`Reward_Plan`
		,`Marketing_Source_Name`
		,IFNULL(`Brand`,'') AS `Brand`
		,ROUND(SUM(IFNULL(`Deposits`             ,0)),2) AS `Deposits`
		,ROUND(SUM(IFNULL(`Adj_(Chargebacks)`    ,0)),2) as `Adj_(Chargebacks)`
		,ROUND(SUM(IFNULL(`Total_Net_Revenue`    ,0)),2) as `Total_Net_Revenue`
		,ROUND(SUM(IFNULL(`Total_Net_Revenue_MTD`,0)),2) as `Total_Net_Revenue_MTD`
		,ROUND(SUM(IFNULL(`Turnover`             ,0)),2) as `Turnover`
		,ROUND(SUM(IFNULL(`CPA`                  ,0)),0) as `CPA`
FROM Monthly_Data
GROUP BY DATE,Advertiser,ifnull(Brand,''),Username_id,Marketing_Source_Name,Prodotto,Reward_Plan,Country
;