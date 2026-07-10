/* 
INSTALACIÓN DE SOPORTE PARA TRATAMIENTO DE Rebrandly y Status en CASCADA
Ejecución desde SOPORTE_Cascada_Status_v1.4.cmd

-- Conceptos/Campos
`Stat_effect`     : Status Efectivo (texto descriptivo de Stat_aggreg)
`Stat_aggreg`     : Código (0/1/4/6/X) del Status Compuesto derivado de la cascada y los demás Status del registro
`NotUse_StatEf`   : Flag (0/1) para obligar al uso del Status normal en lugar del Status Effectivo en una MS
                    Impide aplicar el Status derivado de la cascada 
                    (Por ej: excluir una ms al poner Paused el Advertiser por Cap)
                    
-- Campos de Status derivados de otras tablas (creados para evitar conflictos con existentes)
`Stat_Publ`      = en TABLE `campaign_advertiser`       valor de `Stat_aggreg` de TABLE `campaign_publisher`
`Stat_Adve`      = en TABLE `campaign_username`         valor de `Stat_aggreg` de TABLE `campaign_advertiser`
`Stat_Affi`      = en TABLE `account_landing_pages`     valor de `Stat_aggreg` de TABLE `account_account`
`Stat_Acct`      = en TABLE `campaign_marketing_source` valor de `Stat_aggreg` de TABLE `campaign_username`
`Stat_Chan`      = en TABLE `campaign_marketing_source` valor de `Stat_aggreg` de TABLE `account_landing_pages`

03.03.2023 V1     Inicial
04.03.2023 V1.1   Tabla campaign_mkt_source_url
                  Trigger por Insert de MS
11.03.2023 V1.3   Se agrega campo Stat_MS en Tabla campaign_mkt_source_url
23.03.2023 V1.4   Se habilita todo para instalación en un solo paso
25.03.2023 V1.6   Cambios en actualización de Stat_aggreg
                  Nuevos triggers por insert Advertiser y Account
                  Cambios en notificaciones

/* Agrega campos y tabla antes de modelo para prueba de concepto ---------------------------------------------------------------
*/ /*
ALTER TABLE `campaign_marketing_source` ADD COLUMN `Stat_effect`   VARCHAR(30) NULL DEFAULT "Active" AFTER `Status_id`  ,
                                        ADD COLUMN `Stat_aggreg`   VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_effect`     ,
                                        ADD COLUMN `Stat_Acct`     VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_aggreg`     ,
                                        ADD COLUMN `Stat_Chan`     VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_aggreg`     ,
                                        ADD COLUMN `NotUse_StatEf` VARCHAR(2)  NULL DEFAULT "0" AFTER `Status_id`       ;
ALTER TABLE `campaign_advertiser`       ADD COLUMN `Stat_Publ`     VARCHAR(2)  NULL DEFAULT "1" AFTER `Status_id`       ,
                                        ADD COLUMN `Stat_effect`   VARCHAR(30) NULL DEFAULT "Active" AFTER `Status_id`  ,
                                        ADD COLUMN `Stat_aggreg`   VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_effect`     ;
ALTER TABLE `campaign_username`         ADD COLUMN `Stat_Adve`     VARCHAR(2)  NULL DEFAULT "1" AFTER `Status`          ,
                                        ADD COLUMN `Stat_effect`   VARCHAR(30) NULL DEFAULT "Active" AFTER `Status`     ,
                                        ADD COLUMN `Stat_aggreg`   VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_effect`     ;
ALTER TABLE `account_landing_pages`     ADD COLUMN `Stat_Affi`     VARCHAR(2)  NULL DEFAULT "1" AFTER `Status_id`       ,
                                        ADD COLUMN `Stat_effect`   VARCHAR(30) NULL DEFAULT "Active" AFTER `Status_id`  ,
                                        ADD COLUMN `Stat_aggreg`   VARCHAR(2)  NULL DEFAULT "1" AFTER `Stat_effect`     ;

DROP TABLE IF EXISTS `campaign_mkt_source_url`;
*/
CREATE TABLE IF NOT EXISTS `campaign_mkt_source_url` 
(
	`id`               INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	`MS_id`            INT(10) UNSIGNED NOT NULL DEFAULT '0',
	`Stat_MS`          VARCHAR(2)           NULL DEFAULT NULL,
	`Stat_aggreg`      VARCHAR(2)           NULL DEFAULT NULL,
	`Stat_effect`      VARCHAR(30)          NULL DEFAULT NULL,
	`Affiliate_id`     INT(10)              NULL DEFAULT NULL,
	`Tracker_ID`       VARCHAR(50)          NULL DEFAULT NULL,
	`Tracklink`        VARCHAR(250)         NULL DEFAULT NULL,
	`Shortlink`        VARCHAR(150)         NULL DEFAULT NULL,
	`Shortlink_id`     VARCHAR(150)         NULL DEFAULT NULL,
	`Tracklink_to_API` VARCHAR(250)         NULL DEFAULT NULL,
	`Stat_Sent_to_API` TINYINT(3)           NULL DEFAULT '0',
	`Creation_Date`    TIMESTAMP            NULL DEFAULT CURRENT_TIMESTAMP,
	`Last_Update`      TIMESTAMP            NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`Operator`         VARCHAR(30)          NULL DEFAULT 'SysOp',
	PRIMARY KEY (`id`) USING BTREE,
	UNIQUE INDEX `MS_id` (`MS_id`) USING BTREE
)
ENGINE=InnoDB
;
-- ----------------------------------------------------------------------------------------------
-- SET INIT STATUS-------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------

Select a.id,a.Advertiser_Name
      ,a.Status_id,a.Stat_aggreg,a.Stat_effect
      ,a.Stat_Publ AS "DStatus"
      ,x.Status_id AS "Derived Real"
from campaign_advertiser a 
LEFT JOIN campaign_publisher x ON x.id=a.Publisher_id  
where a.Stat_aggreg not in (a.Status_id,a.Stat_Publ)
   or a.Stat_Publ!=x.Status_id
;

Select a.id,a.Username
      ,a.Status_id,a.Stat_aggreg,a.Stat_effect
      ,a.Stat_Adve   AS "Derived Status"
      ,x.Stat_aggreg AS "Derived Real"
from campaign_username a 
LEFT JOIN campaign_advertiser x ON x.id=a.Advertiser_id  
where a.Stat_aggreg not in (a.Status_id,a.Stat_Adve)
   or a.Stat_Adve!=x.Stat_aggreg
;

Select a.id,a.landing_page_name
      ,a.Status_id,a.Stat_aggreg,a.Stat_effect
      ,a.Stat_Affi   AS "Derived Status"
      ,x.Status_id 	AS "Derived Real"
from account_landing_pages a 
LEFT JOIN account_account x ON x.id=a.Account_id  
where a.Stat_aggreg not in (a.Status_id,a.Stat_Affi)
   or a.Stat_Affi!=x.Status_id
;

Select a.id,a.Tracker_ID,ad.Advertiser_Name
      ,x.Username AS `Account`,a.Username_id,z.Username AS `Affiliate`
      ,a.Status_id,a.Stat_aggreg,a.Stat_effect,NotUse_StatEf
      ,case when a.Stat_aggreg!="1" then
               (case when a.Stat_aggreg in (a.Status_id,a.Stat_Chan,a.Stat_Acct) 
                     then "OK" else "NO OK" end)
            else
               (case when a.Status_id="1" and a.Stat_Chan="1" and a.Stat_Acct="1"
                     then "OK" else "NO OK" end)
            end      as "Eff Stat OK?"
      ,a.Stat_Chan   AS "MS Stat_Chan"
      ,a.Stat_Acct   AS "MS Stat_Acct"
      ,x.Stat_aggreg AS "Stat_Acct Real"
      ,y.Stat_aggreg AS "Stat_Chan Real"
      ,z.Status_id   AS "Stat_User Real"
from campaign_marketing_source a 
LEFT JOIN campaign_username      x ON x.id=a.Username_id  
LEFT JOIN account_landing_pages  y ON y.id=a.Channel_id  
LEFT JOIN account_account        z ON z.id=a.Affiliate_id  
LEFT JOIN campaign_advertiser   ad ON ad.id=a.Advertiser_id  

where
   ((case when a.Stat_aggreg!="1" then
               (case when a.Stat_aggreg in (a.Status_id,a.Stat_Chan,a.Stat_Acct) 
                     then "OK" else "NO OK" end)
            else
               (case when a.Status_id="1" and a.Stat_Chan="1" and a.Stat_Acct="1"
                     then "OK" else "NO OK" end)
            end)="NO OK"   
   AND  	NotUse_StatEf<>1)
--    (
--    OR   	a.Stat_Acct!=x.Stat_aggreg
--    OR 	a.Stat_Chan!=y.Stat_aggreg
--    )
;

/******* COMPRUEBA CAMBIO DE STATUS POR CAMBIO DE CAP ********/

SELECT * FROM campaign_marketing_source
WHERE Status_id=Stat_aggreg
	AND NotUse_StatEf=1
	;