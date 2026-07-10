/*
PROCEDURE_Gestor_MonthlySources_v4_daily.sql - Reporte multimodo diario de las MS

Descripción:
  Procedimiento Gestor_MonthlySources con acumulación diaria.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

MS_id           =[ALL | id de la MS]. OPCIONAL. Default=ALL. tiene prioridad sobre el resto de parámetros, excepto la fecha
Tag             =[ALL | Tag]. OPCIONAL. Default=ALL
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Area            =[ALL | gaming / forex]. OPCIONAL. Default=ALL
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month. Limita el rango de días disponibles cuando no se informa Day. Acepta múltiples valores con ^.
Day             =[AAAA-MM-DD]. OPCIONAL. Default=ALL. Acepta múltiples días con ^. En Filters muestra todos los días del Month hasta fin de mes o hoy.
Mode            =[Monthly | Daily]. OPCIONAL. Default=Monthly. Monthly acumula por mes y oculta filtro Day. Daily acumula por día, habilita filtro Day y muestra columna Date.
Affiliate_id    =[ALL | id del Affiliate]. OPCIONAL. Default=ALL
ReferrerMode    =[Yes | No]. Solo muestra los referidos. Default=No
Master_Affiliate_id=[ALL | id del M. Affiliate]. OPCIONAL. Default=ALL
Publisher_id    =[ALL | id del Publisher]. OPCIONAL. Default=ALL
Brand           =[ALL | Name del Brand]. OPCIONAL. Default=ALL
Account_id      =[ALL | id del Adv_Account. OPCIONAL. Default=ALL
Account         =[ALL | nombre del Adv_Account. OPCIONAL. Default=ALL
Channel_id      =[ALL | id del Channel]. OPCIONAL. Default=ALL
Product         =[ALL | Product]. Producto según Publisher. OPCIONAL. Default=ALL
ProductMS       =[ALL | Product]. Producto original de la MS. OPCIONAL. Default=ALL
Platform        =[ALL | Platform]. OPCIONAL. Default=ALL
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
OnlyOverCap     =[Yes | No]. Solo muestra los que exceden el CPA_Limit. Default=No (fuerza GroupByMS=yes)
OnlyBigCPA_SUp  =[Yes | No]. Solo muestra los que exceden el Ratio. Default=No (fuerza GroupByMS=yes)
GroupByMS       =[Yes | No]. Agrupa Product by MS. OPCIONAL. Default=yes
Total           =[Yes | No]. Incluye línea/s de Totales. OPCIONAL. Default=Yes
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Meta            =[No | Yes]. [No] OPCIONAL. Columna 1 como METADATO: total/data/setting.
Search          =[(dato a buscar]. OPCIONAL. Busca string en Tracker_ID/Tracker_Name/Code_To_Affiliate/MS_id
Debug           =[No | Yes | KeyValues]. OPCIONAL. Default=No
                  [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query.

Keys no utilizadas:
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No
View            =[viewAFF | viewGES]. Info de Fact2 (viewAFF) o de Fact1 (viewGES). OPCIONAL. Default=viewAFF
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=CPA
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]'])

Ejemplos:

call Gestor_MonthlySources('');              -- Todos los valores de selección por default
call Gestor_MonthlySources('mode=daily,debug=ye');      -- Todos los valores de selección por default usando debug
call Gestor_MonthlySources('^owner=^864^865,affiliate_id=^39^130^850,debug=ye');
call Gestor_MonthlySources('^owner=^864,affiliate_id=^39^130^850,debug=ye');
call Gestor_MonthlySources('month=2026-04,filters=yes,debug=ye');
call Gestor_MonthlySources('^day=^2026-05-01^2026-05-06,debug=ye');
call Gestor_MonthlySources('^owner=^864^865,Brand=^LeoVegas^Lottomatica^PlanetWin365,debug=ye');
call Gestor_MonthlySources('^affiliate_id=^39^506^450,filters=yes,debug=ye');
call Gestor_MonthlySources('filters=yes,debug=ye');
call Gestor_MonthlySources('^tag=^1^2^3,filters=ye,debug=ye');
call Gestor_MonthlySources('^month=^2025-11^2025-12,^tag=^1,filters=ye,debug=ye');

29.09.2022 V2     Primera versión operativa
01.10.2022 V2.2   Se agrega generación de filtros. Se agrega Key=Channel_id
09.10.2022 V2.3   Opción de ver info sobre Fact1/Fact2. Parametro [viewAFF | viewGES]
10.10.2022 V2.4   Filtros sobre la misma selección de parámetros
11.10.2022 V2.5   Columna y filtro Brand_Group
11.10.2022 V2.6   Columna METAdatos. Quitado parámetro View. Parémtro seleccionado se oculta
13.10.2022 V2.6.1 filtro GroupByMS (deja una row por MS)
13.10.2022 V2.6.2 Tratamiento de filtros x Product,Platform y Brand_Group con espacios internos
                  Agregado columna CallKey a Filtros
14.10.2022        Order by CPA desc
14.10.2022 V2.6.3 Agrega columnas,`First_Time_Deposit`,`Views`,`Clicks`,`Signups`,`Impressions`
                  ,`Deposits`,`Depositing_Customers`,`Active_Customers`
14.10.2022        Agrega columna Cap/Used
18.10.2022 V2.6.4 Agrega opción OnlyOverCap
19.10.2022 V2.6.5 MS_id null=missing
21.10.2022 V2.6.6 Agregadas columnas RS y CPA Value - Aff y Gestor. MS_Status. Elimina de filtro los que no tienen key
21.10.2022 V2.6.7 En desarrollo. Permite la inclusión de parámetros opcionales estáticos
26.10.2022 V2.6.8 Agrega parámetro MS_id
26.10.2022 V2.6.9 Agrega parámetro Search
24.11.2022 V2.7   Agrega parámetro Account (Username) (nombre del Account Adv)
03.01.2023        Trata el caso del Month 2023-1 en lugar de 2023-01
25.01.2023        Acepta parámetros con espacios
01.02.2023 v2.7   Area=[ALL | gaming / forex]. OPCIONAL. Default=ALL
14.02.2023 v2.7.2 No muestra filtro forex/gaming si no hay forex
16.02.2023 v2.7.3 GroupByMS como filtro
23.02.2023 v2.7.4 Publisher_id en lugar de Brand_group
                  Cambio de orden de los filtros
25.04.2023 v2.7.5 Filtro por Brand/Advertiser_Name en lugar de Advertiser_id
18.05.2023 v2.7.6 Agrega Product MS
24.07.2023 v2.7.7 Filtro por Brand tratamiento de espacio (modif para evitar iny SQL)
                  Fix filtro por Account
27.11.2023        Selección de fechas hasta dos años
10.01.2024 v2.7.8 Agregados campos Username_id y Advertiser_id a la grilla
15.01.2024 v2.7.9 Karen: Agregados campo Publisher_id a la grilla
                  Opción 3 de edit MS. Create en "missing"
28.06.2024        Tratamiento Month=CM/LM
09.08.2024 v2.8   Multicurrency
04.09.2024 v2.8.1 Fix filtro por Owner
10.10.2024 v2.8.2 Karen: Fix "Column 'CPA_Limit' in where clause is ambiguous"
02.11.2024 v2.9   Columna Ratio CPA/Signups. Opción OnlyBigCPA_SUp
16.11.2024 v2.9.1 Muestra Product MS al agrupar por MS (RS/ARev)
17.11.2024 v3     Modo Referrer
13.01.2025 v3.0.1 Ratio >=0.7 cuando CPA>=5
12.02.2025        Fix espacio dentro de Product
21.05.2025 v3.1   PARAMETROS MULTIVALOR
24.05.2025        Tags
25.05.2025 v3.2   parametros multivalor se indican con ^ al comienzo y entre valores
27.05.2025        parametros multivalor se indican con ^ al comienzo del nombre del parámetro y entre valores
06.06.2025 v3.2.1 Muestra columna del valor filtrado si es multivalor
18.12.2025 v3.2.2 fix Tags: elimina elemento vacío
10.01.2026 v3.2.2 GroupByMS=yes por default
10.04.2026 v3.2.3 Meta: etiqueta de columna Publisher -> Operator en fila setting
10.04.2026 v3.2.4 Filtros: clave visible Publisher -> Operator (Key en lista de filtros)
07.05.2026 v4     Acumulación diaria y filtro Day multivalor
11.05.2026 v4.1   Parametro Mode=Monthly/Daily. Monthly agrega por mes y oculta Day; Daily agrega por dia, habilita Day y muestra Date
11.05.2026 v4.1.1 Date: muestra mes si es multivalor

*/

DROP PROCEDURE IF EXISTS Gestor_MonthlySources;
DROP PROCEDURE IF EXISTS Gestor_MonthlySources_dev;
DROP PROCEDURE IF EXISTS Gestor_MonthlySources_multiple;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Gestor_MonthlySources`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v4.1.1 11.05.2026 Monthly/Daily Sources PARAMETROS MULTIVALOR y Tags'
BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version            ='v4.1.1 11.05.2026';
SET @Month              =CONCAT('("',LEFT(CURDATE(),7),'")');
-- SELECT @Month ;
SET @MS_id              ='';
SET @Day                ='';
SET @Mode               ='MONTHLY';
SET @Area               ='';
SET @Tag                ='';
SET @Owner              ='';
SET @Brand              ='';
SET @Affiliate_id       ='';
SET @Master_Affiliate_id='';
SET @Account_id         ='';
SET @Account            ='';
SET @Channel_id         ='';
SET @Product            ='';
SET @ProductMS          ='';
SET @Platform           ='';
SET @Publisher_id       ='';
SET @ReferrerMode       ='NO';
SET @Total              ='YES';
SET @Filters            ='NO';
SET @TotLine            ='FIRST';
SET @Meta               ='YES';
SET @Debug              ='NO';
SET @View               ='VIEWGES';
SET @GroupByMS          ='YES';
SET @OnlyOverCap        ='NO';
SET @OnlyBigCPA_SUp     ='NO';
SET @Search             ='';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
--  @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;
-- IF @Debug="YES" THEN SELECT @Owner,@Month,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine,@OrderBy,@Order,@InputCommLine; END IF;

-- Procesamiento de parámetros de entrada
-- Los parámetros multivalor se indican con ^ al inicio del nombre del parámetro
-- y los valores se separan con ^
WHILE @InputCommLine>' ' DO
   -- Extracción de key=value
   SET @e=INSTR(@InputCommLine,'=');    				   
   SET @c=INSTR(@InputCommLine,','); 					   
   SET @k=SUBSTRING(@InputCommLine,1,@e-1); 			   
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1)); 	
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   -- Tratamiento de month/day monovalor como multivalor
   -- para mantener compatibilidad del código en ambos casos
   IF lower(@k)='month' THEN SET @k=CONCAT("^",@k); END IF;
   IF lower(@k)='day'   THEN SET @k=CONCAT("^",@k); END IF;
   
   -- SELECT @k AS "Key",@v as "Value";
   
   -- Procesamiento de parámetros multivalor
   -- Input ex: ^affiliate_id=39^84 -> affiliate_id IN ("39","84")
   IF LEFT(@k,1)='^' THEN
      -- Formatear valor para cláusula IN
      SET @v=CONCAT('("',@v,'")');           
      SET @v=REPLACE(@v,'^','","'); 
      SET @v=REPLACE(@v,'"",',''); -- elimina elemento vacío         
      -- Remover el indicador de multivalor del nombre
      SET @k=SUBSTRING(@k,2);                
   END IF;
   
   -- Asignación de valores a variables según el parámetro
   IF lower(@k)='month'                THEN SET @Month                  =UPPER(@v); END IF;
   IF lower(@k)='day'                  THEN SET @Day                    =UPPER(@v); END IF;
   IF lower(@k)='mode'                 THEN SET @Mode                   =UPPER(@v); END IF;
   IF lower(@k)='ms_id'                THEN SET @MS_id                  =UPPER(@v); END IF;
   IF lower(@k)='area'                 THEN SET @Area                   =lower(@v); END IF;
   IF lower(@k)='tag'                  THEN SET @Tag                    =lower(@v); END IF;
   IF lower(@k)='owner'                THEN SET @Owner                  =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id'        THEN SET @Advertiser_id          =UPPER(@v); END IF;
   IF lower(@k)='brand'                THEN SET @Brand                  =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'         THEN SET @Affiliate_id           =UPPER(@v); END IF;
   IF lower(@k)='master_affiliate_id'  THEN SET @Master_Affiliate_id    =UPPER(@v); END IF;
   IF lower(@k)='account_id'           THEN SET @Account_id             =UPPER(@v); END IF;
   IF lower(@k)='publisher_id'         THEN SET @Publisher_id           =UPPER(@v); END IF;
   IF lower(@k)='account'              THEN SET @Account                =UPPER(@v); END IF;
   IF lower(@k)='channel_id'           THEN SET @Channel_id             =UPPER(@v); END IF;
   IF lower(@k)='currency'             THEN SET @Currency               =UPPER(@v); END IF;
   IF lower(@k)='product'              THEN SET @Product                =UPPER(@v); END IF;
   IF lower(@k)='productms'            THEN SET @ProductMS              =UPPER(@v); END IF;
   IF lower(@k)='platform'             THEN SET @Platform               =UPPER(@v); END IF;
   -- Parametros monovalor
   IF lower(@k)='total'                THEN SET @Total                  =UPPER(@v); END IF;
   IF lower(@k)='totline'              THEN SET @TotLine                =UPPER(@v); END IF;
   IF lower(@k)='referrermode'         THEN SET @ReferrerMode           =UPPER(@v); END IF;
   IF lower(@k)='groupbyms'            THEN SET @GroupByMS              =UPPER(@v); END IF;
   IF lower(@k)='onlyovercap'          THEN SET @OnlyOverCap            =UPPER(@v); END IF;
   IF lower(@k)='onlybigcpa_sup'       THEN SET @OnlyBigCPA_SUp         =UPPER(@v); END IF;
   IF lower(@k)='search'               THEN SET @Search                 =UPPER(@v); END IF;
   IF lower(@k)='view'                 THEN SET @View                   =UPPER(@v); END IF;
   IF lower(@k)='debug'                THEN SET @Debug                  =UPPER(@v); END IF;
   IF lower(@k)='filters'              THEN SET @Filters                =UPPER(@v); END IF;
   IF lower(@k)='meta'                 THEN SET @Meta                   =UPPER(@v); END IF;

END WHILE;

IF @Mode NOT IN ("MONTHLY","DAILY") THEN SET @Mode="MONTHLY"; END IF;
IF @Mode="MONTHLY" THEN SET @Day=""; END IF;

SET @MultiMonth=LOCATE(',',@Month);
IF @MultiMonth>0 THEN SET @MultiMonth=1; ELSE SET @MultiMonth=0; END IF;

-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

-- Recupera espacios reemplazados en front end por caracter "!"
IF @Product       !="" THEN SET @Product      =replace(@Product,"!"," ");     END IF;
IF @Platform      !="" THEN SET @Platform     =replace(@Platform,"!"," ");    END IF;
IF @Brand         !="" THEN SET @Brand        =replace(@Brand,"!"," ");       END IF;
IF @Account       !="" THEN SET @Account      =replace(@Account,"!"," ");     END IF;

-- Check month para caso 2023-1 en lugar de 2023-01
IF CHAR_LENGTH(@Month)=6 THEN SET @Month=CONCAT(LEFT(@Month,5),'0',RIGHT(@Month,1)); END IF;

IF  @Month = "CM" THEN SET @Month=CONCAT('("',LEFT(CURDATE(),7),'")'); END IF;
IF  @Month = "LM" THEN SET @Month=CONCAT('("',LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),'")'); END IF;

IF @Debug!="NO" THEN SELECT @ReferrerMode,@Mode,@Month,@MultiMonth,@Day,@Tag,@View,@Currency,@Filters,@OWNER,@OnlyOverCap,@OnlyBigCPA_SUp,@Publisher_id
                           ,@Brand,@Master_Affiliate_id,@Affiliate_id,@Account_id,@Account,@Channel_id,@Product
                           ,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereMS_id         ='';
SET @WhereDay           ='';
SET @WhereOwner         ='';
SET @WhereArea          ='';
SET @WhereBrand         ='';
SET @WherePublisher_id  ='';
SET @WhereAffiliate_id  ='';
SET @WhereAdv_Account_id='';
SET @WhereAdv_Account   ='';
SET @WhereChannel_id    ='';
SET @WhereStatus        ='';
SET @WhereProduct       ='';
SET @WhereProductMS     ='';
SET @WherePlatform      ='';
SET @WhereSearch        ='';
SET @WhereMaster_Affiliate_id='';
SET @WhereTag           ='';
SET @JoinOnTag          ='';
-- SET @GroupDateExpr      ='CASE WHEN @Mode="DAILY" THEN DATE(D.Date) ELSE STR_TO_DATE(CONCAT(LEFT(D.Date,7),"-01"),"%Y-%m-%d") END';
SET @GroupDateExpr      ='CASE WHEN @Mode="DAILY" THEN DATE(D.Date) ELSE LEFT(D.Date,7) END';

IF @Day               !="" THEN SET @WhereDay=CONCAT(" AND DATE(D.Date) IN ",@Day); END IF;

IF @MS_id             !="" THEN SET @WhereMS_id=CONCAT(" AND D.MS_id IN ",@MS_id);
ELSE
   IF @Owner          !=""   THEN SET @WhereOwner           =CONCAT(" AND D.Owner IN ",@Owner);                            END IF;
   IF @Area           !=""   THEN SET @WhereArea            =CONCAT(" AND D.Area IN ",@Area);                              END IF;
   IF @Brand          !=""   THEN SET @WhereBrand           =CONCAT(" AND IFNULL(D.Brand        ,'') IN ",@Brand);         END IF;
   IF @Affiliate_id   !=""   THEN SET @WhereAffiliate_id    =CONCAT(" AND IFNULL(D.Affiliate_id ,'') IN ",@Affiliate_id);  END IF;
   IF @Account_id     !=""   THEN SET @WhereAdv_Account_id  =CONCAT(" AND IFNULL(D.Username_id  ,'') IN ",@Account_id);    END IF;
   IF @Account        !=""   THEN SET @WhereAdv_Account     =CONCAT(" AND IFNULL(D.Username     ,'') IN ",@Account);       END IF;
   IF @Channel_id     !=""   THEN SET @WhereChannel_id      =CONCAT(" AND IFNULL(D.Channel_id   ,'') IN ",@Channel_id);    END IF;
   IF @Product        !=""   THEN SET @WhereProduct         =CONCAT(" AND IFNULL(D.Product      ,'') IN ",@Product);       END IF;
   IF @ProductMS      !=""   THEN SET @WhereProductMS       =CONCAT(" AND IFNULL(M.Product      ,'') IN ",@ProductMS);     END IF;
   IF @Platform       !=""   THEN SET @WherePlatform        =CONCAT(" AND IFNULL(D.Portal       ,'') IN ",@Platform);      END IF;
   IF @Publisher_id   !=""   THEN SET @WherePublisher_id    =CONCAT(" AND IFNULL(D.Publisher_id ,'') IN ",@Publisher_id);  END IF;
   IF @Master_Affiliate_id!="" and @ReferrerMode="YES"
   THEN SET @WhereMaster_Affiliate_id=CONCAT(" AND IFNULL(R.Master_Affiliate_id ,'') IN ",@Master_Affiliate_id);
   END IF;
   IF @Search         !=""   THEN SET @WhereSearch          =@SearchClause; END IF;
   IF @Tag            !=""   THEN SET @WhereTag             =CONCAT(" AND Tg.Tag_id IN ",@Tag);                             END IF;
   IF @Tag            !=""   THEN 
         SET @JoinOnTag=CONCAT('
            INNER JOIN LATERAL (
               SELECT * FROM `account_account_tags` Tg 
               WHERE Tg.`Affiliate_id`=D.`Affiliate_id` '
               ,@WhereTag,' LIMIT 1) AS Tags ON TRUE '
               );
   END IF;                 
END IF;

IF @OnlyOverCap ="YES"
THEN SET @WhereOnlyOverCap=CONCAT(" AND (sb.CPA_Limit>0 AND CPA/sb.CPA_Limit>0.8)"); -- K: 10.10.2024
     SET @GroupByMS="YES";                             -- fuerza agrupación por ms para ver OverCap
ELSE SET @WhereOnlyOverCap=' ';  END IF;

IF @OnlyBigCPA_SUp="YES"
THEN SET @WhereBigCPA_SUp=CONCAT(" AND (sb.Ratio_CPA_SUp>=0.7)");
     SET @GroupByMS="YES";                             -- fuerza agrupación por ms
ELSE SET @WhereBigCPA_SUp=' ';  END IF;

IF @GroupByMS="YES" -- AND @Product="("")"
THEN SET @GroupBySeleccBase='';
ELSE SET @GroupBySeleccBase=' ,IFNULL(D.Product,"") ';  END IF;

IF @TotLine="FIRST" THEN SET @PositionTotLine=" Asc"; ELSE SET @PositionTotLine=" Desc"; END IF;

IF @Debug!="NO" THEN SELECT @OnlyOverCap,@GroupByMS,@Product,@GroupBySeleccBase,@View,@WhereOnlyOverCap,@Search,@MS_id; END IF;
IF @Debug!="NO" THEN SELECT @WhereMS_id,@WhereDay,@WhereArea,@WhereOwner,@WhereBrand,@WhereAffiliate_id,@WhereAdv_Account_id,@WherePublisher_id,
                            @JoinOnTag,@WhereAdv_Account,@WhereChannel_id,@WhereProduct,@WherePlatform,@WhereMaster_Affiliate_id,@WhereSearch; END IF;

SET @Kforex=(
   SELECT COUNT(*) FROM `campaign_marketing_source` `M`
   LEFT JOIN `campaign_username` `CU` ON `CU`.`id` = `M`.`Username_id`
   WHERE CU.Area="forex"
);
IF @Debug!="NO" THEN SELECT @Kforex FROM DUAL; END IF;

/**************************************************************************************************************/
-- Script para crear tabla temporal con tags agrupados por Affiliate_id
-- A partir de account_account_tags (A) y account_account_tags_list (L)

-- Eliminar tabla temporal si existe
DROP TABLE IF EXISTS temp_affiliate_tags;
-- Crear tabla temporal con tags agrupados por Affiliate_id
CREATE TABLE temp_affiliate_tags AS
SELECT 
    A.Affiliate_id,
    GROUP_CONCAT(DISTINCT A.Tag_id ORDER BY A.Tag_id SEPARATOR ',') AS Tags_id,
    GROUP_CONCAT(DISTINCT L.Tag ORDER BY L.Tag SEPARATOR ' ') AS Tags_name
FROM account_account_tags A
INNER JOIN account_account_tags_list L ON A.Tag_id = L.id
WHERE A.Status = 1 AND L.Status = 1
GROUP BY A.Affiliate_id;

-- Verificar resultados
IF @Debug!="NO" THEN SELECT * FROM temp_affiliate_tags ORDER BY Affiliate_id; END IF;

/**************************************************************************************************************/
SET @SQLmeta=concat(
' UNION ALL (
SELECT
   "setting" as Meta
   ,if(@Mode="DAILY" OR @MultiMonth=1,"width=100px","omit=true") as date
   ,if(@Area!="" OR @Kforex=0,"omit=true","width=80px") as Area
   -- ,if((LENGTH(@Owner)-LENGTH(REPLACE(@Owner,",",""))=0,"omit=true","width=80px") as Owner_id
   -- ,if(@Owner!="","omit=true","width=80px") as Owner_id
   -- ,if(@Publisher_id!="" OR @Account_id!="" OR @Affiliate_id!="","omit=true","width=110px") as Operator
   -- ,if(@Platform!="" OR @Publisher_id!="" OR @Account_id!="" OR @Brand!="" OR @Affiliate_id!="","omit=true","width=100px") as Platform
   -- ,if(@Brand="","width=120px","width=120px,omit=true") as Brand
   -- ,if(@Account_id="","width=160px","width=160px,omit=true") as Account
   -- ,if(@ReferrerMode!="YES","omit=true","width=160px") as Referrer
   -- ,if(@Affiliate_id="","width=160px","width=160px,omit=true") as Affiliate
   ,"width=80px"    as Owner_id
   ,"width=110px"   as Operator
   ,"width=100px,tooltip=yes"   as Platform
   ,"width=120px"   as Brand
   ,"width=160px"   as Account
   ,if(@ReferrerMode!="YES","omit=true","width=160px") as Referrer
   ,"width=160px,"  as Affiliate
   ,"width=120px,center=true,action=3" as MS_id    -- 15.01.2024
   ,"width=100px" as MS_Status
   ,"width=100px,center=true" as Cap
   ,"width=130px" as Tracker_ID
   ,if(@Product!="" OR @GroupByMS="YES","omit=true","minWidth:100px,maxWidth=400px,width=150px,tooltip=yes") Product
   ,"width=100px"           ProductMS
   ,"width=80px,right=true" cpa
   ,"width=160px,tooltip=yes" Tags
   ,"width=80px,right=true" curr
   ,"width=90px,right=true" nr
   ,"width=90px,right=true" Ge_sum_CPA
   ,"width=90px,right=true" Ge_sum_RS
   ,"width=90px,right=true" Af_sum_CPA
   ,"width=90px,right=true" Af_sum_RS
   ,"width=80px,right=true" Ge_cpa
   ,"width=80px,right=true" Ge_rs
   ,if(@GroupByMS="YES","omit=true","width=80px,right=true") Af_cpa
   ,if(@GroupByMS="YES","omit=true","width=80px,right=true") Af_rs
   ,"width=150px"        -- ,tooltip=yes" Channel
   ,"width=150px"        -- ,tooltip=yes" Tracker_name
   ,"width=100px"        as Cod2Aff
-- ,`FTD`,`Views`,`Clicks`,`Signups`,`CPA`,`Ratio_CPA_SUp`,`Deposits`,`DepCust`,`ActCust`
   ,"width=90px,right=true","width=90px,right=true","width=90px,right=true","width=100px,right=true"
   ,"width=90px,right=true","width=90px,right=true","width=110px,right=true","width=90px,right=true","width=90px,right=true"
   ,"omit=yes"             `Username_id`          -- 10.01.2024
   ,"omit=yes"             `Advertiser_id`        -- 10.01.2024
	,"omit=yes"             `Publisher_id`         -- 15.01.2024
	,"omit=yes"             `Master_Affiliate_id`
	FROM DUAL WHERE @Meta="YES")'
);
-- IF @Debug!="NO" THEN SELECT @SQLmeta; END IF;
/**************************************************************************************************************/

SET @SQL=concat('
WITH Seleccion_base as (
SELECT ',@GroupDateExpr,' as Date
   ,D.Area
   ,D.Owner
   ,D.Brand,D.Username as Account
   ,D.Affiliate
   ,IFNULL(D.MS_id,"missing")    AS MS_id
   ,if(D.MS_id IS NULL,"unknown",M.Status) AS MS_Status
   ,lower(D.Tracker_ID)          as `Tracker_ID`
   ,lower(D.Tracker_Name)        as `Tracker_Name`
   ,D.Code_To_Affiliate          as `Cod2Aff`
   ,lower(D.Product)             as `Product`
   ,lower(M.Product)             as `ProductMS`
	,D.Channel,D.CPA_Limit
   ,SUM(D.Qualified_Players)     as `CPA`
   ,SUM(D.Net_Revenue)           as `NetRev`
	,SUM(D.`Revenue_Share_Gestor`   ) AS `Ge_sum_RS`
	,SUM(D.`Revenue_Share_Affiliate`) AS `Af_sum_RS`
	,SUM(D.`CPA_Value_Gestor`       ) AS `Ge_sum_CPA`
	,SUM(D.`CPA_Value_Affiliate`    ) AS `Af_sum_CPA`
   ,D.Deal_Aff_CPA                as `Af_CPA`
   ,D.Deal_Aff_RS                 as `Af_RS`
   ,D.Deal_Ges_CPA                as `Ge_CPA`
   ,D.Deal_Ges_RS                 as `Ge_RS`
   ,SUM(D.`First_Time_Deposit`)   as `FTD`
   ,SUM(D.`Views`)                as `Views`
   ,SUM(D.`Clicks`)               as `Clicks`
   ,SUM(D.`Signups`)              as `Signups`
   ,(CASE WHEN SUM(D.Signups)>0
          AND SUM(D.`Qualified_Players`)>=5
         THEN ROUND(SUM(D.`Qualified_Players`)/SUM(D.Signups),2)
         ELSE "--" END)           as `Ratio_CPA_SUp`
   ,SUM(D.`Deposits`)             as `Deposits`
   ,SUM(D.`Depositing_Customers`) as `DepCust`
   ,SUM(D.`Active_Customers`)     as `ActCust`
   ,D.Publisher_id
   ,P.Advertiser_Name             as `Operator`
   ,D.Portal                      as `Platform`
   ,D.Username_id                                  -- 10.01.2024
   ,D.Advertiser_id                                -- 10.01.2024
   ,D.Data_Currency
   ,R.Master_Affiliate_id
   ,A1.`username`       as `Master_Affiliate`
   ,lower(ifnull(T.`Tags_name`,"")) as `Tags`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`id` = D.`MS_id` AND D.MS_id is not null
LEFT JOIN campaign_publisher            P ON P.id=D.Publisher_id
LEFT JOIN master_affiliate_deals_per_affiliate R ON @ReferrerMode="YES" and D.Affiliate_id=R.Sub_Affiliate_id
                                                and D.Date between R.Valid_From and IFNULL(R.Valid_To,CURDATE())
LEFT JOIN `account_account`          `A1` ON @ReferrerMode="YES" and `A1`.`id` = R.Master_Affiliate_id
LEFT JOIN temp_affiliate_tags           T ON T.Affiliate_id = D.Affiliate_id
',@JoinOnTag,'
WHERE (@Day != "" OR LEFT(D.Date,7) IN ',@MONTH,')
   AND ((@ReferrerMode="YES" and R.Master_Affiliate_id is not null)
   OR    @ReferrerMode!="YES")
'
   ,@WhereMS_id
   ,@WhereDay
   ,@WhereArea
   -- ,@WhereTag
   ,@WhereOwner
   ,@WhereBrand
   ,@WherePublisher_id
   ,@WhereAffiliate_id
   ,@WhereAdv_Account_id
   ,@WhereAdv_Account
   ,@WhereChannel_id
   ,@WhereProduct
   ,@WhereProductMS
   ,@WherePlatform
   ,@WhereMaster_Affiliate_id
   ,@WhereSearch
   ,'
GROUP BY ',@GroupDateExpr,',D.Area,D.Publisher_id,D.Brand,D.Username,IFNULL(MS_id,0),D.Tracker_ID,D.Tracker_Name',@GroupBySeleccBase,'
ORDER BY ',@GroupDateExpr,',D.Area,P.Advertiser_Name,D.Brand,MS_id
)
(
SELECT '
   ,IF(@Meta="YES","'data' as `Meta`,",""),'
   Date,Area
   ,A.`username` as `Owner`
   ,sb.Operator,Platform,Brand,Account
   ,Master_Affiliate as `Referrer`
   ,Affiliate
   ,MS_id
   ,MS_Status AS Status
   ,CASE sb.CPA_Limit>0
         WHEN CPA/sb.CPA_Limit>=0.8 THEN concat(sb.CPA_Limit,"/",ROUND(CPA/sb.CPA_Limit*100,0),"%")
         ELSE "" END  as `Cap/Used`
   ,Tracker_ID
   ,Product
   ,ProductMS as `Product MS`
   ,CPA
   ,Tags
   ,Data_Currency `Currcy`
   ,NetRev
   ,Ge_sum_CPA   `Ge_CPA Total`
   ,Ge_sum_RS    `Ge_RS Total`
   ,Af_sum_CPA   `Af_CPA Total`
   ,Af_sum_RS    `Af_RS Total`
   ,Ge_CPA       `Ge_CPA Deal`
   ,Ge_RS        `Ge_RS Deal`
   ,Af_CPA       `Af_CPA Deal`
   ,Af_RS        `Af_RS Deal`
   ,Channel,Tracker_Name,Cod2Aff
   ,`FTD`,`Views`,`Clicks`
   ,`Signups`
   ,CPA
   ,`Ratio_CPA_SUp` as "Ratio CPA/SUp"
   ,`Deposits`,`DepCust`,`ActCust`
   ,sb.Username_id
   ,Advertiser_id                      -- 10.01.2024
   ,Publisher_id                       -- 15.01.2024
   ,Master_Affiliate_id
FROM Seleccion_base sb
LEFT JOIN `account_account` `A` ON `A`.`id` = sb.Owner
WHERE 1=1',@WhereOnlyOverCap,@WhereBigCPA_SUp,'
)
UNION ALL
(
SELECT
--  Date,Owner,Publisher,Platform,Advertiser,Account,Master_Affiliate,Affiliate
  ',IF(@Meta="YES","'total' as `Meta`,",""),'
   " ~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~TOTALS~~~~~"
-- ,MS_id,Tracker_ID,Product
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,SUM(CPA)
   ,"~~~~~"
   ,Data_Currency
   ,SUM(NetRev)
   ,SUM(Ge_sum_CPA)
   ,SUM(Ge_sum_RS )
   ,SUM(Af_sum_CPA)
   ,SUM(Af_sum_RS )
-- ,Af_CPA,Af_RS
   ,"~~~~~"
   ,"~~~~~"
-- ,Ge_CPA,Ge_RS
   ,"~~~~~","~~~~~"
-- ,Channel,Tracker_Name,Cod2Aff
   ,"~~~~~"
   ,"~~~~~"
   ,"~~~~~"
   ,SUM(`FTD`) as FTD,SUM(`Views`) as Views,SUM(`Clicks`) as Clicks,SUM(`Signups`) as Signups
   ,SUM(CPA)
   ,"~~~~~"
   ,SUM(`Deposits`) as Deposits,SUM(`DepCust`) as DepCust,SUM(`ActCust`) as ActCust
   ,"~~~~~"              -- 10.01.2024
   ,"~~~~~"              -- 10.01.2024
   ,"~~~~~"              -- 15.01.2024
   ,"~~~~~"
FROM Seleccion_base sb   -- K: 10.10.2024
WHERE @Total="YES"'
,@WhereOnlyOverCap,@WhereBigCPA_SUp,'
GROUP BY Data_Currency
)'
,IF(@Meta="YES",@SQLmeta,""),'
ORDER BY Date',@PositionTotLine,',convert(`CPA`,signed) DESC;');

-- -------------FILTERS----------------------------------------------
SET @SQLfilterDay='';
IF @Mode="DAILY" THEN
   SET @SQLfilterDay=CONCAT('(SELECT "01","Day",DATE_FORMAT(`date`,"%Y-%m-%d"),"^Day",DATE_FORMAT(`date`,"%Y-%m-%d"),"" AS K FROM DayFilter WHERE LEFT(`date`,7) IN ',@MONTH,') UNION ALL ');
END IF;

SET @SQLfilters=CONCAT('
WITH RECURSIVE MonthFilter AS (
  SELECT  CURDATE() AS date
  UNION ALL
  SELECT DATE_SUB(date, INTERVAL 1 MONTH) FROM MonthFilter
  WHERE DATE_SUB(date, INTERVAL 1 MONTH) >= DATE_SUB(CURDATE(), INTERVAL 23 MONTH)
  		and DATE_SUB(date, INTERVAL 1 MONTH) >= "2022-01-01"
),
DayFilter AS (
  SELECT CAST(DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 23 MONTH), "%Y-%m-01") AS DATE) AS date
  UNION ALL
  SELECT DATE_ADD(date, INTERVAL 1 DAY) FROM DayFilter
  WHERE DATE_ADD(date, INTERVAL 1 DAY) <= CURDATE()
  		and DATE_ADD(date, INTERVAL 1 DAY) >= "2022-01-01"
),
BaseCount AS (
SELECT DATE(D.Date) as Date,Area
   ,D.Owner
   ,A.`username` as `Owner_name`
   ,D.Brand as Brand
   ,D.Username as Account
   ,D.Affiliate as Affiliate
   ,IFNULL(MS_id,"missing") AS MS_id
	,D.Tracker_ID
	,D.Tracker_Name
	,D.Code_To_Affiliate as Cod2Aff
	,D.Channel
   ,if(@Product!="" OR @GroupByMS="YES","",D.Product) as `Product`
   ,lower(M.Product)             as `ProductMS`
   -- ,SUM(Qualified_Players) as CPA,SUM(Net_Revenue) as NetRev,Deal_Aff_CPA as `Af_CPA`,Deal_Aff_RS as `Af_RS`
   ,D.Username_id
   ,D.Affiliate_id
   ,D.Advertiser_id
   ,IFNULL(D.`Channel_id`,"") as `Channel_id`
   ,IFNULL(D.`Publisher_id`,"") as `Publisher_id`
   ,IFNULL(P.`Advertiser_Name`,"") as `Operator`
   ,IFNULL(Portal,"") as Platform
   ,R.Master_Affiliate_id
   ,A1.`username`       as `Master_Affiliate`
   ,ifnull(T.`Tag_id`,0) as `Tag_id`
   ,ifnull(TL.`Tag`,"") as `Tag`
FROM Snapshot_day_by_day_fact1 D
LEFT JOIN `campaign_marketing_source` `M` ON `M`.`id` = D.`MS_id` AND D.MS_id is not null
LEFT JOIN campaign_publisher           P ON P.id=D.Publisher_id
LEFT JOIN `account_account`           `A` ON `A`.`id` = D.Owner
LEFT JOIN master_affiliate_deals_per_affiliate R ON @ReferrerMode="YES" and D.Affiliate_id=R.Sub_Affiliate_id
                                                and D.Date between R.Valid_From and IFNULL(R.Valid_To,CURDATE())
LEFT JOIN `account_account`           `A1` ON @ReferrerMode="YES" and `A1`.`id` = R.Master_Affiliate_id
LEFT JOIN `account_account_tags`      `T`  ON `T`.`Affiliate_id` = `D`.`Affiliate_id` -- and `T`.`Tag_id` is not null
LEFT JOIN `account_account_tags_list` `TL` ON `TL`.`id` = `T`.`Tag_id` and `TL`.`Status` = 1 and `T`.`Tag_id` is not null

WHERE (@Day != "" OR LEFT(D.Date,7) IN ',@MONTH,')
   AND ((@ReferrerMode="YES" and R.Master_Affiliate_id is not null)
   OR    @ReferrerMode!="YES")
'
   ,@WhereMS_id
   ,@WhereDay
   ,@WhereArea
   -- ,@WhereTag
   ,@WhereOwner
   ,@WhereBrand
   ,@WherePublisher_id
   ,@WhereAffiliate_id
   ,@WhereAdv_Account_id
   ,@WhereAdv_Account
   ,@WhereChannel_id
   ,@WhereProduct
   ,@WhereProductMS
   ,@WherePlatform
   ,@WhereMaster_Affiliate_id
   ,@WhereSearch
   ,'
GROUP BY DATE(D.Date),IFNULL(D.Owner,""),IFNULL(D.Publisher_id,""),IFNULL(R.Master_Affiliate_id,"")
   ,IFNULL(Platform,""),IFNULL(D.Brand,"")
   ,IFNULL(D.Username,""),IFNULL(MS_id,0),IFNULL(D.Tracker_ID,""),IFNULL(D.Tracker_Name,"")'
   ,@GroupBySeleccBase,'
   ,IFNULL(D.Affiliate,""),IFNULL(D.CHANNEL,""),IFNULL(T.`Tag`,"")
)
-- SELECT LEFT(DATE,7) AS month_year FROM MonthFilter ORDER BY DATE desc;

(SELECT "00" as "Korder","Month" AS "Key",LEFT(`date`,7) AS "Value","^Month" AS `CallKey`,LEFT(`date`,7) AS `CallValue`
                                                                         ,"" AS "Rows" FROM MonthFilter GROUP BY LEFT(`date`,7)) UNION ALL
',@SQLfilterDay,'
(SELECT "02","Option"     ,"Show MS by product","GroupByMS"    ,"NO"     ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "02","Option"     ,"Ratio CPA/SUp>0.6","OnlyBigCPA_SUp","YES"    ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "02","Option"     ,"Referrer Mode","referrermode","YES"          ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "03","Area"       ,`Area`       ,"Area"         ,`Area`          ,"" AS K       FROM BaseCount WHERE @Kforex>0 AND `Area`>" " GROUP BY IFNULL(`Area`,"")) UNION ALL
(SELECT "07","Referrer"   ,`Master_Affiliate`  ,"Master_Affiliate_id"    ,`Master_Affiliate_id`  ,COUNT(*) AS K FROM BaseCount
               WHERE @ReferrerMode="YES" and `Master_Affiliate_id` is not null GROUP BY IFNULL(`Master_Affiliate_id`  ,"")) UNION ALL
(SELECT "09","Operator"  ,`Operator`  ,"^Publisher_id" ,`Publisher_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Operator`  >" " GROUP BY IFNULL(`Operator`  ,"")) UNION ALL
(SELECT "13","Brand" 	  ,`Brand` 	    ,"^Brand"        ,replace(Brand," ","!")
                                                                         ,COUNT(*) AS K FROM BaseCount WHERE `Brand` >" "      GROUP BY IFNULL(`Brand` ,""))      UNION ALL
(SELECT "16","Account"    ,`Account`    ,"^Account"      ,replace(Account," ","!")
                                                                         ,COUNT(*) AS K FROM BaseCount WHERE `Account`    >" " GROUP BY IFNULL(`Account`    ,"")) UNION ALL
(SELECT "19","Affiliate"  ,`Affiliate`  ,"^Affiliate_id" ,`Affiliate_id`  ,COUNT(*) AS K FROM BaseCount WHERE `Affiliate`  >" " GROUP BY IFNULL(`Affiliate`  ,"")) UNION ALL
(SELECT "20","Tag"        ,`Tag`        ,"^Tag"          ,`Tag_id`        ,COUNT(*) AS K FROM BaseCount WHERE `Tag`>"" GROUP BY `Tag`) UNION ALL
(SELECT "30","Channel"    ,`Channel`    ,"^Channel_id"   ,`Channel_id`    ,COUNT(*) AS K FROM BaseCount WHERE `Channel`    >" " GROUP BY IFNULL(`Channel`    ,"")) UNION ALL
(SELECT "32","ProductMS"  ,`ProductMS`  ,"^ProductMS"    ,`ProductMS`     ,COUNT(*) AS K FROM BaseCount WHERE `ProductMS`  >" " GROUP BY IFNULL(`ProductMS`  ,"")) UNION ALL
(SELECT "33","Product"    ,`Product`    ,"^Product"      ,replace(Product," ","!"),COUNT(*) AS K FROM BaseCount WHERE `Product`    >" " GROUP BY IFNULL(`Product`    ,"")) UNION ALL
(SELECT "38","Platform"   ,`Platform`   ,"^Platform"     ,`Platform`      ,COUNT(*) AS K FROM BaseCount WHERE `Platform`   >" " GROUP BY IFNULL(`Platform`   ,"")) UNION ALL
(SELECT "40","Owner"      ,`Owner_name` ,"^Owner"        ,`Owner`         ,COUNT(*) AS K FROM BaseCount WHERE `Owner`      >" " GROUP BY IFNULL(`Owner`      ,""))
-- ORDER BY 1,3
ORDER BY 1, case when `CallKey` IN ("^Month","^Day") then `CallValue` else "" end desc, 3 ASC
;');

IF @Debug!="NO" THEN SELECT @SQLfilters; END IF;
IF @Debug!="NO" THEN SELECT @SQL,@SQLmeta; END IF;

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQL;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

END$$
DELIMITER ;

/*
call Gestor_MonthlySources('');              -- Todos los valores de selección por default
call Gestor_MonthlySources('debug=ye');      -- Todos los valores de selección por default usando debug
call Gestor_MonthlySources('^owner=864^865,^affiliate_id=39^130^850,debug=ye');
call Gestor_MonthlySources('^owner=865,^affiliate_id=39^130^850,debug=ye');
call Gestor_MonthlySources('filters=yes,debug=ye');
call Gestor_MonthlySources('^day=^2025-12-01^2025-12-02,debug=ye');
call Gestor_MonthlySources('^owner=864^865,^Brand=LeoVegas^Lottomatica^PlanetWin365,debug=ye');
call Gestor_MonthlySources('^owner=864,^Brand=LeoVegas^Lottomatica^PlanetWin365,debug=ye');
call Gestor_MonthlySources('^affiliate_id=39^506^450,filters=yes,debug=ye');
call Gestor_MonthlySources('^tag=1^2^3,filters=ye,debug=ye');

*/
