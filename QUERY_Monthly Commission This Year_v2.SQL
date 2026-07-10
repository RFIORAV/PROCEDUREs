SELECT Brand,sum(net_Total_comm) AS Tot_Com
,SUM(net_Total_comm) AS "Total"
,SUM(CASE WHEN RIGHT(`Month`,2)="01" THEN net_Total_comm ELSE 0 END) AS "M01"
,SUM(CASE WHEN RIGHT(`Month`,2)="02" THEN net_Total_comm ELSE 0 END) AS "M02"
,SUM(CASE WHEN RIGHT(`Month`,2)="03" THEN net_Total_comm ELSE 0 END) AS "M03"
,SUM(CASE WHEN RIGHT(`Month`,2)="04" THEN net_Total_comm ELSE 0 END) AS "M04"
,SUM(CASE WHEN RIGHT(`Month`,2)="05" THEN net_Total_comm ELSE 0 END) AS "M05"
,SUM(CASE WHEN RIGHT(`Month`,2)="06" THEN net_Total_comm ELSE 0 END) AS "M06"
,SUM(CASE WHEN RIGHT(`Month`,2)="07" THEN net_Total_comm ELSE 0 END) AS "M07"
,SUM(CASE WHEN RIGHT(`Month`,2)="08" THEN net_Total_comm ELSE 0 END) AS "M08"
,SUM(CASE WHEN RIGHT(`Month`,2)="09" THEN net_Total_comm ELSE 0 END) AS "M09"
,SUM(CASE WHEN RIGHT(`Month`,2)="10" THEN net_Total_comm ELSE 0 END) AS "M10"
,SUM(CASE WHEN RIGHT(`Month`,2)="11" THEN net_Total_comm ELSE 0 END) AS "M11"
,SUM(CASE WHEN RIGHT(`Month`,2)="12" THEN net_Total_comm ELSE 0 END) AS "M12"
from monthly_comms_affiliate
WHERE Affiliate_id=453 AND `Month`>=left(date_sub(CURDATE(),INTERVAL 11 MONTH),7)
GROUP BY Brand WITH ROLLUP 
HAVING sum(net_Total_comm)<>0