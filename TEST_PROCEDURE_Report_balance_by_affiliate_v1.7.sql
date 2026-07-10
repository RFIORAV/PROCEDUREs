/*
TEST_PROCEDURE_Report_balance_by_affiliate_v1.7.sql
Pruebas minimas para Report_balance_by_affiliate_dev (v1.7)

Objetivo:
- Validar ejecucion basica del SP.
- Validar filtros y opciones.
- Verificar presencia/consistencia de columnas nuevas:
  `Commis. Curr. Mth`, `Confirmed 20th Day CM`, `Confirmed Total CM`.

Nota importante sobre corte dia 20:
- El SP usa CURDATE() internamente.
- Para probar ambos escenarios (<20 y >=20), ejecutar este script en fechas reales
  de cada ventana o ajustar temporalmente v_CurrentDay en el SP de QA.
*/

-- 1) Smoke test (ejecucion normal)
CALL Report_balance_by_affiliate_dev('');

-- 2) Modo debug (muestra SQL generado)
CALL Report_balance_by_affiliate_dev('debug=yes');

-- 3) Solo filtros disponibles
CALL Report_balance_by_affiliate_dev('filters=yes,debug=YE');

-- 4) Incluir balances en cero
CALL Report_balance_by_affiliate_dev('omit_0=no');

-- 5) Solo afiliados activos
CALL Report_balance_by_affiliate_dev('showactive=yes,omit_0=no');

-- 6) Solo afiliados inactivos
CALL Report_balance_by_affiliate_dev('showinactives=yes,omit_0=no');

-- 7) Todos (activos + inactivos)
CALL Report_balance_by_affiliate_dev('includeinactives=yes,omit_0=no');

-- 8) Guardar resultado en temporal y mostrar contenido
CALL Report_balance_by_affiliate_dev('tmptable=yes,debug=YE,omit_0=no');

-- 9) Verificacion columnas nuevas en temporal
SELECT
   `Meta`,
   `Affiliate_id`,
   `Affiliate`,
   `Currency`,
   `Commis. Curr. Mth`,
   `Confirmed 20th Day CM`,
   `Confirmed Total CM`,
   `Confirmed`,
   `Confirmed21`
FROM tmp_balance_by_affiliate
ORDER BY `Affiliate`
LIMIT 200;

-- 10) Caso ventana dia 1..19 (ejecutar cuando aplique)
-- Esperado:
-- - `Confirmed 20th Day CM` > 0 para afiliados con comision del mes previo pendiente.
-- - `Confirmed Total CM` sin duplicar indebidamente ese bloque.
CALL Report_balance_by_affiliate_dev('tmptable=yes,omit_0=no');
SELECT
   `Affiliate`,
   `Commis. Curr. Mth`,
   `Confirmed 20th Day CM`,
   `Confirmed Total CM`
FROM tmp_balance_by_affiliate
WHERE `Meta`='data'
  AND (`Confirmed 20th Day CM`<>0 OR `Confirmed Total CM`<>0)
ORDER BY `Affiliate`
LIMIT 200;

-- 11) Caso ventana dia >=20 (ejecutar cuando aplique)
-- Esperado:
-- - `Confirmed 20th Day CM` = 0 para el ciclo actual.
-- - monto migrado a `Confirmed Total CM`.
CALL Report_balance_by_affiliate_dev('tmptable=yes,omit_0=no');
SELECT
   `Affiliate`,
   `Confirmed 20th Day CM`,
   `Confirmed Total CM`
FROM tmp_balance_by_affiliate
WHERE `Meta`='data'
ORDER BY `Affiliate`
LIMIT 200;
