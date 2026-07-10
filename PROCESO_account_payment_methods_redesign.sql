/*
TABLE_account_payment_methods_redesign.sql

Rediseño normalizado de account_payment_methods.
Sin tabla de enlace: cada registro de detalle es autónomo y referencia su invoicing company.

Modelo:
  - account_payment_method_invoicing: N empresas de facturación por afiliado
  - account_payment_method_{card|bank|crypto|paypal}: N métodos por afiliado, cada uno
    vinculado a una invoicing company via invoicing_id
  - Combinación lógica por tipo: (Affiliate_id, invoicing_id) en tablas de pago

Notas:
  - Todas las tablas comparten cabecera: id, Affiliate_id, Affiliate,
    Payment_Method_Description, Status_id, Status, verified, tracking
  - verified (Admin Approval) en cada tabla
  - Sin foreign keys ni constraints (unicidad e integridad en capa de aplicación)
  - sub_account_* se crean con LIKE tras desplegar el esquema base

24.05.2026 v1   Rediseño normalizado inicial
24.05.2026 v1.1 id AUTO_INCREMENT y tracking en todas las tablas
24.05.2026 v1.2 account_payment_methods como tabla de enlace; sin payment_method_id en hijas
24.05.2026 v1.3 verified en cada detalle e invoicing; sin ENGINE/CHARSET explícito
24.05.2026 v1.4 eliminada account_payment_methods; cabecera común en cada tabla
24.05.2026 v1.5 sin foreign keys ni constraints
24.05.2026 v1.6 INSERT migración invoicing desde account_account
24.05.2026 v1.7 INSERT migración card/bank/crypto/paypal desde account_payment_methods
*/

DROP VIEW IF EXISTS `view_account_payment_methods`;
-- DROP TABLE IF EXISTS `account_payment_methods`;
DROP TABLE IF EXISTS `account_payment_method_invoicing`;
DROP TABLE IF EXISTS `account_payment_method_paypal`;
DROP TABLE IF EXISTS `account_payment_method_crypto`;
DROP TABLE IF EXISTS `account_payment_method_bank`;
DROP TABLE IF EXISTS `account_payment_method_card`;

-- ---------------------------------------------------------------------------
-- Invoicing Company data — N empresas de facturación por afiliado
-- ---------------------------------------------------------------------------
CREATE TABLE `account_payment_method_invoicing` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id` INT NOT NULL,
   `Affiliate` VARCHAR(80) NOT NULL,
   `Payment_Method_Description` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej Anatriello SL - B12345678',
   `company_fiscal_ID` VARCHAR(30) NULL DEFAULT NULL COMMENT 'old fiscal_code',
   `company_VAT_ID` VARCHAR(60) NULL DEFAULT NULL COMMENT 'old iva',
   `company_fiscal_name` VARCHAR(60) NULL DEFAULT NULL,
   `company_address` VARCHAR(60) NULL DEFAULT NULL,
   `company_country` VARCHAR(2) NULL DEFAULT NULL COMMENT 'old country',
   -- Admin Approval check
   `verified` TINYINT NULL DEFAULT NULL,
   -- Record status (enabled/disabled)
   `Status_id` VARCHAR(2) NULL DEFAULT NULL,
   `Status` VARCHAR(30) NULL DEFAULT NULL,
   -- Common user's tracking data
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User` VARCHAR(30) NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_apmi_affiliate` (`Affiliate_id`)
);

-- Migración: empresas de facturación desde datos fiscales en account_account
INSERT INTO `account_payment_method_invoicing` (
   `Affiliate_id`,
   `Affiliate`,
   `Payment_Method_Description`,
   `company_fiscal_ID`,
   `company_VAT_ID`,
   `company_fiscal_name`,
   `company_address`,
   `company_country`
)
SELECT
   A.`id`,
   A.`username`,
   TRIM(CONCAT(COALESCE(NULLIF(TRIM(A.`company_fiscal_name`), ''), A.`username`))),
   NULLIF(TRIM(A.`fiscal_code`), ''),
   NULLIF(TRIM(A.`iva`), ''),
   NULLIF(TRIM(A.`company_fiscal_name`), ''),
   LEFT(TRIM(CONCAT_WS(', ', NULLIF(TRIM(A.`company_address`), ''), NULLIF(TRIM(A.`city`), ''))), 60),
   NULLIF(TRIM(A.`nation`), '')
FROM `account_account` A
WHERE NULLIF(TRIM(A.`fiscal_code`), '') IS NOT NULL
   OR NULLIF(TRIM(A.`iva`), '') IS NOT NULL
   OR NULLIF(TRIM(A.`company_fiscal_name`), '') IS NOT NULL
   OR NULLIF(TRIM(A.`company_address`), '') IS NOT NULL
;

-- ---------------------------------------------------------------------------
-- Credit card data
-- ---------------------------------------------------------------------------
CREATE TABLE `account_payment_method_card` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id` INT NOT NULL,
   `Affiliate` VARCHAR(80) NOT NULL,
   `Payment_Method_Description` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej Anatriello SL - VISAXXXXXXXX',
   `Preferred_invoicing_id` INT NULL DEFAULT NULL,
   `Card_Company` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej VISA/AMEX/MASTERCARD/...',
   `Card_Owner_Name` LONGTEXT NULL DEFAULT NULL,
   `Card_Owner_Number` LONGTEXT NULL DEFAULT NULL,
   `Card_Expiry_Date` DATE NULL DEFAULT NULL,
   `Card_CVV` VARCHAR(3) NULL DEFAULT NULL,
   -- Admin Approval check
   `verified` TINYINT NULL DEFAULT NULL,
   -- Record status (enabled/disabled)
   `Status_id` VARCHAR(2) NULL DEFAULT NULL,
   `Status` VARCHAR(30) NULL DEFAULT NULL,
   -- Common user's tracking data
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User` VARCHAR(30) NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_apmc_affiliate` (`Affiliate_id`),
   KEY `idx_apmc_invoicing` (`Preferred_invoicing_id`)
);

-- ---------------------------------------------------------------------------
-- Bank account data
-- ---------------------------------------------------------------------------
CREATE TABLE `account_payment_method_bank` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id` INT NOT NULL,
   `Affiliate` VARCHAR(80) NOT NULL,
   `Payment_Method_Description` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej Anatriello SL - IBANXXXXXXXX',
   `Preferred_invoicing_id` INT NULL DEFAULT NULL,
   `Bank_Name` VARCHAR(100) NULL DEFAULT NULL,
   `Bank_IBAN` VARCHAR(100) NULL DEFAULT NULL,
   `Bank_Swift` VARCHAR(20) NULL DEFAULT NULL,
   `Recipients_full_name` LONGTEXT NULL DEFAULT NULL COMMENT 'old Owner_Address',
   -- Admin Approval check
   `verified` TINYINT NULL DEFAULT NULL,
   -- Record status (enabled/disabled)
   `Status_id` VARCHAR(2) NULL DEFAULT NULL,
   `Status` VARCHAR(30) NULL DEFAULT NULL,
   -- Common user's tracking data
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User` VARCHAR(30) NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_apmb_affiliate` (`Affiliate_id`),
   KEY `idx_apmb_invoicing` (`Preferred_invoicing_id`)
);

-- ---------------------------------------------------------------------------
-- Crypto account data
-- ---------------------------------------------------------------------------
CREATE TABLE `account_payment_method_crypto` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id` INT NOT NULL,
   `Affiliate` VARCHAR(80) NOT NULL,
   `Payment_Method_Description` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej Anatriello SL - WALLETXXXXXXXX',
   `Preferred_invoicing_id` INT NULL DEFAULT NULL,
   `Crypto_Wallet_Address` VARCHAR(100) NULL DEFAULT NULL COMMENT 'old Crypto_Address',
   `Crypto_Network` VARCHAR(100) NULL DEFAULT NULL COMMENT 'old Crypto_Type',
   `Crypto_memo_tag_ref` VARCHAR(100) NULL DEFAULT NULL,
   -- Admin Approval check
   `verified` TINYINT NULL DEFAULT NULL,
   -- Record status (enabled/disabled)
   `Status_id` VARCHAR(2) NULL DEFAULT NULL,
   `Status` VARCHAR(30) NULL DEFAULT NULL,
   -- Common user's tracking data
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User` VARCHAR(30) NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_apmcr_affiliate` (`Affiliate_id`),
   KEY `idx_apmcr_invoicing` (`Preferred_invoicing_id`)
);

-- ---------------------------------------------------------------------------
-- Paypal data
-- ---------------------------------------------------------------------------
CREATE TABLE `account_payment_method_paypal` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Affiliate_id` INT NOT NULL,
   `Affiliate` VARCHAR(80) NOT NULL,
   `Payment_Method_Description` VARCHAR(100) NULL DEFAULT NULL COMMENT 'Ej Anatriello SL - PAYPALXXXXXXXX',
   `Preferred_invoicing_id` INT NULL DEFAULT NULL,
   `PayPal_email` VARCHAR(100) NULL DEFAULT NULL,
   -- Admin Approval check
   `verified` TINYINT NULL DEFAULT NULL,
   -- Record status (enabled/disabled)
   `Status_id` VARCHAR(2) NULL DEFAULT NULL,
   `Status` VARCHAR(30) NULL DEFAULT NULL,
   -- Common user's tracking data
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User` VARCHAR(30) NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_apmp_affiliate` (`Affiliate_id`),
   KEY `idx_apmp_invoicing` (`Preferred_invoicing_id`)
);

-- ---------------------------------------------------------------------------
-- Migración: métodos de pago desde account_payment_methods (tabla legacy)
-- Requiere que account_payment_methods exista (DROP comentado arriba).
-- Enrutamiento mutuamente excluyente: PayPal > Crypto > Bank > Card.
-- Preferred_invoicing_id: principal empresa de facturación del afiliado, si existe.
-- ---------------------------------------------------------------------------

INSERT INTO `account_payment_method_paypal` (
   `Affiliate_id`,
   `Affiliate`,
   `Payment_Method_Description`,
   `Preferred_invoicing_id`,
   `PayPal_email`,
   `Status_id`,
   `Status`,
   `Creation_Date`,
   `Last_Update`,
   `User`
)
SELECT
   PM.`Account_id`,
   A.`username`,
   LEFT(TRIM(CONCAT(
      COALESCE(NULLIF(TRIM(I.`Payment_Method_Description`), ''), A.`username`),
      ' - ',
      COALESCE(NULLIF(TRIM(PM.`PayPal_email`), ''), PM.`id`)
   )), 100),
   I.`id`,
   NULLIF(TRIM(PM.`PayPal_email`), ''),
   PM.`Status_id`,
   PM.`Status`,
   PM.`Creation_Date`,
   PM.`Last_Update`,
   PM.`Operator`
FROM `account_payment_methods` PM
INNER JOIN `account_account` A ON A.`id` = PM.`Account_id`
LEFT JOIN `account_account` U ON U.`id` = PM.`Operator`
LEFT JOIN `account_payment_method_invoicing` I
   ON I.`Affiliate_id` = PM.`Account_id`
   AND I.`id` = (
      SELECT MIN(I2.`id`)
      FROM `account_payment_method_invoicing` I2
      WHERE I2.`Affiliate_id` = PM.`Account_id`
   )
WHERE NULLIF(TRIM(PM.`PayPal_email`), '') IS NOT NULL;

INSERT INTO `account_payment_method_crypto` (
   `Affiliate_id`,
   `Affiliate`,
   `Payment_Method_Description`,
   `Preferred_invoicing_id`,
   `Crypto_Wallet_Address`,
   `Crypto_Network`,
   `Crypto_memo_tag_ref`,
   `Status_id`,
   `Status`,
   `Creation_Date`,
   `Last_Update`,
   `User`
)
SELECT
   PM.`Account_id`,
   A.`username`,
   LEFT(TRIM(CONCAT(
      COALESCE(NULLIF(TRIM(I.`Payment_Method_Description`), ''), A.`username`),
      ' - ',NULLIF(TRIM(PM.`Crypto_Type`), ''),' - ',
      COALESCE(NULLIF(TRIM(PM.`Crypto_Address`), ''), PM.`id`)
   )), 100),
   I.`id`,
   NULLIF(TRIM(PM.`Crypto_Address`), ''),
   NULLIF(TRIM(PM.`Crypto_Type`), ''),
   NULL,
   PM.`Status_id`,
   PM.`Status`,
   PM.`Creation_Date`,
   PM.`Last_Update`,
   PM.`Operator`
FROM `account_payment_methods` PM
INNER JOIN `account_account` A ON A.`id` = PM.`Account_id`
LEFT JOIN `account_account` U ON U.`id` = PM.`Operator`
LEFT JOIN `account_payment_method_invoicing` I
   ON I.`Affiliate_id` = PM.`Account_id`
   AND I.`id` = (
      SELECT MIN(I2.`id`)
      FROM `account_payment_method_invoicing` I2
      WHERE I2.`Affiliate_id` = PM.`Account_id`
   )
WHERE (
         NULLIF(TRIM(PM.`Crypto_Address`), '') IS NOT NULL
      OR NULLIF(TRIM(PM.`Crypto_Type`), '') IS NOT NULL
   )
;

INSERT INTO `account_payment_method_bank` (
   `Affiliate_id`,
   `Affiliate`,
   `Payment_Method_Description`,
   `Preferred_invoicing_id`,
   `Bank_Name`,
   `Bank_IBAN`,
   `Bank_Swift`,
   `Recipients_full_name`,
   `Status_id`,
   `Status`,
   `Creation_Date`,
   `Last_Update`,
   `User`
)
SELECT
   PM.`Account_id`,
   A.`username`,
   LEFT(TRIM(CONCAT(
      COALESCE(NULLIF(TRIM(I.`Payment_Method_Description`), ''), A.`username`),
      ' - ',NULLIF(TRIM(PM.`Bank_Name`), ''),' - ',
      COALESCE(NULLIF(TRIM(PM.`Bank_IBAN`), ''), PM.`id`)
   )), 100),
   I.`id`,
   NULLIF(TRIM(PM.`Bank_Name`), ''),
   NULLIF(TRIM(PM.`Bank_IBAN`), ''),
   NULLIF(TRIM(PM.`Bank_Swift`), ''),
   NULLIF(TRIM(PM.`Owner_Address`), ''),
   PM.`Status_id`,
   PM.`Status`,
   PM.`Creation_Date`,
   PM.`Last_Update`,
   PM.`Operator`
FROM `account_payment_methods` PM
INNER JOIN `account_account` A ON A.`id` = PM.`Account_id`
LEFT JOIN `account_account` U ON U.`id` = PM.`Operator`
LEFT JOIN `account_payment_method_invoicing` I
   ON I.`Affiliate_id` = PM.`Account_id`
   AND I.`id` = (
      SELECT MIN(I2.`id`)
      FROM `account_payment_method_invoicing` I2
      WHERE I2.`Affiliate_id` = PM.`Account_id`
   )
WHERE (
         NULLIF(TRIM(PM.`Bank_IBAN`), '') IS NOT NULL
      OR NULLIF(TRIM(PM.`Bank_Name`), '') IS NOT NULL
   )
;

INSERT INTO `account_payment_method_card` (
   `Affiliate_id`,
   `Affiliate`,
   `Payment_Method_Description`,
   `Preferred_invoicing_id`,
   `Card_Owner_Name`,
   `Card_Owner_Number`,
   `Card_Expiry_Date`,
   `Card_CVV`,
   `Status_id`,
   `Status`,
   `Creation_Date`,
   `Last_Update`,
   `User`
)
SELECT
   PM.`Account_id`,
   A.`username`,
   LEFT(TRIM(CONCAT(
      COALESCE(NULLIF(TRIM(I.`Payment_Method_Description`), ''), A.`username`),
      ' - ',
      COALESCE(NULLIF(TRIM(PM.`Card_Owner_Number`), ''), PM.`id`)
   )), 100),
   I.`id`,
   NULLIF(TRIM(PM.`Card_Owner_Name`), ''),
   NULLIF(TRIM(PM.`Card_Owner_Number`), ''),
   PM.`Card_Expiry_Date`,
   NULLIF(TRIM(PM.`Card_CVV`), ''),
   PM.`Status_id`,
   PM.`Status`,
   PM.`Creation_Date`,
   PM.`Last_Update`,
   PM.`Operator`
FROM `account_payment_methods` PM
INNER JOIN `account_account` A ON A.`id` = PM.`Account_id`
LEFT JOIN `account_account` U ON U.`id` = PM.`Operator`
LEFT JOIN `account_payment_method_invoicing` I
   ON I.`Affiliate_id` = PM.`Account_id`
   AND I.`id` = (
      SELECT MIN(I2.`id`)
      FROM `account_payment_method_invoicing` I2
      WHERE I2.`Affiliate_id` = PM.`Account_id`
   )
WHERE (
         NULLIF(TRIM(PM.`Card_Owner_Number`), '') IS NOT NULL
      OR NULLIF(TRIM(PM.`Card_Owner_Name`), '') IS NOT NULL
      OR PM.`Card_Expiry_Date` IS NOT NULL
   )
;

-- ---------------------------------------------------------------------------
-- Vista unificada: todos los métodos de pago + empresas de facturación
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW `view_account_payment_methods` AS
SELECT
   C.`id`,
   C.`Affiliate_id`,
   C.`Affiliate`,
   C.`Payment_Method_Description`,
   'Card' AS `Payment_Method`,
   C.`Preferred_invoicing_id`,
   C.`Card_Owner_Name`,
   C.`Card_Owner_Number`,
   C.`Card_Expiry_Date`,
   C.`Card_CVV`,
   NULL AS `Bank_Name`,
   NULL AS `Bank_IBAN`,
   NULL AS `Bank_Swift`,
   NULL AS `Recipients_full_name`,
   NULL AS `Crypto_Wallet_Address`,
   NULL AS `Crypto_Network`,
   NULL AS `Crypto_memo_tag_ref`,
   NULL AS `PayPal_email`,
   I.`company_fiscal_ID`,
   I.`company_VAT_ID`,
   I.`company_fiscal_name`,
   I.`company_address`,
   I.`company_country`,
   I.`verified` AS `invoicing_verified`,
   C.`verified` AS `method_verified`,
   C.`Status_id`,
   C.`Status`,
   C.`Creation_Date`,
   C.`Last_Update`,
   C.`User`
FROM `account_payment_method_card` C
LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = C.`Preferred_invoicing_id`

UNION ALL

SELECT
   B.`id`,
   B.`Affiliate_id`,
   B.`Affiliate`,
   B.`Payment_Method_Description`,
   'Bank' AS `Payment_Method`,
   B.`Preferred_invoicing_id`,
   NULL, NULL, NULL, NULL,
   B.`Bank_Name`,
   B.`Bank_IBAN`,
   B.`Bank_Swift`,
   B.`Recipients_full_name`,
   NULL, NULL, NULL, NULL,
   I.`company_fiscal_ID`,
   I.`company_VAT_ID`,
   I.`company_fiscal_name`,
   I.`company_address`,
   I.`company_country`,
   I.`verified`,
   B.`verified`,
   B.`Status_id`,
   B.`Status`,
   B.`Creation_Date`,
   B.`Last_Update`,
   B.`User`
FROM `account_payment_method_bank` B
LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = B.`Preferred_invoicing_id`

UNION ALL

SELECT
   CR.`id`,
   CR.`Affiliate_id`,
   CR.`Affiliate`,
   CR.`Payment_Method_Description`,
   'Crypto' AS `Payment_Method`,
   CR.`Preferred_invoicing_id`,
   NULL, NULL, NULL, NULL,
   NULL, NULL, NULL, NULL,
   CR.`Crypto_Wallet_Address`,
   CR.`Crypto_Network`,
   CR.`Crypto_memo_tag_ref`,
   NULL,
   I.`company_fiscal_ID`,
   I.`company_VAT_ID`,
   I.`company_fiscal_name`,
   I.`company_address`,
   I.`company_country`,
   I.`verified`,
   CR.`verified`,
   CR.`Status_id`,
   CR.`Status`,
   CR.`Creation_Date`,
   CR.`Last_Update`,
   CR.`User`
FROM `account_payment_method_crypto` CR
LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = CR.`Preferred_invoicing_id`

UNION ALL

SELECT
   P.`id`,
   P.`Affiliate_id`,
   P.`Affiliate`,
   P.`Payment_Method_Description`,
   'PayPal' AS `Payment_Method`,
   P.`Preferred_invoicing_id`,
   NULL, NULL, NULL, NULL,
   NULL, NULL, NULL, NULL,
   NULL, NULL, NULL,
   P.`PayPal_email`,
   I.`company_fiscal_ID`,
   I.`company_VAT_ID`,
   I.`company_fiscal_name`,
   I.`company_address`,
   I.`company_country`,
   I.`verified`,
   P.`verified`,
   P.`Status_id`,
   P.`Status`,
   P.`Creation_Date`,
   P.`Last_Update`,
   P.`User`
FROM `account_payment_method_paypal` P
LEFT JOIN `account_payment_method_invoicing` I ON I.`id` = P.`Preferred_invoicing_id`;
