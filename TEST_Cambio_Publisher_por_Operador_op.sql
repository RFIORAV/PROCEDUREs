/*
TEST_Cambio_Publisher_por_Operador.sql

Propósito:
  Ejecución manual (MySQL 8.0.x) para validar los procedures tocados en el
  cambio de etiquetas Meta/filtros Publisher -> Operator (y User donde aplica).

Uso:
  Conectar a la base deseada (p. ej. euroaffiliati2 o affacc_dev) y ejecutar
  por bloques o completo. Los CALL usan filters=no (o omisión del listado de
  filtros) y filters=yes salvo donde el procedure no admite parámetro de entrada.

Notas:
  - Ajustar Affiliate_id, Publisher_id, Month, etc. si en su entorno no existen
    datos y algún listado devuelve vacío (no implica error de etiquetas).
  - Dash_Gestor_TotalByAdvertiser_dev y Report_MarketingSources1_dev suelen
    coexistir solo en entornos de desarrollo.
  - En producción suele desplegarse una sola versión de InvoiceToPubliser
    (v1.x o v1.2_bonus); el nombre de rutina es el mismo.

Historial:
  10.04.2026 v1.0 Script inicial
*/

-- Descomentar si corresponde:
-- USE euroaffiliati2;
SET NAMES utf8mb4;

/* =============================================================================
   Gestor_MonthlySources
   ============================================================================= */
SELECT 'Gestor_MonthlySources — sin filters=yes (listado datos)' AS test_step;
CALL Gestor_MonthlySources('filters=no,debug=no');

SELECT 'Gestor_MonthlySources — con filters=yes' AS test_step;
CALL Gestor_MonthlySources('filters=yes,debug=no');

/* =============================================================================
   Gestor_MonthlySources_dev
   ============================================================================= */
SELECT 'Gestor_MonthlySources_dev — sin filters=yes' AS test_step;
CALL Gestor_MonthlySources_dev('filters=no,debug=no');

SELECT 'Gestor_MonthlySources_dev — con filters=yes' AS test_step;
CALL Gestor_MonthlySources_dev('filters=yes,debug=no');

/* =============================================================================
   Gestor_YearlySources
   ============================================================================= */
SELECT 'Gestor_YearlySources — sin filters=yes' AS test_step;
CALL Gestor_YearlySources('filters=no,meta=yes');

SELECT 'Gestor_YearlySources — con filters=yes' AS test_step;
CALL Gestor_YearlySources('filters=yes,meta=yes');

/* =============================================================================
   Report_MarketingSources1
   ============================================================================= */
SELECT 'Report_MarketingSources1 — sin filters=yes' AS test_step;
CALL Report_MarketingSources1('Mode=Gestor,filters=no,debug=no');

SELECT 'Report_MarketingSources1 — con filters=yes' AS test_step;
CALL Report_MarketingSources1('Mode=Gestor,filters=yes,debug=no');

/* =============================================================================
   Report_MarketingSources1_dev
   ============================================================================= */
SELECT 'Report_MarketingSources1_dev — sin filters=yes' AS test_step;
CALL Report_MarketingSources1_dev('Mode=Gestor,filters=no,debug=no');

SELECT 'Report_MarketingSources1_dev — con filters=yes' AS test_step;
CALL Report_MarketingSources1_dev('Mode=Gestor,filters=yes,debug=no');

/* =============================================================================
   InvoiceToPubliser
   ============================================================================= */
SELECT 'InvoiceToPubliser — sin filters=yes' AS test_step;
CALL InvoiceToPubliser('month=LM,filters=no,debug=no');

SELECT 'InvoiceToPubliser — con filters=yes' AS test_step;
CALL InvoiceToPubliser('month=LM,filters=yes,debug=no');

/* =============================================================================
   Dash_Gestor_TotalByAdvertiser
   ============================================================================= */
SELECT 'Dash_Gestor_TotalByAdvertiser — sin filters=yes' AS test_step;
CALL Dash_Gestor_TotalByAdvertiser('filters=no,debug=no');

SELECT 'Dash_Gestor_TotalByAdvertiser — con filters=yes' AS test_step;
CALL Dash_Gestor_TotalByAdvertiser('filters=yes,debug=no');

/* =============================================================================
   Dash_Gestor_TotalByAdvertiser_dev
   ============================================================================= */
SELECT 'Dash_Gestor_TotalByAdvertiser_dev — sin filters=yes' AS test_step;
CALL Dash_Gestor_TotalByAdvertiser_dev('filters=no,debug=no');

SELECT 'Dash_Gestor_TotalByAdvertiser_dev — con filters=yes' AS test_step;
CALL Dash_Gestor_TotalByAdvertiser_dev('filters=yes,debug=no');

/* =============================================================================
   Report_Publisher_invoices
   ============================================================================= */
SELECT 'Report_Publisher_invoices — sin filters=yes' AS test_step;
CALL Report_Publisher_invoices('filters=no,debug=no');

SELECT 'Report_Publisher_invoices — con filters=yes' AS test_step;
CALL Report_Publisher_invoices('filters=yes,debug=no');

/* =============================================================================
   Report_Brands
   ============================================================================= */
SELECT 'Report_Brands — sin filters=yes' AS test_step;
CALL Report_Brands('filters=no,debug=no');

SELECT 'Report_Brands — con filters=yes' AS test_step;
CALL Report_Brands('filters=yes,debug=no');

/* =============================================================================
   Report_Accounts
   ============================================================================= */
SELECT 'Report_Accounts — sin filters=yes' AS test_step;
CALL Report_Accounts('filters=no,debug=no');

SELECT 'Report_Accounts — con filters=yes' AS test_step;
CALL Report_Accounts('filters=yes,debug=no');

/* =============================================================================
   Report_Campaigns
   ============================================================================= */
SELECT 'Report_Campaigns — sin filters=yes' AS test_step;
CALL Report_Campaigns('filters=no,debug=no');

SELECT 'Report_Campaigns — con filters=yes' AS test_step;
CALL Report_Campaigns('filters=yes,debug=no');

/* =============================================================================
   Aff_MarketingSources -  ERROR
   ============================================================================= */
SELECT 'Aff_MarketingSources — sin filters=yes' AS test_step;
CALL Aff_MarketingSources('Month=LM,filters=no,debug=no');

SELECT 'Aff_MarketingSources — con filters=yes' AS test_step;
CALL Aff_MarketingSources('Month=LM,filters=yes,debug=no');

/* =============================================================================
   Report_MS_Rebrandly
   ============================================================================= */
SELECT 'Report_MS_Rebrandly — sin filters=yes' AS test_step;
CALL Report_MS_Rebrandly('filters=no,debug=no');

SELECT 'Report_MS_Rebrandly — con filters=yes' AS test_step;
CALL Report_MS_Rebrandly('filters=yes,debug=no');

/* =============================================================================
   Report_Publisher_ManAdj
   ============================================================================= */
SELECT 'Report_Publisher_ManAdj — sin filters=yes' AS test_step;
CALL Report_Publisher_ManAdj('filters=no,debug=no');

SELECT 'Report_Publisher_ManAdj — con filters=yes' AS test_step;
CALL Report_Publisher_ManAdj('filters=yes,debug=no');

/* =============================================================================
   Publisher_balance_to_Proforma
   ============================================================================= */
SELECT 'Publisher_balance_to_Proforma — sin filters=yes' AS test_step;
CALL Publisher_balance_to_Proforma('month=LM,filters=no,debug=no');

SELECT 'Publisher_balance_to_Proforma — con filters=yes' AS test_step;
CALL Publisher_balance_to_Proforma('month=LM,filters=yes,debug=no');

/* =============================================================================
   Report_Publisher_Interactions
   ============================================================================= */
SELECT 'Report_Publisher_Interactions — sin filters=yes' AS test_step;
CALL Report_Publisher_Interactions('filters=no,debug=no');

SELECT 'Report_Publisher_Interactions — con filters=yes' AS test_step;
CALL Report_Publisher_Interactions('filters=yes,debug=no');

/* =============================================================================
   Dash_Gestor_ProfitByAff
   ============================================================================= */
SELECT 'Dash_Gestor_ProfitByAff — sin filters=yes' AS test_step;
CALL Dash_Gestor_ProfitByAff('param=cpa,publisher_id=all,advertiser_id=all,filters=no,meta=no,debug=no');

SELECT 'Dash_Gestor_ProfitByAff — con filters=yes' AS test_step;
CALL Dash_Gestor_ProfitByAff('param=cpa,publisher_id=all,advertiser_id=all,filters=yes,meta=no,debug=no');

/* =============================================================================
   Report_bonus_gestor
   ============================================================================= */
SELECT 'Report_bonus_gestor — sin filters=yes' AS test_step;
CALL Report_bonus_gestor('Filters=no');

SELECT 'Report_bonus_gestor — con Filters=yes' AS test_step;
CALL Report_bonus_gestor('Filters=yes');

/* =============================================================================
   Report_Publisher
   ============================================================================= */
SELECT 'Report_Publisher — sin filters=yes' AS test_step;
CALL Report_Publisher('filters=no,debug=no');

SELECT 'Report_Publisher — con filters=yes' AS test_step;
CALL Report_Publisher('filters=yes,debug=no');

/* =============================================================================
   Report_Cashflow
   ============================================================================= */
SELECT 'Report_Cashflow — sin filters=yes' AS test_step;
CALL Report_Cashflow('filters=no');

SELECT 'Report_Cashflow — con filters=yes' AS test_step;
CALL Report_Cashflow('filters=yes');

/* =============================================================================
   Check_DbD / Check_DbD_dev  (sin parámetro InputCommLine: no aplica filters)
   ============================================================================= */
SELECT 'Check_DbD — sin parámetro (no hay filters=yes)' AS test_step;
CALL Check_DbD();

SELECT 'Check_DbD_dev — sin parámetro (no hay filters=yes)' AS test_step;
CALL Check_DbD_dev();

/* =============================================================================
   lite_Info_for_graph
   ============================================================================= */
SELECT 'lite_Info_for_graph — sin filters=yes' AS test_step;
CALL lite_Info_for_graph('month=CM,InfoSource=Comms,info_by=Brand,filters=no,meta=yes,debug=no');

SELECT 'lite_Info_for_graph — con filters=yes' AS test_step;
CALL lite_Info_for_graph('filters=yes,debug=no');

/* =============================================================================
   lite_Info_for_graph_v2
   ============================================================================= */
SELECT 'lite_Info_for_graph_v2 — sin filters=yes' AS test_step;
CALL lite_Info_for_graph_v2('month=LM,InfoSource=Comms,InfoBy=Brand,Component=VerticalBarChart');

SELECT 'lite_Info_for_graph_v2 — con filters=yes' AS test_step;
CALL lite_Info_for_graph_v2('filters=yes');

/* =============================================================================
   Report_Affiliate_Tags  (Meta: Operator -> User)
   ============================================================================= */
SELECT 'Report_Affiliate_Tags — sin filters=yes' AS test_step;
CALL Report_Affiliate_Tags('filters=no,meta=yes,debug=no');

SELECT 'Report_Affiliate_Tags — con Filters=yes' AS test_step;
CALL Report_Affiliate_Tags('Filters=yes,meta=yes,debug=no');

/* =============================================================================
   Report_Economics_Affiliate_dev
   ============================================================================= */
SELECT 'Report_Economics_Affiliate_dev — sin filters=yes' AS test_step;
CALL Report_Economics_Affiliate_dev('Affiliate_id=39,filters=no,meta=yes,debug=no');

SELECT 'Report_Economics_Affiliate_dev — con filters=yes' AS test_step;
CALL Report_Economics_Affiliate_dev('Affiliate_id=39,filters=yes,meta=yes,debug=no');

SELECT 'TEST_Cambio_Publisher_por_Operador — fin' AS test_step;
