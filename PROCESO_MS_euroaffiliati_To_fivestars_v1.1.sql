/*
      PROCESO DE TRANSFERENCIA DE MS DE CUENTAS INDIRECTAS
      
      06.03.2025 V1
      08.05.2025 V1.1   Generalizado para cualquier db origen o destino
      
*/
-- Constantes para euroaffiliati -> fivestars -- REVISAR Y MODIFICAR EN CADA EJECUCIÓN

SET @Orig_DB               ="euroaffiliati2";  
SET @Orig_Affiliate_id     =909;            -- Afiliado ea fivestars
SET @Orig_Last_Update      ='2025-03-06';   -- para afinar selección de MS en origen si es necesario. Si no, dejar en blanco

SET @Dest_DB               ="fivestars";  
SET @Dest_Affiliate_id     =4;              -- Parking
SET @Dest_Publisher_id     =67;             -- Euroaffiliati
SET @Dest_Channel_id       =1;              -- Parking
SET @Dest_Deal_id          =188;            -- CPA=0 RS=0 BL=0
SET @Dest_Deal_Valid_From  ='2025-03-01';   -- MODIFICAR SEGUN CORRESPONDA
SET @Dest_Product_Deal     ='';

-- Constantes para fivestars -> euroaffiliati -- REVISAR Y MODIFICAR EN CADA EJECUCIÓN

SET @Orig_DB               ="fivestars";  
SET @Orig_Affiliate_id     =157;            -- Afiliado en origen
SET @Orig_Last_Update      ='';             -- para afinar selección de MS en origen si es necesario. Si no, dejar en blanco

SET @Dest_DB               ="euroaffiliati2";  
SET @Dest_Affiliate_id     =84;             -- Parking
SET @Dest_Channel_id       =531;            -- Parking
SET @Dest_Publisher_id     =140;            -- fivestars
SET @Dest_Deal_id          =188;            -- CPA=0 RS=0 BL=0
SET @Dest_Deal_Valid_From  ='2025-05-01';   -- MODIFICAR SEGUN CORRESPONDA
SET @Dest_Product_Deal     ='';

-- ----------------------------------------------------------------------
-- ----------------------------------------------------------------------

SET @SQL_insert=CONCAT('
INSERT INTO ',@Dest_DB,'.`campaign_marketing_source`(
    `Owner`
   ,`Code`
   ,`Tracklink`
   ,`Tracker_ID`
   ,`Tracker_Name`
   ,`Code_To_Affiliate`
   ,`Product`
   ,`Source`
   ,`CPA_Limit`
   ,`Status_id`
   ,`NotUse_StatEf`
   ,`Description`
   ,`Affiliate_id`
   ,`Advertiser_id`
   ,`Publisher_id`
   ,`Username_id`
   ,`Channel_id`
   ,`Deal_id`
   ,`Deal_Valid_From`
   ,`Product_Deal`
   ,`Operator`
   )
   '
);

SET @SQL_select=CONCAT('   
SELECT
    DEST.`Owner`              AS `Owner`
   ,""                        as `Code`
   ,CONCAT("https://",m.`Shortlink`) as `Tracklink`
   ,m.`Tracker_ID`
   ,m.`Tracker_Name`
   ,m.`Code_To_Affiliate`
   ,m.`Product`
   ,m.`Source`
   ,m.`CPA_Limit`
   ,"1"                       as `Status_id`
   ,"0"                       as `NotUse_StatEf`
   ,CONCAT("Transfer SysOp ",NOW()) as `Description`
   ,@Dest_Affiliate_id        AS `Affiliate_id`
   ,DEST.`Advertiser_id`      AS `Advertiser_id`
   ,@Dest_Publisher_id        AS `Publisher_id`
   ,DEST.`Username_id`        AS `Username_id`
   ,@Dest_Channel_id          AS `Channel_id`
   ,@Dest_Deal_id             AS `Deal_id`
   ,@Dest_Deal_Valid_From     AS `Deal_Valid_From`
   ,@Dest_Product_Deal        AS `Product_Deal`
   ,"SysOp"                   AS `Operator`
FROM ',@Orig_DB,'.`campaign_marketing_source` m
LEFT JOIN ',@Orig_DB,'.campaign_advertiser A ON A.id=m.Advertiser_id
LEFT JOIN LATERAL (
      SELECT A5.id as Advertiser_id,U5.id as Username_id,U5.Owner,U5.Data_Currency
      FROM ',@Dest_DB,'.campaign_username U5
      LEFT JOIN ',@Dest_DB,'.campaign_advertiser A5 ON A5.id=U5.Advertiser_id
      WHERE U5.Publisher_id=@Dest_Publisher_id   -- en origen
        AND A5.Advertiser_name=A.`Advertiser_name`
) AS DEST on TRUE
WHERE m.`Affiliate_id`=@Orig_Affiliate_id 
AND (LEFT(m.`Last_Update`,10)=@Orig_Last_Update AND @Orig_Last_Update!="" 
   OR @Orig_Last_Update="")
;
'
);

SET @SQL=CONCAT(@SQL_insert,@SQL_select);

-- -----------------------------------------------------------------------------------

SELECT @SQL_insert;
SELECT @SQL_select;
SELECT @SQL;

-- for testing. Muestra las MS seleccionadas tal como van a insertarse en DB destino
PREPARE stmt1 FROM @SQL_select;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

-- ejecucion final. Inserta las MS en db destino
PREPARE stmt1 FROM @SQL;
EXECUTE stmt1;
DEALLOCATE PREPARE stmt1;

