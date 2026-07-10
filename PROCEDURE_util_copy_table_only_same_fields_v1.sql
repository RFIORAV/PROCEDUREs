/* PROCEDURE util_copy_table_only_same_fields


Descripción:
  Procedimiento util_copy_table_only_same_fields.
Features:

Keys:
 source_table = [valor]. Parámetro de entrada.
 target_table = [valor]. Parámetro de entrada.

✔ Dynamic Column Matching: Copies only fields present in both tables.
✔ No Manual Column Mapping: Saves time and avoids errors in column listing.
✔ Adaptable to Schema Changes: Automatically adjusts when tables are altered.

 Benefits:

    Ensures NULL values do not cause errors in non-nullable target fields.
    Automatically detects column types and applies appropriate defaults.
    Works dynamically without requiring manual column mapping.

How It Works

    Matches columns in source_table and target_table by name.
    Checks if the destination field (target table) is non-nullable:
        If numeric, replaces NULL values with 0.
        If string-based, replaces NULL values with '' (empty string).
    Dynamically constructs the INSERT ... SELECT statement, using COALESCE(field, default_value).
    Executes the statement dynamically.

How to Use:
    
CALL util_copy_table_only_same_fields('source_table', 'target_table');

29.01.2025 v1  ChatGPT

*/

DROP PROCEDURE IF EXISTS util_copy_table_only_same_fields;

DELIMITER $$

CREATE PROCEDURE util_copy_table_only_same_fields(
    IN source_table VARCHAR(64),
    IN target_table VARCHAR(64)
)
COMMENT 'Copia una tabla a otra usando los campos que se llaman igual en ambas'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v1 29.01.2025';
SET @sql_stmt     = '';
    
-- Construct dynamic SQL for inserting only matching columns
SELECT 
    CONCAT(
       'INSERT INTO ', target_table, ' (',
       GROUP_CONCAT(column_name ORDER BY ordinal_position SEPARATOR ', '),
       ') SELECT ',
       GROUP_CONCAT(
          CASE 
             WHEN is_nullable = 'NO' THEN 
                CONCAT(
                   'COALESCE(', column_name, 
                   ', ', 
                   CASE 
                       WHEN data_type IN ('char', 'varchar', 'text', 'tinytext', 'mediumtext', 'longtext') 
                       THEN "''" 
                       ELSE '0' 
                   END, 
                   ')'
                )
             ELSE column_name 
          END
          ORDER BY ordinal_position SEPARATOR ', '
       ),
       ' FROM ', source_table, ';'
) INTO @sql_stmt
FROM (
   SELECT c.COLUMN_NAME, c.ORDINAL_POSITION, t.IS_NULLABLE, c.DATA_TYPE
   FROM INFORMATION_SCHEMA.COLUMNS c
   JOIN INFORMATION_SCHEMA.COLUMNS t 
       ON  c.COLUMN_NAME = t.COLUMN_NAME 
       AND t.TABLE_SCHEMA = DATABASE() 
       AND t.TABLE_NAME = target_table
   WHERE c.TABLE_SCHEMA = DATABASE() 
     AND c.TABLE_NAME = source_table
) matched_columns;

SELECT source_table,target_table,@sql_stmt;

 -- Prepare, execute, and clean up dynamic SQL
 IF @sql_stmt IS NOT NULL THEN
     PREPARE stmt FROM @sql_stmt;
     EXECUTE stmt;
     DEALLOCATE PREPARE stmt;
 END IF;
    
END$$

DELIMITER ;

/* Test

CALL util_copy_table_only_same_fields('monthly_comms_affiliate_v5', 'monthly_comms_affiliate');

*/
