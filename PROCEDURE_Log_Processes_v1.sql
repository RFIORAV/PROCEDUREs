/*
PROCEDURE_Log_Processes_v1.sql - log de procesos

Descripción:
  Procedimiento Log_Processes.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Comments        =[ any string ]. OPCIONAL. Default="" - NO UTILIZAR "=" DENTRO DE Comments
proc_origin     =[ any string ]. OPCIONAL. Default="" - NO UTILIZAR "=" DENTRO DE proc_origin
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Log_Processes('proc_origin=MS_Status_6_Reset,Comments=Reset de Status Paused NM,debug=YES');

18.03.2024 v1
*/

DROP PROCEDURE IF EXISTS Log_Processes;

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Log_Processes`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'Add records to table `Log_Processes`'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 20.03.2024';

SET @Month           =LEFT(CURDATE(),7);
SET @Timestamp       =NOW();
SET @Proc_origin     ='';
SET @Comments        ='';
SET @Debug           ='NO';


SET @InputCommLine=Concat(InputCommLine ,',');       -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,' ','!');  -- cambia espacios por signo !
SET @InputCommLine=replace(@InputCommLine,'"','!');  -- Elimina comillas

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

   IF lower(@k)='proc_origin'     THEN SET @Proc_origin   =UPPER(@v); END IF;
   IF lower(@k)='Comments'        THEN SET @Comments      =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

SET @Proc_origin=REPLACE(@Proc_origin,"!"," ");   -- cambia signo ! por espacios
SET @Comments   =REPLACE(@Comments,"!"," ");      -- cambia signo ! por espacios

IF @Debug!="NO" THEN SELECT @Debug,@Proc_origin,@Comments,InputCommLine; END IF;

/**************************************************************************************************************/
CREATE TABLE IF NOT EXISTS `log_processes` (
	`id` INT(10) NOT NULL AUTO_INCREMENT,
	`proc_origin`  VARCHAR(100) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
	`Comments`     VARCHAR(250) NULL DEFAULT NULL COLLATE 'utf8mb4_0900_ai_ci',
	`Creation_Date` DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`id`) USING BTREE
   )
ENGINE=InnoDB
;
/**************************************************************************************************************/

IF @Debug="NO" THEN
   INSERT INTO `log_processes` (`proc_origin`,`Comments`)
   VALUES (@Proc_origin,@Comments);
ELSE
   SELECT @Debug,@Proc_origin,@Comments;
END IF;

-- -------------------------------------------------------------------
END$$
DELIMITER ;

/*
call Log_Processes('proc_origin=MS_Status_6_Reset,Comments=Reset de Status Paused NM,debug=YES');

*/
