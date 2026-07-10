/* PROCEDURE_Sync_MS_DbD_DbD_lm_byBrand.sql - Check Last Month Raw data by Brand_id 
                                              Stored data Vs New downloaded data (DbD vs DbD_lm)

Descripción:
  Procedimiento Sync_MS_DbD_DbD_lm_byBrand.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Mode:         = [ view | run ]
                  view=Muestra las diferencias pero no las aplica
                  run=Reemplaza contenido de DbD por DbD_LM para el Last Month
Brand         =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
Meta          =[No | Yes]. [yes] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Debug         =[No | Yes ]. [No] NO EJECUTA QUERY y devuelve el código del Query. 

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Sync_MS_DbD_DbD_lm_byBrand(' '); -- Asumirá todos los defaults
call Sync_MS_DbD_DbD_lm_byBrand('mode=view,Brand=lotomattica,debug=no'); 

09.09.2022 V1  Primera versión. Copia lógica de PROCEDURE_Sync_MS_DbD_DbD_lm
   
   
*/
DROP PROCEDURE IF EXISTS Sync_MS_DbD_DbD_lm_byBrand;

DELIMITER $$
CREATE PROCEDURE Sync_MS_DbD_DbD_lm_byBrand(IN
   InputCommLine    VARCHAR(250)
   )
   
   COMMENT 'Check/Update LM Raw data by Brand: Stored data Vs New downloaded data (DbD vs DbD_lm)'
   LANGUAGE SQL

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 27.12.2023';
SET @Brand           ='ALL';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @LastMonth       =concat("'",LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),"' ");
SET @Meta            ='YES';
SET @Mode            ='VIEW';
SET @Username        ='ALL';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
--  @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- @InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);  
   
   if lower(@k)='brand'           THEN SET @Brand         =UPPER(@v); END IF;
   if lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   if lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   if lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   if lower(@k)='mode'            THEN SET @Mode          =UPPER(@v); END IF;
   if lower(@k)='username'        THEN SET @Username      =UPPER(@v); END IF;

END WHILE;

IF @Mode!='RUN' then SET @Debug='YES'; END IF;

SET @WhereBrand ='';
SET @WhereUsername='';

IF @Brand !="ALL" THEN SET @WhereBrand=CONCAT(" AND Brand='",@Brand,"' "); END IF;

SET SESSION group_concat_max_len = 200000;

-- -------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------

SET @SQL=CONCAT('DELETE FROM Snapshot_day_by_day WHERE LEFT(Date,7)=',@LastMonth,@WhereBrand,';');
SET @SQL1=CONCAT('
INSERT IGNORE INTO Snapshot_day_by_day 
   SELECT * FROM Snapshot_day_by_day_lm WHERE LEFT(Date,7)=',@LastMonth,@WhereBrand,';');

SET @SQLview=CONCAT('
with LM_minus_Dbd as (
   SELECT "" as Meta
         ,Brand
         ,X.Username AS "Username_id"
         ,U.Username
         ,Tracker_ID
         ,Tracker_name
         ,X.Product
         ,SUM(CPA_DbD)        AS CPA_DbD
         ,SUM(CPA_LM)         AS CPA_LM
         ,sum(CPA_LM-CPA_DbD) AS DIFF
			,SUM(NR_DbD)         AS NR_DbD 
         ,SUM(NR_LM)          AS NR_LM 
	FROM (
      SELECT "DbD" AS `Table`,Brand,Username,Tracker_ID,Tracker_name,Product
            ,SUM(Qualified_players) AS CPA_DbD,0 AS CPA_LM
            ,SUM(Net_Revenue)       AS NR_DbD ,0 AS NR_LM
      FROM Snapshot_day_by_day WHERE LEFT(DATE,7)=',@LastMonth,@WhereBrand,'
      GROUP BY Brand,Username,Tracker_ID
      UNION ALL -- -----------------------------
      SELECT "LM"  AS `Table`,Brand,Username,Tracker_ID,Tracker_name,Product
            ,0 AS CPA_DbD,SUM(Qualified_players) AS CPA_LM
            ,0 AS NR_DbD ,SUM(Net_Revenue)       AS NR_LM 
      FROM Snapshot_day_by_day_lm WHERE LEFT(DATE,7)=',@LastMonth,@WhereBrand,'
      GROUP BY Brand,Username,Tracker_ID
   ) AS X
	LEFT JOIN campaign_username U ON U.id=X.Username
-- where @warning_CPA!="yes"
	GROUP BY Brand,X.Username,Tracker_ID having DIFF<>0 OR SUM(NR_DbD) <> SUM(NR_LM)      -- 05.10.2022
)
   SELECT 
    D.Meta,D.Brand,D.Username_id AS `Acct id`,D.Username
   ,M.id as `MS_id`
   ,D.Tracker_ID,D.Tracker_name,D.Product
   ,IFNULL(`A`.`username`, "_Unassigned") AS `Affiliate`
   ,CPA_DbD,CPA_LM,DIFF,NR_DbD,NR_LM
   FROM LM_minus_Dbd D
   -- ----------------------------Seleccion MS----------------------------------------------
   LEFT JOIN LATERAL (                                                                        
      SELECT                                                                                  
         CASE  WHEN M.Tracker_ID = D.Tracker_ID and M.Tracker_Name = D.Tracker_Name then 4    
               WHEN M.Tracker_ID = D.Tracker_ID then 3                                        
               WHEN M.Tracker_Name = D.Tracker_Name then 2                                    
               ELSE 1 END AS MatchValue                                                       
         ,M.* FROM campaign_marketing_source M                                                
      WHERE M.Username_id = D.Username_id AND                                                    
         (D.Tracker_ID IN (M.Tracker_ID,M.Tracker_Name)                                       
      OR  D.Tracker_Name IN (M.Tracker_ID,M.Tracker_Name))                                    
      ORDER BY MatchValue DESC LIMIT 1                                                        
      ) AS M ON true                                                                          
   -- ----------------------------Seleccion de Affiliate------------------------------------
   LEFT JOIN LATERAL (                                                                        
      SELECT *,ROW_NUMBER() OVER(PARTITION BY MS_id ORDER BY Deal_Valid_From DESC) AS RowNr   
      FROM `campaign_mkt_source_deal` WHERE `MS_id` = M.id AND `is_active` = 1                
                                       -- AND `Deal_Valid_From` <= `D`.`Date`                   
      ORDER BY RowNr LIMIT 1                                                                  
   ) AS M2 ON TRUE                                                                            
   -- ----------------------------Seleccion de producto-------------------------------------  
   LEFT JOIN `account_account` `A` ON `A`.`id` = `M2`.`Affiliate_id`                                                                          
   -- --------------------------------------------------------------------------------------

   UNION ALL
   SELECT ""," Total Diff ","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~","~~~~~",SUM(CPA_DbD),SUM(CPA_LM),sum(DIFF),SUM(NR_DbD),SUM(NR_LM)
	from LM_minus_Dbd 
   
   UNION ALL
   SELECT
   "setting" as Meta
   ,"width=150px" as "1"
   ,"width=80px"  as "2"
   ,"width=150px" as "3"
   ,"width=90px"  as "4"
   ,"width=100px" as "5"

   ,"width=200px" as "6"
   ,"width=100px" as "7"
   ,"width=150px" as "8"

   ,"width=100px" as "9"
   ,"width=100px" as "10"
   ,"width=100px" as "11"
   ,"width=100px" as "12"
   ,"width=100px" as "13"
   FROM DUAL WHERE @Meta="YES"
  
   ORDER BY 
       CASE WHEN `DIFF`=0 or Brand=" Total Diff" THEN 0 ELSE 1 END DESC
      ,Brand,Username,`DIFF` DESC;
');

IF @Debug!="NO" THEN SELECT @Mode,@Filters,@Brand,@Username,@Debug,@Meta,@LastMonth,@WhereBrand,InputCommLine; END IF;
IF @Debug!="NO" THEN SELECT @SQL,@SQL1,@SQLview; END IF;

IF @Mode!="RUN" OR @Debug="YES" THEN

	PREPARE stmt1 FROM @SQLview;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

ELSE 

   PREPARE stmt1 FROM @SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
   
   PREPARE stmt2 FROM @SQL1;
   EXECUTE stmt2;
   DEALLOCATE PREPARE stmt2;

END IF;

END$$
DELIMITER ;

/*

call Sync_MS_DbD_DbD_lm_byBrand(' '); -- Asumirá todos los defaults
call Sync_MS_DbD_DbD_lm_byBrand('mode=runa,brand=BetFair '); 
call Sync_MS_DbD_DbD_lm_byBrand('mode=view,Brand=lotomattica,debug=no');


*/