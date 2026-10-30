/*
PROCEDURE_Dash_BrandMatrix.sql() - CPA/Signup/FTD/Click/Comms - Matriz por Brand

Descripción:
  Procedimiento Dash_BrandMatrix.
  Matrices CPA/Signup/FTD/Click/NR desde Snapshot_day_by_day_fact* (CPA=`Qualified_Players`).
  Matrices net_CPA_Val/net_RS_Val/net_Total_comm desde monthly_comms_*_v5.

Observaciones:

Cada Key debe estar seguida de = y el valor deseado SIN comillas (ni simples ' ni dobles ")
Cada par Key=Value de estar seguidO por una COMA
El conjunto de pares [Key=Value] debe ir entre '' (comillas simples) porque forman UN UNICO PARAMETRO string de entrada para el PROCEDURE.

Keys:
InputCommLine = [valor]. Parámetro de entrada.

View            =[viewAFF | viewGES | viewMAF]. Datos de Fact2/Fact1/Fact3 respectivamente. OBLIGATORIO.
Month           =[AAAA-MM]. OPCIONAL. Default=Current Month día>=6. Last Month día<6
MatrixBy        =[CPA | net_CPA_Val | net_RS_Val | net_Total_comm | Signup | FTD | Click | NR ].
                  OPCIONAL. Default=CPA.
                  CPA/Signup/FTD/Click/NR desde Snapshot (CPA=`Qualified_Players`).
                  net_* desde monthly_comms_affiliate_v5 (ViewAFF) o monthly_comms_gestor_v5 (ViewGES).
                  ViewMAF no admite matrices net_* (fallback Signup).
                  En ViewAFF, net_RS_Val y net_Total_comm solo si Check_RS_affiliate(Affiliate_id)=1.
MasterAff_id    =[ MasterAff_id ]. SOLO PARA MODO viewMAF. Default=''
Affiliate_id    =[ALL | id del Affiliate_id | ALLdetail]. ALLdetail=All en secuencia continua
                  OPCIONAL para View=viewGES (Default=ALL).
                  OBLIGATORIO para View=viewAFF
Advertiser_id   =[ALL | id del Advertiser_id]. OPCIONAL. Default=ALL
ByDay           =[No | Yes]. Info acumulada por Dia/Mes. OPCIONAL. Default=No.
                  Se fuerza No para matrices desde monthly_comms_*.
LastMonths      =[No | Yes]. Info acumulada LastMonths. OPCIONAL. Default=No
Owner           =[ALL | id del Owner]. OPCIONAL. Default=ALL
Total           =[Yes | No]. Incluye línea/s de Totales x OWNER/Currency. OPCIONAL. Default=Yes
TotLine         =[First | Last]. Posición de la línea de Totales. OPCIONAL. Default=First
Meta            =[No | Yes]. [No] OPCIONAL. Coluna 1 como METADATO: total/data/setting
Filters         =[Yes | No]. Devuelve la lista de filtros. OPCIONAL. Default=no.
Debug           =[No | Yes | KeyValues]. [No] NO EJECUTA QUERY y devuelve el código del Query.
                  [KeyValues] EJECUTA QUERY y devuelve KeyValues del Query. OPCIONAL. Default=No

Keys no utilizadas:
Currency        =[EUR | Original]. Moneda a la que se convierten los resultados. Original=No hacer conversiones. El Profit NO SE CALCULARÁ cuando sean monedas distintas. OPCIONAL. Default=EUR.
ByAccount       =[No | Yes]. Info acumulada por Account/Advertiser. OPCIONAL. Default=No
OrderBy         =[CPA | CPAvalue | Profit | Advertiser]. OPCIONAL. Default=Affiliate
Order           =[Desc | Asc]. OPCIONAL. Default=Desc

Parámetros ('[Key=Value[,...]']')

Ejemplos:

call Dash_BrandMatrix('View=VIEWGES');
call Dash_BrandMatrix('View=VIEWGES,MatrixBy=CPA,meta=yes,debug=no');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=39,Month=LM,MatrixBy=net_Total_comm');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=ALL,Month=LM,MatrixBy=net_CPA_Val');
call Dash_BrandMatrix_dev('View=ViewAFF,Affiliate_id=13,MatrixBy=CPA,meta=yes');
call Dash_BrandMatrix_dev('View=ViewAFF,Affiliate_id=13,MatrixBy=CPA,meta=yes');
call Dash_BrandMatrix('View=ViewAFF,Affiliate_id=39,MatrixBy=net_RS_Val,meta=yes');
call Dash_BrandMatrix('View=ViewAFF,Affiliate_id=39,MatrixBy=net_Total_comm,filters=yes');
call Dash_BrandMatrix('View=ViewAFF,Affiliate_id=39,ByDay=yes,MatrixBy=ftd,meta=yes');
call Dash_BrandMatrix('View=ViewGES,Owner=2,Month=2022-08,MatrixBy=Signup');

04.09.2022 V1     Total_FACT1_AFFILIATE_CPAbyDay_BrandMatrix
08.09.2022 V2     FACT1/2 Como parámetro + Currency. Unifica acumulaciones de CPA
26.09.2022 V2.2   Optimización
26.09.2022 V3     Recodificacion de PROCEDURE_Dash_BrandMatrix.
                  Parámetros con Key=Value en un solo campo de entrada como CommandLine
07.10.2022 v3.2   Columna METAdatos
25.10.2022 v3.3   Nombres Columnas Brand Matrix Separados en las mayúsculas con Regex
02.11.2022        Retorna con mensaje cuando no hay CPAs en la selección
16.11.2022 v3.4   Agregado parámetro MatrixBy=[CPA | Signup | FTD | Click ]. OPCIONAL. Default=CPA
03.01.2023 v1.1   Filters
12.05.2023 v1.2   @Month='CM'/'LM'
12.05.2023 v1.3   Agregado NR
31.05.2023 v1.4   Karen - filtro por Advertiser_id
09.08.2023 v1.5   Agregado Total Comission a la matriz. Fixes en columna total
04.09.2023 v1.6   Karen. Se agregó variable setting cuando no existe resultados
16.01.2024 v1.7   Habilitada selección por Afiliado
27.05.2024 v1.8   Tratamiento de Subafiliados
                  Tratamiento de Master Affiliate
29.05.2024 v1.9   Opción LastMonths
06.08.2024 v2     Multi-currency
11.08.2024 v2.1   fix Multi-currency
13.09.2024 v2.2   No agrupa por Owner
26.11.2024 V2.3   Reporte por dia todos los afiliados. Parametro ALLdetail
06.03.2025 v2.3.1 Fix mostrando datos ByDay
31.12.2025 v2.3.2 Agregado parámetro Graph para mostrar imágenes de las marcas
07.04.2026 v2.3.3 Restaurdo filtro por Net_Revenue<>0
04.08.2026 v2.3.4 Matrices CPA/net_CPA_Val/net_RS_Val/net_Total_comm desde monthly_comms_*_v5.
                  Eliminadas CPA y Commission desde Snapshot. Filtros RS en ViewAFF
                  condicionados a Check_RS_affiliate=1.
05.08.2026 v2.3.5 CPA vuelve a Snapshot (`Qualified_Players`); net_* siguen en monthly_comms_*_v5.
*/

-- DROP PROCEDURE IF EXISTS Dash_BrandMatrix_dev;
DROP PROCEDURE IF EXISTS Dash_BrandMatrix;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Dash_BrandMatrix`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'v2.3.5 05.08.2026 - CPA/Comms/Reg/FTD/Click/NR - Matriz por Brand'
    SQL SECURITY DEFINER

proc_label:BEGIN
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version      ='v2.3.5 05.08.2026';
SET @View         ='VIEWAFF';
SET @Owner        ='ALL';
SET @Month        =IF(DAY(CURDATE())<=5,LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7),LEFT(CURDATE(),7));
SET @MatrixBy     ='CPA';
SET @Affiliate_id ='ALL';
SET @MasterAff_id ='';
SET @LastMonths   ='NO';
SET @Currency     ='EUR';
SET @OrderBy      ='CPA';
SET @Order        ='DESC';
SET @Total        ='YES';
SET @TotLine      ='FIRST';
SET @Debug        ='NO';
SET @Meta         ='YES';
SET @ByDay        ='no';
SET @Advertiser_id='ALL';
SET @ByAccount    ='NO';
SET @Filters      ='NO';
SET @UseComms     ='NO';
SET @MetricField  ='Qualified_Players';
SET @MetricLabel  ='Total CPA';
SET @BrandCond    ='';
SET @ShowRS       ='NO';

SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

WHILE @InputCommLine>' ' DO
   SET @e=INSTR(@InputCommLine,'=');
   SET @c=INSTR(@InputCommLine,',');
   SET @k=SUBSTRING(@InputCommLine,1,@e-1);
   SET @v=SUBSTRING(@InputCommLine,@e+1,@c-(@e+1));
   SET @InputCommLine=SUBSTRING(@InputCommLine,@c+1);
   SET @k=TRIM(@k);
   SET @v=TRIM(@v);

   IF lower(@k)='owner'         THEN SET @Owner        =UPPER(@v); END IF;
   IF lower(@k)='month'         THEN SET @Month        =UPPER(@v); END IF;
   IF lower(@k)='matrixby'      THEN SET @MatrixBy     =UPPER(@v); END IF;
   IF lower(@k)='masteraff_id'  THEN SET @MasterAff_id =UPPER(@v); END IF;
   IF lower(@k)='lastmonths'    THEN SET @LastMonths   =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id' THEN SET @Advertiser_id=UPPER(@v); END IF;
   IF lower(@k)='currency'      THEN SET @Currency     =UPPER(@v); END IF;
   IF lower(@k)='byaccount'     THEN SET @ByAccount    =UPPER(@v); END IF;
   IF lower(@k)='orderby'       THEN SET @OrderBy      =UPPER(@v); END IF;
   IF lower(@k)='order'         THEN SET @Order        =UPPER(@v); END IF;
   IF lower(@k)='total'         THEN SET @Total        =UPPER(@v); END IF;
   IF lower(@k)='totline'       THEN SET @TotLine      =UPPER(@v); END IF;
   IF lower(@k)='debug'         THEN SET @Debug        =UPPER(@v); END IF;
   IF lower(@k)='view'          THEN SET @View         =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'  THEN SET @Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='byday'         THEN SET @ByDay        =UPPER(@v); END IF;
   IF lower(@k)='meta'          THEN SET @Meta         =UPPER(@v); END IF;
   IF lower(@k)='filters'       THEN SET @Filters      =UPPER(@v); END IF;

END WHILE;

IF @Debug!="NO" THEN SELECT @Owner,@Month,@LastMonths,@Currency,@Advertiser_id,@ByAccount,@Debug,@Total,@TotLine
                           ,@OrderBy,@Order,@View, @MatrixBy ,@Affiliate_id,@ByDay,InputCommLine; END IF;

IF @Owner="ALL" THEN SET @WhereOwner=' ';
ELSE SET @WhereOwner=CONCAT(" AND Owner='",@Owner,"'"); END IF;

IF @Month='CM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 0 MONTH),7); END IF;
IF @Month='LM' THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

-- ----------------------------------------------------
-- TRATAMIENTO DE PERIODO DE REPORTE ------------------
-- ----------------------------------------------------
SET @PastMonths=LEFT(DATE_SUB(CURDATE(), INTERVAL 6 MONTH),7);

IF   @LastMonths='YES'
THEN SET @Month_Report=@PastMonths;
     SET @Compare=">=";
ELSE SET @Month_Report=@Month;
     SET @Compare="=";
END IF;

IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@Currency); END IF;

/**************************************************************************************************************/

-- Validación
IF   @Affiliate_id IN ("","ALL","ALLdetail") AND @View='VIEWAFF'
THEN
    Select 'data' as Meta,'Affiliate_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;

-- Matrices de comisión (net_*) vs Snapshot (CPA/Signup/FTD/Click/NR)
SET @UseComms=IF(@MatrixBy IN ('NET_CPA_VAL','NET_RS_VAL','NET_TOTAL_COMM'),'YES','NO');

-- ViewMAF no admite matrices net_*: fallback a Signup
IF @View='VIEWMAF' AND @UseComms='YES' THEN
   SET @MatrixBy='SIGNUP';
   SET @UseComms='NO';
END IF;

-- Filters: afiliados/brands desde Snapshot (UI); opciones MatrixBy sí incluyen comms/RS
IF @Filters='YES' THEN
   SET @UseComms='NO';
END IF;

-- Gate RS en ViewAFF (solo ejecución de datos, no Filters)
IF @Filters!='YES'
   AND @View='VIEWAFF'
   AND @MatrixBy IN ('NET_RS_VAL','NET_TOTAL_COMM')
   AND IFNULL(Check_RS_affiliate(CAST(@Affiliate_id AS UNSIGNED)),0)=0
THEN
    Select 'data' as Meta,'RS matrices not available for affiliate' as '' from dual;
    LEAVE proc_label;
END IF;

-- Métricas mensuales: sin ByDay
IF @UseComms='YES' THEN
   SET @ByDay='NO';
   SET @MetricField=CASE @MatrixBy
      WHEN 'NET_CPA_VAL'    THEN 'net_CPA_Val'
      WHEN 'NET_RS_VAL'     THEN 'net_RS_Val'
      WHEN 'NET_TOTAL_COMM' THEN 'net_Total_comm'
      ELSE 'net_CPA_Val'
   END;
   SET @MetricLabel=CASE @MatrixBy
      WHEN 'NET_CPA_VAL'    THEN 'Total CPA Value'
      WHEN 'NET_RS_VAL'     THEN 'Total Rev Share'
      WHEN 'NET_TOTAL_COMM' THEN 'Total Commission'
   END;
   SET @BrandCond='(CPA<>0 OR net_CPA_Val<>0 OR net_RS_Val<>0 OR net_Total_comm<>0)';
ELSE
   SET @MetricField='Qualified_Players';
   SET @MetricLabel='Total CPA';
   SET @BrandCond='(Qualified_Players<>0 OR Signups<>0 OR First_Time_Deposit<>0 OR Net_Revenue<>0)';
END IF;

-- 31.05.2023 Karen
IF @Advertiser_id="ALL" THEN
     SET @WhereAdvertiser_id=' ';
ELSE SET @WhereAdvertiser_id=CONCAT(' AND Advertiser_id=',@Advertiser_id);
END IF;

-- ----------------------------------------------------
SET @Order_by=' ORDER BY Date ';
SET @Group_by=' GROUP BY xDate ';
-- ----------------------------------------------------
IF @View='VIEWGES' THEN
   IF @Affiliate_id="ALLdetail"
   THEN SET @Group_by=' GROUP BY xAffiliate,xDate ';
        SET @ByDay='YES';
        SET @Order_by=' ORDER BY Affiliate,Date ';
        -- ALLdetail implica ByDay; si UseComms, ByDay no aplica → forzar agrupación mensual
        IF @UseComms='YES' THEN
           SET @ByDay='NO';
           SET @Group_by=' GROUP BY LEFT(Date,7),xAffiliate ';
        END IF;
   END IF;
   IF @Affiliate_id="ALL"
   THEN  SET @Order_by=' ORDER BY Affiliate,Date ';
         IF @ByDay='YES'
         THEN SET @Group_by=' GROUP BY Date,xAffiliate ';
         ELSE SET @Group_by=' GROUP BY LEFT(Date,7),xAffiliate ';
         END IF;
   END IF;
END IF;

-- ----------------------------------------------------
SET @FlagAll=if(@Affiliate_id="ALL","1","0");
-- ----------------------------------------------------

/************ TRATAMIENTO DE SUBAFILIADOS ******************************************/
SET @AffiliateGroup=(SELECT group_id FROM account_account_groups
                     WHERE account_id=@Affiliate_id AND group_id=6);
IF  @AffiliateGroup IS NULL THEN SET @AffiliateGroup=0; END IF;
/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET @MasterAffGroup=(SELECT group_id FROM account_account_groups
                     WHERE account_id=@MasterAff_id AND group_id=4);
IF  @MasterAffGroup IS NULL THEN SET @MasterAffGroup=0; END IF;

SET  @Affiliate_list="";
IF   @MasterAffGroup = 4
THEN CALL Master_Sub_Affiliate(@MasterAff_id, @Affiliate_list);
ELSE SET @Affiliate_list=CONCAT("(",@Affiliate_id,")");
END IF;

/*---------------------------------------------------------------------------------*/

IF @Debug!="NO" THEN SELECT @Affiliate_id,@AffiliateGroup,@MasterAff_id,@MasterAffGroup,@Affiliate_list
                           ,@UseComms,@MetricField,@MetricLabel; END IF;

IF   @View="VIEWMAF" AND @MasterAffGroup!=4
THEN
    Select 'data' as Meta,'MasterAff_id must be MAF' as '' from dual;
    LEAVE proc_label;
END IF;

SET  @WhereAffiliate_id=CONCAT(' AND Affiliate_id=',@Affiliate_id);

IF   @View='VIEWGES'
THEN IF @Affiliate_id in ("ALL","ALLdetail") THEN SET @WhereAffiliate_id=""; END IF;
END IF;

IF   @View='VIEWMAF'
THEN IF  @Affiliate_id="ALL"
     THEN SET @WhereAffiliate_id=CONCAT(' AND Affiliate_id IN ',@Affiliate_list);
     END IF;
END IF;

-- Tabla de datos: monthly_comms (subquery con alias) o Snapshot
SET @DataTable=" ";
SET @FromAlias="F";
IF @UseComms='YES' THEN
   SET @FromAlias="mc";
   IF @View='VIEWAFF' THEN
      SET @DataTable=CONCAT(
         '(SELECT `Owner`,`Month` AS `Date`,`Affiliate`,`Currency` AS `Data_currency`,`Brand`,'
         ,'`Affiliate_id`,`Advertiser_id`,`CPA`,`net_CPA_Val`,`net_RS_Val`,`net_Total_comm` '
         ,'FROM `monthly_comms_affiliate_v5`) AS mc '
      );
   END IF;
   IF @View='VIEWGES' THEN
      SET @DataTable=CONCAT(
         '(SELECT `Owner`,`Month` AS `Date`,`Username` AS `Affiliate`,`Data_Currency` AS `Data_currency`,`Brand`,'
         ,'`Username_id` AS `Affiliate_id`,`Advertiser_id`,`CPA`,`net_CPA_Val`,`net_RS_Val`,`net_Total_comm` '
         ,'FROM `monthly_comms_gestor_v5`) AS mc '
      );
   END IF;
ELSE
   IF   @View='VIEWGES' THEN SET @DataTable="Snapshot_day_by_day_fact1 ";     END IF;
   IF   @View='VIEWAFF' THEN SET @DataTable="Snapshot_day_by_day_fact2 ";     END IF;
   IF   @View='VIEWAFF' AND @AffiliateGroup
                        THEN SET @DataTable="sub_Snapshot_day_by_day_fact3 "; END IF;
   IF   @View='VIEWMAF' THEN SET @DataTable="sub_Snapshot_day_by_day_fact3 "; END IF;
END IF;

/*******************************************************************************/
SET SESSION group_concat_max_len = 200000;

SET @SQLbrands=CONCAT('
    SET @Check_Brands=(SELECT COUNT(DISTINCT Brand) FROM ',@DataTable,'
    WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'" ',@WhereAffiliate_id,'
    AND ',@BrandCond,');'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLbrands;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

IF ifnull(@Check_Brands,0)=0 THEN
    Select 'Not enough data to show' from dual;
    LEAVE proc_label;
END IF;

-- ----------------------------------------------------------------------------------------------------------

SET @SQLmat=CONCAT('
    SET @SQLwrkMatrix=(
    SELECT GROUP_CONCAT(CONCAT("\r\nSUM(CASE WHEN Brand=\'", Brand,"\' THEN `',@MetricField,'` ELSE 0 END) AS \'"
   ,REGEXP_REPLACE(Brand,"([A-Z]+)"," $1",4,0,"c"),"\'") ORDER BY Brand)
    FROM (
       SELECT DISTINCT `Brand` FROM ',@DataTable,'
       WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'" ',@WhereAffiliate_id,'
       AND ',@BrandCond,'
			 order by 1
    ) AS xx);'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLmat;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;


-- K 29.12.2025
SET @urlBase = 'https://storage.googleapis.com/affiliatteaccess.appspot.com/assets/img/pippo/';

SET @SQLmet=CONCAT('
    SET @SQLwrkMatrixMeta=
    (SELECT GROUP_CONCAT(
			CONCAT(
            "\'width=130px,center=true,headerImg=",
            @urlBase,
            LOWER(REPLACE(TRIM(Brand)," ","")),
            ".jpg\'"
        )
		)
    FROM (
       SELECT DISTINCT Brand FROM ',@DataTable,'
       WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'" ',@WhereAffiliate_id,'
       AND ',@BrandCond,'
			 order by 1
    ) AS xx);'
);

IF @Debug!="YES" THEN
   PREPARE stmt1 FROM @SQLmet;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;

-- ----------------------------------------------------------------------------------------------------------

IF @Debug!="NO" THEN SELECT @View,@AffiliateGroup,@DataTable
                           ,@MasterAff_id,@MasterAffGroup
                           ,@Affiliate_list,@WhereAffiliate_id
                           ,@Check_Brands,@SQLbrands,@SQLmat,@SQLmet
                           ,@SQLwrkMatrix,@SQLwrkMatrixMeta; END IF;


-- ----------------------------------------------------------------------------------------------------------

SET @SQLmeta=concat(
'(
SELECT
   "setting" as `Meta`
   ,"omit=true"                                          as `Owner`
   ,"width=100px"                                        as `Date`
   ,IF(@View="VIEWGES","width=150px","omit=true")        as `Affiliate`
   ,IF(@MultiCurrency="YES","width=080px","omit=true")   as `Op Curr`
   ,"width=120px,right=true"                             as `Total`,'
   ,@SQLwrkMatrixMeta,'
   ,"width=100px,omit=true"                              as Total1
   ,"omit=yes"                                           as `Affiliate_id`
	FROM DUAL WHERE @Meta="YES")'
);

SET @SQLwrkTotal=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'total' as `Meta`,",""),'
    Owner
    ,""                                      as `Date`
    ," ~~TOTAL~~"                            as `Affiliate`
    ,Data_currency                           as `Op Curr`
   ,SUM(`',@MetricField,'`)                 AS `',@MetricLabel,'`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(`',@MetricField,'`)           AS `',@MetricLabel,'1` \r\n
   ,`Affiliate_id`
   FROM '
   ,@DataTable,' WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAdvertiser_id,'\r\n'
   );

SET @SQLwrkDetail=CONCAT(
   '(
    SELECT '
    ,IF(@Meta="YES","'data' as `Meta`,",""),'
    Owner
   ,IF("',@ByDay,'"="YES",Date,LEFT(Date,7)) as `xDate`
   ,IF("',@Affiliate_id,'"="ALL",if("',@ByDay,'"="YES","ALL",',@FromAlias,'.Affiliate),',@FromAlias,'.Affiliate) as `xAffiliate`
   ,Data_currency                           as `Op Curr`
   ,SUM(`',@MetricField,'`) AS `Total`,'
   ,@SQLwrkMatrix
   ,',\r\nSUM(`',@MetricField,'`) AS `Total1` \r\n
   ,`Affiliate_id`
   FROM '
   ,@DataTable
   ,IF(@UseComms='YES','',' F'),' WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAdvertiser_id,'\r\n'
   ,@Group_by,' HAVING SUM(`',@MetricField,'`)<>0
   )');
--
SET @SQLcheckTotal=CONCAT(
   'SELECT SUM(`',@MetricField,'`) INTO @Kreg FROM '
   ,@DataTable,' WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAdvertiser_id);

SET @SQLnodataTotal='SELECT "data" as `Meta`,"No data to show" as "" FROM DUAL
UNION ALL SELECT "setting" as `Meta`, "omit=true"  FROM DUAL';
--
IF @Debug!="NO" THEN SELECT @Debug,@View,@Month_Report,@Affiliate_id
                           ,@SQLmeta,@SQLwrkTotal,@SQLwrkDetail,@SQLcheckTotal; END IF;

-- Snapshot: reemplazo de métrica (comms ya usa @MetricField)
IF @MatrixBy='SIGNUP' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Signups");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Signups");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Signups");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Signups");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total Signups");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total Signups");
END IF;

IF @MatrixBy='FTD' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","First_Time_Deposit");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","First_Time_Deposit");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total FTD");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total FTD");
END IF;

IF @MatrixBy='CLICK' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Clicks");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Clicks");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Clicks");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Clicks");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Total Clicks");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Total Clicks");
END IF;

IF @MatrixBy='NR' THEN
   SET @SQLwrkMatrix    =REPLACE(@SQLwrkMatrix,    "Qualified_Players","Net_Revenue");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Qualified_Players","Net_Revenue");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Qualified_Players","Net_Revenue");
   SET @SQLcheckTotal   =REPLACE(@SQLcheckTotal,   "Qualified_Players","Net_Revenue");
   SET @SQLwrkDetail    =REPLACE(@SQLwrkDetail,    "Total CPA","Net_Revenue");
   SET @SQLwrkTotal     =REPLACE(@SQLwrkTotal,     "Total CPA","Net_Revenue");
END IF;
-- -----
-- ---------------------------------------------------------------

	PREPARE stmt1 FROM @SQLcheckTotal;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
-- ---------------------------------------------------------------

IF @Debug!="NO" THEN SELECT @SQLcheckTotal, @Kreg; END IF;
IF @Debug!="NO" THEN SELECT @SQLwrkMatrix; END IF;
IF @Debug!="NO" THEN SELECT @SQLwrkDetail; END IF;
IF @Debug!="NO" THEN SELECT @SQLwrkTotal;  END IF;

SET @SQL = CONCAT(
    if(@Total='YES' AND @TotLine='FIRST',@SQLwrkTotal,'')
   ,if(@Total='YES' AND @TotLine='FIRST',' UNION ALL ','')
   ,@SQLwrkDetail
   ,if(@Total='YES' AND @TotLine!='FIRST',' UNION ALL ','')
   ,if(@Total='YES' AND @TotLine!='FIRST',@SQLwrkTotal,'')
   ,IF(@Meta='YES',' UNION ALL ','')
   ,IF(@Meta='YES',@SQLmeta,'')
   ,@Order_By
   ,');');

IF @Kreg IS NULL OR @Kreg=0 THEN SET @SQL=@SQLnodataTotal; END IF; -- 0 = sin datos (admite métricas decimales)

SET @M0=left(date_sub(curdate(), interval 0 month),7);
SET @M1=left(date_sub(curdate(), interval 1 month),7);
SET @M2=left(date_sub(curdate(), interval 2 month),7);
SET @M3=left(date_sub(curdate(), interval 3 month),7);
SET @M4=left(date_sub(curdate(), interval 4 month),7);
SET @M5=left(date_sub(curdate(), interval 5 month),7);
SET @M6=left(date_sub(curdate(), interval 6 month),7);
SET @M7=left(date_sub(curdate(), interval 7 month),7);

-- Mostrar filtros RS: ViewGES siempre; ViewAFF solo si Check_RS_affiliate=1
SET @ShowRS='NO';
IF @View='VIEWGES' THEN SET @ShowRS='YES'; END IF;
IF @View='VIEWAFF'
   AND @Affiliate_id NOT IN ('','ALL','ALLDETAIL')
   AND IFNULL(Check_RS_affiliate(CAST(@Affiliate_id AS UNSIGNED)),0)=1
THEN SET @ShowRS='YES'; END IF;

-- Filters Affiliate_list: métrica CPA (comms) o Qualified_Players (Snapshot)
SET @FilterMetric=IF(@UseComms='YES','CPA','Qualified_Players');

SET @SQL_Affiliate_list=CONCAT(
   'WITH Affiliate_list as (
    SELECT
       `Affiliate`
      ,`Affiliate_id`
      ,SUM(`',@FilterMetric,'`) AS "CPA"
      ,count(*) AS "Rows"
      FROM '
   ,@DataTable,'
    WHERE LEFT(DATE,7)',@Compare,'"',@Month_Report,'"'
   ,@WhereOwner,@WhereAffiliate_id,@WhereAdvertiser_id,'\r\n'
   ,'GROUP BY `Affiliate`,`Affiliate_id` HAVING SUM(`',@FilterMetric,'`)<>0
   )');


-- SET @Dat0="CPA"           ,@Dat0a="CPA"             ;
-- SET @Dat5="NET_CPA_VAL"   ,@Dat5a="Sum CPA Value"   ;
-- SET @Dat6="NET_RS_VAL"    ,@Dat6a="Sum RS Value"    ;
-- SET @Dat7="NET_TOTAL_COMM",@Dat7a="Sum Commission"  ;
-- SET @Dat1="Signup"        ,@Dat1a="Sign Ups"        ;
-- SET @Dat2="FTD"                   "FTD"             ;
-- SET @Dat3="Click"         ,@Dat3a="Clicks"          ;
-- SET @Dat4="NR"            ,@Dat4a="Net Revenue"     ;

SET @SQLfilters=CONCAT(
@SQL_Affiliate_list,
'
(SELECT "7" as "Korder","Affiliate" AS "Key",`Affiliate`    AS "Value","Affiliate_id"    AS `CallKey`,`Affiliate_id` AS "CallValue","" AS "Rows"
  FROM Affiliate_list WHERE @View!="VIEWAFF") UNION ALL
(SELECT "1","Month"   ,@M0              ,"Month"       ,@M0   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M1              ,"Month"       ,@M1   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M2              ,"Month"       ,@M2   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M3              ,"Month"       ,@M3   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M4              ,"Month"       ,@M4   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M5              ,"Month"       ,@M5   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M6              ,"Month"       ,@M6   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,@M7              ,"Month"       ,@M7   ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "1","Month"   ,"Last 6 months"  ,"LastMonths" ,"YES"  ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "3","Criteria","Data By Day"    ,"ByDay"       ,"YES" ,"" AS "Rows" FROM DUAL WHERE @UseComms!="YES") UNION ALL
(SELECT "3","Criteria","ALL: detail by day","Affiliate_id","ALLdetail" ,"" AS "Rows" FROM DUAL where @View="VIEWGES" AND @UseComms!="YES") UNION ALL
(SELECT "5","Data"    ,"CPA"            ,"MatrixBy"    ,"CPA"            ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "5","Data"    ,"Sum CPA Value"  ,"MatrixBy"    ,"NET_CPA_VAL"    ,"" AS "Rows" FROM DUAL WHERE @View IN ("VIEWAFF","VIEWGES")) UNION ALL
(SELECT "5","Data"    ,"Sum Rev Share"  ,"MatrixBy"    ,"NET_RS_VAL"     ,"" AS "Rows" FROM DUAL WHERE @ShowRS="YES") UNION ALL
(SELECT "5","Data"    ,"Sum Commission" ,"MatrixBy"    ,"NET_TOTAL_COMM" ,"" AS "Rows" FROM DUAL WHERE @ShowRS="YES") UNION ALL
(SELECT "5","Data"    ,"Sign Ups"       ,"MatrixBy"    ,"Signup"         ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "5","Data"    ,"FTD"            ,"MatrixBy"    ,"FTD"            ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "5","Data"    ,"Clicks"         ,"MatrixBy"    ,"Click"          ,"" AS "Rows" FROM DUAL) UNION ALL
(SELECT "5","Data"    ,"Net Revenue"    ,"MatrixBy"    ,"NR"             ,"" AS "Rows" FROM DUAL WHERE @View="VIEWGES")

ORDER BY 1, CASE WHEN `Key` IN ("Affiliate_id","Data") THEN Value ELSE "1" END  ASC,
				CASE WHEN `Key` NOT IN ("Affiliate_id","Data") THEN Value ELSE "1" END  DESC            
;');

IF @Filters="YES" THEN SET @SQL=@SQLfilters; END IF;

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
call Dash_BrandMatrix(' '); -- No devolverá nada porque asume ViewAFF y Affiliate_id=9999999
call Dash_BrandMatrix('View=VIEWGES,debug=ye');
call Dash_BrandMatrix('View=VIEWGES,MatrixBy=CPA,meta=yes,debug=no');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=39,Month=LM,MatrixBy=net_Total_comm,debug=ye');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=ALL,Month=LM,MatrixBy=net_CPA_Val');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=ALL,ByDay=yes,Month=2022-08,MatrixBy=Signup,meta=yes');
call Dash_BrandMatrix('View=ViewAFF,Affiliate_id=ALL,ByDay=yes'); --  ERROR Para View=viewAFF Default Affiliate_id=9999999
call Dash_BrandMatrix('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=cpa,meta=yes,filters=yes,debug=no');
call Dash_BrandMatrix('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=net_RS_Val,meta=yes,debug=ye');
call Dash_BrandMatrix('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=net_Total_comm,meta=yes,debug=ye');
call Dash_BrandMatrix('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=net_CPA_Val,meta=yes,debug=ye');
call Dash_BrandMatrix('View=ViewAFF,Month=2023-07,Affiliate_id=39,ByDay=yes,MatrixBy=ftd,meta=yes,debug=no');
call Dash_BrandMatrix('View=ViewAFF,Month=2022-12,Affiliate_id=39,ByDay=yes,MatrixBy=click,meta=yes,debug=no');
call Dash_BrandMatrix('View=ViewGES,Month=LM,debug=yes');
call Dash_BrandMatrix('View=ViewGES,filters=yes,debug=non');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=512,filters=ye,debug=ye');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=39,LastMonths=YES,MatrixBy=CPA,debug=ye');
call Dash_BrandMatrix('View=ViewAFF,Month=LM,Affiliate_id=39,MatrixBy=ftd,meta=yes,debug=ye');
call Dash_BrandMatrix('View=ViewMAF,Month=LM,debug=ye'); -- ERROR falta MasterAff_id
call Dash_BrandMatrix('View=ViewMAF,MasterAff_id=39,Month=LM,debug=ye'); -- ERROR MasterAff_id no es MAF
call Dash_BrandMatrix('View=ViewMAF,MasterAff_id=440,Month=LM,debug=ye');
call Dash_BrandMatrix('View=ViewMAF,MasterAff_id=440,Month=LM,filters=yes,debug=ye');
call Dash_BrandMatrix('View=ViewGES,MasterAff_id=440,Month=LM,filters=yes,debug=ye');
call Dash_BrandMatrix('View=ViewAFF,Affiliate_id=469,Month=lm,filters=ye,meta=YEs,debug=ye');
call Dash_BrandMatrix('View=ViewGES,Affiliate_id=all,Month=CM,filters=ye,meta=yes,debug=yes');
*/
