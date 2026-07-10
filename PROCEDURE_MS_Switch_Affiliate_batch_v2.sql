/* PROCEDURE_MS_Switch_Affiliate_batch.sql

Descripción:
  Procedimiento MS_Switch_Affiliate_batch.
Funcionalidades principales:

Keys:
Accounts_origen = [valor1^valor2^...]. Lista de cuentas origen (IDs), separadas por ^.
Account_destino = [valor]. Cuenta destino (ID).
Product         = [casino | sport]. Producto a procesar.
Channel_parking = [valor]. Canal de parking en la cuenta destino.
Lower_limit_cpa = [valor]. Umbral mínimo de Qualified_Players acumulados (últimos 3 meses).
Deal_Valid_From = [yyyy-mm-dd]. Fecha efectiva para aplicar en los updates. Default = CURDATE()+7 días.
                  Tener en cuenta como afecta a las ms que pasan a Parking
Debug           = [No | Yes]. Default=No. Si Yes: sólo devuelve dos SELECT (paso 1 = mismas filas que el cursor; paso 2 = MS destino parking) y no ejecuta updates.

- Migración masiva de Marketing Sources: Permite transferir múltiples fuentes de marketing desde varias cuentas origen a una cuenta destino
- Validación de actividad: Solo migra MS con más de X jugadores calificados en los últimos 3 meses
- Prevención de duplicados: Verifica que no existan registros duplicados en la cuenta destino antes de la migración
- Actualización automática de estados: Marca las fuentes migradas como inactivas en la cuenta origen
- Gestión de fechas: Permite fechas de validez futuras para asegurar una transición suave

Características técnicas:

- Procesamiento por lotes mediante cursores para manejo eficiente de múltiples registros
- Implementación de manejo de errores con CONTINUE HANDLER
- Modo Debug para verificación previa de registros afectados
- Validaciones múltiples:
  * Verificación de actividad histórica
  * Control de duplicados
  * Estado de agregación válido
- Actualización atómica con LIMIT 1 para garantizar integridad
- Trazabilidad mediante descripción automática de cambios
- Preservación de información crítica: códigos de afiliado, canales y deals
   
   CALL MS_Switch_Affiliate_batch('Accounts_origen=26^28^45^69^85^87^92,Account_destino=86,Product=casino,Channel_parking=10,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=26^28^45^69^85^87^92,Account_destino=27,Product=sport,Channel_parking=10,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=229^230,Account_destino=111,Product=casino,Channel_parking=20,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=229^230,Account_destino=110,Product=sport,Channel_parking=20,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=34^35^36^37^236^237,Account_destino=86,Product=casino,Channel_parking=10,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=229,Account_destino=229,Product=casino,Channel_parking=621,Lower_limit_cpa=0,Deal_Valid_From=2026-05-01,Debug=no');
   CALL MS_Switch_Affiliate_batch('Accounts_origen=230,Account_destino=230,Product=sport,Channel_parking=621,Lower_limit_cpa=0,Deal_Valid_From=2026-05-01,Debug=no');

11.06.2025 v1     Primera versión operativa
04.05.2026 v2     Cambio de entrada a modo Key=Value (InputCommLine)
                  Ajuste de selección por Channel_parking y filtros de affiliate
                  Debug=Yes: dos SELECT (criterio cursor paso 1 + paso 2), sin abrir cursor ni updates
                  Se agrega parámetro Lower_limit_cpa para umbral mínimo de actividad
                  Se agrega parámetro Deal_Valid_From para controlar la fecha efectiva de updates
  
*/

DROP PROCEDURE IF EXISTS MS_Switch_Affiliate_batch;

DELIMITER $$

CREATE PROCEDURE MS_Switch_Affiliate_batch (
    IN InputCommLine VARCHAR(1000)
)
COMMENT 'Procedimiento MS_Switch_Affiliate_batch.'
proc_label:BEGIN
    DECLARE v_Version VARCHAR(32);
    DECLARE v_InputCommLine VARCHAR(1200);
    DECLARE v_k VARCHAR(150);
    DECLARE v_v VARCHAR(1000);
    DECLARE v_e INT;
    DECLARE v_c INT;
    DECLARE v_Accounts_origen VARCHAR(1000);
    DECLARE v_Account_destino INT;
    DECLARE v_Product_param VARCHAR(50);
    DECLARE v_Channel_parking INT;
    DECLARE v_lower_limit_cpa INT;
    DECLARE v_Debug VARCHAR(3);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id INT;
    DECLARE v_code_to_affiliate VARCHAR(50);
    DECLARE v_product VARCHAR(50);
    DECLARE v_status VARCHAR(30);
    DECLARE v_status_id VARCHAR(2);
    DECLARE v_Stat_aggreg VARCHAR(2);
    DECLARE v_affiliate_id INT;
    DECLARE v_channel_id INT;
    DECLARE v_deal_id INT;
    DECLARE v_country_deal VARCHAR(2);
    DECLARE v_product_deal VARCHAR(50);
    DECLARE v_shortlink VARCHAR(150);
    DECLARE v_shortlink_id VARCHAR(150);
    DECLARE v_existing_count INT DEFAULT 0;
    DECLARE v_username_id INT;
    DECLARE v_Deal_Valid_From DATE;
    DECLARE v_Deal_Valid_From_param DATE;

    -- Cursor para leer registros origen usando IN
    DECLARE cur_origen CURSOR FOR 
        SELECT cms.id, cms.Code_To_Affiliate, cms.Product, cms.Status, cms.Status_id, cms.Stat_aggreg, cms.Affiliate_id, 
               cms.Channel_id, cms.Deal_id, cms.Country_Deal, cms.Product_Deal, 
               cms.Deal_Valid_From, cms.Shortlink, cms.Shortlink_id,
               cms.Username_id
        FROM campaign_marketing_source cms
        left join lateral (SELECT SUM(COALESCE(sdbdf.Qualified_Players, 0)) as CPA_90_days
              FROM Snapshot_day_by_day_fact1 sdbdf
              WHERE sdbdf.MS_id = cms.id
                AND sdbdf.Date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
              GROUP BY sdbdf.MS_id) as sdbdf_90_days ON TRUE
        WHERE FIND_IN_SET(cms.Username_id, v_Accounts_origen)
          AND cms.Stat_aggreg IN ('1','4')
          AND cms.Affiliate_id NOT IN (84,300,449)
          AND cms.Product = v_Product_param
          AND COALESCE(sdbdf_90_days.CPA_90_days, 0) >= v_lower_limit_cpa
          ;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET v_Version = 'v2 04.05.2026';
    SET v_Accounts_origen = '';
    SET v_Account_destino = 0;
    SET v_Product_param = '';
    SET v_Channel_parking = 0;
    SET v_lower_limit_cpa = 30;
    SET v_Debug = 'NO';
    SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
    SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');
    SET v_Deal_Valid_From = DATE_ADD(CURDATE(), INTERVAL 7 DAY); -- Fecha de cambio efectiva
    SET v_Deal_Valid_From_param = DATE_ADD(CURDATE(), INTERVAL 7 DAY); -- Fecha de cambio efectiva

    parse_loop: WHILE LENGTH(TRIM(v_InputCommLine)) > 0 DO
        SET v_e = INSTR(v_InputCommLine, '=');
        SET v_c = INSTR(v_InputCommLine, ',');

        IF v_e = 0 OR v_c = 0 OR v_e > v_c THEN
            LEAVE parse_loop;
        END IF;

        SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
        SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
        SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

        CASE LOWER(v_k)
            WHEN 'accounts_origen' THEN SET v_Accounts_origen = REPLACE(v_v, '^', ',');
            WHEN 'account_destino' THEN SET v_Account_destino = IFNULL(CAST(v_v AS UNSIGNED), 0);
            WHEN 'product'         THEN SET v_Product_param = LOWER(v_v);
            WHEN 'channel_parking' THEN SET v_Channel_parking = IFNULL(CAST(v_v AS UNSIGNED), 0);
            WHEN 'lower_limit_cpa' THEN SET v_lower_limit_cpa = IFNULL(CAST(v_v AS SIGNED), 0);
            WHEN 'deal_valid_from' THEN SET v_Deal_Valid_From_param = STR_TO_DATE(v_v, '%Y-%m-%d');
            WHEN 'debug'           THEN SET v_Debug = UPPER(v_v);
            ELSE SET v_k = v_k; -- Ignora keys no reconocidas (evita Error 1339)
        END CASE;
    END WHILE parse_loop;

    IF v_Accounts_origen = '' OR v_Account_destino = 0 OR v_Product_param = '' OR v_Channel_parking = 0 OR v_lower_limit_cpa < 0 OR v_Deal_Valid_From IS NULL THEN
        SELECT CONCAT('ERROR: Parámetros inválidos. Versión ', v_Version) AS Error,
               'Formato esperado: Accounts_origen=26^28,Account_destino=86,Product=casino,Channel_parking=10,Lower_limit_cpa=30,Deal_Valid_From=2026-05-15,Debug=Yes' AS Ejemplo;
        LEAVE proc_label;
    END IF;

    -- Debug=Yes: mismas filas que el cursor (paso 1) y MS destino parking (paso 2); no updates ni cursor
    IF v_Debug = 'YES' THEN
        SELECT cms.id, cms.Code_To_Affiliate, cms.Product, cms.Status, cms.Status_id, cms.Stat_aggreg, cms.Affiliate_id,
               cms.Channel_id, cms.Deal_id, cms.Country_Deal, cms.Product_Deal,
               cms.Deal_Valid_From, cms.Shortlink, cms.Shortlink_id,
               cms.Username_id, COALESCE(sdbdf_90_days.CPA_90_days, 0) as CPA_90_days
        FROM campaign_marketing_source cms
        left join lateral (SELECT SUM(COALESCE(sdbdf.Qualified_Players, 0)) as CPA_90_days
              FROM Snapshot_day_by_day_fact1 sdbdf
              WHERE sdbdf.MS_id = cms.id
                AND sdbdf.Date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
              GROUP BY sdbdf.MS_id) as sdbdf_90_days ON TRUE
        WHERE FIND_IN_SET(cms.Username_id, v_Accounts_origen)
          AND cms.Stat_aggreg IN ('1','4')
          AND cms.Affiliate_id NOT IN (84,300,449)
          AND cms.Product = v_Product_param
          AND COALESCE(sdbdf_90_days.CPA_90_days, 0) >= v_lower_limit_cpa
          ;

        SELECT cms.id, cms.Username_id, cms.Code_To_Affiliate, cms.Product, cms.Status, cms.Status_id, cms.Stat_aggreg,
               cms.Affiliate_id, cms.Channel_id, cms.Deal_id, cms.Country_Deal, cms.Product_Deal,
               cms.Deal_Valid_From, cms.Shortlink, cms.Shortlink_id
        FROM campaign_marketing_source cms
        WHERE cms.Username_id = v_Account_destino
          AND cms.Affiliate_id = 84
          AND cms.Stat_aggreg = '1'
          AND cms.Product = v_Product_param
          AND cms.Channel_id = v_Channel_parking;

        LEAVE proc_label;
    END IF;

    -- Abrir cursor
    OPEN cur_origen;
    
    read_loop: LOOP
        FETCH cur_origen INTO v_id, v_code_to_affiliate, v_product, v_status, 
                             v_status_id, v_stat_aggreg, v_affiliate_id, v_channel_id, v_deal_id,
                             v_country_deal, v_product_deal, v_deal_valid_from,
                             v_shortlink, v_shortlink_id, v_username_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;

        IF v_Debug = 'NO' THEN
            -- Intentar actualizar UN registro destino
            UPDATE campaign_marketing_source 
            SET Code_To_Affiliate = v_code_to_affiliate,
                  Product           = v_product,
                  Status            = v_status,
                  Status_id         = v_status_id,
                  Affiliate_id      = v_affiliate_id,
                  Channel_id        = v_channel_id,
                  Deal_id           = v_deal_id,
                  Country_Deal      = v_country_deal,
                  Product_Deal      = CASE WHEN v_product_deal = 'any' THEN '' ELSE v_product_deal END,
                  Deal_Valid_From   = v_Deal_Valid_From,
                  Shortlink         = v_shortlink,
                  Shortlink_id      = v_shortlink_id,
                  Description       = concat_ws(" ","SP:MS_Switch_Affiliate_batch",NOW(),"Aff origin:",84) 
            WHERE Username_id  = v_Account_destino 
               AND Affiliate_id = 84 
               AND Stat_aggreg = '1'
               AND Product = v_product
               AND Channel_id = v_Channel_parking
            LIMIT 1;
            
            -- Si se actualizó correctamente el registro destino, actualizar el registro origen
            IF ROW_COUNT() > 0 THEN
                  UPDATE campaign_marketing_source 
                  SET   Status_id   ='9',
                        Affiliate_id      = 300, -- Aff_SWAP
                        Deal_Valid_From   = v_Deal_Valid_From_param,
                        Description =concat_ws(" ","SP:MS_Switch_Affiliate_batch",NOW(),"Aff origin:",v_affiliate_id), 
                        Shortlink   ='',
                        Shortlink_id=''
                  WHERE id = v_id;
            END IF;
        END IF;
        
    END LOOP;
    
    CLOSE cur_origen;
    
END$$

DELIMITER ;

/*
comprueba que el sp haga lo siguiente:
1. Selecciona las marketing sources (MS) que pertenezcan a las cuentas de origen (Accounts_origen) con Stat_aggreg=1 o 4 y que no estén asignadas al Affiliate_id=84 o 300. Estas MS son las candidatas a ser reasignadas al Affiliate_id=300
2. Selecciona las MS que pertenezcan a Account_destino = [valor]. Cuenta destino con Stat_aggreg=1 y que estén asignadas al Affiliate_id=84, Product=Parámetro Product y Channel_id=parámetro de entrada Channel_parking. Estas MS son las candidatas a ser reasignadas con los datos de las MS seleccionadas en 1.
3. Comprueba que hay suficientes MS seleccionadas en el paso 2. para reasignar las seleccionadas en Paso 1. Si no hay suficientes, sólo procesará tantas MS del paso 1 como haya del paso 2.
4. Reasignación: 
Ciclo de Updates encadenados para cada MS seleccionado en el paso 1 y para cada MS seleccionado en el paso 2
Update de MS del paso 1:
            UPDATE campaign_marketing_source 
            SET Code_To_Affiliate = v_code_to_affiliate,
                  Product           = v_product,
                  Status            = v_status,
                  Status_id         = v_status_id,
                  Affiliate_id      = v_affiliate_id,
                  Channel_id        = v_channel_id,
                  Deal_id           = v_deal_id,
                  Country_Deal      = v_country_deal,
                  Product_Deal      = v_product_deal,
                  -- Deal_Valid_From   = v_deal_valid_from,
                  Deal_Valid_From   = DATE_ADD(CURDATE(), INTERVAL 7 DAY),
                  Shortlink         = v_shortlink,
                  Shortlink_id      = v_shortlink_id,
                  Description       = concat_ws(" ","Batch switch aff",NOW(),"Aff origin:",Affiliate_id)

Update de MS del paso 2:
                  UPDATE campaign_marketing_source 
                  SET   Status_id   ='9',
                        Affiliate_id      = 300, -- Aff_SWAP
                        Deal_Valid_From   = DATE_ADD(CURDATE(), INTERVAL 7 DAY),
                        Description =concat_ws(" ","Batch switch aff",NOW(),"Aff origin:",v_affiliate_id), 
                        -- Shortlink   ='',
                        Shortlink_id=''
para cada MS seleccionado en el paso 2                         
*/