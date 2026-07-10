/*
PROCEDURE_HandleEditOperation_v1.sql - Maneja ediciones de grillas

Descripción:
  Procedimiento HandleEditOperation.

Observaciones:
Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value debe estar seguido por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada

Keys:
PRCorigen   =[nombre del procedure que invoca]
<Campo>     =[valor anterior]  (primera ocurrencia)
<Campo>     =[valor nuevo]     (segunda ocurrencia)
Debug       =[No | Yes]. OPCIONAL. Default=No
InputCommLine = [valor]. Parámetro de entrada.

Ejemplo:
call HandleEditOperation('PRCorigen=FM_edit_info_fact1,Clicks=13,Clicks=2,Date=2026-02-01,MS_id=4680')

call HandleEditOperation('PRCorigen=FM_edit_info_fact1
   ,Date=2026-01-15
   ,MS_id=5730
   ,Qualified_Players_Adjusted=10,Qualified_Players_Adjusted=8
   ,First_Time_Deposit=10,First_Time_Deposit=8
   ,Signups=8,Signups=6
   ,Net_Revenue=100,Net_Revenue=80
   ,Clicks=200,Clicks=80
   ,Deposits=110,Deposits=85
   ,debug=ye');

26.01.2026 v1  Primera versión
*/

DROP PROCEDURE IF EXISTS HandleEditOperation;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `HandleEditOperation`(IN
   InputCommLine    VARCHAR(2000)
   )
   COMMENT 'Procesa parámetros de edición (old/new) y debug'
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version     ='v1 26.01.2026';
SET @PRCorigen   ='';
SET @Date        ='';
SET @MS_id       ='';
SET @Debug       ='NO';

SET @InputCommLineOrig=InputCommLine; 
SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

DROP TEMPORARY TABLE IF EXISTS tmp_HandleEditOperation_params;
CREATE TEMPORARY TABLE tmp_HandleEditOperation_params (
   ParamName  VARCHAR(256) NOT NULL PRIMARY KEY,
   OldValue   TEXT,
   NewValue   TEXT,
   Occur      INT NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS `tmp_HandleEditCall_params` (
   `ParamName` TEXT NOT NULL,
   `OldValue` TEXT NULL DEFAULT NULL,
   `NewValue` TEXT NULL DEFAULT NULL,
   `Occur` INT NOT NULL DEFAULT '0',
   `DiffValue` TEXT NULL DEFAULT NULL
);
TRUNCATE TABLE tmp_HandleEditCall_params;
insert into tmp_HandleEditCall_params (ParamName,OldValue) values ("omit",@InputCommLineOrig);
-- Procesamiento de parámetros de entrada
WHILE @InputCommLine>' ' DO
   -- Extracción de key=value
   SET @e=INSTR(@InputCommLine,'=');
   SET @c=INSTR(@InputCommLine,',');
   SET @k=SUBSTRING(@InputCommLine,1,@e-1);
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1));
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   -- Asignación de valores especiales
   IF lower(@k)='prcorigen' THEN SET @PRCorigen = @v; END IF;
   IF lower(@k)='debug'     THEN SET @Debug    = UPPER(@v); END IF;
   IF lower(@k)='date'      THEN SET @Date     = UPPER(@v); END IF;
   IF lower(@k)='ms_id'     THEN SET @MS_id    = UPPER(@v); END IF;
   IF lower(@k)='country'   THEN SET @Country  = UPPER(@v); END IF;
   -- Procesamiento de parámetros old/new (pares con mismo nombre)
   IF lower(@k)!='prcorigen' AND lower(@k)!='debug' AND @k!='' THEN
      IF (SELECT COUNT(*) FROM tmp_HandleEditOperation_params WHERE ParamName=@k)=0 THEN
         INSERT INTO tmp_HandleEditOperation_params (ParamName, OldValue, NewValue, Occur)
         VALUES (@k, @v, NULL, 1);
      ELSE
         UPDATE tmp_HandleEditOperation_params
            SET NewValue=@v,
                Occur=Occur+1
          WHERE ParamName=@k;
      END IF;
   END IF;
END WHILE;

-- Debug: mostrar valores procesados
IF @Debug!="NO" THEN SELECT @PRCorigen AS PRCorigen; end if;

INSERT INTO tmp_HandleEditCall_params
   SELECT ParamName,
      OldValue,
      NewValue,
      Occur,
      CASE
         WHEN Occur=1 THEN OldValue
         WHEN OldValue REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
          AND NewValue REGEXP '^-?[0-9]+(\\.[0-9]+)?$'
         THEN REPLACE(
                FORMAT(
                   CAST(NewValue AS DECIMAL(30,10)) - CAST(OldValue AS DECIMAL(30,10)),
                   GREATEST(
                      CASE WHEN INSTR(OldValue,'.')>0 THEN LENGTH(SUBSTRING_INDEX(OldValue,'.',-1)) ELSE 0 END,
                      CASE WHEN INSTR(NewValue,'.')>0 THEN LENGTH(SUBSTRING_INDEX(NewValue,'.',-1)) ELSE 0 END
                   )
                ),
                ',',''
              )
         ELSE NewValue
      END AS DiffValue
   FROM tmp_HandleEditOperation_params
   ORDER BY ParamName;
-- END IF;

-- CALL Set_record_dbd_manual ('is_active=2,deal_to_apply=1,MS_id=5722,date=2026-01-03,Qualified_Players=-1,debug=yes');

SELECT CONCAT('is_active=2,deal_to_apply=1,',GROUP_CONCAT(CONCAT(ParamName, '=', IFNULL(DiffValue, 'NULL')) ORDER BY ParamName SEPARATOR ', '))
INTO @parametros
FROM tmp_HandleEditCall_params where ParamName!="omit" and DiffValue is not null;

CALL Set_record_dbd_manual (REPLACE(@parametros,"Qualified_Players_Adjusted","Qualified_Players"));

IF @Debug!="NO" THEN
   Select @parametros; 
   insert into tmp_HandleEditCall_params (ParamName) values (@parametros);
END IF;

END$$
DELIMITER ;

/*
call HandleEditOperation('PRCorigen=FM_edit_info_fact1
   ,Date=2026-01-15
   ,MS_id=5729
   ,Qualified_Players_Adjusted=10,Qualified_Players_Adjusted=8
   ,First_Time_Deposit=10,First_Time_Deposit=8
   ,Signups=8,Signups=6
   ,Net_Revenue=100,Net_Revenue=80
   ,Clicks=200,Clicks=80
   ,Deposits=110,Deposits=85
   ,Country=IT,Country=ES
   ,debug=ye');
*/