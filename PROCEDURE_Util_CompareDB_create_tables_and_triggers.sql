/* COMPARA UNA DB DE CONTRA euroaffiliati2
      GENERA CREATE TABLES FALTANTES

Descripción:
  Procedimiento PROCEDURE_Util_CompareDB_create_tables_and_triggers.
      GENERA TRIGGERS FALTANTES
   20.03.2024

Keys:

--     E J E C U T A R     I N T E R A C T I V A M E N T E 

*/

-- SHOW TRIGGERS;

-- Define los nombres de las bases de datos
SET @firstDatabaseName = 'euroaffiliati2';
SET @secondDatabaseName = DATABASE();

-- Encuentra las tablas que existen en la primera base de datos pero no en la segunda
SELECT CONCAT('CREATE TABLE ', cl.TABLE_NAME, ' LIKE ', @firstDatabaseName, '.', cl.TABLE_NAME, ';') AS createMissingTables
FROM information_schema.TABLES cl
WHERE cl.TABLE_SCHEMA = @firstDatabaseName
--    AND left(cl.TABLE_NAME,6) IN ("accoun","campai","master","super_")
   AND cl.TABLE_NAME NOT LIKE '%202%'
   AND cl.TABLE_NAME NOT LIKE '%copy%'
   AND cl.TABLE_NAME NOT LIKE '%temp%'
   AND cl.TABLE_NAME NOT LIKE '%old'
   AND cl.TABLE_NAME NOT LIKE 'django%'   
AND cl.TABLE_NAME NOT IN (
    SELECT TABLE_NAME
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = @secondDatabaseName
);

-- Encuentra los triggers que existen en la primera base de datos pero no en la segunda
SELECT CONCAT_WS(' '
   ,'DROP TRIGGER IF EXISTS'
   ,tr.TRIGGER_NAME
   ,';\n'
   ,'DELIMITER $$\n'
   ,'CREATE DEFINER=`b3w1nn3r`@`%` TRIGGER'
   ,tr.TRIGGER_NAME
   ,'\n'
   ,tr.ACTION_TIMING
   ,tr.EVENT_MANIPULATION
   ,'ON'
   ,tr.EVENT_OBJECT_TABLE
   ,'FOR EACH'
   ,tr.ACTION_ORIENTATION
   ,'\n'
   ,tr.ACTION_STATEMENT
   ,'\n$$\nDELIMITER ;') AS createMissingTriggers
FROM information_schema.TRIGGERS tr
WHERE tr.TRIGGER_SCHEMA = @firstDatabaseName
AND tr.TRIGGER_NAME NOT IN (
    SELECT tr1.TRIGGER_NAME
    FROM information_schema.TRIGGERS tr1
    WHERE tr1.TRIGGER_SCHEMA = @secondDatabaseName
);
