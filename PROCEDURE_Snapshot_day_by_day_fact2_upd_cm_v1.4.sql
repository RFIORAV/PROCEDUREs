/* PROCEDURE UPDATE_day_by_day_fact2_current_month
   30.08.2022 V1     Actualiza Snapshot_day_by_day_fact2 para Mes Cte (hasta dia 3 del mes sigte)

Descripción:
  Procedimiento Snapshot_day_by_day_fact2_upd_cm.
                     Exige cambiar VIEW_monthly_fact_aff2.sql

Keys:
                     
   09.12.2022 V1.2   Agrupa por Producto. Elimina la cláusula HAVING
   03.02.2023 v1.3   FX
   21.11.2023 v1.3.1 Fix: sum(Qualified_Players_Adjusted) AS Qualified_Players,sum(Qualified_Players) AS Qualified_Players_Adjusted
   22.05.2024 v1.4   Llama a Sync_Fact2_from_Fact1
   03.06.2024 v1.4.1 Fix. Ejecuta month=CM siempre y month=LM días 1 a 3
*/
DROP PROCEDURE IF EXISTS Snapshot_day_by_day_fact2_upd_cm;

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;

DELIMITER $$
CREATE PROCEDURE Snapshot_day_by_day_fact2_upd_cm()
   COMMENT 'FACT2-UPDATE CurrMonth desde FACT1 - Considera Mes Cte hasta dia 3 del mes sigte - CALL Sync_Fact2_from_Fact1'
   LANGUAGE SQL
    
BEGIN

DECLARE MesCorriente VARCHAR(7) DEFAULT left(curdate(),7);

SET @Version='v1.4.1 03.06.2024';
    
CALL Sync_Fact2_from_Fact1('mode=run,month=CM');

IF DAY(CURDATE()) <= 3 THEN
   SET @ParamProc=CONCAT("mode=run,month=LM,MS_id=allall,debug=no,db=",database());
   CALL Sync_Fact2_from_Fact1(@ParamProc);
END IF;

END$$
DELIMITER ;

/*
select @ParamProc;
*/