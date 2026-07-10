/*
PROCEDURE_UTIL_Sync_bot_files_allDB_v1.sql-  CREA todos las tablas de bots en TODAS las DB

Descripción:
  Procedimiento UTIL_Sync_bot_files_allDB.

Keys:

06.03.2025 v1

*/

DROP PROCEDURE IF EXISTS UTIL_Sync_bot_files_allDB;

/*  Claude 3.7  
Por favor, escribe un stored procedure mysql8 que haga lo siguiente:
- Dermine en qué DB hay tablas cuyo nombre comienza con "gambl" o con "play", por ejemplo con este query

      SELECT TABLE_SCHEMA,TABLE_NAME
      FROM  `information_schema`.`TABLES`
      WHERE
         `TABLE_NAME` LIKE 'gambling%'
         OR `TABLE_NAME` LIKE 'players%'
         OR `TABLE_NAME` LIKE 'API%'
      GROUP BY TABLE_NAME;

- De la lista obtenida en el punto anterior crea las tablas (usando CREATE LIKE) que faltan en cada una de las DB 
de modo que al final todas las DB de la lista tengan las mismas tablas cuyo nombre comienza con "gambl" o con "play"
*/

-- -------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE UTIL_Sync_bot_files_allDB()
COMMENT 'Procedimiento UTIL_Sync_bot_files_allDB.'

BEGIN
   DECLARE done INT DEFAULT FALSE;
   DECLARE tableName VARCHAR(250);
   DECLARE DbName VARCHAR(250);
   
   -- Cursor para TABLE_SCHEMA,TABLE_NAME de tablas que existen que pueden no estar en todas
   DECLARE table_cursor CURSOR FOR
      SELECT TABLE_SCHEMA,TABLE_NAME
      FROM  `information_schema`.`TABLES`
      WHERE `TABLE_NAME` LIKE 'gambling%' OR `TABLE_NAME` LIKE 'players%' OR `TABLE_NAME` LIKE 'API_%'
      GROUP BY TABLE_NAME;
   /*      
      TABLE_SCHEMA         ; TABLE_NAME
      -- ------------------------------------------------------
      affiliabuzz          ; gambling_day_by_day_referon
      affiliabuzz          ; players_netrefer
      affiliaterevolution  ; gambling_day_by_day_888
      affiliaterevolution  ; gambling_day_by_day_betway
      affiliaterevolution  ; gambling_day_by_day_betway_scraper
      affiliaterevolution  ; gambling_day_by_day_buffalo
      affiliaterevolution  ; gambling_day_by_day_cristaltec
      affiliaterevolution  ; gambling_day_by_day_instantcasino
      deally               ; gambling_day_by_day_admiralbet
      deally               ; gambling_day_by_day_fantasyteam
      deally               ; gambling_day_by_day_newgioco
      euroaffiliati2       ; gambling_day_by_day_betsson
      euroaffiliati2       ; gambling_day_by_day_cellxpert
      euroaffiliati2       ; gambling_day_by_day_netbet
      euroaffiliati2       ; gambling_day_by_day_netrefer
      euroaffiliati2       ; gambling_day_by_day_roosterpartners
      euroaffiliati2       ; gambling_day_by_day_smart4ads
      euroaffiliati_dev    ; API_NetRefer
      marca_blanca         ; gambling_day_by_day_betpartners
   */

   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN table_cursor;

   readTable_loop: LOOP
      FETCH table_cursor INTO DbName,tableName;
      IF done THEN
         LEAVE readTable_loop;
      END IF;
      
      SET @tableLIKE = CONCAT(DbName,".",tableName);
      SET @DbName =DbName;
      SET @Table  =tableName;
      
      VER_Tablas: BEGIN
         DECLARE done1 INT DEFAULT FALSE;
         DECLARE eachDbName VARCHAR(250);         
         -- Cursor para TABLE_SCHEMA, DB tienen al menos una tabla que coincide con el patrón
         DECLARE db_cursor CURSOR FOR
            SELECT DISTINCT TABLE_SCHEMA
            FROM information_schema.TABLES
            WHERE `TABLE_NAME` LIKE 'gambling%' OR `TABLE_NAME` LIKE 'players%' OR `TABLE_NAME` LIKE 'API_%'
            GROUP BY TABLE_SCHEMA;
            /*      
               deally
               euroaffiliati2
               affiliaterevolution
               marca_blanca
               brasiliacon
               affiliabuzz
               euroaffiliati_dev
               fivestars         
            */   
         DECLARE CONTINUE HANDLER FOR NOT FOUND SET done1 = TRUE;
         OPEN db_cursor;        
         readDb_loop: LOOP
            FETCH db_cursor INTO eachDbName;
            IF done1 THEN
               LEAVE readDb_loop;
            END IF;
            
            SET @tableToCreate = CONCAT(eachDbName,".",@Table);
            SET @eachDbName =eachDbName;
            SET @createTableQuery = CONCAT('CREATE TABLE IF NOT EXISTS ',@tableToCreate,' LIKE ',@tableLIKE,';');

            IF eachDbName!=@DbName -- AND eachDbName="euroaffiliati2"
            THEN
               -- SELECT @Table,@tableToCreate,@tableLIKE,@createTableQuery;
               PREPARE stmt FROM @createTableQuery;
               EXECUTE stmt;
               DEALLOCATE PREPARE stmt;
            END IF;
            
         END LOOP;
         CLOSE db_cursor;
         
      END;
         
    END LOOP;

    CLOSE table_cursor;   
  
END //

DELIMITER ;

/*
call UTIL_Sync_bot_files_allDB;
*/