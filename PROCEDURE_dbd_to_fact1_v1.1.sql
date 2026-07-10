/*
PROCEDURE_DbD_to_fact1.sql

Descripción:
  Procedimiento DbD_to_fact1.

   	**	Actualiza tabla Snapshot_day_by_day_fact1 desde Snapshot_day_by_day
      ** Igual que Snapshot_day_by_day_fact1_upd_from_dbd pero con parámetros de entrada

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month           =[AAAA-MM | CM | LM | ALLALL]. OPCIONAL. Default=CM=Current Month. (ALLALL indica procesar toda la tabla desde el principio)
Publisher_id    =[ALL | Affiliate_id ]. OPCIONAL. Default=ALL
Advertiser_id   =[ALL | SubAffiliate_id ]. OPCIONAL. Default=ALL
Account_id      =[ALL | Status_id ]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call DbD_to_fact1('MS_id=130,debug=no');

15.05.2024 V1     Snapshot_day_by_day_fact1_upd_from_dbd con Parámetros: Month, Publisher_id, Advertiser_id, Account_id
09.04.2025 v1.1   PROCESO ALLALL RESTINGIDO A affiliateaccess (db demo)
                  IF @Month='ALLALL' AND DATABASE()="affiliateaccess"
*/

DROP PROCEDURE IF EXISTS DbD_to_fact1;
-- -------------------------------------------------------------
DELIMITER //

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `DbD_to_fact1`(IN
   InputCommLine    VARCHAR(250)
   )
COMMENT 'Actualiza FACT1 desde DbD - Parámetros: Month, Publisher_id, Advertiser_id, Account_id'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

proc_label:BEGIN

SET @Version         ='v1.1 09.04.2025';
SET @CurrentDay      =curdate();
-- Month, Publisher_id, Advertiser_id, Account_id
SET @Month           =left(curdate(),7);
SET @Publisher_id    ='all';
SET @Advertiser_id   ='all';
SET @Account_id      ='all';

SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

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

   IF lower(@k)='month'           THEN SET @Month         =UPPER(@v); END IF;
   IF lower(@k)='publisher_id'    THEN SET @Publisher_id  =      @v;  END IF;
   IF lower(@k)='advertiser_id'   THEN SET @Advertiser_id =      @v;  END IF;
   IF lower(@k)='account_id'      THEN SET @Account_id    =     (@v); END IF;
   
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

/************ VALIDACION PARAMETROS ************************************************/

SET @TableToProcess="`Snapshot_day_by_day`"; -- Table to process
SET @ProcessALL="1=2"; -- Flag negativo
IF @Month='ALLALL' AND DATABASE()="affiliateaccess"
   THEN SET @Month="2022-01"; 
        SET @ProcessALL="1=1"; -- Flag positivo
        SET @TableToProcess="`Snapshot_day_by_day`"; -- VIEW to process
END IF;

IF @Month='CM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF @Debug!="NO" THEN SELECT @Month,@Publisher_id,@Advertiser_id,@Account_id,@Debug,@Filters,@Meta,@ProcessALL,InputCommLine; END IF;

-- Valida fecha
IF    LEFT(@Month,3)='202' 
THEN
      IF   SUBSTRING(@Month,6,2) NOT IN ('01','02','03','04','05','06','07','08','09','10','11','12')
      THEN SELECT "Invalid Month parameter" from dual;
           LEAVE proc_label; 
      END IF;
END IF;
-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------

SET @Username_ids_from_Adv   ='';
SET @Username_ids_from_Pub   ='';
SET @DeleteWherePublisher_id ='';
SET @DeleteWhereAdvertiser_id='';
SET @DeleteWhereAccount_id   ='';
SET @WherePublisher_id       ='';
SET @WhereAdvertiser_id      ='';
SET @WhereAccount_id         ='';

-- Obtiene Accounts de Advertiser_id
IF @Advertiser_id!="ALL" THEN 
   SET  @Username_ids_from_Adv=(SELECT GROUP_CONCAT(id SEPARATOR ', ') AS ids 
                                FROM campaign_username 
                                WHERE Advertiser_id = @Advertiser_id); 
END IF;
-- Obtiene Accounts de Publisher_id
IF @Publisher_id!="ALL" THEN 
   SET  @Username_ids_from_Pub=(SELECT GROUP_CONCAT(id SEPARATOR ', ') AS ids 
                                FROM campaign_username 
                                WHERE Publisher_id = @Publisher_id); 
END IF;
-- ----------------------------------------------------------------------------

IF @Publisher_id !="ALL" THEN SET @DeleteWherePublisher_id  =CONCAT(" AND Username_id IN (",@Username_ids_from_Pub,") "); END IF;
IF @Advertiser_id!="ALL" THEN SET @DeleteWhereAdvertiser_id =CONCAT(" AND Username_id IN (",@Username_ids_from_Adv,") "); END IF;
IF @Account_id   !="ALL" THEN SET @DeleteWhereAccount_id    =CONCAT(" AND Username_id =",@Account_id ); END IF;

IF @Publisher_id !="ALL" THEN SET @WherePublisher_id  =CONCAT(" AND D.Username IN (",@Username_ids_from_Pub,") "); END IF;
IF @Advertiser_id!="ALL" THEN SET @WhereAdvertiser_id =CONCAT(" AND D.Username IN (",@Username_ids_from_Adv,") "); END IF;
IF @Account_id   !="ALL" THEN SET @WhereAccount_id    =CONCAT(" AND D.Username =",@Account_id ); END IF;

IF @Debug!="NO" THEN SELECT @Publisher_id,@Advertiser_id,@Account_id
                           ,@DeleteWherePublisher_id,@WhereAdvertiser_id,@DeleteWhereAccount_id
                           ,@WherePublisher_id,@WhereAdvertiser_id,@WhereAccount_id; END IF;
-- ----------------------------------------------------------------------------

-- SET SESSION group_concat_max_len = 200000;

-- ----------------------------------------------------------------------------
-- IF @ProcessALL="1=1" -- Procesar todos las tablas Snapshot_day_by_day_AAAA
-- THEN
-- SET @CreateViewDbD='';
-- SELECT CONCAT('
--    CREATE OR REPLACE VIEW Snapshot_day_by_day_ACUM as 
--    SELECT * FROM Snapshot_day_by_day UNION ALL
--    SELECT * FROM ',
--    GROUP_CONCAT(TABLE_NAME SEPARATOR ' UNION ALL SELECT * from '),';') 
--    INTO @CreateViewDbD
-- FROM information_schema.`TABLES`
-- WHERE TABLE_SCHEMA =DATABASE() and table_type='BASE TABLE' AND TABLE_NAME LIKE 'Snapshot_day_by_day_202%';
-- END IF;
-- ----------------------------------------------------------------------------


SET @DeleteFromFact1=CONCAT('
DELETE FROM Snapshot_day_by_day_fact1 WHERE IFNULL(`Origin`,"")!="manual" AND `Area`="gaming"
      AND (LEFT(DATE,7)="',@Month,'" OR ',@ProcessALL,')               -- En caso de ALLALL borra TODO - Flag 1=1
',@DeleteWherePublisher_id  
 ,@DeleteWhereAdvertiser_id
 ,@DeleteWhereAccount_id   
,';'
);
-- ------------------------------------------------------------------------
-- ------------------------------------------------------------------------
SET @InsertFromDbd=CONCAT('
INSERT IGNORE INTO Snapshot_day_by_day_fact1
SELECT
   `D`.`id` AS `id`,
   ""                                     as `Origin`,
   "gaming"                               as `Area`,   
   `CU`.`Owner` 			 	 	 				AS `Owner`,          -- 05.08.2022
   IFNULL(`A`.`username`, "_Unassigned") 	AS `Affiliate`,
   IFNULL(`A`.`id`, 1)                    AS `Affiliate_id`,
   `CDG`.`Deal_Name`                      AS `Deal`,
   `CDA`.`Deal_Name`                      AS `Deal_Aff`,
   `D`.`Hour_Update`                      AS `Hour_Update`,
   `D`.`Date`                             AS `Date`,
   `CU`.`Username`                        AS `Username`,
   `D`.`Username`                         AS `Username_id`,
   `D`.`Portal`                           AS `Portal`,
   `AD`.`Advertiser_Name`                 AS `Brand`,          -- 30.10.2022
   `AD`.`id`                              AS `Advertiser_id`,
   `CU`.`Publisher_id`                    AS `Publisher_id`,   -- 21.01.2023
    IFNULL(`AD`.`Brand_Group`,"")         AS `Brand_Group`,    -- 11.10.2022
    IF(`AD`.`Brand_Group`>"",IFNULL(`AD`.`Brand_Group_Acum`,0),0) AS `Brand_Group_Acum`,  -- 28.10.2022
    IFNULL(`M`.`Tracker_ID`,`D`.`Tracker_ID`) AS `Tracker_ID`,     -- 26.10.2022 if ms=null Tracker_id de DbD
   `D`.`Tracker_ID`                       AS `Tracker_ID_DbD`,
   `M`.`id`                               AS `MS_id`,
   `D`.`Tracker_Name`                     AS `Tracker_Name`,
   `M`.`Code_To_Affiliate`                AS `Code_To_Affiliate`,
   IFNULL(`D`.`Product`, "")              AS `Product`,
   IFNULL(`M`.`Product`, "")              AS `Product_Real`,
   -- `D`.`Qualified_Players` AS `Qualified_Players`,

   @CPA :=(CASE WHEN IFNULL(`D`.`Qualified_Players`,0)=0            -- 18.11.2022
                 AND IFNULL(D.CPA_Value_Gestor,0)<>0                -- 18.11.2022
                 AND IFNULL(`CDG`.`CPA_Value`,0)>0                  -- 18.11.2022
                THEN ROUND(D.CPA_Value_Gestor/`CDG`.`CPA_Value`,0)  -- 18.11.2022
                ELSE IFNULL(`D`.`Qualified_Players`,0) END)         -- 18.11.2022
                                          AS `Qualified_Players`,   -- 18.11.2022

-- `D`.`Qualified_Players_Adjusted`       AS `Qualified_Players_Adjusted`,
   @CPA                                   AS `Qualified_Players_Adjusted`,
   `D`.`First_Time_Deposit`               AS `First_Time_Deposit`,
   `D`.`Views`                            AS `Views`,
   `D`.`Clicks`                           AS `Clicks`,
   `D`.`Signups`                          AS `Signups`,
   `D`.`Impressions`                      AS `Impressions`,
   `D`.`Sign_Up_Offer`                    AS `Sign_Up_Offer`,
   `D`.`Type`                             AS `Type`,
   `D`.`Language`                         AS `Language`,
   `D`.`Country`,
   `D`.`Brand_Name`,
   `D`.`Registration_Date`                AS `Registration_Date`,
   `D`.`Deposits`                         AS `Deposits`,
   `D`.`Depositing_Customers`             AS `Depositing_Customers`,
   `D`.`Active_Customers`                 AS `Active_Customers`,
   `D`.`New_Depositing_Customers`         AS `New_Depositing_Customers`,
   `D`.`New_Active_Customers`             AS `New_Active_Customers`,
   `D`.`First_Time_Active_Customers`      AS `First_Time_Active_Customers`,
   `D`.`Turnover`                         AS `Turnover`,

   -- `D`.`Net_Revenue` AS `NR_DbD`,CU.RSasNR,`CDG`.`RS_Percentage`,    -- para Debug -- 22.11.2022
   @NR :=(CASE WHEN CU.RSasNR=1 AND IFNULL(`CDG`.`RS_Percentage`,0)>0                 -- 22.11.2022
               THEN ROUND(`D`.`Net_Revenue` / `CDG`.`RS_Percentage` * 100,2)          -- 22.11.2022
          ELSE IFNULL(`D`.`Net_Revenue`, 0) END) as `Net_Revenue`,                    -- 22.11.2022

   `M`.`Shortlink`                        AS `Shortlink`,
   `M`.`CPA_Limit`                        AS `CPA_Limit`,
   `lp`.`id`                              AS `Channel_id`,
   `lp`.`landing_page_name`               AS `Channel`,
   IFNULL(`A`.`first_level`, " ") 	      AS `Level_1`,
   IFNULL(`A`.`second_level`, " ") 	      AS `Level_2`,
   IFNULL(`A`.`third_level`, " ") 	      AS `Level_3`,
   IFNULL(`A`.`fourth_level`, " ") 	      AS `Level_4`,
   ROUND(((@NR * IFNULL(`CDG`.`RS_Percentage`, 0)) / 100), 2) AS `Revenue_Share_Gestor`,
   ROUND(((@NR * IFNULL(`CDA`.`RS_Percentage`, 0)) / 100), 2) AS `Revenue_Share_Affiliate`,
   ROUND((@CPA * IFNULL(`CDA`.`CPA_Value`, 0)), 0) AS `CPA_Value_Affiliate`,  -- 18.11.2022
   ROUND((@CPA * IFNULL(`CDG`.`CPA_Value`, 0)), 0) AS `CPA_Value_Gestor`,     -- 18.11.2022
   IFNULL(`CDA`.`id`, 0) 				      AS `Deal_Aff_id`,
   IFNULL(`CDA`.`CPA_Value`, 0) 		      AS `Deal_Aff_CPA`,
   IFNULL(`CDA`.`Carry_Over`, 0) 	      AS `Deal_Aff_Carry_Over`,
   IFNULL(`CDA`.`RS_Against_CPA`, 0)      AS `Deal_Aff_RS_Against_CPA`,
   IFNULL(`CDA`.`RS_Base`, 0) 		      AS `Deal_Aff_RS_Base`,
   IFNULL(`CDA`.`RS_Percentage`, 0)       AS `Deal_Aff_RS`,
   IFNULL(`M1`.`Deal_Valid_From`, 0)      AS `Deal_Aff_Valid_From`,           -- 05.11.2022
   IFNULL(`CDG`.`id`, 0) 				      AS `Deal_Ges_id`,
   IFNULL(`CDG`.`CPA_Value`, 0) 		      AS `Deal_Ges_CPA`,
   IFNULL(`CDG`.`Carry_Over`, 0) 	      AS `Deal_Ges_Carry_Over`,
   IFNULL(`CDG`.`RS_Against_CPA`, 0)      AS `Deal_Ges_RS_Against_CPA`,
   IFNULL(`CDG`.`RS_Base`, 0) 		      AS `Deal_Ges_RS_Base`,
   IFNULL(`CDG`.`RS_Percentage`, 0)       AS `Deal_Ges_RS`,
   IFNULL(`CDP`.`Valid_From`, 0) 	      AS `Deal_Ges_Valid_From`,           -- 05.11.2022
   CU.Data_Currency,
   CU.is_indirect,                                                            -- 28.11.2022
   CU.Advertiser_indirect_id,                                                 -- 28.11.2022
   left(NOW(),16) as "TimeGen"
FROM ',@TableToProcess,' `D`
LEFT JOIN `campaign_username` `CU` ON (`CU`.`id` = `D`.`Username`)
LEFT JOIN `campaign_advertiser` `AD` ON (`AD`.`id` = `CU`.`Advertiser_id`)          -- 30.10.2022
		-- AND (`AD`.`Owner` = `D`.`Owner`)                                           -- 10.08.2022
-- ----------------------------Seleccion MS----------------------------------------------
LEFT JOIN LATERAL (                                                                        -- 02.12.2022
   SELECT                                                                                  -- 02.12.2022
      CASE  WHEN M.Tracker_ID = D.Tracker_ID and M.Tracker_Name = D.Tracker_Name then 4    -- 02.12.2022
            WHEN M.Tracker_ID = D.Tracker_ID then 3                                        -- 02.12.2022
            WHEN M.Tracker_Name = D.Tracker_Name then 2                                    -- 02.12.2022
            ELSE 1 END AS MatchValue                                                       -- 02.12.2022
      ,M.* FROM campaign_marketing_source M                                                -- 02.12.2022
   WHERE M.Username_id = D.Username AND                                                    -- 02.12.2022
		(D.Tracker_ID IN (M.Tracker_ID,M.Tracker_Name)                                       -- 02.12.2022
	OR  D.Tracker_Name IN (M.Tracker_ID,M.Tracker_Name))                                    -- 02.12.2022
	ORDER BY MatchValue DESC LIMIT 1                                                        -- 02.12.2022
	) AS M ON true                                                                          -- 02.12.2022
-- ----------------------------Seleccion de Affiliate------------------------------------
LEFT JOIN LATERAL (                                                                            -- 09.11.2022
	SELECT *,ROW_NUMBER() OVER(PARTITION BY MS_id 
                                 ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr               -- 15.02.2023
	FROM `campaign_mkt_source_deal` WHERE `MS_id` = M.id AND `is_active` = 1                    -- 09.11.2022
                                     AND `Deal_Valid_From` <= `D`.`Date`                       -- 09.11.2022
	ORDER BY RowNr LIMIT 1                                                                      -- 09.11.2022
) AS M2 ON TRUE                                                                                -- 09.11.2022
-- ----------------------------Seleccion de DEAL producto--------------------------------      -- 09.11.2022
LEFT JOIN LATERAL (                                                                            -- 09.11.2022
	SELECT * FROM (                                                                             -- 09.11.2022
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product 
                                 ORDER BY Deal_Valid_From DESC,id DESC) AS RowNr               -- 15.02.2023
      FROM `campaign_mkt_source_deal` WHERE `MS_id` = M.id AND Affiliate_id=M2.Affiliate_id    -- 09.11.2022
                                        AND `is_active` = 1                                    -- 09.11.2022
                                        AND `Deal_Valid_From` <= `D`.`Date`                    -- 09.11.2022
	) AS DbP                                                                                    -- 09.11.2022
	WHERE RowNr=1 AND
      -- IFNULL(DbP.`Product`,"") IN (IFNULL(D.Product, ""),IFNULL(M.Product, ""),""," ")     -- 15.03.2023
		(
		    TRIM(IFNULL(DbP.`Product`,"")) IN (TRIM(IFNULL(D.Product, "")),"")  -- coincide Product regla o catch all
		OR (IFNULL(DbP.`Product`,"")=TRIM(IFNULL(M.Product, "")) 
			 AND TRIM(IFNULL(D.Product, ""))="")                                 -- Product regla=Product MS cuando Product entrada vacio
		)      
	ORDER BY DbP.`Product` DESC LIMIT 1	                                                        -- 09.11.2022
) AS M1 ON TRUE                                                                                -- 09.11.2022
-- --------------------------------------------------------------------------------------

LEFT JOIN `account_account` `A` ON `A`.`id` = `M2`.`Affiliate_id`
LEFT JOIN `campaign_deal_affiliate` `CDA` ON `CDA`.`id` = `M1`.`Deal_id`

LEFT JOIN LATERAL (                                                                       -- 09.11.2022
	SELECT * FROM (                                                                        -- 09.11.2022
      SELECT *,ROW_NUMBER() OVER(PARTITION BY Product 
                                 ORDER BY Valid_From DESC,id DESC) AS RowNr               -- 15.02.2023
      FROM `campaign_deal_gestor_prod_date`                                               -- 09.11.2022
      WHERE `Username_id` = `D`.`Username` AND `Advertiser_id` = `CU`.`Advertiser_id`     -- 09.11.2022
        AND `is_active` = 1  AND `Valid_From` <= `D`.`Date`                               -- 09.11.2022
	) AS DbP                                                                               -- 09.11.2022
	WHERE RowNr=1 AND IFNULL(DbP.`Product`,"") IN (IFNULL(D.Product, ""),""," ")           -- 09.11.2022
	ORDER BY DbP.`Product` DESC LIMIT 1	                                                   -- 09.11.2022
) AS CDP ON TRUE                                                                          -- 09.11.2022

LEFT JOIN `campaign_deal_gestor` `CDG` ON ((`CDG`.`id` = `CDP`.`Deal_id`))
LEFT JOIN `campaign_advertiser_status` `CS` ON ((`CS`.`id` = `AD`.`id`))
LEFT JOIN `account_landing_pages` `lp` ON ((`lp`.`id` = `M2`.`Channel_id`))

WHERE
  (LEFT(DATE,7)="',@Month,'" OR ',@ProcessALL,')               -- En caso de ALLALL procesa todo - Flag 1=1
',@WherePublisher_id 
 ,@WhereAdvertiser_id
 ,@WhereAccount_id   
,';'
);

IF @Debug!="NO" THEN SELECT @CreateViewDbD;   END IF;
IF @Debug!="NO" THEN SELECT @DeleteFromFact1; END IF;
IF @Debug!="NO" THEN SELECT @InsertFromDbd;   END IF;

IF @Debug != "YES" THEN
   
   PREPARE stmt1 FROM @CreateViewDbD;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
   
	PREPARE stmt1 FROM @DeleteFromFact1;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;

	PREPARE stmt1 FROM @InsertFromDbd;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
   
END IF;

END;
//
DELIMITER ;

/*
-- --------------------tests---------------------------------
CALL DbD_to_fact1('month=LM,publisher_id=13,debug=yes');
CALL DbD_to_fact1('month=ALLALL,debug=ye');
CALL DbD_to_fact1('month=ALLALL,publisher_id=13,debug=yeS'); -- reproceso de TODO DbD para Publ Sisal
CALL DbD_to_fact1('');        -- asume CM
CALL DbD_to_fact1('ENERO');   -- asume CM
CALL DbD_to_fact1('ALLALL');
CALL DbD_to_fact1('2022-05'); -- error
CALL DbD_to_fact1('2022-15'); -- error
CALL DbD_to_fact1('month=2023-10,debug=yes');
*/
