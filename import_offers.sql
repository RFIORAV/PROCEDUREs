/*
import_offers.sql
Crea la tabla external_ms_list e importa el CSV de ofertas RiteMood.
Tras la carga, completa campos derivados y lookups a campaign_*.

Ejecutar (PowerShell):
& "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" `
  -h localhost -P 3304 --protocol=tcp -u b3w1nn3r -pabcd `
  --local-infile=1 -D ritemood `
  -e "SOURCE D:/Reinaldo/_FRA/db/PROCEDUREs/import_offers.sql"

CSV origen:
  D:\Reinaldo\_FRA\db\ritemood\offers-2026_09_02_10_16_03 (1) (2).csv

Requiere --local-infile=1 en el cliente MySQL.

Campos derivados (tras import):
  Brand         = texto a la izquierda del primer guión en title
  Affiliate     = texto entre [] en title
  Baseline      = importe EUR de "A minimum deposit of XX&euro" en description
  Publisher_id  = campaign_publisher.id donde Advertiser_Name = advertiser
  Publisher     = campaign_publisher.Advertiser_Name (mismo match)
  Advertiser_id = campaign_advertiser.id donde Advertiser_Name = Brand
  Tracker_name  = title
  Tracker_id    = valor de mid= | tag= | utm_campaign= en tracking_url (hasta &)
  CPA_Aff       = payouts sin sufijo EUR
  CPA_Ges       = our_revenue sin sufijo EUR

02.09.2026 v1 Primera versión
29.09.2026 v1.1 Campos Publisher_id, Publisher, Brand, Advertiser_id, Baseline, Affiliate
29.09.2026 v1.2 Campos Tracker_name, Tracker_id, CPA_Aff, CPA_Ges
*/

USE ritemood;

DROP TABLE IF EXISTS external_ms_list;

CREATE TABLE external_ms_list (
  id                 INT            NOT NULL,
  external_offer_id  VARCHAR(64)    NULL,
  title              VARCHAR(128)   NOT NULL,
  status             VARCHAR(32)    NOT NULL,
  advertiser         VARCHAR(64)    NULL,
  tracking_url       VARCHAR(512)   NULL,
  preview_url        VARCHAR(512)   NULL,
  description        TEXT           NULL,
  notes              VARCHAR(255)   NULL,
  countries          VARCHAR(64)    NULL,
  categories         VARCHAR(64)    NULL,
  top_offer          VARCHAR(8)     NULL,
  cr                 DECIMAL(10,2)  NULL,
  daily_limit        VARCHAR(32)    NULL,
  total_limit        VARCHAR(32)    NULL,
  last_day           INT            NULL,
  today              INT            NULL,
  payouts            VARCHAR(32)    NULL,
  our_revenue        VARCHAR(32)    NULL,
  privacy_level      VARCHAR(32)    NULL,
  created_at         DATETIME       NULL,
  updated_at         DATETIME       NULL,
  released_at        DATETIME       NULL,
  kpi                TEXT           NULL,
  offer_managers     VARCHAR(64)    NULL,
  Publisher_id       INT            NULL,
  Publisher          VARCHAR(150)   NULL,
  Brand              VARCHAR(128)   NULL,
  Advertiser_id      INT            NULL,
  Baseline           DECIMAL(10,2)  NULL,
  Affiliate          VARCHAR(32)    NULL,
  Tracker_name       VARCHAR(128)   NULL,
  Tracker_id         VARCHAR(128)   NULL,
  CPA_Aff            DECIMAL(10,2)  NULL,
  CPA_Ges            DECIMAL(10,2)  NULL,
  PRIMARY KEY (id),
  KEY idx_status (status),
  KEY idx_advertiser (advertiser),
  KEY idx_categories (categories),
  KEY idx_top_offer (top_offer),
  KEY idx_publisher_id (Publisher_id),
  KEY idx_advertiser_id (Advertiser_id),
  KEY idx_brand (Brand),
  KEY idx_affiliate (Affiliate),
  KEY idx_tracker_id (Tracker_id)
) ENGINE=InnoDB
  COMMENT='Ofertas importadas desde export RiteMood';

LOAD DATA LOCAL INFILE 'D:/Reinaldo/_FRA/db/ritemood/offers-2026_09_02_10_16_03 (1) (2).csv'
INTO TABLE external_ms_list
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
  @id,
  @external_offer_id,
  @title,
  @status,
  @advertiser,
  @tracking_url,
  @preview_url,
  @description,
  @notes,
  @countries,
  @categories,
  @top_offer,
  @cr,
  @daily_limit,
  @total_limit,
  @last_day,
  @today,
  @payouts,
  @our_revenue,
  @privacy_level,
  @created_at,
  @updated_at,
  @released_at,
  @kpi,
  @offer_managers
)
SET
  id                = CAST(@id AS UNSIGNED),
  external_offer_id = NULLIF(NULLIF(TRIM(@external_offer_id), ''), '-'),
  title             = TRIM(@title),
  status            = TRIM(@status),
  advertiser        = NULLIF(NULLIF(TRIM(@advertiser), ''), '-'),
  tracking_url      = NULLIF(NULLIF(TRIM(@tracking_url), ''), '-'),
  preview_url       = NULLIF(NULLIF(TRIM(@preview_url), ''), '-'),
  description       = NULLIF(NULLIF(TRIM(@description), ''), '-'),
  notes             = NULLIF(NULLIF(TRIM(@notes), ''), '-'),
  countries         = NULLIF(NULLIF(TRIM(@countries), ''), '-'),
  categories        = NULLIF(NULLIF(TRIM(@categories), ''), '-'),
  top_offer         = NULLIF(NULLIF(TRIM(@top_offer), ''), '-'),
  cr                = NULLIF(NULLIF(TRIM(@cr), ''), '-'),
  daily_limit       = NULLIF(NULLIF(TRIM(@daily_limit), ''), '-'),
  total_limit       = NULLIF(NULLIF(TRIM(@total_limit), ''), '-'),
  last_day          = NULLIF(NULLIF(TRIM(@last_day), ''), '-'),
  today             = NULLIF(NULLIF(TRIM(@today), ''), '-'),
  payouts           = NULLIF(NULLIF(TRIM(@payouts), ''), '-'),
  our_revenue       = NULLIF(NULLIF(TRIM(@our_revenue), ''), '-'),
  privacy_level     = NULLIF(NULLIF(TRIM(@privacy_level), ''), '-'),
  created_at        = STR_TO_DATE(NULLIF(NULLIF(TRIM(@created_at), ''), '-'), '%d/%m/%Y %H:%i'),
  updated_at        = STR_TO_DATE(NULLIF(NULLIF(TRIM(@updated_at), ''), '-'), '%d/%m/%Y %H:%i'),
  released_at       = STR_TO_DATE(NULLIF(NULLIF(TRIM(@released_at), ''), '-'), '%d/%m/%Y %H:%i'),
  kpi               = NULLIF(NULLIF(TRIM(@kpi), ''), '-'),
  offer_managers    = NULLIF(NULLIF(TRIM(@offer_managers), ''), '-'),
  Brand             = NULLIF(TRIM(SUBSTRING_INDEX(TRIM(@title), '-', 1)), ''),
  Affiliate         = CASE
                        WHEN LOCATE('[', TRIM(@title)) > 0
                         AND LOCATE(']', TRIM(@title)) > LOCATE('[', TRIM(@title))
                        THEN NULLIF(TRIM(SUBSTRING(
                               TRIM(@title),
                               LOCATE('[', TRIM(@title)) + 1,
                               LOCATE(']', TRIM(@title)) - LOCATE('[', TRIM(@title)) - 1
                             )), '')
                        ELSE NULL
                      END,
  Baseline          = CAST(
                        NULLIF(
                          REGEXP_SUBSTR(
                            REGEXP_SUBSTR(IFNULL(NULLIF(TRIM(@description), '-'), ''), 'A minimum deposit of [0-9]+'),
                            '[0-9]+'
                          ),
                          ''
                        ) AS DECIMAL(10,2)
                      ),
  Tracker_name      = TRIM(@title),
  Tracker_id        = CASE
                        WHEN IFNULL(NULLIF(TRIM(@tracking_url), '-'), '') LIKE '%mid=%'
                        THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(@tracking_url), 'mid=', -1), '&', 1), '')
                        WHEN IFNULL(NULLIF(TRIM(@tracking_url), '-'), '') LIKE '%tag=%'
                        THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(@tracking_url), 'tag=', -1), '&', 1), '')
                        WHEN IFNULL(NULLIF(TRIM(@tracking_url), '-'), '') LIKE '%utm_campaign=%'
                        THEN NULLIF(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(@tracking_url), 'utm_campaign=', -1), '&', 1), '')
                        ELSE NULL
                      END,
  CPA_Aff           = CAST(
                        NULLIF(REPLACE(NULLIF(NULLIF(TRIM(@payouts), ''), '-'), 'EUR', ''), '')
                        AS DECIMAL(10,2)
                      ),
  CPA_Ges           = CAST(
                        NULLIF(REPLACE(NULLIF(NULLIF(TRIM(@our_revenue), ''), '-'), 'EUR', ''), '')
                        AS DECIMAL(10,2)
                      );

/* Lookups: Publisher / Advertiser */
UPDATE external_ms_list e
LEFT JOIN campaign_publisher p
  ON p.Advertiser_Name = e.advertiser
SET
  e.Publisher_id = p.id,
  e.Publisher    = p.Advertiser_Name;

UPDATE external_ms_list e
LEFT JOIN campaign_advertiser a
  ON a.Advertiser_Name = e.Brand
SET
  e.Advertiser_id = a.id;

SELECT COUNT(*) AS filas_importadas FROM external_ms_list;
SELECT
  SUM(Publisher_id IS NOT NULL) AS matched_publisher,
  SUM(Advertiser_id IS NOT NULL) AS matched_advertiser,
  SUM(Baseline IS NOT NULL) AS with_baseline,
  SUM(Affiliate IS NOT NULL) AS with_affiliate,
  SUM(Tracker_id IS NOT NULL) AS with_tracker_id,
  SUM(CPA_Aff IS NOT NULL) AS with_cpa_aff
FROM external_ms_list;

SELECT id, title, Tracker_name, Tracker_id, CPA_Aff, CPA_Ges, Brand, Affiliate
FROM external_ms_list
ORDER BY id DESC
LIMIT 10;
