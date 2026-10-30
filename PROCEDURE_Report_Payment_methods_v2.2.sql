/*
PROCEDURE_Report_Payment_methods_v2.2.sql - Report métodos de pago normalizados

Descripción:
  Muestra una tabla de payment methods a la vez (invoicing, card, bank, crypto, paypal),
  cada una con su propia fila setting y columnas de datos.
  Sin Table_Type (vacío o ALL) o con Filters=Yes: solo devuelve filtros.
  Con Table_Type concreto (y Affiliate_id opcional): datos de ese tipo.
  SQL estático (sin PREPARE). Incluye columna oculta table_type (omit=yes).

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples)

Keys:
  Affiliate_id = [ALL | id]. OPCIONAL. Default=ALL. Filtra por afiliado si se indica.
  Table_Type   = [ALL | invoicing | card | bank | crypto | paypal]. Default=ALL.
                 Con ALL/vacío solo filtros; valor concreto requerido para ver datos.
  Status       = [ALL | Status_value]. OPCIONAL. Default=ALL. Solo aplica a datos.
  Meta         = [No | Yes]. Default=Yes. Fila setting en datos.
  Filters      = [Yes | No]. Default=No. Si Yes (o Table_Type ALL/vacío), solo filtros.
  Debug        = [No | Yes | KeyValues]. Default=No.
                 Yes = mensaje de depuración sin datos; KeyValues = parámetros parseados.

Parámetros ('[Key=Value[,...]'])

Ejemplos:
  call Report_payment_methods('filters=yes');
  call Report_payment_methods('Table_Type=bank');
  call Report_payment_methods('Affiliate_id=39,Table_Type=bank,filters=yes');
  call Report_payment_methods('Affiliate_id=39,Table_Type=invoicing');
  call Report_payment_methods('Affiliate_id=39,Table_Type=card,debug=yes');
  call Report_payment_methods('Affiliate_id=39,Table_Type=paypal,Status=Active,debug=KeyValues');

30.03.2023 V1     Primera versión operativa
04.07.2025 v1.1   PayPal_email
04.07.2025 v1.2   Filtro Status
24.05.2026 v2.1   Tablas normalizadas; Table_Type; meta por tabla; SQL dinámico con "
22.07.2026 v2.2   Karen. Se agrega columna table_type; SQL estático; cabecera alineada al código
*/

DROP PROCEDURE IF EXISTS Report_payment_methods;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_payment_methods`(IN InputCommLine VARCHAR(250))
COMMENT 'v2.2 22.07.2026 - Report payment methods — tablas normalizadas por tipo'
SQL SECURITY DEFINER

proc_label:BEGIN

DECLARE v_Version VARCHAR(32) DEFAULT 'v2.2 22.07.2026';
DECLARE v_Affiliate_id VARCHAR(32) DEFAULT 'ALL';
DECLARE v_Table_Type VARCHAR(20) DEFAULT 'ALL';
DECLARE v_Status VARCHAR(30) DEFAULT 'ALL';
DECLARE v_Debug VARCHAR(16) DEFAULT 'NO';
DECLARE v_Filters VARCHAR(8) DEFAULT 'NO';
DECLARE v_Meta VARCHAR(8) DEFAULT 'YES';
DECLARE v_ShowData TINYINT DEFAULT 0;
DECLARE v_Affiliate_id_int INT DEFAULT NULL;

DECLARE v_InputCommLine VARCHAR(260);
DECLARE v_e INT;
DECLARE v_c INT;
DECLARE v_k VARCHAR(64);
DECLARE v_v VARCHAR(180);

SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

WHILE v_InputCommLine > ' ' DO
   SET v_e = INSTR(v_InputCommLine, '=');
   SET v_c = INSTR(v_InputCommLine, ',');
   SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
   SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
   SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

   IF LOWER(v_k) = 'affiliate_id' THEN SET v_Affiliate_id = v_v; END IF;
   IF LOWER(v_k) = 'table_type'   THEN SET v_Table_Type   = LOWER(v_v); END IF;
   IF LOWER(v_k) = 'status'       THEN SET v_Status       = v_v; END IF;
   IF LOWER(v_k) = 'filters'      THEN SET v_Filters      = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'meta'         THEN SET v_Meta         = UPPER(v_v); END IF;
   IF LOWER(v_k) = 'debug'        THEN SET v_Debug        = UPPER(v_v); END IF;
END WHILE;

IF v_Debug = 'KEYVALUES' THEN
   SELECT v_Version AS `Version`, v_Affiliate_id AS Affiliate_id, v_Table_Type AS Table_Type,
          v_Status AS Status, v_Filters AS Filters, v_Meta AS Meta, v_Debug AS Debug;
   LEAVE proc_label;
END IF;

IF v_Table_Type NOT IN ('', 'ALL') THEN
   SET v_ShowData = 1;
END IF;

IF v_Affiliate_id NOT IN ('', 'ALL') THEN
   SET v_Affiliate_id_int = CAST(v_Affiliate_id AS UNSIGNED);
END IF;

IF v_Debug = 'YES' THEN
   SELECT CONCAT('Report_payment_methods ', v_Version,
          ' — SQL estático (sin PREPARE); Table_Type=', v_Table_Type,
          '; Affiliate_id=', v_Affiliate_id) AS `Debug`;
   LEAVE proc_label;
END IF;

-- ---------------------------------------------------------------------------
-- Filtros (Filters=Yes, sin Table_Type, o Debug distinto de ejecución directa)
-- ---------------------------------------------------------------------------
IF v_Filters = 'YES' OR v_ShowData = 0 THEN

   WITH FilterSource AS (
      SELECT 'invoicing' AS `Table_Type`, T.`Affiliate_id`, T.`Affiliate`, T.`Status`
      FROM `account_payment_method_invoicing` T
      WHERE v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int
      UNION ALL
      SELECT 'card', T.`Affiliate_id`, T.`Affiliate`, T.`Status`
      FROM `account_payment_method_card` T
      WHERE v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int
      UNION ALL
      SELECT 'bank', T.`Affiliate_id`, T.`Affiliate`, T.`Status`
      FROM `account_payment_method_bank` T
      WHERE v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int
      UNION ALL
      SELECT 'crypto', T.`Affiliate_id`, T.`Affiliate`, T.`Status`
      FROM `account_payment_method_crypto` T
      WHERE v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int
      UNION ALL
      SELECT 'paypal', T.`Affiliate_id`, T.`Affiliate`, T.`Status`
      FROM `account_payment_method_paypal` T
      WHERE v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int
   )
   (SELECT '01' AS Korder, 'Data type' AS `Key`,
           CASE FS.`Table_Type`
              WHEN 'invoicing' THEN 'Invoicing company'
              WHEN 'card'      THEN 'Card'
              WHEN 'bank'      THEN 'Bank'
              WHEN 'crypto'    THEN 'Crypto'
              WHEN 'paypal'    THEN 'PayPal'
              ELSE FS.`Table_Type`
           END AS Value,
           'Table_Type' AS CallKey,
           FS.`Table_Type` AS CallValue,
           COUNT(*) AS `Rows`
    FROM FilterSource FS
    WHERE v_Affiliate_id_int IS NULL OR FS.`Affiliate_id` = v_Affiliate_id_int
    GROUP BY FS.`Table_Type`)
   UNION ALL
   (SELECT '02', 'Affiliate', FS.`Affiliate`, 'Affiliate_id', FS.`Affiliate_id`, COUNT(*)
    FROM FilterSource FS
    WHERE v_Table_Type IN ('', 'ALL') OR FS.`Table_Type` = v_Table_Type
    GROUP BY FS.`Affiliate_id`, FS.`Affiliate`)
   UNION ALL
   (SELECT '03', 'Status', IFNULL(FS.`Status`, ''), 'Status', IFNULL(FS.`Status`, ''), COUNT(*)
    FROM FilterSource FS
    WHERE (v_Affiliate_id_int IS NULL OR FS.`Affiliate_id` = v_Affiliate_id_int)
      AND (v_Table_Type IN ('', 'ALL') OR FS.`Table_Type` = v_Table_Type)
    GROUP BY IFNULL(FS.`Status`, ''))
   ORDER BY Korder ASC,
            CASE WHEN Korder IN ('01','02') THEN Value END ASC,
            CASE WHEN Korder NOT IN ('01','02') THEN Value END ASC;

   LEAVE proc_label;
END IF;

-- ---------------------------------------------------------------------------
-- Datos + meta por tipo (SQL estático, sin PREPARE)
-- ---------------------------------------------------------------------------

IF v_Table_Type = 'invoicing' THEN

   (SELECT 'setting'                 AS Meta,
           'width=80px,action=2'     AS `Action`,
           'omit=yes'                AS `id`,
           'omit=yes'                AS `Affiliate id`,
           'width=150px,tooltip=yes' AS `Affiliate`,
           'width=400px,tooltip=yes' AS `Description`,
           'width=150px,tooltip=yes' AS `Fiscal ID`,
           'width=120px,tooltip=yes' AS `VAT ID`,
           'width=180px,tooltip=yes' AS `Fiscal name`,
           'width=180px,tooltip=yes' AS `Address`,
           'width=90px'              AS `Country`,
           'width=90px,right=true'   AS `Verified`,
           'omit=yes'                AS `Status id`,
           'width=100px'             AS `Status`,
           'omit=yes'                AS `Creation_Date`,
           'width=150px'             AS `Last Update`,
           'width=100px'             AS `User`,
			  'omit=yes'                AS `table_type`   -- K 21.06.2026
    FROM DUAL
    WHERE v_Meta = 'YES')
   UNION ALL
   SELECT 'data' AS Meta, '...' AS `Action`,
          T.`id`, T.`Affiliate_id`, T.`Affiliate`, T.`Payment_Method_Description`,
          T.`company_fiscal_ID`, T.`company_VAT_ID`, T.`company_fiscal_name`,
          T.`company_address`, T.`company_country`, T.`verified`,
          T.`Status_id`, T.`Status`, T.`Creation_Date`,
          LEFT(IFNULL(T.`Last_Update`, ''), 19) AS `Last Update`, T.`User`
					,v_Table_Type     -- K 21.06.2026
   FROM `account_payment_method_invoicing` T
   WHERE (v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int)
     AND (v_Status = 'ALL' OR T.`Status` = v_Status)
   ORDER BY `Meta`, `Affiliate`, `Description`, `id`;

ELSEIF v_Table_Type = 'card' THEN

   (SELECT 'setting' AS Meta,
           'width=80px,action=2' AS `Action`,
           'omit=yes' AS `id`,
           'omit=yes' AS `Affiliate id`,
           'width=150px,tooltip=yes' AS `Affiliate`,
           'width=400px' AS `Description`,
           'omit=yes' AS `Preferred invoicing id`,
           'width=180px,tooltip=yes' AS `Invoicing Company`,
           'width=100px' AS `Card company`,
           'width=180px,tooltip=yes' AS `Owner name`,
           'width=180px,tooltip=yes' AS `Card number`,
           'width=110px' AS `Expiry date`,
           'width=80px,tooltip=yes' AS `CVV`,
           'width=90px,right=true' AS `Verified`,
           'omit=yes' AS `Status id`,
           'width=100px,tooltip=yes' AS `Status`,
           'omit=yes' AS `Creation_Date`,
           'width=150px' AS `Last Update`,
           'width=100px' AS `User`,
			  'omit=yes' AS `table_type`   -- K 21.06.2026
    FROM DUAL
    WHERE v_Meta = 'YES')
   UNION ALL
   SELECT 'data' AS Meta, '...' AS `Action`,
          T.`id`, T.`Affiliate_id`, T.`Affiliate`, T.`Payment_Method_Description`,
          T.`Preferred_invoicing_id`,
          I.`Payment_Method_Description` AS `Invoicing Company`,
          T.`Card_Company`, T.`Card_Owner_Name`, T.`Card_Owner_Number`,
          T.`Card_Expiry_Date`, T.`Card_CVV`, T.`verified`,
          T.`Status_id`, T.`Status`, T.`Creation_Date`,
          LEFT(IFNULL(T.`Last_Update`, ''), 19) AS `Last Update`, T.`User`
					,v_Table_Type     -- K 21.06.2026
   FROM `account_payment_method_card` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE (v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int)
     AND (v_Status = 'ALL' OR T.`Status` = v_Status)
   ORDER BY `Meta`, `Affiliate`, `Description`, `id`;

ELSEIF v_Table_Type = 'bank' THEN

   (SELECT 'setting' AS Meta,
           'width=80px,action=2' AS `Action`,
           'omit=yes' AS `id`,
           'width=100px' AS `Affiliate id`,
           'width=150px,tooltip=yes' AS `Affiliate`,
           'width=400px,tooltip=yes' AS `Description`,
           'omit=yes' AS `Preferred invoicing id`,
           'width=180px,tooltip=yes' AS `Invoicing Company`,
           'width=180px,tooltip=yes' AS `Bank name`,
           'width=250px' AS `IBAN`,
           'width=120px,tooltip=yes' AS `Swift`,
           'width=200px,tooltip=yes' AS `Recipient`,
           'width=90px,right=true' AS `Verified`,
           'omit=yes' AS `Status id`,
           'width=100px,tooltip=yes' AS `Status`,
           'omit=yes' AS `Creation_Date`,
           'width=150px' AS `Last Update`,
           'width=100px' AS `User`,
					 'omit=yes' AS `table_type`   -- K 21.06.2026
    FROM DUAL
    WHERE v_Meta = 'YES')
   UNION ALL
   SELECT 'data' AS Meta, '...' AS `Action`,
          T.`id`, T.`Affiliate_id`, T.`Affiliate`, T.`Payment_Method_Description`,
          T.`Preferred_invoicing_id`,
          I.`Payment_Method_Description` AS `Invoicing Company`,
          T.`Bank_Name`, T.`Bank_IBAN`, T.`Bank_Swift`, T.`Recipients_full_name`,
          T.`verified`, T.`Status_id`, T.`Status`, T.`Creation_Date`,
          LEFT(IFNULL(T.`Last_Update`, ''), 19) AS `Last Update`, T.`User`
					,v_Table_Type     -- K 21.06.2026
   FROM `account_payment_method_bank` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE (v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int)
     AND (v_Status = 'ALL' OR T.`Status` = v_Status)
   ORDER BY `Meta`, `Affiliate`, `Description`, `id`;

ELSEIF v_Table_Type = 'crypto' THEN

   (SELECT 'setting' AS Meta,
           'width=80px,action=2' AS `Action`,
           'omit=yes' AS `id`,
           'omit=yes' AS `Affiliate id`,
           'width=150px,tooltip=yes' AS `Affiliate`,
           'width=200px,tooltip=yes' AS `Description`,
           'omit=yes' AS `Preferred invoicing id`,
           'width=180px,tooltip=yes' AS `Invoicing Company`,
           'width=220px,tooltip=yes' AS `Wallet address`,
           'width=120px,tooltip=yes' AS `Network`,
           'width=120px,tooltip=yes' AS `Memo tag`,
           'width=90px,right=true' AS `Verified`,
           'omit=yes' AS `Status id`,
           'width=100px,tooltip=yes' AS `Status`,
           'omit=yes' AS `Creation_Date`,
           'width=150px' AS `Last Update`,
           'width=100px' AS `User`,
					 'omit=yes' AS `table_type`   -- K 21.06.2026
    FROM DUAL
    WHERE v_Meta = 'YES')
   UNION ALL
   SELECT 'data' AS Meta, '...' AS `Action`,
          T.`id`, T.`Affiliate_id`, T.`Affiliate`, T.`Payment_Method_Description`,
          T.`Preferred_invoicing_id`,
          I.`Payment_Method_Description` AS `Invoicing Company`,
          T.`Crypto_Wallet_Address`, T.`Crypto_Network`, T.`Crypto_memo_tag_ref`,
          T.`verified`, T.`Status_id`, T.`Status`, T.`Creation_Date`,
          LEFT(IFNULL(T.`Last_Update`, ''), 19) AS `Last Update`, T.`User`
					,v_Table_Type     -- K 21.06.2026
   FROM `account_payment_method_crypto` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE (v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int)
     AND (v_Status = 'ALL' OR T.`Status` = v_Status)
   ORDER BY `Meta`, `Affiliate`, `Description`, `id`;

ELSEIF v_Table_Type = 'paypal' THEN

   (SELECT 'setting' AS Meta,
           'width=80px,action=2' AS `Action`,
           'omit=yes' AS `id`,
           'omit=yes' AS `Affiliate id`,
           'width=150px,tooltip=yes' AS `Affiliate`,
           'width=200px,tooltip=yes' AS `Description`,
           'omit=yes' AS `Preferred invoicing id`,
           'width=180px,tooltip=yes' AS `Invoicing Company`,
           'width=220px,tooltip=yes' AS `PayPal email`,
           'width=90px,right=true' AS `Verified`,
           'omit=yes' AS `Status id`,
           'width=100px,tooltip=yes' AS `Status`,
           'omit=yes' AS `Creation_Date`,
           'width=150px' AS `Last Update`,
           'width=100px' AS `User`,
					 'omit=yes' AS `table_type`   -- K 21.06.2026
    FROM DUAL
    WHERE v_Meta = 'YES')
   UNION ALL
   SELECT 'data' AS Meta, '...' AS `Action`,
          T.`id`, T.`Affiliate_id`, T.`Affiliate`, T.`Payment_Method_Description`,
          T.`Preferred_invoicing_id`,
          I.`Payment_Method_Description` AS `Invoicing Company`,
          T.`PayPal_email`, T.`verified`, T.`Status_id`, T.`Status`, T.`Creation_Date`,
          LEFT(IFNULL(T.`Last_Update`, ''), 19) AS `Last Update`, T.`User`
					,v_Table_Type     -- K 21.06.2026
   FROM `account_payment_method_paypal` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE (v_Affiliate_id_int IS NULL OR T.`Affiliate_id` = v_Affiliate_id_int)
     AND (v_Status = 'ALL' OR T.`Status` = v_Status)
   ORDER BY `Meta`, `Affiliate`, `Description`, `id`;

END IF;

END$$
DELIMITER ;

/*
call Report_payment_methods('filters=yes');
call Report_payment_methods('Table_Type=bank');
call Report_payment_methods('Affiliate_id=39,Table_Type=bank,filters=yes');
call Report_payment_methods('Affiliate_id=39,Table_Type=invoicing');
call Report_payment_methods('Affiliate_id=39,Table_Type=card,debug=yes');
call Report_payment_methods('Affiliate_id=39,Table_Type=paypal,Status=Active,debug=KeyValues');
*/
