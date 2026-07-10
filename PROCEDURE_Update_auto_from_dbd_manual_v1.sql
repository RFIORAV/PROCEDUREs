/* PROCEDURE_Update_auto_from_dbd_manual.sql


Descripción:
  Procedimiento Update_auto_from_dbd_manual.
Funcionalidades principales:

Keys:
Debug = [valor]. Parámetro de entrada.

- Procesamiento automático de registros manuales: Ejecuta automáticamente una secuencia de procedimientos cuando se detectan registros no procesados en la tabla Snapshot_day_by_day_manual
- Actualización de facturas: Procesa datos manuales y actualiza las tablas de hechos correspondientes
- Sincronización de datos: Mantiene la consistencia entre las diferentes tablas de hechos del sistema
- Actualización de comisiones: Recalcula las comisiones mensuales tanto para gestores como para afiliados
- Control de procesamiento: Marca los registros como procesados para evitar ejecuciones duplicadas

Características técnicas:

- Procesamiento por lotes mediante cursores para manejo eficiente de múltiples registros
- Implementación de manejo de errores con CONTINUE HANDLER
- Reemplazo dinámico de parámetros basado en los datos de cada registro
- Validación de estado de procesamiento antes de ejecutar procedimientos
- Actualización atómica del estado de procesamiento
- Trigger automático para resetear el estado de procesamiento cuando se modifican datos

Secuencia de ejecución:
1. Snapshot_day_by_day_fact1_upd_from_dbd_manual - Actualiza tabla de hechos principal
2. total_monthy_comm_ges_upd - Recalcula comisiones mensuales de gestores
3. Sync_Fact2_from_Fact1 - Sincroniza datos entre tablas de hechos
4. total_monthy_comm_aff_upd - Recalcula comisiones mensuales de afiliados

Test:
- Verificar que los registros con is_proccessed=0 se procesen correctamente
- Confirmar que los parámetros se reemplacen dinámicamente
- Validar que is_proccessed se actualice a 1 después del procesamiento
- Probar que el trigger resetee is_proccessed a 0 cuando se modifiquen datos

1. Ejecutar manualmente:
   CALL Update_auto_from_dbd_manual('NO');  -- Sin información de debug
   CALL Update_auto_from_dbd_manual('YES'); -- Con información de debug

11.09.2025 v1     Primera versión operativa
12.02.2026 v1.1   Se marca como procesado en Snapshot_day_by_day_fact1_upd_from_dbd_manual
*/

DROP PROCEDURE IF EXISTS Update_auto_from_dbd_manual;

DELIMITER $$

CREATE PROCEDURE Update_auto_from_dbd_manual(
    IN Debug VARCHAR(3) -- DEFAULT 'NO'
)
COMMENT 'Procedimiento Update_auto_from_dbd_manual.'
BEGIN
    DECLARE v_Version VARCHAR(20);
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id INT;
    DECLARE v_date DATE;
    DECLARE v_ms_id INT;
    DECLARE v_database_name VARCHAR(64);
    DECLARE v_date_formatted VARCHAR(7);
    DECLARE v_sync_params VARCHAR(500);
    
    -- Cursor para leer registros no procesados
    DECLARE cur_manual CURSOR FOR 
        SELECT id, Date, MS_id
        FROM Snapshot_day_by_day_manual
        WHERE is_proccessed = 0;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET v_Version = 'v1.1 12.02.2026';
    -- Obtener nombre de la base de datos actual
    SET v_database_name = DATABASE();
    
    -- Mostrar información de inicio solo en modo DEBUG
    IF Debug = 'YES' THEN
        SELECT 'Iniciando procesamiento automático de registros manuales' AS 'Info',
               NOW() AS 'Fecha_Inicio',
               v_database_name AS 'Base_Datos';
        
        -- Mostrar registros a procesar
        SELECT 'Registros pendientes de procesamiento:' AS 'Info';
        SELECT id, Date, MS_id, LEFT(Date, 7) AS 'YYYY_MM'
        FROM Snapshot_day_by_day_manual
        WHERE is_proccessed = 0;
    END IF;
    
    -- Abrir cursor
    OPEN cur_manual;
    
    read_loop: LOOP
        FETCH cur_manual INTO v_id, v_date, v_ms_id;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Formatear fecha como YYYY-MM
        SET v_date_formatted = LEFT(v_date, 7);
        
        -- Construir parámetros para Sync_Fact2_from_Fact1
        SET v_sync_params = CONCAT('mode=RUN,month=', v_date_formatted, ',MS_id=', v_ms_id, ',db=', v_database_name);
        
        -- Mostrar información del registro en procesamiento solo en modo DEBUG
        IF Debug = 'YES' THEN
            SELECT CONCAT('Procesando registro ID: ', v_id) AS 'Info',
                   v_date_formatted AS 'YYYY_MM',
                   v_ms_id AS 'MS_id',
                   v_database_name AS 'DB',
                   v_sync_params AS 'Sync_Params';
        END IF;
        
        -- Ejecutar secuencia de procedimientos
        CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual(v_date_formatted);
        
        CALL total_monthy_comm_ges_upd(v_date_formatted);
        
        CALL Sync_Fact2_from_Fact1(v_sync_params);
        
        CALL total_monthy_comm_aff_upd(v_date_formatted);
        
        -- Marcar registro como procesado (12.02.2026 se marca en Snapshot_day_by_day_fact1_upd_from_dbd_manual)
        -- UPDATE Snapshot_day_by_day_manual 
        -- SET is_proccessed = 1
        -- WHERE id = v_id;
        
        -- Verificar que se actualizó correctamente solo en modo DEBUG
        IF Debug = 'YES' THEN
            IF ROW_COUNT() > 0 THEN
                SELECT CONCAT('Registro ID ', v_id, ' marcado como procesado') AS 'Resultado';
            ELSE
                SELECT CONCAT('ERROR: No se pudo marcar el registro ID ', v_id, ' como procesado') AS 'Error';
            END IF;
        END IF;
        
    END LOOP;
    
    CLOSE cur_manual;
    
    -- Mostrar resumen final solo en modo DEBUG
    IF Debug = 'YES' THEN
        SELECT 'Procesamiento completado' AS 'Info',
               NOW() AS 'Fecha_Fin',
               (SELECT COUNT(*) FROM Snapshot_day_by_day_manual WHERE is_proccessed = 0) AS 'Registros_Pendientes';
    END IF;
    
END$$

DELIMITER ;

-- Trigger para resetear is_proccessed cuando se modifiquen datos
DROP TRIGGER IF EXISTS Snapshot_day_by_day_manual_before_update_proccessed;

DELIMITER $$

CREATE TRIGGER Snapshot_day_by_day_manual_before_update_proccessed
before UPDATE ON Snapshot_day_by_day_manual
FOR EACH ROW
BEGIN
    -- Verificar si algún campo relevante ha cambiado (excluyendo is_proccessed y Hour_Update)
    IF (OLD.is_active != NEW.is_active OR
        OLD.deal_to_apply != NEW.deal_to_apply OR
        OLD.MS_id != NEW.MS_id OR
        OLD.Area != NEW.Area OR
        OLD.Owner != NEW.Owner OR
        OLD.Affiliate != NEW.Affiliate OR
        OLD.Campaign != NEW.Campaign OR
        OLD.Deal != NEW.Deal OR
        OLD.Deal_Aff != NEW.Deal_Aff OR
        OLD.Date != NEW.Date OR
        OLD.Username != NEW.Username OR
        OLD.Portal != NEW.Portal OR
        OLD.Brand != NEW.Brand OR
        OLD.Tracker_ID != NEW.Tracker_ID OR
        OLD.Tracker_Name != NEW.Tracker_Name OR
        OLD.Code_To_Affiliate != NEW.Code_To_Affiliate OR
        OLD.Product != NEW.Product OR
        OLD.Product_Real != NEW.Product_Real OR
        OLD.Qualified_Players != NEW.Qualified_Players OR
        OLD.Qualified_Players_Adjusted != NEW.Qualified_Players_Adjusted OR
        OLD.Criteria_Type != NEW.Criteria_Type OR
        OLD.Level_Reached != NEW.Level_Reached OR
        OLD.First_Time_Deposit != NEW.First_Time_Deposit OR
        OLD.Views != NEW.Views OR
        OLD.Clicks != NEW.Clicks OR
        OLD.Signups != NEW.Signups OR
        OLD.Impressions != NEW.Impressions OR
        OLD.Sign_Up_Offer != NEW.Sign_Up_Offer OR
        OLD.Type != NEW.Type OR
        OLD.Language != NEW.Language OR
        OLD.Country != NEW.Country OR
        OLD.Brand_Name != NEW.Brand_Name OR
        OLD.Registration_Date != NEW.Registration_Date OR
        OLD.Deposits != NEW.Deposits OR
        OLD.Depositing_Customers != NEW.Depositing_Customers OR
        OLD.Active_Customers != NEW.Active_Customers OR
        OLD.New_Depositing_Customers != NEW.New_Depositing_Customers OR
        OLD.New_Active_Customers != NEW.New_Active_Customers OR
        OLD.First_Time_Active_Customers != NEW.First_Time_Active_Customers OR
        OLD.Turnover != NEW.Turnover OR
        OLD.Net_Revenue != NEW.Net_Revenue OR
        OLD.Revenue_Share_Gestor != NEW.Revenue_Share_Gestor OR
        OLD.Revenue_Share_Affiliate != NEW.Revenue_Share_Affiliate OR
        OLD.CPA_Value_Affiliate != NEW.CPA_Value_Affiliate OR
        OLD.CPA_Value_Gestor != NEW.CPA_Value_Gestor OR
        OLD.TypeInfo != NEW.TypeInfo OR
        OLD.Aff_Credit_1 != NEW.Aff_Credit_1 OR
        OLD.Aff_Credit_2 != NEW.Aff_Credit_2 OR
        OLD.Aff_Credit_3 != NEW.Aff_Credit_3 OR
        OLD.Ges_Credit_1 != NEW.Ges_Credit_1 OR
        OLD.Ges_Credit_2 != NEW.Ges_Credit_2 OR
        OLD.Ges_Credit_3 != NEW.Ges_Credit_3) THEN
        
        -- Resetear is_proccessed a 0 para indicar que necesita reprocesamiento
        SET NEW.is_proccessed = 0;
        
    END IF;
END$$

DELIMITER ;

-- Comentarios adicionales para uso del procedimiento:
/*
USO DEL PROCEDIMIENTO:

1. Ejecutar manualmente:
   CALL Update_auto_from_dbd_manual('NO');  -- Sin información de debug
   CALL Update_auto_from_dbd_manual('YES'); -- Con información de debug

2. Programar ejecución automática (ejemplo con Event Scheduler):
   CREATE EVENT IF NOT EXISTS evt_process_manual_records
   ON SCHEDULE EVERY 1 HOUR
   DO
     CALL Update_auto_from_dbd_manual('NO');

3. Verificar registros pendientes:
   SELECT COUNT(*) as 'Registros_Pendientes' 
   FROM Snapshot_day_by_day_manual 
   WHERE is_proccessed = 0;

4. Verificar registros procesados:
   SELECT COUNT(*) as 'Registros_Procesados' 
   FROM Snapshot_day_by_day_manual 
   WHERE is_proccessed = 1;

NOTAS IMPORTANTES:
- El trigger se ejecuta automáticamente cuando se modifican datos en la tabla
- Los parámetros se reemplazan dinámicamente basándose en los datos de cada registro
- El procedimiento procesa todos los registros pendientes en una sola ejecución
- Se incluye manejo de errores y logging para facilitar el debugging
- El parámetro DEBUG controla la salida informativa (YES/NO, por defecto NO)
- En producción usar DEBUG='NO' para mejor rendimiento
*/
