/* EVENT_Snapshot_day_by_day_fact1_event.sql

   15.07.2022 V1     Lanza Update DbD_fact1 y DbD_fact2
   25.09.2022 v1.1   Lanza Show_Diff_CPA_DbD_yesterday('SET') a partir de las 23
   02.10.2022 v1.2   Lanza total_monthy_comm_ges_upd()
   09.11.2022 v1.3   Lanza CALL Status_tables_upd();
   16.03.2023 v1.4   Lanza total_monthy_comm_aff_upd()
   19.04.2023        Cambio de parámetro en Show_Diff_CPA_DbD_yesterday()
   20.03.2024 v1.5   Ejecución MS_Status_6_Reset el día 1 de cada mes entre las 00:25 y 0:35
                     Eliminación CALL Status_tables_upd(); por obsoleta
   25.07.2024 V1.6   Actualización de tabla exchange_rate 
   05.09.2024 V1.6a  Reemplazo procedure exchange_rate por sync_common_tables_upd
   22.02.2025 v1.7   Update Country_web en campaign_mkt_source_url 
   07.03.2025 v1.8   Agregado proceso generación log dashboard
                     Se instala en todas las DB pero hace LEAVE 
                     IF DATABASE() IN ("euroaffiliati_dev,marca_blanca,affiliateaccess")
   22.03.2025 v1.8.1 Proceso exclusivo de affiliaterevolution pasa datos de players_netrefer_API a Snapshot_day_by_day
   25.03.2025        Proceso de generación de postbacks 
   30.03.2025        Pasa datos HISTORICOS de Snapshot_day_by_day a Snapshot_day_by_day_YYYY (DEFAULT CURDATE-4 MESES)
   04.04.2025        Pasa datos HISTORICOS de Snapshot_day_by_day_fact1/2 a Snapshot_day_by_day_fact1/2_YYYY (DEFAULT CURDATE-24 MESES) -- 04.04.2025
   06.04.2025 v1.8.2 Proceso de generación de postbacks habilitado para todas las db
                     Lógica de generación log dashboard CM siempre y LM entre días 1 a 5
   08.04.2025 v1.8.3 Proceso adicional en affiliaterevolution para LM en días 6 y 17
   11.09.2025 v1.8.4 Proceso de movimientos manuales
   03.12.2025 v1.8.5 Actualiza la tabla dash_total_by_month
   24.02.2026 v1.8.6 Comprobacion cada hora de ultima actualizacion de datos y ejecucion de Bot
   17.03.2026 v1.8.7 Notificación de CPA missing
   27.03.2026 v1.8.8 Regenera indice players_netrefer_API_idx
   12.04.2026 v1.8.9 Fix en IF DATABASE() IN ("euroaffiliati_dev","marca_blanca","affiliateaccess")
   15.04.2026 v1.8.10 Actualiza la tabla dash_total_by_month cada media hora
   06.06.2026 v1.8.11 Fix en Dash_Gestor_TotalByAdvertiser rec_log=yes CM días 1 a 5
   08.06.2026 v1.8.12 Recalcula facturas de Proforma y actualiza tabla campaign_publisher_invoice
   12.06.2026 v1.8.13 Cálculo y generación de movimientos DbD_manual para compensar exceso de Cap
                     Pausa automática (Status_id=6) por exceso de CPA a nivel Operator/Brand/Account/Affiliate
   16.06.2026 v1.8.14 Desvío de ejecución de Report_players_netrefer a Report_players_general
   19.06.2026 v1.8.15 Ejecución de Snapshot_day_by_day_fact1_upd_from_dbd_manual para CM y LM
   22.06.2026 v1.8.16 Recálculo de log dashboard CM y LM
   24.06.2026 v1.8.17 Cálculo y generación de movimientos DbD_manual para compensar CPA que no llegan al baseline del afiliado
   20.07.2026 v1.8.18 Actualiza Product_Real=Product en Snapshot_day_by_day hasta que se actualicen los bots
*/

DROP EVENT IF EXISTS Snapshot_day_by_day_fact1_event;
-- -----------------------------------------------------
DELIMITER //

CREATE EVENT `Snapshot_day_by_day_fact1_event`
	ON SCHEDULE EVERY 30 MINUTE STARTS '2025-01-01 00:15:00'
	ON COMPLETION PRESERVE ENABLE
	COMMENT 'v1.8.18 20.07.2026: Update Snapshot_day_by_day_fact1/fact2+Commiss+log dashboard+Baseline_check_to_DbD_manual+Actualiza Product_Real=Product en Snapshot_day_by_day hasta que se actualicen los bots'
   DO 
   
Main_Label: BEGIN
   SET @Version         ='v1.8.18 20.07.2026';
   SET @CurrentDay      =curdate();
   
   -- Pasa actualizaciones tablas comunues desde ea2 a las otras db
   IF DATABASE()!="euroaffiliati2" AND HOUR(NOW()) IN (06,13,19) AND MINUTE(NOW())<30
   THEN CALL sync_common_tables_upd(); 
   END IF;
   
   -- No ejecuta en estas DB -- 07.03.2025 --------
   IF DATABASE() IN ("euroaffiliati_dev","marca_blanca","affiliateaccess")
   THEN LEAVE Main_Label; 
   END IF;    
   
   /*-----------------------------------------------------------------*/
   
   -- Proceso de datos de entrada
   call Cap_excess_to_DbD_manual('');           -- 12.06.2026 Cálculo y generación de movimientos DbD_manual para compensar exceso de Cap
   call Cap_excess_by_level_Set_Status('');     -- 12.06.2026 Pausa automática (Status_id=6) por exceso de CPA a nivel Operator/Brand/Account/Affiliate
   -- CALL Update_auto_from_dbd_manual('NO');      -- Datos manuales Sin información de debug - 11.09.2025
   CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('CM');   
   CALL Snapshot_day_by_day_fact1_upd_from_dbd_manual('LM');   
   
   -- 20.07.2026 Actualiza Product_Real=Product en Snapshot_day_by_day hasta que se actualicen los bots
   UPDATE Snapshot_day_by_day f SET f.Product_Real=f.Product,f.Product="" 
   WHERE DATE>="2026-04-01" AND LEFT(f.Product, 20) REGEXP "[0-9]{2}";

   CALL Snapshot_day_by_day_fact1_upd();        -- Determina cuando debe procesal LM, además de CM
   CALL Snapshot_day_by_day_fact2_upd_cm();
   
   -- Recálculo de comisiones
   CALL total_monthy_comm_ges_upd('');
   CALL total_monthy_comm_aff_upd('');

   -- Recálculo de log dashboard
   call Dash_Gestor_TotalByAdvertiser('Month=CM,Rec_log=DASH');
   call Dash_Gestor_TotalByAdvertiser('Month=LM,Rec_log=DASH');
   
   -- Update Country_web en campaign_mkt_source_url -- 22.02.2025
   CALL `campaign_mkt_source_url_upd_country`();
   
   -- -------------------------------------------------------------------------------------
   -- Proceso de generación de postbacks - 25.03.2025
   -- IF DATABASE()="euroaffiliati2" 
   -- THEN CALL Postback_for_Affiliate(''); 
   -- END IF;
   -- Habilitado para todas las db 06.04.2025
   CALL Postback_for_Affiliate(''); 
   
   /*-----------------------------------------------------------------*/ 
   -- Restablece Status activo para los que estaban con Status=6 (Paused until next month)
   IF   DAY(NOW())=01 AND HOUR(NOW())=00 AND MINUTE(NOW())<30 
   THEN CALL MS_Status_6_Reset('debug=NO');
   END IF;
   
   -- Toma cant de CPA por MS para comparar con día siguiente
   IF   HOUR(NOW())>22 
   THEN CALL Show_Diff_CPA_DbD_yesterday('Action=SET'); 
        CALL Show_Diff_CPA_DbD_90days('Action=SET'); 
   END IF;
   
      -- proceso generación log dashboard A LAS 15:15 Y 23:15 -- 07.03.2025
   IF HOUR(NOW()) IN (15,23) AND MINUTE(NOW())<30
   THEN CALL Dash_Gestor_TotalByAdvertiser('month=CM,rec_log=yes'); 
   END IF; 

   -- proceso generación log dashboard A LAS 15:15 Y 23:15
   CALL DashTotalByMonth('CM');  -- 15.04.2026 Actualiza la tabla dash_total_by_month con el mes actual cada media hora
   IF HOUR(NOW()) IN (9,12,15,18,23) AND MINUTE(NOW())<30
   THEN CALL DashTotalByMonth('LM'); -- Actualiza la tabla dash_total_by_month -- 03.12.2025
        IF DAY(NOW()) BETWEEN 01 AND 05
        THEN CALL Dash_Gestor_TotalByAdvertiser('month=LM,rec_log=yes'); 
        END IF;   
   END IF;   

   -- Pasa datos HISTORICOS 
   --    de Snapshot_day_by_day a Snapshot_day_by_day_YYYY (DEFAULT CURDATE-4 MESES) -- 30.03.2025
   --    de Snapshot_day_by_day_fact1/2 a Snapshot_day_by_day_fact1/2_YYYY (DEFAULT CURDATE-24 MESES) -- 04.04.2025
   IF   DAY(NOW())=01 AND HOUR(NOW())=00 AND MINUTE(NOW())<30 
   THEN CALL DbD_data_to_history ('');
        CALL DbD_fact_data_to_history ('');
   END IF;   
   
   -- Comprobacion cada hora de ultima actualizacion de datos y ejecucion de Bot -- 24.02.2026
   IF MINUTE(NOW())<30
   THEN CALL Check_Bot_Status('notificar=yes,waitbot=10');
   END IF;

   -- Notificación de CPA missing -- 17.03.2026
   IF HOUR(NOW())=12 AND MINUTE(NOW())<30
   THEN CALL Show_Diff_CPA_DbD_yesterday('Action=notify');
   END IF;

   -- Recalcula facturas de Proforma y actualiza tabla campaign_publisher_invoice -- 08.06.2026
   IF HOUR(NOW()) in (12,18) AND MINUTE(NOW())<30
   THEN CALL Publisher_balance_to_Proforma('month=LM,EXPORT=YES');
   END IF;
   
   -- Regenera indice players_netrefer_API_idx -- 27.03.2026
   IF HOUR(NOW()) in (12,18) AND MINUTE(NOW())<30
   THEN call Report_players_general('genidx=yes');
         CALL Baseline_check_to_DbD_manual('');     -- 24.06.2026 Cálculo y generación de movimientos DbD_manual para compensar CPA que no llegan al baseline del afiliado
      -- call Report_players_netrefer('genidx=yes'); -- DESVIO DESDE 16.06.2026
   END IF;
   -- -------------------------------------------------------------------------------------  

   -- Proceso exclusivo de affiliaterevolution pasa datos de players_netrefer_API a Snapshot_day_by_day
   -- Proceso transferido a EVENT_Snapshot_day_by_day_fact1_event_AR.sql
   -- IF DATABASE()="affiliaterevolution" 
   -- THEN 
   --    CALL players_nerefer_to_DbD_AR(''); 
   --    -- Proceso adicional para LM en días específicos
   --    IF DAY(NOW()) IN (08,19) AND HOUR(NOW())=00 AND MINUTE(NOW())<30
   --    THEN CALL players_nerefer_to_DbD_AR('LM');
   --         CALL Snapshot_day_by_day_fact1_upd_from_dbd('LM');
   --    END IF;
   -- END IF;
   
   /*-----------------------------------------------------------------*/
   
END Main_Label;

//
DELIMITER ;
