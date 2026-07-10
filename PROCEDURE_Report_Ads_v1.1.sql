/*
PROCEDURE_Report_Ads.sql - Report Ads

Descripción:
  Procedimiento Report_Ads.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Mode              =[Aff | Ges | Option]. Opcional. Asume "Aff"
Account_id        =[id de Account_id] Obligatorio para Aff. [Para Ges: Opcional. Default ALL}
Account           =[Account name] [Para Ges: Opcional. Default ALL}
Product           =[Product | blank] Obligatorio para Aff. [Para Ges: Opcional. Default ALL}
Brand             =[Brand | blank] Obligatorio para Aff. [Para Ges: Opcional. Default ALL}
Status_id         =[0 | 1] 1=Active/Other=Inactive. Opcional. Default ALL
Option            =[Brand | Account]
Expiration        =[Valid | Expired] Opcional. Default ALL
Excl_Ad_code      =[Ad_code]. Ad_code a excluir cuando se muestra Ads (normalmente es le Ad que ya tiene)

Filters           =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta              =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug             =[No | Yes | KeyValues]. OPCIONAL. Default=No
                   [No] NO EJECUTA QUERY y devuelve el código del Query.
                   [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Report_Ads('Account_id=490,Product=sport,Excl_Ad_code=1234,debug=ye');

23.02.2025 Primera versión operativa
27.05.2026 v1.1 Añadida opción colorBg=[Active:green;Inactive:red;Paused:orange;Paused auto NM:orange;Active *:green;Other *:red;Paused *:orange;Paused auto NM *:orange] a columna Status

*/

DROP PROCEDURE IF EXISTS Report_Ads;

DELIMITER $$

CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Ads`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.1 27.05.2026 - Report Ads Afiliates'

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.1 27.05.2026';
SET @CurrentDay      =curdate();
SET @Month           =left(curdate(),7);

SET @Mode            ='Aff'; -- Mode Aff/Ges
SET @Account_id      ='';
SET @Product         ='';
SET @Account         ='';
SET @Option          ='';
SET @Expiration      ='';
SET @Excl_Ad_code    ='';
SET @Status_id       ='';
SET @Brand           ='';

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

   IF lower(@k)='mode'            THEN SET @Mode          =UPPER(@v); END IF;
   IF lower(@k)='product'         THEN SET @Product       =UPPER(@v); END IF;
   IF lower(@k)='account'         THEN SET @Account       =UPPER(@v); END IF;
   IF lower(@k)='Option'          THEN SET @Option        =UPPER(@v); END IF;
   IF lower(@k)='account_id'      THEN SET @Account_id    =UPPER(@v); END IF;
   IF lower(@k)='brand'           THEN SET @Brand         =UPPER(@v); END IF;
   IF lower(@k)='status_id'       THEN SET @Status_id     =UPPER(@v); END IF;
   IF lower(@k)='expiration'      THEN SET @Expiration    =UPPER(@v); END IF;
   IF lower(@k)='excl_Ad_code'    THEN SET @Excl_Ad_code  =UPPER(@v); END IF;

   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;

END WHILE;

-- Recompone valor parámetros con ! en lugar de espacio
SET @Account=REPLACE(@Account,"!"," ");
SET @Brand  =REPLACE(@Brand,"!"," ");
-- ----------------------------------------------------

-- Valors default parámetros según @Mode--------------------
IF @Mode='Aff' THEN
   SET @Expiration      ='Valid';
   SET @Status_id       ='1';
ELSE
   IF  @Account_id ='' THEN SET @Account_id='ALL'; END IF;
   IF  @Account    ='' THEN SET @Account   ='ALL'; END IF;
   IF  @Product    ='' THEN SET @Product   ='ALL'; END IF;
   IF  @Expiration ='' THEN SET @Expiration='';    END IF;
   IF  @Brand      ='' THEN SET @Brand     ='ALL'; END IF;
   IF  @Status_id  ='' THEN SET @Status_id ='ALL'; END IF;
   IF  @Status_id NOT IN ('ALL','1') THEN SET @Status_id ='0'; END IF;
END IF;
-- --------------------------------------------------------

IF @Debug!="NO" THEN SELECT @Mode,@Status_id,@Account_id,@Account,@Brand,@Product,@Expiration,@Excl_Ad_code,@Option
                           ,@Filters,@Debug,@Meta,InputCommLine; END IF;

-- Valida datos obligatorios Mode Aff
IF @Mode="AFF" THEN
   IF   @Account_id IN ("","ALL") OR @Product IN ("","ALL")
   THEN
      Select 'data' as Meta,'Account_id/Product mandatory' as '' from dual;
      LEAVE proc_label;
   END IF;
END IF;

SET @WhereProduct='';
SET @WhereAccount_id='';
SET @WhereAccount='';
SET @WhereBrand='';
SET @WhereStatus='';
SET @WhereExpired='';

IF @Product       NOT IN ("","ALL") THEN SET @WhereProduct       =CONCAT(" AND a.`Product`      ='",@Product,"'");    END IF;
IF @Account_id    NOT IN ("","ALL") THEN SET @WhereAccount_id    =CONCAT(" AND a.`Account_id`   ='",@Account_id,"'"); END IF;
IF @Account       NOT IN ("","ALL") THEN SET @WhereAccount       =CONCAT(" AND a.`Account`      ='",@Account,"'");    END IF;
IF @Brand         NOT IN ("","ALL") THEN SET @WhereBrand         =CONCAT(" AND a.`Brand`        ='",@Brand,"'");      END IF;
IF @Status_id      ="1"   THEN SET @WhereStatus        =CONCAT(" AND a.`Status_id`    ='1'");               END IF;
IF @Status_id      ="0"   THEN SET @WhereStatus        =CONCAT(" AND a.`Status_id`   !='1'");               END IF;
IF @Expiration    !="" THEN
   IF @Expiration  ="Expired"
   THEN  SET @WhereExpired   =CONCAT(" AND a.Valid_To < CURDATE()");
   ELSE  SET @WhereExpired   =CONCAT(" AND (a.Valid_To >= CURDATE() OR a.Valid_To IS NULL)");
   END IF;
END IF;

IF @Debug!="NO" THEN SELECT @WhereProduct,@WhereAccount_id,@WhereAccount,@WhereBrand,@WhereStatus,@WhereExpired; END IF;

CREATE TABLE IF NOT EXISTS campaign_advertiser_ads_v2 (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  Ad_code       VARCHAR(50)   NOT NULL,             -- Código del anuncio
  Status_id     SMALLINT          NULL DEFAULT '1', -- 0/1
  Product       VARCHAR(50)   NOT NULL,             -- 'sport', 'casino', etc.
  Brand         VARCHAR(100)  NOT NULL,             -- Nombre de la marca (advertiser), derivada de 'Account'
  Advertiser_id INT           NOT NULL,             -- Identificador de Brand
  Account_id    INT           NOT NULL,             -- Identificador de cuenta
  Country       VARCHAR(2)    NULL,                 -- País al cual se aplica; NULL = para todos
  Title         VARCHAR(255)  NOT NULL,             -- Título resumido del Ad
  Description   TEXT          NOT NULL,             -- Descripción detallada del Ad
  Valid_From    DATE          NOT NULL,             -- Fecha desde la cual aplica
  Valid_To      DATE          NULL,                 -- Fecha hasta la cual aplica; NULL = permanente
  -- Campos de control/ auditoría
  Creation_Date DATETIME      NULL DEFAULT CURRENT_TIMESTAMP,
  Last_Update   DATETIME      NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  User          INT           NULL DEFAULT NULL,

  PRIMARY KEY (id)
);
/*
SELECT a.`id`,a.`Ad_code`,a.`Status_id`,a.`Product`,a.`Brand`,a.`Advertiser_id`,a.`Account_id`,a.`Country`
      ,a.`Title`,a.`Description`,a.`Valid_From`,a.`Valid_To`,a.`Base_Url`,a.`Creation_Date`,a.`Last_Update`,a.`User`
FROM campaign_advertiser_ads_v2 a
*/

SET @SQLmeta=concat(
'(
SELECT
   "setting" as Meta
   ,"width=100px,action=2"                    as `Action`      -- K 21.02.2025
   ,"width=080px"                             as `Ad Code`
	,IF(@Mode="AFF","omit=true","width=100px,colorBg=[Active:green;Inactive:red;Paused:orange]") AS `Status`
   ,"width=100px"                             as `Product`
	,"width=120px"                             as `Brand`
	,IF(@Mode="AFF","omit=true","width=100px") AS `Account id`
	,IF(@Mode="AFF","omit=true","width=200px") AS `Account`
	,"width=100px"                             AS `Country`
	,"width=300px"                             AS `Title`
	,"width=350px,tooltip=yes"                 as `Description`
	,"width=100px"                             AS `Valid From`
	,"width=100px"                             AS `Valid Until`
	,IF(@Mode="AFF","omit=true","width=140px") AS `Last Update`
	,IF(@Mode="AFF","omit=true","width=100px") AS `User`
	,"omit=true"                               AS `id`          -- K 23.02.2025
	FROM DUAL WHERE @Meta="YES")'
);

SET @CTE=CONCAT('
WITH Ads_available as (
  SELECT a.`id`,a.`Ad_code`,a.`Status_id`,a.`Product`,a.`Brand`,a.`Advertiser_id`,a.`Account_id`,a.`Country`
        ,a.`Title`,a.`Description`,a.`Valid_From`
        ,ifnull(a.`Valid_To`,"2030-12-31") as `Valid_To`
        ,a.`Base_Url`,a.`Creation_Date`,a.`Last_Update`
        ,u.Username  as `Account`
        ,AA.username as `User`
  FROM campaign_advertiser_ads_v2 a
  LEFT JOIN account_account AA  on AA.id=a.User
  LEFT JOIN campaign_username u ON u.id=a.Account_id
)
');

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
UNION ALL
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,'...' as `Action`,",""),
   'Ad_code
   ,if(Status_id!=1,"Inactive","Active") as Status
   ,Product
	,Brand
	,Account_id
	,Account
	,Country
	,Title
	,Description
	,Valid_From
	,Valid_to
   ,DATE_FORMAT(Last_Update,"%Y-%m-%d %H:%i") as Last_Update
   ,User
	,id                                                         -- K 23.02.2025
FROM Ads_available a
WHERE 1=1
',
   @WhereProduct,
   @WhereAccount,
   @WhereAccount_id,
   @WhereBrand,
   @WhereStatus,
   @WhereExpired,
'
;'
);

SET @SQLfilters=CONCAT(
@CTE,
',
Main_Table_Data as (
SELECT *
FROM Ads_available a
WHERE 1=1
',
   @WhereProduct,
   @WhereAccount,
   @WhereAccount_id,
   @WhereBrand,
   @WhereStatus,
   @WhereExpired,
'
)
(SELECT "01" as "Korder","Expiration date" as "Key","Valid"   as "Value","Expiration" as `CallKey`,"Valid"   as "CallValue","" as "Rows" FROM DUAL) UNION ALL
(SELECT "01" as "Korder","Expiration date" as "Key","Expired" as "Value","Expiration" as `CallKey`,"Expired" as "CallValue","" as "Rows" FROM DUAL) UNION ALL
(SELECT "03","Status"   ,"Active"   ,"Status_id"   ,"1"           ,"" AS K       FROM DUAL) UNION ALL
(SELECT "03","Status"   ,"Inactive" ,"Status_id"   ,"0"           ,"" AS K       FROM DUAL) UNION ALL
(SELECT "05","Product"  ,`Product`  ,"Product"     ,`Product`     ,COUNT(*) AS K FROM Main_Table_Data GROUP BY Product) UNION ALL
(SELECT "07","Brand"	   ,`Brand`    ,"Brand"       ,replace(`Brand`," ","!")  ,COUNT(*) AS K FROM Main_Table_Data GROUP BY `Brand`) UNION ALL
-- (SELECT "13","Mode"     ,"Gestor"   ,"Mode"        ,"Ges"          ,"" AS K       FROM DUAL) UNION ALL
-- (SELECT "13","Mode"     ,"Affiliate","Mode"        ,"Aff"          ,"" AS K       FROM DUAL) UNION ALL
(SELECT "09","Account"	,`Account`  ,"Account"     ,replace(`Account`," ","!"),COUNT(*) AS K FROM Main_Table_Data GROUP BY `Account`)
ORDER BY 1,3
;');

SET @SQL_Option=CONCAT('
WITH MS_with_bid as (
  SELECT
          ms.`Product`           as `Product`
         ,u.Username             as `Account`
         ,ms.`Username_id`       as `Account_id`
         ,a.Advertiser_Name      as `Brand`
         ,a.id                   as `Advertiser_id`
    FROM campaign_marketing_source ms
    INNER JOIN campaign_username u   ON u.`id`=ms.`Username_id`
    INNER JOIN campaign_advertiser a ON a.`id`=u.Advertiser_id
    WHERE ms.Stat_aggreg IN (1,6)
      AND ms.Tracklink NOT LIKE "%rebrand.ly%"
      AND ms.Tracklink NOT LIKE "%affly%"
      AND ms.Tracklink LIKE "%?pid=%"
      AND ms.Tracklink LIKE "%bid=%"
    GROUP BY a.Advertiser_Name,ms.`Username_id`
)
SELECT ',
    IF(@Option="Brand"  ,"`Brand` AS 'Option',"             ,""),
    IF(@Option="Brand"  ,"`Advertiser_id` AS Advertiser_id ",""),
    IF(@Option="Account","`Account` AS 'Option',"           ,""),
    IF(@Option="Account","`Account_id` AS Account_id "      ,""),
'
FROM MS_with_bid
',
IF(@Option="Account","WHERE `Brand`=@Brand ",""),

IF(@Option="Brand"  ,"GROUP BY `Brand`"     ,""),
IF(@Option="Account","GROUP BY `Account_id`",""),

IF(@Option="Brand"  ,"ORDER BY `Brand`"     ,""),
IF(@Option="Account","ORDER BY `Account`"   ,""),
';'
);

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL_Option; END IF;
IF @Debug!="NO" THEN SELECT @SQL; END IF;

IF @Filters!="NO" THEN SET @SQL=@SQLfilters; END IF;
IF @Mode="Option" THEN SET @SQL=@SQL_Option; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END $$
DELIMITER ;

/*
call Report_Ads('Account_id=36,Product=casino,Excl_Ad_code=1675,debug=ye');

call Report_Ads('mode=ges,filters=ye,debug=ye');
call Report_Ads('mode=ges,filters=yes,debug=ye');

call Report_Ads('mode=ges,Account=euroaffiliati,Product=all,Brand=all,Expiration=valid,Status_id=all,debug=ye');
call Report_Ads('mode=ges,Account=euroaffiliati,Product=all,Brand=all,Expiration=valid,Status_id=all,filters=yes,debug=ye');

call Report_Ads('mode=option,brand=PlanetWin365,option=account');
call Report_Ads('mode=option,option=brand');

*/