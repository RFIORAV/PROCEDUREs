/*
PROCEDURE_Aff_Commission_Last12months_v1.sql - Comisiones Afiliado ultimo año

Descripción:
  Procedimiento Aff_Commission_Last12months.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Affiliate_id    =[ALL | Affiliate_id ]. OPCIONAL. Default=ALL
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Aff_Commission_Last12months('affiliate_id=39 ');  -- aff
call Aff_Commission_Last12months('affiliate_id=829');  -- subaff
call Aff_Commission_Last12months('affiliate_id=440');  -- masteraff

10.08.2024 v1
30.08.2024        Karen: agrega columna para icono Brand
23.09.2024        RF: eliminado Action=2

*/

DROP PROCEDURE IF EXISTS Aff_Commission_Last12months;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Aff_Commission_Last12months`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'AFFILIATES - Report Commission Last year'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 30.08.2024';
SET @Affiliate_id    ='';
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

   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =      @v;  END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;
/* ------------------------------------------------------------------- */

-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

IF @Debug!="NO" THEN SELECT @Affiliate_id,@MultiCurrency,@Currency,@Debug,@Meta,InputCommLine; END IF;

/* ------------------------------------------------------------------- */
SET @Month00=LEFT(DATE_SUB(CURDATE(), INTERVAL  0 MONTH),7);
SET @Month01=LEFT(DATE_SUB(CURDATE(), INTERVAL  1 MONTH),7);
SET @Month02=LEFT(DATE_SUB(CURDATE(), INTERVAL  2 MONTH),7);
SET @Month03=LEFT(DATE_SUB(CURDATE(), INTERVAL  3 MONTH),7);
SET @Month04=LEFT(DATE_SUB(CURDATE(), INTERVAL  4 MONTH),7);
SET @Month05=LEFT(DATE_SUB(CURDATE(), INTERVAL  5 MONTH),7);
SET @Month06=LEFT(DATE_SUB(CURDATE(), INTERVAL  6 MONTH),7);
SET @Month07=LEFT(DATE_SUB(CURDATE(), INTERVAL  7 MONTH),7);
SET @Month08=LEFT(DATE_SUB(CURDATE(), INTERVAL  8 MONTH),7);
SET @Month09=LEFT(DATE_SUB(CURDATE(), INTERVAL  9 MONTH),7);
SET @Month10=LEFT(DATE_SUB(CURDATE(), INTERVAL 10 MONTH),7);
SET @Month11=LEFT(DATE_SUB(CURDATE(), INTERVAL 11 MONTH),7);
/* ------------------------------------------------------------------- */

SET SESSION group_concat_max_len = 200000;

SET @SQL=CONCAT('
SELECT
    "data" `Meta`
   ,Affiliate_id
   ,Brand
   ,Currency                                                               as `Curr`
   ,FORMAT(SUM(net_Total_comm)                                         ,2) AS `Total`
   ,FORMAT(SUM(CASE WHEN Month=@Month00 THEN net_Total_comm ELSE 0 END),2) AS `',@Month00,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month01 THEN net_Total_comm ELSE 0 END),2) AS `',@Month01,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month02 THEN net_Total_comm ELSE 0 END),2) AS `',@Month02,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month03 THEN net_Total_comm ELSE 0 END),2) AS `',@Month03,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month04 THEN net_Total_comm ELSE 0 END),2) AS `',@Month04,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month05 THEN net_Total_comm ELSE 0 END),2) AS `',@Month05,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month06 THEN net_Total_comm ELSE 0 END),2) AS `',@Month06,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month07 THEN net_Total_comm ELSE 0 END),2) AS `',@Month07,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month08 THEN net_Total_comm ELSE 0 END),2) AS `',@Month08,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month09 THEN net_Total_comm ELSE 0 END),2) AS `',@Month09,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month10 THEN net_Total_comm ELSE 0 END),2) AS `',@Month10,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month11 THEN net_Total_comm ELSE 0 END),2) AS `',@Month11,'`
FROM monthly_comms_affiliate_v5
WHERE Month>=@Month11 and Affiliate_id=@Affiliate_id
GROUP BY Affiliate_id,Brand,Currency

UNION ALL

SELECT
    "total" `Meta`
   ,Affiliate_id
   ,"____Total____"                                                        as `tot`
   ,Currency                                                               as `Curr`
   ,FORMAT(SUM(net_Total_comm)                                         ,2) AS `Total`
   ,FORMAT(SUM(CASE WHEN Month=@Month00 THEN net_Total_comm ELSE 0 END),2) AS `',@Month00,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month01 THEN net_Total_comm ELSE 0 END),2) AS `',@Month01,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month02 THEN net_Total_comm ELSE 0 END),2) AS `',@Month02,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month03 THEN net_Total_comm ELSE 0 END),2) AS `',@Month03,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month04 THEN net_Total_comm ELSE 0 END),2) AS `',@Month04,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month05 THEN net_Total_comm ELSE 0 END),2) AS `',@Month05,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month06 THEN net_Total_comm ELSE 0 END),2) AS `',@Month06,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month07 THEN net_Total_comm ELSE 0 END),2) AS `',@Month07,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month08 THEN net_Total_comm ELSE 0 END),2) AS `',@Month08,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month09 THEN net_Total_comm ELSE 0 END),2) AS `',@Month09,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month10 THEN net_Total_comm ELSE 0 END),2) AS `',@Month10,'`
   ,FORMAT(SUM(CASE WHEN Month=@Month11 THEN net_Total_comm ELSE 0 END),2) AS `',@Month11,'`
FROM monthly_comms_affiliate_v5
WHERE Month>=@Month11 and Affiliate_id=@Affiliate_id
GROUP BY Affiliate_id,Currency

UNION ALL

SELECT
   "setting" `Meta`
   ,"omit=true"
   -- ,"width=120px,Action=2" -- 27.08.2024
   ,"width=120px"             -- 23.09.2024
   ,"width=080px"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
   ,"width=090px,right=true"
FROM DUAL WHERE @Meta="YES"

ORDER BY Affiliate_id,Brand,Curr
;');

SET @SQLfilters=CONCAT(
'
(SELECT "01" as "Korder"
            ,"Affiliate" AS "Key"
                         ,`Affiliate` AS "Value"
                                          ,"Affiliate_id" AS `CallKey`
                                                         ,`Affiliate_id` AS "CallValue"
                                                                         ,COUNT(*) AS "Rows"
FROM monthly_comms_affiliate_v5
WHERE Month>=@Month11
GROUP BY Affiliate_id
)
ORDER BY 1,3
;');

IF @Debug!="NO"   THEN SELECT @SQL;          END IF;
IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;
IF @Debug!="NO"   THEN SELECT @SQLfilters;   END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Aff_Commission_Last12months('affiliate_id=39 ,filters=ye,debug=ye');
call Aff_Commission_Last12months('affiliate_id=827,debug=ye');
call Aff_Commission_Last12months('affiliate_id=440,debug=ye');

*/