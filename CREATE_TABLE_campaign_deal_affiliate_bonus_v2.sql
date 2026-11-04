/*
CREATE_TABLE_campaign_deal_affiliate_bonus_v2.sql

Esquema de reglas de bonus al affiliate (cabecera + brands).

Tablas:
  - campaign_deal_affiliate_bonus       : regla (importe fijo y/o % NR, MS, período, umbrales)
  - campaign_deal_affiliate_bonus_brand : brands (Advertiser_id) a las que aplica la regla

Semántica de filtros (NULL / vacío = sin restricción = ALL):
  - Affiliate_id       NULL  => todos los affiliates
  - Code_to_Affiliate  NULL/'' => todas las marketing sources
  - Sin filas en campaign_deal_affiliate_bonus_brand => todas las brands
  - Date_Valid_From    obligatorio
  - Date_Valid_to      NULL => permanente (sin fecha fin)

Importe mensual (cuando se cumplan umbrales):
  Bonus_mensual = Bonus_Value
                + NR_mes * Bonus_NR / 100
                + CPA_mes * Bonus_Value_per_CPA
  Al menos uno de Bonus_Value, Bonus_NR o Bonus_Value_per_CPA debe ser > 0
  (CHECK chk_bonus_importe).

Umbrales CPA_min / NR_min / FTD_min (0 = umbral no aplica):
  - Conditions = 'ANY' => basta cumplir un umbral activo (>0)
  - Conditions = 'ALL' => deben cumplirse todos los umbrales activos (>0)

Cálculo mensual (referencia para SP):
  Sobre Snapshot_day_by_day_fact2, acumular Qualified_Players (CPA),
  Net_Revenue (NR) y First_Time_Deposit (FTD) del Affiliate_id, mes dentro
  del período, brands de la hija (o todas) y/o Code_to_Affiliate.

Migración:
  1. Renombra la tabla antigua a campaign_deal_affiliate_bonus_old (si existe y aún tiene Brand).
  2. Crea cabecera + hija.
  3. Copia datos; mapea Brand -> Advertiser_id vía campaign_advertiser.Advertiser_Name.
  4. Reglas sin Brand (vacío) quedan sin filas hijas (= all brands).
  5. Filas antiguas con Bonus_Value<=0 migran con Bonus_Value=0.01 para satisfacer CHECK
     (revisar manualmente; o asignar Bonus_NR después).

09.09.2026 v2    Cabecera + brands; Bonus_NR; sin Brand VARCHAR
09.09.2026 v2.1  Bonus_Value_per_CPA (importe fijo por CPA)
*/

-- =============================================================================
-- 1) Backup / rename de la estructura antigua (solo si aún tiene columna Brand)
-- =============================================================================
SET @v_has_old := (
   SELECT COUNT(*)
   FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus'
);

SET @v_has_brand := (
   SELECT COUNT(*)
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus'
     AND COLUMN_NAME = 'Brand'
);

SET @v_has_old_bak := (
   SELECT COUNT(*)
   FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus_old'
);

SET @v_sql_rename := IF(
   @v_has_old > 0 AND @v_has_brand > 0 AND @v_has_old_bak = 0,
   'RENAME TABLE `campaign_deal_affiliate_bonus` TO `campaign_deal_affiliate_bonus_old`',
   'SELECT "skip rename: sin tabla antigua con Brand o ya existe _old" AS info'
);
PREPARE stmt_rename FROM @v_sql_rename;
EXECUTE stmt_rename;
DEALLOCATE PREPARE stmt_rename;

-- =============================================================================
-- 2) Cabecera
-- =============================================================================
CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_bonus` (
   `id`                   INT            NOT NULL AUTO_INCREMENT,
   `Affiliate_id`         INT            NULL DEFAULT NULL COMMENT 'NULL = todos los affiliates',
   `Code_to_Affiliate`    VARCHAR(50)    NULL DEFAULT NULL COMMENT 'NULL o vacío = todas las MS',
   `Description`          VARCHAR(250)   NULL DEFAULT NULL,
   `Date_Valid_From`      DATE           NOT NULL COMMENT 'Inicio de vigencia (obligatorio)',
   `Date_Valid_to`        DATE           NULL DEFAULT NULL COMMENT 'NULL = permanente',
   `Bonus_Value`          DECIMAL(12,2)  NOT NULL DEFAULT 0 COMMENT 'Importe fijo opcional',
   `Bonus_NR`             DECIMAL(8,2)   NOT NULL DEFAULT 0 COMMENT '% sobre NR acumulado del mes filtrado',
   `Bonus_Value_per_CPA`  DECIMAL(12,2)  NOT NULL DEFAULT 0 COMMENT 'Importe fijo por cada CPA del mes filtrado',
   `Currency`             VARCHAR(5)     NULL DEFAULT 'EUR',
   `Conditions`           VARCHAR(10)    NOT NULL DEFAULT 'ANY' COMMENT 'ANY|ALL sobre umbrales CPA_min/NR_min/FTD_min (>0)',
   `CPA_min`              INT            NOT NULL DEFAULT 0 COMMENT '0 = no aplica; CPA = SUM(Qualified_Players) del mes filtrado',
   `NR_min`               INT            NOT NULL DEFAULT 0 COMMENT '0 = no aplica; NR = SUM(Net_Revenue) del mes filtrado',
   `FTD_min`              INT            NOT NULL DEFAULT 0 COMMENT '0 = no aplica; FTD = SUM(First_Time_Deposit) del mes filtrado',
   `Status_id`            SMALLINT       NULL DEFAULT 1,
   `Status`               VARCHAR(30)    NULL DEFAULT 'Active',
   `Creation_Date`        DATETIME       NULL DEFAULT CURRENT_TIMESTAMP,
   `Last_Update`          DATETIME       NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `User`                 VARCHAR(30)    NULL DEFAULT ' ',
   PRIMARY KEY (`id`) USING BTREE,
   KEY `idx_aff_dates` (`Affiliate_id`, `Date_Valid_From`, `Date_Valid_to`),
   KEY `idx_code_to_aff` (`Code_to_Affiliate`),
   KEY `idx_status_id` (`Status_id`),
   CONSTRAINT `chk_bonus_conditions` CHECK (`Conditions` IN ('ANY', 'ALL')),
   CONSTRAINT `chk_bonus_importe` CHECK (`Bonus_Value` > 0 OR `Bonus_NR` > 0 OR `Bonus_Value_per_CPA` > 0),
   CONSTRAINT `chk_bonus_dates` CHECK (`Date_Valid_to` IS NULL OR `Date_Valid_to` >= `Date_Valid_From`)
) ENGINE=InnoDB COMMENT='Reglas bonus affiliate: fijo y/o %NR y/o por CPA; brands en hija (0 filas=all)';

-- Si la cabecera ya existía sin Bonus_Value_per_CPA, agregarla
SET @v_has_per_cpa := (
   SELECT COUNT(*)
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus'
     AND COLUMN_NAME = 'Bonus_Value_per_CPA'
);
SET @v_sql_add_per_cpa := IF(
   @v_has_per_cpa = 0,
   'ALTER TABLE `campaign_deal_affiliate_bonus`
      ADD COLUMN `Bonus_Value_per_CPA` DECIMAL(12,2) NOT NULL DEFAULT 0
         COMMENT ''Importe fijo por cada CPA del mes filtrado''
         AFTER `Bonus_NR`',
   'SELECT "skip ADD Bonus_Value_per_CPA" AS info'
);
PREPARE stmt_add_per_cpa FROM @v_sql_add_per_cpa;
EXECUTE stmt_add_per_cpa;
DEALLOCATE PREPARE stmt_add_per_cpa;

-- Actualizar CHECK de importe si existe la tabla previa (drop+add)
SET @v_has_chk := (
   SELECT COUNT(*)
   FROM information_schema.TABLE_CONSTRAINTS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus'
     AND CONSTRAINT_NAME = 'chk_bonus_importe'
     AND CONSTRAINT_TYPE = 'CHECK'
);
SET @v_sql_chk := IF(
   @v_has_chk > 0,
   'ALTER TABLE `campaign_deal_affiliate_bonus`
      DROP CHECK `chk_bonus_importe`,
      ADD CONSTRAINT `chk_bonus_importe`
         CHECK (`Bonus_Value` > 0 OR `Bonus_NR` > 0 OR `Bonus_Value_per_CPA` > 0)',
   'SELECT "skip chk_bonus_importe refresh" AS info'
);
PREPARE stmt_chk FROM @v_sql_chk;
EXECUTE stmt_chk;
DEALLOCATE PREPARE stmt_chk;
-- =============================================================================
-- 3) Hija: brands (Advertiser_id). 0 filas para un Bonus_id => todas las brands
-- =============================================================================
CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_bonus_brand` (
   `id`            INT NOT NULL AUTO_INCREMENT,
   `Bonus_id`      INT NOT NULL COMMENT 'FK a campaign_deal_affiliate_bonus.id',
   `Advertiser_id` INT NOT NULL COMMENT 'Brand (campaign_advertiser.id)',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE KEY `uk_bonus_advertiser` (`Bonus_id`, `Advertiser_id`),
   KEY `idx_advertiser` (`Advertiser_id`),
   CONSTRAINT `fk_aff_bonus_brand` FOREIGN KEY (`Bonus_id`) REFERENCES `campaign_deal_affiliate_bonus` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Brands de una regla bonus; sin filas = aplica a todas';

-- =============================================================================
-- 4) Migración desde campaign_deal_affiliate_bonus_old (si existe y cabecera vacía)
-- =============================================================================
SET @v_has_old_bak := (
   SELECT COUNT(*)
   FROM information_schema.TABLES
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus_old'
);

SET @v_cnt_new := (
   SELECT IFNULL((
      SELECT COUNT(*) FROM `campaign_deal_affiliate_bonus`
   ), 0)
);

SET @v_has_operator := (
   SELECT COUNT(*)
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus_old'
     AND COLUMN_NAME = 'Operator'
);

SET @v_has_user := (
   SELECT COUNT(*)
   FROM information_schema.COLUMNS
   WHERE TABLE_SCHEMA = DATABASE()
     AND TABLE_NAME = 'campaign_deal_affiliate_bonus_old'
     AND COLUMN_NAME = 'User'
);

SET @v_op_expr := CASE
   WHEN @v_has_operator > 0 AND @v_has_user > 0
      THEN 'COALESCE(NULLIF(TRIM(o.`Operator`), ""), NULLIF(TRIM(o.`User`), ""), " ")'
   WHEN @v_has_operator > 0
      THEN 'IFNULL(NULLIF(TRIM(o.`Operator`), ""), " ")'
   WHEN @v_has_user > 0
      THEN 'IFNULL(NULLIF(TRIM(o.`User`), ""), " ")'
   ELSE '" "'
END;

SET @v_sql_mig_hdr := IF(
   @v_has_old_bak > 0 AND @v_cnt_new = 0,
   CONCAT(
      'INSERT INTO `campaign_deal_affiliate_bonus` (',
      '  `id`, `Affiliate_id`, `Code_to_Affiliate`, `Description`,',
      '  `Date_Valid_From`, `Date_Valid_to`,',
      '  `Bonus_Value`, `Bonus_NR`, `Bonus_Value_per_CPA`, `Currency`, `Conditions`,',
      '  `CPA_min`, `NR_min`, `FTD_min`,',
      '  `Status_id`, `Status`, `Creation_Date`, `Last_Update`, `User`',
      ') SELECT',
      '  o.`id`,',
      '  o.`Affiliate_id`,',
      '  NULLIF(TRIM(IFNULL(o.`Code_to_Affiliate`, "")), ""),',
      '  NULLIF(TRIM(IFNULL(o.`Description`, "")), ""),',
      '  IFNULL(o.`Date_Valid_From`, CURDATE()),',
      '  o.`Date_Valid_to`,',
      '  CASE WHEN IFNULL(o.`Bonus_Value`, 0) > 0 THEN o.`Bonus_Value` ELSE 0.01 END,',
      '  0,',
      '  0,',
      '  IFNULL(NULLIF(TRIM(o.`Currency`), ""), "EUR"),',
      '  CASE UPPER(TRIM(IFNULL(o.`Conditions`, "ANY"))) WHEN "ALL" THEN "ALL" ELSE "ANY" END,',
      '  IFNULL(o.`CPA_min`, 0),',
      '  IFNULL(o.`NR_min`, 0),',
      '  IFNULL(o.`FTD_min`, 0),',
      '  IFNULL(o.`Status_id`, 1),',
      '  o.`Status`,',
      '  o.`Creation_Date`,',
      '  o.`Last_Update`,',
      '  ', @v_op_expr,
      ' FROM `campaign_deal_affiliate_bonus_old` o'
   ),
   'SELECT "skip migrate header: no _old o cabecera ya con datos" AS info'
);

PREPARE stmt_mig_hdr FROM @v_sql_mig_hdr;
EXECUTE stmt_mig_hdr;
DEALLOCATE PREPARE stmt_mig_hdr;

-- Brands: Brand VARCHAR -> Advertiser_id por nombre
SET @v_cnt_brand := (
   SELECT IFNULL((SELECT COUNT(*) FROM `campaign_deal_affiliate_bonus_brand`), 0)
);

SET @v_sql_mig_brand := IF(
   @v_has_old_bak > 0 AND @v_cnt_brand = 0,
   'INSERT IGNORE INTO `campaign_deal_affiliate_bonus_brand` (`Bonus_id`, `Advertiser_id`)
    SELECT o.`id`, a.`id`
    FROM `campaign_deal_affiliate_bonus_old` o
    INNER JOIN `campaign_advertiser` a
            ON UPPER(TRIM(a.`Advertiser_Name`)) = UPPER(TRIM(o.`Brand`))
    INNER JOIN `campaign_deal_affiliate_bonus` b
            ON b.`id` = o.`id`
    WHERE NULLIF(TRIM(IFNULL(o.`Brand`, "")), "") IS NOT NULL',
   'SELECT "skip migrate brands: no _old o hija ya con datos" AS info'
);

PREPARE stmt_mig_brand FROM @v_sql_mig_brand;
EXECUTE stmt_mig_brand;
DEALLOCATE PREPARE stmt_mig_brand;

-- Alinear AUTO_INCREMENT de cabecera tras migración con ids explícitos
SET @v_max_id := (
   SELECT IFNULL(MAX(`id`), 0) FROM `campaign_deal_affiliate_bonus`
);
SET @v_sql_ai := IF(
   @v_max_id > 0,
   CONCAT('ALTER TABLE `campaign_deal_affiliate_bonus` AUTO_INCREMENT = ', @v_max_id + 1),
   'SELECT "skip AUTO_INCREMENT" AS info'
);
PREPARE stmt_ai FROM @v_sql_ai;
EXECUTE stmt_ai;
DEALLOCATE PREPARE stmt_ai;

/*
Verificación sugerida tras ejecutar:

SELECT COUNT(*) AS n_bonus FROM campaign_deal_affiliate_bonus;
SELECT COUNT(*) AS n_brand FROM campaign_deal_affiliate_bonus_brand;

SELECT o.id, o.Brand, b.Advertiser_id, a.Advertiser_Name
FROM campaign_deal_affiliate_bonus_old o
LEFT JOIN campaign_deal_affiliate_bonus_brand b ON b.Bonus_id = o.id
LEFT JOIN campaign_advertiser a ON a.id = b.Advertiser_id
WHERE NULLIF(TRIM(IFNULL(o.Brand,"")),"") IS NOT NULL
  AND b.id IS NULL;
-- Filas sin match de Brand: revisar nombres en campaign_advertiser

SELECT id, Bonus_Value, Bonus_NR, Description
FROM campaign_deal_affiliate_bonus
WHERE Bonus_Value = 0.01 AND Bonus_NR = 0;
-- Candidatos migrados con valor simbólico; corregir a mano
*/
