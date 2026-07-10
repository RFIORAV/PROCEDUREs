SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;

select stop; -- por si acaso

create table fm20.campaign_marketing_source_test_all like fm20.campaign_marketing_source;
truncate fm20.campaign_marketing_source_test_all;

insert ignore into fm20.campaign_marketing_source_test_all (

   `Code`,
   `Tracklink`,
   `Tracker_ID`,
   `Tracker_Name`,
   `Code_To_Affiliate`,
   -- `Product`,
   `Status`,
   `Status_id`,
   -- `Valid_From`,
   `Description`,
   `Affiliate_id`,
   -- `Advertiser_id`,
   -- `Publisher_id`,
   -- `Username_id`,
   -- `Channel_id`,
   -- `Deal_id`,
   -- `Country_Deal`,
   -- `Product_Deal`,
   -- `Deal_Valid_From`,
   `Shortlink`,
   -- `Shortlink_id`,
   `Operator`,
   `Advertiser_id_OK`,
   `Campaign_id`,
   `Status_Adv_id`
)

with fm20aff_reports as (
SELECT r.`usercampaignid`,
       DATE_FORMAT(FROM_UNIXTIME(r.`datereport`), '%Y-%m-%d') AS `datereport`,
       r.`dealtypeassigned`,
       r.`clicks`,
       r.`registrazioni`,
       r.`depositi`,
       r.`firsttimedeposit`,
       r.`cpa`,
       r.`cpaassigned` AS `CPA_value`,
       r.`netrevenue`,
       r.`rsassigned`,
       r.`rssubaffiliate`,
       r.`ricavi`,
       r.`dateupdate`,
       u.id AS Affiliate_id,
       u.user_login AS Affiliate,
       b.id as b_id,
       b.bookname,
       c.id as c_id,
       c.campaignname,
       uc.linkref as Shortlink,
       case when left(uc.linkref,20)="https://fm2bet.link/" then mid(uc.linkref,21) else lnkr.urltoken end as Token,
       lnkr.Tracklink
FROM fabio.`jqe_fm20aff_reports` r
LEFT JOIN fabio.jqe_fm20aff_users_campaigns uc ON r.usercampaignid = uc.id
LEFT JOIN fabio.jqe_fm20aff_campaigns c ON uc.campaignid = c.id
LEFT JOIN fabio.jqe_fm20aff_books b ON c.bookid = b.id
LEFT JOIN fabio.jqe_users u ON uc.userid = u.id
left join lateral (Select ifnull(lr.linkref,uc.linkref) Tracklink,urltoken from fabio.jqe_fm20aff_linkref_redirector lr 
   where lr.usercampaignid = uc.id
--       or lr.urltoken = mid(uc.linkref,21)
   order by lr.id desc
   limit 1
   ) as lnkr ON true
-- WHERE r.`datereport` >= UNIX_TIMESTAMP('2023-01-01')
-- --    AND r.`datereport` <= UNIX_TIMESTAMP('2025-12-31')
--    AND uc.linkref !="paused"
GROUP BY  r.usercampaignid  
)
select 
  ifnull(Token,"no_token") as Code,
  ifnull(Tracklink,Shortlink) as Tracklink,
--   ifnull(Token,Tracklink) as Tracker_ID,
  case  WHEN ifnull(Tracklink,Shortlink) LIKE '%aspx?pid=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(ifnull(Tracklink,Shortlink), '?pid=', -1), '&', 1)
        WHEN ifnull(Tracklink,Shortlink) LIKE '%siteid=%'   THEN SUBSTRING_INDEX(SUBSTRING_INDEX(ifnull(Tracklink,Shortlink), 'siteid=', -1), '&', 1)
        WHEN ifnull(Tracklink,Shortlink) LIKE '%mid=%'      THEN SUBSTRING_INDEX(SUBSTRING_INDEX(ifnull(Tracklink,Shortlink), 'mid=', -1), '_', -1)
        WHEN ifnull(Tracklink,Shortlink) LIKE '%z=%'        THEN SUBSTRING_INDEX(SUBSTRING_INDEX(ifnull(Tracklink,Shortlink), 'z=', -1), '&', 1)
        WHEN ifnull(Tracklink,Shortlink) LIKE '%?affiliate=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(ifnull(Tracklink,Shortlink), '?affiliate=', -1), '_', 1)
        ELSE ifnull(Token,ifnull(Tracklink,Shortlink)) END as Tracker_ID,
  ifnull(Token,"no_token") as Tracker_Name,
  ifnull(Token,"no_token") as Code_To_Affiliate,
  "Active",
  "1",
  concat(bookname," - ",campaignname),
  Affiliate_id,
  Shortlink,
  "SysOP",
  usercampaignid,
  c_id,
  bookname
from fm20aff_reports;

drop table if exists fm20.marketing_sources_from_DbD;
create table fm20.marketing_sources_from_DbD
  select distinct username,Brand,Tracker_ID,Tracker_Name
From fm20.Snapshot_day_by_day
;

select t.*,d.*
from fm20.campaign_marketing_source_test_all t
left join fm20.marketing_sources_from_DbD d on t.Tracker_ID=d.Tracker_ID 
and t.Description LIKE CONCAT('%', d.Brand, '%')
where d.username is not null
;

select 

   t.`Code`,
   t.`Tracklink`,
   t.`Tracker_ID`,
   t.`Tracker_Name`,
   t.`Code_To_Affiliate`,
   -- `Product`,
   t.`Status`,
   t.`Status_id`,
   -- `Valid_From`,
   t.`Description`,
   t.`Affiliate_id`,
   -- `Advertiser_id`,
   -- `Publisher_id`,
   -- `Campaign_id`,
   Acct.`id` as `Username_id`,
   a.`Advertiser_Name` as `Brand`,
   -- `Deal_id`,
   -- `Country_Deal`,
   -- `Product_Deal`,
   -- `Deal_Valid_From`,
   t.`Shortlink`,
   -- `Shortlink_id`,
   t.`Operator`
from fm20.campaign_marketing_source_test t
left join fm20.campaign_advertiser a on a.id=t.Advertiser_id
left join lateral (select u.id from fm20.campaign_username u where u.Advertiser_id=t.Advertiser_id limit 1) as Acct on true
-- left join fm20.marketing_sources_from_DbD d ON (t.Tracker_ID=d.Tracker_ID OR t.Tracker_Name=d.Tracker_Name OR t.Tracker_id=d.Tracker_Name OR t.Tracker_Name=d.Tracker_id )
-- and t.Description LIKE CONCAT('%', d.Brand, '%')
where t.Username_id is null
;
update fm20.campaign_marketing_source_test_all t
left join fm20.campaign_advertiser a on a.id=t.Advertiser_id
left join lateral (select u.id from fm20.campaign_username u where u.Advertiser_id=t.Advertiser_id limit 1) as Acct on true
-- left join fm20.marketing_sources_from_DbD d ON (t.Tracker_ID=d.Tracker_ID OR t.Tracker_Name=d.Tracker_Name OR t.Tracker_id=d.Tracker_Name OR t.Tracker_Name=d.Tracker_id )
-- and t.Description LIKE CONCAT('%', d.Brand, '%')
set t.Username_id=Acct.id
where t.Username_id is null
;

-- -------------------------------------------------------
truncate table account_landing_pages;
insert ignore into account_landing_pages (`Account_id`,`landing_page_channel`,`landing_page_url`,`landing_page_name`)
-- ,`landing_page_logo`,`landing_page_color`,`product`,`Status`,`Status_id`,`Stat_effect`,`Stat_aggreg`,`Stat_Affi`,`nation`
-- ,`traffic_source`,`socials`,`Owner`,`Priority`,`Comparator_Url`,`File`,`Creation_Date`,`Last_Update`,`Operator` 
select id,username as landing_page_channel,username as landing_page_url,"Default" as landing_page_name
from account_account a
where id>1
;

UPDATE campaign_marketing_source_test_all m
LEFT JOIN account_landing_pages l ON l.Account_id=m.Affiliate_id
SET Channel_id=l.id
;
UPDATE campaign_marketing_source_test_all m
SET Deal_id=1,Country_Deal="",Product_Deal="",Deal_Valid_From="2024-01-01"
;
INSERT INTO account_account_groups (account_id,group_id)
SELECT a.id,"3" FROM account_account a WHERE a.id>6;

select * 
from campaign_marketing_source
where Tracklink LIKE '%aspx?pid=%' or Tracklink LIKE '%siteid=%' or Tracklink LIKE '%mid=%' or Tracklink LIKE '%z=%'
or Tracklink LIKE '%?affiliate=%'
;

update fm20.campaign_marketing_source_test_all 
set Tracker_ID=case  WHEN Tracklink LIKE '%aspx?pid=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Tracklink, '?pid=', -1), '&', 1)
--                      WHEN Tracklink LIKE '%siteid=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Tracklink, 'siteid=', -1), '&', 1)
--                      WHEN Tracklink LIKE '%mid=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Tracklink, 'mid=', -1), '_', -1)
--                      WHEN Tracklink LIKE '%z=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Tracklink, 'z=', -1), '&', 1)
--                      WHEN Tracklink LIKE '%?affiliate=%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Tracklink, '?affiliate=', -1), '_', 1)
                     ELSE Tracker_ID END
;

-- ----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------

-- SELECT m.id as MS_id,m.Status_Adv_id,SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1) AS Adv,SUBSTRING_INDEX(b.Advertiser_Name, ' ', 1) AS Brnd,b.Advertiser_Name,b.id AS Adv_id,b.Publisher_id
-- FROM 
UPDATE 
campaign_marketing_source_test_all m
LEFT JOIN campaign_advertiser b ON SUBSTRING_INDEX(b.Advertiser_Name, ' ', 1) = SUBSTRING_INDEX(m.Status_Adv_id, ' ', 1)
SET m.Advertiser_id=b.id,m.Publisher_id=b.Publisher_id
WHERE b.id IS NOT null
;
-- select d.username,t.* from
UPDATE 
fm20.campaign_marketing_source_test_all t
LEFT JOIN campaign_advertiser b ON b.id=t.Advertiser_id
LEFT join fm20.marketing_sources_from_DbD d on (t.Tracker_ID=d.Tracker_ID OR t.Tracker_Name=d.Tracker_Name) and d.Brand=b.Advertiser_Name
SET Username_id=d.username
WHERE d.username is not null
;

UPDATE campaign_username u
SET u.Product_Deal=IFNULL(u.Product_Deal,''),u.Country_Deal=IFNULL(u.Country_Deal,''),
    u.Valid_From=IFNULL(u.Valid_From,'2024-01-01'),
    u.Deal_Main_id=1
WHERE u.Deal_Main_id IS NULL
;
-- -------------------------------------------------------------
/**************************************************************/
-- -------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE campaign_mkt_source_url;
TRUNCATE campaign_marketing_source;
TRUNCATE campaign_mkt_source_deal;
INSERT IGNORE INTO campaign_marketing_source SELECT * FROM campaign_marketing_source_test_all;

-- Procesos upd fact1/fact/comisiones
CALL Snapshot_day_by_day_fact1_upd_from_dbd('CM');
CALL Snapshot_day_by_day_fact1_upd_from_dbd('LM');
call Sync_Fact2_from_Fact1('mode=RUN,month=LM,MS_id=allall,db=fm20');
CALL total_monthy_comm_ges_upd('');
CALL Snapshot_day_by_day_fact2_upd_cm;
CALL total_monthy_comm_aff_upd('');

-- -------------------------------------------------------------
/**************************************************************/
-- -------------------------------------------------------------
With DbD_detail as (
select D.Brand,D.Tracker_ID,D.Tracker_Name,D.Username,
   -- M.id as MS_id,M.Tracker_ID as MTracker_ID, M.Tracker_Name as MTracker_Name,M.Code,
   ad.Advertiser_Name,ad.id AS Adv_id,
   cu.Username AS Accnt,
   p.Advertiser_Name AS Publ,p.id AS Pub_id
from Snapshot_day_by_day D
inner join campaign_username cu on cu.id=D.Username
inner join campaign_advertiser ad on ad.id=cu.Advertiser_id
inner join campaign_publisher p on p.id=cu.Publisher_id
group by D.Brand,D.Tracker_ID,D.Tracker_Name,D.Username
)
update campaign_marketing_source_test_all m
inner join DbD_detail D on D.Adv_id=m.Advertiser_id and D.Tracker_ID=m.Tracker_ID and D.Tracker_Name=m.Tracker_Name and D.Username=m.Username_id
inner join campaign_advertiser ad on ad.id=D.Adv_id
-- inner join campaign_publisher p on p.id=D.Pub_id
set m.Advertiser_id=D.Adv_id,m.Publisher_id=D.Pub_id
;
-- -------------- Arreglos posteriores

-- SELECT * FROM 
UPDATE 
`fm20`.`campaign_marketing_source` m
SET Username=10
WHERE Advertiser_id=69 AND m.Username_id IS null
;
-- -------------------------------------------------------------
SET @DateFrom = "2026-01-01";
WITH Detail_Fact1 as (
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
  WHERE LEFT(Date,7)>=@DateFrom 
      AND (MS_ID IS NULL OR ifnull(Deal_Ges_id,0)=0 
			OR (Affiliate!='_Unassigned' AND (ifnull(Deal_Aff_id,0)=0 AND Qualified_Players<>0)))
      AND (Qualified_Players<>0 OR Net_Revenue<>0)
  GROUP BY Brand,username,Tracker_ID,Tracker_Name,Product HAVING Warning!=''
  ORDER BY Brand,Affiliate,Tracker_ID,Tracker_Name
)
SELECT * FROM Detail_Fact1
;
  -- -----------------------------------------------------------------------
  
UPDATE campaign_marketing_source_test
SET Username_id=257
WHERE Username_id=10
;
-- select * from
UPDATE 
campaign_marketing_source_test
SET Username_id=30
WHERE Username_id in (29,30) and Tracker_Name like '%casino%'
;
-- SELECT * FROM 
update
`fm20`.`campaign_marketing_source_test` 
SET Username_id=20
WHERE `Description` IN ('Lottomatica Casino - Lottomatica Casino')
;
-- ---------------Deals ------------------------------
DROP TABLE IF EXISTS fm20.campaign_deal_affiliate_fabio;
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

update `campaign_deal_affiliate`
   SET Currency=ifnull(Currency,"EUR"),Deal_Name=
 	CONCAT('CPA: ',round(CPA_value,0),' ',Currency,IF(Baseline>0,CONCAT(' BL: ',Baseline,' ',Currency),''),
	CASE WHEN RS_Percentage_Displayed>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage_Displayed,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        WHEN RS_Percentage>0  
        THEN CONCAT(' + RS: ',round(RS_Percentage,0),'%',' (By: ',RS_Base,' /CPA-RS: '
      		 ,IF(RS_Against_CPA>0,'Yes','No'),')')
        ELSE '' END)
where ifnull(Deal_Name,"")=""
;   
-- Select d.CPA_value,ifnull(cpaassigned,0),d.RS_Percentage,ifnull(rsassigned,0)  from
UPDATE 
campaign_marketing_source_test_all m
INNER JOIN `fabio`.`jqe_fm20aff_users_campaigns` c on c.id=m.Advertiser_id_OK
inner join `campaign_deal_affiliate` d on d.CPA_value=ifnull(cpaassigned,0) and d.RS_Percentage=ifnull(rsassigned,0)  
SET m.Deal_id=d.id
;   
-- --------------------------------------------------------------------
-- TRUNCATE campaign_mkt_source_deal;
-- INSERT IGNORE INTO campaign_marketing_source SELECT * FROM campaign_marketing_source_test;
UPDATE Snapshot_day_by_day
SET Username=257
WHERE Username=10
;
UPDATE Snapshot_day_by_day
SET Brand="Betsson" -- Username=257
WHERE Username=270
;
-- UPDATE campaign_marketing_source
-- SET Username_id=257
-- WHERE Username_id=10
;
