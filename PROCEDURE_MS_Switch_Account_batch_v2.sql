/*
PROCEDURE_MS_Switch_Account_batch_v2.sql

Descripción:
  Procedimiento MS_Switch_Account_batch.

Keys:
  InputCommLine = [valor]. Parámetro de entrada.

Funcionalidades principales:

Lectura de registros origen: Utiliza una tabla temporal para almacenar todos los registros donde Username_id IN (@Accounts_origen), Status_id = '1' y Product = @Product
Verificación de Qualified_Players: Solo procesa registros cuya suma de Qualified_Players en Snapshot_day_by_day_fact1 para el período @Day_from a @Day_to sea >= @CPA_Min
Actualización condicional: Para cada registro de la tabla temporal, intenta actualizar un registro que cumpla Username_id = @Account_destino, Affiliate_id = 84, Product = @Product, Stat_aggreg = 1, Channel_id = 531
Transferencia de campos: Actualiza todos los campos especificados desde el registro origen al destino

Características técnicas:

Usa una tabla temporal para almacenar los registros origen
Itera sobre la tabla temporal usando un bucle WHILE
Utiliza LIMIT 1 en el UPDATE para asegurar que solo se actualice un registro por iteración
Si no existe un registro destino que cumpla los criterios, automáticamente pasa al siguiente registro origen
Recibe parámetros como pares key=value (similar a PROCEDURE_Report_players_netrefer_v2.3.sql)

PARÁMETROS DE ENTRADA (formato key=value):

1. Day_from (VARCHAR(10)) - Descripción: Fecha inicial del período en formato YYYY-MM-DD
2. Day_to (VARCHAR(10)) - Descripción: Fecha final del período en formato YYYY-MM-DD
3. CPA_Min (INT) - Descripción: Suma mínima de Qualified_Players requerida para procesar un registro
4. Accounts_origen (VARCHAR(1000)) - Descripción: Lista de IDs de cuentas origen separados por comas. 
   ^Accounts_origen=111^86 -> Puede ser un solo valor o una lista de valores separados por comas. 
   Si es una lista, se debe usar el símbolo ^ para separar los valores. Ejemplo: ^111^86 -> Accounts_origen IN ("111","86")

5. Account_destino (INT) - Descripción: ID de la cuenta destino donde se transferirán los registros
6. Product (VARCHAR(50)) - Descripción: Tipo de producto a procesar ('casino', 'sport', etc.)
7. Debug (VARCHAR(3)) - Descripción: Modo de depuración. Si es 'NO' ejecuta las actualizaciones, en caso contrario solo muestra información

Ejemplos de uso:

CALL MS_Switch_Account_batch('Day_from=2025-11-01,Day_to=2025-11-30,CPA_Min=5,Accounts_origen=111,Account_destino=262,Product=casino,Debug=NO');
CALL MS_Switch_Account_batch('Day_from=2025-11-01,Day_to=2025-11-30,CPA_Min=5,Accounts_origen=86,Account_destino=261,Product=casino,Debug=NO');
CALL MS_Switch_Account_batch('Day_from=2025-11-01,Day_to=2025-11-30,CPA_Min=5,^Accounts_origen=36^236,Account_destino=266,Product=casino,Debug=NO');
CALL MS_Switch_Account_batch('Day_from=2025-12-01,Day_to=2025-12-31,CPA_Min=0,Accounts_origen=266,Account_destino=265,Product=casino,Debug=yes');

11.12.2025 v2.0 Primera versión con parámetros key=value y verificación de Qualified_Players
05.01.2026 v2.1 Se permite que el Product de la MS origen sea diferente al Product de la MS destino
*/

DROP PROCEDURE IF EXISTS MS_Switch_Account_batch;
-- DROP PROCEDURE IF EXISTS MS_Switch_Account_batch_v2;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `MS_Switch_Account_batch`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Switch Account Batch v2 - Transfer marketing sources between accounts'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v2.1 05.01.2026';
SET @CurrentDay      =curdate();
SET @Day_from        ='';
SET @Day_to          ='';
SET @CPA_Min         =0;
SET @Accounts_origen ='';
SET @Account_destino =0;
SET @Product         ='';
SET @Debug           ='NO';
-- Inicialización de variables de usuario
SET @v_id = NULL;
SET @v_code_to_affiliate = NULL;
SET @v_product = NULL;
SET @v_status = NULL;
SET @v_status_id = NULL;
SET @v_affiliate_id = NULL;
SET @v_channel_id = NULL;
SET @v_deal_id = NULL;
SET @v_country_deal = NULL;
SET @v_product_deal = NULL;
SET @v_deal_valid_from = NULL;
SET @v_shortlink = NULL;
SET @v_shortlink_id = NULL;
SET @v_username_id = NULL;
SET @v_qualified_players_sum = 0;

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

-- Parseo de parámetros key=value
WHILE @InputCommLine>' ' DO
   SET @e=INSTR(@InputCommLine,'=');    				   -- Posición del =
   SET @c=INSTR(@InputCommLine,','); 					   -- Posición de la coma
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Key
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- Value
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);
   -- Procesamiento de parámetros multivalor
   -- Input ex: ^Accounts_origen=111^86 -> Accounts_origen IN ("111","86")
   IF LEFT(@k,1)='^' THEN
      -- Formatear valor para cláusula IN
      SET @v=CONCAT('("',@v,'")');           
      SET @v=REPLACE(@v,'^','","');          
      -- Remover el indicador de multivalor del nombre
      SET @k=SUBSTRING(@k,2);        

   END IF;
   IF lower(@k)='day_from'        THEN SET @Day_from        =@v; END IF;
   IF lower(@k)='day_to'          THEN SET @Day_to          =@v; END IF;
   IF lower(@k)='cpa_min'         THEN SET @CPA_Min         =CAST(@v AS UNSIGNED); END IF;
   IF lower(@k)='accounts_origen' THEN SET @Accounts_origen =@v; END IF;
   IF lower(@k)='account_destino' THEN SET @Account_destino=CAST(@v AS UNSIGNED); END IF;
   IF lower(@k)='product'         THEN SET @Product         =@v; END IF;
   IF lower(@k)='debug'           THEN SET @Debug           =UPPER(@v); END IF;

END WHILE;

-- Validación de parámetros obligatorios
IF @Day_from = '' OR @Day_to = '' OR @Accounts_origen = '' OR @Account_destino = 0 OR @Product = '' THEN
    SELECT 'ERROR: Faltan parámetros obligatorios. Requeridos: Day_from, Day_to, Accounts_origen, Account_destino, Product' AS 'Error';
    LEAVE proc_label;
END IF;

-- Transformar '("36","236")' a '36,236'
SET @Accounts_origen =replace(@Accounts_origen,'"',''); -- 36,236 -> Accounts_origen IN (36,236)
SET @Accounts_origen =replace(@Accounts_origen,'(',''); -- 36,236 -> Accounts_origen IN (36,236)
SET @Accounts_origen =replace(@Accounts_origen,')',''); -- 36,236 -> Accounts_origen IN (36,236)

IF @Debug!="NO" THEN 
    SELECT @Day_from, @Day_to, @CPA_Min, @Accounts_origen, @Account_destino, @Product, @Debug AS 'Parámetros';
END IF;

-- Modo Debug: mostrar registros seleccionados
IF @Debug != "NO" THEN
    SELECT 'Registros origen que cumplen criterios' AS 'Info';
    
    SELECT 
        cms.id AS `MS_id`,
        cms.Username_id AS `Account_origen`, 
        cms.Code_To_Affiliate, 
        cms.Product, 
        cms.Status, 
        cms.Status_id, 
        cms.Affiliate_id, 
        A.username AS `Affiliate`,
        cms.Channel_id, 
        cms.Deal_id, 
        cms.Country_Deal, 
        cms.Product_Deal, 
        cms.Deal_Valid_From, 
        cms.Shortlink, 
        cms.Shortlink_id,
        SUM(COALESCE(sdbdf.Qualified_Players, 0)) AS `Qualified_Players_Sum`
    FROM campaign_marketing_source cms
    LEFT JOIN `account_account` `A` ON `A`.`id` = `cms`.`Affiliate_id`
    LEFT JOIN Snapshot_day_by_day_fact1 sdbdf ON sdbdf.MS_id = cms.id
        AND sdbdf.Date >= @Day_from
        AND sdbdf.Date <= @Day_to
    WHERE cms.Username_id IN (@Accounts_origen)
      AND cms.Status_id = '1'
    --   AND cms.Product = @Product
      AND cms.Affiliate_id != 84 
    GROUP BY 
        cms.id 
    HAVING `Qualified_Players_Sum` >= @CPA_Min;
    
    SELECT 'Registros destino disponibles' AS 'Info';
    
    SELECT 
        cms.id, 
        cms.Code_To_Affiliate, 
        cms.Product, 
        cms.Status, 
        cms.Status_id, 
        cms.Affiliate_id, 
        cms.Channel_id, 
        cms.Deal_id, 
        cms.Country_Deal, 
        cms.Product_Deal, 
        cms.Deal_Valid_From, 
        cms.Shortlink, 
        cms.Shortlink_id
    FROM campaign_marketing_source cms
    WHERE cms.Username_id = @Account_destino 
      AND cms.Affiliate_id = 84 
      AND cms.Stat_aggreg = '1'
      AND cms.Channel_id = 531
      AND cms.Product = @Product;
END IF;

-- Crear tabla temporal con los registros origen
DROP TEMPORARY TABLE IF EXISTS tmp_ms_origen;

CREATE TEMPORARY TABLE tmp_ms_origen AS
SELECT 
    cms.id, 
    cms.Code_To_Affiliate, 
    cms.Product, 
    cms.Status, 
    cms.Status_id, 
    cms.Affiliate_id, 
    cms.Channel_id, 
    cms.Deal_id, 
    cms.Country_Deal, 
    cms.Product_Deal, 
    cms.Deal_Valid_From, 
    cms.Shortlink, 
    cms.Shortlink_id,
    cms.Username_id,
    cms.CPA_Limit,
    cms.Source,
    cms.Ad_Code,
    cms.Ad_Valid_From,
    cms.Ad_Valid_To,
    SUM(COALESCE(sdbdf.Qualified_Players, 0)) AS qualified_players_sum
FROM campaign_marketing_source cms
LEFT JOIN Snapshot_day_by_day_fact1 sdbdf ON sdbdf.MS_id = cms.id
    AND sdbdf.Date >= @Day_from
    AND sdbdf.Date <= @Day_to
WHERE cms.Username_id IN (@Accounts_origen)
  AND cms.Status_id = '1'
  --  AND cms.Product = @Product
  AND cms.Affiliate_id != 84 
GROUP BY 
    cms.id
HAVING qualified_players_sum >= @CPA_Min;

-- Agregar índice para mejorar el rendimiento
ALTER TABLE tmp_ms_origen ADD PRIMARY KEY (id);

-- Bucle para procesar cada registro de la tabla temporal
process_loop: WHILE (SELECT COUNT(*) FROM tmp_ms_origen) > 0 DO
    -- Seleccionar el primer registro (el que tiene el menor id)
    SELECT 
        id, 
        Code_To_Affiliate, 
        Product, 
        Status, 
        Status_id, 
        Affiliate_id, 
        Channel_id, 
        Deal_id, 
        Country_Deal, 
        Product_Deal, 
        Deal_Valid_From, 
        Shortlink, 
        Shortlink_id,
        Username_id,
        CPA_Limit,
        Source,
        Ad_Code,
        Ad_Valid_From,
        Ad_Valid_To,
        qualified_players_sum
    INTO 
        @v_id, 
        @v_code_to_affiliate, 
        @v_product, 
        @v_status, 
        @v_status_id, 
        @v_affiliate_id, 
        @v_channel_id, 
        @v_deal_id, 
        @v_country_deal, 
        @v_product_deal, 
        @v_deal_valid_from, 
        @v_shortlink, 
        @v_shortlink_id, 
        @v_username_id, 
        @v_cpa_limit,
        @v_source,
        @v_ad_code,
        @v_ad_valid_from,
        @v_ad_valid_to,
        @v_qualified_players_sum
    FROM tmp_ms_origen
    ORDER BY id
    LIMIT 1;

    IF @v_id IS NULL THEN
        LEAVE process_loop;
    END IF;

    IF @Debug = 'NO' THEN
        -- Intentar actualizar UN registro destino
        UPDATE campaign_marketing_source 
        SET Code_To_Affiliate = @v_code_to_affiliate,
            -- Product           = @v_product,
            Status            = @v_status,
            Status_id         = @v_status_id,
            Affiliate_id      = @v_affiliate_id,
            Channel_id        = @v_channel_id,
            Deal_id           = @v_deal_id,
            Country_Deal      = @v_country_deal,
            Product_Deal      = @v_product_deal,
            Deal_Valid_From   = @v_deal_valid_from,
            Shortlink         = @v_shortlink,
            Shortlink_id      = @v_shortlink_id,
            CPA_Limit         = @v_cpa_limit,
            Source            = @v_source,
            Ad_Code           = @v_ad_code,
            Ad_Valid_From     = @v_ad_valid_from,
            Ad_Valid_To       = @v_ad_valid_to,
            Operator          = "SysOp",
            Description       = CONCAT_WS(' ', 'Batch switch acct', NOW(), 'Accnt origin:', @v_username_id) 
        WHERE Username_id  = @Account_destino 
          AND Affiliate_id = 84 
          AND Stat_aggreg = '1'
          AND Channel_id = 531
          AND Product = @Product
        LIMIT 1;
        
        -- Si se actualizó correctamente el registro destino, actualizar el registro origen
        IF ROW_COUNT() > 0 THEN
            UPDATE campaign_marketing_source 
            SET Status_id   = '9',
                Description = CONCAT_WS(' ', 'Switch acct', NOW(), 'Shortlink origin:', Shortlink, 'Shortlink_id:', Shortlink_id), 
                Shortlink   = '',
                Shortlink_id = '',
                Affiliate_id  = 84,
                Channel_id = 5,
                Ad_Code           = NULL,
                Ad_Valid_From     = NULL,
                Ad_Valid_To       = NULL,
                Operator = "SysOp",
                Description = CONCAT_WS(' ', 'Batch switch acct', NOW(), 'Accnt origin:', @v_username_id)
            WHERE id = @v_id;
        END IF;
    END IF;
    
    -- Eliminar el registro procesado de la tabla temporal
    DELETE FROM tmp_ms_origen WHERE id = @v_id;
    
END WHILE process_loop;

-- Eliminar tabla temporal
DROP TEMPORARY TABLE IF EXISTS tmp_ms_origen;

IF @Debug != "NO" THEN
    SELECT 'Proceso completado' AS 'Info';
END IF;

END$$

DELIMITER ;

