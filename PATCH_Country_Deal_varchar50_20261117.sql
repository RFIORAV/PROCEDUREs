/*
PATCH 17.11.2026 — Country_Deal VARCHAR(2) → VARCHAR(50)

Listas ISO2 separadas por coma (IT,ES,DE o AR,MX,PA).

Uso exclusivo de Country / Country_Deal:
  compliance de landings de afiliados (mostrar ofertas según IP)
  y protección Zero-Waste CPA en affly.eu.
No interviene en la liquidación de comisiones
(Snapshot_day_by_day_fact1_upd_from_dbd v3.9.5).

Regla de negocio:
  la MS hereda los países de su Account cuando Country_Deal va vacío.
  En la MS solo se guarda una excepción puntual.
  Lista efectiva:
    IF(TRIM(IFNULL(MS.Country_Deal,''))='',
       TRIM(IFNULL(CU.Country_Deal,'')),
       TRIM(MS.Country_Deal,''))

Columnas:
  campaign_username.Country_Deal
  campaign_username_history.Country_Deal
  campaign_marketing_source.Country_Deal
  campaign_marketing_source_history.Country_Deal
  campaign_deal_gestor_prod_date.Country
  campaign_mkt_source_deal.Country
    Las dos últimas las rellenan los triggers al copiar Country_Deal.
    Sin ampliarlas, una lista multi-país falla o se trunca en modo estricto.

Ejecutar una vez en cada base. Idempotente: omite columnas que ya miden 50 o más.
MySQL 8.0.37+. Conserva NULL, DEFAULT, charset y collation de cada columna.
*/

DROP PROCEDURE IF EXISTS _patch_widen_country_deal;
DELIMITER $$
CREATE PROCEDURE _patch_widen_country_deal()
BEGIN
   DECLARE v_done INT DEFAULT 0;
   DECLARE v_sql TEXT;
   DECLARE cur CURSOR FOR
      SELECT CONCAT(
         'ALTER TABLE `', C.TABLE_NAME, '` MODIFY COLUMN `', C.COLUMN_NAME, '` VARCHAR(50) ',
         IF(C.IS_NULLABLE = 'NO', 'NOT NULL ', 'NULL '),
         CASE
            WHEN C.COLUMN_DEFAULT IS NULL AND C.IS_NULLABLE = 'YES' THEN 'DEFAULT NULL '
            WHEN C.COLUMN_DEFAULT IS NULL THEN ''
            ELSE CONCAT('DEFAULT ', QUOTE(C.COLUMN_DEFAULT), ' ')
         END,
         -- IF(C.CHARACTER_SET_NAME IS NULL, '', CONCAT('CHARACTER SET ', C.CHARACTER_SET_NAME, ' ')),
         -- IF(C.COLLATION_NAME IS NULL, '', CONCAT('COLLATE ', C.COLLATION_NAME, ' ')),
         'COMMENT ', QUOTE(
            CASE
               WHEN C.TABLE_NAME = 'campaign_username' AND C.COLUMN_NAME = 'Country_Deal'
                  THEN 'Paises ISO2 separados por coma. Solo compliance de landings y Zero-Waste CPA. La MS vacia hereda esta lista.'
               WHEN C.TABLE_NAME = 'campaign_marketing_source' AND C.COLUMN_NAME = 'Country_Deal'
                  THEN 'Excepcion de paises ISO2 separados por coma. Vacio = hereda Country_Deal de la Account. Solo compliance y Zero-Waste.'
               WHEN C.COLUMN_NAME = 'Country'
                  THEN 'Copia de Country_Deal (lista ISO2). No condiciona la liquidacion de comisiones.'
               ELSE 'Historico de lista ISO2. No condiciona la liquidacion de comisiones.'
            END
         )
      )
      FROM information_schema.COLUMNS C
      WHERE C.TABLE_SCHEMA = DATABASE()
        AND (
              (C.TABLE_NAME IN (
                  'campaign_username',
                  'campaign_username_history',
                  'campaign_marketing_source',
                  'campaign_marketing_source_history'
               ) AND C.COLUMN_NAME = 'Country_Deal')
           OR (C.TABLE_NAME IN (
                  'campaign_deal_gestor_prod_date',
                  'campaign_mkt_source_deal'
               ) AND C.COLUMN_NAME = 'Country')
        )
        AND C.CHARACTER_MAXIMUM_LENGTH < 50;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

   OPEN cur;
   read_loop: LOOP
      FETCH cur INTO v_sql;
      IF v_done = 1 THEN
         LEAVE read_loop;
      END IF;
      SET @patch_sql = v_sql;
      PREPARE stmt FROM @patch_sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
   END LOOP;
   CLOSE cur;
END$$
DELIMITER ;

CALL _patch_widen_country_deal();
DROP PROCEDURE IF EXISTS _patch_widen_country_deal;
