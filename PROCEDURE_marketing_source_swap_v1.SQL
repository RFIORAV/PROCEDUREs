/* PROCEDURE_marketing_source_swap.SQL - Swapping a un Afiliado de una MS por otra equivalente


Descripción:
  Procedimiento marketing_source_swap.
Keys:

Affiliate_id    =[id del Affiliate_id]. OBIGATORIO.
Date            =[AAAA-MM-DD]. OPCIONAL. Default=Current Date
MS_id           =[MS_id]. MS que será reemplazada. OBIGATORIO. Debe existir y pertenecer a Affiliate_id
MS_id_swap      =[MS_id]. MS de reemplazo. OBIGATORIO. Debe existir.
Brand           =[Brand]. Nombre de la Brand/advertiser. OBIGATORIO. Ambas MS deben tener el mismo Brand

Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Parámetros ('[Key=Value[,...]'])

Ejemplos:

marketing_source_swap(' ');                                   -- ERROR Sin Affiliate_id
marketing_source_swap('Affiliate_id=ALL,MS_id=1234');         -- ERROR Affiliate_id=ALL
marketing_source_swap('Affiliate_id=39,Brand=ALL,Month=LM');  -- OK
marketing_source_swap('Brand=ALL,Month=LM');                  -- ERROR Affiliate_id=""

05.07.2024 v1     Swapping de una MS por otra equivalente

*/

DROP PROCEDURE IF EXISTS marketing_source_swap;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE marketing_source_swap(
   InputCommLine    VARCHAR(250)
)
   COMMENT 'Swapping de una MS por otra equivalente'
   LANGUAGE SQL

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v1 05.07.2024';
SET @Date         =CURDATE();
SET @Affiliate_id ='';
SET @MS_id        ='';
SET @MS_id_swap   ='';
SET @Brand        ='';

SET @Meta         ='YES';
SET @Debug        ='NO';
SET @Filters      ='NO';                

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas


WHILE @InputCommLine>' ' DO
-- @InputCommLine: Month=2022-08,ByAccount=yes,OrderBy=Profit
-- @InputCommLine: ----5----0----5----0----5----0----5----0--
   SET @e=INSTR(@InputCommLine,'=');    				   -- 6
   SET @c=INSTR(@InputCommLine,','); 					   -- 14
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   -- Month
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	-- 2022-08
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);   

   IF lower(@k)='affiliate_id'  THEN SET @Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='brand'         THEN SET @Brand        =UPPER(@v); END IF;
   IF lower(@k)='date'          THEN SET @Date         =UPPER(@v); END IF;
   IF lower(@k)='ms_id'         THEN SET @MS_id        =UPPER(@v); END IF;
   IF lower(@k)='ms_id_swap'    THEN SET @MS_id_swap   =UPPER(@v); END IF;
   
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;   
   IF lower(@k)='mode'          THEN SET @Mode         =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Affiliate_id,@Brand,@Date,@MS_id,@MS_id_swap,@Debug,InputCommLine; END IF;

/************ VALIDACION PARAMETROS ************************************************/

-- @Affiliate_id obligatorio
IF   @Affiliate_id="" THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

-- @Affiliate_id obligatorio
IF   @MS_id="" or  @MS_id_swap="" or @Brand=""
THEN
    Select 'data' as Meta,'MS_id, MS_id_swap, Brand= mandatory' as '' from dual;
    LEAVE proc_label;
END IF; 

--  MS_id no existe o no pertenece al afiliado
SET @Existe=0;
SET @Existe=(select count(*) from campaign_marketing_source where id=@MS_id and Affiliate_id=@Affiliate_id);
IF  @Existe=0 THEN
    Select 'data' as Meta,'MS_id - not exist or wrong affiliate' as '' from dual;
    LEAVE proc_label;
END IF; 

--  MS_id_swap no existe
SET @Existe=0;
SET @Existe=(select count(*) from campaign_marketing_source where id=@MS_id_swap);
IF  @Existe=0 THEN
    Select 'data' as Meta,'MS_id_swap - not exist' as '' from dual;
    LEAVE proc_label;
END IF; 
 
--  MS_id y MS_id_swap no son de la misma Brand
SET @Advertiser_Name1="";
SET @Advertiser_Name1=
   (select a.Advertiser_Name
    from campaign_marketing_source m
    inner join campaign_advertiser a on a.id=m.Advertiser_id
    where m.id=@MS_id);
SET @Advertiser_Name2="";
SET @Advertiser_Name2=
   (select a.Advertiser_Name
    from campaign_marketing_source m
    inner join campaign_advertiser a on a.id=m.Advertiser_id
    where m.id=@MS_id_swap);

IF  @Brand!=@Advertiser_Name1 or @Brand!=@Advertiser_Name2 THEN
    Select 'data' as Meta,'MS_id/MS_id_swap - not the same brand' as '' from dual;
    LEAVE proc_label;
END IF; 


-- Pasa MS_swap a Affiliate_id       
/** ESTE UPDATE DEBE HACERSE ANTES DEL OTRO **/
UPDATE `campaign_marketing_source` Sw
LEFT JOIN `campaign_marketing_source` MS on MS.id=@MS_id
SET Sw.`Affiliate_id`      =MS.`Affiliate_id`
   ,Sw.`Deal_Valid_From`   =@Date
   ,Sw.`Channel_id`        =MS.`Channel_id`
   ,Sw.`Code_To_Affiliate` =MS.`Code_To_Affiliate`
   ,Sw.`Deal_id`           =MS.`Deal_id`
   ,Sw.`Country_Deal`      =MS.`Country_Deal`
   ,Sw.`Product_Deal`      =(case when MS.`Product_Deal`="any" then "" else MS.`Product_Deal` END)
   ,Sw.`Status_id`         =MS.`Status_id`
   ,Sw.`Shortlink`         =MS.`Shortlink`
   ,Sw.`Shortlink_id`      =MS.`Shortlink_id`
WHERE Sw.id = @MS_id_swap
;

-- Pasa MS actual a Afiliado Aff_Swap       
UPDATE `campaign_marketing_source` MS
LEFT JOIN `campaign_marketing_source` Sw on Sw.id=@MS_id_swap
SET MS.`Affiliate_id`=300 
   ,MS.`Deal_Valid_From`=@Date
   ,MS.`Channel_id`=400
   ,MS.`Shortlink_id`=CONCAT("old: ",MS.`Shortlink_id`)
   ,MS.`Product_Deal`=(case when Sw.`Product_Deal`="any" then "" else Sw.`Product_Deal` END)
WHERE MS.id = @MS_id
;


END$$
DELIMITER ;

/*
-- TEST --------------
call marketing_source_swap('');  -- error
call marketing_source_swap('Affiliate_id=540,MS_id=3401,MS_id_swap=4233,Date=2024-07-10,Brand=sportingbet,debug=yes');  -- error
call marketing_source_swap('Affiliate_id=540,MS_id=3408,MS_id_swap=42330,Date=2024-07-10,Brand=sportingbet,debug=yes'); -- error 
call marketing_source_swap('Affiliate_id=540,MS_id=3408,MS_id_swap=4233,Date=2024-07-10,Brand=sportingbet,debug=yes'); 

call marketing_source_swap('Affiliate_id=540,MS_id=3408,MS_id_swap=4224,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3409,MS_id_swap=4225,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3410,MS_id_swap=4226,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3411,MS_id_swap=4227,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3494,MS_id_swap=4228,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3796,MS_id_swap=4229,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=3925,MS_id_swap=4230,Brand=sportingbet,debug=yes');
call marketing_source_swap('Affiliate_id=540,MS_id=4036,MS_id_swap=4231,Brand=sportingbet,debug=yes');

*/