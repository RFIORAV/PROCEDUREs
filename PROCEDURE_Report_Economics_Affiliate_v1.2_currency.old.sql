/*
PROCEDURE_Report_Economics_Affiliate_v1.sql - Reporte Financial Mov/Manual Adjustment según filtros

Descripción:
  Procedimiento Report_Economics_Affiliate.
D:\Reinaldo\_FRA\db\PROCEDUREs\PROCEDURE_Report_Economics_Affiliate_v1.2_currency.old.sql
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
call Report_Economics_Affiliate('Affiliate_id=39,debug=YE');

29.03.2023 V1     Basada en PROCEDURE_Report_FinMov_ManAdj_v1.1
12.01.2024 v1.1   Descripción incluye channel y sub_affliate
09.08.2024 v1.2   Tratamiento Currency
                  Obtiene @Currency desde @GridCurrency en tabla util_settings
*/

DROP PROCEDURE IF EXISTS Report_Economics_Affiliate;
 
DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Economics_Affiliate`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report Financial Mov / Manual Adjustments/ Commis Affiliate'
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.2 09.08.2024';
SET @CurrentDay      =curdate();
SET @Affiliate_id    ='ALL';

SET @Month_From      =LEFT(DATE_SUB(CURDATE(), INTERVAL 5 MONTH),7);
SET @Month_From      ='2022-01';
SET @Operation       ='ALL';
SET @Status          ='ALL';
SET @Filters         ='NO';
SET @TotLine         ='FIRST';
SET @Meta            ='YES';
SET @Debug           ='NO';
SET @FinMov          ='YES';
SET @ManAdj          ='YES';
SET @Search          ='';

SET @MS_id           ='ALL';
SET @Owner           ='ALL';
SET @Advertiser_id   ='ALL';
SET @Account_id      ='ALL';
SET @Channel_id      ='ALL';
SET @DealbyProduct   ='NO';
SET @Platform        ='ALL';
SET @Brand_Group     ='ALL';
SET @Currency        ='EUR';
SET @Total           ='YES';
SET @View            ='VIEWGES';
SET @GroupByMS       ='NO';
SET @OnlyOverCap     ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month_From,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

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

   IF lower(@k)='Month_From'      THEN SET @Month_From    =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='operation'       THEN SET @Operation     =      @v;  END IF;
   IF lower(@k)='status'          THEN SET @Status        =      @v;  END IF;
   IF lower(@k)='finmov'          THEN SET @FinMov        =      @v;  END IF;
   IF lower(@k)='manadj'          THEN SET @ManAdj        =      @v;  END IF;
   IF lower(@k)='search'          THEN SET @Search        =      @v;  END IF;

END WHILE;

-- Recupera espacios reemplazados en front end por caracter "\"
SET @Operation      =replace(@Operation,"!"," ");
-- SET @Platform     =replace(@Platform,"!"," ");
-- SET @Brand_Group  =replace(@Brand_Group,"!"," ");

-- IF @Debug!="NO" THEN SELECT @Operation,@Platform,@Brand_Group; END IF;
--
-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

IF @Debug!="NO" THEN SELECT @Month_From,@View,@Filters,@OWNER,@OnlyOverCap,@Brand_Group,@Advertiser_id,@Affiliate_id,@Account_id
,@Channel_id,@Operation,@DealbyProduct,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @Month_From    =concat('"',@Month_From,'"');
SET @WhereMonth_From    ='';
SET @WhereAffiliate_id  ='';
SET @WhereOperation     ='';
SET @WhereStatus        ='';
SET @WhereSearch        ='';

IF @Affiliate_id  !="ALL" THEN SET @WhereAffiliate_id  =CONCAT(" AND M.Affiliate_id   =",@Affiliate_id  ); END IF;
IF @Status        !="ALL" THEN SET @WhereStatus        =CONCAT(" AND M.`Status`       ='",@Status,"'");    END IF;
-- IF @Operation     !="ALL" THEN SET @WhereOperation     =CONCAT(" AND M.`OP_type`      ='",@Operation,"'"); END IF;
-- IF @Search        !=""    THEN SET @WhereSearch        =@SearchClause; END IF;

IF @Debug!="NO" THEN SELECT @WhereAffiliate_id,@WhereOperation,@WhereStatus,@WhereSearch; END IF;

/**************************************************************************************************************/
SET @SQLmeta=concat(
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
   ,"width=100px"             as Operator
	FROM DUAL WHERE @Meta="YES")
UNION ALL 
'
);
-- IF @Debug!="NO" THEN SELECT @SQLmeta; END IF;
/**************************************************************************************************************/

SET SESSION group_concat_max_len = 100000;
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
SET @CTE=concat('
WITH Movements AS (
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
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
  AND M.Month>=',@Month_From  
   ,@WhereAffiliate_id,
'  
UNION ALL
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
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
WHERE @FinMov="yes"
  AND M.`Status` IN (1,2)
  AND left(M.Date,7)>=',@Month_From  
   ,@WhereAffiliate_id
   ,@WhereStatus,
'
UNION ALL
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
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
WHERE @ManAdj="yes"
  AND M.`Status` IN (1,2)
  AND left(M.Date,7)>=',@Month_From 
   ,@WhereAffiliate_id
   ,@WhereStatus
,')'
);

SET @CloseQuery=';';
SET @Balance:=0;

SET @SQL=concat(
@CTE,
@SQLmeta,
'
(SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
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
   ,IF(@Meta="YES","'total' as Meta,",""),'
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
GROUP BY M.MonthFrom ',if(@WhereAffiliate_id="",", M.Affiliate",""),',Currency
)
UNION ALL
(
SELECT '
   ,IF(@Meta="YES","'total' as Meta,",""),'
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
',@CloseQuery
);

SET @SQLfilters=CONCAT(
@CTE,'
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

IF @Filters!="NO" THEN SET @SQL=@SQLfilters; END IF;

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
call Report_Economics_Affiliate('debug=ye'); -- Devuelve todas los movimientos de los últimos 6 meses
call Report_Economics_Affiliate('debug=yes,Affiliate_id=39,filters=no,meta=yes');
call Report_Economics_Affiliate('debug=ye,search=invoice,filters=yes');
call Report_Economics_Affiliate('debug=ye,filters=yeS');
call Report_Economics_Affiliate('Affiliate_id="39",status=active,meta=yes,debug=non');
call Report_Economics_Affiliate('Affiliate_id=39,status=active,DealbyProduct=yes,debug=no');
call Report_Economics_Affiliate('Affiliate_id=39,debug=YE');
call Report_Economics_Affiliate('Affiliate_id=827,debug=YES');
*/
