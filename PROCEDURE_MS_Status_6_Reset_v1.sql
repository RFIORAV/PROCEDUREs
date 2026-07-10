/*
PROCEDURE_MS_Status_6_Reset_v1.sql - MS_Status 6 (Paused until Next Month) Reset

Descripción:
  Procedimiento MS_Status_6_Reset.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call MS_Status_6_Reset('debug=YES');

18.03.2024 v1  
*/

DROP PROCEDURE IF EXISTS MS_Status_6_Reset;

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `MS_Status_6_Reset`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'MS_Status 6 (Paused until Next Month) Reset'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 18.03.2024';

SET @Month           =LEFT(CURDATE(),7);
SET @Debug           ='NO';

SET @Meta            ='NO';
SET @Filters         ='NO';
SET @Affiliate_id    ='ALL';
SET @Channel_id      ='ALL';
SET @DealbyProduct   ='NO';
 
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

   IF lower(@k)='affiliate_id'    THEN SET @Affiliate_id  =UPPER(@v); END IF;
   IF lower(@k)='channel_id'      THEN SET @Channel_id    =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   -- IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='mode'            THEN SET @Mode          =UPPER(@v); END IF;
   IF lower(@k)='month'           THEN SET @Month         =UPPER(@v); END IF;
   IF lower(@k)='view'            THEN SET @View          =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Debug,@Meta,InputCommLine; END IF;

/**************************************************************************************************************/

SET SESSION group_concat_max_len = 200000;

-- ----------------------------------------------------------------
-- 01.06.2023 --
-- REHABILITACION MS PAUSED POR CAP A COMIENZO DE MES SIGUIENTE ---
-- ----------------------------------------------------------------
IF @Debug!="NO" THEN
   SELECT * FROM account_account             WHERE Status_id='6';
   SELECT * FROM account_landing_pages       WHERE Status_id='6';
   SELECT * FROM campaign_publisher          WHERE Status_id='6';
   SELECT * FROM campaign_advertiser         WHERE Status_id='6';
   SELECT * FROM campaign_username           WHERE Status_id='6';
   SELECT * FROM campaign_marketing_source   WHERE Status_id='6' or Stat_aggreg='6';
ELSE
   UPDATE account_account           SET Status_id='1' WHERE Status_id='6';
   UPDATE account_landing_pages     SET Status_id='1' WHERE Status_id='6';
   UPDATE campaign_publisher        SET Status_id='1' WHERE Status_id='6';
   UPDATE campaign_advertiser       SET Status_id='1' WHERE Status_id='6';
   UPDATE campaign_username         SET Status_id='1' WHERE Status_id='6';
   UPDATE campaign_marketing_source SET Status_id='1' WHERE Status_id='6';
END IF;
-- ----------------------------------------------------------------
-- ----------------------------------------------------------------
/*
IF @Debug!="NO" THEN
   SELECT M.id AS "MS",M.Status_id,M.Stat_aggreg,M.NotUse_StatEf,M.Stat_Chan,M.Stat_Acct,M.Stat_effect
         ,M.Username_id    ,`CU`.`Status_id`  as `Status`
         ,M.Publisher_id   ,`AD`.`Status_id`  as `Status`
         ,M.Advertiser_id  ,`P`.`Status_id`   as `Status`
         ,M.Affiliate_id   ,`A`.`Status_id`   as `Status`
         ,M.Channel_id     ,`CH`.`Status_id`  as `Status`
         ,left(NOW(),16) as 'TimeGen'
   FROM campaign_marketing_source M  
   LEFT JOIN `campaign_username`       `CU`  ON `CU`.`id`   = M.Username_id
   LEFT JOIN `campaign_advertiser`     `AD`  ON `AD`.`id`   = CU.Advertiser_id
   LEFT JOIN `campaign_publisher`      `P`   ON `P`.`id`    = CU.Publisher_id
   LEFT JOIN `account_landing_pages`   `CH`  ON `CH`.`id`   = M.Channel_id
   LEFT JOIN `account_account`         `A`   ON `A`.`id`    = CH.Account_id
   WHERE M.Stat_aggreg='6';
ELSE
-- ---------------------------------------------------------------
-- SYNC STATUS MS
-- ---------------------------------------------------------------
UPDATE campaign_marketing_source M 
LEFT JOIN account_landing_pages L ON L.id=M.Channel_id
LEFT JOIN account_account 		  A ON A.id=M.Affiliate_id 
LEFT JOIN campaign_username     U ON U.id=M.Username_id
SET M.Stat_Chan=(case when L.`Stat_aggreg` IS null
						 	 then ifnull(A.`Status_id`,"1") 
						 	 else L.`Stat_aggreg` 
                      end)
   ,M.Stat_Acct=ifnull(U.`Stat_aggreg`,"1") 
   ,M.Stat_aggreg=(
      CASE  WHEN M.`Status_id`!='1'
            THEN M.`Status_id`
            ELSE 
                  CASE  WHEN ifnull(M.`Stat_Acct`,"1")!='1'
                        THEN ifnull(M.`Stat_Acct`,"1")
                        ELSE ifnull(M.`Stat_Chan`,"1")
                  END
      END)
   ,M.Stat_effect=(
      CASE M.Stat_aggreg
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)
   ,M.Status=(
      CASE M.Status_id
         WHEN '0' THEN 'Inactive'
         WHEN '1' THEN 'Active'
         WHEN '4' THEN 'Paused'
         WHEN '6' THEN 'Paused auto NM'
         ELSE 'Other'
      END)   
WHERE 1=1 AND NotUse_StatEf<>1;
END IF;
*/
-- -------------------------------------------------------------------
-- -------------------------------------------------------------------
END$$
DELIMITER ;

/*
call MS_Status_6_Reset('debug=YES');

*/
