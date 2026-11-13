/*
PROCEDURE_Report_MultiQuery_v1.sql - Grid con Multi queries - (Detailed Reports)

Descripción:
  Procedimiento Report_MultiQuery.
Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id del Affiliate_id].
TypeReport      =[Default | DashCeo ]. OPCIONAL. Default=Default
Meta            =[No | Yes]. Default [Yes] OPCIONAL. Columna 1 como METADATO: total/data/setting
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_MultiQuery('Affiliate_id=177,TypeReport=DashCeo,debug=ye'); 

Log modificaciones:

12.09.2023 V1     Primera version
14.09.2023 V1.1   Karen. multi_query_account
20.03.2025 v1.3   Karen. Adaptación CEO's dashboard settings 
05.05.2025 v1.3.1 Karen. Order Ceo
13.05.2026 v1.3.2 Karen. Fix

*/

DROP PROCEDURE IF EXISTS Report_MultiQuery;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_MultiQuery`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Grid con Multi queries'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v1.3.2 13.05.2026';
SET @Month        =LEFT(CURDATE(),7);
SET @Account_id   ='2';
SET @TypeReport   ='Default';   -- 20.03.2025                                             

SET @Meta         ='YES';
SET @Debug        ='NO';
SET @Filters      ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

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

   IF lower(@k)='TypeReport'    THEN SET @TypeReport   =UPPER(@v); END IF; -- 20.03.2025                                                                                       
   IF lower(@k)='Account_id'    THEN SET @Account_id   =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Account_id,@TypeReport,@debug,@meta,@Filters; END IF;

/* **************************************************/

SET @CTE=CONCAT('
WITH BaseData as (
   SELECT 
	   CAST(order_ceo AS CHAR)
		,title
      ,Descr_IT
      ,Descr_ES
      ,Descr_EN
      ,code
      ,params_Procedure
      ,is_Procedure
      ,is_Filter
      ,Procedure_call
		,mq.id
      ,CASE WHEN @TypeReport="DashCeo" 
            THEN IFNULL(mqa.is_checked_ceo,0) 
            ELSE IFNULL(mqa.is_checked,0) 
            END as `checked`
		,IFNULL(mqa.language,"EN")
		,CASE WHEN mqa.language="IT" AND Descr_IT IS NOT NULL THEN Descr_IT
            WHEN mqa.language="ES" AND Descr_ES IS NOT NULL THEN Descr_ES
            WHEN mqa.language="EN" AND title    IS NOT NULL THEN title
            ELSE title END
		,mqa.id as id_mqa
		,mq.Orden
   FROM multi_query mq
	LEFT JOIN multi_query_account mqa ON mq.id=mqa.multi_query_id AND mqa.account_id=',@Account_id,'
   WHERE case when @TypeReport="CheckSync" THEN params_Procedure like "%Page=Check&Sync%"  
				else params_Procedure not like "%Page=Check&Sync%" end   -- K11.05.2026
   ORDER BY `checked` DESC, order_ceo ASC
)
');

SET @SQL=concat(
@CTE,'
SELECT
   "setting"         as `Meta`
	,IF(@TypeReport = "DashCeo", "width=120px", "omit=true") as `Priority`  -- 24.04.2025
   ,"width=400px"    as `Name`
   ,"width=500px,tooltip=yes"  as `Descr IT`
   ,"width=500px,tooltip=yes"  as `Descr ES`
   ,"width=200px,tooltip=yes,omit=true"  as `Descr EN`
   ,"omit=true"      as `code`
   ,"omit=true"      as `params_Procedure`
   ,"omit=true"      as `is_Procedure`
   ,"omit=true"      as `is_Filter`
   ,"omit=true"      as `5`
	,"omit=true"      as `id`
	,"omit=true"      as `checked`
	,"omit=true"      as `check_language` 
	,"omit=true"      as `descr_language` 
	,"omit=true"      as `id_mqa` 
	,"omit=true"      as `orden`                               
	FROM DUAL
UNION ALL
SELECT "data",T.* FROM BaseData T
ORDER BY 
    `checked` DESC,                 
    CASE 
        WHEN `Descr IT` IS NULL THEN 1 
        ELSE 0 
    END,
   ',CASE
        WHEN @TypeReport = "DashCeo"    THEN " `Priority` ASC"
        WHEN @TypeReport = "CheckSync"  THEN " `orden` ASC"   -- K 13.05.2026
        ELSE                                 " `Descr IT` ASC"
    END,
';'
);

IF @Debug!="NO" THEN SELECT @CTE; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/* Testing

call Report_MultiQuery('Affiliate_id=177,TypeReport=DashCeo,debug=ye'); 


*/