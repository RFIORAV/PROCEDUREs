/* PATCH VARIOS

*/

-- REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`, `Procedure_call`, `Creation_Date`, `Last_Update`, `Operator`) 
-- VALUES (12, ' LM_Fact_x_Affiliate', ' LM_Fact_x_Affiliate', 'Reporte por Afiliado: Factura mes anterior', 'Resoconto per affiliato: Fattura del mese precedente', 0, 'call Dash_TotalByAffiliate(\'ViewGES\',\'ALL\',\'LM\',\'ALL\',\'EUR\',\'ROLLUP\');\r\n\r\n/*\r\n-- ----------------------------------------------------------------\r\n-- Fact_x_Affiliate_mes_anterior\r\n-- 24.03.2022\r\n-- 13.09.2022 Call\r\n-- 21.03.2024 Call proc v1.1\r\n-- ----------------------------------------------------------------\r\n\r\ncall Dash_TotalByAffiliate(\'ViewGES\',\'ALL\',\'LM\',\'ALL\',\'EUR\',\'ROLLUP\');\r\n\r\nSELECT Date,LEFT(DATE,7) as Date -- Brand -- \r\n	,Affiliate,Product_Real\r\n	,SUM(CPA           )	as CPA\r\n	,SUM(CPA_Value     )	as CPA_Value\r\n	,SUM(CPA_Val_AJ_RS )	as CPA_Val_AJ_RS\r\n	-- ,SUM(Net_Revenue   )	as Net_Revenue\r\n	,SUM(RS_Value      )	as RS_Value\r\n	,SUM(RS_AJUST      )	as RS_AJUST\r\n	,SUM(CPA_Val_AJ_RS+RS_AJUST) as TOTAL_AJUST\r\n-- 	,Aff_RS_Base AS \'BaseAcumula\',Aff_Carry_Over AS Carry,Aff_RS_Against_CPA AS RSrestaCPA,Aff_CPA AS \'ValxCPA\',Aff_RS AS \'RS\'\r\nFROM view_monthly_fact_aff2\r\nwhere LEFT(DATE,7)=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7)\r\nGROUP BY Affiliate WITH ROLLUP HAVING TOTAL_AJUST<>0 or CPA>0\r\n;\r\n*/', 0, NULL, NULL, '2022-04-07 01:17:06', '2024-03-21 18:44:14', 'SysOP');

SET FOREIGN_KEY_CHECKS = 0;
SET @DB=DATABASE();

CREATE TABLE IF NOT EXISTS `multi_query_20240321` (
   `id` INT(10) NOT NULL AUTO_INCREMENT,
   `title` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Descr_EN` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Descr_ES` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Descr_IT` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `is_Procedure` TINYINT(1) NOT NULL DEFAULT '0',
   `code` LONGTEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `is_Filter` TINYINT(1) NOT NULL DEFAULT '0',
   `params_Procedure` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Procedure_call` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Creation_Date` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
   `Last_Update` DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `Operator` VARCHAR(30) NULL DEFAULT 'SysOP' COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE
)
COLLATE 'utf8mb4_0900_ai_ci' ENGINE=InnoDB;
TRUNCATE `multi_query_20240321`;
INSERT INTO `multi_query_20240321` SELECT * FROM `multi_query`;

TRUNCATE TABLE `multi_query`;
INSERT INTO `multi_query` SELECT * FROM euroaffiliati2.multi_query WHERE @DB!="euroaffiliati2";
