SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;
SET SESSION group_concat_max_len = 100000;

SET @schema_name = 'fabio';
SET @table_like = 'jqe_fm20aff_uc_%';
SET @result_table = 'fabio_fm20aff_uc_estructura';

SELECT MAX(col_count) INTO @max_cols
FROM (
  SELECT table_name, COUNT(*) AS col_count
  FROM information_schema.columns
  WHERE table_schema = @schema_name
    AND table_name LIKE @table_like
  GROUP BY table_name
) t;

SET @max_cols = IFNULL(@max_cols, 0);

SET @drop_sql = CONCAT(
  'DROP TABLE IF EXISTS `', @schema_name, '`.`', @result_table, '`;'
);
PREPARE stmt_drop FROM @drop_sql;
EXECUTE stmt_drop;
DEALLOCATE PREPARE stmt_drop;

SET @cols_def = '';
SET @cols_names = '';
SET @cols_select = '';
SET @query_select = '';

WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < @max_cols
)
SELECT
  GROUP_CONCAT(
    CONCAT(
      ', `campo_', n, '` varchar(64)',
      ', `tipo_campo_', n, '` varchar(16)'
    )
    ORDER BY n SEPARATOR ''
  ) AS cols_def,
  GROUP_CONCAT(
    CONCAT('`campo_', n, '`, `tipo_campo_', n, '`')
    ORDER BY n SEPARATOR ', '
  ) AS cols_names,
  GROUP_CONCAT(
    CONCAT(
      'MAX(CASE WHEN ordinal_position=', n,
      ' THEN column_name END) AS `campo_', n, '`, ',
      'MAX(CASE WHEN ordinal_position=', n,
      ' THEN column_type END) AS `tipo_campo_', n, '`'
    )
    ORDER BY n SEPARATOR ', '
  ) AS cols_select
INTO @cols_def, @cols_names, @cols_select
FROM seq;

SET @query_select = CONCAT(
  "CONCAT('UPDATE fm20.campaign_marketing_source_test_all t ",
  "INNER JOIN fabio.`', table_name, '` uc ON uc.`', ",
  "MAX(CASE WHEN ordinal_position=2 THEN column_name END), '`=t.Advertiser_id_OK ",
  "SET ',",
  "CASE",
  " WHEN MAX(CASE WHEN ordinal_position=4 THEN column_name END) IS NULL THEN ",
  "   CONCAT('t.Tracker_Name=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=3 THEN column_name END), '`')",
  " WHEN MAX(CASE WHEN ordinal_position=4 THEN data_type END) IN ",
  "   ('int','tinyint','smallint','mediumint','bigint') THEN ",
  "   CONCAT('t.Tracker_id=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=4 THEN column_name END), '`,', ",
  "   't.Tracker_Name=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=3 THEN column_name END), '`')",
  " WHEN MAX(CASE WHEN ordinal_position=3 THEN data_type END) IN ",
  "   ('int','tinyint','smallint','mediumint','bigint') THEN ",
  "   CONCAT('t.Tracker_id=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=3 THEN column_name END), '`,', ",
  "   't.Tracker_Name=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=4 THEN column_name END), '`')",
  " ELSE ",
  "   CONCAT('t.Tracker_Name=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=3 THEN column_name END), '`,', ",
  "   'Tracker_id=uc.`', ",
  "   MAX(CASE WHEN ordinal_position=4 THEN column_name END), '`')",
  " END, ';') AS `query_update`"
);

SET @create_sql = CONCAT(
  'CREATE TABLE `', @schema_name, '`.`', @result_table, '` (',
  '`tabla` varchar(64) NOT NULL',
  IF(@max_cols > 0, @cols_def, ''),
  ', `query_update` text',
  ');'
);
select  @create_sql;
PREPARE stmt_create FROM @create_sql;
EXECUTE stmt_create;
DEALLOCATE PREPARE stmt_create;

SET @insert_sql = CONCAT(
  'INSERT INTO `', @schema_name, '`.`', @result_table, '` (`tabla`',
  IF(@max_cols > 0, CONCAT(', ', @cols_names), ''),
  ', `query_update`',
  ') SELECT table_name AS `tabla`',
  IF(@max_cols > 0, CONCAT(', ', @cols_select), ''),
  ', ', @query_select,
  ' FROM information_schema.columns',
  ' WHERE table_schema = ', QUOTE(@schema_name),
  ' AND table_name LIKE ', QUOTE(@table_like),
  ' GROUP BY table_name',
  ' ORDER BY table_name;'
);
PREPARE stmt_insert FROM @insert_sql;
EXECUTE stmt_insert;
DEALLOCATE PREPARE stmt_insert;

-- Ejecutar los UPDATE generados en la tabla de resultados
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_exec_fabio_fm20aff_updates $$
CREATE PROCEDURE sp_exec_fabio_fm20aff_updates()
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_query TEXT;
  DECLARE cur CURSOR FOR
    SELECT query_update
    FROM `fabio`.`fabio_fm20aff_uc_estructura`
    WHERE query_update IS NOT NULL AND query_update <> '';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_query;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;

    SET @sql = v_query;
    PREPARE stmt_upd FROM @sql;
    EXECUTE stmt_upd;
    DEALLOCATE PREPARE stmt_upd;
  END LOOP;
  CLOSE cur;
END $$
DELIMITER ;

CALL sp_exec_fabio_fm20aff_updates();
 -- -------------------------------------------------------
-- UPDATE fm20.campaign_marketing_source_test t
-- INNER JOIN fabio.[tabla] uc ON uc.[campo_2]=t.Advertiser_id_OK
-- SET t.Tracker_Name=uc.[campo_4],Tracker_id=uc.[campo_3]
-- ;
 -- -------------------------------------------------------
-- Condiciones de la cláusula SET del UPDATE:
-- Si Campo_3 es INT, entonces Tracker_id=uc.[campo_3]
-- Si Campo_4 es INT, entonces Tracker_id=uc.[campo_4]
-- Si Campo_3 es VARCHAR, y Campo_4 es INT, entonces Tracker_Name=uc.[campo_3],Tracker_id=uc.[campo_4]
-- Si Campo_3 es VARCHAR, y Campo_4 es VARCHAR, entonces Tracker_Name=uc.[campo_3],Tracker_id=uc.[campo_4]
-- Si Campo_4 es NULL, entonces Tracker_Name=uc.[campo_3]
-- Por regla general, si Campo_3 o Campo_4 son INT, entonces Tracker_id=uc.[campo_3] o Tracker_id=uc.[campo_4]
-- y el otro (si no es nulo) se asigna a Tracker_Name.

-- Atribución de Brand/Advertiser a ms
-- SELECT
--    b.`id`,   ad.id,
--    `bookname`,
--    ad.Advertiser_Name,
--    `logoimagepath`,
--    `websiteurl`,
--    b.`country`,
--    `flagimagepath`,
--    `languages`,
--    `productsoffered`,
--    `currenciesaccepted`,
--    `baseline`,
--    `isbookavailable`,
--    `bonus`,
--    `description`,
--    `dateupdate`
-- FROM fabio.jqe_fm20aff_books b
-- left join fm20.campaign_advertiser ad on SUBSTRING_INDEX(ad.Advertiser_Name, ' ', 1) = SUBSTRING_INDEX(b.bookname, ' ', 1)
-- WHERE ad.id IS NOT NULL ;

-- INSERT INTO fm20.campaign_advertiser (Advertiser_Name)
-- SELECT m.Status_Adv_id
-- ,m.id,m.Tracklink,m.Tracker_ID,m.Tracker_Name,m.Status_Adv_id,ad.Advertiser_Name 
-- FROM 
UPDATE 
fm20.campaign_marketing_source_test_all m
left join fm20.campaign_advertiser ad on 
                        case when SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)="Lottomatica" then "Better"
                             when SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)="William" then "WilliamHill"
                             when SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)="888Casino" then "888`"
                             when SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)="888Sport" then "888`"
                             when SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)="StarcasinoBet" then "Starcasino"
                             else SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)
                        end=SUBSTRING_INDEX(ad.Advertiser_Name, ' ', 1)
SET m.Advertiser_id=ad.id,m.Publisher_id=ad.Publisher_id
-- WHERE ad.id IS NULL 
-- GROUP BY m.Status_Adv_id
;
-- crear Accounts faltantes con Brand
insert into fm20.campaign_username (Area,Advertiser_id,Username,is_active)
Select "gaming" as Area,a.id as Advertiser_id,"default" as Username,0
from fm20.campaign_advertiser a
left join fm20.campaign_username u on u.Advertiser_id=a.id
where u.id is null
;

-- ---------------Deals ------------------------------
CREATE TABLE fm20.campaign_deal_affiliate_fabio
SELECT  `id`,  `userid`,  `campaignid`, `campaignname`
      ,  `dealtypeassigned`,  `cpaassigned`,  `rsassigned`
FROM `fabio`.`jqe_fm20aff_users_campaigns`
GROUP BY IFNULL(`cpaassigned`,0),  IFNULL(`rsassigned`,0)
;
INSERT INTO `campaign_deal_affiliate` (`CPA_Value`, `RS_Percentage`, `RS_Percentage_Displayed`,Baseline) -- VALUES ('No Deal', 0.00, 0.00, 0.00, '2022-01-01');
SELECT IFNULL(`cpaassigned`,0),IFNULL(`rsassigned`,0)*100,IFNULL(`rsassigned`,0)*100,0
FROM fm20.campaign_deal_affiliate_fabio
;

update `campaign_deal_affiliate_copy`
   SET Deal_Name=
	CONCAT('CPA: ',round(CPA_value,0),' ',Currency,IF(Baseline>0,CONCAT(' BL: ',Baseline,' ',Currency),''),
	CASE WHEN RS_Percentage_Displayed>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage_Displayed,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        WHEN RS_Percentage>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        ELSE '' END)
where Deal_Name IS NULL
;   

-- ------------------------------------------------------------------------
/**************************************************************************/
-- ------------------------------------------------------------------------
-- análisis de errores "MS missing" después de los
-- Procesos upd fact1/fact/comisiones
-- CALL Snapshot_day_by_day_fact1_upd_from_dbd('CM');
-- CALL Snapshot_day_by_day_fact1_upd_from_dbd('LM');
-- call Sync_Fact2_from_Fact1('mode=RUN,month=LM,MS_id=allall,db=fm20');
-- CALL total_monthy_comm_ges_upd('');
-- CALL Snapshot_day_by_day_fact2_upd_cm;
-- CALL total_monthy_comm_aff_upd('');
-- ------------------------------------------------------------------------
  drop table Check_Fact1;
  
  create table Check_Fact1
  SELECT "" as Meta,
     'Fact1' as Tabla,`Date`,`Origin`,Brand
     ,Username_id,Username,Affiliate
	  ,Tracker_ID,Tracker_Name
     ,Product
     ,IFNULL(MS_ID,'missing') as MS_ID -- 11/01/2024
	  ,CASE WHEN MS_ID IS NULL     
           THEN '<<MS missing' 
            ELSE CASE WHEN ifnull(Deal_Aff_id,0)=0 AND ifnull(Deal_Ges_id,0)=0 AND Affiliate NOT IN ('_Unassigned','Parking')
                        THEN '<<DEAL G&A missing. Check Prod/ Country'
                      WHEN ifnull(Deal_Aff_id,0)=0 AND Affiliate NOT IN ('_Unassigned','Parking')
                      	THEN '<<DEAL Aff missing. Check Prod/ Country'
                      WHEN ifnull(Deal_Ges_id,0)=0  
                        THEN '<<DEAL Ges missing. Check Prod/ Country'
            			 ELSE '' END
				END  as Warning
     ,Deal_Aff_id
     ,SUM(Qualified_Players) AS CPA
     ,SUM(Net_Revenue) AS NR
     ,D.Country
     ,D.Hour_Update
     ,P.Advertiser_name as `Publisher` -- 10.01.2024
     ,D.Publisher_id                   -- 10.01.2024
     ,D.Advertiser_id                  -- 10.01.2024     
  FROM Snapshot_day_by_day_fact1 D
  LEFT JOIN campaign_publisher P ON P.id=D.Publisher_id     -- 10.01.2024
  WHERE LEFT(Date,7)>="2026-01"
      AND (MS_ID IS NULL OR ifnull(Deal_Ges_id,0)=0 
			OR (Affiliate!='_Unassigned' AND (ifnull(Deal_Aff_id,0)=0 AND Qualified_Players<>0)))
      AND (Qualified_Players<>0 OR Net_Revenue<>0)

  GROUP BY Brand,username,Tracker_ID,Tracker_Name,Product -- HAVING Warning='<<MS missing'
  ORDER BY Brand,Affiliate,Tracker_ID,Tracker_Name
  ;

with MS_Brands as (
SELECT u.id as Accnt_id,u.Username as Account,u.Advertiser_id,u.Publisher_id,p.Advertiser_Name as `Publisher`,a.Advertiser_Name as `Brand`
from campaign_username u
INNER JOIN campaign_advertiser a ON a.id=u.Advertiser_id
INNER JOIN campaign_publisher p ON p.id=u.Publisher_id
ORDER BY `Publisher`,`Brand` -- p.Advertiser_Name,a.Advertiser_Name
),
Missing_MS as (
SELECT
     min(D.`Date`) as `Date`
   , D.`Brand`
   , D.`Username_id` as `Accnt DbD`
   , D.`Username`
   , m.`Username_id` as `Accnt MS`   
   , D.`Affiliate`
   , D.`Tracker_ID` as `Tracker_id DbD`
   , D.`Tracker_Name` as `Tracker_name DbD`
   , D.`Product` as `Product DbD`
   , D.`MS_ID` as 'MS_id DbD'
   , D.`CPA`
   , D.`NR`
   , D.`Publisher`
   , D.`Publisher_id` as `Publisher_id DbD`
   , D.`Advertiser_id` as `Advertiser_id DbD`
   , m.`id` as MS_id
   , m.`Tracklink`
   , m.`Tracker_ID` as `Tracker_id MS`
   , m.`Tracker_Name` as `Tracker_name MS`
   , m.`Product`
   , m.`Status_Adv_id`as `Book fabio`
   , m.`Description`  as `Brand-Campaign fabio`
   , m.`Affiliate_id`
   , m.`Advertiser_id`
   , m.`Advertiser_id_OK` as `user_campaign fabio`
   , m.`Publisher_id`
   , m.`Username_id`

FROM Check_Fact1 D
LEFT JOIN lateral (
select m.* from campaign_marketing_source m 
-- left join MS_Brands ms on ms.Brand=D.Brand and ms.Publisher=D.Publisher
where (m.Advertiser_id=D.Advertiser_id or m.Publisher_id=D.Publisher_id)
   and
      (    D.Tracker_ID <=> ifnull(m.Tracker_ID,0)
        OR D.Tracker_Name <=> ifnull(m.Tracker_Name,'')
        OR D.Tracker_ID <=> ifnull(m.Tracker_Name,'')
      )
) as m on true
-- WHERE m.id IS  NULL
GROUP BY D.`Brand`,D.`Username_id`, D.`Username`,D.`Tracker_ID`,D.`Tracker_Name`
order by  D.`Brand`,D.`Username_id`, D.`Username`
)
select * from Missing_MS mis where `MS_id DbD`="missing"  and MS_id is  null
UNION ALL
select * from Missing_MS mis where `MS_id DbD`="missing"  and MS_id is not null
order by case when MS_id is null then 0 else 1 end,Brand,`Accnt DbD`
;
-- Select m.`Username_id`,mis.`Accnt DbD`,mis.MS_id,m.id from
-- update 
-- Missing_MS mis
-- inner join Snapshot_day_by_day_brands d on mis.`Accnt DbD`=d.Username
-- inner join fm20.campaign_marketing_source_test_all m on mis.MS_id=m.id 
-- set m.`Username_id`=mis.`Accnt DbD`
-- where mis.MS_id is not null and mis.`MS_id DbD`="missing"
-- ;

-- -------------------------------------------------------------------------
-- Arreglos manuales Username_id depués del análisis de errores
-- -------------------------------------------------------------------------
SELECT u.id,u.Username,u.Advertiser_id,u.Publisher_id,a.id,a.Advertiser_Name
from campaign_username u
INNER JOIN campaign_advertiser a ON a.id=u.Advertiser_id
ORDER BY a.Advertiser_Name
;
UPDATE campaign_marketing_source_test_all c
INNER JOIN campaign_username u ON u.id=c.Username_id
SET c.Advertiser_id=u.Advertiser_id,c.Publisher_id=u.Publisher_id
;
-- Select d.CPA_value,ifnull(cpaassigned,0),d.RS_Percentage,ifnull(rsassigned,0)  from
UPDATE 
campaign_marketing_source_test_all m
INNER JOIN `fabio`.`jqe_fm20aff_users_campaigns` c on c.id=m.Advertiser_id_OK
inner join `campaign_deal_affiliate` d on d.CPA_value=ifnull(cpaassigned,0) and d.RS_Percentage=ifnull(rsassigned,0)  
SET m.Deal_id=d.id
;
-- -------------------------------------------------------------
-- Cambios visibles luego de procesar DbD
-- Better
UPDATE campaign_marketing_source_test_all m
SET Username_id=20
Where Username_id IN (19) AND Status_Adv_id IN ('Lottomatica Casino')
;
-- EuroBet
UPDATE campaign_marketing_source_test_all m
SET Username_id=9
Where Username_id IN (8) AND Tracker_Name LIKE '%_2'
;
-- Lottomatica - GoldBet/Better
UPDATE campaign_marketing_source_test_all m
SET Username_id=14
Where Username_id IN (12) AND `Description` IN ('Goldbet Casino - Goldbet Casino')
;
UPDATE campaign_marketing_source_test_all m
SET Username_id=15
Where Username_id IN (12) AND `Description` IN ('Goldbet - Goldbet 2022')
;
update
campaign_marketing_source_test_all
SET Username_id=12,Advertiser_id=16,Publisher_id=16
WHERE Tracklink LIKE '%goldbet%'
;
update
campaign_marketing_source_test_all
SET Username_id=15,Advertiser_id=16,Publisher_id=16
WHERE Tracklink LIKE '%goldbet%' AND `Description` IN ('Goldbet Casino - Goldbet Casino')
;
-- Lottomatica/goldbet/better adecuación segun Dbd
CREATE TABLE Snapshot_day_by_day_accnt_lotto_casino
SELECT  `Date`,  `Username`,  `Brand`,  `Tracker_ID`, `Tracker_Name`
FROM `fm20`.`Snapshot_day_by_day` 
WHERE left(DATE,7)='2026-01'
   AND Tracker_Name LIKE '%casino%'
   AND Username IN ('12','13','14','15')
GROUP BY `Username`,  `Brand`,  `Tracker_ID`, `Tracker_Name`
ORDER BY `Username`
;
CREATE TABLE Snapshot_day_by_day_accnt_lotto_mix
SELECT  `Date`,  `Username`,  `Brand`,  `Tracker_ID`, `Tracker_Name`
FROM `fm20`.`Snapshot_day_by_day` 
WHERE left(DATE,7)='2026-01'
   AND Tracker_Name LIKE '%mix%'
   AND Username IN ('12','13','14','15')
GROUP BY `Username`,  `Brand`,  `Tracker_ID`,  `Tracker_Name`
ORDER BY `Username`
;
CREATE TABLE Snapshot_day_by_day_accnt_lotto_nomix_nocasino
SELECT  `Date`,  `Username`,  `Brand`,  `Tracker_ID`,  `Tracker_Name`
FROM `fm20`.`Snapshot_day_by_day` 
WHERE left(DATE,7)='2026-01'
   AND Tracker_Name not LIKE '%mix%' AND Tracker_Name not LIKE '%casino%'
   AND Username IN ('12','13','14','15')
GROUP BY `Username`,  `Brand`,  `Tracker_ID`,  `Tracker_Name`
ORDER BY `Username`
;
-- SELECT c.*,m.* FROM 
UPDATE 
campaign_marketing_source_test_all m
INNER JOIN Snapshot_day_by_day_accnt_lotto_casino c ON c.Tracker_ID=m.Tracker_ID AND c.Tracker_Name=m.Tracker_Name
LEFT JOIN campaign_username u ON u.id=c.Username
SET m.Publisher_id=u.Publisher_id,m.Advertiser_id=u.Advertiser_id,m.Username_id=u.id
;
-- SELECT * FROM 
UPDATE 
campaign_marketing_source_test_all m
inner JOIN Snapshot_day_by_day_accnt_lotto_mix c ON c.Tracker_ID=m.Tracker_ID AND c.Tracker_Name=m.Tracker_Name
INNER JOIN campaign_username u ON u.id=c.Username
SET m.Publisher_id=u.Publisher_id,m.Advertiser_id=u.Advertiser_id,m.Username_id=u.id
;
-- SELECT * FROM 
UPDATE 
campaign_marketing_source_test_all m
inner JOIN Snapshot_day_by_day_accnt_lotto_nomix_nocasino c ON c.Tracker_ID=m.Tracker_ID AND c.Tracker_Name=m.Tracker_Name
INNER JOIN campaign_username u ON u.id=c.Username
SET m.Publisher_id=u.Publisher_id,m.Advertiser_id=u.Advertiser_id,m.Username_id=u.id
;
-- PlanetWin365
UPDATE campaign_marketing_source_test_all m
SET Username_id=22
Where Username_id IN (21) AND `Description` IN ('Planetwin365 - Planetwin365 Casino')
      AND Tracker_Name NOT LIKE '[NO IMPORT] Framadda%' 
;
-- Snai
UPDATE campaign_marketing_source_test_all m
SET Username_id=269
Where Username_id IN (25) AND `Description` IN ('Snai - Snai')
;
-- SELECT * FROM
update
campaign_marketing_source_test_all
SET Username_id=25,Advertiser_id=15,Publisher_id=15
WHERE Tracklink LIKE '%snai%' AND Username_id NOT IN (25,269)
;
-- WilliamHill
UPDATE campaign_marketing_source_test_all m
SET Username_id=30
Where Username_id IN (29) AND `Description` IN ('William Hill Casino - William Hill Casino')
;
-- Betsson 
UPDATE campaign_marketing_source_test_all m
SET Username_id=270
Where Username_id IN (10) AND `Description` IN ('Betsson HYBRID - Betsson Sport HYBRID')
;
-- SELECT * FROM
update
campaign_marketing_source_test_all
SET Username_id=10,Advertiser_id=69,Publisher_id=69
WHERE Tracklink LIKE '%betsson%'
;
-- SELECT * FROM
update
campaign_marketing_source_test_all
SET Username_id=257,Advertiser_id=77,Publisher_id=69
WHERE Tracklink LIKE '%starcasino%'
;
-- Netbet 
UPDATE campaign_marketing_source_test_all m
SET Username_id=259
Where Username_id IN (258) AND `Description` IN ('Netbet - Netbet Casino 2022','Netbet - Netbet Sport 2025','Netbet - Netbet Casino 2025')
;
-- Sisal
-- SELECT * FROM
update
campaign_marketing_source_test_all
SET Username_id=24,Advertiser_id=13,Publisher_id=13
WHERE Tracklink LIKE '%sisal%'
;