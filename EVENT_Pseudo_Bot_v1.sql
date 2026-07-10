/* EVENT_Snapshot_day_by_day_fact1_event.sql

   10.12.2024 v1
   
*/

DROP EVENT IF EXISTS Pseudo_Bot_event;
-- -----------------------------------------------------
DELIMITER //

CREATE EVENT `Pseudo_Bot_event`
	ON SCHEDULE EVERY 3 HOUR STARTS '2024-12-01 03:30:00'
	ON COMPLETION PRESERVE ENABLE
	COMMENT 'Update Snapshot_day_by_day from dbOrigen.Snapshot_day_by_day_fact2'
   DO 
BEGIN
   SET @Version         ='v1 10.12.2024';
   SET @CurrentDay      =curdate();
   
   CALL PseudoBOT_Indirect_account();
 
   IF   (HOUR(NOW())>=15 and HOUR(NOW())<=16) OR
        (HOUR(NOW())>=21 and HOUR(NOW())<=22)
   THEN CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('LM');
   END IF;
   
END;
//
DELIMITER ;
