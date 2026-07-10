/* CPA_Limit histórico desde campaign_marketing_source_history 

v1 31.05.2026 - CPA_Limit histórico: fact_Date usa el valor vigente en cada fecha
                 vía campaign_marketing_source_history (LATERAL + Aud_Date/Aud_Action)

);
*/

DROP TABLE IF EXISTS `campaign_mkt_source_cap_date`;
CREATE TABLE IF NOT EXISTS `campaign_mkt_source_cap_date` (
   `id`              INT           NOT NULL AUTO_INCREMENT,
   `MS_id`           INT           NOT NULL DEFAULT '0',
   `Date_Valid`      DATE          NULL     DEFAULT NULL,
   `Affiliate_id`    INT           NULL     DEFAULT NULL,
   `CPA_Limit`       INT           NULL     DEFAULT NULL,
   `is_active`       TINYINT       NULL     DEFAULT '1',
   `Creation_Date`   DATETIME      NULL     DEFAULT (now()),
   `Last_Update`     DATETIME      NULL     DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   `User`            VARCHAR(30)   NULL     DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   INDEX `MS_id`        (`MS_id`,`Date_Valid`) USING BTREE,
   INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE
);

INSERT INTO campaign_mkt_source_cap_date (
        `MS_id`
       ,`CPA_Limit`
       ,`Date_Valid`
       ,`Affiliate_id`
       ,`Creation_Date`
       ,`Last_Update`
       ,`User`
       )
SELECT 
       src.id,   
       src.CPA_Limit_Despues,
       src.Date_Valid,
       src.Affiliate_id,
       src.Fecha_Cambio,
       src.Fecha_Cambio,
       src.Aud_Agent
FROM (
    SELECT 
       h.id,
       m.Affiliate_id,
       h.Operator,
       ROW_NUMBER() OVER(PARTITION BY h.id ORDER BY h.Aud_Date ASC) AS rn,
       h.Aud_Date                                                    AS Fecha_Cambio,
       LEFT(h.Aud_Date, 10)                                          AS Date_Valid,
       h.CPA_Limit                                                   AS CPA_Limit_Antes,
       COALESCE(
          LEAD(h.CPA_Limit) OVER(PARTITION BY h.id ORDER BY h.Aud_Date ASC),
          m.CPA_Limit
       )                                                             AS CPA_Limit_Despues,
       h.Aud_Action,
       h.Aud_Agent
    FROM campaign_marketing_source_history h
    INNER JOIN campaign_marketing_source m ON m.id = h.id
    WHERE h.Aud_Action LIKE '%CPA_Limit%'
) AS src
ON DUPLICATE KEY UPDATE
    `CPA_Limit` = src.CPA_Limit_Despues;