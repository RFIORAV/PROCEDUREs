/* FUNCTION_getCurrencyConversionFactor - Obtiene factor multiplicador para convertir moneda origen en moneda destino

   Parámetros de invocación:
      - originSymbol: Moneda origen
      - destSymbol: Moneda destino

Ej: getCurrencyConversionFactor('EUR', 'USD')

Test: SELECT getCurrencyConversionFactor('EUR', 'USD');

30.07.2024  v1    Primera versión (copilot)
02.12.2025  v1.1  Evita lectura de tabla cuando originSymbol = destSymbol

**/

DROP FUNCTION IF EXISTS getCurrencyConversionFactor;

DELIMITER $$

CREATE FUNCTION getCurrencyConversionFactor(originSymbol VARCHAR(50), destSymbol VARCHAR(50)) RETURNS DECIMAL(20,10)
   COMMENT 'Obtiene factor multiplicador para convertir moneda origen en moneda destino'
   LANGUAGE SQL
   -- DETERMINISTIC
   READS SQL DATA

BEGIN

    DECLARE Version     varchar(30) DEFAULT 'v1.1 02.12.2025';
    DECLARE originRate  DECIMAL(20,10) DEFAULT 1;
    DECLARE destRate    DECIMAL(20,10) DEFAULT 1;

	 IF originSymbol!=destSymbol THEN
       -- Get the rates for the origin and destination currencies
       SELECT `Rate` INTO originRate FROM `exchange_rate` WHERE `Currency` = originSymbol;
       SELECT `Rate` INTO destRate   FROM `exchange_rate` WHERE `Currency` = destSymbol;
    END IF;

    -- Calculate the conversion factor
    RETURN destRate / originRate;

END $$

/*
SELECT getCurrencyConversionFactor('EUR', 'USD');
SELECT getCurrencyConversionFactor('EUR', 'BRL')*4;
*/