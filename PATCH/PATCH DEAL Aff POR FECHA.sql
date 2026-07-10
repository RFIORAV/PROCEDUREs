/*    PATCH DEALS POR FECHA
      04.02.2024
*/
-- --------------------------------------------------------------------------------------------------

UPDATE campaign_mkt_source_deal SET Product="" WHERE Product<"a" OR Product IS NULL;
UPDATE campaign_deal_gestor_prod_date SET Product="" WHERE Product<"a" OR Product IS NULL;

-- --------------------------------------------------------------------------------------------------
-- Selección de registros repetidos de los cuales solo debería quedar uno

SELECT * from campaign_mkt_source_deal
GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country -- ,is_active 
HAVING COUNT(*)>1
ORDER BY MS_id,Deal_Valid_From desc
;

-- Extracción de líneas únicas

DROP TABLE IF EXISTS `campaign_mkt_source_deal_depurada`;

CREATE TABLE `campaign_mkt_source_deal_depurada`
   WITH Sin_repetidos_activos_inactivos as (
      SELECT * FROM campaign_mkt_source_deal
      GROUP BY MS_id,`Deal_id`,Deal_Valid_From,Product,Affiliate_id,Country,is_active
),
 Sin_repetidos_mixtos as (
      SELECT `id`,`MS_id`,`Deal_Valid_From`,`Product`,`Affiliate_id`,`Channel_id`,`Deal_id`
            ,`Country`,1,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
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

ALTER TABLE `campaign_mkt_source_deal`
	DROP INDEX `MS_id`,
	ADD UNIQUE INDEX `MS_id` (`MS_id`, `Deal_Valid_From`, `Affiliate_id`, `Product`, `Deal_id`, `Country`) USING BTREE;
   