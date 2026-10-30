/* 
PROCEDURE_Dash_Aff_Channel.sql() - CPA/Signup/FTD/Click - Dash affiliate Channel 

Descripción:
  Procedimiento Dash_Aff_Channel.
  
Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id del Affiliate_id]. 
Month           =[AAAA-MM | CM | LM ]. OPCIONAL. Default=Current Month
Brand           =[Brand | ALL ]. Nombre de la Brand/advertiser. OPCIONAL. Default=ALL
Channel_id      =[Channel_id | ALL ]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. Default [Yes] OPCIONAL. Columna 1 como METADATO: total/data/setting
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Dash_Aff_Channel(' ');                                   -- ERROR Sin Affiliate_id
call Dash_Aff_Channel('Affiliate_id=ALL,Month=LM');           -- ERROR Affiliate_id=ALL
call Dash_Aff_Channel('Affiliate_id=450,Brand=ALL,Month=LM,debug=ye');  -- OK
call Dash_Aff_Channel('Affiliate_id=450,Month=LM,debug=ye');  -- OK
call Dash_Aff_Channel('Brand=ALL,Month=LM');                  -- ERROR Affiliate_id=""

call Dash_Aff_Channel('Affiliate_id=39,Brand=betclic,Month=LM,debug=no');

08.08.2023 V1     Primera version (basada en Dash_Aff_Brand)
06.10.2023 v1.1   Fix brand=all, Channel_id=all. Eliminada opción ALL en filtros. Eliminado CTEbyBrand
08.11.2023 v1.2   Agregada columna `Total_Comission` para los casos en que hay RS
27.05.2024 v1.3   Tratamiento de Subafiliados
06.08.2024 v1.4   Multi-currency 
04.08.2026 v1.5   Columna RS_Val (suma Revenue_Share_Affiliate si Check_RS_affiliate=1)
*/

DROP PROCEDURE IF EXISTS Dash_Aff_Channel;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_Aff_Channel`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.5 04.08.2026 - Dash_Aff_Channel - Reports by channel - CPA/Reg/FTD/CPA Val'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v1.5 04.08.2026';
SET @Month        =LEFT(CURDATE(),7);
SET @Affiliate_id ='';
SET @Channel_id   ='ALL';
SET @Brand        ='ALL';

SET @Meta         ='YES';
SET @Debug        ='NO';
SET @Filters      ='NO'; -- K 06/2023                                   

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit
-- @InputCommLine: ----5----0----5----0----5----0----5----0--
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);   

   IF lower(@k)='month'         THEN SET @Month        =UPPER(@v); END IF;
   IF lower(@k)='brand'         THEN SET @Brand        =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'  THEN SET @Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='channel_id'    THEN SET @Channel_id   =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='mode'          THEN SET @Mode         =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;

END WHILE;

/************ VALIDACION PARAMETROS ************************************************/

IF @Month='CM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- En views de Afiliado impide pedir @Affiliate_id="ALL"  
IF   @Affiliate_id IN ("","ALL")THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

SET @Month_Report     =@Month;
SET @WhereMonth       =CONCAT(' LEFT(DATE,7)="',@Month,'" ');
SET @WhereAffiliate   =CONCAT(' AND Affiliate_id="',@Affiliate_id,'" ');
SET @WhereBrand       ='';
SET @Wherechannel_id  ='';
SET @CTE_GroupBy      ='';
SET @CTE_OrderBy      =' ORDER BY DATE';

IF @Brand NOT IN ("","ALL") THEN 
   SET @WhereBrand=CONCAT(' AND Brand="',@Brand,'" ');
ELSE   
   SET @CTE_GroupBy=CONCAT(@CTE_GroupBy,' Brand,'); 
END IF; 

IF @channel_id NOT IN ("","ALL") THEN 
   SET @WhereChannel_id=CONCAT(' AND Channel_id="',@Channel_id,'" ');
ELSE   
   SET @CTE_GroupBy=CONCAT(@CTE_GroupBy,' Channel_id,');    
END IF; 

IF @Filters="YES" THEN 
   SET @CTE_OrderBy=' ORDER BY Channel,Brand';
END IF; 

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET @AffiliateGroup=(SELECT group_id FROM account_account_groups 
                     WHERE account_id=@Affiliate_id AND  group_id=6);
IF  @AffiliateGroup IS NULL THEN SET @AffiliateGroup=0; END IF;
/*---------------------------------------------------------------------------------*/

/* **************************************************/

IF @Debug!="NO" THEN SELECT @Debug,@Affiliate_id,@Month_Report,@MultiCurrency,@Currency,@WhereMonth,@WhereAffiliate
                           ,@WhereChannel_id,@WhereBrand,@CTE_GroupBy,@Filters; END IF;


-- SET SESSION group_concat_max_len = 200000;

SET @CTE=CONCAT('              
WITH BaseDataByCurrency as (
   SELECT date,Affiliate_id,Channel,Channel_id,Brand
      ,SUM(Signups)              as `Signups`
      ,SUM(First_Time_Deposit)   as `FTD`
      ,SUM(Qualified_Players)    as `CPA`
      ,Data_Currency
      ,SUM(CPA_Value_Affiliate)  as `CPA_val`
      ,SUM(IFNULL(`Revenue_Share_Affiliate`,0)) as `RS_val`
      ,SUM(
         getCurrencyConversion(CPA_Value_Affiliate,Data_Currency,@Currency)+
         getCurrencyConversion(ifnull(`Revenue_Share_Affiliate`,0),Data_Currency,@Currency)
         )  as `Total_Comission`      
   FROM Snapshot_day_by_day_fact2 F
   WHERE '
      ,@WhereMonth
      ,@WhereAffiliate
      ,@WhereChannel_id      
      ,@WhereBrand
      ,' 
   GROUP BY ',@CTE_GroupBy,' DATE,Data_Currency HAVING `Signups`>0 OR `FTD`>0 OR `CPA`<>0 OR `CPA_val`<>0 OR `RS_val`<>0 OR `Total_Comission`<>0
)
,
BaseData as (
   SELECT date,Affiliate_id,Channel,Channel_id,Brand
      ,SUM(Signups)              as `Signups`
      ,SUM(FTD)                  as `FTD`
      ,SUM(CPA)                  as `CPA`
      ,`Data_Currency`           as `Data_Currency`
      ,SUM(CPA_val)              as `CPA_val`
      ,SUM(RS_val)               as `RS_val`
      ,@Currency                 as `Currency`
      ,SUM(Total_Comission)      as `Total_Comission`     
   FROM BaseDataByCurrency F
   GROUP BY ',@CTE_GroupBy,' DATE,Data_Currency HAVING `Signups`>0 OR `FTD`>0 OR `CPA`<>0 OR `CPA_val`<>0 OR `RS_val`<>0 OR `Total_Comission`<>0
   ',@CTE_OrderBy,'
)
, 
TotalRow as (
   SELECT " --Total--",Affiliate_id," " AS `Channel`," " `Channel_id`," " `Brand`
      ,IFNULL(SUM(Signups),0)   as `Signups`
      ,IFNULL(SUM(FTD),0)       as `FTD`
      ,IFNULL(SUM(CPA),0)       as `CPA`
      ,`Data_Currency`
      ,IFNULL(SUM(CPA_val),0)   as `CPA_val`
      ,IFNULL(SUM(RS_val),0)    as `RS_val`
      ,@Currency                as `Currency`
      ,SUM(Total_Comission)     as `Total_Comission`      
   FROM BaseData F
)');

SET @Check_RS_affiliate=ifnull(Check_RS_affiliate(@Affiliate_id),0);

SET @SQL=concat(
@CTE,'    
SELECT  
   "setting"         as `Meta`
   ,"width=100px"    as `Date`
   ,"omit=true"      as `Affiliate_id` 
   ,'
   ,IF(@Channel_id IN ("","ALL"),'"width=200px"','"omit=true"'), '  as `Channel`
   ,"omit=true"      as `Channel_id` 
   ,'
   ,IF(@Brand IN ("","ALL"),'"width=130px"','"omit=true"'), '       as `Brand`
   ,"width=100px,right=true"    as `Signups`
   ,"width=100px,right=true"    as `FTD`
   ,"width=100px,right=true"    as `CPA`
   ,"width=100px,center=true"   as `Operation Currency`
   ,"width=100px,right=true"    as `CPA val`
   ,',IF(@Check_RS_affiliate=1,'"width=100px,right=true"','"omit=true"'), ' as `RS val`
   ,IF(@MultiCurrency="YES","width=100px,center=true","omit=true") as `Currency`
   ,"width=100px,right=true"    as `Total Comission`   
	FROM DUAL WHERE "',@Meta,'"="YES"
UNION ALL
SELECT "total",T.* FROM TotalRow T
UNION ALL
SELECT "data",T.* FROM BaseData T
;');

/* FILTERING -------------------------------------------------------*/

SET @M0=left(date_sub(curdate(), interval 0 month),7);
SET @M1=left(date_sub(curdate(), interval 1 month),7);
SET @M2=left(date_sub(curdate(), interval 2 month),7);
SET @M3=left(date_sub(curdate(), interval 3 month),7);
SET @M4=left(date_sub(curdate(), interval 4 month),7);
SET @M5=left(date_sub(curdate(), interval 5 month),7);
SET @M6=left(date_sub(curdate(), interval 6 month),7);
SET @M7=left(date_sub(curdate(), interval 7 month),7);

SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "1" as "Korder","Month" AS "Key",@M0     AS "Value","Month" AS `CallKey`,@M0     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M1     AS "Value","Month" AS `CallKey`,@M1     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M2     AS "Value","Month" AS `CallKey`,@M2     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M3     AS "Value","Month" AS `CallKey`,@M3     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M4     AS "Value","Month" AS `CallKey`,@M4     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M5     AS "Value","Month" AS `CallKey`,@M5     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M6     AS "Value","Month" AS `CallKey`,@M6     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1" as "Korder","Month" AS "Key",@M7     AS "Value","Month" AS `CallKey`,@M7     AS "CallValue","" AS "Rows" FROM DUAL) UNION ALL

(SELECT "3" as "Korder","Channel" AS "Key",`Channel` AS "Value","Channel_id" AS `CallKey`,`Channel_id` AS "CallValue"
                                                                       ,COUNT(*) AS "Rows" FROM BaseData GROUP BY `Channel_id`) UNION ALL      
(SELECT "5" as "Korder","Brand" AS "Key",`Brand` AS "Value","Brand" AS `CallKey`,`Brand` AS "CallValue"
                                                                       ,COUNT(*) AS "Rows" FROM BaseData GROUP BY `Brand`)       
;');

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;
IF @Debug!="NO"   THEN SELECT @CTE; END IF;
IF @Debug!="NO"   THEN SELECT @SQLfilters; END IF;

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
IF  @AffiliateGroup=6 THEN
    SET @SQL=REPLACE(@SQL,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
--  SET @SQL=REPLACE(@SQL,"campaign_marketing_source","sub_campaign_marketing_source");
--  SET @SQL=REPLACE(@SQL,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
--  SET @SQL=REPLACE(@SQL,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
--  SET @SQL=REPLACE(@SQL,"account_landing_pages","sub_account_landing_pages");
--  SET @SQL=REPLACE(@SQL,"account_payment_methods","sub_account_payment_methods");
--  SET @SQL=REPLACE(@SQL,"account_account_bills","sub_account_account_bills");
--  SET @SQL=REPLACE(@SQL,"view_monthly_fact_aff4","sub_view_monthly_fact_aff4");
END IF;
/*---------------------------------------------------------------------------------*/

IF @Debug!="NO" THEN SELECT @SQL; END IF;   
IF @Debug!="NO" THEN SELECT @Debug,@Month_Report,@Affiliate_id,@Brand,@Check_RS_affiliate
                           ,@WhereMonth,@WhereAffiliate,@WhereChannel_id,@WhereBrand,@CTE_GroupBy,@Filters; END IF;

IF @Debug != "YES" THEN 
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;   
END IF;

END$$
DELIMITER ;

/* Testing

call Dash_Aff_Channel(' ');                                               -- ERROR Sin Affiliate_id, ni Brand
call Dash_Aff_Channel('Affiliate_id=ALL,Month=LM');                       -- ERROR Affiliate_id=ALL
call Dash_Aff_Channel('Affiliate_id=29,Brand=ALL,Month=CM,Filters=ye,debug=ye');  -- OK
call Dash_Aff_Channel('Brand=ALL,Month=LM');                              -- ERROR Affiliate_id=""
              
call Dash_Aff_Channel('Affiliate_id=39,Brand=ALL,Month=LM,Filters=YEs,debug=YE');
call Dash_Aff_Channel('Affiliate_id=39,Brand=all,channel_id=all,Month=LM,Filters=YE,debug=YE');
call Dash_Aff_Channel('Affiliate_id=826,Month=LM,filters=ye,debug=ye');  -- sub aff

*/
