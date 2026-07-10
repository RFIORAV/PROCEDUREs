/*
PROCEDURE_GetAffiliateTags.sql - Report Tags Affiliate

Descripción:
  Procedimiento GetAffiliateTags.

Keys:
affiliate_id = [valor]. Parámetro de entrada.

Ejemplos:

call GetAffiliateTags(39);

24.05.2025  v1

*/

DROP PROCEDURE IF EXISTS GetAffiliateTags;

DELIMITER $$

CREATE PROCEDURE GetAffiliateTags (
    IN affiliate_id INT
    )
    COMMENT 'Get Affiliate Tags'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 24.05.2025';
SET @affiliate_id    =affiliate_id;
    
CREATE TABLE IF NOT EXISTS `account_account_tags` 
(
   `id`               INT            NOT NULL AUTO_INCREMENT,
	`Affiliate_id`     INT            NOT NULL DEFAULT 0,
	`Status`           TINYINT        NOT NULL DEFAULT 1, --  COMMENT 'Status=Disabled',
	`Tag`              VARCHAR(120)   NOT NULL DEFAULT '',
	`Tag_id`           INT            NOT NULL DEFAULT 0,
   `Creation_Date`    DATETIME           NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update`      DATETIME           NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User`             VARCHAR(30)        NULL DEFAULT NULL,
	PRIMARY KEY (`id`)                              USING BTREE,
	UNIQUE INDEX `Tag` (`Tag`, `Affiliate_id`)      USING BTREE,
	INDEX `Affiliate_id` (`Affiliate_id`)           USING BTREE,
	INDEX `Affiliate_id_Tag` (`Affiliate_id`,`Tag`) USING BTREE
)
;
CREATE TABLE IF NOT EXISTS `account_account_tags_list` 
(
   `id`               INT            NOT NULL AUTO_INCREMENT,
	`Status`           TINYINT        NOT NULL DEFAULT 1 COMMENT 'Status=Disabled',
	`Tag`              VARCHAR(120)   NOT NULL DEFAULT '',
	`Description`      VARCHAR(120)   NOT NULL DEFAULT '',
   `Creation_Date`    DATETIME           NULL DEFAULT (CURRENT_TIMESTAMP),
   `Last_Update`      DATETIME           NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP,
   `User`             VARCHAR(30)        NULL DEFAULT NULL,
	PRIMARY KEY (`id`)                              USING BTREE,
	UNIQUE INDEX `Tag` (`Tag`)                      USING BTREE
)
;

-- ---------------------------------------------------------------------------------
SELECT 
    t.Affiliate_id,
    t.Tag,
    COALESCE(tl.Description, '') AS Description,
--  t.Status,
    t.Tag_id,
    LEFT(t.Creation_Date,10)  AS `Creation_Date`,
    LEFT(t.Last_Update,16)    AS `Last_Update`,    
    COALESCE(t.User, 'SysOp') AS `User`
FROM account_account_tags t
LEFT JOIN account_account_tags_list tl ON t.Tag = tl.Tag AND tl.Status = 1
WHERE t.Affiliate_id = @affiliate_id AND t.Status = 1
ORDER BY t.Tag ASC;
-- ---------------------------------------------------------------------------------
    
END$$

DELIMITER ;

/* Testing 

-- DROP TABLE `account_account_tags_list`;
REPLACE INTO `account_account_tags_list` (`id`,`Tag`,`Description`) VALUES
( 1,'BigAff','Big Affiliates')           ,
( 2,'SmallAff','Small Affiliates')       ,
( 3,'MedAff','Medium Affiliates')        ,
( 4,'Premium','Premium Affiliates')      ,
( 5,'Type AA','Type AA Affiliates')      ,
( 6,'Type BB','Type BB Affiliates')      ,
( 7,'Type CC','Type CC Affiliates')      ,
( 8,'Type DD','Type DD Affiliates')      ,
( 9,'Subgroup 1','Subgroup 1 Affiliates'),
(10,'Subgroup 2','Subgroup 2 Affiliates'),
(11,'Subgroup 3','Subgroup 3 Affiliates'),
(12,'Subgroup 4','Subgroup 4 Affiliates')
;

-- DROP TABLE `account_account_tags`;
REPLACE INTO `account_account_tags` (`Tag_id`,`Tag`,`Affiliate_id`) VALUES
( 1,'BigAff'    ,506),
( 2,'SmallAff'  ,39 ),
( 3,'MedAff'    ,450),
( 5,'Type AA'   ,39 ),
( 9,'Subgroup 1',39 ),
( 6,'Type BB'   ,506),
(10,'Subgroup 2',506),
( 7,'Type CC'   ,450),
(11,'Subgroup 3',450)
;

SELECT T.*,TL.Description,A.* 
FROM `account_account_tags` T
INNER JOIN `account_account` A ON T.`Affiliate_id`=A.id
INNER JOIN `account_account_tags_list` TL ON TL.`Tag`=T.`Tag`
;
SELECT * 
FROM `account_account_tags` T
INNER JOIN `account_account_tags_list` TL ON TL.`Tag`=T.`Tag`
;
*/