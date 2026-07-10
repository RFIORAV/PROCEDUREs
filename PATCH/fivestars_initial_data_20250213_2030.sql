/* Datos iniciales db fivestar */

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;

truncate fivestars.account_account             ;
truncate fivestars.account_account_groups      ;
truncate fivestars.account_landing_pages       ;
truncate fivestars.auth_group                  ;
truncate fivestars.auth_group_menu             ;
truncate fivestars.auth_group_permissions      ;
truncate fivestars.auth_menu                   ;
truncate fivestars.auth_permission             ;
truncate fivestars.campaign_advertiser         ;
truncate fivestars.campaign_advertiser_licence ;
truncate fivestars.campaign_deal_affiliate     ;
truncate fivestars.campaign_deal_gestor        ;
truncate fivestars.campaign_publisher          ;
truncate fivestars.campaign_publisher_platform ;
truncate fivestars.comm_type_via               ;
truncate fivestars.dash_favorite               ;
truncate fivestars.exchange_rate               ;
truncate fivestars.multi_query                 ;
truncate fivestars.multi_query_account         ;
truncate fivestars.util_countries              ;
truncate fivestars.util_settings               ;

insert into fivestars.account_account             select * from marca_blanca.account_account             ;
insert into fivestars.account_account_groups      select * from marca_blanca.account_account_groups      ;
insert into fivestars.account_landing_pages       select * from marca_blanca.account_landing_pages       ;
insert into fivestars.auth_group                  select * from deally.auth_group                  ;
insert into fivestars.auth_group_menu             select * from deally.auth_group_menu             ;
insert into fivestars.auth_group_permissions      select * from deally.auth_group_permissions      ;
insert into fivestars.auth_menu                   select * from deally.auth_menu                   ;
insert into fivestars.auth_permission             select * from deally.auth_permission             ;
insert into fivestars.campaign_advertiser         select * from marca_blanca.campaign_advertiser         ;
insert into fivestars.campaign_advertiser_licence select * from euroaffiliati2.campaign_advertiser_licence ;
insert into fivestars.campaign_deal_affiliate     select * from marca_blanca.campaign_deal_affiliate     ;
insert into fivestars.campaign_deal_gestor        select * from marca_blanca.campaign_deal_gestor        ;
insert into fivestars.campaign_publisher          select * from marca_blanca.campaign_publisher          ;
insert into fivestars.campaign_publisher_platform select * from marca_blanca.campaign_publisher_platform ;
insert into fivestars.comm_type_via               select * from marca_blanca.comm_type_via               ;
insert into fivestars.dash_favorite               select * from marca_blanca.dash_favorite               ;
insert into fivestars.exchange_rate               select * from deally.exchange_rate               ;
insert into fivestars.multi_query                 select * from deally.multi_query                 ;
insert into fivestars.multi_query_account         select * from deally.multi_query_account         ;
insert into fivestars.util_countries              select * from deally.util_countries              ;
insert into fivestars.util_settings               select * from euroaffiliati2.util_settings              ;