/*
PROCEDURE_Report_Bonus_Affiliate_v1.2.sql - Report Reglas Bonus Affiliate

Descripción:
  Lista reglas de bonus affiliate (campaign_deal_affiliate_bonus +
  campaign_deal_affiliate_bonus_brand). Brands como CSV o ALL.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  Affiliate_id  =[ALL | id]. OPCIONAL. Default=ALL. NULL en tabla = todos los affiliates.
  Brand         =[ALL | Advertiser_Name]. OPCIONAL. Default=ALL. Filtra por brand en hija.
  Advertiser_id =[ALL | id]. OPCIONAL. Default=ALL. Filtra por Advertiser_id en hija.
  Status_bonus  =[ALL | valid | expired]. OPCIONAL. Default=ALL.
  Status_id     =[ALL | 1 | 0]. OPCIONAL. Default=ALL. 1=Active 0=Inactive
  Filters       =[Yes | No]. Devuelve lista de filtros. OPCIONAL. Default=No.
  Meta          =[Yes | No]. Fila setting. OPCIONAL. Default=Yes.
  Debug         =[No | Yes | KeyValues]. OPCIONAL. Default=No.

Ejemplos:
  call Report_Bonus_Affiliate('debug=ye');
  call Report_Bonus_Affiliate('filters=yes');
  call Report_Bonus_Affiliate('Affiliate_id=440,Status_bonus=valid');
  call Report_Bonus_Affiliate('Brand=PlanetWin365,debug=keyvalues');

02.12.2024 V1     Primera versión operativa
08.01.2025 v1.1   Filtro por Status_bonus=Expired/Valid
10.09.2026 v1.2   Adecuación a cabecera+brands; Bonus_NR; Bonus_Value_per_CPA;
                  User; Brand CSV/ALL; filtro Advertiser_id
*/

DROP PROCEDURE IF EXISTS Report_Bonus_Affiliate;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Bonus_Affiliate`(
   IN InputCommLine VARCHAR(250)
)
COMMENT 'v1.2 10.09.2026 - Report reglas bonus affiliate (cabecera+brands)'
SQL SECURITY DEFINER
proc_label:BEGIN

DECLARE v_Version        VARCHAR(32)  DEFAULT 'v1.2 10.09.2026';
DECLARE v_InputCommLine  VARCHAR(260);
DECLARE v_e              INT;
DECLARE v_c              INT;
DECLARE v_k              VARCHAR(64);
DECLARE v_v              VARCHAR(200);

DECLARE v_Affiliate_id   VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Brand          VARCHAR(80)  DEFAULT 'ALL';
DECLARE v_Advertiser_id  VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Status_bonus   VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Status_id      VARCHAR(32)  DEFAULT 'ALL';
DECLARE v_Debug          VARCHAR(16)  DEFAULT 'NO';
DECLARE v_Filters        VARCHAR(8)   DEFAULT 'NO';
DECLARE v_Meta           VARCHAR(8)   DEFAULT 'YES';

DECLARE v_WhereAffiliate VARCHAR(120) DEFAULT '';
DECLARE v_WhereStatus    VARCHAR(80)  DEFAULT '';
DECLARE v_WhereBrand     VARCHAR(400) DEFAULT '';
DECLARE v_WhereAdv       VARCHAR(400) DEFAULT '';
DECLARE v_WhereStatusBonus VARCHAR(160) DEFAULT '';

SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

WHILE v_InputCommLine > ' ' DO
   SET v_e = INSTR(v_InputCommLine, '=');
   SET v_c = INSTR(v_InputCommLine, ',');
   IF v_e = 0 OR v_c = 0 OR v_c < v_e THEN
      SET v_InputCommLine = '';
   ELSE
      SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
      SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
      SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

      IF LOWER(v_k) = 'affiliate_id'  THEN SET v_Affiliate_id  = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'status_bonus'  THEN SET v_Status_bonus  = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'status_id'     THEN SET v_Status_id     = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'brand'         THEN SET v_Brand         = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'advertiser_id' THEN SET v_Advertiser_id = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'meta'          THEN SET v_Meta          = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'filters'       THEN SET v_Filters       = UPPER(v_v); END IF;
      IF LOWER(v_k) = 'debug'         THEN SET v_Debug         = UPPER(v_v); END IF;
   END IF;
END WHILE;

IF v_Debug = 'KEYVALUES' THEN
   SELECT v_Version AS Version, v_Filters AS Filters, v_Status_id AS Status_id,
          v_Status_bonus AS Status_bonus, v_Brand AS Brand, v_Advertiser_id AS Advertiser_id,
          v_Affiliate_id AS Affiliate_id, v_Meta AS Meta, InputCommLine;
END IF;

IF v_Affiliate_id != 'ALL' THEN
   SET v_WhereAffiliate = CONCAT(' AND B.`Affiliate_id`=', REPLACE(v_Affiliate_id, '"', ''));
END IF;
IF v_Status_id != 'ALL' THEN
   SET v_WhereStatus = CONCAT(' AND B.`Status_id`=', REPLACE(v_Status_id, '"', ''));
END IF;
IF v_Brand != 'ALL' THEN
   SET v_WhereBrand = CONCAT(
      ' AND EXISTS (SELECT 1 FROM `campaign_deal_affiliate_bonus_brand` bb',
      ' INNER JOIN `campaign_advertiser` ca ON ca.`id`=bb.`Advertiser_id`',
      ' WHERE bb.`Bonus_id`=B.`id` AND UPPER(TRIM(ca.`Advertiser_Name`))="',
      REPLACE(v_Brand, '"', '""'), '")'
   );
END IF;
IF v_Advertiser_id != 'ALL' THEN
   SET v_WhereAdv = CONCAT(
      ' AND EXISTS (SELECT 1 FROM `campaign_deal_affiliate_bonus_brand` bb',
      ' WHERE bb.`Bonus_id`=B.`id` AND bb.`Advertiser_id`=',
      REPLACE(v_Advertiser_id, '"', ''), ')'
   );
END IF;

CASE LOWER(v_Status_bonus)
   WHEN 'expired' THEN
      SET v_WhereStatusBonus = ' AND CURDATE() > IFNULL(B.`Date_Valid_to`,"9999-12-31") ';
   WHEN 'valid' THEN
      SET v_WhereStatusBonus = ' AND CURDATE() <= IFNULL(B.`Date_Valid_to`,"9999-12-31") ';
   ELSE
      SET v_WhereStatusBonus = '';
END CASE;

IF v_Debug != 'NO' AND v_Debug != 'KEYVALUES' THEN
   SELECT v_WhereAffiliate, v_WhereBrand, v_WhereAdv, v_WhereStatus, v_WhereStatusBonus;
END IF;

/**************************************************************************************************************/
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
   PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB COMMENT='Reglas bonus affiliate: fijo y/o %NR y/o por CPA; brands en hija (0 filas=all)';

CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_bonus_brand` (
   `id`            INT NOT NULL AUTO_INCREMENT,
   `Bonus_id`      INT NOT NULL COMMENT 'FK a campaign_deal_affiliate_bonus.id',
   `Advertiser_id` INT NOT NULL COMMENT 'Brand (campaign_advertiser.id)',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE KEY `uk_bonus_advertiser` (`Bonus_id`, `Advertiser_id`),
   KEY `idx_advertiser` (`Advertiser_id`)
) ENGINE=InnoDB COMMENT='Brands de una regla bonus; sin filas = aplica a todas';
/**************************************************************************************************************/

SET @CTE = CONCAT(
'WITH Main_Table_Data AS (
SELECT
    B.`id`
   ,B.`Status`
   ,B.`Affiliate_id`
   ,IFNULL(A.`username`,"ALL") AS `Affiliate`
   ,IFNULL((
       SELECT GROUP_CONCAT(DISTINCT ca.`Advertiser_Name` ORDER BY ca.`Advertiser_Name` SEPARATOR ",")
       FROM `campaign_deal_affiliate_bonus_brand` bb
       INNER JOIN `campaign_advertiser` ca ON ca.`id` = bb.`Advertiser_id`
       WHERE bb.`Bonus_id` = B.`id`
    ),"ALL") AS `Brand`
   ,CASE WHEN NULLIF(TRIM(IFNULL(B.`Code_to_Affiliate`,"")),"") IS NULL THEN "-Any-" ELSE B.`Code_to_Affiliate` END AS `Code_to_Affiliate`
   ,B.`Description`
   ,B.`Date_Valid_From`
   ,IFNULL(B.`Date_Valid_to`,"permanent") AS `Date_Valid_to`
   ,B.`Bonus_Value`
   ,B.`Bonus_NR`
   ,B.`Bonus_Value_per_CPA`
   ,B.`Currency`
   ,B.`Conditions`
   ,B.`CPA_min`
   ,B.`NR_min`
   ,B.`FTD_min`
   ,B.`Status_id`
   ,LEFT(IFNULL(B.`Creation_Date`,""),19) AS `Creation_Date`
   ,LEFT(IFNULL(B.`Last_Update`,""),19) AS `Last_Update`
   ,IFNULL(NULLIF(TRIM(B.`User`),"")," ") AS `User`
FROM `campaign_deal_affiliate_bonus` B
LEFT JOIN `account_account` A ON A.`id` = B.`Affiliate_id`
WHERE 1=1 '
   ,v_WhereAffiliate
   ,v_WhereStatus
   ,v_WhereStatusBonus
   ,v_WhereBrand
   ,v_WhereAdv
,')
');

SET @SQLmeta = CONCAT(
'(
SELECT
   "setting" AS Meta
   ,"width=80px,action=2" AS `Action`
   ,"omit=true" AS `id`
   ,"width=100px" AS `Status`
   ,"omit=true" AS `Affiliate_id`
   ,"width=130px" AS `Affiliate`
   ,"width=180px,tooltip=yes" AS `Brand`
   ,"width=100px" AS `Code to Aff (MS)`
   ,"width=220px,tooltip=yes" AS `Description`
   ,"width=100px" AS `Valid From`
   ,"width=100px" AS `Valid Until`
   ,"width=100px,right=true" AS `Bonus Value`
   ,"width=90px,right=true" AS `Bonus % NR`
   ,"width=110px,right=true" AS `Bonus / CPA`
   ,"width=70px" AS `Currency`
   ,"width=80px" AS `Conditions`
   ,"width=100px,right=true" AS `CPA minimum`
   ,"width=100px,right=true" AS `NR minimum`
   ,"width=100px,right=true" AS `FTD minimum`
   ,"omit=true" AS `Status_id`
   ,"omit=true" AS `Creation_Date`
   ,"width=140px" AS `Last Update`
   ,"width=100px" AS `User`
FROM DUAL WHERE "', v_Meta, '"="YES")
UNION ALL '
);

SET @SQL = CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" AS `Meta`
   ,"..." AS `Action`
   ,MT.`id`
   ,MT.`Status`
   ,MT.`Affiliate_id`
   ,MT.`Affiliate`
   ,MT.`Brand`
   ,MT.`Code_to_Affiliate`
   ,MT.`Description`
   ,MT.`Date_Valid_From`
   ,MT.`Date_Valid_to`
   ,MT.`Bonus_Value`
   ,MT.`Bonus_NR`
   ,MT.`Bonus_Value_per_CPA`
   ,MT.`Currency`
   ,MT.`Conditions`
   ,MT.`CPA_min`
   ,MT.`NR_min`
   ,MT.`FTD_min`
   ,MT.`Status_id`
   ,MT.`Creation_Date`
   ,MT.`Last_Update`
   ,MT.`User`
FROM Main_Table_Data MT
ORDER BY CASE WHEN `Meta`="setting" THEN 0 ELSE 1 END, `Affiliate`, `id`
');

SET @SQLfilters = CONCAT(
@CTE,
'
(SELECT "01" AS Korder,"Status Bonus" AS `Key`,"Expired" AS Value,"Status_bonus" AS Caption,"expired" AS id,"" AS extra FROM DUAL)
UNION ALL
(SELECT "01","Status Bonus","Valid","Status_bonus","valid","")
UNION ALL
(SELECT "03","Status",IFNULL(`Status`,"") , "Status_id", CAST(`Status_id` AS CHAR), CAST(COUNT(*) AS CHAR)
 FROM Main_Table_Data GROUP BY `Status_id`,`Status`)
UNION ALL
(SELECT "05","Brand", br.`Advertiser_Name`, "Brand", br.`Advertiser_Name`, CAST(COUNT(DISTINCT B.`id`) AS CHAR)
 FROM `campaign_deal_affiliate_bonus` B
 INNER JOIN `campaign_deal_affiliate_bonus_brand` bb ON bb.`Bonus_id`=B.`id`
 INNER JOIN `campaign_advertiser` br ON br.`id`=bb.`Advertiser_id`
 WHERE 1=1 ', v_WhereAffiliate, v_WhereStatus, v_WhereStatusBonus, '
 GROUP BY br.`Advertiser_Name`)
UNION ALL
(SELECT "05","Brand","ALL","Brand","ALL","")
UNION ALL
(SELECT "06","Advertiser", br.`Advertiser_Name`, "Advertiser_id", CAST(br.`id` AS CHAR), CAST(COUNT(DISTINCT B.`id`) AS CHAR)
 FROM `campaign_deal_affiliate_bonus` B
 INNER JOIN `campaign_deal_affiliate_bonus_brand` bb ON bb.`Bonus_id`=B.`id`
 INNER JOIN `campaign_advertiser` br ON br.`id`=bb.`Advertiser_id`
 WHERE 1=1 ', v_WhereAffiliate, v_WhereStatus, v_WhereStatusBonus, '
 GROUP BY br.`id`, br.`Advertiser_Name`)
UNION ALL
(SELECT "07","Affiliate",`Affiliate`,"Affiliate_id",CAST(`Affiliate_id` AS CHAR),CAST(COUNT(*) AS CHAR)
 FROM Main_Table_Data GROUP BY `Affiliate_id`,`Affiliate`)
ORDER BY Korder ASC, Value ASC
');

IF v_Filters != 'NO' THEN
   SET @SQL = @SQLfilters;
END IF;

IF v_Debug != 'NO' THEN
   SELECT @SQL AS generated_sql;
END IF;

IF v_Debug != 'YES' THEN
   PREPARE stmt1 FROM @SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
CALL Report_Bonus_Affiliate('debug=yes');
CALL Report_Bonus_Affiliate('filters=yes');
CALL Report_Bonus_Affiliate('Affiliate_id=440,Status_bonus=valid');
CALL Report_Bonus_Affiliate('Brand=PlanetWin365');
CALL Report_Bonus_Affiliate('Advertiser_id=17,Meta=yes');
*/
