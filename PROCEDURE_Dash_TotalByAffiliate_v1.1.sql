/*
PROCEDURE_Dash_TotalByAffiliate.sql - Dashboard Gestor/Affiliate. Tot x Affiliate/ALL - Currency conversion

Descripción:
  Procedimiento Dash_TotalByAffiliate.

Keys:

Parámetros obligatorios:

AreaUser        =[ViewGES | ViewAFF]. Default=ViewAFF
AffiliateID     =[ALL | id del Affiliate]. Default=ALL
Month           =[AAAA-MM | CM | LM]. Default=Current Month.
Owner           =[ALL | id del Owner]. Default=ALL
Curr_result     =[ Data_Currency]. Default=EUR
RollUp          = RollUp de totales. Default=NO

Ejemplos:

call Dash_TotalByAffiliate('ViewGES','ALL','2024-02','ALL','EUR','ROLLUP');
call Dash_TotalByAffiliate('ViewGES','ALL','LM','ALL','EUR','ROLLUP');

07.09.2022 V1     Primera versión operativa
21.03.2024 v1.1   Admite Month como LM/CM
*/

DROP PROCEDURE IF EXISTS `Dash_TotalByAffiliate`;

DELIMITER ;;

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_TotalByAffiliate`(IN
   AreaUser    VARCHAR(50),
   AffiliateID VARCHAR(50),
   Month       VARCHAR(7),
   Owner       VARCHAR(50),
   Curr_result VARCHAR(3),
   RollUp      VARCHAR(6)
   )
    COMMENT 'Dashboard Gestor. Tot x Affiliate/ALL - Currency conversion'
BEGIN

SET @Version         ='v1.1 21.03.2024';
SET @Debug           ='NO';

	IF upper(AffiliateID)='ALL' THEN
   	SET @WhereAffiliateID='';
   ELSE
   	SET @WhereAffiliateID=concat(' AND Affiliate_id=',CAST(AffiliateID AS UNSIGNED INTEGER));
	END IF;
	IF LOWER(ifnull(Owner,'ALL'))='all' THEN
   	SET @WhereOwner='';
   ELSE
   	SET @WhereOwner=concat(' AND Owner=',CAST(Owner AS UNSIGNED INTEGER));
	END IF;

	IF Month is not null THEN
      SET @Month_Report=Month;
      IF  Month = "CM" THEN SET @Month_Report=LEFT(CURDATE(),7); END IF;
      IF  Month = "LM" THEN SET @Month_Report=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;
   ELSE
      SET @Month_Report=LEFT(CURDATE(),7);
	END IF;
   
	IF LOWER(ifnull(RollUp,''))='rollup' THEN
      SET @RollUp=' WITH ROLLUP ';
   ELSE
      SET @RollUp='';
	END IF;
   
   
   SET @Goup_by=' GROUP BY Owner,Affiliate '; 

   IF upper(Curr_result)='ALL' THEN
      SET @Curr_result=CONCAT('"',upper(Curr_result),'"');
      SET @Goup_by=' GROUP BY Owner,Data_Currency,Affiliate ';
   ELSE
      SET @Curr_result=CONCAT('"',upper(Curr_result),'"');
      
      
	END IF;
   
	IF AreaUser='ViewGES' THEN
      SET @DataTable=" FROM Snapshot_day_by_day_fact1 ";
      SET @SQL_Select='
      ,ROUND(SUM(CPA_Value_Gestor)       /xx.Coef,2) AS `CPA_Value_Gestor`
      ,ROUND(SUM(Net_Revenue)            /xx.Coef,2) AS `Net_Revenue`
      ,ROUND(SUM(Revenue_Share_Gestor)   /xx.Coef,2) AS `RS_Gestor`
      ,ROUND(SUM(CPA_Value_Affiliate)    /xx.Coef,2) AS `CPA_Value_Affiliate`
      ,ROUND(SUM(Revenue_Share_Affiliate)/xx.Coef,2) AS `RS_Affiliate`
      ,ROUND((SUM(CPA_Value_Gestor)-SUM(CPA_Value_Affiliate)
                                        )/xx.Coef,2) AS `CPA_Profit` \r\n';
      SET @Having=' HAVING `CPA`<>0 OR `RS_Affiliate`<>0 ORDER BY Owner,Data_Currency,Affiliate';                                          
   ELSE
      SET @DataTable=" FROM Snapshot_day_by_day_fact2 ";
      SET @SQL_Select='
      ,ROUND(SUM(Net_Revenue)            /xx.Coef,2) AS `Net_Revenue`
      ,ROUND(SUM(CPA_Value_Affiliate)    /xx.Coef,2) AS `CPA_Value_Affiliate`
      ,ROUND(SUM(Revenue_Share_Affiliate)/xx.Coef,2) AS `RS_Affiliate`
      ,SUM(`First_Time_Deposit`) AS `FTD`
      ,SUM(`Views`             ) AS `Views`             
      ,SUM(`Clicks`            ) AS `Clicks`            
      ,SUM(`Signups`           ) AS `Signups`           
      ,SUM(`Impressions`       ) AS `Impressions` \r\n';      
      SET @Having=' HAVING `CPA`<>0 OR `RS_Affiliate`<>0 ORDER BY Owner,Data_Currency,Affiliate';                                          
	END IF;   
   
   
   
   SET SESSION group_concat_max_len = 100000;
   
   SET @SQL = CONCAT(
   'SELECT Owner,left(Date,7) as `Month`
   	,IF(',@Curr_result,'="ALL",Data_Currency,',@Curr_result,') as `Data_Currency`
   	,`Affiliate`
      ,SUM(Qualified_Players) AS `CPA`'
   ,@SQL_Select
   ,@DataTable
   ,' LEFT JOIN LATERAL (SELECT
     (SELECT Rate FROM exchange_rate x WHERE x.Currency=Data_Currency)/
     (SELECT Rate FROM exchange_rate x WHERE x.Currency='
     ,'IF(',@Curr_result,'="ALL",Data_Currency,',@Curr_result,')) as Coef ) 
      AS xx ON TRUE
   WHERE LEFT(DATE,7)="',@Month_Report,'" '
   ,@WhereAffiliateID
   ,@WhereOwner,'\r\n'
   ,@Goup_by,@RollUp,@Having,';');

IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END ;;
DELIMITER ;

/*
call Dash_TotalByAffiliate('ViewGES','ALL','2024-02','ALL','EUR','ROLLUP');
call Dash_TotalByAffiliate('ViewAFF','ALL','LM','ALL','EUR','ROLLUP');
*/