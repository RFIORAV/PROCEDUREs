/* PATCH TODAS LAS DB
   24.05.2024
*/

TRUNCATE multi_query;
-- TRUNCATE multi_query_account;
INSERT IGNORE INTO multi_query         SELECT * FROM euroaffiliati2.multi_query_20240524;
-- INSERT IGNORE INTO multi_query_account SELECT * FROM euroaffiliati2.multi_query_account_20240524;

REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`, `Procedure_call`, `Creation_Date`, `Last_Update`, `Operator`) 
VALUES (1, ' Affiliate\'s Balance Report', 'Report of Balance by affiliate', 'Reporte por Afiliado: Saldo actual', 'Resoconto per affiliato: Saldo attuale', 1
      , 'Report_balance_by_affiliate', 1, '', NULL, '2022-04-07 01:17:06', NOW(), 'SysOP')
      ,(13, ' Invoicing to Publisher', ' Invoicing to Publisher', 'Facturación al Publisher', 'Fatturazione all\'Operatore', 1
      , 'InvoiceToPubliser', 1, '', NULL, '2022-04-07 01:17:06', NOW(), 'SysOP')
;

DELETE FROM `multi_query` WHERE `id` IN (54,31,37);

-- SELECT * FROM 
UPDATE multi_query_account M SET multi_query_id=1 ,is_checked=1 WHERE multi_query_id=37;
UPDATE multi_query_account M SET multi_query_id=13,is_checked=1 WHERE multi_query_id=31;

DELETE FROM multi_query_account WHERE is_checked=0 OR multi_query_id=54;

-- Records apuntando a afiliados que no existen
DELETE M
FROM multi_query_account M
LEFT JOIN account_account A ON A.id=M.account_id
WHERE A.id IS null
;
-- Records duplicados
DELETE M
FROM multi_query_account M
INNER JOIN multi_query_account M1 
   ON M1.multi_query_id=M.multi_query_id AND M1.account_id=M.account_id
  AND M.id>M1.id
;
-- Records apuntando a multi_query que no existen
DELETE M
FROM multi_query_account M
LEFT JOIN multi_query A ON A.id=M.multi_query_id
WHERE A.id IS null
;

/*
DELETE cr1
  FROM customer_movie_rentals cr1
    INNER JOIN customer_movie_rentals cr2
      ON cr1.customer_id = cr2.customer_id
      AND cr1.rental_id > cr2.rental_id;
*/
