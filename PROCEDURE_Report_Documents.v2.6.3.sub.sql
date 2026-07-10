/*
PROCEDURE_Report_Documents.sql - Reports Documents

Descripción:
  Procedimiento Report_Documents.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

mode             =[ GESTOR | AFFILIATE | MAF ] OBLIGATORIO.
MasterAff_id     =[ MasterAff_id ]. SOLO PARA MAF EN MODO MAF. Default=''
Affiliate_id     =[id de affiliate]
Op_Type          =[ Withdraw | "NoWithdraw" ] Tipo de documento. Default='NoWithdraw'
ActionTaken      =[ "ALL" | "Pending" | "Accepted" | "Paid" | "Blocked" | "Other" ] Status de la operación en account_financial_movement. Default=ALL
Month            =[YYYY-MM]. Filtro por mes en formato YYYY-MM. Filtra registros de account_account_bills por Creation_Date. OPCIONAL. Default=''
Filters          =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta             =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug            =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Documents('Mode=Gestor');
call Report_Documents('Mode=Gestor,Affiliate_id=334');
call Report_Documents('Mode=Gestor,Affiliate_id=74,Op_Type=Withdraw,Month=2025-07,debug=non');
call Report_Documents('Mode=Gestor,Op_Type=Withdraw,Month=2026-03,debug=non');
call Report_Documents('Mode=Gestor,Op_Type=Withdraw,debug=non');
call Report_Documents('Mode=Gestor,filters=yes,debug=non');


10.10.2023 V1     Karen. Primera versión operativa
01.02.2024 V2     Karen. Se agregó "Op Type" y "Financial_Movement_id"
27.03.2024 v2.1   RF. Cambios en la presentación del grid (RS)
09.04.2024 v2.2   RR. Muestra Confirmed y Estimated Balance
27.05.2024 v2.3   Tratamiento de Subafiliados
                  Tratamiento de Master Affiliate
11.09.2024 v2.4   Agregado filtros
09.10.2024 v2.5   Agregado Description
22.09.2025 v2.6   Agregado parámetro Month para filtrar por mes en Creation_Date
28.02.2026 v2.6.1 Fix: eliminación de variables globales
26.03.2026 v2.6.2 Agrega tabla temporal tmp_balance_by_affiliate    
27.05.2026 v2.6.3 Añadida opción colorBg=[Pending:orange;Accepted:green;Paid:green;Blocked:red;Other:orange] a columna Action taken
*/

DROP PROCEDURE IF EXISTS Report_Documents;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Documents`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v2.6.3 27.05.2026 - Report Documents - Gestor/Affiliate'

proc_label:BEGIN
DECLARE v_version             VARCHAR(30);
DECLARE v_current_day         DATE;
DECLARE v_affiliate_id        VARCHAR(30);
DECLARE v_masteraff_id        VARCHAR(30);
DECLARE v_actiontaken         VARCHAR(20);
DECLARE v_op_type             VARCHAR(30);
DECLARE v_mode                VARCHAR(20);
DECLARE v_debug               VARCHAR(20);
DECLARE v_filters             VARCHAR(20);
DECLARE v_meta                VARCHAR(20);
DECLARE v_month               VARCHAR(10);
DECLARE v_input_comm_line     VARCHAR(500);
DECLARE v_e                   INT;
DECLARE v_c                   INT;
DECLARE v_k                   VARCHAR(100);
DECLARE v_v                   VARCHAR(250);
DECLARE v_lmonth              CHAR(7);
DECLARE v_date_confirm        CHAR(10);
DECLARE v_affiliate_group     INT;
DECLARE v_masteraff_group     INT;
DECLARE v_affiliate_list      TEXT;
DECLARE v_whereaffiliate_id   TEXT;
DECLARE v_whereactiontaken    TEXT;
DECLARE v_whereop_type        TEXT;
DECLARE v_wheremonth          TEXT;
DECLARE v_cte                 LONGTEXT;
DECLARE v_sqlmeta             LONGTEXT;
DECLARE v_sql                 LONGTEXT;
DECLARE v_sqlfilters          LONGTEXT;
DECLARE v_col_affiliate       VARCHAR(100);
DECLARE v_col_amount          VARCHAR(100);
DECLARE v_col_confbalance     VARCHAR(100);
DECLARE v_col_action_status   VARCHAR(100);
DECLARE v_col_action_taken    VARCHAR(100);
DECLARE v_col_reviewed_on     VARCHAR(100);
DECLARE v_col_remarks         VARCHAR(100);

SET v_version         ='v2.6.3 27.05.2026';
SET v_current_day     =CURDATE();
SET v_affiliate_id    ='';
SET v_masteraff_id    ='';
SET v_actiontaken     ='ALL';
SET v_op_type         ='NoWithdraw';
SET v_mode            ='';
SET v_debug           ='NO';
SET v_filters         ='NO';
SET v_meta            ='YES';
SET v_month           ='';

-- --------------------------------------------------------------------------
SET v_input_comm_line=CONCAT(InputCommLine ,',');      -- Coma de cierre
-- SET v_input_comm_line=REPLACE(v_input_comm_line,' ','');  -- Elimina espacios
SET v_input_comm_line=REPLACE(v_input_comm_line,'"','');  -- Elimina comillas

IF v_debug!="NO" THEN SELECT v_input_comm_line; END IF;
-- IF v_debug="YES" THEN SELECT v_owner,v_month,v_currency,v_advertiser_id,v_byaccount,v_debug,v_total,v_totline,v_orderby,v_order,v_input_comm_line; END IF;

WHILE v_input_comm_line>' ' DO
-- v_input_comm_line: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- v_input_comm_line: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_input_comm_line,'=');    				-- 6
   SET v_c=INSTR(v_input_comm_line,','); 					-- 14
   SET v_k=SUBSTRING(v_input_comm_line,1,v_e-1); 			-- Month
   SET v_v=SUBSTRING(v_input_comm_line,v_e+1,v_c-(v_e+1)); -- 2022-08
   SET v_input_comm_line=SUBSTRING(v_input_comm_line,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF LOWER(v_k)='affiliate_id'    THEN SET v_affiliate_id  =      v_v;  END IF;
   IF LOWER(v_k)='masteraff_id'    THEN SET v_masteraff_id  =      v_v;  END IF;
   IF LOWER(v_k)='actiontaken'     THEN SET v_actiontaken   =      v_v;  END IF;
   IF LOWER(v_k)='op_type'         THEN SET v_op_type       =      v_v;  END IF;
   IF LOWER(v_k)='mode'            THEN SET v_mode          =UPPER(v_v); END IF;
   IF LOWER(v_k)='meta'            THEN SET v_meta          =UPPER(v_v); END IF;
   IF LOWER(v_k)='filters'         THEN SET v_filters       =UPPER(v_v); END IF;
   IF LOWER(v_k)='debug'           THEN SET v_debug         =UPPER(v_v); END IF;
   IF LOWER(v_k)='month'           THEN SET v_month         =      v_v;  END IF;

END WHILE;
-- --------------------------------------------------------------------------
IF v_debug!="NO" THEN SELECT v_mode,v_masteraff_id,v_affiliate_id,v_month,v_actiontaken,v_op_type,v_debug,v_filters,v_meta,InputCommLine; END IF;

-- Validaciones --------------------------------------------------
IF   v_affiliate_id IN ("","ALL") AND v_mode NOT IN ("GESTOR","MAF")
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;
IF   v_masteraff_id IN ("","ALL") AND v_mode="MAF"
THEN
    Select 'data' as Meta,'MasterAff_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;
-- ----------------------------------------------------------------

SET v_lmonth=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET v_date_confirm=CONCAT(LEFT(CURDATE(),7),"-20");

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET v_affiliate_group=(SELECT group_id FROM account_account_groups
                       WHERE account_id=v_affiliate_id AND group_id=6);
IF  v_affiliate_group IS NULL THEN SET v_affiliate_group=0; END IF;
/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET v_masteraff_group=(SELECT group_id FROM account_account_groups
                       WHERE account_id=v_masteraff_id AND group_id=4);
IF  v_masteraff_group IS NULL THEN SET v_masteraff_group=0; END IF;

SET v_affiliate_list="";
IF v_masteraff_group = 4 THEN CALL Master_Sub_Affiliate(v_masteraff_id, v_affiliate_list); END IF;

/*---------------------------------------------------------------------------------*/

IF v_debug!="NO" THEN SELECT "after call",v_affiliate_id,v_affiliate_group,v_masteraff_id,v_masteraff_group,v_affiliate_list; END IF;

IF   v_mode="MAF" AND v_masteraff_group!=4
THEN
    Select 'data' as Meta,'MasterAff_id must be MAF' as '' from dual;
    LEAVE proc_label;
END IF;

SET v_whereaffiliate_id='';
SET v_whereactiontaken='';
SET v_whereop_type='';
SET v_wheremonth='';

IF  v_mode="AFFILIATE"  THEN SET v_whereaffiliate_id=CONCAT(" AND b.Account_id  =",v_affiliate_id);      END IF;
IF  v_mode="GESTOR" AND v_affiliate_id NOT IN ("","ALL")
                       THEN SET v_whereaffiliate_id=CONCAT(" AND b.Account_id  =",v_affiliate_id);         END IF;
IF  v_mode="MAF"        THEN SET v_whereaffiliate_id=CONCAT(" AND b.Account_id IN ",v_affiliate_list);    END IF;

IF  v_mode!="AFFILIATE"  THEN 
    IF  v_op_type="Withdraw" THEN SET v_whereop_type    =CONCAT(" AND b.Op_Type='",v_op_type,"'");
                            ELSE SET v_whereop_type      =" AND b.Op_Type!='Withdraw'";                      
    END IF;
END IF;
IF  v_actiontaken!="ALL" THEN SET v_whereactiontaken=CONCAT(" AND ActionTaken='",v_actiontaken,"'");     END IF;
IF  v_month!="" THEN SET v_wheremonth=CONCAT(" AND LEFT(b.Creation_Date,7)='",v_month,"'");              END IF;

IF  v_debug!="NO" THEN SELECT v_whereaffiliate_id,v_whereactiontaken,v_whereop_type,v_affiliate_group,v_masteraff_group,v_affiliate_list; END IF;

-- --------------------------------------------------------------------------
-- --------------------------------------------------------------------------

SET v_cte=CONCAT('
WITH Main_Table_Data as (
SELECT
     b.`id`
	 ,b.`doc_Filename`
    ,b.`Description`
	 ,b.Op_Type
    ,a.`username` as `Affiliate`
    ,a.`id`       as `Affiliate_id`
	 ,LEFT(b.Creation_Date,16) AS `Exp_Date`
    ,FORMAT(ifnull(f.Amount_Debit,"0"),2) AS `Ammount`
    ,FORMAT(tba.Confirmed,2) AS `ConfBalance`
    ,ifnull(f.`Status`,"") AS `Action_Status_id`
    ,case ifnull(f.`Status`,"")
                  when "0" then "Pending"
                  when "1" then "Accepted"
                  when "2" then "Paid"
                  when "3" then "Blocked"
                  ELSE "Other"
     end as `ActionTaken`
    ,case when ifnull(f.`Status`,"") IN ("1","2","3")
      then left(f.`Last_Update`,16)
      end AS `Reviewed on`
    ,case when ifnull(f.`Status`,"") IN ("3")
      then f.Description
      ELSE ""
      end AS `Remarks`
    ,b.url_file 
    -- ,tba.Estimated
    -- ,tba.Confirmed
    -- ,tba.Confirmed21
    -- ,tba.Financial_Confirmed
FROM account_account_bills b
LEFT JOIN account_account            a ON b.Account_id=a.id
LEFT JOIN account_financial_movement f ON b.Financial_Movement_id=f.id
LEFT JOIN tmp_balance_by_affiliate tba ON b.Account_id=tba.Affiliate_id
WHERE 1=1 '
   ,v_whereop_type
   ,v_whereaffiliate_id
   ,v_wheremonth
,'),
Main_Table_Data_Filter as (
SELECT
     b.`id`
	,b.`doc_Filename`
    ,b.`Description`
	,b.Op_Type
    ,a.`username` as `Affiliate`
    ,a.`id`       as `Affiliate_id`
	,LEFT(b.Creation_Date,16) AS `Exp_Date`
    ,FORMAT(ifnull(f.Amount_Debit,"0"),2) AS `Ammount`
    -- ,FORMAT(tba.Confirmed,2) AS `ConfBalance`
    ,ifnull(f.`Status`,"") AS `Action_Status_id`
    ,case ifnull(f.`Status`,"")
                  when "0" then "Pending"
                  when "1" then "Accepted"
                  when "2" then "Paid"
                  when "3" then "Blocked"
                  ELSE "Other"
     end as `ActionTaken`
    ,case when ifnull(f.`Status`,"") IN ("1","2","3")
      then left(f.`Last_Update`,16)
      end AS `Reviewed on`
    ,case when ifnull(f.`Status`,"") IN ("3")
      then f.Description
      ELSE ""
      end AS `Remarks`
    ,b.url_file 
    -- ,tba.Estimated
    -- ,tba.Confirmed
    -- ,tba.Confirmed21
    -- ,tba.Financial_Confirmed
FROM account_account_bills b
LEFT JOIN account_account            a ON b.Account_id=a.id
LEFT JOIN account_financial_movement f ON b.Financial_Movement_id=f.id
-- LEFT JOIN tmp_balance_by_affiliate tba ON b.Account_id=tba.Affiliate_id
WHERE 1=1 '
   ,v_whereop_type
   ,v_whereaffiliate_id
   ,v_wheremonth
,')
');

SET v_col_affiliate     = IF(v_mode="GESTOR","width=150px","omit=yes");
SET v_col_amount        = IF(v_op_type="Withdraw" OR v_mode="AFFILIATE","width=100px,right=yes","omit=yes");
SET v_col_confbalance   = IF(v_op_type="Withdraw" OR v_mode="AFFILIATE","width=100px,right=yes","omit=yes");
SET v_col_action_status = "omit=yes";
SET v_col_action_taken  = IF(v_op_type="Withdraw" OR v_mode="AFFILIATE","width=100px,colorBg=[Pending:orange;Accepted:green;Paid:green;Blocked:red;Other:orange]","omit=yes");
SET v_col_reviewed_on   = IF(v_op_type="Withdraw" OR v_mode="AFFILIATE","width=130px","omit=yes");
SET v_col_remarks       = IF(v_op_type="Withdraw" OR v_mode="AFFILIATE","width=300px,tooltip=yes","omit=yes");

IF v_meta="YES" THEN
    SET v_sqlmeta=CONCAT(
    '(
    SELECT
         "setting"                              as Meta
        ,"width=90px,action=2,center=yes"       as `action`
        ,"omit=yes"                             as `id`
        ,"width=250px,tooltip=yes"              as `Name`
        ,"width=250px,tooltip=yes"              as `Description`
        ,"width=100px"                          as `Op. Type`
        ,"',v_col_affiliate,'"                  as `Affiliate`
        ,"omit=yes"                             as `Affiliate_id`
        ,"width=140px"                          as `Date submitted`
        ,"',v_col_amount,'"                     as `Amount`
        ,"',v_col_confbalance,'"                as `Confirm. Balance today`
        ,"',v_col_action_status,'"              as `Action_Status_id`
        ,"',v_col_action_taken,'"               as `Action taken`
        ,"',v_col_reviewed_on,'"                as `Reviewed on`
        ,"',v_col_remarks,'"                    as `Remarks`
        ,"omit=yes"                             as `url`
    FROM DUAL)
    UNION ALL '
    );
ELSE
    SET v_sqlmeta='';
END IF;

SET v_cte=REPLACE(v_cte,"%%LMonth%%",v_lmonth);
SET v_cte=REPLACE(v_cte,"%%Date_confirm%%",v_date_confirm);

/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
IF  v_affiliate_group=6 OR v_masteraff_group=4 THEN
    SET v_cte=REPLACE(v_cte,"Snapshot_day_by_day_fact2","sub_Snapshot_day_by_day_fact3");
    SET v_cte=REPLACE(v_cte,"campaign_marketing_source","sub_campaign_marketing_source");
    SET v_cte=REPLACE(v_cte,"campaign_mkt_source_deal","sub_campaign_mkt_source_deal");
    SET v_cte=REPLACE(v_cte,"campaign_deal_affiliate","sub_campaign_deal_affiliate");
    SET v_cte=REPLACE(v_cte,"account_landing_pages","sub_account_landing_pages");
    SET v_cte=REPLACE(v_cte,"account_payment_methods","sub_account_payment_methods");
    SET v_cte=REPLACE(v_cte,"account_account_bills","sub_account_account_bills");
    SET v_cte=REPLACE(v_cte,"view_monthly_fact_aff4","sub_view_monthly_fact_aff4");
END IF;
/*---------------------------------------------------------------------------------*/

SET v_sql=CONCAT(
v_cte,
v_sqlmeta,
'
SELECT "data" as `Meta`
    ,"..." as `Action`
	,MT.*
FROM Main_Table_Data MT
WHERE 1=1 ',v_whereactiontaken,
'
ORDER BY `Date submitted` desc
;');

SET v_sqlfilters=CONCAT(
v_cte,'
(SELECT "03" as "Korder"
            ,"Affiliate" AS "Key"
                         ,`Affiliate` AS "Value"
                                          ,"Affiliate_id" AS `CallKey`
                                                         ,`Affiliate_id` AS "CallValue"
                                                                         ,COUNT(*) AS "Rows"
FROM Main_Table_Data_Filter GROUP BY `Affiliate_id`) union all
(SELECT "05","Action taken",`ActionTaken`,"ActionTaken",`ActionTaken`,COUNT(*) FROM Main_Table_Data_Filter MT GROUP BY MT.`ActionTaken`) union all
(SELECT "01","Month",LEFT(`Exp_Date`,7),"Month",LEFT(`Exp_Date`,7),COUNT(*) FROM Main_Table_Data_Filter MT GROUP BY LEFT(`Exp_Date`,7))
ORDER BY 1, case when `CallKey`="Month" then `CallValue` else "" end desc, 3
;');

-- Obtiene balances de afiliados para el mes actual
-- devuelve tabla temporal tmp_balance_by_affiliate
CALL  Report_balance_by_affiliate('tmptable=yes');

IF v_debug!="NO"   THEN SELECT v_sql;          END IF;
IF v_filters="YES" THEN SET v_sql=v_sqlfilters; END IF;
IF v_debug!="NO"   THEN SELECT v_sqlfilters;   END IF;

IF v_debug != "YES" THEN
    -- PREPARE en MySQL requiere variable de sesión (@), se usa como puente.
    SET @v_sql = v_sql;
	PREPARE stmt1 FROM @v_sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
    SET @v_sql = NULL;
END IF;

END$$
DELIMITER ;

/*
call Report_Documents('Mode=Gestor,filters=ye,debug=ye');        -- TODOS
call Report_Documents('Mode=Gestor,Affiliate_id=39,ActionTaken=ALL,debug=ye');
call Report_Documents('Mode=affiliate,Affiliate_id=334,debug=ye'); -- Aff normal
call Report_Documents('Mode=affiliate,Affiliate_id=834,debug=ye'); -- sub aff
call Report_Documents('Mode=MAF,debug=ye');                        -- ERROR falta Master Aff
call Report_Documents('Mode=MAF,MasterAff_id=440,debug=ye');       -- Master Aff
call Report_Documents('Mode=MAF,MasterAff_id=334,debug=ye');       -- ERROR no es Master Aff
call Report_Documents('Mode=affiliate,Affiliate_id=39,debug=ye');
call Report_Documents('Mode=Gestor,Affiliate_id=all,Op_Type=Withdraw,ActionTaken=ALL,debug=ye');
call Report_Documents('Mode=Gestor,Affiliate_id=334,Month=2024-10,debug=ye'); -- Filtro por mes específico
call Report_Documents('Mode=Gestor,filters=yes,Month=2024-10'); -- Ver filtros disponibles para octubre 2024
*/
