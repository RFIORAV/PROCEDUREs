SELECT CONCAT("ALTER TABLE ",t.TABLE_SCHEMA,".",t.`TABLE_NAME`," COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';") AS `-- Alter`
FROM `information_schema`.`TABLES` t
WHERE TABLE_COLLATION IN ('utf8mb4_unicode_ci')
;

-- Alter
ALTER TABLE core_saas.core_credential COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.django_migrations COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_alert COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_raw_payload COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_sync_log COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_deal COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_reward_plan_suggestion COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_commission_snapshot COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_tracking_source COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_source_discovery_notice COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_ai_action_proposal COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_account_offers COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_partner COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_commission_event COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_assistant_conversation COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_assistant_message COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_software COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_merchant COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_program COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_offer COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_account COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_connector_profile COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_program_connector COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_source_record COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_sync_attempt COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
ALTER TABLE core_saas.core_connector COLLATE='utf8mb4_0900_ai_ci',   CONVERT TO CHARSET utf8mb4 COLLATE 'utf8mb4_0900_ai_ci';
