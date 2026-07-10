/* FUNCTION_getCurrencyConversion_v1.sql - Convertir importe moneda origen en moneda destino

   Parámetros de invocación:
      - originValue Valor origen
      - originSymbol: Moneda origen
      - destSymbol: Moneda destino
      
Ej: getCurrencyConversion(10000, 'EUR', 'USD')

Test: SELECT getCurrencyConversion(10000, 'EUR', 'USD');      

31.07.2024  v1    Primera versión (copilot)
02.12.2025  v1.1  Evita lectura de tabla cuando originSymbol = destSymbol 
  
**/

DROP FUNCTION IF EXISTS getCurrencyConversion;
 
DELIMITER $$

CREATE FUNCTION getCurrencyConversion(
                  originValue    DECIMAL(20,2),
                  originSymbol   VARCHAR(150),
                  destSymbol     VARCHAR(150)) 
                  RETURNS DECIMAL(20,2)
   COMMENT 'Convertir moneda origen en moneda destino'
   LANGUAGE SQL
--    NOT DETERMINISTIC
   READS SQL DATA

BEGIN
    DECLARE Version     varchar(30) DEFAULT 'v1.1 02.12.2025';
    DECLARE originRate  DECIMAL(20,10) DEFAULT 1;
    DECLARE destRate    DECIMAL(20,10) DEFAULT 1;

	 IF originSymbol!=destSymbol THEN
       -- Get the rates for the origin and destination currencies
	 	 SELECT IFNULL(`Rate`,1) INTO originRate  FROM `exchange_rate` WHERE `Currency` = TRIM(LEFT(originSymbol,3));
	 	 SELECT IFNULL(`Rate`,1) INTO destRate    FROM `exchange_rate` WHERE `Currency` = TRIM(LEFT(destSymbol,3));
	 END IF;    

    -- Calculate the conversion factor
    RETURN originValue * destRate / originRate;
END $$

/*
SELECT getCurrencyConversion(10000, 'EUR', 'USD');
SELECT getCurrencyConversion(10000, 'EUR', 'BRL')*4;
SELECT getCurrencyConversion(10000, 'brl', 'usd');
SELECT getCurrencyConversion(10000, 'ar', 'usd');
*/