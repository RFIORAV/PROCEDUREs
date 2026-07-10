/*
A continuación se presenta un ejemplo de cómo podría implementarse el diseño de tablas (usando CREATE TABLE IF NOT EXISTS para MySQL 8), junto 
con los campos solicitados y los objetos necesarios (triggers, procedimientos y evento programado) que cubren la lógica descrita.
*/
-- 1. Creación de tablas
-- 1.1 Tabla campaign_advertiser_ads_v2
-- Esta tabla almacena los anuncios/landing pages (Ads/LP) disponibles.

CREATE TABLE IF NOT EXISTS campaign_advertiser_ads_v2 (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  
  Ads_Code      VARCHAR(50)   NOT NULL,  -- Código del anuncio
  Product       VARCHAR(50)   NOT NULL,  -- 'sport', 'casino', etc.
  Brand         VARCHAR(100)  NOT NULL,  -- Nombre de la marca (advertiser), derivada de 'Account' 
  Account_id    INT           NOT NULL,  -- Identificador de cuenta
  Country       VARCHAR(50)   NULL,      -- País al cual se aplica; NULL = para todos
  Title         VARCHAR(255)  NOT NULL,  -- Título resumido del Ad
  Description   TEXT          NOT NULL,  -- Descripción detallada del Ad
  Valid_From    DATE          NOT NULL,  -- Fecha desde la cual aplica
  Valid_To      DATE          NULL,      -- Fecha hasta la cual aplica; NULL = permanente

  -- Campos de control/ auditoría
  Creation_Date DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  Last_Update   DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  User          INT NULL DEFAULT NULL,

  PRIMARY KEY (id)
);

-- 1.2 Tabla campaign_advertiser_ads_applied_v2
-- Esta tabla registra qué Anuncio/Landing Page se ha asignado a qué MS (Marketing Source) y su estado.

CREATE TABLE IF NOT EXISTS campaign_advertiser_ads_applied_v2 (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,

  ad_id       INT UNSIGNED NOT NULL,  -- FK que referencia a 'campaign_advertiser_ads_v2(id)'
  Status_id   TINYINT       NOT NULL, -- 1=Activo, 0=Obsoleto (o inactivo)
  ms_id       INT UNSIGNED  NOT NULL, -- FK que referencia a la tabla de Marketing Source
  Product     VARCHAR(50)   NOT NULL, -- Copia de 'Product' para control
  Account_id  INT           NOT NULL, -- Copia de 'Account_id' para control
  Tracklink_new VARCHAR(500) NOT NULL,-- URL con el [Ads_Code]
  Valid_From  DATE          NOT NULL,
  Valid_To    DATE          NULL,

  -- Campos de control / auditoría
  Creation_Date DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  Last_Update   DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  User          INT NULL DEFAULT NULL,

  PRIMARY KEY (id),
  KEY fk_ad_id (ad_id),
  CONSTRAINT fk_ad_id 
    FOREIGN KEY (ad_id) 
    REFERENCES campaign_advertiser_ads_v2(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

-- 1.3 Tabla (ejemplo) campaign_mkt_source_url
-- No se proporcionan todos los detalles en la descripción, pero suele ser la tabla donde se asocia un MS con su URL actual. Se muestra un diseño 
-- de ejemplo para ilustrar cómo relacionarla en los triggers:

CREATE TABLE IF NOT EXISTS campaign_mkt_source_url (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,

  ms_id      INT UNSIGNED  NOT NULL,  -- FK hacia la tabla de marketing source
  Tracklink  VARCHAR(500) NOT NULL,   -- URL en uso actualmente para la MS
  
  -- Campos de control / auditoría
  Creation_Date DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  Last_Update   DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  User          INT NULL DEFAULT NULL,

  PRIMARY KEY (id)
  -- Podría ponerse foreign key a campaign_marketing_source si corresponde
);

-- Nota: La tabla campaign_marketing_source no se define aquí porque no está completamente descrita; se asume que ya existe y contiene, entre 
-- otros campos, id, Product, Account_id, Tracklink, Status_id, etc.

-- 2. Triggers
-- 2.1 Trigger en campaign_advertiser_ads_v2 (AFTER UPDATE)
-- Requisito: Cuando se actualice cualquier campo (excepto Country, Title, Description) se deben reflejar esos cambios en 
-- campaign_advertiser_ads_applied_v2.

DELIMITER $$
CREATE TRIGGER trg_campaign_advertiser_ads_v2_upd
AFTER UPDATE
ON campaign_advertiser_ads_v2
FOR EACH ROW
BEGIN
  -- Verificamos si alguno de los campos relevantes cambió
  IF (   OLD.Ads_Code    <> NEW.Ads_Code
      OR OLD.Product    <> NEW.Product
      OR OLD.Brand      <> NEW.Brand
      OR OLD.Account_id <> NEW.Account_id
      OR OLD.Valid_From <> NEW.Valid_From
      OR OLD.Valid_To   <> NEW.Valid_To
     ) THEN

    -- Ajustamos todos los registros en 'campaign_advertiser_ads_applied_v2' que correspondan a este ad
    UPDATE campaign_advertiser_ads_applied_v2
       SET Product       = NEW.Product,
           Account_id    = NEW.Account_id,
           Valid_From    = NEW.Valid_From,
           Valid_To      = NEW.Valid_To,
           -- Opcional: si el Ads_Code forma parte de la Tracklink, hacer un REPLACE
           Tracklink_new = REPLACE(Tracklink_new, OLD.Ads_Code, NEW.Ads_Code)
     WHERE ad_id = NEW.id;
  END IF;
END $$
DELIMITER ;

-- En el ejemplo de arriba se usa REPLACE para actualizar el Ads_Code en la URL (Tracklink_new). Dependiendo de la estructura real de la URL, podr
-- ía requerirse una concatenación diferente.
-- 2.2 Trigger en campaign_advertiser_ads_applied_v2 (AFTER INSERT / UPDATE)
-- Requisito: Cada vez que se inserte o modifique un registro en campaign_advertiser_ads_applied_v2, se deberá modificar la tabla 
-- campaign_mkt_source_url para reflejar la nueva URL (proceso habitual de sincronización con rebrandly/affly).


DELIMITER $$
CREATE TRIGGER trg_campaign_advertiser_ads_applied_v2_insup
AFTER INSERT OR UPDATE
ON campaign_advertiser_ads_applied_v2
FOR EACH ROW
BEGIN
  -- Si está activo (Status_id=1), actualizamos la URL en 'campaign_mkt_source_url'
  IF NEW.Status_id = 1 THEN
    -- Ejemplo: suponiendo que el registro de campaign_mkt_source_url está vinculado por ms_id
    UPDATE campaign_mkt_source_url
       SET Tracklink = NEW.Tracklink_new
     WHERE ms_id = NEW.ms_id;
  END IF;

  -- Si se desactiva (Status_id=0), podría revertirse la URL o dejarse en blanco.
  -- Esto dependerá de la lógica de negocio. Ejemplo (opcional):
  IF NEW.Status_id = 0 THEN
    -- Podríamos limpiar la URL, revertir a una genérica, etc.
    -- UPDATE campaign_mkt_source_url
    --    SET Tracklink = 'URL_por_defecto'
    --  WHERE ms_id = NEW.ms_id;
  END IF;
END $$
DELIMITER ;


-- 3. Stored Procedures (ejemplos)
-- 3.1 Aff_report_Ads_available
-- Requisito: Mostrar un grid con los registros de campaign_advertiser_ads_v2 que cumplan las condiciones:
-- Coincidan con la MS del afiliado en Product y Account_id.
-- MS tenga Status_id en (1, 6).
-- La Tracklink sea directa (no rebrandly/affly).
-- Valid_From ≤ CURDATE().
-- Valid_To > CURDATE() o sea NULL.
-- Para filtrar por MS del afiliado, asumimos que en la tabla campaign_marketing_source hay algún campo affiliate_id o similar. A modo de ejemplo:


DELIMITER $$
CREATE PROCEDURE Aff_report_Ads_available (
  IN p_affiliate_id INT
)
BEGIN
  /*
    Muestra los Ads que son válidos hoy y que coinciden 
    con las MS pertenecientes al afiliado.
  */
  SELECT a.*
    FROM campaign_advertiser_ads_v2 a
    JOIN campaign_marketing_source ms
      ON ms.Product    = a.Product
     AND ms.Account_id = a.Account_id
    -- Ejemplo de cómo distinguir Tracklink "directo":
    WHERE ms.affiliate_id = p_affiliate_id
      AND ms.Status_id IN (1,6)
      AND ms.Tracklink NOT LIKE '%rebrand.ly%'
      AND ms.Tracklink NOT LIKE '%affly%'
      AND a.Valid_From <= CURDATE()
      AND (a.Valid_To > CURDATE() OR a.Valid_To IS NULL);
END $$
DELIMITER ;

-- 3.2 Consulta de MS compatibles que aún no tienen el Ad asignado
-- Requisito: Al seleccionar un Ad, ver las MS que sean compatibles (mismo Product y Account_id, etc.) y que no tengan un Status_id activo (1) 
-- para ese Ad.

DELIMITER $$
CREATE PROCEDURE Aff_report_MS_not_assigned (
  IN p_affiliate_id INT,
  IN p_ad_id INT
)
BEGIN
  SELECT ms.id AS ms_id, ms.Product, ms.Account_id, ms.Tracklink
    FROM campaign_marketing_source ms
    JOIN campaign_advertiser_ads_v2 a ON a.id = p_ad_id
                                     AND a.Product    = ms.Product
                                     AND a.Account_id = ms.Account_id
    WHERE ms.affiliate_id = p_affiliate_id
      -- Filtro para MS que no tengan asignado este Ad con Status=1
      AND NOT EXISTS (
            SELECT 1 
              FROM campaign_advertiser_ads_applied_v2 caa
             WHERE caa.ad_id = p_ad_id
               AND caa.ms_id = ms.id
               AND caa.Status_id = 1
           );
END $$
DELIMITER ;

-- 3.3 Asignar un Ad a una MS (ejemplo de inserción)
-- Cuando el usuario selecciona un Ad y una o varias MS, se insertan los registros en campaign_advertiser_ads_applied_v2. Ejemplo de un procedure 
-- que inserta un solo registro (se puede adaptar para lotes):

DELIMITER $$
CREATE PROCEDURE Aff_assign_Ad_to_MS (
  IN p_ad_id INT,
  IN p_ms_id INT,
  IN p_tracklink_new VARCHAR(500),
  IN p_valid_from DATE,
  IN p_valid_to DATE,
  IN p_status_id TINYINT
)
BEGIN
  INSERT INTO campaign_advertiser_ads_applied_v2
    (ad_id, Status_id, ms_id, Product, Account_id, Tracklink_new, Valid_From, Valid_To)
  SELECT a.id,
         p_status_id,
         ms.id,
         ms.Product,
         ms.Account_id,
         p_tracklink_new,
         p_valid_from,
         p_valid_to
    FROM campaign_advertiser_ads_v2 a
    JOIN campaign_marketing_source ms ON ms.id = p_ms_id
    WHERE a.id = p_ad_id;
END $$
DELIMITER ;


-- 4. Evento programado (cada 30 minutos)
-- Requisito: Cada media hora, poner Status_id=0 en campaign_advertiser_ads_applied_v2 a todos aquellos registros cuyo Valid_To ya haya caducado. 
-- Esto disparará el trigger que actualiza la tabla campaign_mkt_source_url.

CREATE EVENT IF NOT EXISTS evt_expire_campaign_advertiser_ads
ON SCHEDULE EVERY 30 MINUTE
STARTS '2023-01-01 00:00:00'
DO
BEGIN
  UPDATE campaign_advertiser_ads_applied_v2
     SET Status_id = 0
   WHERE Status_id = 1
     AND Valid_To IS NOT NULL
     AND Valid_To < CURRENT_DATE();
END;

-- Ajustar fecha de STARTS según corresponda o simplemente omitirla si se quiere iniciar al momento de la creación.

-- Notas finales
-- Campos de auditoría: Siguen el formato solicitado:

-- id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
-- Creation_Date DATETIME NULL DEFAULT CURRENT_TIMESTAMP
-- Last_Update DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
-- User INT NULL DEFAULT NULL

-- Restricciones adicionales (FKs, índices, etc.): Dependiendo de la base de datos existente, se pueden agregar llaves foráneas a 
-- campaign_marketing_source u otras tablas relacionadas, para reforzar la integridad referencial.

-- Lógica de actualización de la URL: En el ejemplo se utilizó REPLACE(Tracklink_new, OLD.Ads_Code, NEW.Ads_Code). Ajustar según la forma exacta 
-- en que se construye la URL o si se requiere otra lógica.

-- Valid_To y el evento programado**: El ejemplo asigna Status_id=0 cuando Valid_To < CURRENT_DATE(). Se podría usar NOW() en vez de CURRENT_DATE
-- () si se desea mayor precisión temporal.

-- Con esto se cubren las estructuras de tablas, los triggers, procedimientos y el evento que cumplen con los requisitos descritos.

