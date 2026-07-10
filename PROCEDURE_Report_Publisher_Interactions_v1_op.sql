/*
PROCEDURE_Report_Publisher_Interactions_v1.sql

Descripción:
  Procedimiento Report_Publisher_Interactions.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Publisher_id    =[ALL | id de Publisher]. OPCIONAL. Default=ALL. 
Status_id       =[ALL | 1 | 0 | N]. OPCIONAL. Default=ALL.

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
 
Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Publisher_Interactions('debug=yes'); -- Devuelve todas las MS
call Report_Publisher_Interactions('debug=ye,filters=yes');
call Report_Publisher_Interactions('debug=ye,filters=no,status=0');

26.01.2025 V1     Primera versión operativa
10.04.2026 v1.1   Meta/filtros: nombre publisher (Advertiser_Name) -> Operator

*/

DROP PROCEDURE IF EXISTS Report_Publisher_Interactions;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Publisher_Interactions`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Publisher Interactions'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.1 10.04.2026';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);
SET @Publisher_id    ='ALL';
SET @Status_id       ='ALL';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @Meta            ='YES';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- @InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   IF lower(@k)='publisher_id'    THEN SET @Publisher_id  =UPPER(@v); END IF;
   IF lower(@k)='status_id'       THEN SET @Status_id     =      @v;  END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;

END WHILE;

CREATE TABLE IF NOT EXISTS `account_publisher_interactions` (
   `id`               INT            NOT NULL AUTO_INCREMENT,
   `Publisher_id`     INT            NOT NULL DEFAULT '0',
   `contact_date`     DATETIME           NULL DEFAULT CURRENT_TIMESTAMP,
   `contact_method`   VARCHAR(80)        NULL DEFAULT NULL COMMENT 'phone/mail/personal/other',
   `staff_member_id`  INT            NOT NULL DEFAULT '0',
   `contacted_person` VARCHAR(100)   NOT NULL DEFAULT '',
   `contact_object`   TEXT,
   `contact_result`   TEXT,
   `follow_up_needed` VARCHAR(30)        NULL DEFAULT 'NO' COMMENT 'YES/NO',
   `follow_up_by`     INT            NOT NULL DEFAULT '0',
   `Status_id`        INT            NOT NULL DEFAULT '0' COMMENT '0=Pending 1=Completed',
   `Creation_Date`    DATETIME           NULL DEFAULT CURRENT_TIMESTAMP,
   `Last_Update`      DATETIME           NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   `User`             INT            NOT NULL DEFAULT '0',
   PRIMARY KEY (`id`) USING BTREE
);

IF @Debug!="NO" THEN SELECT @Month,@Filters,@Publisher_id,@Debug,@Meta,InputCommLine; END IF;

SET @WherePublisher='';
SET @WhereStatus='';

IF @Publisher_id  !="ALL" THEN SET @WherePublisher     =CONCAT(" AND i.Publisher_id=",@Publisher_id );   END IF;
IF @Status_id     !="ALL" THEN SET @WhereStatus        =CONCAT(" AND i.`Status_id`=",@Status_id );      END IF;

IF @Debug!="NO" THEN SELECT @WhereStatus,@WherePublisher; END IF;

SET @Count=0;

/**************************************************************************************************************/

SET @CTE_interactions=CONCAT('
WITH Main_Table_Data as (
SELECT 
    i.`id`                    `id`
   ,i.`Publisher_id`          `Publisher_id`
   ,a.`Advertiser_Name`    as `Operator`
   ,i.`staff_member_id`       `staff_member_id`
   ,s.`username`           as `Staff`
   ,left(i.`contact_date`,16)  `contact_date`
   ,i.`contact_method`        `contact_method`
   ,i.`contacted_person`      `contacted_person`
   ,i.`contact_object`        `contact_object`
   ,i.`contact_result`        `contact_result`
   ,i.`follow_up_needed`      `follow_up_needed`
   ,i.`follow_up_by`          `follow_up_by`
   ,f.`username`           as `Staff follow up`
   ,i.`Status_id`             `Status_id`
   ,CASE WHEN i.`Status_id`=1 THEN "Completed" ELSE "Pending" END 
                           as `Action_status`
   ,left(i.`Creation_Date`,16) `Creation_Date`
   ,left(i.`Last_Update`,16)   `Last_Update`
   ,i.`User`                  `User`
   ,u.`username`           as `User name`
FROM `account_publisher_interactions` i
LEFT JOIN campaign_publisher  a     ON a.id=i.Publisher_id
LEFT JOIN account_account     s     ON s.id=i.staff_member_id
LEFT JOIN account_account     f     ON f.id=i.follow_up_by
LEFT JOIN account_account     u     ON u.id=i.User
WHERE 1=1 '
   ,@WherePublisher
   ,@WhereStatus
,')
');

SET @SQLmeta_interactions=CONCAT(
'(
SELECT
   "setting" as Meta
   ,"width=80px,action=2"   as `Action`
   ,"omit=yes"              as `id`
   ,"omit=yes"              as `Publisher_id`
   ,"width=140px"           as `Operator`
   ,"omit=yes"              as `staff_member_id`
   ,"width=100px"           as `Staff`
   ,"width=140px"           as `contact date`
   ,"width=100px"           as `contact method`
   ,"width=100px"           as `contacted person`
   ,"width=200px,tooltip=yes"  `contact object`
   ,"width=200px,tooltip=yes"  `contact result`
   ,"width=100px"           as `follow-up needed`
   ,"omit=yes"              as `follow_up_by`
   ,"width=100px"           as `Staff follow up`
   ,"omit=yes"              as `Status_id`
   ,"width=100px"           as `Action status`
   ,"omit=yes"              as `Creation Date`
   ,"width=140px"           as `Last Update`
   ,"omit=yes"              as `User`
   ,"width=100px"           as `User name` 
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE_interactions,
@SQLmeta_interactions,
'
SELECT "data" as `Meta`,"..." as `Action`,
   MT.*
FROM Main_Table_Data MT
;'
);

-- ------------------------------------------------------------

SET @Month_INI=left(DATE_SUB(CURDATE(), INTERVAL 12 MONTH),7);

SET @SQLfilters=CONCAT(
@CTE_interactions,'
(SELECT "01" as "Korder","Operator" AS "Key",`Operator` AS "Value","Publisher_id" AS `CallKey`,`Publisher_id` AS "CallValue",COUNT(*) AS "Rows"
                                                                                     FROM Main_Table_Data GROUP BY `Publisher_id`) UNION ALL
-- (SELECT "03","Invoiced Month",`Invoiced_Month`,"Invoiced_Month" ,`Invoiced_Month`,"" FROM Main_Table_Data WHERE `Invoiced_Month`>="',@Month_INI,'"  
--                                                                                      GROUP BY `Invoiced_Month`) UNION ALL
(SELECT "05","Status",`Action_status`,"Status_id" ,`Status_id`              ,COUNT(*) AS K FROM Main_Table_Data GROUP BY `Status_id`)
ORDER BY 1,3
;');

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/* 

call Report_Publisher_Interactions('debug=ye'); -- Devuelve todas las MS
call Report_Publisher_Interactions('debug=ye,filters=yeS');
call Report_Publisher_Interactions('debug=ye,DataFrom=Payments');
call Report_Publisher_Interactions('debug=ye,filters=no,Publisher_id=2');
call Report_Publisher_Interactions('debug=ye,filters=no,Invoice_id=10');
call Report_Publisher_Interactions('debug=ye,filters=no,Invoiced_Month=2024-01');
*/

