/*
PROCEDURE_Report_Payment_methods_v2.1.sql - Report métodos de pago normalizados

Descripción:
  Muestra una tabla de payment methods a la vez (invoicing, card, bank, crypto, paypal),
  cada una con su propia fila setting y columnas de datos.
  Sin Table_Type seleccionado solo devuelve filtros.
  Con Table_Type y sin Affiliate_id muestra todos los registros de ese tipo.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples)

Keys:
  Affiliate_id = [ALL | id]. OPCIONAL. Default=ALL. Filtra por afiliado si se indica.
  Table_Type   = [ALL | invoicing | card | bank | crypto | paypal]. OPCIONAL. Default=ALL. Obligatorio para ver datos.
  Status       = [ALL | Status_value]. OPCIONAL. Default=ALL
  Meta         = [No | Yes]. Default=Yes
  Filters      = [Yes | No]. Default=No. Si falta Table_Type, siempre devuelve filtros.
  Debug        = [No | Yes | KeyValues]. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:
  call Report_payment_methods('filters=yes');
  call Report_payment_methods('Affiliate_id=39,Table_Type=bank,filters=yes');
  call Report_payment_methods('Table_Type=bank');
  call Report_payment_methods('Affiliate_id=39,Table_Type=invoicing');
  call Report_payment_methods('Affiliate_id=39,Table_Type=bank');  
  call Report_payment_methods('Table_Type=bank'); 
  call Report_payment_methods('Affiliate_id=547,Table_Type=card,Status=Active,filters=yes,debug=yes');

30.03.2023 V1     Primera versión operativa
04.07.2025 v1.1   PayPal_email
04.07.2025 v1.2   Filtro Status
24.05.2026 v2.1   Tablas normalizadas; Table_Type; meta por tabla; SQL dinámico con "
*/

DROP PROCEDURE IF EXISTS Report_payment_methods;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_payment_methods`(IN InputCommLine VARCHAR(250))
COMMENT 'Report payment methods — tablas normalizadas por tipo'
SQL SECURITY DEFINER
proc_label:BEGIN

DECLARE v_Version VARCHAR(32) DEFAULT 'v2.1 24.05.2026';

SET @Affiliate_id = 'ALL';
SET @Table_Type    = 'ALL';
SET @Status        = 'ALL';
SET @Debug         = 'NO';
SET @Filters       = 'NO';
SET @Meta          = 'YES';
SET @ShowData      = 'NO';
SET @InputCommLine = CONCAT(InputCommLine, ',');
SET @InputCommLine = REPLACE(@InputCommLine, '"', '');
SET @WhereStatus   = '';
SET @WhereAffiliate = '';
SET @WhereFilterAffiliate = '';
SET @WhereFilterTable     = '';
SET @SQL             = '';
SET @SQLfilters      = '';
SET @SQLmeta         = '';
SET @SQLbody         = '';
SET @CTE             = '';

WHILE @InputCommLine > ' ' DO
   SET @e = INSTR(@InputCommLine, '=');
   SET @c = INSTR(@InputCommLine, ',');
   SET @k = TRIM(SUBSTRING(@InputCommLine, 1, @e - 1));
   SET @v = TRIM(SUBSTRING(@InputCommLine, @e + 1, @c - (@e + 1)));
   SET @InputCommLine = SUBSTRING(@InputCommLine, @c + 1);

   IF LOWER(@k) = 'affiliate_id' THEN SET @Affiliate_id = @v; END IF;
   IF LOWER(@k) = 'table_type'   THEN SET @Table_Type   = LOWER(@v); END IF;
   IF LOWER(@k) = 'status'       THEN SET @Status       = @v; END IF;
   IF LOWER(@k) = 'filters'      THEN SET @Filters      = UPPER(@v); END IF;
   IF LOWER(@k) = 'meta'         THEN SET @Meta         = UPPER(@v); END IF;
   IF LOWER(@k) = 'debug'        THEN SET @Debug         = UPPER(@v); END IF;
END WHILE;

IF @Debug = 'KEYVALUES' THEN
   SELECT v_Version AS `Version`, @Affiliate_id AS Affiliate_id, @Table_Type AS Table_Type,
          @Status AS Status, @Filters AS Filters, @Meta AS Meta, @Debug AS Debug;
   LEAVE proc_label;
END IF;

IF @Table_Type NOT IN ('', 'ALL') THEN
   SET @ShowData = 'YES';
END IF;

IF @Status != 'ALL' THEN
   SET @WhereStatus = CONCAT(' AND T.`Status` = "', REPLACE(@Status, '"', '""'), '"');
END IF;

IF @Affiliate_id NOT IN ('', 'ALL') THEN
   SET @WhereAffiliate = CONCAT(' AND T.`Affiliate_id` = ', @Affiliate_id);
   SET @WhereFilterAffiliate = CONCAT(' AND FS.`Affiliate_id` = ', @Affiliate_id);
END IF;

IF @Table_Type NOT IN ('', 'ALL') THEN
   SET @WhereFilterTable = CONCAT(' AND FS.`Table_Type` = "', REPLACE(@Table_Type, '"', '""'), '"');
END IF;

-- ---------------------------------------------------------------------------
-- Filtros: tipo de tabla, afiliado y status (respeta selección parcial)
-- ---------------------------------------------------------------------------
SET @SQLfilters = CONCAT('
WITH FilterSource AS (
   SELECT "invoicing" AS `Table_Type`, T.`Affiliate_id`, T.`Affiliate`, T.`Status` FROM `account_payment_method_invoicing` T
   WHERE 1=1 ', @WhereAffiliate,' UNION ALL
   SELECT "card", T.`Affiliate_id`, T.`Affiliate`, T.`Status` FROM `account_payment_method_card` T
   WHERE 1=1 ', @WhereAffiliate,' UNION ALL
   SELECT "bank", T.`Affiliate_id`, T.`Affiliate`, T.`Status` FROM `account_payment_method_bank` T
   WHERE 1=1 ', @WhereAffiliate,' UNION ALL
   SELECT "crypto", T.`Affiliate_id`, T.`Affiliate`, T.`Status` FROM `account_payment_method_crypto` T
   WHERE 1=1 ', @WhereAffiliate,' UNION ALL
   SELECT "paypal", T.`Affiliate_id`, T.`Affiliate`, T.`Status` FROM `account_payment_method_paypal` T
   WHERE 1=1 ', @WhereAffiliate,'
)
(SELECT "01" AS Korder, "Data type" AS `Key`,
        CASE FS.`Table_Type`
           WHEN "invoicing" THEN "Invoicing company"
           WHEN "card"      THEN "Card"
           WHEN "bank"      THEN "Bank"
           WHEN "crypto"    THEN "Crypto"
           WHEN "paypal"    THEN "PayPal"
           ELSE FS.`Table_Type`
        END AS Value,
        "Table_Type" AS CallKey,
        FS.`Table_Type` AS CallValue,
        COUNT(*) AS `Rows`
 FROM FilterSource FS
 WHERE 1=1 ', @WhereFilterAffiliate, '
 GROUP BY FS.`Table_Type`)
UNION ALL
(SELECT "02", "Affiliate", FS.`Affiliate`, "Affiliate_id", FS.`Affiliate_id`, COUNT(*)
 FROM FilterSource FS
 WHERE 1=1 ', @WhereFilterTable, '
 GROUP BY FS.`Affiliate_id`, FS.`Affiliate`)
UNION ALL
(SELECT "03", "Status", IFNULL(FS.`Status`, ""), "Status", IFNULL(FS.`Status`, ""), COUNT(*)
 FROM FilterSource FS
 WHERE 1=1 ', @WhereFilterAffiliate, @WhereFilterTable, '
 GROUP BY IFNULL(FS.`Status`, ""))
ORDER BY Korder ASC,
         CASE WHEN Korder IN ("01","02") THEN Value END ASC,
         CASE WHEN Korder NOT IN ("01","02") THEN Value END ASC
');

-- ---------------------------------------------------------------------------
-- Datos + meta por tipo de tabla
-- ---------------------------------------------------------------------------
IF @ShowData = 'YES' THEN

   IF @Table_Type = 'invoicing' THEN

      SET @CTE = CONCAT('
WITH Main_Table_Data AS (
   SELECT
      T.`id`,
      T.`Affiliate_id`,
      T.`Affiliate`,
      T.`Payment_Method_Description`,
      T.`company_fiscal_ID`,
      T.`company_VAT_ID`,
      T.`company_fiscal_name`,
      T.`company_address`,
      T.`company_country`,
      T.`verified`,
      T.`Status_id`,
      T.`Status`,
      T.`Creation_Date`,
      LEFT(IFNULL(T.`Last_Update`, ""), 19) AS `Last Update`,
      T.`User`
   FROM `account_payment_method_invoicing` T
   WHERE 1=1 ', @WhereAffiliate, @WhereStatus, '
)');

      SET @SQLmeta = CONCAT('(
SELECT
   "setting" AS Meta,
   "width=80px,action=2" AS `Action`,
   "omit=yes" AS `id`,
   "omit=yes" AS `Affiliate id`,
   "width=150px,tooltip=yes" AS `Affiliate`,
   "width=400px,tooltip=yes" AS `Description`,
   "width=150px,tooltip=yes" AS `Fiscal ID`,
   "width=120px,tooltip=yes" AS `VAT ID`,
   "width=180px,tooltip=yes" AS `Fiscal name`,
   "width=180px,tooltip=yes" AS `Address`,
   "width=90px" AS `Country`,
   "width=90px,right=true" AS `Verified`,
   "omit=yes" AS `Status id`,
   "width=100px" AS `Status`,
   "omit=yes" AS `Creation_Date`,
   "width=150px" AS `Last Update`,
   "width=100px" AS `User`
FROM DUAL WHERE "', @Meta, '" = "YES")
UNION ALL ');

      SET @SQLbody = '
SELECT "data" AS Meta, "..." AS `Action`, MT.*
FROM Main_Table_Data MT
ORDER BY `Meta`, `Affiliate`, `Description`, `id`
';

   ELSEIF @Table_Type = 'card' THEN

      SET @CTE = CONCAT('
WITH Main_Table_Data AS (
   SELECT
      T.`id`,
      T.`Affiliate_id`,
      T.`Affiliate`,
      T.`Payment_Method_Description`,
      T.`Preferred_invoicing_id`,
      I.`Payment_Method_Description` AS `Invoicing Company`,
      T.`Card_Company`,
      T.`Card_Owner_Name`,
      T.`Card_Owner_Number`,
      T.`Card_Expiry_Date`,
      T.`Card_CVV`,
      T.`verified`,
      T.`Status_id`,
      T.`Status`,
      T.`Creation_Date`,
      LEFT(IFNULL(T.`Last_Update`, ""), 19) AS `Last Update`,
      T.`User`
   FROM `account_payment_method_card` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE 1=1 ', @WhereAffiliate, @WhereStatus, '
)');

      SET @SQLmeta = CONCAT('(
SELECT
   "setting" AS Meta,
   "width=80px,action=2" AS `Action`,
   "omit=yes" AS `id`,
   "omit=yes" AS `Affiliate id`,
   "width=150px,tooltip=yes" AS `Affiliate`,
   "width=400px" AS `Description`,
   "omit=yes" AS `Preferred invoicing id`,
   "width=180px,tooltip=yes" AS `Invoicing Company`,
   "width=100px" AS `Card company`,
   "width=180px,tooltip=yes" AS `Owner name`,
   "width=180px,tooltip=yes" AS `Card number`,
   "width=110px" AS `Expiry date`,
   "width=80px,tooltip=yes" AS `CVV`,
   "width=90px,right=true" AS `Verified`,
   "omit=yes" AS `Status id`,
   "width=100px,tooltip=yes" AS `Status`,
   "omit=yes" AS `Creation_Date`,
   "width=150px" AS `Last Update`,
   "width=100px" AS `User`
FROM DUAL WHERE "', @Meta, '" = "YES")
UNION ALL ');

      SET @SQLbody = '
SELECT "data" AS Meta, "..." AS `Action`, MT.*
FROM Main_Table_Data MT
ORDER BY `Meta`, `Affiliate`, `Description`, `id`
';

   ELSEIF @Table_Type = 'bank' THEN

      SET @CTE = CONCAT('
WITH Main_Table_Data AS (
   SELECT
      T.`id`,
      T.`Affiliate_id`,
      T.`Affiliate`,
      T.`Payment_Method_Description`,
      T.`Preferred_invoicing_id`,
      I.`Payment_Method_Description` AS `Invoicing Company`,
      T.`Bank_Name`,
      T.`Bank_IBAN`,
      T.`Bank_Swift`,
      T.`Recipients_full_name`,
      T.`verified`,
      T.`Status_id`,
      T.`Status`,
      T.`Creation_Date`,
      LEFT(IFNULL(T.`Last_Update`, ""), 19) AS `Last Update`,
      T.`User`
   FROM `account_payment_method_bank` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE 1=1 ', @WhereAffiliate, @WhereStatus, '
)');

      SET @SQLmeta = CONCAT('(
SELECT
   "setting" AS Meta,
   "width=80px,action=2" AS `Action`,
   "omit=yes" AS `id`,
   "width=100px" AS `Affiliate id`,
   "width=150px,tooltip=yes" AS `Affiliate`,
   "width=400px,tooltip=yes" AS `Description`,
   "omit=yes" AS `Preferred invoicing id`,
   "width=180px,tooltip=yes" AS `Invoicing Company`,
   "width=180px,tooltip=yes" AS `Bank name`,
   "width=250px" AS `IBAN`,
   "width=120px,tooltip=yes" AS `Swift`,
   "width=200px,tooltip=yes" AS `Recipient`,
   "width=90px,right=true" AS `Verified`,
   "omit=yes" AS `Status id`,
   "width=100px,tooltip=yes" AS `Status`,
   "omit=yes" AS `Creation_Date`,
   "width=150px" AS `Last Update`,
   "width=100px" AS `User`
FROM DUAL WHERE "', @Meta, '" = "YES")
UNION ALL ');

      SET @SQLbody = '
SELECT "data" AS Meta, "..." AS `Action`, MT.*
FROM Main_Table_Data MT
ORDER BY `Meta`, `Affiliate`, `Description`, `id`
';

   ELSEIF @Table_Type = 'crypto' THEN

      SET @CTE = CONCAT('
WITH Main_Table_Data AS (
   SELECT
      T.`id`,
      T.`Affiliate_id`,
      T.`Affiliate`,
      T.`Payment_Method_Description`,
      T.`Preferred_invoicing_id`,
      I.`Payment_Method_Description` AS `Invoicing Company`,
      T.`Crypto_Wallet_Address`,
      T.`Crypto_Network`,
      T.`Crypto_memo_tag_ref`,
      T.`verified`,
      T.`Status_id`,
      T.`Status`,
      T.`Creation_Date`,
      LEFT(IFNULL(T.`Last_Update`, ""), 19) AS `Last Update`,
      T.`User`
   FROM `account_payment_method_crypto` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE 1=1 ', @WhereAffiliate, @WhereStatus, '
)');

      SET @SQLmeta = CONCAT('(
SELECT
   "setting" AS Meta,
   "width=80px,action=2" AS `Action`,
   "omit=yes" AS `id`,
   "omit=yes" AS `Affiliate id`,
   "width=150px,tooltip=yes" AS `Affiliate`,
   "width=200px,tooltip=yes" AS `Description`,
   "omit=yes" AS `Preferred invoicing id`,
   "width=180px,tooltip=yes" AS `Invoicing Company`,
   "width=220px,tooltip=yes" AS `Wallet address`,
   "width=120px,tooltip=yes" AS `Network`,
   "width=120px,tooltip=yes" AS `Memo tag`,
   "width=90px,right=true" AS `Verified`,
   "omit=yes" AS `Status id`,
   "width=100px,tooltip=yes" AS `Status`,
   "omit=yes" AS `Creation_Date`,
   "width=150px" AS `Last Update`,
   "width=100px" AS `User`
FROM DUAL WHERE "', @Meta, '" = "YES")
UNION ALL ');

      SET @SQLbody = '
SELECT "data" AS Meta, "..." AS `Action`, MT.*
FROM Main_Table_Data MT
ORDER BY `Meta`, `Affiliate`, `Description`, `id`
';

   ELSEIF @Table_Type = 'paypal' THEN

      SET @CTE = CONCAT('
WITH Main_Table_Data AS (
   SELECT
      T.`id`,
      T.`Affiliate_id`,
      T.`Affiliate`,
      T.`Payment_Method_Description`,
      T.`Preferred_invoicing_id`,
      I.`Payment_Method_Description` AS `Invoicing Company`,
      T.`PayPal_email`,
      T.`verified`,
      T.`Status_id`,
      T.`Status`,
      T.`Creation_Date`,
      LEFT(IFNULL(T.`Last_Update`, ""), 19) AS `Last Update`,
      T.`User`
   FROM `account_payment_method_paypal` T
   LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = T.`Preferred_invoicing_id`
   WHERE 1=1 ', @WhereAffiliate, @WhereStatus, '
)');

      SET @SQLmeta = CONCAT('(
SELECT
   "setting" AS Meta,
   "width=80px,action=2" AS `Action`,
   "omit=yes" AS `id`,
   "omit=yes" AS `Affiliate id`,
   "width=150px,tooltip=yes" AS `Affiliate`,
   "width=200px,tooltip=yes" AS `Description`,
   "omit=yes" AS `Preferred invoicing id`,
   "width=180px,tooltip=yes" AS `Invoicing Company`,
   "width=220px,tooltip=yes" AS `PayPal email`,
   "width=90px,right=true" AS `Verified`,
   "omit=yes" AS `Status id`,
   "width=100px,tooltip=yes" AS `Status`,
   "omit=yes" AS `Creation_Date`,
   "width=150px" AS `Last Update`,
   "width=100px" AS `User`
FROM DUAL WHERE "', @Meta, '" = "YES")
UNION ALL ');

      SET @SQLbody = '
SELECT "data" AS Meta, "..." AS `Action`, MT.*
FROM Main_Table_Data MT
ORDER BY `Meta`, `Affiliate`, `Description`, `id`
';

   ELSE
      SET @ShowData = 'NO';
   END IF;

END IF;

IF @ShowData = 'YES' AND @Filters != 'YES' AND @CTE > '' THEN
   SET @SQL = CONCAT(@CTE, @SQLmeta, @SQLbody);
ELSE
   SET @SQL = @SQLfilters;
END IF;

IF @Debug != 'NO' THEN SELECT @SQL; END IF;

IF @Debug != 'YES' THEN
   PREPARE stmt1 FROM @SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
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
