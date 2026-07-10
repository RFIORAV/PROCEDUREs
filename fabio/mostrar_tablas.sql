-- Script MySQL 8.0 para mostrar el contenido de las tablas
-- Tablas: jqe_fm20aff_users, jqe_fm20aff_campaigns, jqe_fm20aff_books y jqe_fm20aff_reports
 -- Mostrar contenido de la tabla users con user_info

SELECT u.*,
       ui.*
FROM jqe_users u
LEFT JOIN jqe_fm20aff_users_info ui ON u.id = ui.userid;

-- Mostrar contenido de la tabla campaigns con books y users

SELECT c.*,
       b.*,
       u.*
FROM jqe_fm20aff_campaigns c
LEFT JOIN jqe_fm20aff_books b ON c.bookid = b.id
LEFT JOIN jqe_fm20aff_users_campaigns ui ON c.campaignid = ui.id
LEFT JOIN jqe_users u ON ui.userid = u.id;

-- Mostrar contenido de la tabla books

SELECT *
FROM jqe_fm20aff_books;

-- Mostrar contenido de la tabla reports

SELECT *
FROM jqe_fm20aff_reports;


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
       u.user_login AS Affiliate,
       b.id,
       b.bookname,
       c.id,
       c.campaignname,
       uc.linkref as Shortlink,
       case when left(uc.linkref,20)="https://fm2bet.link/" then mid(uc.linkref,21) else uc.linkref end as Token,
       lnkr.Tracklink
FROM `jqe_fm20aff_reports` r
LEFT JOIN jqe_fm20aff_users_campaigns uc ON r.usercampaignid = uc.id
LEFT JOIN jqe_fm20aff_campaigns c ON uc.campaignid = c.id
LEFT JOIN jqe_fm20aff_books b ON c.bookid = b.id
LEFT JOIN jqe_users u ON uc.userid = u.id
left join lateral (Select ifnull(lr.linkref,uc.linkref) Tracklink from jqe_fm20aff_linkref_redirector lr 
   where lr.urltoken = mid(uc.linkref,21)) as lnkr ON true
WHERE r.`datereport` >= UNIX_TIMESTAMP('2025-12-01')
   AND r.`datereport` <= UNIX_TIMESTAMP('2025-12-31')
   AND r.cpa>0 ;

SELECT -- r.`usercampaignid`,
       DATE_FORMAT(FROM_UNIXTIME(r.`datereport`), '%Y-%m') AS `datereport`,
       -- r.`dealtypeassigned`,
       b.id,
       IFNULL(b.bookname,r.usercampaignid) as bookname,
       c.id,
       c.campaignname,
       -- u.user_login AS Affiliate,
       sum(ifnull(r.`clicks`,0)) as `clicks`,
       sum(ifnull(r.`registrazioni`,0)) as `registrazioni`,
       sum(ifnull(r.`depositi`,0)) as `depositi`,
       sum(ifnull(r.`firsttimedeposit`,0)) as `firsttimedeposit`,
       sum(ifnull(r.`cpa`,0)) as `cpa`,
       ifnull(r.`cpaassigned`,0) AS `cpaassigned`,
       sum(ifnull(r.`netrevenue`,0)) as `netrevenue`,
       ifnull(r.`rsassigned`,0) as `rsassigned`,
       -- r.`rssubaffiliate`,
       sum(ifnull(r.`ricavi`,0)) as `ricavi`
       -- r.`dateupdate`,
--        uc.linkref as Shortlink,
--        case when left(uc.linkref,20)="https://fm2bet.link/" then mid(uc.linkref,21) else uc.linkref end as Token,
--        lnkr.Tracklink
FROM `jqe_fm20aff_reports` r
LEFT JOIN jqe_fm20aff_users_campaigns uc ON r.usercampaignid = uc.id
LEFT JOIN jqe_fm20aff_campaigns c ON uc.campaignid = c.id
LEFT JOIN jqe_fm20aff_books b ON c.bookid = b.id
LEFT JOIN jqe_users u ON uc.userid = u.id
left join lateral (Select ifnull(lr.linkref,uc.linkref) Tracklink from jqe_fm20aff_linkref_redirector lr 
   where lr.urltoken = mid(uc.linkref,21)) as lnkr ON true
-- WHERE r.`datereport` >= UNIX_TIMESTAMP('2025-01-01')
--    AND r.`datereport` <= UNIX_TIMESTAMP('2025-12-31')
--    AND r.cpa>0
GROUP BY DATE_FORMAT(FROM_UNIXTIME(r.`datereport`), '%Y-%m') -- , b.id, c.id -- WITH rollup
ORDER BY DATE_FORMAT(FROM_UNIXTIME(r.`datereport`), '%Y-%m'), b.bookname, c.campaignname
   ;

ALTER TABLE `jqe_fm20aff_linkref_redirector` ADD UNIQUE INDEX `urltoken` (`urltoken`);

SELECT r.id,
       DATE_FORMAT(FROM_UNIXTIME(r.dategenerated), '%Y-%m-%d') AS `dategenerated`,
       r.urltoken,
       r.linkref,
       r.islocked,
       r.clickcount,
       r.usercampaignid,
       c.*
FROM jqe_fm20aff_linkref_redirector r
LEFT JOIN jqe_fm20aff_users_campaigns uc ON uc.id = r.usercampaignid
LEFT JOIN jqe_fm20aff_campaigns c ON uc.campaignid = c.id
LEFT JOIN jqe_fm20aff_books b ON c.bookid = b.id
LEFT JOIN jqe_users u ON uc.userid = u.id ;


SELECT -- DISTINCT
* , -- usercampaignid -- urltoken
COUNT(*)
FROM jqe_fm20aff_linkref_redirector r
WHERE r.islocked=1;


SET FOREIGN_KEY_CHECKS = 0;


INSERT
IGNORE INTO `campaign_marketing_source` (`Code`, `Tracklink`, `Tracker_ID`, `Tracker_Name`, `Code_To_Affiliate`, `Product`, -- `Status`,
 `Status_id`, `Valid_From`, `Description`, `Affiliate_id`, `Advertiser_id`, `Publisher_id`, -- `Campaign_id`,
 `Username_id` -- `Deal_id`,
 -- `Country_Deal`,
 -- `Product_Deal`,
 -- `Deal_Valid_From`
 ) ;


SELECT -- c.id,
 r.urltoken AS `Code`,
 r.linkref AS `Tracklink`,
 r.urltoken AS `Tracker_ID`,
 c.campaignname AS `Tracker_Name`,
 r.urltoken AS `Code_To_Affiliate`,
 c.productoffered AS `Product`, -- null,
 c.campaignstatus AS `Status_id`,
 DATE_FORMAT(FROM_UNIXTIME(r.dategenerated), '%Y-%m-%d') AS `Valid_From`,
 c.description AS `Description`,
 uc.userid AS `Affiliate_id`,
 b.id AS `Advertiser_id`,
 b.id AS `Publisher_id`,
 b.id AS `Username_id`
FROM jqe_fm20aff_linkref_redirector r
INNER JOIN jqe_fm20aff_users_campaigns uc ON uc.id = r.usercampaignid
INNER JOIN jqe_fm20aff_campaigns c ON uc.campaignid = c.id
INNER JOIN jqe_fm20aff_books b ON c.bookid = b.id
INNER JOIN jqe_users u ON uc.userid = u.id -- WHERE c.id IS NOT NULL
ORDER BY r.id DESC ;


SELECT `id`,
       `userid`,
       `campaignid`,
       `isrequested`,
       `campaignname`,
       `daterequested`,
       `campaignrequeststatus`,
       `dealtypeassigned`,
       `cpaassigned`,
       `rsassigned`,
       `linkref`
FROM `jqe_fm20aff_users_campaigns`;


SELECT DISTINCT userid
FROM `jqe_fm20aff_users_campaigns`;