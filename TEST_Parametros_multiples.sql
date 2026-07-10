-- call `TEST_parametro_multiple_dev`('');

DROP PROCEDURE IF EXISTS TEST_parametro_multiple_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `TEST_parametro_multiple_dev`(IN
   InputCommLine    VARCHAR(250)
   )
    COMMENT 'TEST_parametro_multiple_dev'
BEGIN
-- ------
-- --------------------------------------------------------------------------------------------
-- Defaults
SET @Version         ='v1 20.05.2025';
SET @Month           =left(curdate(),7);
SET @MS_id           ='ALL';
SET @Area            ='ALL';
SET @Owner           ='ALL';
SET @Brand           ='ALL';
SET @Affiliate_id    ='ALL';
SET @Master_Affiliate_id='ALL';
SET @ReferrerMode    ='NO';
SET @Account_id      ='ALL';
SET @Account         ='ALL';
SET @Channel_id      ='ALL';
SET @Product         ='ALL';
SET @ProductMS       ='ALL';
SET @Platform        ='ALL';
SET @Brand_Group     ='ALL';
SET @Publisher_id    ='ALL';
-- SET @Currency        ='EUR';
SET @Total           ='YES';
SET @Filters         ='NO';
SET @TotLine         ='FIRST';
SET @Meta            ='YES';
SET @Debug           ='YES';
SET @View            ='VIEWGES';
SET @GroupByMS       ='NO';
SET @OnlyOverCap     ='NO';
SET @OnlyBigCPA_SUp  ='NO';
SET @Search          ='';

SET @InputCommLine='Month=LM,affiliate_id=(39^130^84),Account_id=(1^2^3),Filters=no,debug=non,meta=yes';      -- Coma de cierre

-- SET @InputCommLine=Concat(InputCommLine ,',');      -- Coma de cierre
SET @InputCommLine=Concat(@InputCommLine ,',');      -- Coma de cierre
--  @InputCommLine=replace(@InputCommLine,' ','');  -- Elimina espacios
SET @InputCommLine=replace(@InputCommLine,'"','');  -- Elimina comillas

IF @Debug!="NO" THEN SELECT @InputCommLine; END IF;

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
 
   IF    LEFT(@v,1)='(' AND RIGHT(@v,1)=')'
   THEN  SET @v=REPLACE(@v,'(','("'); 
         SET @v=REPLACE(@v,')','")'); 
         SET @v=REPLACE(@v,'^','","');
   END IF; 
 
   IF lower(@k)='month'                THEN SET @Month               =UPPER(@v); END IF;
   IF lower(@k)='ms_id'                THEN SET @MS_id               =UPPER(@v); END IF;
   IF lower(@k)='area'                 THEN SET @Area                =lower(@v); END IF;
   IF lower(@k)='owner'                THEN SET @Owner               =UPPER(@v); END IF;
   IF lower(@k)='advertiser_id'        THEN SET @Advertiser_id       =UPPER(@v); END IF;
   IF lower(@k)='brand'                THEN SET @Brand               =UPPER(@v); END IF;
   IF lower(@k)='master_affiliate_id'  THEN SET @Master_Affiliate_id =UPPER(@v); END IF;
   IF lower(@k)='account_id'           THEN SET @Account_id          =UPPER(@v); END IF;
   IF lower(@k)='publisher_id'         THEN SET @Publisher_id        =UPPER(@v); END IF;
   IF lower(@k)='referrermode'         THEN SET @ReferrerMode        =UPPER(@v); END IF;
   IF lower(@k)='account'              THEN SET @Account             =UPPER(@v); END IF;
   IF lower(@k)='channel_id'           THEN SET @Channel_id          =UPPER(@v); END IF;
   IF lower(@k)='currency'             THEN SET @Currency            =UPPER(@v); END IF;
   IF lower(@k)='total'                THEN SET @Total               =UPPER(@v); END IF;
   IF lower(@k)='totline'              THEN SET @TotLine             =UPPER(@v); END IF;
   IF lower(@k)='debug'                THEN SET @Debug               =UPPER(@v); END IF;
   IF lower(@k)='filters'              THEN SET @Filters             =UPPER(@v); END IF;
   IF lower(@k)='view'                 THEN SET @View                =UPPER(@v); END IF;
   IF lower(@k)='meta'                 THEN SET @Meta                =UPPER(@v); END IF;
   IF lower(@k)='groupbyms'            THEN SET @GroupByMS           =UPPER(@v); END IF;
   IF lower(@k)='onlyovercap'          THEN SET @OnlyOverCap         =UPPER(@v); END IF;
   IF lower(@k)='onlybigcpa_sup'       THEN SET @OnlyBigCPA_SUp      =UPPER(@v); END IF;
   IF lower(@k)='product'              THEN SET @Product             =UPPER(@v); END IF;
   IF lower(@k)='productms'            THEN SET @ProductMS           =UPPER(@v); END IF;
   IF lower(@k)='platform'             THEN SET @Platform            =UPPER(@v); END IF;
   IF lower(@k)='brand_group'          THEN SET @Brand_Group         =UPPER(@v); END IF;
   IF lower(@k)='search'               THEN SET @Search              =UPPER(@v); END IF;
   IF lower(@k)='affiliate_id'         THEN SET @Affiliate_id        =UPPER(@v); END IF;

END WHILE;

SELECT @Month,@MS_id,@Area,@Owner,@Advertiser_id,@Brand,@Affiliate_id,@Master_Affiliate_id,@Account_id,@Publisher_id
      ,@ReferrerMode,@Account,@Channel_id,@Currency,@Total,@TotLine,@Debug,@Filters,@View,@Meta,@GroupByMS
      ,@OnlyOverCap,@OnlyBigCPA_SUp,@Product,@ProductMS,@Platform,@Brand_Group,@Search;
/*
-- Obtiene @MultiCurrency y @Currency desde tabla util_settings
SET @MultiCurrency=(SELECT IFNULL(`Value_01`,'NO')  FROM `util_settings` WHERE Setting='MultiCurrency');
SET @Currency=     (SELECT IFNULL(`Value_01`,'EUR') FROM `util_settings` WHERE Setting='GridCurrency');

-- Recupera espacios reemplazados en front end por caracter "!"
IF @Product       !="ALL" THEN SET @Product      =replace(@Product,"!"," ");     END IF;
IF @Platform      !="ALL" THEN SET @Platform     =replace(@Platform,"!"," ");    END IF;
IF @Brand_Group   !="ALL" THEN SET @Brand_Group  =replace(@Brand_Group,"!"," "); END IF;
IF @Brand         !="ALL" THEN SET @Brand        =replace(@Brand,"!"," ");       END IF;
IF @Account       !="ALL" THEN SET @Account      =replace(@Account,"!"," ");     END IF;

-- Check month para caso 2023-1 en lugar de 2023-01
IF CHAR_LENGTH(@Month)=6 THEN SET @Month=CONCAT(LEFT(@Month,5),'0',RIGHT(@Month,1)); END IF;
*/
IF  @Month = "CM" THEN SET @Month=LEFT(CURDATE(),7); END IF;
IF  @Month = "LM" THEN SET @Month=LEFT(DATE_SUB(CURDATE(), INTERVAL 1 MONTH),7); END IF;

IF @Debug!="NO" THEN SELECT @ReferrerMode,@Month,@View,@Currency,@Filters,@OWNER,@OnlyOverCap,@OnlyBigCPA_SUp,@Brand_Group,@Publisher_id
                           ,@Brand,@Master_Affiliate_id,@Affiliate_id,@Account_id,@Account,@Channel_id,@Product
                           ,@Platform,@Currency,@Total,@Debug,@Meta,InputCommLine; END IF;

SET @WhereMS_id='';
SET @WhereOwner='';
SET @WhereArea='';
SET @WhereBrand ='';
SET @WherePublisher_id  ='';
SET @WhereAffiliate_id  ='';
SET @WhereAdv_Account_id='';
SET @WhereAdv_Account   ='';
SET @WhereChannel_id    ='';
SET @WhereStatus        ='';
SET @WhereProduct       ='';
SET @WhereProductMS     ='';
SET @WherePlatform      ='';
SET @WhereBrand_Group   ='';
SET @WhereSearch        ='';
SET @WhereMaster_Affiliate_id='';

IF @Affiliate_id   !="ALL"   THEN SET @WhereAffiliate_id    =CONCAT(" AND IFNULL(D.Affiliate_id ,'') IN ",@Affiliate_id  );   END IF;
IF @Account_id     !="ALL"   THEN SET @WhereAdv_Account_id  =CONCAT(" AND IFNULL(D.Username_id  ,'') IN ",@Account_id);       END IF;
   
   IF @Owner          !="ALL"   THEN SET @WhereOwner           =CONCAT(" AND D.Owner=",@Owner);                               END IF;
   IF @Area           !="ALL"   THEN SET @WhereArea            =CONCAT(" AND D.Area='",@Area,"'");                            END IF;
   IF @Brand          !="ALL"   THEN SET @WhereBrand           =CONCAT(" AND IFNULL(D.Brand        ,'')='",@Brand,"'");       END IF;
   IF @Account        !="ALL"   THEN SET @WhereAdv_Account     =CONCAT(" AND IFNULL(D.Username     ,'')='",@Account,"'");     END IF;
   IF @Channel_id     !="ALL"   THEN SET @WhereChannel_id      =CONCAT(" AND IFNULL(D.Channel_id	 ,'')=",@Channel_id);      END IF;
   IF @Product        !="ALL"   THEN SET @WhereProduct         =CONCAT(" AND IFNULL(D.Product      ,'')='",@Product,"'");  	END IF;
   IF @ProductMS      !="ALL"   THEN SET @WhereProductMS       =CONCAT(" AND IFNULL(M.Product      ,'')='",@ProductMS,"'");  	END IF;
   IF @Platform       !="ALL"   THEN SET @WherePlatform        =CONCAT(" AND IFNULL(D.Portal     	 ,'')='",@Platform,"'"); 	END IF;
   IF @Publisher_id   !="ALL"   THEN SET @WherePublisher_id    =CONCAT(" AND IFNULL(D.Publisher_id  ,'')=",@Publisher_id);    END IF;
   IF @Brand_Group    !="ALL"   THEN SET @WhereBrand_Group     =CONCAT(" AND IFNULL(D.Brand_Group  ,'')='",@Brand_Group,"'"); END IF;
   IF @Master_Affiliate_id!="ALL" and @ReferrerMode="YES"
   THEN SET @WhereMaster_Affiliate_id=CONCAT(" AND IFNULL(R.Master_Affiliate_id ,'')='",@Master_Affiliate_id,"'"); END IF;

-- IF lower(@Currency)='original' THEN SET @Currency_result='ALL'; ELSE SET @Currency_result=UPPER(@Currency); END IF;

-- IF @View="VIEWAFF" THEN
     -- SET @FromTable='," " as Platform FROM Snapshot_day_by_day_fact2 ';
     -- SET @FilterFromTable='," " as Platform FROM Snapshot_day_by_day_fact2 ';
     -- SET @AcumGesOnly='';
     -- SET @TotGesOnly='';
     -- SET @Meta='';
-- ELSE
	  -- SET @FromTable=",Brand_Group,Portal as Platform,Deal_Ges_CPA as `Ge_CPA`,Deal_Ges_RS as `Ge_RS` FROM Snapshot_day_by_day_fact1 ";
	  -- SET @FilterFromTable=",Portal as Platform FROM Snapshot_day_by_day_fact1 ";
     -- SET @AcumGesOnly=',Ge_CPA,Ge_RS ';
     -- SET @TotGesOnly=',"~~~~~","~~~~~"';
-- END IF;

IF @Debug!="NO" THEN SELECT @OnlyOverCap,@GroupByMS,@Product,@GroupBySeleccBase,@View,@WhereOnlyOverCap,@Search,@MS_id; END IF;
IF @Debug!="NO" THEN SELECT @WhereMS_id,@WhereArea,@WhereOwner,@WhereBrand,@WhereAffiliate_id,@WhereAdv_Account_id,@WherePublisher_id;  END IF;

SET @SQLquery=CONCAT('
   SELECT * FROM Snapshot_day_by_day_fact1 D
   WHERE 1=1 '
      ,@WhereAffiliate_id  
      ,@WhereAdv_Account_id
      ,';'
);

IF @Debug!="NO" THEN SELECT @SQLquery; END IF;

IF @Debug != "YES" THEN
	PREPARE stmt1 FROM @SQLquery;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
END IF;


END$$
DELIMITER ;

-- call `TEST_parametro_multiple_dev`('');
