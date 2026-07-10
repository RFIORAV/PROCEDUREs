/* PROCEDURE_Update_auto_from_dbd_manual_v1.1.sql


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

- Carga de meses distintos pendientes en tabla temporal (sin cursor sobre Snapshot_day_by_day_manual)
- Bucle por mes distinto (YYYY-MM) para Snapshot y Sync_Fact2_from_Fact1
- Recálculo global de comisiones ges/aff al final del ciclo
- Validación de estado de procesamiento antes de ejecutar procedimientos
- Trigger automático para resetear el estado de procesamiento cuando se modifican datos

Secuencia de ejecución:
1. Por cada mes distinto pendiente (YYYY-MM):
   a. Snapshot_day_by_day_fact1_upd_from_dbd_manual
   b. Sync_Fact2_from_Fact1 (mode=run,month=YYYY-MM)
2. total_monthy_comm_ges_upd('')
3. total_monthy_comm_aff_upd('')

Test:
- Verificar que los registros con is_proccessed=0 se procesen correctamente
- Confirmar que solo se invoca una vez por mes distinto
- Validar que is_proccessed se actualice a 1 después del procesamiento
- Probar que el trigger resetee is_proccessed a 0 cuando se modifiquen datos

1. Ejecutar manualmente:
   CALL Update_auto_from_dbd_manual('NO');  -- Sin información de debug
   CALL Update_auto_from_dbd_manual('YES'); -- Con información de debug

11.09.2025 v1     Primera versión operativa
12.02.2026 v1.1   Se marca como procesado en Snapshot_day_by_day_fact1_upd_from_dbd_manual
20.06.2026 v1.1   Tabla temporal por mes distinto; Snapshot+Sync por mes; comisiones ges/aff al final
*/

DROP PROCEDURE IF EXISTS Update_auto_from_dbd_manual;

DELIMITER $$

CREATE PROCEDURE Update_auto_from_dbd_manual(
    IN Debug VARCHAR(3) -- DEFAULT 'NO'
)
COMMENT 'v1.1 20.06.2026 - Procedimiento Update_auto_from_dbd_manual.'
proc_label:BEGIN
    DECLARE v_Version VARCHAR(20);
    DECLARE v_date_formatted VARCHAR(7);
    DECLARE v_sync_params VARCHAR(500);
    DECLARE v_month_count INT DEFAULT 0;
    DECLARE v_seq INT DEFAULT 0;

    SET v_Version = 'v1.1 20.06.2026';

    DROP TEMPORARY TABLE IF EXISTS tmp_manual_months;
    CREATE TEMPORARY TABLE tmp_manual_months (
        seq INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
        date_formatted VARCHAR(7) NOT NULL
    ) ENGINE=MEMORY;

    INSERT INTO tmp_manual_months (date_formatted)
    SELECT DISTINCT LEFT(Date, 7)
    FROM Snapshot_day_by_day_manual
    WHERE is_proccessed = 0 AND is_active=1
    ORDER BY LEFT(Date, 7);

    SELECT COUNT(*) INTO v_month_count FROM tmp_manual_months;

    IF Debug = 'YES' THEN
        SELECT 'Iniciando procesamiento automático de registros manuales' AS 'Info',
               NOW() AS 'Fecha_Inicio',
               DATABASE() AS 'Base_Datos',
               v_Version AS 'Version';

        SELECT 'Meses distintos pendientes de procesamiento:' AS 'Info';
        SELECT date_formatted AS 'YYYY_MM'
        FROM tmp_manual_months
        ORDER BY seq;
    END IF;

    IF v_month_count = 0 THEN
        IF Debug = 'YES' THEN
            SELECT 'No hay registros pendientes de procesamiento' AS 'Info';
        END IF;
        LEAVE proc_label;
    END IF;

    SET v_seq = 0;
    month_loop: WHILE v_seq < v_month_count DO
        SET v_seq = v_seq + 1;

        SELECT date_formatted
        INTO v_date_formatted
        FROM tmp_manual_months
        WHERE seq = v_seq;

        SET v_sync_params = CONCAT('mode=run,month=', v_date_formatted,',db=', DATABASE());
        IF v_date_formatted = LEFT(CURRENT_DATE(), 7) 
        THEN SET v_sync_params = CONCAT(v_sync_params,',MS_id=ALL');
        ELSE SET v_sync_params = CONCAT(v_sync_params,',MS_id=ALLALL');
        END IF;

        IF Debug = 'YES' THEN
            SELECT CONCAT('Procesando mes: ', v_date_formatted) AS 'Info',
                   v_sync_params AS 'Sync_Params';
        END IF;

        CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual(v_date_formatted);
        CALL Sync_Fact2_from_Fact1(v_sync_params);
    END WHILE;

    IF Debug = 'YES' THEN
        SELECT 'Recalculando comisiones mensuales ges/aff (global)' AS 'Info';
    END IF;

    CALL total_monthy_comm_ges_upd('');
    CALL total_monthy_comm_aff_upd('');

    DROP TEMPORARY TABLE IF EXISTS tmp_manual_months;

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
- El procedimiento procesa todos los meses distintos pendientes en una sola ejecución
- is_proccessed se marca en Snapshot_day_by_day_fact1_upd_from_dbd_manual
- El parámetro DEBUG controla la salida informativa (YES/NO, por defecto NO)
- En producción usar DEBUG='NO' para mejor rendimiento
*/
