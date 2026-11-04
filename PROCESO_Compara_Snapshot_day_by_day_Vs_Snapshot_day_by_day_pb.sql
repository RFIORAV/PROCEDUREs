-- Comparación de valores diarios por Account entre Snapshot_day_by_day y Snapshot_day_by_day_pb
-- ---------------------------------------------------------------------------------------------


WITH
usernames_pb AS (
  SELECT DISTINCT `Username`
  FROM `Snapshot_day_by_day_pb`
  WHERE `Date` >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    AND `Date` <  DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01')
    AND IFNULL(`Username`, '') > ''
),
agg_dbd AS (
  SELECT
    `Date`,
    `Username`,
    `Tracker_ID`,
    SUM(IFNULL(`Qualified_Players`, 0))   AS CPA,
    SUM(IFNULL(`First_Time_Deposit`, 0)) AS FTD,
    SUM(IFNULL(`Signups`, 0))            AS Sup,
    SUM(IFNULL(`Net_Revenue`, 0))        AS NR
  FROM `Snapshot_day_by_day`
  WHERE `Date` >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    AND `Date` <  DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01')
    AND `Username` IN (SELECT `Username` FROM usernames_pb)
  GROUP BY `Date`, `Username`, `Tracker_ID`
),
agg_pb AS (
  SELECT
    `Date`,
    `Username`,
    `Tracker_ID`,
    SUM(IFNULL(`Qualified_Players`, 0))   AS CPA,
    SUM(IFNULL(`First_Time_Deposit`, 0)) AS FTD,
    SUM(IFNULL(`Signups`, 0))            AS Sup,
    SUM(IFNULL(`Net_Revenue`, 0))        AS NR
  FROM `Snapshot_day_by_day_pb`
  WHERE `Date` >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    AND `Date` <  DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01')
    AND `Username` IN (SELECT `Username` FROM usernames_pb)
  GROUP BY `Date`, `Username`, `Tracker_ID`
),
comparacion AS (
  SELECT
    COALESCE(d.`Date`, p.`Date`)               AS `Date`,
    COALESCE(d.`Username`, p.`Username`)       AS `Username`,
    COALESCE(d.`Tracker_ID`, p.`Tracker_ID`)   AS `Tracker_ID`,
    IFNULL(d.CPA, 0) AS CPA,
    IFNULL(d.FTD, 0) AS FTD,
    IFNULL(d.Sup, 0) AS Sup,
    IFNULL(d.NR, 0)  AS NR,
    IFNULL(p.CPA, 0) AS CPA_pb,
    IFNULL(p.FTD, 0) AS FTD_pb,
    IFNULL(p.Sup, 0) AS Sup_pb,
    IFNULL(p.NR, 0)  AS NR_pb,
    IFNULL(d.CPA, 0) - IFNULL(p.CPA, 0) AS Diff_CPA,
    IFNULL(d.FTD, 0) - IFNULL(p.FTD, 0) AS Diff_FTD,
    IFNULL(d.Sup, 0) - IFNULL(p.Sup, 0) AS Diff_Sup,
    IFNULL(d.NR, 0)  - IFNULL(p.NR, 0)  AS Diff_NR
  FROM agg_dbd d
  LEFT JOIN agg_pb p
    ON p.`Date` = d.`Date`
   AND p.`Username` = d.`Username`
   AND IFNULL(p.`Tracker_ID`, '') = IFNULL(d.`Tracker_ID`, '')
  UNION
  SELECT
    COALESCE(d.`Date`, p.`Date`)               AS `Date`,
    COALESCE(d.`Username`, p.`Username`)       AS `Username`,
    COALESCE(d.`Tracker_ID`, p.`Tracker_ID`)   AS `Tracker_ID`,
    IFNULL(d.CPA, 0) AS CPA,
    IFNULL(d.FTD, 0) AS FTD,
    IFNULL(d.Sup, 0) AS Sup,
    IFNULL(d.NR, 0)  AS NR,
    IFNULL(p.CPA, 0) AS CPA_pb,
    IFNULL(p.FTD, 0) AS FTD_pb,
    IFNULL(p.Sup, 0) AS Sup_pb,
    IFNULL(p.NR, 0)  AS NR_pb,
    IFNULL(d.CPA, 0) - IFNULL(p.CPA, 0) AS Diff_CPA,
    IFNULL(d.FTD, 0) - IFNULL(p.FTD, 0) AS Diff_FTD,
    IFNULL(d.Sup, 0) - IFNULL(p.Sup, 0) AS Diff_Sup,
    IFNULL(d.NR, 0)  - IFNULL(p.NR, 0)  AS Diff_NR
  FROM agg_dbd d
  RIGHT JOIN agg_pb p
    ON p.`Date` = d.`Date`
   AND p.`Username` = d.`Username`
   AND IFNULL(p.`Tracker_ID`, '') = IFNULL(d.`Tracker_ID`, '')
  WHERE d.`Date` IS NULL
)
SELECT
  `Date`,
  `Username`,
  `Tracker_ID`,
  CPA, FTD, Sup, NR,
  CPA_pb, FTD_pb, Sup_pb, NR_pb,
  Diff_CPA, Diff_FTD, Diff_Sup, Diff_NR
FROM comparacion
UNION ALL
SELECT
  NULL,
  'TOTAL',
  NULL,
  SUM(CPA), SUM(FTD), SUM(Sup), SUM(NR),
  SUM(CPA_pb), SUM(FTD_pb), SUM(Sup_pb), SUM(NR_pb),
  SUM(Diff_CPA), SUM(Diff_FTD), SUM(Diff_Sup), SUM(Diff_NR)
FROM comparacion
ORDER BY
  CASE WHEN `Username` = 'TOTAL' THEN 1 ELSE 0 END,
  `Date`,
  `Username`,
  `Tracker_ID`;