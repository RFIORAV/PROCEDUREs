/*
PROCEDURE_Report_Publisher.sql - Report Publisher (Publisher)

Descripción:
  Procedimiento Report_Publisher.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

Advertiser_id   =[ALL | id del Advertiser]. OPCIONAL. Default=ALL
Status          =[ALL | 1 | 0]. OPCIONAL. Default=ALL. 1=Active 0=Inactive
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Meta            =[No | Yes]. OPCIONAL. Columna 1 como METADATO: total/data/setting. Default [No]
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Parámetros ('[Key=Value[,...]'])

Key no utilizadas:

Mode            =[Affiliate | Gestor]. OPCIONAL. Default=affiliate
MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Product         =[ALL | Product]. OPCIONAL. Default=ALL. Si tiene más de una palabra, separar con "!" en lugar de espacio
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Affiliate_id    =[ALL | id del Affiliate]. OBLIGATORIO. Default=''
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
DealbyProduct   =[No | Yes]. Devuelve último deal activo por cada Product. OPCIONAL. Default=no.
Search          =[(dato a buscar]. OPCIONAL. Busca string en Tracker_ID/Tracker_Name/Code_To_Affiliate/MS_id/MS_id/affiliate/Channel

Ejemplos:

call Report_Publisher('debug=yes'); -- Devuelve todas las MS
call Report_Publisher('debug=ye,filters=yes');
call Report_Publisher('debug=ye,filters=no,status=0');

19.01.2023 V1     Primera versión operativa
02.03.2023 V1.1   correcciones
01.08.2023 v1.2   Eliminación de algunas columnas (Riccardo)
27.11.2024 V1.3   Default ORDER BY Publisher (RS)
28.02.2025 v1.4   Eliminación de campos de la grid: `Category` `Status id` `id`
14.04.2025 v1.4.1 Mostrar datos para factura (campo `Commercial_History`)
                  Nuevo campo `InvoiceByAccnt` indica que hay que hacer una factura por cada Account
10.04.2026 v1.4.2 Meta: etiqueta columna nombre (Advertiser_Name) Publisher -> Operator; usuario -> User
18.05.2026 v1.4.2 Ruta de navegación: /dash/publisher/id (Karen 18052026)
27.05.2026 v1.4.3 Añadida opción colorBg=[Active:green;Paused:orange;Other:red] a columna Status

*/

DROP PROCEDURE IF EXISTS Report_Publisher;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Report_Publisher`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v1.4.3 27.05.2026: Report_Publisher'
    
proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1.4.3 27.05.2026';
SET @CurrentDay      =curdate();

SET @Publisher_id    ='ALL';
SET @Debug           ='NO';
SET @Filters         ='NO';
SET @STATUS          ='ALL';

SET @Mode            ='gestor';
SET @Affiliate_id    ='ALL';
SET @Month           =left(curdate(),7);
SET @Account_id      ='ALL';
SET @Brand_Group     ='ALL';
SET @Channel_id      ='ALL';
SET @Currency        ='EUR';
SET @DealbyProduct   ='NO';
SET @MS_id           ='ALL';
SET @Meta            ='YES';
SET @Owner           ='ALL';
SET @Platform        ='ALL';
SET @Product         ='ALL';
SET @Search          ='';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
-- SET @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Publisher_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

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

   IF lower(@k)='Publisher_id'    THEN SET @Publisher_id  =UPPER(@v); END IF;
   IF lower(@k)='status'          THEN SET @Status        =      @v;  END IF;
   IF lower(@k)='meta'            THEN SET @Meta          =UPPER(@v); END IF;
   IF lower(@k)='filters'         THEN SET @Filters       =UPPER(@v); END IF;
   IF lower(@k)='debug'           THEN SET @Debug         =UPPER(@v); END IF;

END WHILE;

-- Recupera espacios reemplazados en front end por caracter "\"
SET @Product      =replace(@Product,"!"," ");
-- SET @Platform     =replace(@Platform,"!"," ");
-- SET @Brand_Group  =replace(@Brand_Group,"!"," ");

-- IF @Debug!="NO" THEN SELECT @Product,@Platform,@Brand_Group; END IF;
--

-- IF @Mode!='GESTOR' THEN
   -- SET @Mode='AFFILIATE';
   -- SET @View='VIEWAFF';
-- END IF;

IF @Debug!="NO" THEN SELECT @Mode,@Month,@View,@Filters,@OWNER,@OnlyOverCap,@Brand_Group,@Publisher_id,@Affiliate_id,@Account_id
,@Channel_id,@Product,@DealbyProduct,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereMS_id='';
SET @WhereOwner='';
SET @WherePublisher_id ='';
SET @WhereAffiliate_id  ='';
SET @WhereAdv_Account_id='';
SET @WhereChannel_id    ='';
SET @WhereProduct       ='';
SET @WhereStatus        ='';
SET @WhereSearch        ='';

SET @SearchClause=replace('and (M.id like "%XXX%" or Description like "%XXX%"
     or M.Deal_Name like "%XXX%") like "%XXX%")','XXX',@Search);

IF @Publisher_id  !="ALL" THEN SET @WherePublisher_id  =CONCAT(" AND id  =",@Publisher_id );             END IF;
IF @Status        !="ALL" THEN SET @WhereStatus        =CONCAT(" AND `Status`       ='",@Status,"'");    END IF;
-- IF @Owner         !="ALL" THEN SET @WhereOwner         =CONCAT(" AND Owner=",@Owner);                    END IF;
-- IF @Product       !="ALL" THEN SET @WhereProduct       =CONCAT(" AND `Product`      ='",@Product,"'");   END IF;
-- IF @Status         ="0"   THEN SET @WhereStatus        =CONCAT(" AND `Status_id`   !='1'");              END IF;
-- IF @Search        !=""    THEN SET @WhereSearch        =@SearchClause; END IF;

IF @Debug!="NO" THEN SELECT @WhereOwner,@WherePublisher_id,@WhereAffiliate_id,@WhereAdv_Account_id,@WhereChannel_id,@WhereProduct,@WhereStatus,@WhereMS_id,@WhereSearch; END IF;

SET @Count=0;

/**************************************************************************************************************/

-- SET SESSION group_concat_max_len = 100000;

SET @CTE=CONCAT('
WITH Main_Table_Data as (
SELECT 
    `id`
   -- ,`Owner`
   ,`Advertiser_Name` AS `Operator`
   ,`Status`
   ,`Status_id`
   ,`CPA_Limit`
   ,`Brand_Group`
   ,`Brand_Group_Acum`
   ,`Affiliate_Manager`
   ,`Affiliate_Manager_Email`
   ,`Affiliate_Manager_Phone`
   ,`Affiliate_Manager_Skype`
   ,left(ifnull(`Pay_Day`,""),10) as `Pay_Day`
   ,`Category`
   ,`Country`
   ,`Platform_Domain`
   ,`Commercial_History`   -- Invoicing data
   ,CASE WHEN `InvoiceByAccnt`=1 THEN "Yes" ELSE "No" END AS `InvoiceByAccnt`
   ,`Dominio_Commerciale`
   ,`KYC`
   -- ,`Creation_Date`
   ,left(ifnull(`Last_Update`,""),19) `Last_Update`
   ,ifnull(usr.username,"") as `User`  
   ,CONCAT("/dash/publisher/",`id`)   -- K18052026
FROM campaign_publisher T
LEFT JOIN LATERAL (SELECT usr.username FROM account_account usr where usr.id=T.`Operator`) AS usr ON TRUE
WHERE 1=1 '
   ,@WhereOwner
   ,@WherePublisher_id
   ,@WhereProduct
   ,@WhereStatus
   ,@WhereSearch
,')
');

SET @SQLmeta=CONCAT(
'(
SELECT
   "setting" as Meta,"width=80px,action=2" as `Action`
   ,"width=050px"   as `id`
   -- ,"width=100px"   as `Owner`
   ,"width=250px,route=_routePath"   as `Operator`   -- K18052026
   ,"width=080px,colorBg=[Active:green;Paused:orange;Other:red]"   as `Status`
   ,"omit=true"     as `Status id`
   ,"width=080px"   as `CPA Limit`
   ,"omit=true"     as `Brand Group`
   ,"omit=true"     as `Brand Group Acum`
   ,"width=200px"   as `Manager`
   ,"width=100px,tooltip=yes" as `Manager Email`
   ,"width=100px"   as `Manager Phone`
   ,"omit=true"     as `Manager Skype`
   ,"omit=true"     as `Pay Day`
   ,"omit=true"     as `Category`
   ,"omit=true"     as `Country`
   ,"width=130px"   as `Data Platform`
   ,"width=200px,tooltip=yes" as `Invoicing data`
   ,"width=100px"   as `Invoice By Accnt`
   ,"width=300px,tooltip=yes"   as `Web page`
   ,"omit=true"     as `KYC`
   -- ,"width=100px"   as `Creation Date`
   ,"width=150px"   as `Last Update`
   ,"width=100px"   as `User`    
   ,"omit=true"     as _routePath   -- K18052026
FROM DUAL WHERE @Meta="YES")
UNION ALL '
);

SET @SQL=CONCAT(
@CTE,
@SQLmeta,
'
SELECT "data" as `Meta`,"..." as `Action`,
   MT.* 
FROM Main_Table_Data MT
ORDER BY `Operator`
');

-- ------------------------------------------------------------
SET @SQLfilters=CONCAT(
@CTE,'
(SELECT "1" as "Korder","Status" AS "Key",`Status` AS "Value","Status" AS `CallKey`,`Status` AS "CallValue",COUNT(*) AS "Rows"
                                                                                       FROM Main_Table_Data GROUP BY `Status`       ) UNION ALL
(SELECT "5","Operator",`Operator`,"Publisher_id",`id` ,COUNT(*) AS K FROM Main_Table_Data WHERE IFNULL(`Operator`,"")>"" GROUP BY IFNULL(`Operator` ,"")) 
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

call Report_Publisher('debug=ye'); -- Devuelve todas las MS
call Report_Publisher('debug=ye,filters=yes');
call Report_Publisher('debug=ye,filters=no,status=0');

*/
