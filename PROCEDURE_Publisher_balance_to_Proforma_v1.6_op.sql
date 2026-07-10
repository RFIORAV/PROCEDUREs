/*
PROCEDURE_Publisher_balance_to_Proforma_v1.sql - Inserta los resultados x Publisher de InvoiceToPubliser

Descripción:
  Procedimiento Publisher_balance_to_Proforma.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month           =[ALL | AAAA-MM ]. OPCIONAL. Default=ALL
Owner_id        =[ALL | id del Owner]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | id del Advertiser]. OPCIONAL. Default=ALL
Export          =[Yes | No]. INSERT en campaign_publisher_invoice. OPCIONAL. Default=no.

Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
 
Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Publisher_balance_to_Proforma('month=LM,debug=ye'); -- Devuelve todas las MS
call Publisher_balance_to_Proforma_dev('month=LM,debug=ye'); -- Devuelve todas las MS
call Publisher_balance_to_Proforma_dev('month=2025-12,Export=ye,debug=non');
call Publisher_balance_to_Proforma_dev('debug=ye,filters=yes');
call Publisher_balance_to_Proforma_dev('debug=ye,filters=no');
call Publisher_balance_to_Proforma_dev('month=2026-04,EXPORT=YES,debug=ye');
CALL Publisher_balance_to_Proforma('month=2026-01,export=yes,debug=ye');

05.03.2025 V1     Primera versión operativa
14.04.2025        Facturación por Account cuando campo `InvoiceByAccnt`=1 en la tabla campaign_publisher
05.09.2025        Facturación por Brand cuando campo `InvoiceByBrand`  o `InvoiceByAccnt`=1 en la tabla campaign_publisher
27.02.2026        Inclusión de fecha de vencimiento de la factura y fecha de factura estimadas
05.03.2026        Inclusión de comprobación de existencia de la factura en la tabla campaign_publisher_invoice
10.04.2026 v1.5   Meta/filtros: etiqueta de nombre publisher -> Operator (export INSERT sin cambio de columnas BD)
03.06.2026 v1.6   Export: INSERT reemplazado por UPSERT (ON DUPLICATE KEY UPDATE) sobre índice Owner_id

*/

DROP PROCEDURE IF EXISTS Publisher_balance_to_Proforma;
DROP PROCEDURE IF EXISTS Publisher_balance_to_Proforma_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Publisher_balance_to_Proforma`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Publisher balance to Proforma'

proc_label:BEGIN
DECLARE v_Version                   VARCHAR(30);
DECLARE v_CurrentDay                DATE;
DECLARE v_Month                     VARCHAR(20);
DECLARE v_Owner_id                  VARCHAR(20);
DECLARE v_Publisher_id              VARCHAR(20);
DECLARE v_Invoiced_Month            VARCHAR(20);
DECLARE v_Status_id                 VARCHAR(20);
DECLARE v_Export                    VARCHAR(10);
DECLARE v_Debug                     VARCHAR(20);
DECLARE v_Filters                   VARCHAR(10);
DECLARE v_Meta                      VARCHAR(10);
DECLARE v_InputCommLine             VARCHAR(300);
DECLARE v_e                         INT;
DECLARE v_c                         INT;
DECLARE v_k                         VARCHAR(100);
DECLARE v_v                         VARCHAR(255);
DECLARE v_WhereOwner                TEXT;
DECLARE v_WherePublisher            TEXT;
DECLARE v_WhereMonth                TEXT;
DECLARE v_WhereInvoiced_Month       TEXT;
DECLARE v_CTE                       LONGTEXT;
DECLARE v_SQL_Result                LONGTEXT;
DECLARE v_SQLmeta                   LONGTEXT;
DECLARE v_SQL                       LONGTEXT;
DECLARE v_EXP_WhereOwner            TEXT;
DECLARE v_EXP_WherePublisher        TEXT;
DECLARE v_EXP_WhereInvoiced_Month   TEXT;
DECLARE v_SQL_Result_export         LONGTEXT;
DECLARE v_SQL_DELETE                LONGTEXT;
DECLARE v_SQL_UPDATE                LONGTEXT;
DECLARE v_SQL_EXPORT                LONGTEXT;
DECLARE v_SQLfilters                LONGTEXT;
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.6 03.06.2026';
SET v_CurrentDay      =curdate();
SET v_Month           ="LM";
SET v_Owner_id        ='ALL';
SET v_Publisher_id    ='ALL';
SET v_Invoiced_Month  ='ALL';
SET v_Status_id       ='ALL';
SET v_Export          ='NO';

SET v_Debug           ='NO';
SET v_Filters         ='NO';
SET v_Meta            ='YES';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- @InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='owner_id'        THEN SET v_Owner_id      =UPPER(v_v); END IF;
   IF lower(v_k)='publisher_id'    THEN SET v_Publisher_id  =UPPER(v_v); END IF;
   IF lower(v_k)='month'           THEN SET v_Month         =UPPER(v_v); END IF;
   IF lower(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF lower(v_k)='Export'          THEN SET v_Export        =UPPER(v_v); END IF;
   IF lower(v_k)='filters'         THEN SET v_Filters       =UPPER(v_v); END IF;
   IF lower(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;

END WHILE;

IF  v_Month = "CM" THEN SET v_Month=LEFT(CURDATE(),7); END IF;
IF  v_Month = "LM" THEN SET v_Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF v_Debug!="NO" THEN SELECT v_Month,v_Export,v_Filters,v_Owner_id,v_Publisher_id,v_Debug,v_Meta,InputCommLine; END IF;

SET v_WhereOwner='';
SET v_WherePublisher='';
SET v_WhereMonth='';
SET v_WhereInvoiced_Month='';

IF v_Owner_id      !="ALL" THEN SET v_WhereOwner         =CONCAT(" AND G.Owner       =",v_Owner_id);      END IF;
IF v_Publisher_id  !="ALL" THEN SET v_WherePublisher     =CONCAT(" AND G.Publisher_id=",v_Publisher_id ); END IF;
IF v_Month         !="ALL" THEN SET v_WhereInvoiced_Month=CONCAT(' AND G.`Month`     ="',v_Month,'"'); END IF;

IF v_Debug!="NO" THEN SELECT v_WhereOwner,v_WherePublisher,v_WhereMonth; END IF;

/*
DROP TABLE IF EXISTS `campaign_publisher_invoice_V2`;

CREATE TABLE IF NOT EXISTS `campaign_publisher_invoice` (
    `id`               INT             NOT NULL AUTO_INCREMENT
   ,`Category`         VARCHAR(80)     NULL DEFAULT "Invoice"
   ,`Status`           VARCHAR(80)     NULL DEFAULT "Active"
   ,`Status_id`        TINYINT         NULL DEFAULT '1'
   ,`Owner`            VARCHAR(80)     NULL DEFAULT NULL
   ,`Owner_id`         INT             NULL DEFAULT NULL
   ,`Publisher`        VARCHAR(80)     NULL DEFAULT NULL
   ,`Publisher_id`     INT             NULL DEFAULT NULL
   ,`Brand`            VARCHAR(80)     NULL DEFAULT NULL
   ,`Invoiced_Month`   VARCHAR(50)     NULL DEFAULT NULL
   ,`Invoice_Number`   VARCHAR(30)     NULL DEFAULT NULL
   ,`Date`             DATE            NULL DEFAULT NULL COMMENT 'Issued date'
   ,`Due_Date`         DATE            NULL DEFAULT NULL COMMENT 'Due date'
   ,`Paymt_Date`       DATE            NULL DEFAULT NULL COMMENT 'Payment date'
   ,`Ammount`          DECIMAL(10,2)   NULL DEFAULT '0.00'
   ,`Currency`         VARCHAR(3)      NULL DEFAULT 'EUR'
   ,`Invoice_address`  TINYTEXT        NULL DEFAULT NULL
   ,`CPA`              INT             NULL DEFAULT 0
   ,`CPA_Value`        DECIMAL(10,2)   NULL DEFAULT '0.00'
   ,`Net_Revenue`      DECIMAL(10,2)   NULL DEFAULT '0.00'
   ,`net_RS_Val`       DECIMAL(10,2)   NULL DEFAULT '0.00'
   ,`Total_Commission` DECIMAL(10,2)   NULL DEFAULT '0.00'
   ,`Gen_invoice`      TINYINT         NULL DEFAULT 0
   ,`Generated`        TINYINT         NULL DEFAULT 0
   ,`Remarks`          TEXT            NULL DEFAULT NULL
   ,`Invoice_File`     TEXT            NULL DEFAULT NULL COMMENT 'Generated pdf file'
   ,`Creation_Date`    DATETIME        NULL DEFAULT (CURRENT_TIMESTAMP)
   ,`Last_Update`      DATETIME        NULL DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP
   ,`Operator`         VARCHAR(30)     NULL DEFAULT "SysOp"
   ,PRIMARY KEY (`id`) USING BTREE
)
ENGINE=InnoDB
;
*/
/**************************************************************************************************************/

SET v_CTE=CONCAT('
WITH RECURSIVE
SetUnConverted as (
   SELECT
       G.Month          AS Date
      ,AC.username      as `Owner`
      ,G.Owner          as Owner_id
      ,G.Area
      ,G.Publisher
      ,G.Publisher_id
      ,G.Brand          as `Brand`
      ,G.Advertiser_id
      ,G.`Username`     as Account
      ,G.Username_id    as Account_id
      ,G.Data_Currency as `Data_Currency`
      ,sum(G.CPA)                              as `CPA`
      ,round(sum(net_CPA_Val     ),2)          as `CPA_Value`
      ,round(sum(Net_Revenue     ),2)          as `Net_Revenue`
      ,round(sum(net_RS_Val      ),2)          as `net_RS_Val`
      ,round(sum(net_Total_comm  ),2)          as `Total_Commission`
      ,P.Commercial_History as `Invoice_address`
      ,IFNULL(P.InvoiceByAccnt,0) as `InvoiceByAccnt`
      ,IFNULL(P.InvoiceByBrand,0) as `InvoiceByBrand`
      ,IFNULL(P.Pay_Day,"")       as `Pay_Day`
      FROM monthly_comms_gestor_v5 G
      LEFT JOIN account_account     AC    ON AC.id=G.Owner
      LEFT JOIN campaign_publisher  P     ON P.id=Publisher_id
      WHERE IFNULL(G.Owner,0)>0'
         ,v_WhereOwner
         ,v_WherePublisher
         ,v_WhereInvoiced_Month
      ,'
      GROUP BY G.Owner,G.Data_Currency,Publisher_id,Brand,Username_id -- ,CarryOver,RS_Base,Product,`Comm_type`
         having `Total_Commission`<>0  -- or `Pending CO`<>0
),
Main_Table_Data as (
   SELECT
       Date
      ,`Owner`
      ,Owner_id
      ,Publisher
      ,Publisher_id
      -- ,Brand
      ,CASE WHEN `InvoiceByBrand`=1 THEN `Brand` ELSE "all" END as `Brand`
      ,CASE WHEN `InvoiceByAccnt`=1 THEN `Account` ELSE "all" END as `Account`
      ,CASE WHEN `InvoiceByAccnt`=1 THEN `Account_id` ELSE 0 END  as `Account_id`
      ,`Data_Currency` AS `Currency`
      ,sum(CPA)                         as `CPA`
      ,round(sum(`CPA_Value`),2)        as `CPA_Value`
      ,round(sum(`Net_Revenue`),2)      as `Net_Revenue`
      ,round(sum(`net_RS_Val`),2)       as `net_RS_Val`
      ,round(sum(`Total_Commission`),2) as `Total_Commission`
      ,`Invoice_address`
      ,`InvoiceByAccnt`
      ,`InvoiceByBrand`
      ,MAX(`Pay_Day`) AS `Pay_Day`
      FROM SetUnConverted G
      GROUP BY G.Owner,G.Data_Currency,Publisher_id
         ,CASE WHEN `InvoiceByBrand`=1 THEN `Brand` ELSE "all" END
         ,CASE WHEN `InvoiceByAccnt`=1 THEN `Account` ELSE "all" END
         -- ,Username_id,CarryOver,RS_Base,Product,`Comm_type`
         -- having `Total_Commission`<>0 or `Pending CO`<>0
)'
);

SET v_SQL_Result=CONCAT('
(
SELECT 
       "data" as `Meta`,
       "Proforma" as `Category`
      ,`Owner`
      ,`Owner_id`
      ,`Publisher`               AS `Operator`
      ,`Publisher_id`
      ,`Brand`
      ,`Account`
      -- ,`Account_id`
      ,`Date`
      ,`Currency`
      ,`CPA`
      ,`CPA_Value`
      ,`Net_Revenue`
      ,`net_RS_Val`
      ,`Total_Commission`
      ,`Total_Commission` as `Amount`
      ,`Invoice_address`
FROM Main_Table_Data
)
ORDER BY Owner,`Operator`,Brand,`Account` 
'
);

SET v_SQLmeta=CONCAT(
'(
SELECT
       "setting" as Meta
      ,"width=100px"             as `Category`
      ,"width=100px"             as `Owner`
      ,"width=080px"             as `Owner id`
      ,"width=150px"             as `Operator`
      ,"omit=yes"                as `Publ id`
      ,"omit=yes"                as `Brand`
      ,"omit=yes"                as `Account`
      ,"width=100px"             as `Invoiced Month`
      ,"width=080px"             as `Currcy`
      ,"width=060px,right=yes"   as `CPA`
      ,"width=100px,right=yes"   as `CPA Value`
      ,"width=100px,right=yes"   as `Net Revenue`
      ,"width=100px,right=yes"   as `net RS_Val`
      ,"width=100px,right=yes"   as `Total Commiss`
      ,"width=100px,right=yes"   as `Amount Due`
      ,"width=200px,tooltip=yes" as `Invoice address`
FROM DUAL WHERE '
, IF(v_Meta="YES",'1=1','1=0')
,')
UNION ALL '
);
 
SET v_SQL=CONCAT(
v_CTE,
v_SQLmeta,
v_SQL_Result,
';'
);

/********************************************************************/
-- -------------------------------------------------------------------
-- PROCESO DE EXPORTACION DE PROFORMAS A `campaign_publisher_invoice`;

SET v_EXP_WhereOwner="",v_EXP_WherePublisher="",v_EXP_WhereInvoiced_Month="";

IF v_Owner_id      !="ALL" THEN SET v_EXP_WhereOwner         =CONCAT(" AND Owner_id        =",v_Owner_id);  END IF;
IF v_Publisher_id  !="ALL" THEN SET v_EXP_WherePublisher     =CONCAT(" AND Publisher_id=",v_Publisher_id ); END IF;
IF v_Month         !="ALL" THEN SET v_EXP_WhereInvoiced_Month=CONCAT(" AND Invoiced_Month='",v_Month,"'" ); END IF;

SET v_SQL_Result_export=CONCAT('
(
SELECT
      "Proforma" as `Category`
      ,`Owner`
      ,`Owner_id`
      ,`Publisher`
      ,`Publisher_id`
      ,`Brand`
      ,`Account`
      ,`Date` AS `Invoiced_Month`
      ,CASE
         WHEN `Date` REGEXP ''^[0-9]{4}-[0-9]{2}$''
            THEN DATE_ADD(LAST_DAY(CONCAT(`Date`,''-01'')), INTERVAL 10 DAY)
         ELSE NULL
       END AS `Date`
      ,CASE
         WHEN `Date` REGEXP ''^[0-9]{4}-[0-9]{2}$'' THEN
            DATE_ADD(
               LAST_DAY(CONCAT(`Date`, ''-01'')),
               INTERVAL
               CASE
                  WHEN INSTR(IFNULL(`Pay_Day`,''''), ''+'') > 0
                     THEN CAST(SUBSTRING_INDEX(`Pay_Day`, ''+'', -1) AS UNSIGNED)
                  ELSE 0
               END DAY
            )
         ELSE NULL
       END AS `Due_Date`
      ,`Currency`
      ,`CPA`
      ,`CPA_Value`
      ,`Net_Revenue`
      ,`net_RS_Val`
      ,`Total_Commission`
      ,`Total_Commission` as `Amount`
      ,`Invoice_address`
FROM Main_Table_Data MTD
WHERE NOT EXISTS (
   SELECT 1
   FROM campaign_publisher_invoice CPI
   WHERE CPI.Owner_id       = MTD.`Owner_id`
     AND CPI.Publisher_id   = MTD.`Publisher_id`
     AND CPI.Invoiced_Month = MTD.`Date`
     AND CPI.Brand          = MTD.`Brand`
     AND CPI.Account        = MTD.`Account`
)
)
ORDER BY Owner,Publisher,Brand,`Account`
');

IF v_Debug!="NO" AND v_Export="YES" THEN SELECT v_EXP_WhereOwner,v_EXP_WherePublisher,v_EXP_WhereInvoiced_Month; END IF;

SET v_SQL_DELETE=CONCAT(
'DELETE FROM `campaign_publisher_invoice` 
 WHERE Category="Proforma"
 ',v_EXP_WhereOwner         
  ,v_EXP_WherePublisher     
  ,v_EXP_WhereInvoiced_Month
 ,';'
);

SET v_SQL_EXPORT=CONCAT(
'
INSERT INTO campaign_publisher_invoice 
   (`Category`,`Owner`,`Owner_id`,`Publisher`,`Publisher_id`,`Brand`,`Account`
    ,`Invoiced_Month`,`Date`,`Due_Date`,`Currency`
    ,`CPA`,`CPA_Value`,`Net_Revenue`,`net_RS_Val`,`Total_Commission`
    ,`Ammount`,`Invoice_address`)
',
v_CTE,
v_SQL_Result_export,
';'
);

-- Actualiza los campos de valor en registros ya existentes (misma clave del índice Owner_id)
SET v_SQL_UPDATE=CONCAT(
v_CTE,
'
UPDATE campaign_publisher_invoice CPI
JOIN Main_Table_Data src
   ON  CPI.Owner_id       = src.Owner_id
   AND CPI.Publisher_id   = src.Publisher_id
   AND CPI.Invoiced_Month = src.`Date`
   AND CPI.Brand          = src.Brand
   AND CPI.Account        = src.Account
SET
    CPI.`Date`             = CASE WHEN src.`Date` REGEXP ''^[0-9]{4}-[0-9]{2}$''
                                  THEN DATE_ADD(LAST_DAY(CONCAT(src.`Date`,''-01'')), INTERVAL 10 DAY)
                                  ELSE NULL END
   ,CPI.`Currency`         = src.`Currency`
   ,CPI.`CPA`              = src.`CPA`
   ,CPI.`CPA_Value`        = src.`CPA_Value`
   ,CPI.`Net_Revenue`      = src.`Net_Revenue`
   ,CPI.`net_RS_Val`       = src.`net_RS_Val`
   ,CPI.`Total_Commission` = src.`Total_Commission`
   ,CPI.`Invoice_address`  = src.`Invoice_address`
;'
);

IF v_Export="YES" 
THEN
   IF v_Debug!="NO" THEN SELECT v_SQL_DELETE; END IF;
   IF v_Debug!="NO" THEN SELECT v_SQL_UPDATE; END IF;
   IF v_Debug!="NO" THEN SELECT v_SQL_EXPORT; END IF;

-- borra proformas existentes
   IF v_Debug != "YES" THEN
      SET @v_SQL_DELETE = v_SQL_DELETE;
      PREPARE stmt1 FROM @v_SQL_DELETE;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;

   -- actualiza invoices existentes
   IF v_Debug != "YES" THEN
      SET @v_SQL_UPDATE = v_SQL_UPDATE;
      PREPARE stmt1 FROM @v_SQL_UPDATE;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;
   -- Paso 2: inserta registros nuevo proforma (no existentes según índice)
   IF v_Debug != "YES" THEN
      SET @v_SQL_EXPORT = v_SQL_EXPORT;
      PREPARE stmt1 FROM @v_SQL_EXPORT;
      EXECUTE stmt1;
      DEALLOCATE PREPARE stmt1;
   END IF;
END IF;
-- -------------------------------------------------------------------
/********************************************************************/


SET v_SQLfilters=CONCAT(
v_CTE,'
,MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
)
(SELECT "01" as "Korder","Owner" AS "Key",`Owner` AS "Value","Owner_id" AS `CallKey`,`Owner_id` AS "CallValue","" AS "Rows","no" AS "TypeAction","" AS "MsgAction" 
                                                                        FROM Main_Table_Data GROUP BY `Owner_id`) UNION ALL
(SELECT "03" as "Korder","Invoiced Month" AS "Key",LEFT(`Date`,7) AS "Value","Month" AS `CallKey`,LEFT(`Date`,7) AS `CallValue`
                                                                         ,"" AS "Rows","no" AS "TypeAction","" AS "MsgAction" FROM MonthFilter) UNION ALL  
(SELECT "05" as "Korder","Export to invoices\' file" AS "Key","EXPORT" AS "Value","EXPORT" AS `CallKey`,"yes" AS "CallValue","" AS "Rows" 
                                                                        ,"yes" AS "TypeAction","Exported OK" AS "MsgAction"
                                                                        FROM DUAL) UNION ALL                                                                        
(SELECT "07" as "Korder","Operator" AS "Key",`Publisher` AS "Value","Publisher_id" AS `CallKey`,`Publisher_id` AS "CallValue","" AS "Rows","no" AS "TypeAction","" AS "MsgAction"  
                                                                        FROM Main_Table_Data GROUP BY `Publisher_id`) 
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3 ASC 
;');

IF v_Filters="YES" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Debug != "YES" THEN
   SET @v_SQL = v_SQL;
	PREPARE stmt1 FROM @v_SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;


/*
update campaign_publisher_invoice i
LEFT JOIN campaign_publisher  p     ON p.id=i.Publisher_id 
LEFT JOIN account_account     a     ON a.id=i.Owner
set i.Publisher=p.Advertiser_name
   ,i.Owner_id=i.Owner
   ,i.Owner=a.Username
   ,i.Invoice_address=p.Commercial_History
   ,i.Status_id=i.Status
   ,i.Status=case when i.Status_id=1 then "Active" else "Inactive" end
where i.Category="Invoice"
;

SELECT  
    "01" AS "Korder",  
    "Owner" AS "Key",  
    `Owner` AS "Value",  
    "Owner_id" AS `CallKey`,  
    `Owner_id` AS "CallValue",  
    "" AS "Rows",  
    "yes" AS "TypeAction",  
    "Operación exitosa" AS "MsgAction"  
FROM DUAL;
 
*/