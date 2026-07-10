/* PROCEDURE_marketing_source_refresh.SQL - 


Descripción:
  Procedimiento marketing_source_refresh.
   14.02.2024 V1     Cambio de MS antiguas por nuevas

Keys:
  Sin parámetros de entrada documentables.
*/

DROP PROCEDURE IF EXISTS marketing_source_refresh;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE marketing_source_refresh()
   COMMENT 'Cambio de MS antiguas por nuevas'
   LANGUAGE SQL

BEGIN

  DECLARE done INT DEFAULT FALSE;
  DECLARE newID,newAccount_id,newPublisher_id,newAdvertiser_id INT;
  DECLARE newTracker_id,newTracker_name,newTracklink VARCHAR(200);
  
  DECLARE new_tracking  CURSOR 
   FOR SELECT `id`,`Publisher_id`,`Advertiser_id`,`Account_id`,`Tracker_id`,`Tracker_name`,`Tracklink` 
       FROM campaign_tracking_sources
       WHERE `Status_id`!='1'
       ;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  SET @Version='v1 20.02.2024';

  OPEN new_tracking;

-- --------------------------------------------------------
  read_loop: LOOP
    FETCH new_tracking INTO newID,newPublisher_id,newAdvertiser_id,newAccount_id,newTracker_id,newTracker_name,newTracklink;

    IF done THEN LEAVE read_loop; END IF;
    
    SET @MSid2update=(
      SELECT id FROM `campaign_marketing_source_refresh`
      WHERE `Tracker_ID`  IS NULL 
        AND `Publisher_id`  =newPublisher_id
        AND `Advertiser_id` =newAdvertiser_id 
        AND `Username_id`   =newAccount_id -- 20.02.2024
      LIMIT 1      
        );
        
    IF @MSid2update > '0' THEN
       
       UPDATE `campaign_marketing_source_refresh`
       SET `Username_id`   =newAccount_id
          ,`Tracker_ID`    =newTracker_id
          ,`Tracker_Name`  =newTracker_name
          ,`Tracklink`     =newTracklink
       WHERE id = @MSid2update;
       
       UPDATE `campaign_tracking_sources`
       SET Status_id="1"
       WHERE id = newID;

    END IF; 
 
  END LOOP;
-- --------------------------------------------------------
  CLOSE new_tracking;

END$$
DELIMITER ;

-- TEST --------------
-- call marketing_source_refresh(); 