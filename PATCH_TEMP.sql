/*    PATCH para uso temporal
      MODIFICAR ANTES DE USAR
*/

-- 12.11.2026

DROP TABLE `players_general_API_idx`;
call Report_players_general('genidx=yes');

-- 06.11.2026

-- ALTER TABLE `util_settings`
   -- CHANGE COLUMN `Value_01_MultiSelect` `Value_01_DataType` VARCHAR(15) NULL DEFAULT NULL AFTER `Value_01_Required`,
   -- CHANGE COLUMN `Value_02_MultiSelect` `Value_02_DataType` VARCHAR(15) NULL DEFAULT NULL AFTER `Value_02_Required`;
   
-- 05.11.2026

-- ALTER TABLE `multi_query` ADD COLUMN `Group_id` INT NULL DEFAULT 2 AFTER `Orden`;

-- 04.11.2026

-- SET FOREIGN_KEY_CHECKS = 0;

-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (46, '202610270832', '2026-10-27', NULL, 'new', 'Marketing Source editing in Operators, Brands and Accounts', 'You can now edit a Marketing Source directly from the Operators, Brands and Accounts modules.', 2, 1, '2026-10-27 20:48:12', '2026-11-04 09:40:13', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (47, '202611030914', '2026-11-03', 'latest', 'new', 'Players Report and Daily Detail in affiliate Reports', 'The Players Report and Daily Detail reports are now available in the Reports section of the affiliate menu.', 1, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (48, '202611030914', '2026-11-03', 'latest', 'new', 'Postback Report in manager menu', 'The Postback Report is now available in the manager menu.', 2, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (49, '202611030914', '2026-11-03', 'latest', 'new', 'Daily Postback Report in manager Dashboard', 'The manager Dashboard now includes the Daily Postback Report.', 3, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (50, '202611030914', '2026-11-03', 'latest', 'improvement', 'Operator accounts without a required Brand', 'You can now create operator accounts without selecting a Brand, and the CPA Limit field is now optional.', 1, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (51, '202611030914', '2026-11-03', 'latest', 'improvement', 'Totals stay visible while scrolling in reports', 'Totals in all affiliate and manager reports now stay fixed at the top while you scroll, so they are always visible.', 2, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');
-- REPLACE INTO `changelog` (`id`, `Version`, `Release_Date`, `Tag`, `Type`, `Title`, `Description`, `Order`, `Status_id`, `Creation_Date`, `Last_Update`, `User`) VALUES (52, '202611030914', '2026-11-03', 'latest', 'improvement', 'Informative tooltips on report columns', 'Some report columns now show an explanatory tooltip when you hover over them. Column names with extra information are underlined so you can easily spot them.', 3, 1, '2026-11-04 09:40:14', '2026-11-04 09:40:14', 'admin');


-- 03.11.2026

-- ALTER TABLE `dash_modules` CHANGE COLUMN `Settings` `Settings` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Query_params`;

-- INSERT IGNORE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (27, 'Daily Postback Report', '# CPA	Total number of CPA conversions for the period.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 12, 7, 4, 7, 0, 24, 'GridComponent', NULL, 'Report_Postback_daily', 'Display=Transpose,Mode=AFF', 'link=/affiliate/report-postback-daily;notice={title:\'Real-Time Webhook Notice:\',text:\'CPA figures shown for today and yesterday are provisional incoming events. Official CPA validation and final commission approval occur once operator API audits consolidate the statements (typically within 24-48 hours).\'}', 1, 1, 1, 11, 3, '2026-06-17 16:37:13', '2026-11-02 10:20:56', 'admin');
-- INSERT IGNORE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (28, 'Daily Postback Report', '# CPA	Total number of CPA conversions for the period.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 12, 10, 4, 10, 0, 0, 'GridComponent', NULL, 'Report_Postback_daily', 'Display=Transpose', 'link=/postback-report;notice={title:\'Real-Time Webhook Notice:\',text:\'CPA figures shown for today and yesterday are provisional incoming events. Official CPA validation and final commission approval occur once operator API audits consolidate the statements (typically within 24-48 hours).\'}', 1, 1, 0, 13, 2, '2026-11-02 16:37:13', '2026-11-03 11:02:44', 'admin');

-- INSERT IGNORE INTO `auth_menu` (`id`, `Code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`, `description`, `Creation_Date`, `Last_Update`) VALUES (98, 'affiliate_reports_players', 'Players Report', 'Activity', '/affiliate/report-players', '0', 46, 0, 0, '0', 7, 1, NULL, '2026-11-02 13:35:03', '2026-11-03 09:10:45');
-- INSERT IGNORE INTO `auth_menu` (`id`, `Code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`, `description`, `Creation_Date`, `Last_Update`) VALUES (99, 'affiliate_reports_daily', 'Daily Detail', 'BarChart2', '/affiliate/report-daily', '0', 46, 0, 0, '0', 6, 1, NULL, '2026-11-02 13:35:03', '2026-11-03 09:10:47');
-- INSERT IGNORE INTO `auth_menu` (`id`, `Code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`, `description`, `Creation_Date`, `Last_Update`) VALUES (100, 'postback_report', 'Postback Report', 'ChevronRight', '/postback-report', '0', 15, 0, 1, '0', 2, 1, '', '2024-10-05 13:35:03', '2026-11-03 11:07:05');

-- INSERT IGNORE INTO `auth_group_menu` (`id`, `group_id`, `menu_id`) VALUES (239, 5, 100);
-- INSERT IGNORE INTO `auth_group_menu` (`id`, `group_id`, `menu_id`) VALUES (238, 2, 100);
-- INSERT IGNORE INTO `auth_group_menu` (`id`, `group_id`, `menu_id`) VALUES (237, 3, 99);
-- INSERT IGNORE INTO `auth_group_menu` (`id`, `group_id`, `menu_id`) VALUES (236, 3, 98);
-- INSERT IGNORE INTO `auth_group_menu` (`id`, `group_id`, `menu_id`) VALUES (235, 3, 97);

-- DROP TABLE `account_notifications_session`;
-- CREATE TABLE `account_notifications_session` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `Account_id` INT NOT NULL,
   -- `last_modal_shown_at` DATETIME NULL DEFAULT NULL,
   -- `modal_snoozed_until` DATETIME NULL DEFAULT NULL,
   -- `dismissed_types` JSON NULL DEFAULT NULL,
   -- `Status_id` INT NOT NULL,
   -- `Creation_Date` DATETIME NOT NULL,
   -- `Last_Update` DATETIME NULL DEFAULT NULL,
   -- `Operator` VARCHAR(30) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- PRIMARY KEY (`id`) USING BTREE
-- )
-- COLLATE='utf8mb4_0900_ai_ci'
-- ENGINE=InnoDB
-- ;

-- SET FOREIGN_KEY_CHECKS = 0;
-- REPLACE INTO `auth_menu` (`id`, `Code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`, `description`, `Creation_Date`, `Last_Update`) VALUES (97, 'affiliate_reports_postback_daily', 'Postback Report', 'Activity', '/affiliate/report-postback-daily', '0', 46, 0, 0, '0', 5, 1, NULL, '2026-09-23 13:35:03', '2026-11-03 13:38:40');

-- DROP TABLE IF EXISTS `account_notifications_session`;
-- CREATE TABLE IF NOT EXISTS `players_general_API_idx` (
   -- `API` VARCHAR(20) NULL DEFAULT "netrefer",
   -- `Date` VARCHAR(7) NULL DEFAULT NULL,
   -- `Advertiser_id` INT NOT NULL DEFAULT '0',
   -- `Advertiser` VARCHAR(50) NULL DEFAULT NULL,
   -- `Username_id` INT NULL DEFAULT NULL,
   -- `Username` VARCHAR(50) NULL DEFAULT NULL,
   -- `Customer_Reference_ID` VARCHAR(50) NULL DEFAULT NULL,
   -- `Signup_Date` VARCHAR(7) NULL DEFAULT NULL,
   -- `Marketing_Source_Name` VARCHAR(50) NULL DEFAULT NULL,
   -- `Affiliate_id` INT NOT NULL DEFAULT '0',
   -- `Affiliate` VARCHAR(100) NOT NULL DEFAULT '',
   -- `Operator_id` INT NOT NULL DEFAULT '0',
   -- `Operator` VARCHAR(150) NULL DEFAULT NULL,
   -- `CPA_Processed_Date` VARCHAR(7) NULL DEFAULT NULL,
   -- `Deposits` DECIMAL(10,2) NULL DEFAULT NULL,
   -- `MS_id` INT NULL DEFAULT NULL,
   -- `Rev_Share_Aff` DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Net Revenue API * RS_Percentage/100 de campaign_deal_affiliate',
   -- `Rev_Share_Netw` DECIMAL(12,2) NOT NULL DEFAULT 0 COMMENT 'Net Revenue API * RS_Percentage/100 de campaign_deal_gestor',
   -- INDEX `Date` (`Date`) USING BTREE,
   -- INDEX `Advertiser_id` (`Advertiser_id`) USING BTREE,
   -- INDEX `Username_id` (`Username_id`) USING BTREE,
   -- INDEX `Signup_Date` (`Signup_Date`) USING BTREE,
   -- INDEX `CPA_Processed_Date` (`CPA_Processed_Date`) USING BTREE,
   -- INDEX `Customer_Reference_ID` (`Customer_Reference_ID`) USING BTREE,
   -- INDEX `Marketing_Source_Name` (`Marketing_Source_Name`) USING BTREE,
   -- INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE,
   -- INDEX `Operator_id` (`Operator_id`) USING BTREE,
   -- INDEX `MS_id` (`MS_id`) USING BTREE
-- );

-- call Report_players_general('genidx=yes');


-- 02.11.2026

-- ALTER TABLE `campaign_deal_affiliate` CHANGE COLUMN `RS_Base` `RS_Base` VARCHAR(30) NULL DEFAULT 'brand' COLLATE 'utf8mb4_0900_ai_ci' AFTER `RS_Percentage_Displayed`;
-- call Report_players_general('genidx=yes');
   
-- 01.11.2026

-- CREATE TABLE IF NOT EXISTS `players_admiralbet_API` (
   -- `ID` INT NOT NULL AUTO_INCREMENT,
   -- `Date` DATE NOT NULL COMMENT 'mese di riferimento (primo del mese)',
   -- `Advertiser` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Username` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Username_id` INT NOT NULL,
   -- `Customer_Reference_ID` VARCHAR(50) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Marketing_Source_Name` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Signup_Date` DATE NULL DEFAULT NULL,
   -- `Signup_Date_Type` VARCHAR(10) NULL DEFAULT NULL COMMENT 'exact | month' COLLATE 'utf8mb4_0900_ai_ci',
   -- `FTD_Date` DATE NULL DEFAULT NULL,
   -- `FTD_Date_Type` VARCHAR(10) NULL DEFAULT NULL COMMENT 'exact | month' COLLATE 'utf8mb4_0900_ai_ci',
   -- `CPA_Processed_Date` DATE NULL DEFAULT NULL,
   -- `Clicks` INT NULL DEFAULT '0',
   -- `Registrations` INT NULL DEFAULT '0',
   -- `Confirmations` INT NULL DEFAULT '0',
   -- `FTD` INT NULL DEFAULT '0',
   -- `Deposits` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Payouts` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Revenue` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Net_Commission` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Created_At` TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP),
   -- `Updated_At` TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   -- PRIMARY KEY (`ID`) USING BTREE,
   -- UNIQUE INDEX `uq_player_month` (`Username_id`, `Customer_Reference_ID`, `Date`) USING BTREE,
   -- INDEX `idx_date` (`Date`) USING BTREE,
   -- INDEX `idx_ms` (`Marketing_Source_Name`) USING BTREE,
   -- INDEX `idx_signup` (`Signup_Date`) USING BTREE,
   -- INDEX `idx_ftd` (`FTD_Date`) USING BTREE
-- )
-- COLLATE='utf8mb4_0900_ai_ci'
-- ;


-- 23.10.2026

-- TRUNCATE changelog;
-- INSERT IGNORE INTO changelog SELECT * FROM euroaffiliati_dev.changelog_copy;

-- 16.10.2026

-- INSERT IGNORE INTO `notification_type` (`id`, `Title`, `Description`, `Type`, `Subtype`, `Display_required`, `Priority`, `Status_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (11, 'New Reward Plan', 'Notifies the user when a new Reward Plan is available', 'New Reward Plan', '', 1, 'Medium', 1, '2026-09-25 10:03:43', '2026-09-25 10:03:43', '334');
-- robocopy "F:\_Jorge_HD_USB_Seagate" "H:" /E /Z /J /ETA /R:2 /W:2

-- 09.10.2026

-- INSERT IGNORE INTO `notification_type` (`id`, `Title`, `Description`, `Type`, `Subtype`, `Display_required`, `Priority`, `Status_id`, `Creation_Date`, `Last_Update`, `Operator`) 
-- VALUES (10, 'Warning SysOp', 'Notifies the user when a new Reward Plan is available', 'Warning SysOp', NULL, 1, 'Medium', 1, '2026-09-25 10:03:43', '2026-09-25 10:03:43', '334');

-- 07.10.2026

-- DROP TABLE `players_general_API_idx`;
-- call Report_players_general('genidx=yes');

-- 26.09.2026

-- INSERT IGNORE INTO `auth_menu` (`id`, `Code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`) 
-- VALUES (97, 'affiliate_reports_postback_daily', 'Daily Postback Report', 'Activity', '/affiliate/report-postback-daily', '0', 46, 0, 0, '0', 5, 0);

-- 24.09.2026

-- CALL Check_and_Notify_Reward_Plan('Init=Yes');

-- 23.09.2026

-- INSERT INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`, `Procedure_call`, `Orden`, `Creation_Date`, `Last_Update`, `Operator`)
 -- VALUES (85, 'Daily Postback Report', 'Daily Postback Report', 'Informe diario de postbacks', 'Report giornaliero dei postback', 1, 'Report_Postback_daily', 1, '', NULL, NULL, '2026-06-08 12:55:00', '2026-09-23 20:53:46', 'SysOP');

-- 15.09.2026

-- SET FOREIGN_KEY_CHECKS = 0;
-- ALTER TABLE `campaign_deal_affiliate_bonus_brand`
   -- ADD CONSTRAINT `FK_campaign_deal_affiliate_bonus_v2` 
   -- FOREIGN KEY (`Bonus_id`) REFERENCES `campaign_deal_affiliate_bonus_v2` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE;
-- ALTER TABLE `campaign_deal_affiliate_bonus_brand`
   -- DROP FOREIGN KEY `fk_aff_bonus_brand`;

-- ALTER TABLE `master_affiliate_deals_per_affiliate`
   -- ADD CONSTRAINT `FK_master_affiliate_deals_v2` FOREIGN KEY (`Deal_id`) REFERENCES `master_affiliate_deals_v2` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION,
   -- ADD CONSTRAINT `FK_account_account` FOREIGN KEY (`Master_Affiliate_id`) REFERENCES `account_account` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION,
   -- ADD CONSTRAINT `FK_account_account_2` FOREIGN KEY (`Sub_Affiliate_id`) REFERENCES `account_account` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION;
-- ALTER TABLE `master_affiliate_deals_per_affiliate`
   -- DROP FOREIGN KEY `master_affiliate_dea_Deal_id_39b018a5_fk_master_af`,
   -- DROP FOREIGN KEY `master_affiliate_dea_Master_Affiliate_id_b50b0363_fk_account_a`,
   -- DROP FOREIGN KEY `master_affiliate_dea_Sub_Affiliate_id_c664d092_fk_account_a`;

-- 12.09.2026

-- SET FOREIGN_KEY_CHECKS = 0;
-- CREATE TABLE IF NOT EXISTS `campaign_deal_affiliate_bonus_brand` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `Bonus_id` INT NOT NULL COMMENT 'FK a campaign_deal_affiliate_bonus.id',
   -- `Advertiser_id` INT NOT NULL COMMENT 'Brand (campaign_advertiser.id)',
   -- `Creation_Date` DATETIME NULL DEFAULT (now()),
   -- `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   -- `User` VARCHAR(30) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',   
   -- PRIMARY KEY (`id`) USING BTREE,
   -- UNIQUE INDEX `uk_bonus_advertiser` (`Bonus_id`, `Advertiser_id`) USING BTREE,
   -- INDEX `idx_advertiser` (`Advertiser_id`) USING BTREE,
   -- CONSTRAINT `fk_aff_bonus_brand` FOREIGN KEY (`Bonus_id`) REFERENCES `campaign_deal_affiliate_bonus` (`id`) ON UPDATE NO ACTION ON DELETE CASCADE
-- )
-- COMMENT='Brands de una regla bonus; sin filas = aplica a todas'
-- ;
-- CREATE TABLE IF NOT EXISTS  `campaign_deal_affiliate_bonus_v2` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `Affiliate_id` INT NOT NULL,
   -- `Code_to_Affiliate` VARCHAR(50) NULL DEFAULT NULL COMMENT 'NULL o vacío = todas las MS' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Description` VARCHAR(250) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Date_Valid_From` DATE NOT NULL COMMENT 'Inicio de vigencia (obligatorio)',
   -- `Date_Valid_to` DATE NULL DEFAULT NULL COMMENT 'NULL = permanente',
   -- `Bonus_Value` DECIMAL(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Importe fijo opcional; ver fórmula con Bonus_NR',
   -- `Bonus_Value_per_CPA` DECIMAL(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Importe fijo por cada CPA del mes filtrado',
   -- `Bonus_NR` DECIMAL(8,2) NOT NULL DEFAULT '0.00' COMMENT '% sobre NR acumulado del filtro; opcional si hay Bonus_Value',
   -- `Currency` VARCHAR(5) NULL DEFAULT 'EUR' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Conditions` VARCHAR(10) NOT NULL DEFAULT 'ANY' COMMENT 'ANY|ALL sobre umbrales CPA_min/NR_min/FTD_min (>0)' COLLATE 'utf8mb4_0900_ai_ci',
   -- `CPA_min` INT NOT NULL DEFAULT '0' COMMENT '0 = no aplica; CPA = SUM(Qualified_Players) del mes filtrado',
   -- `NR_min` INT NOT NULL DEFAULT '0' COMMENT '0 = no aplica; NR = SUM(Net_Revenue) del mes filtrado',
   -- `FTD_min` INT NOT NULL DEFAULT '0' COMMENT '0 = no aplica; FTD = SUM(First_Time_Deposit) del mes filtrado',
   -- `Status_id` SMALLINT NULL DEFAULT '1',
   -- `Status` VARCHAR(30) NULL DEFAULT 'Active' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Creation_Date` DATETIME NULL DEFAULT (now()),
   -- `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   -- `User` VARCHAR(30) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   -- PRIMARY KEY (`id`) USING BTREE,
   -- INDEX `idx_aff_dates` (`Affiliate_id`, `Date_Valid_From`, `Date_Valid_to`) USING BTREE,
   -- INDEX `idx_code_to_aff` (`Code_to_Affiliate`) USING BTREE,
   -- INDEX `idx_status_id` (`Status_id`) USING BTREE
-- )
-- COMMENT='Reglas bonus affiliate: fijo y/o %NR; brands en tabla hija (0 filas=all)'
-- ;
-- CREATE TABLE  IF NOT EXISTS  `master_affiliate_deals_v2` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `Deal_Name` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deal_Currency` VARCHAR(3) NULL DEFAULT 'EUR' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Perc_on_Tot_Comm` DECIMAL(12,2) NULL DEFAULT '0.00' COMMENT '% a aplicar sobre el Total Comm',
   -- `Value_by_CPA` DECIMAL(12,2) NULL DEFAULT '0.00' COMMENT 'Valor por cada CPA',
   -- `Perc_on_CPA_Value` DECIMAL(12,2) NULL DEFAULT NULL COMMENT '% a aplicar sobre el CPA_Net_Value',
   -- `Perc_on_RS` DECIMAL(12,2) NULL DEFAULT '0.00' COMMENT '% a aplicar sobre la RS_Net_Value',
   -- `Perc_on_Margin_value` DECIMAL(12,2) NULL DEFAULT NULL COMMENT '% a aplicar sobre el Margen del Network sobre el Afiliado',
   -- `Creation_Date` DATETIME NULL DEFAULT (now()),
   -- `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   -- `User` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- PRIMARY KEY (`id`) USING BTREE
-- )
-- ;
-- ALTER TABLE `master_affiliate_deals_v2`
   -- CHANGE COLUMN `Perc_on_CPA_Value` `Perc_on_CPA_Value` DECIMAL(12,2) NULL DEFAULT '0.00' COMMENT '% a aplicar sobre el CPA_Net_Value' AFTER `Value_by_CPA`,
   -- CHANGE COLUMN `Perc_on_Margin_value` `Perc_on_Margin_value` DECIMAL(12,2) NULL DEFAULT '0.00' COMMENT '% a aplicar sobre el Margen del Network sobre el Afiliado' AFTER `Perc_on_RS`;
   
-- INSERT INTO `master_affiliate_deals_v2` (`id`,`Deal_Name`,`Deal_Currency`,`Perc_on_Tot_Comm`, `Value_by_CPA`, `Perc_on_RS`, `Creation_Date`, `Last_Update`, `User`)
-- SELECT `id`,`Deal_Name`,`Deal_Currency`,`Commissions_Percentage`,`CPA_Value`,`RS_Percentage`,`Creation_Date`,`Last_Update`,`Operator` 
-- FROM master_affiliate_deals;

-- 08.09.2026

-- UPDATE `util_countries` SET Phone_prefix='+356' WHERE eu='Malta';

-- 05.08.2026

-- REPLACE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_01_MultiSelect`, `Value_02`, `Value_02_Options`, `Value_02_Required`, `Value_02_MultiSelect`) 
-- VALUES ('Fact2_Date_BeginToShow', 'Show Affiliate Data Starting From', 1, 1, 'YES', 'YES/NO', 1, 0, '2021-01-01', 'Date YYYY-MM-DD', 0, 0);

-- 24.07.2026

-- INSERT IGNORE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_01_MultiSelect`, `Value_02`, `Value_02_Options`, `Value_02_Required`, `Value_02_MultiSelect`) 
-- VALUES ('ProductEdition', 'Defines the available product variant (Lite or Network)', 0, 0, 'Network', 'Lite/Network', 1, 0, NULL, NULL, 0, 0);

-- 22.07.2026
/*
SET FOREIGN_KEY_CHECKS = 0;
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (1, 'CPA', 'Total CPA conversions for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=CPA', 'image=images/icons/dash/cpa.png;color=primary', 0, 1, 0, 1, 2, '2026-03-05 05:23:45', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (2, 'CPA Volume (€)', 'Total amount paid in CPAs.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=CPA_Value', 'image=images/icons/dash/cpa-volumen.png;color=success', 0, 1, 0, 2, 2, '2026-03-05 07:00:58', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (3, 'Rev Share Volume (€)', 'Total revenue generated by Rev Share.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=RS_Val', 'image=images/icons/dash/rev-share.png;color=info', 0, 1, 0, 3, 2, '2026-03-05 07:00:58', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (4, 'Gross Commission (€)', 'Total gross commission for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=Tot_Comm', 'image=images/icons/dash/gross-commision.png;color=danger', 0, 1, 0, 4, 2, '2026-03-05 07:00:58', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (5, 'CPA Profit (€)', 'Net profit obtained from CPAs.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=CPA_Profit', 'image=images/icons/dash/gross-commision.png;color=warning', 0, 1, 0, 5, 2, '2026-03-05 07:00:58', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (6, 'Gross Margin (€)', 'Total gross margin for the period', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info', 'Metric=Profit', 'image=images/icons/dash/gross-commision.png;color=secondary', 0, 1, 0, 6, 2, '2026-03-05 07:00:58', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (7, 'Operators Performance', 'Consolidated performance by operator and brand.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 6, 7, 4, 7, 0, 0, 'GridComponent', NULL, 'Dash_Gestor_TotalByAdvertiser', NULL, NULL, 0, 1, 0, 7, 2, '2026-02-20 07:47:19', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (8, 'Account Performance', 'Consolidated performance by account and brand.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 6, 7, 4, 7, 0, 0, 'GridComponent', NULL, 'Dash_Gestor_TotalByAdvertiser', 'ByAccount=yes', NULL, 0, 1, 0, 8, 2, '2026-02-20 07:47:19', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (9, 'Affiliate Activity by Brand', 'Affiliate activity broken down by brand.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 3, 7, 3, 7, 0, 0, 'GridComponent', NULL, 'CPA_ByAFFILIATE_BrandMatrix', 'View=ViewGES', NULL, 0, 1, 0, 9, 2, '2026-02-20 07:47:19', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (10, 'Key indicator\'s evolution', 'Key indicators evolution over time by owner.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 6, 7, 4, 7, 0, 0, 'GridComponent', NULL, 'Report_Snapshots_Dashboards', NULL, NULL, 1, 1, 0, 10, 2, '2026-02-20 07:47:19', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (11, 'Notifications Timeline', 'Timeline of recent system notifications and events', 'free', 'List', NULL, 4, 7, 4, 7, 0, 0, 'NotificationsComponent', ' ', '-', '', 'link=/notifications;', 0, 1, 0, 11, 2, '2026-03-02 16:37:13', '2026-06-23 08:02:49', NULL);
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (12, 'Balance Affiliates', 'Affiliate balances consolidated by account and brand.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 6, 7, 4, 7, 0, 0, 'GridComponent', NULL, 'Report_balance_by_affiliate', NULL, NULL, 1, 1, 0, 12, 2, '2026-02-20 07:47:19', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (13, 'Confirmed Balance', 'Total balance confirmed for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=conf_balance', 'icon=DollarSign;color=success', 0, 1, 1, 1, 3, '2026-06-17 16:37:13', '2026-06-23 08:02:49', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (14, 'Estimated Balance', 'Total estimated balance pending confirmation.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 2, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=est_balance', 'icon=DollarSign;color=primary', 0, 1, 1, 2, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:32', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (15, 'Signups', 'Total number of registered users for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 4, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=SignUp', 'icon=UserPlus;color=info', 0, 1, 1, 3, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:35', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (16, 'FTD', 'Total number of First Time Depositors (FTD).', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 6, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=FTD', 'icon=FileText;color=danger', 0, 1, 1, 4, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:37', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (17, '# CPA', 'Total number of CPA conversions for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 8, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=CPA', 'icon=Award;color=warning', 0, 1, 1, 5, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:40', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (18, 'Commission', 'Total commission generated for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 10, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=Tot_Comm', 'icon=DollarSign;color=secondary', 0, 1, 1, 6, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:42', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (19, 'Activity by Brand', 'Consolidated activity performance by brand.', 'free', 'Grid', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/grid-dinamic.png', 12, 7, 4, 7, 0, 3, 'GridComponent', NULL, 'Dash_BrandMatrix', 'View=ViewAFF,ByDay=yes', NULL, 0, 1, 1, 7, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:44', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (20, 'Signups/FTD/CPA', 'Weekly consolidated metrics for Signups, FTDs, and CPA conversions.', 'free', 'Activity', NULL, 6, 7, 4, 7, 0, 10, 'AreaChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=AreaChart,Metric=ALL', NULL, 0, 1, 1, 8, 3, '2026-06-17 16:37:13', '2026-07-18 06:21:05', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (21, 'CPA Percentages', 'Percentages based on CPA.', 'free', 'PieChart', NULL, 6, 7, 4, 7, 6, 10, 'DonutChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=DonutChart', NULL, 0, 1, 1, 9, 3, '2026-06-17 16:37:13', '2026-06-23 08:15:50', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (22, 'Notifications Timeline', 'Timeline of recent system notifications and events', 'free', 'List', NULL, 6, 7, 4, 7, 0, 17, 'NotificationsComponent', ' ', '-', NULL, 'link=/notifications;', 0, 1, 1, 10, 3, '2026-06-17 16:37:13', '2026-06-23 08:17:15', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (23, 'Rev. Share', 'Total revenue generated by Rev Share.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=RS_VAL', 'icon=DollarSign;color=success,visibilityCheck={procedure=Check_RS_affiliate,field=RS_Status}', 0, 1, 0, 11, 3, '2026-06-17 16:37:13', '2026-07-17 07:00:58', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (24, 'Signups/FTD/CPA (Last 4 Weeks)', 'Weekly consolidated metrics for Signups, FTDs, and CPA conversions.', 'free', 'Activity', NULL, 6, 7, 4, 7, 0, 0, 'AreaChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=AreaChartL4W,Metric=ALL', NULL, 0, 1, 0, 12, 3, '2026-06-17 16:37:13', '2026-07-18 06:21:11', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (25, 'Commissions', 'Total revenue after adjustments, representing actual earnings.', 'free', 'Activity', NULL, 6, 7, 4, 4, 0, 0, 'AreaChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=AreaChart,Metric=RS', NULL, 0, 1, 0, 13, 3, '2026-07-03 16:37:13', '2026-07-18 06:22:31', 'admin');
REPLACE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (26, 'CPA Value', '# CPA	Total number of CPA conversions for the period.', 'free', 'Image', 'https://storage.cloud.google.com/affiliatteaccess.appspot.com/app-assets/images/dash/stat-component.png', 2, 3, 2, 3, 0, 0, 'StatComponent', NULL, 'Dash_info_Aff', 'Metric=CPA_VALUE', 'icon=DollarSign;color=warning', 0, 1, 0, 14, 3, '2026-06-17 16:37:13', '2026-07-16 11:07:53', 'admin');
*/
-- 20.07.2026

-- ALTER TABLE `Snapshot_day_by_day_fact1` ADD COLUMN `Reward_plan` VARCHAR(250) NULL DEFAULT NULL AFTER `Deal_Aff`;

-- 17.07.2026

-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE multi_query;
-- INSERT INTO multi_query SELECT * FROM euroaffiliati_dev.multi_query where database()!="euroaffiliati_dev";

-- 15.07.2026

-- ALTERCMD
-- ALTER TABLE util_settings 
   -- ADD COLUMN `Value_01_MultiSelect` tinyint NULL DEFAULT 0 AFTER `Value_01_Required`,
   -- ADD COLUMN `Value_02_MultiSelect` tinyint NULL DEFAULT 0 AFTER `Value_02_Required`,
   -- CHANGE COLUMN `Value_02` `Value_02` varchar(200) NULL DEFAULT NULL AFTER `Value_01_MultiSelect`,
   -- CHANGE COLUMN `Value_02_Options` `Value_02_Options` text NULL DEFAULT NULL AFTER `Value_02`,
   -- CHANGE COLUMN `Value_02_Required` `Value_02_Required` tinyint NULL DEFAULT 0 AFTER `Value_02_Options`,
   -- CHANGE COLUMN `Value_03` `Value_03` varchar(200) NULL DEFAULT NULL AFTER `Value_02_MultiSelect`,
   -- CHANGE COLUMN `Creation_Date` `Creation_Date` datetime NULL DEFAULT now()  AFTER `Value_03`,
   -- CHANGE COLUMN `Last_Update` `Last_Update` datetime NULL DEFAULT now()  on update CURRENT_TIMESTAMP AFTER `Creation_Date`,
   -- CHANGE COLUMN `Operator` `Operator` varchar(30) NULL DEFAULT ' ' AFTER `Last_Update`;

-- INSERT IGNORE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_01_MultiSelect`, `Value_02`, `Value_02_Options`, `Value_02_Required`, `Value_02_MultiSelect`, `Value_03`) 
-- VALUES ('AllowedPaymentMethods', 'Specifies the allowed payment methods', 0, 1, 'BankTransfer/CreditCard/Crypto', 'BankTransfer/CreditCard/Paypal/Crypto', 1, 1, '', NULL, 0, 0, '');

-- 10.07.2026 -- Karen

-- ALTER TABLE dash_favorite_account ADD UNIQUE KEY uq_favorite_affiliate (Favorite_id, Affiliate_id);

-- 08.07.2026

-- INSERT IGNORE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (24, 'Signups/FTD/CPA/Clicks (Last 4 Weeks)', 'Weekly consolidated metrics for Signups, FTDs, and CPA conversions.', 'free', 'Activity', NULL, 6, 7, 4, 7, 0, 0, 'AreaChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=AreaChartL4W,Metric=ALL', NULL, 0, 1, 0, 12, 3, '2026-06-17 16:37:13', '2026-07-04 07:25:33', 'admin');
-- INSERT IGNORE INTO `dash_modules` (`id`, `Title`, `Description`, `Plan`, `Icon`, `Preview`, `Default_w`, `Default_h`, `Min_w`, `Min_h`, `Position_x`, `Position_y`, `Component`, `Sub_component`, `Query_procedure`, `Query_params`, `Settings`, `Is_filter`, `Is_active`, `Is_default`, `Order`, `Group_id`, `Creation_Date`, `Last_Update`, `Operator`) VALUES (25, 'Net Revenue Vs Commissions', 'Total revenue after adjustments, representing actual earnings.', 'free', 'Activity', NULL, 6, 7, 4, 4, 0, 0, 'AreaChart', NULL, 'Dash_Mob_Aff_BrandByWeek', 'Brand=ALL,Style=AreaChart,Metric=NR', NULL, 0, 1, 0, 12, 3, '2026-07-03 16:37:13', '2026-07-08 20:34:39', 'admin');

-- 07.07.2026

-- ALTER TABLE api_emaillog 
   -- ADD COLUMN template_name VARCHAR(100) NULL DEFAULT NULL, 
   -- ADD COLUMN template_context JSON NULL DEFAULT NULL;

-- 29.06.2026

-- CREATE TABLE IF NOT EXISTS flutter_affilyn_business_profiles     LIKE euroaffiliati_dev.flutter_affilyn_business_profiles    ;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_campaign_kpis_daily   LIKE euroaffiliati_dev.flutter_affilyn_campaign_kpis_daily  ;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_campaigns             LIKE euroaffiliati_dev.flutter_affilyn_campaigns            ;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_marketing_sources     LIKE euroaffiliati_dev.flutter_affilyn_marketing_sources    ;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_partner_summary       LIKE euroaffiliati_dev.flutter_affilyn_partner_summary      ;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_partner_summary_games LIKE euroaffiliati_dev.flutter_affilyn_partner_summary_games;
-- CREATE TABLE IF NOT EXISTS flutter_affilyn_sync_log              LIKE euroaffiliati_dev.flutter_affilyn_sync_log             ;
-- CREATE TABLE IF NOT EXISTS gambling_day_by_day_flutter_affilyn   LIKE euroaffiliati_dev.gambling_day_by_day_flutter_affilyn  ;
-- CREATE TABLE IF NOT EXISTS player_flutter_affilyn                LIKE euroaffiliati_dev.player_flutter_affilyn               ;

-- 25.06.2026

-- Update util_settings u
-- inner join euroaffiliati_dev.util_settings udev on u.Setting=udev.Setting
-- set u.Description=udev.Description
-- ;

-- 24.06.2026

-- INSERT INTO `util_settings` ( `Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_02`, `Value_02_Options`, `Value_02_Required`) 
-- VALUES ('EnforceBaseline', 'EnforceBaseline', 1, 0, 'NO', 'YES/NO', 1, NULL, NULL, 0);

-- ALTER TABLE `players_general_API_idx`
   -- CHANGE COLUMN `Affiliate_id` `Affiliate_id` INT NOT NULL DEFAULT '0' AFTER `Marketing_Source_Name`,
   -- ADD COLUMN `Deposits` DECIMAL(10,2) NULL DEFAULT NULL AFTER `CPA_Processed_Date`,
   -- ADD COLUMN `MS_id` INT NULL DEFAULT NULL AFTER `Deposits`,
   -- DROP INDEX `Affiliate_id`,
   -- ADD INDEX `Affiliate_id` (`Affiliate_id`) USING BTREE,
   -- ADD INDEX `MS_id` (`MS_id`);
   
-- call Report_players_general('genidx=yes');   

-- 23.06.2026

-- ALTERCMD
-- ALTER TABLE dash_modules 
      -- ADD COLUMN `Position_x` int NULL DEFAULT NULL AFTER `Min_h`,
      -- ADD COLUMN `Position_y` int NULL DEFAULT NULL AFTER `Position_x`,
      -- ADD COLUMN `Is_default` tinyint(1) NULL DEFAULT NULL AFTER `Is_active`,
      -- CHANGE COLUMN `Title` `Title` varchar(255) NULL DEFAULT NULL AFTER `id`,
      -- CHANGE COLUMN `Plan` `Plan` varchar(4) NULL DEFAULT 'free' AFTER `Description`,
      -- CHANGE COLUMN `Default_w` `Default_w` int NULL DEFAULT NULL AFTER `Preview`,
      -- CHANGE COLUMN `Default_h` `Default_h` int NULL DEFAULT NULL AFTER `Default_w`,
      -- CHANGE COLUMN `Min_w` `Min_w` int NULL DEFAULT NULL AFTER `Default_h`,
      -- CHANGE COLUMN `Min_h` `Min_h` int NULL DEFAULT NULL AFTER `Min_w`,
      -- CHANGE COLUMN `Component` `Component` varchar(100) NULL DEFAULT NULL AFTER `Position_y`,
      -- CHANGE COLUMN `Sub_component` `Sub_component` varchar(100) NULL DEFAULT NULL AFTER `Component`,
      -- CHANGE COLUMN `Query_procedure` `Query_procedure` varchar(255) NULL DEFAULT NULL AFTER `Sub_component`,
      -- CHANGE COLUMN `Query_params` `Query_params` varchar(500) NULL DEFAULT NULL AFTER `Query_procedure`,
      -- CHANGE COLUMN `Settings` `Settings` varchar(255) NULL DEFAULT NULL AFTER `Query_params`,
      -- CHANGE COLUMN `Is_filter` `Is_filter` tinyint(1) NULL DEFAULT 0 AFTER `Settings`,
      -- CHANGE COLUMN `Is_active` `Is_active` tinyint(1) NULL DEFAULT 1 AFTER `Is_filter`,
      -- CHANGE COLUMN `Order` `Order` int NULL DEFAULT NULL AFTER `Is_default`,
      -- CHANGE COLUMN `Group_id` `Group_id` int NULL DEFAULT NULL AFTER `Order`,
      -- CHANGE COLUMN `Creation_Date` `Creation_Date` datetime NULL DEFAULT now()  AFTER `Group_id`,
      -- CHANGE COLUMN `Last_Update` `Last_Update` datetime NULL DEFAULT now()  on update CURRENT_TIMESTAMP AFTER `Creation_Date`,
      -- CHANGE COLUMN `Operator` `Operator` varchar(30) NULL DEFAULT NULL AFTER `Last_Update`;

-- 22.06.2026

-- ALTER TABLE `account_notifications` ADD INDEX `Affiliate_id` (`Affiliate_id`);
-- ALTER TABLE `account_notifications` ADD INDEX `Date` (`Date`);
-- ALTER TABLE account_notifications   ADD INDEX idx_read_status_date (Read_Status, `Date` DESC);  
 
/*
CREATE TABLE IF NOT EXISTS `campaign_log_dashboard_now` (
   `Meta` VARCHAR(7) NULL DEFAULT NULL,
   `Date` VARCHAR(22) NULL DEFAULT NULL,
   `Owner_id` VARCHAR(50) NULL DEFAULT NULL,
   `Owner` VARCHAR(100) NULL DEFAULT NULL,
   `Operator` VARCHAR(150) NULL DEFAULT NULL,
   `Brand` VARCHAR(150) NULL DEFAULT NULL,
   `Status Brand` VARCHAR(80) NULL DEFAULT NULL,
   `Account` VARCHAR(9) NULL DEFAULT NULL,
   `Status Account` VARCHAR(30) NULL DEFAULT NULL,
   `Curr` VARCHAR(11) NULL DEFAULT NULL,
   `CPA Cap` VARCHAR(57) NULL DEFAULT NULL,
   `Signups` VARCHAR(66) NULL DEFAULT NULL,
   `FTD` VARCHAR(66) NULL DEFAULT NULL,
   `CPA` VARCHAR(58) NULL DEFAULT NULL,
   `CPA Value` VARCHAR(67) NULL DEFAULT NULL,
   `Net Revenue` VARCHAR(67) NULL DEFAULT NULL,
   `Rev Share` VARCHAR(67) NULL DEFAULT NULL,
   `Total Comm` VARCHAR(67) NULL DEFAULT NULL,
   `Profit` VARCHAR(67) NULL DEFAULT NULL,
   `Aff Curr` VARCHAR(11) NULL DEFAULT NULL,
   `Aff CPA Val` VARCHAR(67) NULL DEFAULT NULL,
   `Aff Rev Share` VARCHAR(67) NULL DEFAULT NULL,
   `Aff Tot Comm` VARCHAR(67) NULL DEFAULT NULL,
   `Aff CPA` VARCHAR(42) NULL DEFAULT NULL,
   `Aff RS` VARCHAR(42) NULL DEFAULT NULL,
   `Area` VARCHAR(50) NULL DEFAULT NULL,
   `RS COver Pend` VARCHAR(51) NULL DEFAULT NULL,
   `CPA_Value` VARCHAR(67) NULL DEFAULT NULL,
   `Net_Rev` VARCHAR(67) NULL DEFAULT NULL,
   `RS_Val` VARCHAR(67) NULL DEFAULT NULL,
   `Tot_Comm` VARCHAR(67) NULL DEFAULT NULL,
   `AfCom_cpa` VARCHAR(67) NULL DEFAULT NULL,
   `AfCom_rs` VARCHAR(67) NULL DEFAULT NULL,
   `AfCom_tot` VARCHAR(67) NULL DEFAULT NULL,
   `Publisher_id` VARCHAR(20) NULL DEFAULT NULL,
   `DashMonth` VARCHAR(7) NULL DEFAULT NULL,
   `Date_gen` DATETIME NULL DEFAULT NULL,
   INDEX `DashMonth` (`DashMonth`, `Date_gen`) USING BTREE
);
*/
-- 19.06.2026

-- ALTER TABLE `dash_modules`  ADD COLUMN `Group_id` INT NULL AFTER `Order`;

-- 17.06.2026

-- ALTER TABLE auth_menu                        CHANGE COLUMN `Code` `Code` VARCHAR(50) NULL DEFAULT NULL;
-- ALTER TABLE campaign_mkt_source_deal         CHANGE COLUMN `Code` `Code` VARCHAR(50) NULL DEFAULT NULL;                        

-- 16.06.2026

-- ALTER TABLE `campaign_marketing_source` DROP INDEX `ms_Code_id`;
-- TRUNCATE TABLE players_netrefer_API_idx;

-- 14.06.2026

-- CREATE TABLE IF NOT EXISTS `players_referon_API` (
   -- `ID` INT NOT NULL AUTO_INCREMENT,
   -- `Date` DATE NOT NULL,
   -- `Advertiser` VARCHAR(100) NOT NULL,
   -- `Username` VARCHAR(100) NOT NULL,
   -- `Username_id` VARCHAR(50) NOT NULL,
   -- `Prodotto` VARCHAR(100) NOT NULL,
   -- `Date_col` VARCHAR(50) NULL DEFAULT NULL,
   -- `Product_ID` VARCHAR(100) NULL DEFAULT NULL,
   -- `Product_Name` VARCHAR(255) NULL DEFAULT NULL,
   -- `Brand_ID` VARCHAR(100) NULL DEFAULT NULL,
   -- `Brand_Name` VARCHAR(255) NULL DEFAULT NULL,
   -- `Marketing_Source_ID` VARCHAR(100) NULL DEFAULT NULL,
   -- `Marketing_Source` VARCHAR(255) NULL DEFAULT NULL,
   -- `Customer_ID` VARCHAR(255) NULL DEFAULT NULL,
   -- `Customer_Reg__Date` VARCHAR(255) NULL DEFAULT NULL,
   -- `Geo` VARCHAR(100) NULL DEFAULT NULL,
   -- `Rewarding_Plan` VARCHAR(255) NULL DEFAULT NULL,
   -- `Click_Count` VARCHAR(50) NULL DEFAULT NULL,
   -- `Unique_Click_Count` VARCHAR(50) NULL DEFAULT NULL,
   -- `Reg__Count` VARCHAR(50) NULL DEFAULT NULL,
   -- `FTD_Count` VARCHAR(50) NULL DEFAULT NULL,
   -- `Reg__to_FTD` VARCHAR(50) NULL DEFAULT NULL,
   -- `Bonuses` VARCHAR(100) NULL DEFAULT NULL,
   -- `Deposits` VARCHAR(100) NULL DEFAULT NULL,
   -- `CPA_count` VARCHAR(50) NULL DEFAULT NULL,
   -- `Turnover` VARCHAR(100) NULL DEFAULT NULL,
   -- `NGR` VARCHAR(100) NULL DEFAULT NULL,
   -- `Revenue_Share` VARCHAR(100) NULL DEFAULT NULL,
   -- `CPA` VARCHAR(100) NULL DEFAULT NULL,
   -- `CPC` VARCHAR(100) NULL DEFAULT NULL,
   -- `Fixed_Fee` VARCHAR(100) NULL DEFAULT NULL,
   -- `Deductions` VARCHAR(100) NULL DEFAULT NULL,
   -- `Created_At` TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP),
   -- `Updated_At` TIMESTAMP NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   -- PRIMARY KEY (`ID`) USING BTREE,
   -- INDEX `idx_date` (`Date`) USING BTREE,
   -- INDEX `idx_username` (`Username`) USING BTREE,
   -- INDEX `idx_username_id` (`Username_id`) USING BTREE,
   -- INDEX `idx_advertiser` (`Advertiser`) USING BTREE,
   -- INDEX `idx_prodotto` (`Prodotto`) USING BTREE,
   -- INDEX `idx_date_username_product` (`Date`, `Username_id`, `Prodotto`) USING BTREE
-- )
-- ;

-- 13.06.2026

-- INSERT IGNORE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`) 
-- VALUES ('WithdrawalInvoiceEmail', 'WithdrawalInvoiceEmail', 1, 1, 'finance@affiliateaccess.com', NULL, 1);

-- 11.06.2026

-- UPDATE `auth_menu` set title='Balance' WHERE `Code`='report_operator_balance';
-- DROP EVENT IF EXISTS Snapshot_day_by_day_fact1_event_AR;

-- 09.06.2026

-- SET FOREIGN_KEY_CHECKS = 0;

-- TRUNCATE auth_group_menu;
-- TRUNCATE auth_menu;
-- TRUNCATE multi_query;

-- INSERT INTO auth_group_menu SELECT * FROM euroaffiliati2.auth_group_menu;
-- INSERT INTO auth_menu       SELECT * FROM euroaffiliati2.auth_menu;
-- INSERT INTO multi_query     SELECT * FROM euroaffiliati2.multi_query;


-- 08.06.2026

-- REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`) 
-- VALUES (82, 'Report DbD MANUAL', 'Report MANUAL data', 'Reporte de datos MANUAL', 'Report di dati MANUALI', 1, 'Report_day_by_day', 1, '');

-- ALTER TABLE `campaign_publisher_invoice`
   -- ADD INDEX `Invoice_proforma_key` (`Owner_id`, `Publisher_id`, `Invoiced_Month`, `Brand`, `Account`) USING BTREE;

-- 02.06.2026

-- UPDATE account_payment_methods SET verified=1 WHERE verified IS NULL;

-- ALTER TABLE `Snapshot_day_by_day_manual`
   -- ADD COLUMN `Origin` VARCHAR(50) NOT NULL DEFAULT 'user' COMMENT 'Origen: user/autoCapExcess' AFTER `id`;  
   -- ALTER TABLE `util_settings`
   -- CHANGE COLUMN `Value_01_Required` `Value_01_Required` TINYINT NULL DEFAULT '1' AFTER `Value_01_Options`,
   -- CHANGE COLUMN `Value_02_Required` `Value_02_Required` TINYINT NULL DEFAULT '0' AFTER `Value_02_Options`;
   -- REPLACE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`) 
   -- VALUES ('EnforceCapCPA', 'EnforceCapCPA', 1, 0, 'NO', 'YES/NO', 1);

-- 28.05.2025

-- ALTER TABLE `auth_menu`
   -- CHANGE COLUMN `description` `description` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `status_id`;

-- ALTER TABLE `Snapshot_day_by_day_manual`
   -- ADD COLUMN `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP), 
   -- ADD COLUMN `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,    
   -- ADD COLUMN `User` VARCHAR(30) NULL DEFAULT NULL;

-- 26.05.2025

-- INSERT IGNORE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_02`) 
            -- VALUES ('EnableAffEditPaymentsMethod', 'EnableAffEditPaymentsMethod', 1, 1, 'NO', 'YES/NO', 1, NULL);
-- INSERT IGNORE INTO `util_settings` (`Setting`, `Description`, `Show_enabled`, `Edit_enabled`, `Value_01`, `Value_01_Options`, `Value_01_Required`, `Value_02`) 
            -- VALUES ('RequireTaxInformation', 'RequireTaxInformation', 1, 1, 'yes', 'YES/NO', 1, NULL);

-- 25.05.2026

-- RENAME TABLE gambling_day_by_day_pokerstars TO gambling_day_by_day_flutter;

-- 21.05.2026

-- ALTER TABLE `account_account`
   -- CHANGE COLUMN `is_admin` `is_admin` TINYINT NULL DEFAULT '0' AFTER `last_login`,
   -- CHANGE COLUMN `is_active` `is_active` TINYINT NULL DEFAULT '1' AFTER `is_admin`,
   -- CHANGE COLUMN `is_staff` `is_staff` TINYINT NULL DEFAULT '0' AFTER `is_active`,
   -- CHANGE COLUMN `is_superuser` `is_superuser` TINYINT NULL DEFAULT '0' AFTER `is_staff`,
   -- ADD COLUMN `is_internal_company` TINYINT NULL DEFAULT '0' AFTER `is_superuser`;

-- ALTER TABLE `account_financial_movement` CHANGE COLUMN `Legal_Entity_id` `Owner` INT NULL DEFAULT NULL AFTER `Extra`;

-- 15.05.2026

/* 
ALTER TABLE players_mexos_API 
    ADD COLUMN `Commissioni_Flat` varchar(50) NULL DEFAULT NULL AFTER `Commissioni_RS`
   ,ADD COLUMN `Bingo_Commissioni` varchar(50) NULL DEFAULT NULL AFTER `Casino_Commissioni`
   ,CHANGE COLUMN `Casino_Commissioni` `Casino_Commissioni` varchar(50) NULL DEFAULT NULL AFTER `Commissioni_Flat`
   ,CHANGE COLUMN `Poker_commissioni` `Poker_commissioni` varchar(50) NULL DEFAULT NULL AFTER `Bingo_Commissioni`
   ,CHANGE COLUMN `Scommesse_commissioni` `Scommesse_commissioni` varchar(50) NULL DEFAULT NULL AFTER `Poker_commissioni`
   ,CHANGE COLUMN `Slot_commissioni` `Slot_commissioni` varchar(50) NULL DEFAULT NULL AFTER `Scommesse_commissioni`
   ,CHANGE COLUMN `Commissioni_CPA1` `Commissioni_CPA1` varchar(50) NULL DEFAULT NULL AFTER `Slot_commissioni`
   ,CHANGE COLUMN `Casino_giocato_netto` `Casino_giocato_netto` varchar(50) NULL DEFAULT NULL AFTER `Commissioni_CPA1`
   ,CHANGE COLUMN `Casino_NGR` `Casino_NGR` varchar(50) NULL DEFAULT NULL AFTER `Casino_giocato_netto`
   ,CHANGE COLUMN `Poker_giocato` `Poker_giocato` varchar(50) NULL DEFAULT NULL AFTER `Casino_NGR`
   ,CHANGE COLUMN `Poker_NGR` `Poker_NGR` varchar(50) NULL DEFAULT NULL AFTER `Poker_giocato`
   ,CHANGE COLUMN `Scommesse_giocato` `Scommesse_giocato` varchar(50) NULL DEFAULT NULL AFTER `Poker_NGR`
   ,CHANGE COLUMN `Scommesse_NGR` `Scommesse_NGR` varchar(50) NULL DEFAULT NULL AFTER `Scommesse_giocato`
   ,CHANGE COLUMN `Slot_giocato` `Slot_giocato` varchar(50) NULL DEFAULT NULL AFTER `Scommesse_NGR`
   ,CHANGE COLUMN `Slot_NGR` `Slot_NGR` varchar(50) NULL DEFAULT NULL AFTER `Slot_giocato`
   ,CHANGE COLUMN `Method` `Method` int NULL DEFAULT NULL AFTER `Slot_NGR`
   ,CHANGE COLUMN `Customer_Reference_ID` `Customer_Reference_ID` varchar(100) NULL DEFAULT NULL AFTER `Method`
   ,CHANGE COLUMN `Alias` `Alias` varchar(100) NULL DEFAULT NULL AFTER `Customer_Reference_ID`
   ,CHANGE COLUMN `AffiliateID` `AffiliateID` varchar(100) NULL DEFAULT NULL AFTER `Alias`
   ,CHANGE COLUMN `Country` `Country` varchar(10) NULL DEFAULT NULL AFTER `AffiliateID`
   ,CHANGE COLUMN `Signup_Date` `Signup_Date` varchar(50) NULL DEFAULT NULL AFTER `Country`
   ,CHANGE COLUMN `Reward_Plan` `Reward_Plan` varchar(100) NULL DEFAULT NULL AFTER `Signup_Date`
   ,CHANGE COLUMN `Marketing_Source_Name` `Marketing_Source_Name` varchar(100) NULL DEFAULT NULL AFTER `Reward_Plan`
   ,CHANGE COLUMN `Marketing_Source_ID` `Marketing_Source_ID` varchar(100) NULL DEFAULT NULL AFTER `Marketing_Source_Name`
   ,CHANGE COLUMN `Expiry_Date` `Expiry_Date` varchar(50) NULL DEFAULT NULL AFTER `Marketing_Source_ID`
   ,CHANGE COLUMN `Customer_Type` `Customer_Type` varchar(50) NULL DEFAULT NULL AFTER `Expiry_Date`
   ,CHANGE COLUMN `Customer_Level` `Customer_Level` varchar(50) NULL DEFAULT NULL AFTER `Customer_Type`
   ,CHANGE COLUMN `CPA_Processed_Date` `CPA_Processed_Date` varchar(50) NULL DEFAULT NULL AFTER `Customer_Level`
   ,CHANGE COLUMN `Brand` `Brand` varchar(100) NULL DEFAULT NULL AFTER `CPA_Processed_Date`
   ,CHANGE COLUMN `Customer_Signup_Source` `Customer_Signup_Source` varchar(100) NULL DEFAULT NULL AFTER `Brand`
   ,CHANGE COLUMN `Gross_Revenue` `Gross_Revenue` varchar(50) NULL DEFAULT NULL AFTER `Customer_Signup_Source`
   ,CHANGE COLUMN `Deposits` `Deposits` varchar(50) NULL DEFAULT NULL AFTER `Gross_Revenue`
   ,CHANGE COLUMN `Turnover` `Turnover` varchar(50) NULL DEFAULT NULL AFTER `Deposits`
   ,CHANGE COLUMN `Payouts` `Payouts` varchar(50) NULL DEFAULT NULL AFTER `Turnover`
   ,CHANGE COLUMN `Contributions` `Contributions` varchar(50) NULL DEFAULT NULL AFTER `Payouts`
   ,CHANGE COLUMN `Transactions` `Transactions` int NULL DEFAULT 0 AFTER `Contributions`
   ,CHANGE COLUMN `Points` `Points` varchar(50) NULL DEFAULT NULL AFTER `Transactions`
   ,CHANGE COLUMN `Chargebacks` `Chargebacks` varchar(50) NULL DEFAULT NULL AFTER `Points`
   ,CHANGE COLUMN `Total_Net_Revenue` `Total_Net_Revenue` varchar(50) NULL DEFAULT NULL AFTER `Chargebacks`
   ,CHANGE COLUMN `Total_Net_Revenue_MTD` `Total_Net_Revenue_MTD` varchar(50) NULL DEFAULT NULL AFTER `Total_Net_Revenue`
   ,CHANGE COLUMN `Points_2` `Points_2` varchar(50) NULL DEFAULT NULL AFTER `Total_Net_Revenue_MTD`
   ,CHANGE COLUMN `Sub4` `Sub4` varchar(100) NULL DEFAULT NULL AFTER `Points_2`
   ,CHANGE COLUMN `Var1` `Var1` varchar(100) NULL DEFAULT NULL AFTER `Sub4`
   ,CHANGE COLUMN `Nome_Casino` `Nome_Casino` varchar(100) NULL DEFAULT NULL AFTER `Var1`
   ,CHANGE COLUMN `CTR___deposito` `CTR___deposito` varchar(100) NULL DEFAULT NULL AFTER `Nome_Casino`;
*/

-- 14.05.2026

-- SET FOREIGN_KEY_CHECKS = 0;

-- REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`, `Procedure_call`, `Orden`) 
-- VALUES 
 -- (75, "Gestor Monthly Sources"              , "Gestor Monthly Sources"              , "Gestor Monthly Sources"                           , "Gestor Monthly Sources"                         , 1, "Gestor_MonthlySources"  , 1, ""               , NULL, NULL  )
-- ,(76, "TEST - Daily Sources dev"            , "TEST - Daily Sources dev"            , "TEST - Daily Sources dev"                         , "TEST - Daily Sources dev"                       , 1, "Gestor_MonthlySources"  , 1, "mode=DAILY"     , NULL, NULL  )
-- ,(78, "Sync Previous Month Operator's data" , "Sync Previous Month Operator's data" , "Sincronizar datos del operador del mes anterior"  , "Sincronizza dati operatore mese precedente", 1, "Sync_MS_DbD_DbD_lm"     , 1, "Page=Check&Sync", NULL, 1          )
-- ,(77, "Sync Previous Month Affiliate's data", "Sync Previous Month Affiliate's data", "Sincronizar datos del afiliado del mes anterior"  , "Sincronizza dati affiliato mese precedente", 1, "Compare_Fact1_Fact2"    , 1, "Page=Check&Sync", NULL, 2          )
-- ,(79, "Check/Audit CPA"                     , "Check/Audit CPA"                     , "Verificar/Auditar CPA"                            , "Verifica/Audit CPA"                        , 1, "Report_Reversed_CPA"    , 1, "Page=Check&Sync", NULL, 3          )
-- ,(80, "Check missing/incorrect data"        , "Check missing/incorrect data"        , "Comprobar datos faltantes o incorrectos"          , "Verifica dati mancanti/errati"             , 1, "Check_DbD_dev"          , 1, "Page=Check&Sync", NULL, 4          )
-- ,(81, "Check Bots Status"                   , "Check Bots Status"                   , "Verificar estado de los bots"                     , "Verifica stato bots"                       , 1, "Check_Bot_Status"       , 1, "Page=Check&Sync", NULL, 5          )
-- ;

-- 13.05.2026
/*
CREATE TABLE IF NOT EXISTS `dash_modules` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Title` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Description` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Plan` VARCHAR(4) NOT NULL DEFAULT 'free' COLLATE 'utf8mb4_0900_ai_ci',
   `Icon` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Preview` VARCHAR(500) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Default_w` INT NOT NULL,
   `Default_h` INT NOT NULL,
   `Min_w` INT NOT NULL,
   `Min_h` INT NOT NULL,
   `Component` VARCHAR(100) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Sub_component` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Query_procedure` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Query_params` VARCHAR(500) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Settings` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Is_filter` TINYINT(1) NULL DEFAULT '0',
   `Is_active` TINYINT(1) NOT NULL DEFAULT '1',
   `Order` INT NULL DEFAULT NULL,
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Operator` VARCHAR(30) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
;
TRUNCATE `dash_modules`;
INSERT INTO `dash_modules` SELECT * FROM euroaffiliati_dev.`dash_modules` WHERE DATABASE()!="euroaffiliati_dev";

CREATE TABLE IF NOT EXISTS `account_dash_module_layouts` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Account_id` INT NOT NULL,
   `Module_id` INT NOT NULL,
   `Position_x` INT NOT NULL DEFAULT '0',
   `Position_y` INT NOT NULL DEFAULT '0',
   `Width` INT NOT NULL,
   `Height` INT NOT NULL,
   `Display_order` INT NOT NULL DEFAULT '0',
   `Is_visible` TINYINT(1) NOT NULL DEFAULT '1',
   `Creation_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Operator` VARCHAR(30) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE INDEX `uq_account_module_layout` (`Account_id`, `Module_id`) USING BTREE,
   INDEX `Module_id` (`Module_id`) USING BTREE,
   CONSTRAINT `account_dash_module_layouts_ibfk_1` FOREIGN KEY (`Module_id`) REFERENCES `dash_modules` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
TRUNCATE `account_dash_module_layouts`;
INSERT INTO `account_dash_module_layouts` SELECT * FROM euroaffiliati_dev.`account_dash_module_layouts` WHERE DATABASE()!="euroaffiliati_dev";

ALTER TABLE `auth_menu` ADD COLUMN `description` VARCHAR(200) NULL DEFAULT NULL AFTER `group`;
ALTER TABLE `multi_query` ADD COLUMN `Orden` INT NULL DEFAULT NULL AFTER `Procedure_call`;
*/

-- 18.03.2026
/*
drop table if exists gambling_day_by_day_snai   ;
drop table if exists players_flutter             ;
drop table if exists players_mexos_API             ;

create table if not exists gambling_day_by_day_snai like euroaffiliati_dev.gambling_day_by_day_snai_bkp ;
create table if not exists players_flutter          like euroaffiliati_dev.players_flutter_bkp          ;
create table if not exists players_mexos_API        like euroaffiliati_dev.players_mexos_API_bkp        ;
*/
-- create table if not exists euroaffiliati_dev.gambling_day_by_day_snai_bkp like euroaffiliati_dev.gambling_day_by_day_snai ;
-- create table if not exists euroaffiliati_dev.players_flutter_bkp          like euroaffiliati_dev.players_flutter          ;
-- create table if not exists euroaffiliati_dev.players_mexos_API_bkp        like euroaffiliati_dev.players_mexos_API        ;

-- 27.04.2026
/*
DROP TABLE IF EXISTS `util_settings_v2`;
CREATE TABLE `util_settings_v2` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Setting` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Description` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Show_enabled` TINYINT NULL DEFAULT '0' COMMENT 'User display enabled/disabled',
   `Edit_enabled` TINYINT NULL DEFAULT '0' COMMENT 'User edit enabled/disabled',
   `Value_01` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Value_01_Options` TEXT NULL DEFAULT NULL COMMENT 'Opciones Ej: [YES/NO]' COLLATE 'utf8mb4_0900_ai_ci',
   `Value_01_Required` TINYINT NOT NULL DEFAULT '1',
   `Value_02` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Value_02_Options` TEXT NULL DEFAULT NULL COMMENT 'Opciones Ej: [YES/NO] [€/$]' COLLATE 'utf8mb4_0900_ai_ci',
   `Value_02_Required` TINYINT NOT NULL DEFAULT '0',
   `Value_03` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Creation_Date` DATETIME NULL DEFAULT (now()),
   `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator` VARCHAR(30) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE INDEX `UX_util_settings_Setting` (`Setting`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

INSERT INTO util_settings_v2 (`id`,`Setting`,DESCRIPTION,`Value_01`,`Value_02`,`Value_03`,`Creation_Date`,`Last_Update`,`Operator`
    ,`Show_enabled`,`Edit_enabled`,`Value_01_Options`,`Value_02_Options`,`Value_01_Required`,`Value_02_Required`)
SELECT u.`id`,u.`Setting`,u.`Setting`,u.`Value_01`,u.`Value_02`,u.`Value_03`,u.`Creation_Date`,u.`Last_Update`,u.`Operator`
    ,ifnull(u2.`Show_enabled`,0),ifnull(u2.`Edit_enabled`,0),ifnull(u2.`Value_01_Options`,''),ifnull(u2.`Value_02_Options`,''),ifnull(u2.`Value_01_Required`,1),ifnull(u2.`Value_02_Required`,0)
FROM util_settings u
LEFT JOIN euroaffiliati_dev.util_settings_v2_master u2 ON u2.`Setting`=u.`Setting`
;

DROP TABLE IF EXISTS `util_settings_20260427`;
RENAME TABLE util_settings TO util_settings_20260427;
RENAME TABLE util_settings_v2 TO util_settings;
*/
-- DROP TABLE IF EXISTS `util_settings`;


-- 24.04.2026

-- ALTER TABLE `Snapshot_day_by_day_diff_90days`
   -- CHANGE COLUMN `Brand` `Brand` VARCHAR(100) NULL DEFAULT '0' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Month`,
   -- CHANGE COLUMN `Username` `Username` VARCHAR(100) NULL DEFAULT '0' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Brand`,
   -- CHANGE COLUMN `Tracker_Name` `Tracker_Name` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `MS_id`,
   -- CHANGE COLUMN `Tracker_id` `Tracker_id` VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Tracker_Name`,
   -- CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Tracker_id`;

-- 22.04.2026

-- UPDATE auth_menu a
-- SET Title=replace(a.Title,"Publisher","Operator")
-- ;
-- UPDATE multi_query a
-- SET title=replace(title,"Publisher","Operator"),
 -- Descr_EN=replace(Descr_EN,"Publisher","Operator"),
 -- Descr_ES=replace(Descr_ES,"Publisher","Operator"),
 -- Descr_IT=replace(Descr_IT,"Publisher","Operator")
-- ;

-- 27.03.2026

-- call Report_players_netrefer('genidx=yes');

-- 27.03.2026

  /*  ALTER TABLE Snapshot_day_by_day CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL; */
  
-- CALL util_alter_table_customizable();

-- 20.03.2026

-- ALTER TABLE `gambling_day_by_day_betpartners`
   -- CHANGE COLUMN `Products_Reported` `Products_Reported` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Brand_Reported`,
   -- CHANGE COLUMN `Product` `Product` VARCHAR(200) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Products_Reported`;

-- 18.03.2026

-- drop table if exists gambling_day_by_day_pokerstars   ;
-- drop table if exists gambling_day_by_day_betpartners  ;
-- drop table if exists gambling_day_by_day_betsson      ;

-- create table if not exists gambling_day_by_day_pokerstars  like euroaffiliati2.gambling_day_by_day_pokerstars_bkp;
-- create table if not exists gambling_day_by_day_betpartners like euroaffiliati2.gambling_day_by_day_betpartners_bkp;
-- create table if not exists gambling_day_by_day_betsson     like euroaffiliati2.gambling_day_by_day_betsson_bkp;

-- 17.03.2026

-- CREATE TABLE IF NOT EXISTS `legal_entities` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `name` VARCHAR(150) NOT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `tax_id` VARCHAR(30) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `address` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `email` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `status_id` TINYINT(1) NULL DEFAULT '1',
   -- `Creation_Date` DATETIME NULL DEFAULT (now()),
   -- `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   -- `User` INT NULL DEFAULT NULL,
   -- PRIMARY KEY (`id`) USING BTREE
-- )
-- ;
-- ALTER TABLE `account_financial_movement` ADD COLUMN `Legal_Entity_id` INT NULL DEFAULT NULL AFTER `Extra`;

-- ALTER TABLE `account_account`   ADD COLUMN `Pay_Day` VARCHAR(50) NULL DEFAULT 'Closed_month+20' AFTER `birthday`;

   
-- 07.02.2026

-- INSERT IGNORE INTO `util_settings` (`Setting`, `Value_01`, `Value_02`, `Value_03`) VALUES ('ShowDepositsAff', 'NO', NULL, NULL);


-- 25.02.2026
-- ALTER TABLE `campaign_publisher_history` CHANGE COLUMN `Pay_Day` `Pay_Day` VARCHAR(50) NULL DEFAULT NULL AFTER `Commercial_History`;
-- ALTER TABLE `campaign_publisher`         CHANGE COLUMN `Pay_Day` `Pay_Day` VARCHAR(50) NULL DEFAULT NULL AFTER `Commercial_History`;

-- UPDATE campaign_publisher SET Pay_Day="Closed_month+75";

-- 24.02.2026
-- REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`, `params_Procedure`, `Procedure_call`
-- , `Creation_Date`, `Last_Update`, `Operator`) 
-- VALUES (2, 'Check Bot status info', 'Check Bot\'s status', 'Reporte por Brand: Estado de captura de datos', 'Resoconto per Brand: Stato della cattura dei dati'
-- , 1, 'Check_Bot_Status', 1, '', NULL, '2022-04-07 01:17:06', '2026-02-24 18:18:22', 'SysOP');



-- 19.02.2026 Nuevo menú Affiliate's balance
-- SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
-- SET collation_connection = utf8mb4_0900_ai_ci;
-- SET FOREIGN_KEY_CHECKS = 0;

-- INSERT INTO `auth_group_menu` (`group_id`, `menu_id`) VALUES (2, 88);
-- INSERT INTO `auth_group_menu` (`group_id`, `menu_id`) VALUES (5, 88);
-- INSERT INTO `auth_menu` (`id`, `code`, `title`, `icon`, `path`, `type`, `header_id`, `isExternal`, `isReport`, `group`, `order`, `status_id`, `Creation_Date`, `Last_Update`) 
-- VALUES (88, 'affiliate-balance', 'Affiliate\'s Balance', 'ChevronRight', '/economics/balance-affiliate', '0', 10, 0, 0, '0', 3, 1, '2024-10-05 13:35:03', '2026-02-18 15:27:57');

-- 12.02.2026
-- ALTER TABLE `Snapshot_day_by_day_manual` CHANGE COLUMN `is_proccessed` `is_proccessed` TINYINT NULL DEFAULT '0' AFTER `is_active`;

-- 11.02.2026
-- ALTER TABLE `campaign_publisher_history`
   -- ADD COLUMN `InvoiceByBrand` TINYINT NULL DEFAULT NULL AFTER `InvoiceByAccnt`;

-- 04.02.2026
-- ALTER TABLE `campaign_marketing_source`
   -- DROP INDEX `ms_Code_id`,
   -- DROP INDEX `campaign_marketing_source_Deal_id_3bf3a268`,
   -- DROP FOREIGN KEY `campaign_marketing_s_Deal_id_3bf3a268_fk_campaign_`;

-- 26.01.2026
-- INSERT INTO `util_settings` (`Setting`, `Value_01`, `Value_02`, `Value_03`, `Operator`) 
-- VALUES ('Fact2_Date_Limit', 'NO', NULL, NULL, 'SysOp');


-- 23.01.2026
-- ALTER TABLE `util_settings` ADD UNIQUE INDEX `Setting` (`Setting`);
-- INSERT INTO `util_settings` (`Setting`, `Value_01`, `Value_02`, `Value_03`,`Operator`) 
-- VALUES ('AutogenInvoices', 'NO', NULL, NULL, 'SysOp');


-- 19.12.2025
-- CREATE TABLE IF NOT EXISTS  `Snapshot_day_by_day_temp` (
   -- `id` INT NULL DEFAULT NULL,
   -- `Owner` VARCHAR(55) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Affiliate` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Campaign` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deal` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deal_Aff` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Hour_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   -- `Date` DATE NULL DEFAULT NULL,
   -- `Username` VARCHAR(55) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Portal` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand` VARCHAR(55) NOT NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Tracker_ID` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Tracker_Name` VARCHAR(500) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Code_To_Affiliate` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Product` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Product_Real` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Qualified_Players` INT NULL DEFAULT '0',
   -- `Qualified_Players_Adjusted` INT NULL DEFAULT '0',
   -- `Criteria_Type` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Level_Reached` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `First_Time_Deposit` INT NULL DEFAULT '0',
   -- `Views` INT NULL DEFAULT '0',
   -- `Clicks` INT NULL DEFAULT '0',
   -- `Signups` INT NULL DEFAULT '0',
   -- `Impressions` INT NULL DEFAULT '0',
   -- `Sign_Up_Offer` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Type` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Language` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Country` VARCHAR(50) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand_Name` VARCHAR(50) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Registration_Date` DATE NULL DEFAULT NULL,
   -- `Deposits` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Depositing_Customers` INT NULL DEFAULT '0',
   -- `Active_Customers` INT NULL DEFAULT '0',
   -- `New_Depositing_Customers` INT NULL DEFAULT '0',
   -- `New_Active_Customers` INT NULL DEFAULT '0',
   -- `First_Time_Active_Customers` INT NULL DEFAULT '0',
   -- `Turnover` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Net_Revenue` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Revenue_Share_Gestor` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Revenue_Share_Affiliate` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `CPA_Value_Affiliate` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `CPA_Value_Gestor` DECIMAL(12,2) NULL DEFAULT '0.00'
-- )
-- ;
-- CREATE TABLE  IF NOT EXISTS `Snapshot_day_by_day_temp_lm` (
   -- `id` INT NULL DEFAULT NULL,
   -- `Owner` VARCHAR(55) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Affiliate` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Campaign` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deal` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deal_Aff` VARCHAR(150) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Hour_Update` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP),
   -- `Date` DATE NULL DEFAULT NULL,
   -- `Username` VARCHAR(55) NULL DEFAULT ' ' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Portal` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand` VARCHAR(55) NOT NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Tracker_ID` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Tracker_Name` VARCHAR(500) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Code_To_Affiliate` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Product` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Product_Real` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Qualified_Players` INT NULL DEFAULT '0',
   -- `Qualified_Players_Adjusted` INT NULL DEFAULT '0',
   -- `Criteria_Type` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Level_Reached` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `First_Time_Deposit` INT NULL DEFAULT '0',
   -- `Views` INT NULL DEFAULT '0',
   -- `Clicks` INT NULL DEFAULT '0',
   -- `Signups` INT NULL DEFAULT '0',
   -- `Impressions` INT NULL DEFAULT '0',
   -- `Sign_Up_Offer` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Type` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Language` VARCHAR(55) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Country` VARCHAR(50) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand_Name` VARCHAR(50) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci',
   -- `Registration_Date` DATE NULL DEFAULT NULL,
   -- `Deposits` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Depositing_Customers` INT NULL DEFAULT '0',
   -- `Active_Customers` INT NULL DEFAULT '0',
   -- `New_Depositing_Customers` INT NULL DEFAULT '0',
   -- `New_Active_Customers` INT NULL DEFAULT '0',
   -- `First_Time_Active_Customers` INT NULL DEFAULT '0',
   -- `Turnover` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Net_Revenue` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Revenue_Share_Gestor` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `Revenue_Share_Affiliate` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `CPA_Value_Affiliate` DECIMAL(12,2) NULL DEFAULT '0.00',
   -- `CPA_Value_Gestor` DECIMAL(12,2) NULL DEFAULT '0.00'
-- )
-- ;


-- 18.12.2025
-- CREATE TABLE IF NOT EXISTS `API_NetRefer` (
   -- `id` INT NOT NULL AUTO_INCREMENT,
   -- `Username_id` INT NOT NULL DEFAULT '0',
   -- `Affiliate_ID` INT NULL DEFAULT NULL,
   -- `Date` DATE NULL DEFAULT NULL,
   -- `Product_Name` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand_Name` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Marketing_Source_ID` INT NULL DEFAULT NULL,
   -- `Marketing_Source_Name` VARCHAR(255) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Views` INT NULL DEFAULT NULL,
   -- `Unique_Views` INT NULL DEFAULT NULL,
   -- `Clicks` INT NULL DEFAULT NULL,
   -- `Unique_Clicks` INT NULL DEFAULT NULL,
   -- `Signups` INT NULL DEFAULT NULL,
   -- `Depositing_Customers` INT NULL DEFAULT NULL,
   -- `First_Time_Depositing_Customers` INT NULL DEFAULT NULL,
   -- `CPA_Processed` INT NULL DEFAULT NULL,
   -- `Net_Revenue` DECIMAL(15,2) NULL DEFAULT NULL,
   -- `ChargeBacks` DECIMAL(15,2) NULL DEFAULT NULL,
   -- `Extra_Data` JSON NULL DEFAULT NULL,
   -- `Last_Update` DATETIME NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
   -- PRIMARY KEY (`id`) USING BTREE
-- )
-- ;

-- CREATE TABLE IF NOT EXISTS `players_netrefer_API` (
   -- `Date` DATE NULL DEFAULT NULL,
   -- `Hour_Update` DATETIME NULL DEFAULT (now()),
   -- `Advertiser` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Username` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Username_id` INT NULL DEFAULT NULL,
   -- `Method` INT NULL DEFAULT NULL,
   -- `Prodotto` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Customer_Reference_ID` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Alias` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `AffiliateID` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Country` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Signup_Date` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Reward_Plan` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Marketing_Source_Name` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Marketing_Source_ID` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `URL` VARCHAR(500) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Expiry_Date` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Customer_Type` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Customer_Level` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `CPA_Processed_Date` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Brand` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Customer_Signup_Source` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Gross_Revenue` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Deposits` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Turnover` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Payouts` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Contributions` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Transactions` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Points` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Adj_(Chargebacks)` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Total_Net_Revenue` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Total_Net_Revenue_MTD` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Details` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Subid` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- `Var1` VARCHAR(50) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   -- INDEX `idx_players_netrefer_main` (`Username_id`, `Customer_Reference_ID`, `Date` DESC, `Marketing_Source_ID`, `Marketing_Source_Name`) USING BTREE,
   -- INDEX `idx_players_netrefer_dates` (`Date`, `Signup_Date`, `CPA_Processed_Date`) USING BTREE,
   -- INDEX `idx_players_netrefer_affiliate` (`Advertiser`, `Username`, `Customer_Reference_ID`) USING BTREE,
   -- INDEX `idx_players_netrefer_month` ((left(`Date`,7)), (left(`Signup_Date`,7))) USING BTREE
-- )
-- ;

-- 10.12.2025
-- DROP VIEW IF EXISTS `view_monthly_fact_gestor3`;
-- DROP VIEW IF EXISTS view_balance_affiliate   ;
-- DROP VIEW IF EXISTS view_monthly_fact_aff2   ;
-- DROP VIEW IF EXISTS view_monthly_fact_aff3   ;
-- DROP VIEW IF EXISTS view_monthly_fact_gestor2;           ;
-- DROP VIEW IF EXISTS Totali_affiliate_CPA_brand_matrix    ;
-- DROP VIEW IF EXISTS Totali_affiliate_NR_brand_matrix     ;
-- DROP VIEW IF EXISTS Totali_affiliate_new                 ;
-- DROP VIEW IF EXISTS Totali_gestor_new                    ;
-- DROP VIEW IF EXISTS Totali_username_new                  ;
-- DROP VIEW IF EXISTS Snapshot_day_by_day_fact_brand_affiliate;
-- DROP VIEW IF EXISTS Snapshot_day_by_day_fact_brand_username ;


-- 03.12.2025
-- call DashTotalByMonth('2023-01');
-- call DashTotalByMonth('2024-01');
-- call DashTotalByMonth('2025-01');

-- 03.12.2025
-- REPLACE INTO `multi_query` (`id`, `title`, `Descr_EN`, `Descr_ES`, `Descr_IT`, `is_Procedure`, `code`, `is_Filter`
-- , `params_Procedure`, `Procedure_call`, `Creation_Date`, `Last_Update`, `Operator`) 
-- VALUES (59, 'Report Gross Margin by Month', 'Report Gross Margin by Month', 'Reporte Margen Bruto por mes'
-- , 'Report del margine lordo per mese', 1, 'Report_DashTotalByMonth', 1, '', NULL, '2024-09-11 15:42:23', '2025-12-03 18:37:10', 'SysOP');


-- 01.12.2025
-- ALTER TABLE `account_account_tags_list`
--    CHANGE COLUMN `Description` `Description` VARCHAR(120) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Tag`,
--    CHANGE COLUMN `User` `User` VARCHAR(30) NULL DEFAULT '' COLLATE 'utf8mb4_0900_ai_ci' AFTER `Last_Update`;

-- 03.11.2025
-- REPLACE INTO `notification_type` (`id`, `Title`, `Description`, `Type`, `Subtype`, `Display_required`, `Priority`, `Status_id`
-- , `Creation_Date`, `Last_Update`, `Operator`) VALUES (9, 'Informational Notification'
-- , 'Notifies the user about any informational messages', 'Notification', 'Informative', 1
-- , 'Medium', 1, '2025-10-31 23:44:48', '2025-10-31 23:44:50', '334');


-- 11.09.2025
-- ALTER TABLE `Snapshot_day_by_day_manual`
   -- ADD COLUMN `is_proccessed` TINYINT NULL DEFAULT '1' AFTER `is_active`;

-- 05.09.2025
-- ALTER TABLE `campaign_publisher`
   -- ADD COLUMN `InvoiceByBrand` TINYINT NULL DEFAULT '0' COMMENT '1=Fact por Brand' AFTER `InvoiceByAccnt`;


-- 15.08.2025
-- ALTER TABLE `account_financial_movement` CHANGE COLUMN `Description` `Description` TEXT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Op_type`;
-- ALTER TABLE `account_financial_movement_history` CHANGE COLUMN `Description` `Description` TEXT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Op_type`;

-- ALTER TABLE `account_account_bills` CHANGE COLUMN `Description` `Description` TEXT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Name`;
-- ALTER TABLE `account_account_bills_history` CHANGE COLUMN `Description` `Description` TEXT NULL COLLATE 'utf8mb4_0900_ai_ci' AFTER `Name`;

-- 13.08.2025
/*
CREATE TABLE IF NOT EXISTS  `campaign_publisher_manual_adjustments` (
   `id`                         INT           NOT NULL AUTO_INCREMENT,
   `Publisher_id`               INT           NOT NULL,
   `Date`                       DATE          NULL DEFAULT NULL,
   `Op_type`                    VARCHAR(100)  NULL DEFAULT 'Adjust',
   `Description`                VARCHAR(100)  NULL DEFAULT NULL,
   `Currency`                   VARCHAR(3)    NULL DEFAULT 'EUR',
   `Amount_to_invoice`          DECIMAL(12,2) NULL DEFAULT '0.00',
   `Status_id`                  TINYINT       NULL DEFAULT 1,
   `Remarks`                    TEXT          NULL DEFAULT NULL,
   `IncludeInProfitCalculation` TINYINT       NULL DEFAULT '1' COMMENT '0=No 1=Yes',
   `Owner_id`                   INT           NULL DEFAULT NULL COMMENT 'Profit\'s Owner',
   `Creation_Date`              DATETIME      NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update`                DATETIME      NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`                   VARCHAR(30)   NULL DEFAULT '',
   PRIMARY KEY (`id`) USING BTREE
)
;

ALTER TABLE `account_manual_adjustments`
--    ADD COLUMN `Status_id` TINYINT NULL DEFAULT (1) AFTER `Status`,
   ADD COLUMN `IncludeInProfitCalculation` TINYINT NULL DEFAULT (0) COMMENT '0=No 1=Yes' AFTER `Extra`,
   ADD COLUMN `Owner_id` INT NULL DEFAULT NULL COMMENT 'Profit\'s Owner' AFTER `IncludeInProfitCalculation`;

/*
CREATE TABLE IF NOT EXISTS `account_account_filters` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Account_id` INT NULL DEFAULT NULL,
   `Procedure` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Name` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Filters` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Code` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Status_id` INT NULL DEFAULT NULL,
   `Creation_Date` DATETIME NULL DEFAULT NULL,
   `Last_Update` DATETIME NULL DEFAULT NULL,
   `Operator` INT NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
CREATE TABLE IF NOT EXISTS `account_account_filters_history` (
   `id` INT NULL DEFAULT NULL,
   `Account_id` INT NULL DEFAULT NULL,
   `Procedure` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Name` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Filters` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Code` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Status_id` INT NULL DEFAULT NULL,
   `Creation_Date` DATETIME NULL DEFAULT NULL,
   `Last_Update` DATETIME NULL DEFAULT NULL,
   `Operator` INT NULL DEFAULT NULL,
   `Aud_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Aud_Agent` VARCHAR(40) NULL DEFAULT 'SysOp' COLLATE 'utf8mb4_0900_ai_ci',
   `Aud_Action` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci'
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
CREATE TABLE IF NOT EXISTS  `account_account_table_setting` (
   `id` INT NOT NULL AUTO_INCREMENT,
   `Account_id` INT NULL DEFAULT NULL,
   `Procedure` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Setting` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Status_id` INT NULL DEFAULT NULL,
   `Creation_Date` DATETIME NULL DEFAULT NULL,
   `Last_Update` DATETIME NULL DEFAULT NULL,
   `Operator` INT NULL DEFAULT NULL,
   PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;
CREATE TABLE IF NOT EXISTS `account_account_table_setting_history` (
   `id` INT NULL DEFAULT NULL,
   `Account_id` INT NULL DEFAULT NULL,
   `Procedure` VARCHAR(150) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Setting` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
   `Status_id` INT NULL DEFAULT NULL,
   `Creation_Date` DATETIME NULL DEFAULT NULL,
   `Last_Update` DATETIME NULL DEFAULT NULL,
   `Operator` INT NULL DEFAULT NULL,
   `Aud_Date` DATETIME NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `Aud_Agent` VARCHAR(40) NULL DEFAULT 'SysOp' COLLATE 'utf8mb4_0900_ai_ci',
   `Aud_Action` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci'
)
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB
;

*/




-- DROP PROCEDURE IF EXISTS Util_TableDesignCompare;

-- REPLACE INTO `util_settings` (`id`, `Setting`, `Value_01`) VALUES (5, 'MinWithdrawalAmount', '100');

/*
-- ALTERCMD
ALTER TABLE notification_type ADD COLUMN `Type` varchar(30) NULL DEFAULT NULL AFTER `Description`;
ALTER TABLE notification_type ADD COLUMN `Subtype` varchar(100) NULL DEFAULT NULL AFTER `Type`;
ALTER TABLE notification_type ADD COLUMN `Display_required` int NULL DEFAULT NULL AFTER `Subtype`;
ALTER TABLE notification_type CHANGE COLUMN `Priority` `Priority` varchar(10) DEFAULT NULL AFTER `Display_required`;
ALTER TABLE notification_type CHANGE COLUMN `Status_id` `Status_id` int DEFAULT NULL AFTER `Priority`;
ALTER TABLE notification_type CHANGE COLUMN `Creation_Date` `Creation_Date` datetime DEFAULT NULL AFTER `Status_id`;
ALTER TABLE notification_type CHANGE COLUMN `Last_Update` `Last_Update` datetime NULL DEFAULT NULL AFTER `Creation_Date`;
ALTER TABLE notification_type CHANGE COLUMN `Operator` `Operator` varchar(30) NULL DEFAULT NULL AFTER `Last_Update`;
*/

/*SET @Publisher_id=(SELECT id FROM campaign_publisher WHERE Advertiser_Name="Lottomatica" LIMIT 1);
SET @Advertiser_id=(SELECT id FROM campaign_advertiser WHERE Advertiser_Name="Better" AND Publisher_id=@Publisher_id);
SELECT @Advertiser_id,@Publisher_id;
*/
/*
SELECT AD.Advertiser_Name,a.* FROM
`monthly_comms_affiliate_v5` a
LEFT JOIN campaign_advertiser AD ON AD.id=a.Advertiser_id
-- SET Brand=AD.Advertiser_Name
WHERE a.Advertiser_id=@Advertiser_id
;

SELECT AD.Advertiser_Name,a.* FROM
`Snapshot_day_by_day_fact1` a
LEFT JOIN campaign_advertiser AD ON AD.id=a.Advertiser_id
-- SET Brand=AD.Advertiser_Name
WHERE a.Advertiser_id=@Advertiser_id
;
*/
/*UPDATE `monthly_comms_affiliate_v5` a
LEFT JOIN campaign_advertiser AD ON AD.id=a.Advertiser_id
SET Brand=AD.Advertiser_Name
WHERE a.Advertiser_id=@Advertiser_id AND AD.id IS NOT NULL
;

UPDATE `Snapshot_day_by_day_fact1` a
LEFT JOIN campaign_advertiser AD ON AD.id=a.Advertiser_id
SET Brand=AD.Advertiser_Name
WHERE a.Advertiser_id=@Advertiser_id AND AD.id IS NOT NULL
;

UPDATE `Snapshot_day_by_day_fact2` a
LEFT JOIN campaign_advertiser AD ON AD.id=a.Advertiser_id
SET Brand=AD.Advertiser_Name
WHERE a.Advertiser_id=@Advertiser_id AND AD.id IS NOT NULL
;
*/

