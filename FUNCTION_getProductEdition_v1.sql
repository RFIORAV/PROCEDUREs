/*
FUNCTION_getProductEdition_v1.sql

Descripción:
  Devuelve la edición de producto configurada en util_settings (Setting='ProductEdition').
  Si no hay valor, retorna 'network'. El resultado se normaliza a minúsculas.

Parámetros:
  (ninguno)

Ejemplos:
  SELECT getProductEdition();
  SELECT getProductEdition() AS ProductEdition;

24.07.2026 v1 Karen. Primera versión operativa
*/

DROP FUNCTION IF EXISTS getProductEdition;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` FUNCTION `getProductEdition`() RETURNS VARCHAR(50)
   COMMENT 'v1 24.07.2026 - Devuelve ProductEdition desde util_settings (default network)'
   LANGUAGE SQL
   READS SQL DATA
   SQL SECURITY DEFINER
BEGIN
    DECLARE v_Version        VARCHAR(32) DEFAULT 'v1 24.07.2026';
    DECLARE v_ProductEdition VARCHAR(50) DEFAULT NULL;

    SELECT IFNULL(Value_01, 'Network') INTO v_ProductEdition
    FROM util_settings
    WHERE Setting = 'ProductEdition';

    RETURN LOWER(v_ProductEdition);
END$$

DELIMITER ;
