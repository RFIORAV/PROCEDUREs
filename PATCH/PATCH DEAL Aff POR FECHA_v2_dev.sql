/*    PATCH DEALS POR FECHA - NO UTILIZAR SIN REVISAR PREVIAMENTE
      04.02.2024 
*/
-- --------------------------------------------------------------------------------------------------

UPDATE campaign_mkt_source_deal SET Product="" WHERE Product<"a" OR Product IS NULL;
UPDATE campaign_deal_gestor_prod_date SET Product="" WHERE Product<"a" OR Product IS NULL;

-- --------------------------------------------------------------------------------------------------
-- Selección de registros repetidos de los cuales solo debería quedar uno
SELECT count(*) from campaign_mkt_source_deal where is_active=0; -- 2152 -- 1902
SELECT count(*) from campaign_mkt_source_deal where is_active=1; -- 5572 -- 5504
SELECT count(*) from campaign_mkt_source_deal                  ; -- 7724 -- 7406

SELECT `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
      ,`Country`,`is_active`,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
FROM campaign_mkt_source_deal;


SELECT * 
from campaign_mkt_source_deal
GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country -- ,is_active 
HAVING COUNT(*)>1
ORDER BY MS_id,Deal_Valid_From desc
;

-- Extracción de líneas únicas

DROP TABLE IF EXISTS `campaign_mkt_source_deal_depurada`;

CREATE TABLE `campaign_mkt_source_deal_depurada`
   WITH Sin_repetidos_activos_inactivos as (
      SELECT MAX(`id`) AS `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
            ,`Country`,`is_active`,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
      FROM campaign_mkt_source_deal_20240303
      GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country,is_active
),
 Sin_repetidos_mixtos as (
      SELECT MAX(`id`) AS `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
            ,`Country`,if(COUNT(*)>1,1,`is_active`) AS `is_active`,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
      FROM Sin_repetidos_activos_inactivos
      GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country
)
SELECT * FROM Sin_repetidos_mixtos ORDER BY id
;

-- Regeneración tabla original
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `campaign_mkt_source_deal`;
INSERT INTO campaign_mkt_source_deal SELECT * FROM campaign_mkt_source_deal_depurada D WHERE D.id>0
;
-- muestra cambios
SELECT * 
FROM campaign_mkt_source_deal AS t1
LEFT JOIN campaign_deal_gestor_prod_date_20240303 AS t2
    ON t1.id = t2.id AND t1.is_active != t2.is_active -- AND t1.campo3 = t2.campo3
WHERE t2.id IS not NULL -- OR t2.is_active IS NULL -- OR t2.campo3 IS NULL;
;














-- ALTER TABLE `campaign_mkt_source_deal`
-- 	DROP INDEX `MS_id`,
-- 	ADD UNIQUE INDEX `MS_id` (`MS_id`, `Deal_Valid_From`, `Affiliate_id`, `Product`, `Deal_id`, `Country`) USING BTREE;
--    
-- DROP TABLE IF EXISTS `campaign_mkt_source_deal_depurada`;

-- ANALISIS DE REDUNDANCIA

/*
DROP TABLE IF EXISTS `campaign_mkt_source_deal_depurada`;

-- CREATE TABLE `campaign_mkt_source_deal_depurada`
   WITH Sin_repetidos_activos_inactivos as (
      SELECT * FROM campaign_mkt_source_deal
      WHERE is_active=1
--       GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country
      ORDER BY MS_id,Deal_Valid_From desc,Affiliate_id,Product,id desc -- ,Country
),
 Sin_repetidos_mixtos as (
      SELECT `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
            ,`Country`,1,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
      FROM Sin_repetidos_activos_inactivos
      GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country
)
SELECT * FROM Sin_repetidos_mixtos ORDER BY id
;