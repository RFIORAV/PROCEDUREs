/*
SCRIPT_Parse_Reward_Plan_v1.sql

Parsea Reward_plan → CPA, RS (RevShare), BL según DOC_Parse_Reward_Plan.md

Uso:
  Ejecutar el script completo en MySQL 8.0.37+ / 8.4.
  Sustituir la tabla temporal por la fuente real (p. ej. Snapshot_day_by_day_rew_plan)
  reutilizando las mismas expresiones de extracción.

08.10.2026 v1    Primera versión operativa
*/

SET NAMES 'utf8mb4';

DROP TEMPORARY TABLE IF EXISTS tmp_reward_plan_sample;
CREATE TEMPORARY TABLE tmp_reward_plan_sample (
  id              INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Reward_plan     VARCHAR(200) NOT NULL,
  Operator        VARCHAR(100) NULL,
  Advertiser_Name VARCHAR(100) NULL,
  Account         VARCHAR(100) NULL,
  Account_id      INT          NULL
);

INSERT INTO tmp_reward_plan_sample
  (Reward_plan, Operator, Advertiser_Name, Account, Account_id)
VALUES
  ('80 CPA (30/30) (IT) + 35 RS', '7Stars', 'Rabona', 'Euroaffiliati', 113),
  ('100 CPA (30) + 30 RS', 'KNGPartners', 'Kingmaker', 'arturohardisson', 215),
  ('HYBRID - CPA 65€ + RS 35% - BL 10€', 'Betpartners', 'EuroBet', 'MisterAff_1', 15),
  ('Rev Share 30%', 'Betpartners', 'EuroBet', 'Betquoteit', 10),
  ('fullmoon 75€ + 35%', 'Sisal', 'Sisal', 'fullmoon', 24),
  ('fullmoon_casino 100€ + 30%', 'Sisal', 'Sisal', 'fullmoon', 24),
  ('Rev Share - Flat Revshare 35%', 'Betpartners', 'EuroBet', 'MisterAff_1', 15),
  ('Rev share - Flat Revshare 5%', 'Betpartners', 'EuroBet', 'BonusWelcome', 70),
  ('RevShare Flat per Product', 'Betsson', 'StarCasino', 'Euroaffiliati_2', 124),
  ('Subaffiliation - EUR', 'Betsson', 'StarCasino', 'Euroaffiliati_1', 132),
  ('RevShare Ladder', 'Betsson', 'StarCasino', 'Euroaffiliati_1', 132),
  ('0 + 35%', 'Sisal', 'Sisal', 'affintelligence', 196),
  ('80EUR CPA (10) (IT)', '7Stars', 'Rabona', 'Euroaffiliati', 113),
  ('RS 30% (CASINO - SPORT)', 'Betpartners', 'EuroBet', 'GiocatoriVip', 17),
  ('RevShare Flat', 'Betsson', 'StarCasino', 'Euroaffiliati_2', 124),
  ('HYBRID - CPA 40€ + RS 35% - BL 10€', 'Betpartners', 'EuroBet', 'ilpres99', 248),
  ('Rev share cap_5%_after_3y', 'Betpartners', 'EuroBet', 'ilpres99', 248),
  ('Hybrid (CPA/CPL+RevShare Flat)', 'Betsson', 'StarCasino', 'AffiliateAccess', 270),
  ('HYBRID - CPA 80€ + RS 30% (CASINO - SPORT) - BL 10€', 'Betpartners', 'EuroBet', 'Webwise', 272),
  ('Rev share - Flat Revshare 30%', 'Betpartners', 'EuroBet', 'PromozioniCasino', 20),
  ('70 CPA (30/30) + 35 RS', '7Stars', 'Casinia', 'Euroaffiliati', 116),
  ('80EUR CPA (10) (IT)', 'Playidpartners', 'PlayID', 'info@wws360.com', 284),
  ('Bingo', 'Entain', 'Bwin', 'KarlGula', 262),
  ('150 + 30% BL 30', 'JoinAff', 'CasaBet', 'KarlGula', 258),
  ('100 CPA + 40%Rs Bl 25€', 'JoinAff', 'CasaBet', 'KarlGula', 258),
  ('140 CPA + 20%RS, 20BL', 'JoinAff', 'CasaBet', 'KarlGula', 258),
  ('200EUR CPA + 40 RS', 'Tritana', 'Westace', 'KarlGulaMain', 265),
  ('220EUR CPA + 40 RS', 'Tritana', 'Westace', 'KarlGulaMain', 265),
  ('130EUR CPA (20) + 40 RS', 'WowPartners', 'Legiano', 'KarlGula', 260),
  ('CPA 100 + 40% (30BL)', 'JoinAff', 'Spinko', 'KarlGula', 269),
  ('200EUR CPA (CZ) + 40 RS (CZ)', 'Tritana', 'Spinboss', 'KarlGulaMain', 266),
  ('120EUR CPA (20/20) + 40 RS', 'WowPartners', 'Allyspin', 'KarlGula', 270),
  ('50% RS', 'JoinAff', 'Spinko', 'KarlGula', 269),
  ('CPA 150 + 40% (25 BL)', 'JoinAff', 'Spinko', 'KarlGula', 269),
  ('200EUR CPA (CZ SK) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGulaCZ', 268),
  ('250EUR CPA (CZ HR SK) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGulaCZ', 268),
  ('Empty', 'WowPartners', 'Bankonbet', 'KarlGula', 274),
  ('HYBRID - CPA 90€ + RS 35% - BL 10€', 'BetPartners', 'EuroBet', 'KarlGula1', 261),
  ('250EUR CPA (CZ SK) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGulaCZ', 268),
  ('200EUR CPA (CZ) + 40 RS', 'MioMedia', 'MalinaCasino', 'KarlGulaCZ', 282),
  ('250EUR CPA (CZ) + 40 RS', 'MioMedia', 'MalinaCasino', 'KarlGulaCZ', 282),
  ('150EUR CPA (IT) + 50 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('180EUR CPA (IT) + 50 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('200EUR CPA (IT) + 50 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('200EUR CPA (IT) + 30 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('100EUR CPA (IT) + 50 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('120EUR CPA (10/20) (IT) + 40 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('150EUR CPA (IT) + 40 RS', 'MioMedia', 'Pistolo', 'KarlGula77', 287),
  ('150EUR CPA (IT) + 35 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('200EUR CPA (IT) + 30 RS (IT)', 'MioMedia', 'SlotsPalace', 'KarlGula77', 289),
  ('180EUR CPA (CA) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('180EUR CPA (AU) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('180EUR CPA (CH) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('150EUR CPA (10/25) (IT) + 40 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('120 CPA (25) (IT) + 40 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('90 CPA (20) + 35 RS', 'MioMedia', 'MyEmpire', 'KarlGula77', 288),
  ('170EUR CPA (IT) + 40 RS', 'MioMedia', 'Golisimo', 'KarlGula77', 285),
  ('35 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('200EUR CPA (IT) + 40 RS (IT)', 'MioMedia', 'Pistolo', 'KarlGula77', 287),
  ('150EUR CPA (30) (IT) + 40 RS (IT)', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('150EUR CPA (20) (IT) + 40 RS (IT)', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('150EUR CPA + 40 RS', 'Tritana', 'Westace', 'KarlgulaCZ', 298),
  ('100EUR CPA (25) + 40 RS', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('120EUR CPA (IT) + 40 RS (IT)', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('150EUR CPA (20) + 40 RS', 'Tritana', 'Westace', 'KarlgulaCZ', 298),
  ('160EUR CPA + 40 RS', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('130EUR CPA (PT) + 30 RS (PT)', 'Tritana', 'Westace', 'KarlgulaCZ', 298),
  ('210EUR CPA + 30 RS', 'Tritana', 'Spinboss', 'KarlgulaCZ', 296),
  ('200EUR CPA (CZ HR SK) + 40 RS', 'MioMedia', 'Pistolo', 'KarlGulaCZ', 299),
  ('250EUR CPA (NO) + 30 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286),
  ('290EUR CPA (NO) + 30 RS', 'MioMedia', 'MalinaCasino', 'KarlGula77', 286);

-- ── Extracción (ignora líneas sin CPA/RS/BL) ────────────────────────────────────
-- Nota MySQL 8.x: REGEXP_SUBSTR no admite grupo de captura; se extrae el dígito
-- con REGEXP_REPLACE sobre el match completo.
SELECT
   P.Reward_plan
  ,P.Operator
  ,P.Advertiser_Name as Brand
  ,P.Account
  ,P.Account_id
  ,CAST(IFNULL(P.raw_cpa, 0) AS UNSIGNED) AS CPA
  ,CAST(IFNULL(P.raw_rs,  0) AS UNSIGNED) AS RS
  ,IFNULL(P.raw_bl, '')                   AS BL
FROM (
  SELECT
     S.Reward_plan
    ,S.Operator
    ,S.Advertiser_Name
    ,S.Account
    ,S.Account_id
    ,COALESCE(
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*(EUR|€)?[[:space:]]*CPA', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, 'CPA[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*€[[:space:]]*\\+', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+[[:space:]]*%', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        /* N+M (sin %): CPA = primer número — ej. 80+30 */
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+$', 1, 1, 'i'), '[^0-9].*$', ''), '')
     ) AS raw_cpa
    ,COALESCE(
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*%', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*RS([^A-Za-z]|$)', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '(^|[^A-Za-z])RS[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
        /* N+M (sin %): RS = segundo número — ej. 80+30 */
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+$', 1, 1, 'i'), '^[0-9]+[[:space:]]*\\+[[:space:]]*', ''), '')
     ) AS raw_rs
    ,COALESCE(
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '(^|[^A-Za-z])BL[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*BL([^A-Za-z]|$)', 1, 1, 'i'), '[^0-9].*$', ''), ''),
        NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '\\([0-9]+', 1, 1, 'i'), '[^0-9]', ''), '')
     ) AS raw_bl
  FROM (
    SELECT
       RP.Reward_plan, RP.Operator, A.`Advertiser_Name` AS Advertiser_Name
       , RP.Account, RP.`Account_id`,
       TRIM(Reward_plan) AS rp
    FROM `Snapshot_day_by_day_rew_plan` RP
    LEFT JOIN `campaign_username` U ON U.`id` = RP.`Account_id`
    LEFT JOIN `campaign_advertiser` A ON A.`id` = U.`Advertiser_id`
  ) S
) P
WHERE P.raw_cpa IS NOT NULL
   OR P.raw_rs  IS NOT NULL
   OR P.raw_bl  IS NOT NULL
ORDER BY P.Account_id, P.Reward_plan;
