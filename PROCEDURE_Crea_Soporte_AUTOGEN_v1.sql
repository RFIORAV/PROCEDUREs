/* Crea el soporte para la auto-generación de datos


Descripción:
  Procedimiento Crea_Soporte_AUTOGEN.
   Valores en tabla `util_settings`:
   id record 15: AutogenDefaultUser
   id record 16: AutogenDefaultChannel
   id record 17: AutogenDefaultDeal

Keys:
   
   16.11.2025 v1
*/

DROP PROCEDURE IF EXISTS `Crea_Soporte_AUTOGEN`;

DELIMITER $$

CREATE PROCEDURE `Crea_Soporte_AUTOGEN`()
   COMMENT 'CREA SOPORTE PARA LA AUTO-GENERACIÓN DE MARKETING SOURCES DESDE SNAPSHOT_DAY_BY_DAY'
   LANGUAGE SQL

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 17.11.2025';
SET @Debug           ='NOn';

-- Obtiene @AutogenDefault values desde tabla util_settings
SET @AutogenDefaultUser=(SELECT `Value_01`    FROM `util_settings` WHERE Setting='AutogenDefaultUser');
SET @AutogenDefaultChannel=(SELECT `Value_01` FROM `util_settings` WHERE Setting='AutogenDefaultChannel');
SET @AutogenDefaultDeal=(SELECT `Value_01`    FROM `util_settings` WHERE Setting='AutogenDefaultDeal');

IF @Debug!="NO" THEN SELECT @AutogenDefaultUser,@AutogenDefaultChannel,@AutogenDefaultDeal; END IF;

-- ----------------------------------- AUTOGEN User ------------------------------------------------------

IF @AutogenDefaultUser is null THEN

   INSERT INTO `account_account` (`username`, `password`, `email`, `date_joined`, `last_login`, `is_admin`, `is_active`, `is_staff`
      , `is_superuser`, `first_name`, `last_name`, `phone`, `language`, `address`, `skype`, `fiscal_code`, `iva`, `company_fiscal_name`
      , `company_address`, `nation`, `city`, `birthday`, `first_level`, `second_level`, `third_level`, `fourth_level`, `url`, `terms`, `budget`
      , `Status_id`, `Status`, `profile_pic`, `referral`, `email_report`, `telegram_report`, `referral_id`, `referral_id_origin`, `CPA_Limit`
      , `document_id_back`, `document_id_front`, `id_alias`, `username_alias`, `id_default`, `username_default`, `period_default`, `is_forex`
      , `is_gambling`, `registration_completed`, `user_document_url`, `company_document_url`, `traffic_source`, `Operator`)
      SELECT '_Unassigned', 'pbkdf2_sha256$216000$EZ1yW38gUNop$Kyn7iJzrwONvIKnVVtrfxVbM3nR0MqQp3YkBIwygTa8=', 'info@affiliateaccess.com'
         , NOW(), NOW(), 0, 0, 0, 0, 'autogen', 'autogen', '+123456789', '', '', '', '', '', '', '', 'IT', '', DATE_SUB(CURDATE(), INTERVAL 30 YEAR)
         , '2', NULL, NULL
         , NULL, NULL, 1, '0', '1', 'Active', '', 0, 'Daily', 'Daily', '', NULL, NULL, '', '', '10'
         , 'AUTOGEN', 10, 'AUTOGEN', '2025-11-01', 0, 1, 1, '', '', '', 'SysOp';

   SET @AutogenDefaultUser=(SELECT id FROM `account_account` WHERE `username`="_Unassigned");

   REPLACE INTO `util_settings` (id, `Setting`, `Value_01`, `Value_02`) VALUES (15,'AutogenDefaultUser', @AutogenDefaultUser, 'AUTOGEN');

   REPLACE INTO `account_account_groups` (`account_id`, `group_id`) VALUES (@AutogenDefaultUser, 3);

END IF;
-- ----------------------------------- AUTOGEN Channel ---------------------------------------------------

IF @AutogenDefaultChannel is null THEN

   INSERT INTO `account_landing_pages` (`Account_id`,landing_page_channel,landing_page_name, `product`, `Status`, `Status_id`, `Stat_effect`
      , `Stat_aggreg`, `Stat_Affi`, `Operator`) 
   SELECT @AutogenDefaultUser,'www.google.com', 'Autogen', 'Sport', 'Active', '1', 'Other', '3', '1', 'Autogen';
      
   SET @AutogenDefaultChannel=(SELECT id FROM `account_landing_pages` WHERE `landing_page_name`="Autogen" LIMIT 1);

   REPLACE INTO `util_settings` (id, `Setting`, `Value_01`, `Value_02`) VALUES (16,'AutogenDefaultChannel', @AutogenDefaultChannel, 'AUTOGEN');

END IF;

-- ----------------------------------- AUTOGEN Deal -------------------------------------------------------

IF @AutogenDefauAutogenDefaultDealltChannel is null THEN

   INSERT INTO `campaign_deal_affiliate` (`id`, `Multilevel`, `Owner`, `Deal_Name`, `Description`, `traffic_source`
            , `RS_Base`, `Status`, `Status_id`, `Baseline`, `Deal_Type`, `Advertiser`, `Country`, `Currency`, `Product`, `Operator`) 
      SELECT @AutogenDefaultDeal, 0, '', 'CPA: 0', '', '', 'brand', 0, '0', 0, '', '', '', 'EUR', '', '10' FROM DUAL;
      
   SET @AutogenDefaultDeal=(SELECT id FROM `campaign_deal_affiliate` WHERE `Deal_Name` IN ("CPA: 0","CPA: 0 EUR") LIMIT 1);

   REPLACE INTO `util_settings` (id, `Setting`, `Value_01`, `Value_02`) VALUES (17,'AutogenDefaultDeal', @AutogenDefaultDeal, 'AUTOGEN');

END IF;

IF @Debug!="NO" THEN SELECT @AutogenDefaultUser,@AutogenDefaultChannel,@AutogenDefaultDeal; END IF;

-- ---------------------------------------------------------------------------------------------------------
END$$
DELIMITER ;

