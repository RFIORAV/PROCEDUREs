SELECT 
    `Month`
   ,`Owner`
   ,`Area`
   ,`Data_Currency`
   ,`Comm_type`
   ,`Publisher`
   ,`Brand`
   ,`Product`
   ,`CarryOver`
   ,`RS_Base`
   ,COUNT(*) AS total_registros
   ,SUM(`CPA`) AS total_CPA
   ,SUM(`Net_Revenue`) AS total_Net_Revenue
   ,SUM(`gross_CPA_Val`) AS total_gross_CPA
   ,SUM(`gross_RS_Val`) AS total_gross_RS
   ,SUM(`net_CPA_Val`) AS total_net_CPA
   ,SUM(`net_RS_Val`) AS total_net_RS
   ,SUM(`net_Total_comm`) AS total_net_Total_comm
   ,SUM(`RS_CarryOver_Pend`) AS total_RS_CarryOver_Pend
FROM 
    `monthly_comms_gestor_v5`
GROUP BY 
    `Month`
   -- ,`Owner`
   -- ,`Area`
   ,`Data_Currency`z
   -- ,`Comm_type`
   -- ,`Publisher`
   ,`Brand`
   -- ,`Product` 
   -- ,`CarryOver`
   -- ,`RS_Base`
ORDER BY 
    `Month` DESC 
   ,`Data_Currency` ASC 
   ,`Brand` ASC;
    
    
SELECT 
    `Month`
   -- ,`Owner`
   -- ,`Account_id`
   ,`Comm_type`
   ,`Affiliate`
   ,`Brand`
   ,`Currency`
   ,`Sub_Affiliate`
   -- ,`Product`
   -- ,`Product_Real`
   -- ,`Channel`
   ,COUNT(*) AS total_registros
   ,SUM(`CPA`) AS total_CPA
   ,SUM(`Net_Revenue`) AS total_Net_Revenue
   ,SUM(`gross_CPA_Val`) AS total_gross_CPA
   ,SUM(`gross_RS_Val`) AS total_gross_RS
   ,SUM(`net_CPA_Val`) AS total_net_CPA
   ,SUM(`net_RS_Val`) AS total_net_RS
   ,SUM(`net_Total_comm`) AS total_net_Total_comm
   ,SUM(`RS_carry_NCO`) AS total_RS_carry_NCO
FROM 
    `monthly_comms_affiliate_v5`
GROUP BY 
    `Month`
   -- ,`Owner`
   -- ,`Account_id`
   -- ,`Comm_type`
   ,`Affiliate`
   ,`Brand`
   ,`Currency`
   -- ,`Sub_Affiliate`
   -- ,`Product`
   -- ,`Product_Real`
   -- ,`Channel`
ORDER BY 
    `Month` DESC 
   ,`Affiliate` ASC 
   ,`Brand` ASC;   