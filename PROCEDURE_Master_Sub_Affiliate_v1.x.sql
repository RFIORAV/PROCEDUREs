/* PROCEDURE_Master_Sub_Affiate_v1.sql
      Compone lista de Affiliate_id correspondientes a un MasterAffiliate

Descripción:
  Procedimiento Master_Sub_Affiliate.
      en formato "(1,2,5,8)" para incluir en cláusulas de Query
      Ej: Affiliate_id IN (1,2,5,8)
      
Keys:

MasterAff_id     =[ MasterAff_id ]. Default='' 
Affiliate_ids    =List of Affilate ids

Ejemplos:

SET @Affiliate_list="";
call Master_Sub_Affiliate(441,@Affiliate_list);
SELECT @Affiliate_list;

27.05.2024 v1     Primera versión operativa      
28.02.2026 v1.1   Fix: eliminación de variables globales


*/

DROP PROCEDURE IF EXISTS Master_Sub_Affiliate;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Master_Sub_Affiliate`(
    IN    MasterAff_id    INT
   ,INOUT Affiliate_ids   VARCHAR(250)
   )
   COMMENT 'Affiliate_id list from a MasterAffiliate'
    
proc_label:BEGIN
DECLARE v_Version        VARCHAR(20);
DECLARE v_CurrentDay     DATE;
DECLARE v_MasterAff_id   INT;
DECLARE v_AffiliateGroup INT;
DECLARE v_Affiliate_ids  VARCHAR(250);

-- --------------------------------------------------------------------------------------------
-- Defaults
SET v_Version        ='v1.1 28.02.2026';
SET v_CurrentDay     =CURDATE();

SET v_MasterAff_id   =MasterAff_id;

/************ TRATAMIENTO DE MASTER AFFILIATE **************************************/
SET v_AffiliateGroup=(SELECT group_id FROM account_account_groups 
                      WHERE account_id=v_MasterAff_id AND group_id=4);

IF  v_AffiliateGroup IS NULL
THEN
    Select 'MasterAff_id mandatory' as '' from dual;
    LEAVE proc_label;
END IF;
 
/*---------------------------------------------------------------------------------*/

SET v_Affiliate_ids=(SELECT GROUP_CONCAT(id SEPARATOR ', ') AS ids 
                     FROM account_account 
                     WHERE Second_Level = v_MasterAff_id);

SET Affiliate_ids=CONCAT("(",v_Affiliate_ids,")");

-- SELECT v_MasterAff_id,v_Affiliate_ids,Affiliate_ids; END IF;

END$$
DELIMITER ;
 
/*
SET @Affiliate_list="";
SET @MasterAff_id=440;
call Master_Sub_Affiliate(@MasterAff_id,@Affiliate_list);
SELECT @MasterAff_id,@Affiliate_list;

*/
