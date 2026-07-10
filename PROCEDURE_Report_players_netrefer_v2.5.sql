/*
PROCEDURE_Report_players_netrefer_v2.5.sql

Descripción:
  Wrapper de Report_players_netrefer. Desvía la ejecución a Report_players_general
  reenviando el mismo InputCommLine sin transformación.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | id de Affiliate]. OPCIONAL. Default=ALL.
Data_Month      =[ALL | fecha en formato YYYY-MM]. OPCIONAL. Default=ALL.
Advertiser_id   =[ALL | id de Advertiser]. OPCIONAL. Default=ALL.
Account         =[ALL | id de Account]. OPCIONAL. Default=ALL.
Tracker_name    =[ALL | nombre de Tracker]. OPCIONAL. Default=ALL.
Signup_month    =[ALL | fecha en formato YYYY-MM]. OPCIONAL. Default=ALL.
Customer_ID     =[ALL | id de Customer]. OPCIONAL. Default=ALL.
Show_products   =[Yes | No]. Devuelve los productos. OPCIONAL. Default=no.

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
GenIdx          =[No | Yes]. OPCIONAL. Si es Yes, regenera players_general_API_idx (TRUNCATE + recarga). Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_players_netrefer('debug=ye');
call Report_players_netrefer('debug=ye,filters=yeS');
call Report_players_netrefer('debug=ye,filters=ye,Advertiser_id=15');
call Report_players_netrefer('debug=ye,filters=ye,Advertiser_id=15,show_products=yes');
call Report_players_netrefer('debug=ye,filters=ye,CPA_Month=2025-05,Advertiser_id=15');
call Report_players_netrefer('debug=ye,filters=yes,Affiliate_id=39');
call Report_players_netrefer('genidx=yes,debug=YE');

14.01.2025 V1     Primera versión operativa
14.03.2025 v2     Cambio tabla players_netrefer por players_netrefer_API
27.03.2025 v2.1   Filtro por Signup_month y Customer_ID
04.04.2025 v2.2   Optimización: reemplazo de GROUP BY por DISTINCT en filters
16.06.2025 v2.3   Añadido filtro por CPA_month
26.03.2026 v2.4   Añadida tabla players_netrefer_API_idx para optimizar el rendimiento
                  Nuevo parámetro GenIdx=Yes para truncar y regenerar players_netrefer_API_idx
16.06.2026 v2.5   Desvío de ejecución a Report_players_general (wrapper)

*/

DROP PROCEDURE IF EXISTS Report_players_netrefer;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_players_netrefer`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v2.5 16.06.2026 Report Affiliate Interactions — wrapper de Report_players_general'
SQL SECURITY DEFINER
proc_label:BEGIN
DECLARE v_Version            VARCHAR(50);

SET v_Version         ='v2.5 16.06.2026';

CALL Report_players_general(InputCommLine);
LEAVE proc_label;

END$$
DELIMITER ;
