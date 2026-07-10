/* PROCEDURE_Sync_MS_Fact1_Fact2_lm.sql - LM Sincroniza una o todas las MS de Fact1 con Fact2


Descripción:
  Procedimiento Sync_MS_Fact1_Fact2_lm.
Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

MS_id           =[ALL | id de la MS]. OBLIGATORIO. Default=''.
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. [Yes] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Sync_MS_Fact1_Fact2_lm(1361);
call Sync_MS_Fact1_Fact2_lm('1574');
call Sync_MS_Fact1_Fact2_lm('AllAll');
call Compare_Fact1_Fact2_lm();

Modificaciones:

21.09.2022 V1   Sincroniza una Marketing Source entre Snapshot_day_by_day_fact1 y _fact2
08.11.2022 V1.1 MS_id_PROC="AllAll" Sync todo
10.04.2023 V1.2 Karen. Incluye manejo standard de parámetros de entrada
29.08.2023      Fix
06.01.2024 v1.3 INVOCA Sync_Fact2_from_Fact1
   
*/
DROP PROCEDURE IF EXISTS Sync_MS_Fact1_Fact2_lm;

DELIMITER $$
CREATE PROCEDURE Sync_MS_Fact1_Fact2_lm (IN
   InputCommLine    VARCHAR(250)
   )
   COMMENT 'Sync Fact2 with Fact1 (Last Mont) one MS at a time (Parameter: MS_id)'
   LANGUAGE SQL

proc_label:BEGIN

SET @Version         ='v1.3 06.01.2024';
SET @MS_id_PROC    	='';
SET @MS_id     	   ='';
SET @Debug		      ='NO';
SET @Meta            ='YES';
SET @Action          ='RUN';

SET @InputCommLine=Concat(InputCommLine ,',');      
SET @InputCommLine=replace(@InputCommLine,'"','');
  
IF  @Debug!="NO" THEN SELECT @InputCommLine; END IF;

WHILE @InputCommLine>' ' DO

   SET @e=INSTR(@InputCommLine,'=');    				   
   SET @c=INSTR(@InputCommLine,','); 					   
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);   

   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='ms_id'           THEN SET @MS_id_PROC    =UPPER(@v); END IF; 
   IF lower(@k)='ms_id'           THEN SET @MS_id         =UPPER(@v); END IF; 
	IF lower(@k)='action'          THEN SET @Action        =UPPER(@v); END IF; 	
   
END WHILE;

/* Termina la ejecución inmediatamente:
   - Si no es Action=RUN
   - Si MS_id_PROC está vacío
*/
IF @MS_id=''
THEN LEAVE proc_label;
END IF;     

/*** CALL A PROCESO UNIFICADO SYNC F1/F2 **/

SET @Parameters=Concat("CALL Sync_Fact2_from_Fact1('month=LM,MS_id=",@MS_id,",mode=",@Action,",debug=",@Debug,"')");

IF  @Debug!="NO" THEN SELECT @Parameters,@MS_id,@Action,@Debug; END IF;


PREPARE stmt1xx FROM @Parameters;
EXECUTE stmt1xx;
DEALLOCATE PREPARE stmt1xx;

/*
SET @LastMonth=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7);
SET @Where_MS_id=CONCAT('LEFT(DATE,7)="',@LastMonth,'" AND MS_id=',@MS_id);

SET @SQLdelete=CONCAT('DELETE FROM Snapshot_day_by_day_fact2 WHERE '
    ,IF(@MS_id="AllAll","1=1",@Where_MS_id));

IF  @Debug!="NO" THEN SELECT @LastMonth,@MS_id,@MS_id,@Where_MS_id; END IF;

SET @SQLinsert=CONCAT('
INSERT IGNORE INTO Snapshot_day_by_day_fact2 (
   `id`,`Owner`,`Affiliate`,`Affiliate_id`,`Deal_Aff`,`Date`,`Username`,`Username_id`,`Brand`
   ,`Advertiser_id`,`Tracker_ID`,`MS_id`,`Tracker_Name`,`Code_To_Affiliate`,`Product`,`Product_Real`
   ,`Qualified_Players`,`Qualified_Players_Adjusted`,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`
   ,`Impressions`,`Sign_Up_Offer`,`Type`,`Language`,`Deposits`,`Depositing_Customers`,`Active_Customers`
   ,`New_Depositing_Customers`,`New_Active_Customers`,`First_Time_Active_Customers`,`Turnover`,`Net_Revenue`
   ,`CPA_Limit`,`Channel_id`,`Channel`,`Revenue_Share_Affiliate`,`CPA_Value_Affiliate`,`Deal_Aff_id`
   ,`Deal_Aff_CPA`,`Deal_Aff_Carry_Over`,`Deal_Aff_RS_Against_CPA`,`Deal_Aff_RS_Base`,`Deal_Aff_RS`
   ,`Deal_Aff_Valid_From`,`Data_Currency`,`TimeGen`
) 
SELECT
   id,Owner,Affiliate,Affiliate_id,Deal_Aff,Date,Username,Username_id,Brand
   ,Advertiser_id,Tracker_ID,MS_id,Tracker_Name,Code_To_Affiliate,Product,Product_Real
   ,sum(Qualified_Players) AS Qualified_Players,sum(Qualified_Players_Adjusted) AS Qualified_Players_Adjusted,sum(First_Time_Deposit) AS First_Time_Deposit,sum(Views) AS Views,sum(Clicks) AS Clicks,sum(Signups) AS Signups
   ,sum(Impressions) AS Impressions,Sign_Up_Offer,Type,Language,sum(Deposits) AS Deposits,sum(Depositing_Customers) AS Depositing_Customers,sum(Active_Customers) AS Active_Customers
   ,sum(New_Depositing_Customers) AS New_Depositing_Customers,sum(New_Active_Customers) AS New_Active_Customers,sum(First_Time_Active_Customers) AS First_Time_Active_Customers,sum(Turnover) AS Turnover,sum(Net_Revenue) AS Net_Revenue
   ,CPA_Limit,Channel_id,Channel,sum(Revenue_Share_Affiliate) AS Revenue_Share_Affiliate,sum(CPA_Value_Affiliate) AS CPA_Value_Affiliate,Deal_Aff_id
   ,Deal_Aff_CPA,Deal_Aff_Carry_Over,Deal_Aff_RS_Against_CPA,Deal_Aff_RS_Base,Deal_Aff_RS
   ,Deal_Aff_Valid_From,Data_Currency,TimeGen
FROM Snapshot_day_by_day_fact1
WHERE ',IF(@MS_id="AllAll","1=1",@Where_MS_id),'
-- GROUP BY Owner,Date,Affiliate_id,MS_id -- ,Tracker_ID,Tracker_Name,Deal_Aff_CPA,Deal_Aff_RS
GROUP BY Owner,Date,Affiliate_id,ifnull(MS_id,0),Tracker_ID,Tracker_Name,Deal_Aff_CPA,Deal_Aff_RS
	HAVING 
      sum(Qualified_Players)<>0 OR 
      (SUM(`Net_Revenue`)<>0 and Deal_Aff_RS>0) OR
      sum(First_Time_Deposit)<>0 OR 
      sum(Views)<>0 OR 
      sum(Clicks)<>0 OR 
      sum(Signups)<>0 OR 
      sum(Impressions)<>0
;');
 
IF @Debug!="NO" THEN SELECT @SQLdelete; END IF;
IF @Debug!="NO" THEN SELECT @SQLinsert; END IF;

IF @Debug!="YES" THEN
	PREPARE stmt1 FROM @SQLdelete;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
   PREPARE stmt1 FROM @SQLinsert;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;
*/

END$$
DELIMITER ;

/*
call Sync_MS_Fact1_Fact2_lm("ms_id=2187,debug=ye");
call Sync_MS_Fact1_Fact2_lm('ms_id=1574,debug=non');
call Sync_MS_Fact1_Fact2_lm('ms_id=AllAll,debug=non');

-- call Compare_Fact1_Fact2_lm('action=view,debug=non');

*/