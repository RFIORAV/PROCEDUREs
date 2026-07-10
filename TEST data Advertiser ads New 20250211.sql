CREATE TABLE IF NOT EXISTS campaign_advertiser_ads_v2 (
    id INT NOT NULL AUTO_INCREMENT,
    Ads_Code VARCHAR(50) NOT NULL,                      -- Código del anuncio (Obligatorio)
    Product VARCHAR(50) NOT NULL,                         -- Producto básico de la MS (por ejemplo, sport o casino)
    Advertiser_Name VARCHAR(100) NULL,                    -- Derivado del Account/Brand
    Account_id INT NOT NULL,                              -- Account (Obligatorio)
    Country VARCHAR(2) NULL,                              -- País; NULL indica que aplica para TODOS
    Title VARCHAR(300) NOT NULL,                          -- Título resumido del Ad (Obligatorio)
    Description TEXT NOT NULL,                            -- Descripción detallada (Obligatorio)
    Valid_From DATE NOT NULL,                             -- Fecha de inicio de vigencia (Obligatorio)
    Valid_To DATE NULL,                                   -- Fecha de finalización; NULL indica PERMANENTE
    Creation_Date DATETIME NOT NULL DEFAULT NOW(),
    Last_Update DATETIME NOT NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;
/*
CREATE TABLE IF NOT EXISTS campaign_marketing_source (
    id INT NOT NULL AUTO_INCREMENT,
    Tracklink VARCHAR(250) NOT NULL,   -- URL de la Landing Page (TRACKLINK)
    Product VARCHAR(50) NOT NULL,        -- Producto de la MS (para emparejar con Ads.Product)
    Account_id INT NOT NULL,             -- Account/Brand asociado (para emparejar con Ads.Account_id)
    Status_id INT NOT NULL,              -- Estado de la MS (por ejemplo, 1 o 6 son los válidos)
    Affiliate_id INT NOT NULL,           -- Afiliado al que pertenece la MS
    Creation_Date DATETIME NOT NULL DEFAULT NOW(),
    Last_Update DATETIME NOT NULL DEFAULT NOW() ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;
*/

SET @affiliate_id=490;

SELECT 
    ads.id,
    ads.Ads_Code,
    ads.Product,
    ads.Advertiser_Name,
    ads.Account_id,
    ads.Country,
    ads.Title,
    ads.Description,
    ads.Valid_From,
    ads.Valid_To,
    ms.Tracklink
    ,ms.Affiliate_id
FROM campaign_advertiser_ads_v2 AS ads
JOIN campaign_marketing_source AS ms
  ON ads.Product    = ms.Product
 AND ads.Account_id = ms.username_id
WHERE ms.Affiliate_id = @affiliate_id            -- parámetro del afiliado
  -- AND ms.Status_id IN (1, 6)
  AND ms.Tracklink NOT LIKE '%rebrand.ly%'
  AND ms.Tracklink NOT LIKE '%affly%'
  AND ads.Valid_From <= CURDATE()
  AND (ads.Valid_To > CURDATE() OR ads.Valid_To IS NULL);


-- ---------------------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE Aff_report_Ads_available (IN p_affiliate_id INT)
BEGIN
    SELECT 
        ads.id,
        ads.Ads_Code,
        ads.Product,
        ads.Advertiser_Name,
        ads.Account_id,
        ads.Country,
        ads.Title,
        ads.Description,
        ads.Valid_From,
        ads.Valid_To,
        ms.Tracklink
    FROM campaign_advertiser_ads_v2 AS ads
    JOIN campaign_marketing_source AS ms
      ON ads.Product    = ms.Product
     AND ads.Account_id = ms.Account_id
    WHERE ms.Affiliate_id = p_affiliate_id
      AND ms.Status_id IN (1, 6)
      AND ms.Tracklink NOT LIKE '%rebrand.ly%'
      AND ms.Tracklink NOT LIKE '%affly%'
      AND ads.Valid_From <= CURDATE()
      AND (ads.Valid_To > CURDATE() OR ads.Valid_To IS NULL);
END //

DELIMITER ;
