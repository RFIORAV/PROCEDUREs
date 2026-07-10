/****************************************************/
SET SESSION group_concat_max_len = 10000;
SET @SQL = CONCAT('SELECT ', (SELECT GROUP_CONCAT(CONCAT("`", COLUMN_NAME, "`") ORDER BY ORDINAL_POSITION) FROM
INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA=database() and TABLE_NAME = 'jqe_fm20aff_users_campaigns'), ' 
FROM `jqe_fm20aff_users_campaigns`;');
SELECT @SQL;
/****************************************************/
SELECT TABLE_SCHEMA,TABLE_NAME,CREATE_TIME,UPDATE_TIME
FROM information_schema.`TABLES`
WHERE table_type='BASE TABLE' AND TABLE_NAME LIKE 'monthly_comms_gestor_v5'
-- AND TABLE_SCHEMA =DATABASE() 
;

linkref|user|camp|book|repo|repor|link
nt_acc|

SET NAMES 'utf8mb4' COLLATE 'utf8mb4_0900_ai_ci';
SET collation_connection = utf8mb4_0900_ai_ci;
SET FOREIGN_KEY_CHECKS = 0;
-- ----------------------------

SET @linkref="https://fm2bet.link/4z3s81coch";
SET @linkref="https://record.betpartners.it/_J5O9duDX13VKqXDxdQZqW2Nd7ZgqdRLk/429/";
SET @token=mid(@linkref,21);
SET @token=case when left(@linkef,20)="https://fm2bet.link/" then mid(@linkref,21) else @linkref end;
SELECT @token,@linkref;