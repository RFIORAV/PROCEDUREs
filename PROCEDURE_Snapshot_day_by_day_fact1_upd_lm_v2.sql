/**
	PROCEDURE_Snapshot_day_by_day_fact1_upd_lm

Descripción:
  Procedimiento Snapshot_day_by_day_fact1_upd_lm.
	**	Actualiza tabla Snapshot_day_by_day_fact1 desde view Snapshot_day_by_day_fact
	**	Se lanza desde EVENT
	14.05.2022 Primeros dias del mes actualiza mes corriente y anterior antes de las 07:00
	14.05.2022 Snapshot_day_by_day_fact1_upd_lm Actualiza mes corriente y anterior
	14.05.2022 EVENT Snapshot_day_by_day_fact1_event lanza Procedure Snapshot_day_by_day_fact1_upd cada 30 minutos
   05.09.2022 Preparado para la actualización automática junto con el resto de los PROCEDURES
   29.09.2022 Llama a Snapshot_day_by_day_fact1_upd_from_dbd   

Keys:
  Sin parámetros de entrada documentables.
*/

DROP PROCEDURE IF EXISTS Snapshot_day_by_day_fact1_upd_lm;
-- -----------------------------------------------------
DELIMITER //

CREATE PROCEDURE Snapshot_day_by_day_fact1_upd_lm()
COMMENT 'Actualiza FACT1 desde DbD - Last Month y Cte'
DETERMINISTIC
MODIFIES SQL DATA
-- SQL SECURITY INVOKER

BEGIN

		CALL Snapshot_day_by_day_fact1_upd_from_dbd('LM');
         
END;
//
DELIMITER ;
	
-- -----------------------------------------------------
-- CALL Snapshot_day_by_day_fact1_upd();
-- CALL Snapshot_day_by_day_fact1_upd_lm();
-- -----------------------------------------------------
