/*    PATCH DEALS Gestor POR FECHA
      04.02.2024 - NO UTILIZAR - REVISAR ANTES DE UTILIZAR
*/
-- --------------------------------------------------------------------------------------------------

-- UPDATE campaign_mkt_source_deal SET Product="" WHERE Product<"a" OR Product IS NULL;
UPDATE campaign_deal_gestor_prod_date SET Product="" WHERE Product<"a" OR Product IS NULL;

-- --------------------------------------------------------------------------------------------------
-- Selección de registros REDUNDANTES de los cuales solo debería quedar EL MAS NUEVO

SELECT * -- ,COUNT(*) 
from campaign_deal_gestor_prod_date
GROUP BY Username_id,Valid_From,Product,Country,Deal_id,is_active 
HAVING COUNT(*)>1
ORDER BY Advertiser_id,Username_id,Valid_From desc
;

-- Extracción de líneas únicas

DROP TABLE IF EXISTS `campaign_deal_gestor_prod_date_depurada`;

CREATE TABLE `campaign_deal_gestor_prod_date_depurada`
   WITH Sin_repetidos_activos_inactivos as (
      SELECT * FROM campaign_deal_gestor_prod_date
      GROUP BY Username_id,Valid_From,Product,Country,is_active
),
 Sin_repetidos_mixtos as (
      SELECT `id`,`Advertiser_id,Username_id`,`Valid_From`,`Product`,`Channel_id`,`Deal_id`
            ,`Country`,1,`Code`,`Creation_Date`,`Last_Update`,`Operator` 
      FROM Sin_repetidos_activos_inactivos
      GROUP BY Advertiser_id,Username_id,`Deal_id`,Valid_From,Product,Country
)
SELECT * FROM Sin_repetidos_mixtos ORDER BY id
;

-- Regeneración tabla original
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE `campaign_deal_gestor_prod_date`;
INSERT INTO campaign_deal_gestor_prod_date SELECT * FROM campaign_deal_gestor_prod_date_depurada D WHERE D.id>0
;
   
   
SELECT *
FROM (
    (SELECT * FROM tabla1) AS t1
    LEFT JOIN (SELECT * FROM tabla2) AS t2
    ON t1.campo1 = t2.campo1 AND t1.campo2 = t2.campo2 AND t1.campo3 = t2.campo3
) AS t
WHERE t2.campo1 IS NULL OR t2.campo2 IS NULL OR t2.campo3 IS NULL;

-- SELECT *
-- FROM (
    SELECT * FROM campaign_deal_gestor_prod_date AS t1
    LEFT JOIN campaign_deal_gestor_prod_date_20240303 AS t2
    ON t1.id = t2.id AND t1.is_active != t2.is_active -- AND t1.campo3 = t2.campo3
WHERE t2.id IS not NULL -- OR t2.is_active IS NULL -- OR t2.campo3 IS NULL;
;