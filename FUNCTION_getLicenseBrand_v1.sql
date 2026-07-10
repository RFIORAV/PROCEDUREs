/* FUNCTION_getLicenseBrand_v1.sql - Comprueba si el Brand tiene licencia para operar en el Country solicitado

   Parámetros de invocación:
      - Brand: Moneda origen
      - CountryCode: Moneda destino
      
   Devuelve 1 si tiene licencia para operar en CountryCode - 0, si no tiene
      
Ej: getLicenseBrand('bwin', 'ES');

Test: SELECT getLicenseBrand('bwin', 'IT');      

30.07.2024  v1    Primera versión
  
**/

DROP FUNCTION IF EXISTS getLicenseBrand;

DELIMITER $$

CREATE FUNCTION getLicenseBrand(Brand VARCHAR(150), CountryCode VARCHAR(20)) RETURNS INT
   COMMENT 'Comprueba si el Brand tiene licencia para operar en el Country solicitado'
   LANGUAGE SQL
--    NOT DETERMINISTIC
   READS SQL DATA

BEGIN
    DECLARE Version varchar(30) DEFAULT 'v1 30.07.2024';
    DECLARE LicenseExist INT DEFAULT 0;

    SELECT COUNT(*) INTO LicenseExist 
    FROM `campaign_advertiser_licence` L
    INNER JOIN `util_countries` C ON C.`alpha_2`=CountryCode
    WHERE `Advertiser_Name` = Brand AND `Countries` like concat('%',LEFT(CountryCode,2),'%');

    RETURN LicenseExist;
END $$

/*
SELECT getLicenseBrand('bwin', 'IT');

-- ------------------------------------------------------------------------------------
CREATE TABLE `campaign_advertiser_licence` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Advertiser_Name` VARCHAR(100) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   `Countries` VARCHAR(100) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE INDEX `Advertiser_Name` (`Advertiser_Name`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
*/