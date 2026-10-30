/*
PROCEDURE_monthly_comms_affiliate_v5.7.sql - COMISIONES del AFILIADO

Descripción:
  Calcula comisiones mensuales del afiliado (CPA + Revenue Share) sobre
  Snapshot_day_by_day_fact2, con tratamiento de RS negativa, RS contra CPA
  y acumulación según campaign_deal_affiliate.RS_Base.

Observaciones:
  p_month = mes a procesar en formato YYYY-MM. Si es NULL, vacío o inválido,
  usa CURDATE() - 2 meses como inicio del recálculo (borra e inserta desde ese mes).

Modalidades RS (Deal_Aff_RS / Deal_Aff_RS_Against_CPA / Deal_Aff_RS_Base):
  - Sin RS (Deal_Aff_RS=0): gross_RS_Val=0 y net_RS_Val=0
  - Con RS y Deal_Aff_RS_Against_CPA=1: la RS negativa se resta de gross_CPA_Val
    sin dejar net_CPA_Val negativo; el remanente de RS (si existe) sigue el flujo
    de acumulación
  - Con RS acumulado negativo (según base): net_RS_Val=0
  - net_RS_Val nunca es negativo: las RS negativas del grupo se absorben en las
    positivas del mismo KeyRSAcum (reparto proporcional del neto acumulado ≥ 0)
  - La base de acumulación RS se toma de campaign_deal_affiliate.RS_Base
    (fallback: Snapshot Deal_Aff_RS_Base; default brand):
      account         → Affiliate_id + Account_id
      Operator        → Affiliate_id + Publisher_id
      brand           → Affiliate_id + Brand          (default)
      Operator/brand  → Affiliate_id + Publisher_id + Brand
    Cualquier otro valor se trata como brand.

Parámetros:
  p_month VARCHAR(7)  -- YYYY-MM | NULL | ''

Ejemplos:
  CALL monthly_comms_affiliate_v5('2026-03');
  CALL monthly_comms_affiliate_v5(NULL);
  CALL monthly_comms_affiliate_v5_dev('');

	22.02.2022        Calculos sobre Snapshot_day_by_day_fact1
	02.04.2022        Se agrega Tracker_ID para estadisticas
	19.04.2022        Tratamiento de Deal por producto y fecha
	27.07.2022        Multimoneda
	13.09.2022        incluye Product
   10.10.2022 V3.1   incluye group by deal
   27.10.2022 V3.2   Nuevo cálculo de RS (acumula por Adv Account)
   28.10.2022 V3.2   Utiliza Brand_Group y Brand_Group_Acum
-- 28.11.2022 v3.3   Se trata nuevos campos is_indirect,Advertiser_indirect_id,Advertiser_indirect
   21.01.2023 v3.4   Trata nuevo concepto Publisher (pagador)
   31.01.2023 v3.5   `Area`
   10.03.2023 v4     PROCEDURE_monthly_comms_gestor_v4_COver.sql - C.Over
   11.03.2023 v4     PROCEDURE_monthly_comms_affiliate_v4_COver.sql - C.Over
   11.01.2024 v4.1   Se agrega cálculo comision referral
                     Modifica índices monthly_comms_affiliate
                     compatibilidad con view_monthly_fact_aff4
   29.07.2024 v5     Tratamiento de Currency del deal
   09.08.2024 v5.1   Agregado channel y product
   03.09.2024 v5.1.1 Fix cuando no existe deal afiliado (por error deshabilitando reglas en campaign_mkt_source_deal)
              v5.2   Tramiento de RS negativas
   06.09.2024 v5.2.1 Tratamiento From/To master_affiliate_deals_per_affiliate
   19.09.2024 v5.2.2 Calculo deals referrer por Brand sobre Snapshot_day_by_day_fact2
   01.11.2024 v5.3   Calculo deals referrer por Brand sobre monthly_comms_affiliate_v5
                     Incluye % comisión sobre total comisión afiliado. Acumula a comision por CPA
   20.11.2024 v5.4   Agregado Owner a la tabla
   11.03.2025 v5.5   Recálculo restringido a mes corriente y mes anterior.
                     Comm_type
   11.09.2025 v5.6   Agregado parámetro de entrada para especificar el mes a procesar
   01.04.2026 v5.6.1 Fix collation al comparar Month (uso de DATE)
   04.08.2026 v5.6.2 Tratamiento de RS negativas
   04.08.2026 v5.7   Refactor legibilidad/performance; RS por Deal_Aff_RS_Base
                     (account | Operator | brand | Operator/brand); CASE unificado
                     CPA-vs-RS y acumulación por KeyRSAcum
**/

-- DROP PROCEDURE IF EXISTS monthly_comms_affiliate_v5_dev;
DROP PROCEDURE IF EXISTS monthly_comms_affiliate_v5;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE monthly_comms_affiliate_v5(IN p_month VARCHAR(7))
   COMMENT 'v5.7 04.08.2026 - Comisiones afiliado CPA+RS con acumulación por RS_Base'
   LANGUAGE SQL
   SQL SECURITY DEFINER
proc_label:BEGIN

DECLARE v_Version          VARCHAR(32)  DEFAULT 'v5.7 04.08.2026';
DECLARE v_LMonth           VARCHAR(7);
DECLARE v_LMonthDate       DATE;
DECLARE v_CurrentMonthDate DATE;

SET v_LMonth = CASE
    WHEN p_month IS NOT NULL
         AND p_month != ''
         AND p_month REGEXP '^[0-9]{4}-[0-9]{2}$'
         AND STR_TO_DATE(CONCAT(p_month, '-01'), '%Y-%m-%d') IS NOT NULL
    THEN p_month
    ELSE LEFT(DATE_SUB(CURDATE(), INTERVAL 2 MONTH), 7)
END;
SET v_LMonthDate       = STR_TO_DATE(CONCAT(v_LMonth, '-01'), '%Y-%m-%d');
SET v_CurrentMonthDate = STR_TO_DATE(CONCAT(DATE_FORMAT(CURDATE(), '%Y-%m'), '-01'), '%Y-%m-%d');

-- Compatibilidad con bloques que aún referencian variables de sesión (LATERAL referrer)
SET @LMonthDate        = v_LMonthDate;
SET @CurrentMonthDate  = v_CurrentMonthDate;
SET @Version           = v_Version;

CREATE TABLE IF NOT EXISTS `monthly_comms_affiliate_v5` (
	`Owner`            INT            NOT NULL DEFAULT '0',
	`Account_id`       INT            NOT NULL DEFAULT '0',
	`Comm_type`        VARCHAR(80)        NULL DEFAULT NULL COMMENT 'null/bonus',
	`Month`            VARCHAR(7)     NOT NULL DEFAULT '0000-00',
	`Affiliate`        VARCHAR(80)    NOT NULL DEFAULT '',
	`Brand`            VARCHAR(80)    NOT NULL DEFAULT '',
	`Affiliate_id`     INT            NOT NULL DEFAULT '0',
	`Advertiser_id`    INT            NOT NULL DEFAULT '0',
	`Currency`         VARCHAR(20)    NOT NULL DEFAULT '',
	`CPA`              DECIMAL(12,0)  NOT NULL DEFAULT '0',
	`net_CPA_Val`      DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`net_RS_Val`       DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`net_Total_comm`   DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`RS_carry_NCO`     DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`Net_Revenue`      DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`gross_CPA_Val`    DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`gross_RS_Val`     DECIMAL(12,2)  NOT NULL DEFAULT '0',
	`Sub_Affiliate`    VARCHAR(80)        NULL DEFAULT '',
	`Sub_Affiliate_id` INT                NULL DEFAULT '0',
	`Product`          VARCHAR(80)        NULL DEFAULT '',
	`Product_Real`     VARCHAR(80)        NULL DEFAULT '',
	`Channel`          VARCHAR(80)        NULL DEFAULT '',
	`Channel_id`       INT                NULL DEFAULT '0',
	INDEX `Month_Affiliate_id` (`Month`, `Affiliate_id`)   USING BTREE,
	INDEX `Affiliate_id_Month` (`Affiliate_id`, `Month`)   USING BTREE,
	INDEX `Month_Advertiser_id` (`Month`, `Advertiser_id`) USING BTREE
);

DELETE FROM `monthly_comms_affiliate_v5`
WHERE STR_TO_DATE(CONCAT(`Month`, '-01'), '%Y-%m-%d') >= v_LMonthDate;

-- =====================================================================
-- 1) CPA + RS del afiliado
-- =====================================================================
INSERT IGNORE INTO `monthly_comms_affiliate_v5`
WITH
-- Filas base: deal, moneda y clave de acumulación RS
src AS (
	SELECT
		 f.`Owner`
		,f.`Username_id`                                              AS `Account_id`
		,LEFT(f.`DATE`, 7)                                            AS `Month`
		,f.`Affiliate_id`
		,f.`Advertiser_id`
		,IFNULL(f.`Publisher_id`, 0)                                  AS `Publisher_id`
		,IFNULL(f.`Qualified_Players`, 0)                             AS `Qualified_Players`
		,IFNULL(f.`Net_Revenue`, 0)                                   AS `Net_Revenue`
		,IFNULL(f.`Deal_Aff_id`, 0)                                   AS `Deal_Aff_id`
		,IFNULL(f.`Deal_Aff_CPA`, 0)                                  AS `Deal_Aff_CPA`
		,IFNULL(f.`Deal_Aff_Carry_Over`, 0)                           AS `CarryOver`
		,IFNULL(f.`Deal_Aff_RS_Against_CPA`, 0)                       AS `CPAminusRS`
		,IFNULL(f.`Deal_Aff_RS`, 0)                                   AS `Deal_Aff_RS`
		-- Base de acumulación: deal (autoritativo); fallback fact2; default brand
		,CASE LOWER(TRIM(IFNULL(NULLIF(TRIM(d.`RS_Base`), ''),
		              IFNULL(NULLIF(TRIM(f.`Deal_Aff_RS_Base`), ''), 'brand'))))
			WHEN 'account'        THEN 'account'
			WHEN 'operator'       THEN 'operator'
			WHEN 'operator/brand' THEN 'operator/brand'
			ELSE 'brand'
		 END                                                          AS `RS_Base`
		,IFNULL(d.`Currency`, f.`Data_Currency`)                      AS `Deal_Currency`
		,IFNULL(f.`CPA_Value_Affiliate`, 0)                           AS `gross_CPA_Val_raw`
		,IFNULL(f.`Affiliate`, '')                                    AS `Affiliate`
		,IFNULL(f.`Brand`, '')                                        AS `Brand`
		,f.`Product`
		,f.`Product_Real`
		,IFNULL(f.`Channel`, '')                                      AS `Channel`
		,IFNULL(f.`Channel_id`, 0)                                    AS `Channel_id`
		,f.`Data_Currency`
		,CASE
			WHEN f.`Data_Currency` = d.`Currency` THEN 1
			ELSE getCurrencyConversion(1, f.`Data_Currency`, d.`Currency`)
		 END                                                          AS `FactorNR`
	FROM `Snapshot_day_by_day_fact2` f
	LEFT JOIN `campaign_deal_affiliate` d ON f.`Deal_Aff_id` = d.`id`
	WHERE f.`DATE` >= v_LMonthDate
),
-- Agregación diaria → mensual por dimensiones de comisión
monthly AS (
	SELECT
		 MAX(`Owner`)                                                 AS `Owner`
		,`Account_id`
		,`Month`
		,`Affiliate_id`
		,`Advertiser_id`
		,`Publisher_id`
		,SUM(`Qualified_Players`)                                     AS `CPA`
		,SUM(`Net_Revenue`)                                           AS `Net_Revenue`
		,ROUND(SUM(
			CASE WHEN `Deal_Aff_CPA` > 0
				THEN `Deal_Aff_CPA` * `Qualified_Players`
				ELSE `gross_CPA_Val_raw`
			END
		 ), 2)                                                        AS `gross_CPA_Val`
		,ROUND(SUM(
			CASE WHEN `Deal_Aff_RS` = 0 THEN 0
			     ELSE `Deal_Aff_RS` * `Net_Revenue` / 100 * `FactorNR`
			END
		 ), 2)                                                        AS `gross_RS_Val`
		,`Deal_Aff_id`
		,MAX(`Deal_Aff_CPA`)                                          AS `Deal_Aff_CPA`
		,MAX(`CarryOver`)                                             AS `CarryOver`
		,MAX(`CPAminusRS`)                                            AS `CPAminusRS`
		,`RS_Base`
		,MAX(`Deal_Aff_RS`)                                           AS `Deal_Aff_RS`
		,`Deal_Currency`
		,MAX(`Affiliate`)                                             AS `Affiliate`
		,`Brand`
		,MAX(`Product`)                                               AS `Product`
		,`Product_Real`
		,MAX(`Channel`)                                               AS `Channel`
		,`Channel_id`
		-- Clave de acumulación RS según Deal_Aff_RS_Base
		,CASE `RS_Base`
			WHEN 'account' THEN CONCAT('A|', `Affiliate_id`, '|', `Account_id`)
			WHEN 'operator' THEN CONCAT('O|', `Affiliate_id`, '|', `Publisher_id`)
			WHEN 'operator/brand' THEN CONCAT('OB|', `Affiliate_id`, '|', `Publisher_id`, '|', `Brand`)
			ELSE CONCAT('B|', `Affiliate_id`, '|', `Brand`)
		 END                                                          AS `KeyRSAcum`
	FROM src
	GROUP BY
		 `Account_id`, `Month`, `Affiliate_id`, `Advertiser_id`, `Publisher_id`
		,`Deal_Aff_id`, `RS_Base`, `Deal_Currency`, `Brand`, `Product_Real`, `Channel_id`
	HAVING `CPA` <> 0 OR MAX(`Deal_Aff_RS`) <> 0
),
-- Netting CPA vs RS (sin UNION): Against_CPA solo aplica con RS negativa
netted AS (
	SELECT
		 m.*
		,CASE
			WHEN m.`CPAminusRS` = 1 AND m.`gross_RS_Val` < 0 THEN
				CASE
					WHEN m.`gross_CPA_Val` >= ABS(m.`gross_RS_Val`)
					THEN m.`gross_CPA_Val` - ABS(m.`gross_RS_Val`)
					ELSE 0
				END
			ELSE m.`gross_CPA_Val`
		 END                                                          AS `net_CPA_Val`
		,CASE
			WHEN m.`Deal_Aff_RS` = 0 THEN 0
			WHEN m.`CPAminusRS` = 1 AND m.`gross_RS_Val` < 0 THEN
				CASE
					WHEN m.`gross_CPA_Val` >= ABS(m.`gross_RS_Val`)
					THEN 0
					ELSE m.`gross_CPA_Val` - ABS(m.`gross_RS_Val`)  -- remanente negativo
				END
			ELSE m.`gross_RS_Val`
		 END                                                          AS `net_RS_pre`
	FROM monthly m
),
-- Acumulación RS por Affiliate_id + KeyRSAcum + Month.
-- Si el neto del grupo es < 0 → RS neta = 0; si ≥ 0, solo filas con RS positiva
-- reciben un prorrateo del acumulado (net_RS_Val nunca negativo).
rs_acum AS (
	SELECT
		 `Month`
		,`Affiliate_id`
		,`KeyRSAcum`
		,SUM(`net_RS_pre`)                                            AS `net_RS_Acum`
		,SUM(CASE WHEN `net_RS_pre` > 0 THEN `net_RS_pre` ELSE 0 END) AS `net_RS_Pos`
	FROM netted
	GROUP BY `Month`, `Affiliate_id`, `KeyRSAcum`
),
final_rows AS (
	SELECT
		 n.`Owner`
		,n.`Account_id`
		,n.`Month`
		,n.`Affiliate`
		,n.`Brand`
		,n.`Affiliate_id`
		,n.`Advertiser_id`
		,n.`Deal_Currency`
		,n.`CPA`
		,n.`net_CPA_Val`
		,CASE
			WHEN a.`net_RS_Acum` <= 0 OR n.`net_RS_pre` <= 0 OR a.`net_RS_Pos` <= 0
			THEN 0
			ELSE ROUND(n.`net_RS_pre` * a.`net_RS_Acum` / a.`net_RS_Pos`, 2)
		 END                                                          AS `net_RS_Val`
		,n.`Net_Revenue`
		,n.`gross_CPA_Val`
		,n.`gross_RS_Val`
		,n.`Product`
		,n.`Product_Real`
		,n.`Channel`
		,n.`Channel_id`
	FROM netted n
	INNER JOIN rs_acum a
		ON a.`Month` = n.`Month`
	   AND a.`Affiliate_id` = n.`Affiliate_id`
	   AND a.`KeyRSAcum` = n.`KeyRSAcum`
)
SELECT
	 MAX(`Owner`)                                                     AS `Owner`
	,`Account_id`
	,'CPA+RS'                                                         AS `Comm_type`
	,`Month`
	,MAX(`Affiliate`)                                                 AS `Affiliate`
	,MAX(`Brand`)                                                     AS `Brand`
	,`Affiliate_id`
	,`Advertiser_id`
	,MAX(`Deal_Currency`)                                             AS `Deal_Currency`
	,ROUND(SUM(`CPA`), 0)                                             AS `CPA`
	,ROUND(SUM(`net_CPA_Val`), 2)                                     AS `net_CPA_Val`
	,ROUND(SUM(`net_RS_Val`), 2)                                      AS `net_RS_Val`
	,ROUND(SUM(`net_CPA_Val`) + SUM(`net_RS_Val`), 2)                 AS `net_Total_comm`
	,0                                                                AS `RS_carry_NCO`
	,ROUND(SUM(`Net_Revenue`), 2)                                     AS `Net_Revenue`
	,ROUND(SUM(`gross_CPA_Val`), 2)                                   AS `gross_CPA_Val`
	,ROUND(SUM(`gross_RS_Val`), 2)                                    AS `gross_RS_Val`
	,' '                                                              AS `Sub_Affiliate`
	,0                                                                AS `Sub_Affiliate_id`
	,MAX(`Product`)                                                   AS `Product`
	,MAX(`Product_Real`)                                              AS `Product_Real`
	,MAX(`Channel`)                                                   AS `Channel`
	,MAX(`Channel_id`)                                                AS `Channel_id`
FROM final_rows
GROUP BY `Affiliate_id`, `Account_id`, `Advertiser_id`, `Month`
ORDER BY `Affiliate_id`, `Account_id`, `Advertiser_id`, `Month`
;

-- =====================================================================
-- 2) Comisión Master Aff / Referrer
-- =====================================================================
INSERT IGNORE INTO `monthly_comms_affiliate_v5`
WITH Master_Sub AS (
	SELECT
		 M.`Master_Affiliate_id`                                      AS `Master_Affiliate_id`
		,MC.`username`                                                AS `Master`
		,M.`Sub_Affiliate_id`                                         AS `Sub_Affiliate_id`
		,AC.`username`                                                AS `Sub_Affiliate`
		,IFNULL(M.`Advertiser_id`, 0)                                 AS `Advertiser_id`
		,IFNULL(M.`Status_id`, '1')                                   AS `Status_id`
		,M.`Valid_From`
		,M.`Valid_To`
		,M.`Deal_id`
		,MD.`Deal_Name`
		,MD.`Commissions_Percentage`                                  AS `Perc_Com`
		,MD.`CPA_Value`                                               AS `ComByCPA`
		,MD.`RS_Percentage`                                           AS `RS%`
		,MD.`Deal_Currency`
	FROM `master_affiliate_deals_per_affiliate` M
	LEFT JOIN `account_account` AC        ON M.`Sub_Affiliate_id` = AC.`id`
	LEFT JOIN `account_account` MC        ON M.`Master_Affiliate_id` = MC.`id`
	LEFT JOIN `master_affiliate_deals` MD ON M.`Deal_id` = MD.`id`
)
SELECT
	 MAX(C.`Owner`)                                                   AS `Owner`
	,C.`Account_id`
	,'REFER'                                                          AS `Comm_type`
	,C.`Month`
	,MS.`Master`                                                      AS `Affiliate`
	,C.`Brand`
	,MS.`Master_Affiliate_id`                                         AS `Affiliate_id`
	,C.`Advertiser_id`
	,MS.`Deal_Currency`
	,SUM(C.`CPA`)                                                     AS `CPA`
	,SUM(C.`CPA` * MS.`ComByCPA`)                                     AS `net_CPA_Val`
	,0                                                                AS `net_RS_Val`
	,SUM(C.`CPA` * MS.`ComByCPA` + C.`net_Total_comm` * MS.`Perc_Com` / 100)
	                                                                  AS `net_Total_comm`
	,0                                                                AS `RS_carry_NCO`
	,0                                                                AS `Net_Revenue`
	,0                                                                AS `gross_CPA_Val`
	,0                                                                AS `gross_RS_Val`
	,C.`Affiliate`                                                    AS `Sub_Affiliate`
	,C.`Affiliate_id`                                                 AS `Sub_Affiliate_id`
	,C.`Product`
	,C.`Product_Real`
	,C.`Channel`
	,C.`Channel_id`
FROM `monthly_comms_affiliate_v5` C
INNER JOIN LATERAL (
	SELECT *
	FROM Master_Sub MS
	WHERE MS.`Sub_Affiliate_id` = C.`Affiliate_id`
	  AND MS.`Status_id` = '1'
	  AND (MS.`Advertiser_id` = 0 OR MS.`Advertiser_id` = C.`Advertiser_id`)
	  AND STR_TO_DATE(CONCAT(C.`Month`, '-01'), '%Y-%m-%d') >= MS.`Valid_From`
	  AND STR_TO_DATE(CONCAT(C.`Month`, '-01'), '%Y-%m-%d')
	      <= COALESCE(MS.`Valid_To`, v_CurrentMonthDate)
	ORDER BY MS.`Advertiser_id` DESC
	LIMIT 1
) AS MS
WHERE STR_TO_DATE(CONCAT(C.`Month`, '-01'), '%Y-%m-%d') >= v_LMonthDate
  AND C.`Comm_type` = 'CPA+RS'
GROUP BY
	 C.`Affiliate_id`, C.`Account_id`, C.`Advertiser_id`
	,C.`Month`, C.`Channel_id`, C.`Brand`, C.`Product`, C.`Product_Real`
	,MS.`Master`, MS.`Master_Affiliate_id`, MS.`Deal_Currency`
	,C.`Affiliate`
HAVING `net_Total_comm` <> 0
ORDER BY `Affiliate_id`, `Affiliate`
;

END$$
DELIMITER ;

/*
CALL monthly_comms_affiliate_v5('2026-03');
CALL monthly_comms_affiliate_v5(NULL);
CALL monthly_comms_affiliate_v5('');
*/
