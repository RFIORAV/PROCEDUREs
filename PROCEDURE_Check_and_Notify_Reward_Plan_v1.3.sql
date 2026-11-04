/*
PROCEDURE_Check_and_Notify_Reward_Plan_v1.3.sql

Descripción:
  Detecta Reward_plan nuevos en Snapshot_day_by_day_fact1 (últimos N días)
  por Operator_id / Account_id, los guarda en Snapshot_day_by_day_rew_plan
  si aún no existen, y por cada pendiente (Notified=0) crea la entrada en
  campaign_deal_gestor_rewp parseando CPA/RS/BL, notifica en
  account_notifications informando en Extra_id_1 la id generada
  y marca Notified=1.

Observaciones:
  Cada Key debe estar seguida de = y el valor deseado SIN comillas
  Cada par Key=Value debe ir seguido de una COMA
  El conjunto de pares debe ir entre '' (comillas simples) como único parámetro string

Keys:
  Debug = [No | Yes | KeyValues]. OPCIONAL. Default=No.
          Yes       → muestra candidatos a insertar y pendientes de notificar SIN escribir.
          KeyValues → muestra parámetros parseados y ejecuta normalmente.
  Days  = [número]. Días hacia atrás a considerar en fact1. OPCIONAL. Default=90.
  Notify = [Yes | No]. Si No, solo incorpora faltantes sin notificar. OPCIONAL. Default=Yes.
  Init   = [No | Yes]. Primera carga: incorpora planes y marca Notified=1 SIN emitir
           notificaciones. OPCIONAL. Default=No.

Parámetros ('[Key=Value[,...]']')

Ejemplos:
  CALL Check_and_Notify_Reward_Plan('');
  CALL Check_and_Notify_Reward_Plan('Init=Yes');
  CALL Check_and_Notify_Reward_Plan('Days=90,Notify=Yes');
  CALL Check_and_Notify_Reward_Plan('Debug=KeyValues');

24.09.2026 v1   Primera versión operativa
08.10.2026 v1.1 Añadido Advertiser en notificación
16.10.2026 v1.2 Inserta entrada en campaign_deal_gestor_rewp parseando CPA, RS y BL antes del update final
17.10.2026 v1.3 Loop por pendiente: inserta en campaign_deal_gestor_rewp antes de notificar y guarda id en Extra_id_1
*/

SET NAMES 'utf8mb4';

DROP PROCEDURE IF EXISTS Check_and_Notify_Reward_Plan;
-- DROP PROCEDURE IF EXISTS Check_and_Notify_Reward_Plan_dev;

DELIMITER $$
CREATE DEFINER=`b3w1nn3r`@`%` PROCEDURE `Check_and_Notify_Reward_Plan`(IN InputCommLine VARCHAR(250))
COMMENT 'v1.3 17.10.2026 - Detecta Reward_plan nuevos en fact1, inserta en campaign_deal_gestor_rewp y notifica con Extra_id_1'
SQL SECURITY DEFINER
proc_label:BEGIN

  DECLARE v_Version       VARCHAR(32)  DEFAULT 'v1.3 17.10.2026';
  DECLARE v_Debug         VARCHAR(20)  DEFAULT 'NO';
  DECLARE v_Notify        VARCHAR(5)   DEFAULT 'YES';
  DECLARE v_Init          VARCHAR(5)   DEFAULT 'NO';
  DECLARE v_Days          INT          DEFAULT 90;
  DECLARE v_InputCommLine VARCHAR(400) DEFAULT '';
  DECLARE v_e             INT          DEFAULT 0;
  DECLARE v_c             INT          DEFAULT 0;
  DECLARE v_k             VARCHAR(80)  DEFAULT '';
  DECLARE v_v             VARCHAR(250) DEFAULT '';
  DECLARE v_Error         INT          DEFAULT 0;
  DECLARE v_Msg           VARCHAR(250) DEFAULT '';
  DECLARE v_Inserted      INT          DEFAULT 0;
  DECLARE v_Notified      INT          DEFAULT 0;
  DECLARE v_RewpInserted  INT          DEFAULT 0;

  DECLARE v_Done            INT          DEFAULT 0;
  DECLARE v_RP_id           INT          DEFAULT 0;
  DECLARE v_Reward_plan     VARCHAR(100) DEFAULT '';
  DECLARE v_Operator        VARCHAR(100) DEFAULT NULL;
  DECLARE v_Operator_id     INT          DEFAULT 0;
  DECLARE v_Advertiser_Name VARCHAR(150) DEFAULT NULL;
  DECLARE v_Advertiser_id   INT          DEFAULT NULL;
  DECLARE v_Account         VARCHAR(100) DEFAULT NULL;
  DECLARE v_Account_id      INT          DEFAULT 0;
  DECLARE v_raw_cpa         VARCHAR(50)  DEFAULT NULL;
  DECLARE v_raw_rs          VARCHAR(50)  DEFAULT NULL;
  DECLARE v_raw_bl          VARCHAR(50)  DEFAULT NULL;
  DECLARE v_NewRewpId       VARCHAR(30)  DEFAULT '';

  DECLARE cur_pending CURSOR FOR
    SELECT
       S.id
      ,S.Reward_plan
      ,S.Operator
      ,S.Operator_id
      ,S.Advertiser_Name
      ,S.Advertiser_id
      ,S.Account
      ,S.Account_id
      ,COALESCE(
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*(EUR|€)?[[:space:]]*CPA', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, 'CPA[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*€[[:space:]]*\\+', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+[[:space:]]*%', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          /* N+M (sin %): CPA = primer número — ej. 80+30 */
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+$', 1, 1, 'i'), '[^0-9].*$', ''), '')
       ) AS raw_cpa
      ,COALESCE(
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*%', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*RS([^A-Za-z]|$)', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '(^|[^A-Za-z])RS[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
          /* N+M (sin %): RS = segundo número — ej. 80+30 */
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '^[0-9]+[[:space:]]*\\+[[:space:]]*[0-9]+$', 1, 1, 'i'), '^[0-9]+[[:space:]]*\\+[[:space:]]*', ''), '')
       ) AS raw_rs
      ,COALESCE(
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '(^|[^A-Za-z])BL[[:space:]]*[0-9]+', 1, 1, 'i'), '[^0-9]', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '[0-9]+[[:space:]]*BL([^A-Za-z]|$)', 1, 1, 'i'), '[^0-9].*$', ''), ''),
          NULLIF(REGEXP_REPLACE(REGEXP_SUBSTR(S.rp, '\\([0-9]+', 1, 1, 'i'), '[^0-9]', ''), '')
       ) AS raw_bl
    FROM (
      SELECT
         RP.`id`
        ,RP.`Reward_plan`
        ,RP.`Operator`
        ,RP.`Operator_id`
        ,A.`Advertiser_Name` AS Advertiser_Name
        ,U.`Advertiser_id`   AS Advertiser_id
        ,RP.`Account`
        ,RP.`Account_id`
        ,TRIM(RP.`Reward_plan`) AS rp
      FROM `Snapshot_day_by_day_rew_plan` RP
      LEFT JOIN `campaign_username` U ON U.`id` = RP.`Account_id`
      LEFT JOIN `campaign_advertiser` A ON A.`id` = U.`Advertiser_id`
      WHERE RP.`Notified` = 0
    ) S
    ORDER BY S.Account_id, S.Reward_plan;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_Done = 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 v_Msg = MESSAGE_TEXT;
    SET v_Error = 1;
    ROLLBACK;
    SELECT v_Version AS Version, v_Error AS Error, v_Msg AS Message;
  END;

  -- ── Parseo InputCommLine ──────────────────────────────────────────────────────
  SET v_InputCommLine = CONCAT(IFNULL(InputCommLine, ''), ',');
  SET v_InputCommLine = REPLACE(v_InputCommLine, '"', '');

  WHILE v_InputCommLine > ' ' AND INSTR(v_InputCommLine, '=') > 0 DO
    SET v_e = INSTR(v_InputCommLine, '=');
    SET v_c = INSTR(v_InputCommLine, ',');
    SET v_k = TRIM(SUBSTRING(v_InputCommLine, 1, v_e - 1));
    SET v_v = TRIM(SUBSTRING(v_InputCommLine, v_e + 1, v_c - (v_e + 1)));
    SET v_InputCommLine = SUBSTRING(v_InputCommLine, v_c + 1);

    IF       LOWER(v_k) = 'debug'  THEN SET v_Debug  = UPPER(v_v);
      ELSEIF LOWER(v_k) = 'notify' THEN SET v_Notify = UPPER(v_v);
      ELSEIF LOWER(v_k) = 'init'   THEN SET v_Init   = UPPER(v_v);
      ELSEIF LOWER(v_k) = 'days'   THEN SET v_Days   = CAST(v_v AS SIGNED);
    END IF;
  END WHILE;

  -- ── Tabla de planes conocidos ─────────────────────────────────────────────────
  CREATE TABLE IF NOT EXISTS `Snapshot_day_by_day_rew_plan` (
    `id`            INT          NOT NULL AUTO_INCREMENT,
    `Operator`      VARCHAR(100) NULL DEFAULT NULL,
    `Operator_id`   INT          NOT NULL DEFAULT 0,
    `Account`       VARCHAR(100) NULL DEFAULT NULL,
    `Account_id`    INT          NOT NULL DEFAULT 0,
    `Reward_plan`   VARCHAR(100) NOT NULL DEFAULT '',
    `Notified`      TINYINT      NOT NULL DEFAULT 0 COMMENT '0=pendiente notificar; 1=ya notificado',
    `Creation_date` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_account_id_reward_plan` (`Account_id`, `Reward_plan`)
  ) ENGINE=InnoDB COMMENT='Reward_plan distintos por Operator/Account detectados en fact1';

  -- ── Tabla de deals generados desde Reward_plan ────────────────────────────────
  CREATE TABLE IF NOT EXISTS `campaign_deal_gestor_rewp` (
    `id`                      INT           NOT NULL AUTO_INCREMENT,
    `Multilevel`              TINYINT       NULL DEFAULT NULL,
    `Owner`                   VARCHAR(30)   NULL DEFAULT NULL,
    `Deal_Name`               VARCHAR(150)  NULL DEFAULT NULL,
    `Description`             VARCHAR(150)  NULL DEFAULT NULL,
    `traffic_source`          VARCHAR(250)  NULL DEFAULT NULL,
    `CPA_Value`               DECIMAL(12,2) NULL DEFAULT '0.00',
    `RS_Percentage`           DECIMAL(6,2)  NULL DEFAULT '0.00',
    `RS_Percentage_Displayed` DECIMAL(6,2)  NULL DEFAULT '0.00',
    `RS_Base`                 VARCHAR(50)   NULL DEFAULT 'Account',
    `Carry_Over`              TINYINT       NULL DEFAULT '0',
    `RS_Against_CPA`          TINYINT       NULL DEFAULT '0',
    `Valid_From`              DATE          NULL DEFAULT (CURRENT_DATE),
    `Status`                  VARCHAR(30)   NULL DEFAULT '',
    `Status_id`               TINYINT       NULL DEFAULT '1',
    `Baseline`                INT           NULL DEFAULT NULL,
    `Deal_Type`               VARCHAR(10)   NULL DEFAULT NULL,
    `Country`                 VARCHAR(50)   NULL DEFAULT NULL,
    `Currency`                VARCHAR(5)    NULL DEFAULT NULL,
    `Product`                 VARCHAR(100)  NULL DEFAULT NULL,
    `Advertiser`              VARCHAR(150)  NULL DEFAULT NULL,
    `Advertiser_id`           INT           NULL DEFAULT NULL,
    `Account`                 VARCHAR(150)  NULL DEFAULT NULL,
    `Account_id`              INT           NULL DEFAULT NULL,
    `Operator`                VARCHAR(150)  NULL DEFAULT NULL,
    `Operator_id`             INT           NULL DEFAULT NULL,
    `Campaign_id`             INT           NULL DEFAULT NULL,
    `Last_Update`             DATETIME      NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `Creation_Date`           DATETIME      NULL DEFAULT CURRENT_TIMESTAMP,
    `User`                    VARCHAR(30)   NULL DEFAULT '',
    PRIMARY KEY (`id`) USING BTREE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

  START TRANSACTION;

  -- ── Incorporar Reward_plan faltantes ──────────────────────────────────────────
  INSERT IGNORE INTO `Snapshot_day_by_day_rew_plan` (
     `Operator`
    ,`Operator_id`
    ,`Account`
    ,`Account_id`
    ,`Reward_plan`
    ,`Notified`
    ,`Creation_date`
  )
  SELECT
     MAX(IFNULL(P.`Advertiser_Name`, '')) AS `Operator`
    ,F.`Publisher_id`                     AS `Operator_id`
    ,MAX(IFNULL(F.`Username`, ''))        AS `Account`
    ,F.`Username_id`                      AS `Account_id`
    ,F.`Reward_plan`
    ,IF(v_Init = 'YES', 1, 0)
    ,NOW()
  FROM `Snapshot_day_by_day_fact1` F
  LEFT JOIN `campaign_publisher` P ON P.`id` = F.`Publisher_id`
  WHERE F.`Date` >= DATE_SUB(CURDATE(), INTERVAL v_Days DAY)
    AND IFNULL(TRIM(F.`Reward_plan`), '') <> ''
    AND IFNULL(F.`Username_id`, 0) > 0
  GROUP BY F.`Username_id`, F.`Reward_plan`;

  SET v_Inserted = ROW_COUNT();

  -- ── Loop por cada pendiente de notificar ──────────────────────────────────────
  SET v_Done = 0;
  OPEN cur_pending;

  read_loop: LOOP
    FETCH cur_pending INTO
       v_RP_id
      ,v_Reward_plan
      ,v_Operator
      ,v_Operator_id
      ,v_Advertiser_Name
      ,v_Advertiser_id
      ,v_Account
      ,v_Account_id
      ,v_raw_cpa
      ,v_raw_rs
      ,v_raw_bl;

    IF v_Done = 1 THEN
      LEAVE read_loop;
    END IF;

    SET v_NewRewpId = '';

    -- Crear entrada en campaign_deal_gestor_rewp antes de notificar
    IF v_raw_cpa IS NOT NULL OR v_raw_rs IS NOT NULL THEN
      INSERT INTO `campaign_deal_gestor_rewp` (
         `id`
        ,`Multilevel`
        ,`Owner`
        ,`Deal_Name`
        ,`Description`
        ,`traffic_source`
        ,`CPA_Value`
        ,`RS_Percentage`
        ,`RS_Percentage_Displayed`
        -- ,`RS_Base`
        -- ,`Carry_Over`
        -- ,`RS_Against_CPA`
        -- ,`Valid_From`
        -- ,`Status`
        -- ,`Status_id`
        ,`Baseline`
        -- ,`Deal_Type`
        -- ,`Country`
        -- ,`Currency`
        ,`Product`
        ,`Advertiser`
        ,`Advertiser_id`
        ,`Account`
        ,`Account_id`
        ,`Operator`
        ,`Operator_id`
        ,`Campaign_id`
        ,`Last_Update`
        ,`Creation_Date`
        ,`User`
      ) VALUES (
         NULL
        ,NULL
        ,NULL
        ,v_Reward_plan
        ,v_Reward_plan
        ,NULL
        ,CAST(IFNULL(v_raw_cpa, 0) AS UNSIGNED)
        ,CAST(IFNULL(v_raw_rs,  0) AS UNSIGNED)
        ,CAST(IFNULL(v_raw_rs,  0) AS UNSIGNED)
        -- ,NULL
        -- ,NULL
        -- ,NULL
        -- ,NULL
        -- ,NULL
        -- ,NULL
        ,CAST(NULLIF(IFNULL(v_raw_bl, ''), '') AS UNSIGNED)
        -- ,NULL
        -- ,NULL
        -- ,NULL
        ,v_Reward_plan
        ,v_Advertiser_Name
        ,v_Advertiser_id
        ,v_Account
        ,v_Account_id
        ,v_Operator
        ,v_Operator_id
        ,NULL
        ,NOW()
        ,NOW()
        ,'SysOp'
      );

      SET v_NewRewpId    = CAST(LAST_INSERT_ID() AS CHAR);
      SET v_RewpInserted = v_RewpInserted + 1;
    END IF;

    -- Crear notificación con Extra_id_1 = id del nuevo registro en campaign_deal_gestor_rewp
    INSERT INTO `account_notifications` (
      `id`, `Affiliate_id`, `Extra_id_1`, `Extra_id_2`, `Extra_id_3`,
      `Testo`, `FromUser`, `Type`, `Status`, `Status_id`,
      `Read_Status`, `Comm_Status`, `Date`, `Owner`, `Subtype`,
      `Detail`, `Action`, `Creation_Date`, `Last_Update`, `Operator`
    ) VALUES (
      NULL, '2', v_NewRewpId, '', '',
      CONCAT_WS(' - ', 'NEW REWARD PLAN', v_Reward_plan, v_Operator, v_Advertiser_Name, v_Account),
      'Manager', 'New Reward Plan', 'Pending', '0',
      0, '', NOW(), '', '',
      '', '', NOW(), NOW(), 'SysOp'
    );

    SET v_Notified = v_Notified + 1;

    UPDATE `Snapshot_day_by_day_rew_plan`
    SET `Notified` = 1
    WHERE `id` = v_RP_id;

  END LOOP;

  CLOSE cur_pending;

  COMMIT;

END$$
DELIMITER ;
