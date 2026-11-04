/*
TEST_PROCEDURE_Report_Dbd_Acum_All_v1.sql
Pruebas minimas para Report_Dbd_Acum_All (v1.1 24.09.2026)

Objetivo:
- Validar ejecucion basica y drill-down progresivo.
- Validar filtros, opciones Meta/Filters y modos Debug.
- Validar mensajes de error por parametros invalidos.

Notas:
- Date siempre aplica (default=CURDATE()).
- Drill: Date→Operator→Advertiser→Account→MS (valor <> ALL).
- Ejecutar primero PROCEDURE_Report_Dbd_Acum_All_v1.1.sql para crear el SP.
*/

-- 1) Solo Date: totales por Operator
CALL Report_Dbd_Acum_All('');
CALL Report_Dbd_Acum_All('Date=2026-09-22,meta=no');

-- 2) Date + Operator_id: totales por Advertiser
CALL Report_Dbd_Acum_All('Date=2026-09-22,Operator_id=17,meta=no');

-- 3) Date + Operator + Advertiser: totales por Account
CALL Report_Dbd_Acum_All('Date=2026-09-22,Operator_id=17,Advertiser_id=5,meta=no');

-- 4) Date + Operator + Advertiser + Account: totales por MS
CALL Report_Dbd_Acum_All('Date=2026-09-22,Operator_id=17,Advertiser_id=5,Account_id=ABC,meta=no');

-- 5) Debug / Filters / Meta
CALL Report_Dbd_Acum_All('debug=yes');
CALL Report_Dbd_Acum_All('debug=keyvalues');
CALL Report_Dbd_Acum_All('filters=yes');
CALL Report_Dbd_Acum_All('meta=no');

-- 6) Errores esperados
CALL Report_Dbd_Acum_All('Date=23-09-2026');
CALL Report_Dbd_Acum_All('Affiliate_id=abc');
CALL Report_Dbd_Acum_All('MS_id=XYZ');
