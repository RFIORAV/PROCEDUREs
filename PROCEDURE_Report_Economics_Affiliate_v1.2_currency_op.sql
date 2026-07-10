/*
PROCEDURE_Report_Economics_Affiliate_v1.sql - Reporte Financial Mov/Manual Adjustment según filtros

Descripción:
  Procedimiento Report_Economics_Affiliate_dev.
D:\Reinaldo\_FRA\db\PROCEDUREs\PROCEDURE_Report_Economics_Affiliate_v1.2_currency.sql
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Month_From      =[AAAA-MM]. OPCIONAL. Default=Last 6 Month.
FinMov          =[Yes | No]. OPCIONAL. Incluir Financial Movements. Default=yes
ManAdj          =[Yes | No]. OPCIONAL. Incluir Manual Adjustements. Default=yes
Affiliate_id    =[ALL | id del Affiliate]. OBLIGATORIO. Default=''
Operation       =[ALL | Product]. OPCIONAL. Default=ALL. Si tiene más de una palabra, separar con "!" en lugar de espacio
Status          =[ALL | Status]. OPCIONAL. Default=ALL
Search          =[(dato a buscar]. OPCIONAL. Busca string en Afiliate/Operation/Description/Extra
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.
     
Keys no utilizadas:
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
DealbyProduct   =[No | Yes]. Devuelve último deal activo por cada Product. OPCIONAL. Default=no.
MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Advertiser_id   =[ALL | id del Advertiser]. OPCIONAL. Default=ALL
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
GroupByMS       =[Yes | No]. Agrupa Product by MS. OPCIONAL. Default=No
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
View            =[viewAFF | viewGES]. Info de Fact2 (viewAFF) o de Fact1 (viewGES). OPCIONAL. Default=viewAFF
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Economics_Affiliate(''); -- Devuelve todas los movimientos de los últimos 6 meses
call Report_Economics_Affiliate('debug=ye,Affiliate_id=74,filters=no,meta=yes');
call Report_Economics_Affiliate('debug=ye,search=invoice,filters=ye');
call Report_Economics_Affiliate('Affiliate_id="39",status=active,meta=yes,debug=no');
call Report_Economics_Affiliate('Affiliate_id=39,status=active,DealbyProduct=yes,debug=no');
call Report_Economics_Affiliate_dev('Affiliate_id=39,debug=YE');

29.03.2023 V1     Basada en PROCEDURE_Report_FinMov_ManAdj_v1.1
12.01.2024 v1.1   Descripción incluye channel y sub_affliate
09.08.2024 v1.2   Tratamiento Currency
                  Obtiene @Currency desde @GridCurrency en tabla util_settings
02.03.2026 v1.3   Fix: eliminación de variables globales
10.04.2026 v1.4   Meta: renombre de label Operator a User
*/

-- DROP PROCEDURE IF EXISTS Report_Economics_Affiliate;
DROP PROCEDURE IF EXISTS Report_Economics_Affiliate_dev;
 
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Economics_Affiliate_dev`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Financial Mov / Manual Adjustments/ Commis Affiliate'
BEGIN
DECLARE v_Version         VARCHAR(30);
DECLARE v_CurrentDay      DATE;
DECLARE v_Affiliate_id    VARCHAR(50);
DECLARE v_Month_From      VARCHAR(20);
DECLARE v_Operation       VARCHAR(200);
DECLARE v_Status          VARCHAR(100);
DECLARE v_Filters         VARCHAR(10);
DECLARE v_TotLine         VARCHAR(20);
DECLARE v_Meta            VARCHAR(10);
DECLARE v_Debug           VARCHAR(20);
DECLARE v_FinMov          VARCHAR(10);
DECLARE v_ManAdj          VARCHAR(10);
DECLARE v_Search          VARCHAR(250);
DECLARE v_MS_id           VARCHAR(50);
DECLARE v_Owner           VARCHAR(50);
DECLARE v_Advertiser_id   VARCHAR(50);
DECLARE v_Account_id      VARCHAR(50);
DECLARE v_Channel_id      VARCHAR(50);
DECLARE v_DealbyProduct   VARCHAR(10);
DECLARE v_Platform        VARCHAR(50);
DECLARE v_Brand_Group     VARCHAR(50);
DECLARE v_Currency        VARCHAR(10);
DECLARE v_Total           VARCHAR(10);
DECLARE v_View            VARCHAR(20);
DECLARE v_GroupByMS       VARCHAR(10);
DECLARE v_OnlyOverCap     VARCHAR(10);
DECLARE v_InputCommLine   VARCHAR(300);
DECLARE v_e               INT DEFAULT 0;
DECLARE v_c               INT DEFAULT 0;
DECLARE v_k               VARCHAR(100);
DECLARE v_v               VARCHAR(250);
DECLARE v_MultiCurrency   VARCHAR(10);
DECLARE v_WhereMonth_From   TEXT;
DECLARE v_WhereAffiliate_id TEXT;
DECLARE v_WhereOperation    TEXT;
DECLARE v_WhereStatus       TEXT;
DECLARE v_WhereSearch       TEXT;
DECLARE v_SQLmeta         LONGTEXT;
DECLARE v_CTE             LONGTEXT;
DECLARE v_CloseQuery      VARCHAR(5);
DECLARE v_Balance         DECIMAL(20,4);
DECLARE v_SQL             LONGTEXT;
DECLARE v_SQLfilters      LONGTEXT;
-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version         ='v1.4 10.04.2026';
SET v_CurrentDay      =curdate();
SET v_Affiliate_id    ='ALL';

SET v_Month_From      =LEFT(DATE_SUB(CURDATE(), INTERVAL 5 MONTH),7);
SET v_Month_From      ='2022-01';
SET v_Operation       ='ALL';
SET v_Status          ='ALL';
SET v_Filters         ='NO';
SET v_TotLine         ='FIRST';
SET v_Meta            ='YES';
SET v_Debug           ='NO';
SET v_FinMov          ='YES';
SET v_ManAdj          ='YES';
SET v_Search          ='';

SET v_MS_id           ='ALL';
SET v_Owner           ='ALL';
SET v_Advertiser_id   ='ALL';
SET v_Account_id      ='ALL';
SET v_Channel_id      ='ALL';
SET v_DealbyProduct   ='NO';
SET v_Platform        ='ALL';
SET v_Brand_Group     ='ALL';
SET v_Currency        ='EUR';
SET v_Total           ='YES';
SET v_View            ='VIEWGES';
SET v_GroupByMS       ='NO';
SET v_OnlyOverCap     ='NO';

SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month_From,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

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

   IF lower(v_k)='Month_From'      THEN SET v_Month_From    =UPPER(v_v); END IF;
   IF lower(v_k)='affiliate_id'    THEN SET v_Affiliate_id  =UPPER(v_v); END IF;
   IF lower(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF lower(v_k)='filters'         THEN SET v_Filters       =UPPER(v_v); END IF;
   IF lower(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;
   IF lower(v_k)='operation'       THEN SET v_Operation     =      v_v;  END IF;
   IF lower(v_k)='status'          THEN SET v_Status        =      v_v;  END IF;
   IF lower(v_k)='finmov'          THEN SET v_FinMov        =      v_v;  END IF;
   IF lower(v_k)='manadj'          THEN SET v_ManAdj        =      v_v;  END IF;
   IF lower(v_k)='search'          THEN SET v_Search        =      v_v;  END IF;

END WHILE;

-- Recupera espacios reemplazados en front end por caracter "\"
SET v_Operation      =replace(v_Operation,"!"," ");
-- SET @Platform     =replace(@Platform,"!"," ");
-- SET @Brand_Group  =replace(@Brand_Group,"!"," ");

-- IF @Debug!="NO" THEN SELECT @Operation,@Platform,@Brand_Group; END IF;
--
-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET v_MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET v_Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

IF v_Debug!="NO" THEN SELECT v_Month_From,v_View,v_Filters,v_OWNER,v_OnlyOverCap,v_Brand_Group,v_Advertiser_id,v_Affiliate_id,v_Account_id
,v_Channel_id,v_Operation,v_DealbyProduct,v_Platform,v_Currency,v_Total,v_Debug,v_Meta,InputCommLine; END IF;

SET v_Month_From    =concat('"',v_Month_From,'"');
SET v_WhereMonth_From    ='';
SET v_WhereAffiliate_id  ='';
SET v_WhereOperation     ='';
SET v_WhereStatus        ='';
SET v_WhereSearch        ='';

IF v_Affiliate_id  !="ALL" THEN SET v_WhereAffiliate_id  =CONCAT(" AND M.Affiliate_id   =",v_Affiliate_id  ); END IF;
IF v_Status        !="ALL" THEN SET v_WhereStatus        =CONCAT(" AND M.`Status`       ='",v_Status,"'");    END IF;
-- IF @Operation     !="ALL" THEN SET @WhereOperation     =CONCAT(" AND M.`OP_type`      ='",@Operation,"'"); END IF;
-- IF @Search        !=""    THEN SET @WhereSearch        =@SearchClause; END IF;

IF v_Debug!="NO" THEN SELECT v_WhereAffiliate_id,v_WhereOperation,v_WhereStatus,v_WhereSearch; END IF;

/**************************************************************************************************************/
SET v_SQLmeta=concat(
'(
SELECT
   "setting"                  as Meta
   ,"omit=true"               as id
   ,"omit=true"               as Affiliate_id
   ,"width=200px"             as Affiliate
   ,"width=100px"             as Date
   ,"omit=true"               as Month
   ,"width=100px"             as Op
   ,"width=300px"             as `Desc`
   ,"width=100px"             as `currency`
   ,"width=120px,right=yes"   as `Debit`
   ,"width=120px,right=yes"   as `Credit`
   ,"width=120px,right=yes"   as `Balance`
   ,"omit=true"               as Status_id
   ,"width=90px"              as Status
   ,"omit=true"               as extra
   ,"omit=true"               as Creation_Date
   ,"width=160px"             as `Last_Update`
   ,"width=100px"             as User
	FROM DUAL WHERE "',v_Meta,'"="YES")
UNION ALL 
'
);
-- IF @Debug!="NO" THEN SELECT @SQLmeta; END IF;
/**************************************************************************************************************/

-- SET SESSION group_concat_max_len = 100000;
/*
SELECT `id`,`Affiliate_id`,`Date`,`Op_type`,`Description`,`Amount_Debit`,`Amount_Credit`,`Balance`,`Status`,`Extra`
      ,`Creation_Date`,`Last_Update`,`Operator`
FROM account_financial_movement

SELECT `id`,`Affiliate_id`,`Date`,`Op_type`,`Description`,`Amount_Debit`,`Amount_Credit`,`Balance`,`Status`,`Extra`
      ,`Creation_Date`,`Last_Update`,`Operator`
FROM account_manual_adjustments

SELECT `Month`,`Affiliate`,`Brand`,`Affiliate_id`,`Advertiser_id`,`CPA`,`net_CPA_Val`
      ,`net_RS_Val`,`net_Total_comm`,`RS_carry_NCO`,`Net_Revenue`,`gross_CPA_Val`,`gross_RS_Val` 
FROM monthly_comms_affiliate

*/
SET v_CTE=concat('
WITH Movements AS (
SELECT '
   ,IF(v_Meta="YES","'data' as `Meta`,",""),'
    0                            as `id`
   ,M.`Affiliate_id`
   ,M.`Affiliate`
   ,last_day(concat(M.`Month`,"-01")) as `Date`
   ,M.`Month`                    as `MonthFrom`
   ,"Commision"                  As `Operation`
   -- ,M.`Brand`                    as `Description`
   ,CONCAT_WS(" ",Brand,Product_Real,"-",Channel," ",Sub_Affiliate) as `Description`
   ,`Currency`
   ,0                            as `Amount_Debit`
   ,round(M.`net_Total_comm`,2) as `Amount_Credit`
   ,""                           as `Balance`
   ,"0"                          as `Status_id` 
   ,""                           as `Status`
   ,""                           as `Extra`
   ,""                           as `Creation_Date`
   ,""                           as `Last_Update`
   ,""                           as `Operator`
FROM monthly_comms_affiliate_v5 M
WHERE M.`net_Total_comm`<>0
  AND M.Month>=',v_Month_From  
   ,v_WhereAffiliate_id,
'  
UNION ALL
SELECT '
   ,IF(v_Meta="YES","'data' as `Meta`,",""),'
    M.`id`
   ,M.`Affiliate_id`
   ,A.`username`                 as Affiliate
   ,M.`Date`
   ,left(M.Date,7)               as `MonthFrom`
   ,M.`Op_type`                  As `Operation`
   ,M.`Description`
   ,M.Currency
   ,round(ifnull(M.`Amount_Debit`,"0") ,2) as `Amount_Debit`
   ,round(ifnull(M.`Amount_Credit`,"0"),2) as `Amount_Credit`
   ,""                           as `Balance`
   ,M.`Status`                   as `Status_id`
   ,case M.`Status` when "1" then "Accepted" when "2" then "Paid" end as `Status`
   ,ifnull(M.`Extra`,"")         as `Extra`
   ,M.`Creation_Date`
   ,left(M.`Last_Update`,16)     as `Last_Update`
   ,ifnull(A1.`username`,ifnull(M.`Operator`,"SysOp")) as `Operator`
FROM account_financial_movement M
LEFT JOIN `account_account` `A` ON `A`.`id` = `M`.`Affiliate_id`
LEFT JOIN `account_account` `A1` ON `A1`.`id` = `M`.`Operator`
-- --------------------------------------------------------------------------------------
WHERE "',LOWER(v_FinMov),'"="yes"
  AND M.`Status` IN (1,2)
  AND left(M.Date,7)>=',v_Month_From  
   ,v_WhereAffiliate_id
   ,v_WhereStatus,
'
UNION ALL
SELECT '
   ,IF(v_Meta="YES","'data' as `Meta`,",""),'
    M.`id`
   ,M.`Affiliate_id`
   ,A.`username`                 as Affiliate
   ,M.`Date`
   ,left(M.Date,7)               as `MonthFrom`
   ,M.`Op_type`                  As `Operation`
   ,M.`Description`
   ,M.`Currency`
   ,round(ifnull(M.`Amount_Debit`,"0") ,2) as `Amount_Debit`
   ,round(ifnull(M.`Amount_Credit`,"0"),2) as `Amount_Credit`
   ,""                           as `Balance`
   ,M.`Status`                   as `Status_id`
   ,case M.`Status` when "1" then "Accepted" when "2" then "Confirmed" end as `StatusText`
   ,ifnull(M.`Extra`,"")         as `Extra`
   ,M.`Creation_Date`
   ,left(M.`Last_Update`,16)     as `Last_Update`
   ,ifnull(A1.`username`,ifnull(M.`Operator`,"SysOp")) as `Operator`
FROM account_manual_adjustments M
LEFT JOIN `account_account` `A` ON `A`.`id` = `M`.`Affiliate_id`
LEFT JOIN `account_account` `A1` ON `A1`.`id` = `M`.`Operator`
-- --------------------------------------------------------------------------------------
WHERE "',LOWER(v_ManAdj),'"="yes"
  AND M.`Status` IN (1,2)
  AND left(M.Date,7)>=',v_Month_From 
   ,v_WhereAffiliate_id
   ,v_WhereStatus
,')'
);

SET v_CloseQuery=';';
SET v_Balance:=0;

SET v_SQL=concat(
v_CTE,
v_SQLmeta,
'
(SELECT '
   ,IF(v_Meta="YES","'data' as `Meta`,",""),'
    `id`
   ,`Affiliate_id`
   ,`Affiliate`
   ,`Date`
   ,`MonthFrom`
   ,`Operation`
   ,`Description`
   ,`Currency`
   ,format(`Amount_Debit`,2)     as `Amount_Debit`
   ,format(`Amount_Credit`,2)    as `Amount_Credit`
   ,""                           as `Balance`
   ,`Status_id` 
   ,`Status`
   ,`Extra`
   ,`Creation_Date`
   ,`Last_Update`
   ,`Operator` 
FROM Movements M    
)
UNION ALL
(
SELECT '
   ,IF(v_Meta="YES","'total' as Meta,",""),'
    "~~~~~"
   ,"~~~~~"
   ,Affiliate
   ,CONCAT(M.MonthFrom,"-º ") as Date
   ,M.MonthFrom
   ,"~~~~~"
   ,"~~~~~ Monthly totals ~~~~~"
   ,Currency
   ,FORMAT(SUM(IFNULL(M.Amount_Debit,0)),2)       as Amount_Debit
   ,FORMAT(SUM(IFNULL(M.Amount_Credit,0)),2)      as Amount_Credit
   ,FORMAT(SUM(M.Amount_Debit-M.Amount_Credit),2) as Balance  
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
FROM Movements M 
GROUP BY M.MonthFrom ',if(v_WhereAffiliate_id="",", M.Affiliate",""),',Currency
)
UNION ALL
(
SELECT '
   ,IF(v_Meta="YES","'total' as Meta,",""),'
    "~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,CONCAT(LEFT(CURDATE(),7),"-ºº") as Date
   ,M.MonthFrom
   ,"~~~~~"
   ,"~~~~~ Grand total ~~~~~"
   ,Currency
   ,FORMAT(SUM(ifnull(M.Amount_Debit,0)),2)       as Amount_Debit
   ,FORMAT(SUM(ifnull(M.Amount_Credit,0)),2)      as Amount_Credit
   ,FORMAT(SUM(M.Amount_Debit-M.Amount_Credit),2) as Balance
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
FROM Movements M 
   GROUP BY Currency
-- GROUP BY M.MonthFrom ',if(@WhereAffiliate_id="",", M.Affiliate",""),',Currency
)
ORDER BY Affiliate,Date DESC,Currency
',v_CloseQuery
);

SET v_SQLfilters=CONCAT(
v_CTE,'
(SELECT "01" as "Korder"
            ,"Affiliate" AS "Key"
                         ,`Affiliate` AS "Value"
                                          ,"Affiliate_id" AS `CallKey`
                                                         ,`Affiliate_id` AS "CallValue"
                                                                         ,COUNT(*) AS "Rows"
                                                                                        FROM Movements GROUP BY `Affiliate`)  -- UNION ALL
-- (SELECT "13","Status"     ,`Status`       ,"Status"       ,`Status_id`   ,COUNT(*) AS K FROM Movements GROUP BY IFNULL(`Status`     ,"")) UNION ALL
-- (SELECT "05","Affiliate"  ,`Affiliate`    ,"Affiliate_id" ,`Affiliate_id`,COUNT(*) AS K FROM Movements GROUP BY IFNULL(`Affiliate`  ,"")) -- UNION ALL
-- (SELECT "19","Operation"  ,`Operation`    ,"Operation"  ,`Operation`     ,COUNT(*) AS K FROM Movements GROUP BY IFNULL(`Operation`  ,"")) UNION ALL
-- (SELECT "01","Data"       ,"Fin Movements","FinMov"     ,"yes"           ,"" AS K FROM DUAL) UNION ALL
-- (SELECT "01","Data"       ,"Manual Adjust","ManAdj"     ,"yes"           ,"" AS K FROM DUAL) -- UNION ALL
ORDER BY 1,3
;');

IF v_Filters!="NO" THEN SET v_SQL=v_SQLfilters; END IF;

IF v_Debug!="NO" THEN SELECT v_SQLfilters; END IF;
IF v_Debug!="NO" THEN SELECT v_SQL; END IF;

IF v_Debug != "YES" THEN
  SET @sql_exec = v_SQL;
	PREPARE stmt1 FROM @sql_exec;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Report_Economics_Affiliate('debug=ye'); -- Devuelve todas los movimientos de los últimos 6 meses
call Report_Economics_Affiliate('debug=yes,Affiliate_id=39,filters=no,meta=yes');
call Report_Economics_Affiliate('debug=ye,search=invoice,filters=yes');
call Report_Economics_Affiliate('debug=ye,filters=yeS');
call Report_Economics_Affiliate('Affiliate_id="39",status=active,meta=yes,debug=non');
call Report_Economics_Affiliate('Affiliate_id=39,status=active,DealbyProduct=yes,debug=no');
call Report_Economics_Affiliate('Affiliate_id=39,debug=YE');
call Report_Economics_Affiliate('Affiliate_id=827,debug=YES');
*/
