
WITH CommsByMonth AS (
SELECT 
   Date
   ,Brand
   ,Username
   ,`Username_id`
   ,`Product`
   ,`CPA`
   ,`Data_Currency`
   ,`CPA_Value`
   ,`Net_Revenue`
   ,(@NR_balance_NCO := case when @Username_id_ant!=Username_id then `Net_Revenue`
                              else case when @NR_balance_NCO>0 then `Net_Revenue` 
                                        else @NR_balance_NCO+`Net_Revenue` end
                              end) AS `NR_balance_NCO`
   ,@Username_id_ant:=Username_id AS `UsIdAnt`
   ,(@RS_Value_NCO_gross:=ROUND(@NR_balance_NCO*`Ges_RS`/100.001,2)                          AS `RS_Value_NCO_gross`
   ,(@RS_Value_NCO      :=if(@NR_balance_NCO>0,ROUND(@NR_balance_NCO*`Ges_RS`/100.001,2),0)) AS `RS_Value_NCO`
   ,(@RS_Value_gross    :ROUND(`Net_Revenue`*`Ges_RS`/100.001,2),0)	                        AS `RS_Value_gross`   
   ,(@RS_Value          :=if(`Net_Revenue`>0,  ROUND(`Net_Revenue`  *`Ges_RS`/100.001,2),0))	AS `RS_Value`   
--    ,`RS_AJUST`
	, case when `Ges_RS_Against_CPA`=1 then
			 case when `Ges_Carry_Over`= 1 
               then case when @RS_Value_NCO_gross<0 
                         then case when `CPA_Value`>=ABS(Value_NCO_gross)
                         (@SubtractFromCPA:=`CPA_Value`-ABS(Value_NCO_gross)) end
               else case when @RS_Value_gross<0 then (@SubtractFromCPA:=`CPA_Value`-ABS(RS_Value_gross)) end
			 		case when `CPA_Value`>
   ,`CPA_Val_AJ_RS`
   ,`Total_Commission`
   ,`Ges_id_Deal`
   ,`Ges_CPA`
   ,`Ges_Carry_Over`
   ,`Ges_RS_Against_CPA`
   ,`Ges_RS_Base`
   ,`Ges_RS`
   ,`Ges_Valid_From`   
FROM `view_monthly_fact_gestor3` 
-- WHERE Username_id IN ('10','21')
ORDER BY Username_id, DATE
)
SELECT
   Date
   ,Brand
   ,Username
   ,`Username_id`
   ,`Product`
   ,`CPA`
   ,`Data_Currency`
   ,`CPA_Value`
   ,`Net_Revenue`
   ,`NR_balance_NCO`
   ,`RS_Value_NCO`
   ,`RS_Value`
   ,`RS_AJUST`
   ,`CPA_Val_AJ_RS`
   ,`Total_Commission`
   ,`Ges_id_Deal`
   ,`Ges_CPA`
   ,`Ges_Carry_Over`
   ,`Ges_RS_Against_CPA`
   ,`Ges_RS_Base`
   ,`Ges_RS`
   ,`Ges_Valid_From` 
FROM CommsByMonth
ORDER BY Username_id, DATE
;
