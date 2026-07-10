/**
	PROCEDURE_Snapshot_day_by_day_fact1_upd

Descripción:
  Procedimiento Snapshot_day_by_day_fact1_upd.

Keys:
	
   **	Actualiza tabla Snapshot_day_by_day_fact1 desde view Snapshot_day_by_day_fact
	**	Se lanza desde EVENT
   
	10.05.2022 v1     Actualiza solo mes corriente
	14.05.2022        Primeros dias del mes actualiza mes corriente y anterior antes de las 07:00
	14.05.2022        Snapshot_day_by_day_fact1_upd_lm Actualiza mes corriente y anterior
	14.05.2022        EVENT Snapshot_day_by_day_fact1_event lanza Procedure Snapshot_day_by_day_fact1_upd cada 30 minutos
   05.09.2022        Preparado para la actualización automática junto con el resto de los PROCEDURES
   29.09.2022        Llama a Snapshot_day_by_day_fact1_upd_from_dbd
   03.01.2023        Hasta el día 5 también ejecuta sobre LM
   06.01.2023 v2.1   Forex
   21.01.2023 v2.2   Manual
   09.06.2024 v2.3   Cap_excess_to_DbD_manual
   11.10.2024 v2.4   Eliminados procesos FX
                     Eliminado proceso Betmedia
*/

DROP PROCEDURE IF EXISTS Snapshot_day_by_day_fact1_upd;
-- -----------------------------------------------------

DELIMITER //

CREATE PROCEDURE Snapshot_day_by_day_fact1_upd()
COMMENT 'Actualiza FACT1 desde DbD - MES CORRIENTE/LAST MONTH. Considera Mes Cte hasta dia 5 del mes sigte'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

BEGIN

SET @Version      ='v2.4 11.10.2024';

-- Last Month se ejecuta solamente entre los días 1 y 5 ----------- 
IF DAY(CURDATE()) <= 5 THEN
   CALL Snapshot_day_by_day_fact1_upd_from_dbd           ('LM');
   IF    DATABASE() in ('euroaffiliati2','brasiliacon','euroaffiliati_dev')
   THEN  CALL Cap_excess_to_DbD_manual                   ('LM'); 
   END IF;
   CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual    ('LM');
END IF;

-- Current Month se ejecuta siempre ------------------------------- 
   CALL Snapshot_day_by_day_fact1_upd_from_dbd           ('CM');
   IF    DATABASE() in ('euroaffiliati2','brasiliacon','euroaffiliati_dev') 
   THEN  CALL Cap_excess_to_DbD_manual                   ('CM');
   END IF;
   CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual    ('CM');
-- ----------------------------------------------------------------

END;
//
DELIMITER ;
	
-- -----------------------------------------------------
-- CALL Snapshot_day_by_day_fact1_upd();
-- -----------------------------------------------------

