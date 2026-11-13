/*
CREATE_TABLE_util_options_v2.sql

Catálogo de opciones para los campos de los componentes React (portalv2) que despliegan
una lista y piden al usuario elegir un elemento (react-select). Cada opción se presenta
con etiqueta y explicación en el idioma seleccionado en la app.

Tablas:
  - util_languages       : idiomas de la app (códigos i18next: en, es, it, pt)
  - util_option_groups   : un grupo por campo/dominio (ej. ACCOUNT_STATUS, PRODUCT)
  - util_options         : opciones de cada grupo (valor técnico, orden, default, color, icono, padre)
  - util_options_i18n    : etiqueta + explicación por opción e idioma
  - util_options_access  : perfiles que pueden ver la opción (sin filas = visible para todos)

Reglas:
  - Option_value es el valor técnico que se guarda en el campo. Nunca se traduce ni se cambia;
    si deja de usarse, Is_active=0 (no borrar: los datos de otras tablas lo guardan sin FK).
  - Un grupo por campo: códigos iguales pueden significar cosas distintas en otro campo
    (ej. Status 1 = Active en cuentas, 1 = Confirmed en movimientos financieros).
  - Value_type indica al API cómo devolver el valor al frontend (INT -> número, STRING -> texto),
    para que la comparación en JS (===) coincida con el valor del registro.
  - Idioma: lo elige el usuario en la app (i18next, se guarda solo en el navegador).
    El frontend lo envía en cada petición. Si falta la traducción se usa 'en';
    si tampoco existe, Label = Option_value y Description = ''.
  - Perfil: account_account_groups.group_id (2=Gestor, 3=Affiliate), el mismo que devuelve
    read_alias() en Django. Sin FK a auth_group porque es una tabla gestionada por Django.
  - Opciones dependientes: Parent_option_id apunta a una opción de otro grupo. El componente
    hijo muestra solo las opciones cuyo padre es el valor elegido en el componente padre
    (NULL = sin dependencia). Una opción tiene un único padre.
  - Is_default: preselección en formularios. No se fuerza unicidad por grupo (un multiselect
    puede tener varias); el control (d) lista los grupos de selección simple con más de una.
  - Color: color de badge de reactstrap tal como se usa hoy (light-success, light-danger...).
    Icon: nombre del icono (mismo criterio que dash_modules.Settings icon=...).

Compatibilidad: MySQL 8.0.37 (CHECK aplicado desde 8.0.16). Sin sintaxis 8.4+.

Pasos:
  0. Solo si se ejecutó la v1: eliminar sus tablas (estructura incompatible). Ver bloque 0.
  1. Crear tablas.
  2. Carga inicial de idiomas y de los dominios de negocio sin ambigüedad encontrados en portalv2.
  3. Consultas de prueba / control.

06.11.2026 v1   Primera versión (util_options + util_options_i18n, orientada a util_settings)
06.11.2026 v2   Rediseño para todos los campos de selección de portalv2: grupos, idiomas,
                Value_type, default, color/icono, opciones dependientes y visibilidad por perfil
*/

-- ============================================================================
-- 0. (SOLO SI SE EJECUTÓ LA v1) Eliminar tablas v1 — contienen solo la carga inicial
-- ============================================================================
/*
DROP TABLE IF EXISTS `util_options_i18n`;
DROP TABLE IF EXISTS `util_options`;
*/

-- ============================================================================
-- 1. Tablas
-- ============================================================================

CREATE TABLE IF NOT EXISTS `util_languages` (
   `Lang`          VARCHAR(5)   NOT NULL                 COMMENT 'Código i18next: en, es, it, pt',
   `Name`          VARCHAR(50)  NOT NULL                 COMMENT 'Nombre nativo del idioma',
   `Sort_order`    SMALLINT     NOT NULL DEFAULT 0,
   `Is_active`     TINYINT      NOT NULL DEFAULT 1,
   `Creation_Date` DATETIME     NULL     DEFAULT (NOW()),
   `Last_Update`   DATETIME     NULL     DEFAULT (NOW()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`      VARCHAR(30)  NULL     DEFAULT ' ',
   PRIMARY KEY (`Lang`) USING BTREE,
   CONSTRAINT `chk_util_languages_active` CHECK (`Is_active` IN (0,1))
)
COMMENT='Idiomas de la app para traducción de opciones'
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `util_option_groups` (
   `id`            INT          NOT NULL AUTO_INCREMENT,
   `Group_code`    VARCHAR(50)  NOT NULL                 COMMENT 'Código del grupo. Ej: ACCOUNT_STATUS',
   `Description`   VARCHAR(250) NULL     DEFAULT NULL    COMMENT 'Uso interno: qué campo/columna usa el grupo',
   `Value_type`    VARCHAR(10)  NOT NULL DEFAULT 'STRING' COMMENT 'INT | STRING: tipo con el que el API devuelve Option_value',
   `Is_active`     TINYINT      NOT NULL DEFAULT 1,
   `Creation_Date` DATETIME     NULL     DEFAULT (NOW()),
   `Last_Update`   DATETIME     NULL     DEFAULT (NOW()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`      VARCHAR(30)  NULL     DEFAULT ' ',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE INDEX `UX_util_option_groups_code` (`Group_code`) USING BTREE,
   CONSTRAINT `chk_util_option_groups_type`   CHECK (`Value_type` IN ('INT','STRING')),
   CONSTRAINT `chk_util_option_groups_active` CHECK (`Is_active` IN (0,1))
)
COMMENT='Grupos de opciones: uno por campo/dominio de selección'
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `util_options` (
   `id`               INT          NOT NULL AUTO_INCREMENT,
   `Group_id`         INT          NOT NULL              COMMENT 'FK util_option_groups.id',
   `Option_value`     VARCHAR(100) NOT NULL              COMMENT 'Valor técnico que se guarda en el campo',
   `Parent_option_id` INT          NULL     DEFAULT NULL COMMENT 'FK util_options.id (otro grupo). NULL = sin dependencia',
   `Sort_order`       SMALLINT     NOT NULL DEFAULT 0    COMMENT 'Orden de presentación dentro del grupo',
   `Is_default`       TINYINT      NOT NULL DEFAULT 0    COMMENT '1 = preseleccionada en formularios',
   `Color`            VARCHAR(30)  NULL     DEFAULT NULL COMMENT 'Color badge reactstrap. Ej: light-success',
   `Icon`             VARCHAR(50)  NULL     DEFAULT NULL COMMENT 'Nombre de icono. Ej: DollarSign',
   `Is_active`        TINYINT      NOT NULL DEFAULT 1    COMMENT '1 = visible, 0 = retirada (se conserva para datos históricos)',
   `Creation_Date`    DATETIME     NULL     DEFAULT (NOW()),
   `Last_Update`      DATETIME     NULL     DEFAULT (NOW()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`         VARCHAR(30)  NULL     DEFAULT ' ',
   PRIMARY KEY (`id`) USING BTREE,
   UNIQUE INDEX `UX_util_options_group_value` (`Group_id`, `Option_value`) USING BTREE,
   INDEX `IX_util_options_group_order` (`Group_id`, `Is_active`, `Sort_order`) USING BTREE,
   INDEX `IX_util_options_parent` (`Parent_option_id`) USING BTREE,
   CONSTRAINT `fk_util_options_group`
      FOREIGN KEY (`Group_id`) REFERENCES `util_option_groups` (`id`)
      ON DELETE RESTRICT ON UPDATE CASCADE,
   CONSTRAINT `fk_util_options_parent`
      FOREIGN KEY (`Parent_option_id`) REFERENCES `util_options` (`id`)
      ON DELETE RESTRICT ON UPDATE CASCADE,
   CONSTRAINT `chk_util_options_default` CHECK (`Is_default` IN (0,1)),
   CONSTRAINT `chk_util_options_active`  CHECK (`Is_active`  IN (0,1))
)
COMMENT='Opciones de cada grupo para componentes de selección'
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `util_options_i18n` (
   `Option_id`     INT          NOT NULL                 COMMENT 'FK util_options.id',
   `Lang`          VARCHAR(5)   NOT NULL                 COMMENT 'FK util_languages.Lang',
   `Label`         VARCHAR(100) NOT NULL                 COMMENT 'Texto visible en la lista',
   `Description`   VARCHAR(500) NULL     DEFAULT NULL    COMMENT 'Explicación de la opción (tooltip / ayuda)',
   `Creation_Date` DATETIME     NULL     DEFAULT (NOW()),
   `Last_Update`   DATETIME     NULL     DEFAULT (NOW()) ON UPDATE CURRENT_TIMESTAMP,
   `Operator`      VARCHAR(30)  NULL     DEFAULT ' ',
   PRIMARY KEY (`Option_id`, `Lang`) USING BTREE,
   INDEX `IX_util_options_i18n_lang` (`Lang`) USING BTREE,
   CONSTRAINT `fk_util_options_i18n_option`
      FOREIGN KEY (`Option_id`) REFERENCES `util_options` (`id`)
      ON DELETE CASCADE ON UPDATE CASCADE,
   CONSTRAINT `fk_util_options_i18n_lang`
      FOREIGN KEY (`Lang`) REFERENCES `util_languages` (`Lang`)
      ON DELETE RESTRICT ON UPDATE CASCADE
)
COMMENT='Etiqueta y explicación de cada opción por idioma'
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `util_options_access` (
   `Option_id`        INT         NOT NULL               COMMENT 'FK util_options.id',
   `Account_group_id` INT         NOT NULL               COMMENT 'account_account_groups.group_id: 2=Gestor, 3=Affiliate',
   `Creation_Date`    DATETIME    NULL     DEFAULT (NOW()),
   `Operator`         VARCHAR(30) NULL     DEFAULT ' ',
   PRIMARY KEY (`Option_id`, `Account_group_id`) USING BTREE,
   CONSTRAINT `fk_util_options_access_option`
      FOREIGN KEY (`Option_id`) REFERENCES `util_options` (`id`)
      ON DELETE CASCADE ON UPDATE CASCADE
)
COMMENT='Perfiles que ven la opción. Sin filas para una opción = visible para todos'
COLLATE='utf8mb4_0900_ai_ci'
ENGINE=InnoDB;

-- ============================================================================
-- 2. Carga inicial (idempotente)
-- ============================================================================

INSERT IGNORE INTO `util_languages` (`Lang`, `Name`, `Sort_order`, `Operator`) VALUES
   ('en', 'English',   1, 'setup'),
   ('es', 'Español',   2, 'setup'),
   ('it', 'Italiano',  3, 'setup'),
   ('pt', 'Português', 4, 'setup');

-- Grupos: dominios de negocio de portalv2 cuyo significado no es ambiguo
INSERT IGNORE INTO `util_option_groups` (`Group_code`, `Value_type`, `Description`, `Operator`) VALUES
   ('ACCOUNT_STATUS',     'INT',    'Estado de cuenta/affiliate (Django Account.Status_Choice). statusColor en Account, Affiliate, Channel', 'setup'),
   ('ACTIVE_INACTIVE',    'INT',    'Activo/Inactivo 1/0. STATUS_OPTIONS, optionsStatus, optionsVerified', 'setup'),
   ('YES_NO_INT',         'INT',    'Sí/No 1/0. invoiceAccountOptions, optionRevenueShareCarryOver', 'setup'),
   ('YES_NO',             'STRING', 'Sí/No YES/NO (colación case-insensitive: cubre yes/no). util_settings, optionsFollowUp', 'setup'),
   ('TICKET_STATUS',      'INT',    'Estado de ticket. viewsLite/Ticketing', 'setup'),
   ('TRAFFIC_SOURCE',     'STRING', 'Fuente de tráfico del canal. TrafficSource / optionsTrafficSource', 'setup'),
   ('PRODUCT',            'STRING', 'Producto. optionProduct / typeProduct', 'setup'),
   ('BUSINESS_CATEGORY',  'STRING', 'Categoría de advertiser/brand/publisher. optionCategory', 'setup'),
   ('AFFILIATE_PLATFORM', 'STRING', 'Plataforma de afiliación del advertiser/brand/publisher. optionPlatform', 'setup'),
   ('CURRENCY',           'STRING', 'Moneda de la cuenta. Account/Form Currency', 'setup'),
   ('ACCOUNT_AREA',       'STRING', 'Área de negocio de la cuenta. Account/Form Areas', 'setup'),
   ('BONUS_CONDITIONS',   'STRING', 'Condición de umbrales de bonus (campaign_deal_affiliate_bonus.Conditions)', 'setup'),
   ('INVOICE_CATEGORY',   'STRING', 'Tipo de documento de facturación. categoryOptions', 'setup');

INSERT IGNORE INTO `util_options` (`Group_id`, `Option_value`, `Sort_order`, `Color`, `Is_default`, `Operator`)
SELECT G.`id`, O.Val, O.Ord, O.Color, O.Dflt, 'setup'
FROM `util_option_groups` G
JOIN (
             SELECT 'ACCOUNT_STATUS' AS Grp, '1' AS Val, 1 AS Ord, 'light-success' AS Color, 1 AS Dflt
   UNION ALL SELECT 'ACCOUNT_STATUS',     '3',              2, 'light-danger',    0
   UNION ALL SELECT 'ACCOUNT_STATUS',     '4',              3, 'light-secondary', 0
   UNION ALL SELECT 'ACCOUNT_STATUS',     '6',              4, 'light-secondary', 0
   UNION ALL SELECT 'ACTIVE_INACTIVE',    '1',              1, 'light-success',   1
   UNION ALL SELECT 'ACTIVE_INACTIVE',    '0',              2, 'light-secondary', 0
   UNION ALL SELECT 'YES_NO_INT',         '1',              1, NULL,              0
   UNION ALL SELECT 'YES_NO_INT',         '0',              2, NULL,              0
   UNION ALL SELECT 'YES_NO',             'YES',            1, NULL,              0
   UNION ALL SELECT 'YES_NO',             'NO',             2, NULL,              0
   UNION ALL SELECT 'TICKET_STATUS',      '1',              1, 'info',            1
   UNION ALL SELECT 'TICKET_STATUS',      '2',              2, 'warning',         0
   UNION ALL SELECT 'TICKET_STATUS',      '3',              3, 'success',         0
   UNION ALL SELECT 'TICKET_STATUS',      '4',              4, 'danger',          0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Social',         1, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Seo',            2, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Website',        3, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'SMS',            4, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'MediaBuy',       5, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'App',            6, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Mail',           7, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Marketing',      8, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'DAM',            9, NULL, 0
   UNION ALL SELECT 'TRAFFIC_SOURCE',     'Altro',         10, NULL, 0
   UNION ALL SELECT 'PRODUCT',            'Sport',          1, NULL, 0
   UNION ALL SELECT 'PRODUCT',            'Casino',         2, NULL, 0
   UNION ALL SELECT 'PRODUCT',            'Hybrid',         3, NULL, 0
   UNION ALL SELECT 'PRODUCT',            'Forex',          4, NULL, 0
   UNION ALL SELECT 'BUSINESS_CATEGORY',  'Gambling',       1, NULL, 0
   UNION ALL SELECT 'BUSINESS_CATEGORY',  'Forex',          2, NULL, 0
   UNION ALL SELECT 'BUSINESS_CATEGORY',  'Finance',        3, NULL, 0
   UNION ALL SELECT 'BUSINESS_CATEGORY',  'Insurace',       4, NULL, 0   -- valor con errata tal como se guarda hoy
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Cellxpert',      1, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Entain',         2, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Income Access',  3, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'LivePartners',   4, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Mexos',          5, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'MyAffiliates',   6, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Netrefer',       7, NULL, 0
   UNION ALL SELECT 'AFFILIATE_PLATFORM', 'Other',          8, NULL, 0
   UNION ALL SELECT 'CURRENCY',           'EUR',            1, NULL, 1
   UNION ALL SELECT 'CURRENCY',           'USD',            2, NULL, 0
   UNION ALL SELECT 'CURRENCY',           'GBP',            3, NULL, 0
   UNION ALL SELECT 'ACCOUNT_AREA',       'gaming',         1, NULL, 0
   UNION ALL SELECT 'ACCOUNT_AREA',       'forex',          2, NULL, 0
   UNION ALL SELECT 'BONUS_CONDITIONS',   'ANY',            1, NULL, 1
   UNION ALL SELECT 'BONUS_CONDITIONS',   'ALL',            2, NULL, 0
   UNION ALL SELECT 'INVOICE_CATEGORY',   'Invoice',        1, NULL, 0
   UNION ALL SELECT 'INVOICE_CATEGORY',   'Proforma',       2, NULL, 0
) O ON O.Grp = G.`Group_code`;

-- Traducciones. Description NULL = explicación pendiente de definir por negocio (ver control c)
INSERT IGNORE INTO `util_options_i18n` (`Option_id`, `Lang`, `Label`, `Description`, `Operator`)
SELECT O.`id`, T.Lang, T.Label, T.Descr, 'setup'
FROM `util_options` O
JOIN `util_option_groups` G ON G.`id` = O.`Group_id`
JOIN (
   -- ACCOUNT_STATUS
             SELECT 'ACCOUNT_STATUS' AS Grp, '1' AS Val, 'en' AS Lang, 'Active' AS Label, 'The account operates normally' AS Descr
   UNION ALL SELECT 'ACCOUNT_STATUS','1','es','Activo',          'La cuenta opera con normalidad'
   UNION ALL SELECT 'ACCOUNT_STATUS','1','it','Attivo',          'L''account opera normalmente'
   UNION ALL SELECT 'ACCOUNT_STATUS','1','pt','Ativo',           'A conta opera normalmente'
   UNION ALL SELECT 'ACCOUNT_STATUS','3','en','Blocked',         'The account is blocked and cannot operate'
   UNION ALL SELECT 'ACCOUNT_STATUS','3','es','Bloqueado',       'La cuenta está bloqueada y no puede operar'
   UNION ALL SELECT 'ACCOUNT_STATUS','3','it','Bloccato',        'L''account è bloccato e non può operare'
   UNION ALL SELECT 'ACCOUNT_STATUS','3','pt','Bloqueado',       'A conta está bloqueada e não pode operar'
   UNION ALL SELECT 'ACCOUNT_STATUS','4','en','Paused',          'The account was paused manually'
   UNION ALL SELECT 'ACCOUNT_STATUS','4','es','Pausado',         'La cuenta fue pausada manualmente'
   UNION ALL SELECT 'ACCOUNT_STATUS','4','it','In pausa',        'L''account è stato messo in pausa manualmente'
   UNION ALL SELECT 'ACCOUNT_STATUS','4','pt','Pausado',         'A conta foi pausada manualmente'
   UNION ALL SELECT 'ACCOUNT_STATUS','6','en','Paused auto NM',  'Paused automatically by the system'
   UNION ALL SELECT 'ACCOUNT_STATUS','6','es','Pausado auto NM', 'Pausado automáticamente por el sistema'
   UNION ALL SELECT 'ACCOUNT_STATUS','6','it','In pausa auto NM','Messo in pausa automaticamente dal sistema'
   UNION ALL SELECT 'ACCOUNT_STATUS','6','pt','Pausado auto NM', 'Pausado automaticamente pelo sistema'
   -- ACTIVE_INACTIVE
   UNION ALL SELECT 'ACTIVE_INACTIVE','1','en','Active',   'Enabled'
   UNION ALL SELECT 'ACTIVE_INACTIVE','1','es','Activo',   'Habilitado'
   UNION ALL SELECT 'ACTIVE_INACTIVE','1','it','Attivo',   'Abilitato'
   UNION ALL SELECT 'ACTIVE_INACTIVE','1','pt','Ativo',    'Habilitado'
   UNION ALL SELECT 'ACTIVE_INACTIVE','0','en','Inactive', 'Disabled'
   UNION ALL SELECT 'ACTIVE_INACTIVE','0','es','Inactivo', 'Deshabilitado'
   UNION ALL SELECT 'ACTIVE_INACTIVE','0','it','Inattivo', 'Disabilitato'
   UNION ALL SELECT 'ACTIVE_INACTIVE','0','pt','Inativo',  'Desabilitado'
   -- YES_NO_INT / YES_NO
   UNION ALL SELECT 'YES_NO_INT','1','en','Yes','' UNION ALL SELECT 'YES_NO_INT','1','es','Sí','' UNION ALL SELECT 'YES_NO_INT','1','it','Sì','' UNION ALL SELECT 'YES_NO_INT','1','pt','Sim',''
   UNION ALL SELECT 'YES_NO_INT','0','en','No', '' UNION ALL SELECT 'YES_NO_INT','0','es','No','' UNION ALL SELECT 'YES_NO_INT','0','it','No','' UNION ALL SELECT 'YES_NO_INT','0','pt','Não',''
   UNION ALL SELECT 'YES_NO','YES','en','Yes','' UNION ALL SELECT 'YES_NO','YES','es','Sí','' UNION ALL SELECT 'YES_NO','YES','it','Sì','' UNION ALL SELECT 'YES_NO','YES','pt','Sim',''
   UNION ALL SELECT 'YES_NO','NO','en','No',  '' UNION ALL SELECT 'YES_NO','NO','es','No','' UNION ALL SELECT 'YES_NO','NO','it','No','' UNION ALL SELECT 'YES_NO','NO','pt','Não',''
   -- TICKET_STATUS
   UNION ALL SELECT 'TICKET_STATUS','1','en','Open',        'Ticket received, not yet handled'
   UNION ALL SELECT 'TICKET_STATUS','1','es','Abierto',     'Ticket recibido, aún sin atender'
   UNION ALL SELECT 'TICKET_STATUS','1','it','Aperto',      'Ticket ricevuto, non ancora gestito'
   UNION ALL SELECT 'TICKET_STATUS','1','pt','Aberto',      'Ticket recebido, ainda não atendido'
   UNION ALL SELECT 'TICKET_STATUS','2','en','In progress', 'Ticket being handled'
   UNION ALL SELECT 'TICKET_STATUS','2','es','En curso',    'Ticket en proceso de atención'
   UNION ALL SELECT 'TICKET_STATUS','2','it','In corso',    'Ticket in lavorazione'
   UNION ALL SELECT 'TICKET_STATUS','2','pt','Em andamento','Ticket em atendimento'
   UNION ALL SELECT 'TICKET_STATUS','3','en','Resolved',    'Solution provided, pending closure'
   UNION ALL SELECT 'TICKET_STATUS','3','es','Resuelto',    'Solución aportada, pendiente de cierre'
   UNION ALL SELECT 'TICKET_STATUS','3','it','Risolto',     'Soluzione fornita, in attesa di chiusura'
   UNION ALL SELECT 'TICKET_STATUS','3','pt','Resolvido',   'Solução fornecida, aguardando encerramento'
   UNION ALL SELECT 'TICKET_STATUS','4','en','Closed',      'Ticket closed'
   UNION ALL SELECT 'TICKET_STATUS','4','es','Cerrado',     'Ticket cerrado'
   UNION ALL SELECT 'TICKET_STATUS','4','it','Chiuso',      'Ticket chiuso'
   UNION ALL SELECT 'TICKET_STATUS','4','pt','Fechado',     'Ticket encerrado'
   -- TRAFFIC_SOURCE
   UNION ALL SELECT 'TRAFFIC_SOURCE','Social','en','Social media',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Social','es','Redes sociales',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Social','it','Social network',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Social','pt','Redes sociais',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','Seo','en','SEO',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Seo','es','SEO',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Seo','it','SEO',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Seo','pt','SEO',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','Website','en','Website',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Website','es','Sitio web',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Website','it','Sito web',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Website','pt','Site',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','SMS','en','SMS',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','SMS','es','SMS',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','SMS','it','SMS',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','SMS','pt','SMS',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','MediaBuy','en','Media buying',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','MediaBuy','es','Compra de medios',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','MediaBuy','it','Media buying',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','MediaBuy','pt','Compra de mídia',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','App','en','App',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','App','es','App',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','App','it','App',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','App','pt','App',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','Mail','en','Email',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Mail','es','Email',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Mail','it','Email',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Mail','pt','E-mail',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','Marketing','en','Marketing',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Marketing','es','Marketing',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Marketing','it','Marketing',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Marketing','pt','Marketing',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','DAM','en','DAM',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','DAM','es','DAM',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','DAM','it','DAM',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','DAM','pt','DAM',NULL
   UNION ALL SELECT 'TRAFFIC_SOURCE','Altro','en','Other',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Altro','es','Otro',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Altro','it','Altro',NULL UNION ALL SELECT 'TRAFFIC_SOURCE','Altro','pt','Outro',NULL
   -- PRODUCT
   UNION ALL SELECT 'PRODUCT','Sport','en','Sport',NULL UNION ALL SELECT 'PRODUCT','Sport','es','Deportes',NULL UNION ALL SELECT 'PRODUCT','Sport','it','Sport',NULL UNION ALL SELECT 'PRODUCT','Sport','pt','Esportes',NULL
   UNION ALL SELECT 'PRODUCT','Casino','en','Casino',NULL UNION ALL SELECT 'PRODUCT','Casino','es','Casino',NULL UNION ALL SELECT 'PRODUCT','Casino','it','Casinò',NULL UNION ALL SELECT 'PRODUCT','Casino','pt','Cassino',NULL
   UNION ALL SELECT 'PRODUCT','Hybrid','en','Hybrid',NULL UNION ALL SELECT 'PRODUCT','Hybrid','es','Híbrido',NULL UNION ALL SELECT 'PRODUCT','Hybrid','it','Ibrido',NULL UNION ALL SELECT 'PRODUCT','Hybrid','pt','Híbrido',NULL
   UNION ALL SELECT 'PRODUCT','Forex','en','Forex',NULL UNION ALL SELECT 'PRODUCT','Forex','es','Forex',NULL UNION ALL SELECT 'PRODUCT','Forex','it','Forex',NULL UNION ALL SELECT 'PRODUCT','Forex','pt','Forex',NULL
   -- BUSINESS_CATEGORY
   UNION ALL SELECT 'BUSINESS_CATEGORY','Gambling','en','Gambling',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Gambling','es','Juego',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Gambling','it','Gioco',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Gambling','pt','Jogos',NULL
   UNION ALL SELECT 'BUSINESS_CATEGORY','Forex','en','Forex',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Forex','es','Forex',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Forex','it','Forex',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Forex','pt','Forex',NULL
   UNION ALL SELECT 'BUSINESS_CATEGORY','Finance','en','Finance',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Finance','es','Finanzas',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Finance','it','Finanza',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Finance','pt','Finanças',NULL
   UNION ALL SELECT 'BUSINESS_CATEGORY','Insurace','en','Insurance',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Insurace','es','Seguros',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Insurace','it','Assicurazioni',NULL UNION ALL SELECT 'BUSINESS_CATEGORY','Insurace','pt','Seguros',NULL
   -- AFFILIATE_PLATFORM (nombres propios: misma etiqueta en todos los idiomas salvo Other)
   UNION ALL SELECT 'AFFILIATE_PLATFORM', P.v, L.l, P.v, NULL
      FROM (SELECT 'Cellxpert' v UNION ALL SELECT 'Entain' UNION ALL SELECT 'Income Access' UNION ALL SELECT 'LivePartners'
            UNION ALL SELECT 'Mexos' UNION ALL SELECT 'MyAffiliates' UNION ALL SELECT 'Netrefer') P
      CROSS JOIN (SELECT 'en' l UNION ALL SELECT 'es' UNION ALL SELECT 'it' UNION ALL SELECT 'pt') L
   UNION ALL SELECT 'AFFILIATE_PLATFORM','Other','en','Other',NULL UNION ALL SELECT 'AFFILIATE_PLATFORM','Other','es','Otra',NULL UNION ALL SELECT 'AFFILIATE_PLATFORM','Other','it','Altra',NULL UNION ALL SELECT 'AFFILIATE_PLATFORM','Other','pt','Outra',NULL
   -- CURRENCY
   UNION ALL SELECT 'CURRENCY','EUR','en','EUR','Euro' UNION ALL SELECT 'CURRENCY','EUR','es','EUR','Euro' UNION ALL SELECT 'CURRENCY','EUR','it','EUR','Euro' UNION ALL SELECT 'CURRENCY','EUR','pt','EUR','Euro'
   UNION ALL SELECT 'CURRENCY','USD','en','USD','US dollar' UNION ALL SELECT 'CURRENCY','USD','es','USD','Dólar estadounidense' UNION ALL SELECT 'CURRENCY','USD','it','USD','Dollaro statunitense' UNION ALL SELECT 'CURRENCY','USD','pt','USD','Dólar americano'
   UNION ALL SELECT 'CURRENCY','GBP','en','GBP','Pound sterling' UNION ALL SELECT 'CURRENCY','GBP','es','GBP','Libra esterlina' UNION ALL SELECT 'CURRENCY','GBP','it','GBP','Sterlina britannica' UNION ALL SELECT 'CURRENCY','GBP','pt','GBP','Libra esterlina'
   -- ACCOUNT_AREA
   UNION ALL SELECT 'ACCOUNT_AREA','gaming','en','Gaming',NULL UNION ALL SELECT 'ACCOUNT_AREA','gaming','es','Juego',NULL UNION ALL SELECT 'ACCOUNT_AREA','gaming','it','Gioco',NULL UNION ALL SELECT 'ACCOUNT_AREA','gaming','pt','Jogos',NULL
   UNION ALL SELECT 'ACCOUNT_AREA','forex','en','Forex',NULL  UNION ALL SELECT 'ACCOUNT_AREA','forex','es','Forex',NULL UNION ALL SELECT 'ACCOUNT_AREA','forex','it','Forex',NULL UNION ALL SELECT 'ACCOUNT_AREA','forex','pt','Forex',NULL
   -- BONUS_CONDITIONS
   UNION ALL SELECT 'BONUS_CONDITIONS','ANY','en','Any',           'Meeting one active threshold is enough'
   UNION ALL SELECT 'BONUS_CONDITIONS','ANY','es','Cualquiera',    'Basta con cumplir un umbral activo'
   UNION ALL SELECT 'BONUS_CONDITIONS','ANY','it','Qualsiasi',     'È sufficiente rispettare una soglia attiva'
   UNION ALL SELECT 'BONUS_CONDITIONS','ANY','pt','Qualquer',      'Basta cumprir um limite ativo'
   UNION ALL SELECT 'BONUS_CONDITIONS','ALL','en','All',           'All active thresholds must be met'
   UNION ALL SELECT 'BONUS_CONDITIONS','ALL','es','Todos',         'Deben cumplirse todos los umbrales activos'
   UNION ALL SELECT 'BONUS_CONDITIONS','ALL','it','Tutti',         'Devono essere rispettate tutte le soglie attive'
   UNION ALL SELECT 'BONUS_CONDITIONS','ALL','pt','Todos',         'Todos os limites ativos devem ser cumpridos'
   -- INVOICE_CATEGORY
   UNION ALL SELECT 'INVOICE_CATEGORY','Invoice','en','Invoice','Final tax invoice'
   UNION ALL SELECT 'INVOICE_CATEGORY','Invoice','es','Factura','Factura definitiva'
   UNION ALL SELECT 'INVOICE_CATEGORY','Invoice','it','Fattura','Fattura definitiva'
   UNION ALL SELECT 'INVOICE_CATEGORY','Invoice','pt','Fatura', 'Fatura definitiva'
   UNION ALL SELECT 'INVOICE_CATEGORY','Proforma','en','Proforma','Preliminary invoice, no tax value'
   UNION ALL SELECT 'INVOICE_CATEGORY','Proforma','es','Proforma','Factura preliminar, sin validez fiscal'
   UNION ALL SELECT 'INVOICE_CATEGORY','Proforma','it','Proforma','Fattura preliminare, senza valore fiscale'
   UNION ALL SELECT 'INVOICE_CATEGORY','Proforma','pt','Proforma','Fatura preliminar, sem validade fiscal'
) T ON T.Grp = G.`Group_code` AND T.Val = O.`Option_value`;

-- Ejemplo de visibilidad por perfil (no ejecutar sin decisión de negocio):
-- INSERT IGNORE INTO util_options_access (Option_id, Account_group_id, Operator)
-- SELECT O.id, 2, 'setup' FROM util_options O JOIN util_option_groups G ON G.id=O.Group_id
-- WHERE G.Group_code='ACCOUNT_STATUS' AND O.Option_value='6';   -- solo Gestor ve "Paused auto NM"

-- ============================================================================
-- 3. Consultas de prueba / control
-- ============================================================================

-- a) Opciones de un grupo para un idioma y un perfil (fallback 'en', filtro por perfil)
SET @Lang = 'es', @Grp = 'ACCOUNT_STATUS', @Account_group_id = 3;
SELECT G.`Group_code`
      ,O.`Option_value`                                  AS `Value`
      ,G.`Value_type`
      ,COALESCE(T.`Label`, E.`Label`, O.`Option_value`)  AS `Label`
      ,COALESCE(T.`Description`, E.`Description`, '')    AS `Description`
      ,O.`Is_default`, O.`Color`, O.`Icon`
      ,P.`Option_value`                                  AS `Parent_value`
FROM `util_option_groups` G
JOIN `util_options` O             ON O.`Group_id` = G.`id` AND O.`Is_active` = 1
LEFT JOIN `util_options` P        ON P.`id` = O.`Parent_option_id`
LEFT JOIN `util_options_i18n` T   ON T.`Option_id` = O.`id` AND T.`Lang` = @Lang
LEFT JOIN `util_options_i18n` E   ON E.`Option_id` = O.`id` AND E.`Lang` = 'en'
WHERE G.`Group_code` = @Grp
  AND G.`Is_active` = 1
  AND (NOT EXISTS (SELECT 1 FROM `util_options_access` A WHERE A.`Option_id` = O.`id`)
       OR EXISTS  (SELECT 1 FROM `util_options_access` A WHERE A.`Option_id` = O.`id` AND A.`Account_group_id` = @Account_group_id))
ORDER BY O.`Sort_order`, O.`Option_value`;

-- b) Traducciones que faltan (opción activa x idioma activo)
SELECT G.`Group_code`, O.`Option_value`, L.`Lang` AS `Lang_faltante`
FROM `util_options` O
JOIN `util_option_groups` G ON G.`id` = O.`Group_id`
CROSS JOIN `util_languages` L
LEFT JOIN `util_options_i18n` T ON T.`Option_id` = O.`id` AND T.`Lang` = L.`Lang`
WHERE O.`Is_active` = 1 AND L.`Is_active` = 1 AND T.`Option_id` IS NULL
ORDER BY G.`Group_code`, O.`Sort_order`, L.`Sort_order`;

-- c) Explicaciones pendientes de definir (Description NULL en 'en')
SELECT G.`Group_code`, O.`Option_value`, T.`Label`
FROM `util_options` O
JOIN `util_option_groups` G   ON G.`id` = O.`Group_id`
JOIN `util_options_i18n` T    ON T.`Option_id` = O.`id` AND T.`Lang` = 'en'
WHERE O.`Is_active` = 1 AND T.`Description` IS NULL
ORDER BY G.`Group_code`, O.`Sort_order`;

-- d) Grupos con más de una opción por defecto (revisar si el campo es de selección simple)
SELECT G.`Group_code`, COUNT(*) AS `Defaults`
FROM `util_options` O JOIN `util_option_groups` G ON G.`id` = O.`Group_id`
WHERE O.`Is_default` = 1 AND O.`Is_active` = 1
GROUP BY G.`Group_code` HAVING COUNT(*) > 1;

-- e) Resumen de carga
SELECT G.`Group_code`, G.`Value_type`, COUNT(DISTINCT O.`id`) AS `Opciones`, COUNT(T.`Option_id`) AS `Traducciones`
FROM `util_option_groups` G
LEFT JOIN `util_options` O      ON O.`Group_id` = G.`id`
LEFT JOIN `util_options_i18n` T ON T.`Option_id` = O.`id`
GROUP BY G.`Group_code`, G.`Value_type`
ORDER BY G.`Group_code`;
