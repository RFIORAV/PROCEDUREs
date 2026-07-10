/*
PROCEDURE_Report_Documents.sql - Reports Invoices uploaded by Affiliates

Descripción:
  Procedimiento Report_invoices_aff.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

mode             =[ GESTOR | AFFILIATE | MAF ] OBLIGATORIO. 
MasterAff_id     =[ MasterAff_id ]. SOLO PARA MAF EN MODO MAF. Default=''
Affiliate_id     =[id de affiliate]
Op_Type          =[ Withdraw | "" ] Tipo de documento. Default='Withdraw'
Month            =[YYYY-MM]. Filtro por mes en formato YYYY-MM. Filtra registros de account_account_bills por Creation_Date. OPCIONAL. Default=''
ActionTaken      =[ "ALL" | "Pending" | "Accepted" | "Paid" | "Blocked" | "Other" ] Status de la operación en account_financial_movement. Default=ALL 
Filters          =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta             =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug            =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_invoices_aff('Mode=Gestor,filters=yes,debug=yes');         -- TODOS
call Report_invoices_aff('Mode=Gestor,filters=yes,month=2025-07,debug=ye');
call Report_invoices_aff('Mode=Gestor,Affiliate_id=334');


10.10.2023 V1     Karen. Primera versión operativa
01.02.2024 V2     Karen. Se agregó "Op Type" y "Financial_Movement_id"
27.03.2024 v2.1   RF. Cambios en la presentación del grid (RS)
09.04.2024 v2.2   RR. Muestra Confirmed y Estimated Balance
27.05.2024 v2.3   Tratamiento de Subafiliados
                  Tratamiento de Master Affiliate
11.09.2024 v2.4   CALL PROCEDURE_Report_Documents Op_Type=Withdraw
22.09.2025 v2.5   Agregado parámetro Month para filtrar por mes en Creation_Date
02.03.2026 v2.6   Fix: eliminación de variables globales
                              
*/

DROP PROCEDURE IF EXISTS Report_invoices_aff;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_invoices_aff`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Report docs Invoices Affiliate'
    
proc_label:BEGIN
 
DECLARE v_Version         VARCHAR(30);
DECLARE v_CurrentDay      DATE;
DECLARE v_Affiliate_id    VARCHAR(100);
DECLARE v_MasterAff_id    VARCHAR(100);
DECLARE v_ActionTaken     VARCHAR(50);
DECLARE v_Op_Type         VARCHAR(50);
DECLARE v_Mode            VARCHAR(20);
DECLARE v_Debug           VARCHAR(20);
DECLARE v_Filters         VARCHAR(20);
DECLARE v_Meta            VARCHAR(20);
DECLARE v_Month           VARCHAR(20);
DECLARE v_InputCommLine   VARCHAR(500);
DECLARE v_e               INT;
DECLARE v_c               INT;
DECLARE v_k               VARCHAR(100);
DECLARE v_v               VARCHAR(255);
DECLARE v_CallParam       TEXT;

SET v_Version         ='v2.6 02.03.2026';
SET v_CurrentDay      =curdate();
SET v_Affiliate_id    ='';
SET v_MasterAff_id    ='';
SET v_ActionTaken     ='ALL';
SET v_Op_Type         ='Withdraw';
SET v_Mode            ='';
SET v_Debug           ='NO';
SET v_Filters         ='NO';
SET v_Meta            ='YES';
SET v_Month           ='';

-- --------------------------------------------------------------------------
SET v_InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET v_InputCommLine=replace(v_InputCommLine,' ','');  -- Elimina espacios
SET v_InputCommLine=replace(v_InputCommLine,'"','');  -- Elimina comillas

IF v_Debug!="NO" THEN SELECT v_InputCommLine; END IF;
-- IF v_Debug="YES" THEN SELECT v_Owner,v_Month,v_Currency,v_Advertiser_id,v_ByAccount,v_Debug,v_Total,v_TotLine,v_OrderBy,v_Order,v_InputCommLine; END IF;

WHILE v_InputCommLine>' ' DO
-- v_InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit,Product=Sport!-!Footbol,Filter=yes
-- v_InputCommLine: ----5----0----5----0----5----0----5----0----5----0----5----0----5----0----5----0
   SET v_e=INSTR(v_InputCommLine,'=');    				   -- 6
   SET v_c=INSTR(v_InputCommLine,','); 					   -- 14
   SET v_k=SUBSTRING(v_InputCommLine,1,v_e-1); 			   -- Month
   SET v_v=SUBSTRING(v_InputCommLine,v_e+1,v_c-(v_e+1)); 	-- 2022-08
   SET v_InputCommLine=SUBSTRING(v_InputCommLine,v_c+1);
   SET v_k=TRIM(v_k);
   SET v_v=TRIM(v_v);

   IF lower(v_k)='affiliate_id'    THEN SET v_Affiliate_id  =      v_v;  END IF;
   IF lower(v_k)='masteraff_id'    THEN SET v_MasterAff_id  =      v_v;  END IF;
   IF lower(v_k)='actiontaken'     THEN SET v_ActionTaken   =      v_v;  END IF;
   IF lower(v_k)='op_type'         THEN SET v_Op_Type       =      v_v;  END IF;
	IF lower(v_k)='mode'            THEN SET v_Mode          =UPPER(v_v); END IF;
   IF lower(v_k)='meta'            THEN SET v_Meta          =UPPER(v_v); END IF;
   IF lower(v_k)='filters'         THEN SET v_Filters       =UPPER(v_v); END IF;   
   IF lower(v_k)='debug'           THEN SET v_Debug         =UPPER(v_v); END IF;
   IF lower(v_k)='month'           THEN SET v_Month         =      v_v;  END IF;
 
END WHILE;
-- --------------------------------------------------------------------------
IF v_Debug!="NO" THEN SELECT v_Mode,v_MasterAff_id,v_Affiliate_id,v_ActionTaken,v_Op_Type,v_Debug,v_Filters,v_Meta,InputCommLine; END IF;

SET v_CallParam="Op_Type=Withdraw";
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Affiliate_id!="" AND UPPER(v_Affiliate_id)!="ALL",CONCAT("affiliate_id=",v_Affiliate_id),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_MasterAff_id!="",CONCAT("MasterAff_id=",v_MasterAff_id),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_ActionTaken!="",CONCAT("ActionTaken=",v_ActionTaken),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Month!="",CONCAT("Month=",v_Month),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Mode!="",CONCAT("Mode=",v_Mode),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Meta!="",CONCAT("Meta=",v_Meta),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Filters!="",CONCAT("Filters=",v_Filters),""));
SET v_CallParam=CONCAT(v_CallParam,",",IF(v_Debug!="",CONCAT("Debug=",v_Debug),""));


SET v_CallParam=REPLACE(v_CallParam,',,',',');
SET v_CallParam=REPLACE(v_CallParam,',,',',');

IF v_Debug!="NO" THEN SELECT v_CallParam; END IF;

CALL Report_Documents(v_CallParam);

END$$
DELIMITER ;

/*
call Report_invoices_aff('Mode=Gestor,filters=yes,debug=ye');         -- TODOS
call Report_invoices_aff('Mode=Gestor,Affiliate_id=39,ActionTaken=paid,debug=ye');     
call Report_invoices_aff('Mode=affiliate,Affiliate_id=334,debug=ye'); -- Aff normal
call Report_invoices_aff('Mode=affiliate,Affiliate_id=834,debug=ye'); -- sub aff
call Report_invoices_aff('Mode=MAF,debug=ye');                        -- ERROR falta Master Aff
call Report_invoices_aff('Mode=MAF,MasterAff_id=440,debug=ye');       -- Master Aff
call Report_invoices_aff('Mode=MAF,MasterAff_id=334,debug=ye');       -- ERROR no es Master Aff
*/

