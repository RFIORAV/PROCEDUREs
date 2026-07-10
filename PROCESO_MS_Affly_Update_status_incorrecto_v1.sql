/*  Arregla casos en que varias MS comparten Shortlink porque se ha hecho "switch account"
    pero la actualización de affly/rebrandly aplica el Status de una de las reemplazadas
    sin respetar la condición de Active de la más reciente.
    
    09.06.2025 v1

*/


-- ======================================
-- TRANSACCIÓN COMPLETA EN MySQL 8
-- ======================================

-- Paso 1: Iniciar la transacción
START TRANSACTION;

-- Paso 2: Verificar cuántos registros se van a afectar ANTES del UPDATE
SELECT 
    COUNT(*) as registros_a_actualizar,
    'Registros que se van a actualizar' as descripcion
FROM campaign_mkt_source_url
WHERE Stat_aggreg = '1'
AND id IN (
    SELECT id
    FROM (
        SELECT id,
               MAX(CASE WHEN Stat_aggreg = '1' THEN 1 ELSE 0 END) 
               OVER (PARTITION BY Shortlink) as has_stat_aggreg_1,
               COUNT(*) OVER (PARTITION BY Shortlink) as shortlink_count,
               FIRST_VALUE(Stat_aggreg) 
               OVER (PARTITION BY Shortlink ORDER BY Last_Update DESC) as latest_stat_aggreg
        FROM campaign_mkt_source_url
        WHERE Shortlink IS NOT NULL
    ) t
    WHERE has_stat_aggreg_1 = 1
    AND shortlink_count > 1
    AND latest_stat_aggreg != '1'
);

-- Paso 3: Mostrar algunos registros de ejemplo que se van a actualizar
SELECT 
    id, 
    Shortlink, 
    Stat_aggreg, 
    Stat_Sent_to_API, 
    Last_Update,
    'ANTES DEL UPDATE' as estado
FROM campaign_mkt_source_url
WHERE Stat_aggreg = '1'
AND id IN (
    SELECT id
    FROM (
        SELECT id,
               MAX(CASE WHEN Stat_aggreg = '1' THEN 1 ELSE 0 END) 
               OVER (PARTITION BY Shortlink) as has_stat_aggreg_1,
               COUNT(*) OVER (PARTITION BY Shortlink) as shortlink_count,
               FIRST_VALUE(Stat_aggreg) 
               OVER (PARTITION BY Shortlink ORDER BY Last_Update DESC) as latest_stat_aggreg
        FROM campaign_mkt_source_url
        WHERE Shortlink IS NOT NULL
    ) t
    WHERE has_stat_aggreg_1 = 1
    AND shortlink_count > 1
    AND latest_stat_aggreg != '1'
)
LIMIT 5;

-- Paso 4: Ejecutar el UPDATE
UPDATE campaign_mkt_source_url
SET Stat_Sent_to_API = 0
WHERE Stat_aggreg = '1'
AND id IN (
    SELECT id
    FROM (
        SELECT id,
               MAX(CASE WHEN Stat_aggreg = '1' THEN 1 ELSE 0 END) 
               OVER (PARTITION BY Shortlink) as has_stat_aggreg_1,
               COUNT(*) OVER (PARTITION BY Shortlink) as shortlink_count,
               FIRST_VALUE(Stat_aggreg) 
               OVER (PARTITION BY Shortlink ORDER BY Last_Update DESC) as latest_stat_aggreg
        FROM campaign_mkt_source_url
        WHERE Shortlink IS NOT NULL
    ) t
    WHERE has_stat_aggreg_1 = 1
    AND shortlink_count > 1
    AND latest_stat_aggreg != '1'
);

-- Paso 5: Verificar el resultado del UPDATE
SELECT ROW_COUNT() as filas_actualizadas;

-- Paso 6: Mostrar algunos registros DESPUÉS del UPDATE para verificar
SELECT 
    id, 
    Shortlink, 
    Stat_aggreg, 
    Stat_Sent_to_API, 
    Last_Update,
    'DESPUÉS DEL UPDATE' as estado
FROM campaign_mkt_source_url
WHERE Stat_aggreg = '1'
AND id IN (
    SELECT id
    FROM (
        SELECT id,
               MAX(CASE WHEN Stat_aggreg = '1' THEN 1 ELSE 0 END) 
               OVER (PARTITION BY Shortlink) as has_stat_aggreg_1,
               COUNT(*) OVER (PARTITION BY Shortlink) as shortlink_count,
               FIRST_VALUE(Stat_aggreg) 
               OVER (PARTITION BY Shortlink ORDER BY Last_Update DESC) as latest_stat_aggreg
        FROM campaign_mkt_source_url
        WHERE Shortlink IS NOT NULL
    ) t
    WHERE has_stat_aggreg_1 = 1
    AND shortlink_count > 1
    AND latest_stat_aggreg != '1'
)
LIMIT 5;

-- Paso 7: DECIDIR si hacer COMMIT o ROLLBACK
-- ===============================================
-- Si todo está correcto, ejecuta:
COMMIT;

-- Si algo está mal, ejecuta en su lugar:
-- ROLLBACK;

-- ===============================================
-- ALTERNATIVA: Transacción más simple
-- ===============================================

-- START TRANSACTION;
-- 
-- -- Verificar antes
-- SELECT COUNT(*) as total_a_actualizar FROM campaign_mkt_source_url 
-- WHERE Stat_aggreg = '1' AND [... condiciones ...];
-- 
-- -- Ejecutar UPDATE
-- UPDATE campaign_mkt_source_url SET Stat_Sent_to_API = 0 
-- WHERE [... condiciones ...];
-- 
-- -- Verificar después
-- SELECT ROW_COUNT() as filas_actualizadas;
-- 
-- -- Decidir: COMMIT; o ROLLBACK;

/*
Pasos de la transacción:

START TRANSACTION - Inicia la transacción
Verificación previa - Cuenta cuántos registros se van a actualizar
Vista previa - Muestra algunos registros antes del cambio
UPDATE - Ejecuta la actualización
Verificación posterior - Confirma cuántas filas fueron actualizadas
Vista posterior - Muestra los registros después del cambio
COMMIT o ROLLBACK - Confirma o revierte los cambios

Ventajas de usar transacciones:

Atomicidad: Todo se ejecuta o nada se ejecuta
Verificación: Puedes ver exactamente qué va a cambiar antes de confirmar
Seguridad: Si algo sale mal, puedes hacer ROLLBACK
Control: ROW_COUNT() te dice exactamente cuántas filas se afectaron

Cómo usar:

Ejecuta todo el bloque hasta el UPDATE
Revisa los resultados de las verificaciones
Si todo está correcto, ejecuta COMMIT;
Si algo está mal, ejecuta ROLLBACK; en lugar de COMMIT

Nota importante: En MySQL, las transacciones se confirman automáticamente si cierras la conexión sin hacer COMMIT o ROLLBACK, por lo que es importante decidir explícitamente.
*/