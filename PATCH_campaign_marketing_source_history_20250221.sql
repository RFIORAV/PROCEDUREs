/* 
   21.02.2025 PATCH `campaign_marketing_source_history` por campos agregados
*/

-- ALTER TABLE `campaign_marketing_source_history` 
   -- ADD COLUMN `Ad_Code` VARCHAR(50) NULL DEFAULT NULL AFTER `Priority`,
   -- ADD COLUMN `Ad_Valid_From` DATE NULL DEFAULT NULL AFTER `Ad_Code`,
   -- ADD COLUMN `Ad_Valid_to` DATE NULL DEFAULT NULL AFTER `Ad_Valid_From`
-- ;

--                                            		
DROP TRIGGER IF EXISTS campaign_marketing_source_after_update_history;
DELIMITER $$                                  		
--                                            		
CREATE TRIGGER campaign_marketing_source_after_update_history     		
AFTER UPDATE                                  		
ON campaign_marketing_source FOR EACH ROW                       		
--                                            		
BEGIN                                         		
--                                            		
DECLARE `Trigger_generated_on` TEXT DEFAULT '20250221 patch manual'; 	
DECLARE `Aud_Action` TEXT DEFAULT 'Change in:'; 	                              
IF NOT (OLD.`Owner` <=> NEW.`Owner`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Owner'); END IF;
IF NOT (OLD.`Code` <=> NEW.`Code`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Code'); END IF;
IF NOT (OLD.`Tracklink` <=> NEW.`Tracklink`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Tracklink'); END IF;
IF NOT (OLD.`Tracker_ID` <=> NEW.`Tracker_ID`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Tracker_ID'); END IF;
IF NOT (OLD.`Tracker_Name` <=> NEW.`Tracker_Name`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Tracker_Name'); END IF;
IF NOT (OLD.`Code_To_Affiliate` <=> NEW.`Code_To_Affiliate`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Code_To_Affiliate'); END IF;
IF NOT (OLD.`Product` <=> NEW.`Product`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Product'); END IF;
IF NOT (OLD.`Source` <=> NEW.`Source`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Source'); END IF;
IF NOT (OLD.`CPA_Limit` <=> NEW.`CPA_Limit`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'CPA_Limit'); END IF;
IF NOT (OLD.`Status` <=> NEW.`Status`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status'); END IF;
IF NOT (OLD.`Status_id` <=> NEW.`Status_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_id'); END IF;
IF NOT (OLD.`NotUse_StatEf` <=> NEW.`NotUse_StatEf`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'NotUse_StatEf'); END IF;
IF NOT (OLD.`Stat_effect` <=> NEW.`Stat_effect`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Stat_effect'); END IF;
IF NOT (OLD.`Stat_aggreg` <=> NEW.`Stat_aggreg`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Stat_aggreg'); END IF;
IF NOT (OLD.`Stat_Chan` <=> NEW.`Stat_Chan`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Stat_Chan'); END IF;
IF NOT (OLD.`Stat_Acct` <=> NEW.`Stat_Acct`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Stat_Acct'); END IF;
IF NOT (OLD.`Status_Adv_id` <=> NEW.`Status_Adv_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_Adv_id'); END IF;
IF NOT (OLD.`Status_Acct_id` <=> NEW.`Status_Acct_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_Acct_id'); END IF;
IF NOT (OLD.`Status_Aff_id` <=> NEW.`Status_Aff_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_Aff_id'); END IF;
IF NOT (OLD.`Status_Channel_id` <=> NEW.`Status_Channel_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_Channel_id'); END IF;
IF NOT (OLD.`Status_Pub_id` <=> NEW.`Status_Pub_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Status_Pub_id'); END IF;
IF NOT (OLD.`Valid_From` <=> NEW.`Valid_From`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Valid_From'); END IF;
IF NOT (OLD.`Valid_Until` <=> NEW.`Valid_Until`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Valid_Until'); END IF;
IF NOT (OLD.`Description` <=> NEW.`Description`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Description'); END IF;
IF NOT (OLD.`Affiliate_id` <=> NEW.`Affiliate_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Affiliate_id'); END IF;
IF NOT (OLD.`Advertiser_id` <=> NEW.`Advertiser_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Advertiser_id'); END IF;
IF NOT (OLD.`Advertiser_id_OK` <=> NEW.`Advertiser_id_OK`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Advertiser_id_OK'); END IF;
IF NOT (OLD.`Publisher_id` <=> NEW.`Publisher_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Publisher_id'); END IF;
IF NOT (OLD.`Campaign_id` <=> NEW.`Campaign_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Campaign_id'); END IF;
IF NOT (OLD.`Username_id` <=> NEW.`Username_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Username_id'); END IF;
IF NOT (OLD.`Channel_id` <=> NEW.`Channel_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Channel_id'); END IF;
IF NOT (OLD.`Deal_id` <=> NEW.`Deal_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Deal_id'); END IF;
IF NOT (OLD.`Country_Deal` <=> NEW.`Country_Deal`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Country_Deal'); END IF;
IF NOT (OLD.`Product_Deal` <=> NEW.`Product_Deal`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Product_Deal'); END IF;
IF NOT (OLD.`Deal_Valid_From` <=> NEW.`Deal_Valid_From`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Deal_Valid_From'); END IF;
IF NOT (OLD.`Shortlink` <=> NEW.`Shortlink`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Shortlink'); END IF;
IF NOT (OLD.`Shortlink_id` <=> NEW.`Shortlink_id`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Shortlink_id'); END IF;
IF NOT (OLD.`Manual_Adjustment_CPA` <=> NEW.`Manual_Adjustment_CPA`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Manual_Adjustment_CPA'); END IF;
IF NOT (OLD.`Manual_Adjustment_Euro` <=> NEW.`Manual_Adjustment_Euro`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Manual_Adjustment_Euro'); END IF;
IF NOT (OLD.`Priority` <=> NEW.`Priority`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Priority'); END IF;
IF NOT (OLD.`Ad_Code` <=> NEW.`Ad_Code`)             THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Ad_Code'); END IF;
IF NOT (OLD.`Ad_Valid_From` <=> NEW.`Ad_Valid_From`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Ad_Valid_From'); END IF;
IF NOT (OLD.`Ad_Valid_to` <=> NEW.`Ad_Valid_to`)     THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Ad_Valid_to'); END IF;
IF NOT (OLD.`Creation_Date` <=> NEW.`Creation_Date`) THEN SET Aud_Action=CONCAT_WS(' ',Aud_Action,'Creation_Date'); END IF;

--                                            		
IF                                            		
      NOT (OLD.`id`<=>NEW.`id`                                          )
   OR NOT (OLD.`Owner`<=>NEW.`Owner`                                    )
   OR NOT (OLD.`Code`<=>NEW.`Code`                                      )
   OR NOT (OLD.`Tracklink`<=>NEW.`Tracklink`                            )
   OR NOT (OLD.`Tracker_ID`<=>NEW.`Tracker_ID`                          )
   OR NOT (OLD.`Tracker_Name`<=>NEW.`Tracker_Name`                      )
   OR NOT (OLD.`Code_To_Affiliate`<=>NEW.`Code_To_Affiliate`            )
   OR NOT (OLD.`Product`<=>NEW.`Product`                                )
   OR NOT (OLD.`Source`<=>NEW.`Source`                                  )
   OR NOT (OLD.`CPA_Limit`<=>NEW.`CPA_Limit`                            )
   OR NOT (OLD.`Status`<=>NEW.`Status`                                  )
   OR NOT (OLD.`Status_id`<=>NEW.`Status_id`                            )
   OR NOT (OLD.`NotUse_StatEf`<=>NEW.`NotUse_StatEf`                    )
   OR NOT (OLD.`Stat_effect`<=>NEW.`Stat_effect`                        )
   OR NOT (OLD.`Stat_aggreg`<=>NEW.`Stat_aggreg`                        )
   OR NOT (OLD.`Stat_Chan`<=>NEW.`Stat_Chan`                            )
   OR NOT (OLD.`Stat_Acct`<=>NEW.`Stat_Acct`                            )
   OR NOT (OLD.`Status_Adv_id`<=>NEW.`Status_Adv_id`                    )
   OR NOT (OLD.`Status_Acct_id`<=>NEW.`Status_Acct_id`                  )
   OR NOT (OLD.`Status_Aff_id`<=>NEW.`Status_Aff_id`                    )
   OR NOT (OLD.`Status_Channel_id`<=>NEW.`Status_Channel_id`            )
   OR NOT (OLD.`Status_Pub_id`<=>NEW.`Status_Pub_id`                    )
   OR NOT (OLD.`Valid_From`<=>NEW.`Valid_From`                          )
   OR NOT (OLD.`Valid_Until`<=>NEW.`Valid_Until`                        )
   OR NOT (OLD.`Description`<=>NEW.`Description`                        )
   OR NOT (OLD.`Affiliate_id`<=>NEW.`Affiliate_id`                      )
   OR NOT (OLD.`Advertiser_id`<=>NEW.`Advertiser_id`                    )
   OR NOT (OLD.`Advertiser_id_OK`<=>NEW.`Advertiser_id_OK`              )
   OR NOT (OLD.`Publisher_id`<=>NEW.`Publisher_id`                      )
   OR NOT (OLD.`Campaign_id`<=>NEW.`Campaign_id`                        )
   OR NOT (OLD.`Username_id`<=>NEW.`Username_id`                        )
   OR NOT (OLD.`Channel_id`<=>NEW.`Channel_id`                          )
   OR NOT (OLD.`Deal_id`<=>NEW.`Deal_id`                                )
   OR NOT (OLD.`Country_Deal`<=>NEW.`Country_Deal`                      )
   OR NOT (OLD.`Product_Deal`<=>NEW.`Product_Deal`                      )
   OR NOT (OLD.`Deal_Valid_From`<=>NEW.`Deal_Valid_From`                )
   OR NOT (OLD.`Shortlink`<=>NEW.`Shortlink`                            )
   OR NOT (OLD.`Shortlink_id`<=>NEW.`Shortlink_id`                      )
   OR NOT (OLD.`Manual_Adjustment_CPA`<=>NEW.`Manual_Adjustment_CPA`    )
   OR NOT (OLD.`Manual_Adjustment_Euro`<=>NEW.`Manual_Adjustment_Euro`  )
   OR NOT (OLD.`Priority`      <=> NEW.`Priority`                       )
   OR NOT (OLD.`Ad_Code`       <=> NEW.`Ad_Code`                        )
   OR NOT (OLD.`Ad_Valid_From` <=> NEW.`Ad_Valid_From`                  )
   OR NOT (OLD.`Ad_Valid_to`   <=> NEW.`Ad_Valid_to`                    )
   OR NOT (OLD.`Creation_Date` <=> NEW.`Creation_Date`                  )
THEN                                          		
--                                            		
INSERT INTO campaign_marketing_source_history ( 				   			
    `id`
   ,`Owner`
   ,`Code`
   ,`Tracklink`
   ,`Tracker_ID`
   ,`Tracker_Name`
   ,`Code_To_Affiliate`
   ,`Product`
   ,`Source`
   ,`CPA_Limit`
   ,`Status`
   ,`Status_id`
   ,`NotUse_StatEf`
   ,`Stat_effect`
   ,`Stat_aggreg`
   ,`Stat_Chan`
   ,`Stat_Acct`
   ,`Status_Adv_id`
   ,`Status_Acct_id`
   ,`Status_Aff_id`
   ,`Status_Channel_id`
   ,`Status_Pub_id`
   ,`Valid_From`
   ,`Valid_Until`
   ,`Description`
   ,`Affiliate_id`
   ,`Advertiser_id`
   ,`Advertiser_id_OK`
   ,`Publisher_id`
   ,`Campaign_id`
   ,`Username_id`
   ,`Channel_id`
   ,`Deal_id`
   ,`Country_Deal`
   ,`Product_Deal`
   ,`Deal_Valid_From`
   ,`Shortlink`
   ,`Shortlink_id`
   ,`Manual_Adjustment_CPA`
   ,`Manual_Adjustment_Euro`
   ,`Priority`
   ,`Ad_Code`      
   ,`Ad_Valid_From`
   ,`Ad_Valid_to`  
   ,`Creation_Date`
   ,`Last_Update`
   ,`Operator`
   ,`Aud_Agent`                              			
   ,`Aud_Action`                              		
)                                            			
VALUES (                                      		
    OLD.`id`
   ,OLD.`Owner`
   ,OLD.`Code`
   ,OLD.`Tracklink`
   ,OLD.`Tracker_ID`
   ,OLD.`Tracker_Name`
   ,OLD.`Code_To_Affiliate`
   ,OLD.`Product`
   ,OLD.`Source`
   ,OLD.`CPA_Limit`
   ,OLD.`Status`
   ,OLD.`Status_id`
   ,OLD.`NotUse_StatEf`
   ,OLD.`Stat_effect`
   ,OLD.`Stat_aggreg`
   ,OLD.`Stat_Chan`
   ,OLD.`Stat_Acct`
   ,OLD.`Status_Adv_id`
   ,OLD.`Status_Acct_id`
   ,OLD.`Status_Aff_id`
   ,OLD.`Status_Channel_id`
   ,OLD.`Status_Pub_id`
   ,OLD.`Valid_From`
   ,OLD.`Valid_Until`
   ,OLD.`Description`
   ,OLD.`Affiliate_id`
   ,OLD.`Advertiser_id`
   ,OLD.`Advertiser_id_OK`
   ,OLD.`Publisher_id`
   ,OLD.`Campaign_id`
   ,OLD.`Username_id`
   ,OLD.`Channel_id`
   ,OLD.`Deal_id`
   ,OLD.`Country_Deal`
   ,OLD.`Product_Deal`
   ,OLD.`Deal_Valid_From`
   ,OLD.`Shortlink`
   ,OLD.`Shortlink_id`
   ,OLD.`Manual_Adjustment_CPA`
   ,OLD.`Manual_Adjustment_Euro`
   ,OLD.`Priority`
   ,OLD.`Ad_Code`      
   ,OLD.`Ad_Valid_From`
   ,OLD.`Ad_Valid_to`  
   ,OLD.`Creation_Date`
   ,OLD.`Last_Update`
   ,OLD.`Operator`
   ,NEW.`Operator`                                   
   ,`Aud_Action`                               		
);                                            		
 END IF;                                      
--                                             		
END$$                                         		
--                                            		
DELIMITER ;                                   		
--                                            		
-- SELECT 'Processing trigger for: euroaffiliati2.campaign_marketing_source' as '';									
CREATE TABLE IF NOT EXISTS campaign_marketing_source_history (	   				 						      	
    `id`                                	int null default null
   ,`Owner`                             	varchar(30) null default null
   ,`Code`                              	varchar(50) null default null
   ,`Tracklink`                         	varchar(250) null default null
   ,`Tracker_ID`                        	varchar(50) null default null
   ,`Tracker_Name`                      	varchar(250) null default null
   ,`Code_To_Affiliate`                 	varchar(50) null default null
   ,`Product`                           	varchar(50) null default null
   ,`Source`                            	varchar(250) null default null
   ,`CPA_Limit`                         	varchar(30) null default null
   ,`Status`                            	varchar(30) null default null
   ,`Status_id`                         	varchar(2) null default null
   ,`NotUse_StatEf`                     	varchar(2) null default null
   ,`Stat_effect`                       	varchar(30) null default null
   ,`Stat_aggreg`                       	varchar(2) null default null
   ,`Stat_Chan`                         	varchar(2) null default null
   ,`Stat_Acct`                         	varchar(2) null default null
   ,`Status_Adv_id`                     	varchar(2) null default null
   ,`Status_Acct_id`                    	varchar(2) null default null
   ,`Status_Aff_id`                     	varchar(2) null default null
   ,`Status_Channel_id`                 	varchar(2) null default null
   ,`Status_Pub_id`                     	varchar(2) null default null
   ,`Valid_From`                        	date null default null
   ,`Valid_Until`                       	date null default null
   ,`Description`                       	varchar(150) null default null
   ,`Affiliate_id`                      	int null default null
   ,`Advertiser_id`                     	int null default null
   ,`Advertiser_id_OK`                  	int null default null
   ,`Publisher_id`                      	int null default null
   ,`Campaign_id`                       	int null default null
   ,`Username_id`                       	int null default null
   ,`Channel_id`                        	int null default null
   ,`Deal_id`                           	int null default null
   ,`Country_Deal`                      	varchar(2) null default null
   ,`Product_Deal`                      	varchar(50) null default null
   ,`Deal_Valid_From`                   	date null default null
   ,`Shortlink`                         	varchar(150) null default null
   ,`Shortlink_id`                      	varchar(150) null default null
   ,`Manual_Adjustment_CPA`             	varchar(30) null default null
   ,`Manual_Adjustment_Euro`            	varchar(30) null default null
   ,`Priority`                          	int null default null
   ,`Ad_Code`                           	varchar(150) null default null
   ,`Ad_Valid_From`                     	datetime null default null
   ,`Ad_Valid_to`                       	datetime null default null
   ,`Creation_Date`                     	datetime null default null
   ,`Last_Update`                       	datetime null default null
   ,`Operator`                          	varchar(30) null default null
   -- Auditory tracking data 
   ,`Aud_Date`   DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP	
   ,`Aud_Agent`  VARCHAR(40) NULL DEFAULT 'SysOp'  	
   ,`Aud_Action` TEXT NULL  								
); 							   				               
--                                            		
DROP TRIGGER IF EXISTS campaign_marketing_source_after_delete_history;
DELIMITER $$                                  		
--                                            		
CREATE TRIGGER campaign_marketing_source_after_delete_history     		
AFTER DELETE                                  		
ON campaign_marketing_source FOR EACH ROW                       		
--                                            		
BEGIN                                         		
--                                            		
DECLARE `Trigger_generated_on` TEXT DEFAULT '20250221 patch manual'; 	
DECLARE `Aud_Action` TEXT DEFAULT 'Record DELETED'; 	                           
--                                            		
INSERT INTO campaign_marketing_source_history ( 				   			
    `id`
   ,`Owner`
   ,`Code`
   ,`Tracklink`
   ,`Tracker_ID`
   ,`Tracker_Name`
   ,`Code_To_Affiliate`
   ,`Product`
   ,`Source`
   ,`CPA_Limit`
   ,`Status`
   ,`Status_id`
   ,`NotUse_StatEf`
   ,`Stat_effect`
   ,`Stat_aggreg`
   ,`Stat_Chan`
   ,`Stat_Acct`
   ,`Status_Adv_id`
   ,`Status_Acct_id`
   ,`Status_Aff_id`
   ,`Status_Channel_id`
   ,`Status_Pub_id`
   ,`Valid_From`
   ,`Valid_Until`
   ,`Description`
   ,`Affiliate_id`
   ,`Advertiser_id`
   ,`Advertiser_id_OK`
   ,`Publisher_id`
   ,`Campaign_id`
   ,`Username_id`
   ,`Channel_id`
   ,`Deal_id`
   ,`Country_Deal`
   ,`Product_Deal`
   ,`Deal_Valid_From`
   ,`Shortlink`
   ,`Shortlink_id`
   ,`Manual_Adjustment_CPA`
   ,`Manual_Adjustment_Euro`
   ,`Priority`
   ,`Ad_Code`       
   ,`Ad_Valid_From` 
   ,`Ad_Valid_to`   
   ,`Creation_Date`
   ,`Last_Update`
   ,`Operator`
   ,`Aud_Agent`                              			
   ,`Aud_Action`                              		
)                                            			
VALUES (                                      		
    OLD.`id`
   ,OLD.`Owner`
   ,OLD.`Code`
   ,OLD.`Tracklink`
   ,OLD.`Tracker_ID`
   ,OLD.`Tracker_Name`
   ,OLD.`Code_To_Affiliate`
   ,OLD.`Product`
   ,OLD.`Source`
   ,OLD.`CPA_Limit`
   ,OLD.`Status`
   ,OLD.`Status_id`
   ,OLD.`NotUse_StatEf`
   ,OLD.`Stat_effect`
   ,OLD.`Stat_aggreg`
   ,OLD.`Stat_Chan`
   ,OLD.`Stat_Acct`
   ,OLD.`Status_Adv_id`
   ,OLD.`Status_Acct_id`
   ,OLD.`Status_Aff_id`
   ,OLD.`Status_Channel_id`
   ,OLD.`Status_Pub_id`
   ,OLD.`Valid_From`
   ,OLD.`Valid_Until`
   ,OLD.`Description`
   ,OLD.`Affiliate_id`
   ,OLD.`Advertiser_id`
   ,OLD.`Advertiser_id_OK`
   ,OLD.`Publisher_id`
   ,OLD.`Campaign_id`
   ,OLD.`Username_id`
   ,OLD.`Channel_id`
   ,OLD.`Deal_id`
   ,OLD.`Country_Deal`
   ,OLD.`Product_Deal`
   ,OLD.`Deal_Valid_From`
   ,OLD.`Shortlink`
   ,OLD.`Shortlink_id`
   ,OLD.`Manual_Adjustment_CPA`
   ,OLD.`Manual_Adjustment_Euro`
   ,OLD.`Priority`
   ,OLD.`Ad_Code`       
   ,OLD.`Ad_Valid_From` 
   ,OLD.`Ad_Valid_to`   
   ,OLD.`Creation_Date`
   ,OLD.`Last_Update`
   ,OLD.`Operator`
   ,'SysOp'                                   
   ,`Aud_Action`                               		
);                                            		
 --                                       
--                                             		
END$$                                         		
--                                            		
DELIMITER ; 
