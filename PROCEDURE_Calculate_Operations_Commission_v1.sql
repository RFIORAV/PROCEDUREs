/*
PROCEDURE_Calculate_Operations_Commission_v1.sql - Cálculo de comisiones de operaciones

Descripción:
Este procedimiento calcula las comisiones de operaciones basándose en los movimientos
de la tabla DBD_movements y aplicando las reglas definidas en la tabla Deals.

Keys:
  p_start_date = [valor]. Parámetro de entrada.
  p_end_date = [valor]. Parámetro de entrada.
  p_tracker_id = [valor]. Parámetro de entrada.
  p_product = [valor]. Parámetro de entrada.

Tablas utilizadas:
- DBD_movements: Contiene los movimientos de operaciones con campos Date, Tracker_id, Product, Deposits
- Deals: Contiene las reglas de comisión con campos Product, Criteria, Threshold, Level, CPA

Lógica del cálculo:
1. Agrupa los movimientos por Tracker_id y Product
2. Suma el campo Criteria (ej: Deposits) para cada grupo
3. Aplica las reglas de la tabla Deals según el Threshold alcanzado
4. Calcula la comisión CPA correspondiente al Level alcanzado

Parámetros de entrada:
- p_start_date: Fecha de inicio para el cálculo (formato YYYY-MM-DD)
- p_end_date: Fecha de fin para el cálculo (formato YYYY-MM-DD)
- p_tracker_id: ID del tracker específico (opcional, NULL para todos)
- p_product: Producto específico (opcional, NULL para todos)

Ejemplos de uso:
call Calculate_Operations_Commission('2025-01-01', '2025-01-31', NULL, NULL);
call Calculate_Operations_Commission('2025-01-01', '2025-01-31', 123, 'Sport');

Historial de Versiones:
13.01.2025 V1     Primera versión operativa

*/

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
DROP PROCEDURE IF EXISTS Calculate_Operations_Commission;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Calculate_Operations_Commission`(
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_tracker_id INT,
    IN p_product VARCHAR(80)
)
COMMENT 'Cálculo de comisiones de operaciones basado en movimientos y reglas de deals'
LANGUAGE SQL

proc_label:BEGIN
    -- Declaración de variables
    DECLARE v_version VARCHAR(20) DEFAULT 'v1.0 13.01.2025';
    DECLARE v_error_message VARCHAR(500);
    DECLARE v_sql_query TEXT;
    
    -- Manejo de errores
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_message = MESSAGE_TEXT;
        SELECT CONCAT('Error en Calculate_Operations_Commission: ', v_error_message) AS Error;
        ROLLBACK;
    END;
    
    -- Validación de parámetros
    IF p_start_date IS NULL OR p_end_date IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Las fechas de inicio y fin son obligatorias';
    END IF;
    
    IF p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La fecha de inicio no puede ser mayor que la fecha de fin';
    END IF;
    
    -- Inicio de transacción
    START TRANSACTION;
    
    -- Crear tabla temporal para almacenar resultados
    DROP TEMPORARY TABLE IF EXISTS temp_operations_commission;
    CREATE TEMPORARY TABLE temp_operations_commission (
        tracker_id INT NOT NULL,
        product VARCHAR(80) NOT NULL,
        total_deposits DECIMAL(15,2) NOT NULL DEFAULT 0,
        level_achieved VARCHAR(50) NULL,
        commission_cpa DECIMAL(12,2) NOT NULL DEFAULT 0,
        deal_id INT NULL,
        calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_tracker_product (tracker_id, product),
        INDEX idx_level (level_achieved)
    ) ENGINE=InnoDB;
    
    -- Insertar datos calculados
    INSERT INTO temp_operations_commission (
        tracker_id,
        product,
        total_deposits,
        level_achieved,
        commission_cpa,
        deal_id
    )
    WITH movements_summary AS (
        -- Agrupar movimientos por tracker y producto
        SELECT 
            m.tracker_id,
            m.product,
            SUM(m.deposits) AS total_deposits,
            COUNT(*) AS total_movements
        FROM DBD_movements m
        WHERE m.date BETWEEN p_start_date AND p_end_date
          AND (p_tracker_id IS NULL OR m.tracker_id = p_tracker_id)
          AND (p_product IS NULL OR m.product = p_product)
        GROUP BY m.tracker_id, m.product
        HAVING total_deposits > 0
    ),
    deals_applied AS (
        -- Aplicar reglas de deals según el total de deposits
        SELECT 
            ms.tracker_id,
            ms.product,
            ms.total_deposits,
            ms.total_movements,
            d.id AS deal_id,
            d.level,
            d.cpa,
            d.threshold,
            d.criteria,
            -- Encontrar el nivel más alto alcanzado
            ROW_NUMBER() OVER (
                PARTITION BY ms.tracker_id, ms.product 
                ORDER BY d.threshold DESC
            ) AS rn
        FROM movements_summary ms
        LEFT JOIN deals d ON (
            (d.product = ms.product OR d.product = '' OR d.product IS NULL)
            AND ms.total_deposits >= d.threshold
            AND d.criteria = 'Deposits'
        )
        WHERE d.id IS NOT NULL
    )
    SELECT 
        da.tracker_id,
        da.product,
        da.total_deposits,
        da.level AS level_achieved,
        da.cpa AS commission_cpa,
        da.deal_id
    FROM deals_applied da
    WHERE da.rn = 1; -- Solo el nivel más alto alcanzado
    
    -- Mostrar resultados
    SELECT 
        'RESULTADOS DEL CÁLCULO DE COMISIONES' AS titulo,
        CONCAT('Período: ', p_start_date, ' a ', p_end_date) AS periodo,
        CONCAT('Versión: ', v_version) AS version,
        NOW() AS fecha_calculo;
    
    -- Resumen general
    SELECT 
        'RESUMEN GENERAL' AS tipo_reporte,
        COUNT(*) AS total_registros,
        SUM(total_deposits) AS total_deposits,
        SUM(commission_cpa) AS total_comisiones,
        COUNT(CASE WHEN level_achieved IS NOT NULL THEN 1 END) AS registros_con_comision
    FROM temp_operations_commission;
    
    -- Detalle por tracker y producto
    SELECT 
        'DETALLE POR TRACKER Y PRODUCTO' AS tipo_reporte,
        tracker_id,
        product,
        total_deposits,
        level_achieved,
        commission_cpa,
        deal_id,
        calculation_date
    FROM temp_operations_commission
    ORDER BY tracker_id, product;
    
    -- Resumen por nivel alcanzado
    SELECT 
        'RESUMEN POR NIVEL' AS tipo_reporte,
        level_achieved,
        COUNT(*) AS cantidad_registros,
        SUM(total_deposits) AS total_deposits_nivel,
        SUM(commission_cpa) AS total_comisiones_nivel,
        AVG(commission_cpa) AS promedio_comision
    FROM temp_operations_commission
    WHERE level_achieved IS NOT NULL
    GROUP BY level_achieved
    ORDER BY level_achieved;
    
    -- Top 10 por comisión
    SELECT 
        'TOP 10 POR COMISIÓN' AS tipo_reporte,
        tracker_id,
        product,
        total_deposits,
        level_achieved,
        commission_cpa
    FROM temp_operations_commission
    WHERE commission_cpa > 0
    ORDER BY commission_cpa DESC
    LIMIT 10;
    
    -- Registros sin comisión (para análisis)
    SELECT 
        'REGISTROS SIN COMISIÓN' AS tipo_reporte,
        tracker_id,
        product,
        total_deposits,
        'No aplica deal' AS motivo
    FROM temp_operations_commission
    WHERE level_achieved IS NULL
    ORDER BY total_deposits DESC;
    
    -- Commit de la transacción
    COMMIT;
    
    -- Limpiar tabla temporal
    DROP TEMPORARY TABLE IF EXISTS temp_operations_commission;
    
END$$

DELIMITER ;

-- Ejemplo de uso:
-- call Calculate_Operations_Commission('2025-01-01', '2025-01-31', NULL, NULL); 