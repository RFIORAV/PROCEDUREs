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

UPDATE campaign_advertiser    A LEFT JOIN campaign_publisher  P ON P.id=Publisher_id  
SET A.Stat_Publ=IFNULL(P.`Status_id`,"1")
   ,A.Stat_aggreg=(
      CASE  WHEN A.`Status_id`!='1'
            THEN A.`Status_id`
            ELSE 
                  CASE  WHEN A.`Stat_Publ`!='1'
                        THEN A.`Stat_Publ`
                        ELSE '1'
                  END
      END)
   ,A.Stat_effect=(
      CASE A.Stat_aggreg
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
   ,A.Status=(
      CASE A.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
;
UPDATE campaign_username      U LEFT JOIN campaign_advertiser A ON A.id=Advertiser_id 
SET U.Stat_Adve=ifnull(A.`Stat_aggreg`,"1")
   ,U.Stat_aggreg=(
      CASE  WHEN U.`Status_id`!='1'
            THEN U.`Status_id`
            ELSE 
                  CASE  WHEN U.`Stat_Adve`!='1'
                        THEN U.`Stat_Adve`
                        ELSE '1'
                  END
      END)
   ,U.Stat_effect=(
      CASE U.Stat_aggreg
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
   ,U.Status=(
      CASE U.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
;

UPDATE account_account A
SET A.Status_id=IFNULL(A.Status_id,"1")   
   ,A.Status=(
      CASE A.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
;

UPDATE account_landing_pages  L LEFT JOIN account_account     A ON A.id=Account_id    
SET L.Stat_Affi=IFNULL(A.`Status_id`,"1")
   ,L.Stat_aggreg=(
      CASE  WHEN L.`Status_id`!='1'
            THEN L.`Status_id`
            ELSE 
                  CASE  WHEN L.`Stat_Affi`!='1'
                        THEN L.`Stat_Affi`
                        ELSE '1'
                  END
      END)
   ,L.Stat_effect=(
      CASE L.Stat_aggreg
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
   ,L.Status=(
      CASE L.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
;

-- Calcula Stat_effect
UPDATE campaign_marketing_source M 
LEFT JOIN account_landing_pages L ON L.id=M.Channel_id
LEFT JOIN account_account 		  A ON A.id=M.Affiliate_id 
LEFT JOIN campaign_username     U ON U.id=M.Username_id

SET M.Stat_Chan=(case when L.`Stat_aggreg` IS NULL				-- 13.10.2023 remmplazado Status_id x Stat_aggreg
						 	 then ifnull(A.`Status_id`,"1") 
						 	 else L.`Stat_aggreg` 						-- 13.10.2023 remmplazado Status_id x Stat_aggreg
                      end)
   ,M.Stat_Acct=ifnull(U.`Stat_aggreg`,"1") 
   ,M.Stat_aggreg=(
      CASE  WHEN M.`Status_id`!='1'
            THEN M.`Status_id`
            ELSE 
                  CASE  WHEN M.`Stat_Acct`!='1'
                        THEN M.`Stat_Acct`
                        ELSE M.`Stat_Chan`
                  END
      END)
   ,M.Stat_effect=(
      CASE M.Stat_aggreg
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
   ,M.Status=(
      CASE M.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)   
where 1=1  AND NotUse_StatEf<>1
;
-- -----------------------------------------
SELECT m.Status_id,m.Stat_aggreg,m.Stat_effect,m.Tracklink,u.* FROM
-- ;
-- UPDATE 
campaign_mkt_source_url u
INNER JOIN campaign_marketing_source m ON u.MS_id=m.id
-- SET u.Stat_MS=m.Status_id,u.Stat_aggreg=m.Stat_aggreg
-- 	,u.Stat_effect=m.Stat_effect,u.Tracklink=m.Tracklink
-- 	,u.Stat_Sent_to_API=0
WHERE (u.Stat_aggreg!=m.Stat_aggreg AND (u.Stat_aggreg='1' or m.Stat_aggreg='1'))
	OR (u.Stat_effect!=m.Stat_effect AND (u.Stat_effect='active' or m.Stat_effect='active'))
	OR u.Tracklink!=m.Tracklink
;
-- T E S T S ----------------------------------------------------------------------------------
/*
SELECT * FROM campaign_publisher where id=68;
update campaign_publisher set Status_id='6' where id=68;

SELECT * FROM campaign_advertiser where publisher_id=68;
SELECT * FROM campaign_username  where publisher_id=68;
SELECT * FROM campaign_marketing_source where Affiliate_id=39 and Advertiser_id=68;

SELECT * FROM account_account where id=39;
UPDATE account_account SET Status_id='4' where id=39;
SELECT * FROM campaign_marketing_source where Affiliate_id=39;
*/
