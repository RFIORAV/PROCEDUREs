-- DROP TABLE eurobet_input;
TRUNCATE TABLE eurobet_input;
-- Tabla de entrada
CREATE TABLE IF NOT EXISTS eurobet_input (
    `MA_ID` VARCHAR(50),
    `Customer` VARCHAR(50),
    `Client_Reference` VARCHAR(50),
    `Source_Group` VARCHAR(50),
    `Campaign` VARCHAR(50),
    `Customer_Country` VARCHAR(50),
    `IP_Address` VARCHAR(50),
    `Customer_Join_Date` DATE,
    `Landing_Page_ID` VARCHAR(50),
    `Landing_Page_Description` VARCHAR(255),
    `Affiliate` VARCHAR(100),
    `Affiliate_ID` VARCHAR(50),
    `Affiliate_Status` VARCHAR(50),
    `Affiliate_Country` VARCHAR(50),
    `Customer_Join_Year_and_Month` VARCHAR(10),
    `Signups` INT,
    `First_Deposit_Count` INT,
    `First_Deposit_Amount` DECIMAL(10,2),
    `Deposits` DECIMAL(10,2),
    `Gross_Win` DECIMAL(10,2),
    `Bonus` DECIMAL(10,2),
    `Tax` DECIMAL(10,2),
    `Turnover` DECIMAL(10,2),
    `Net_Revenue` DECIMAL(10,2),
    `Qualified_Players_Tier_1` INT,
    `Qualified_Players_Tier_2` INT,
    `Hits` INT,
    `First_Deposit_Count_2` INT,
    `First_Deposit_Amount_2` DECIMAL(10,2),
    `Bingo_Number_Tickets` INT,
    `Bingo_Turnover` DECIMAL(10,2),
    `Bingo_Gross_Win` DECIMAL(10,2),
    `Bingo_Bonus` DECIMAL(10,2),
    `Bingo_Tax` DECIMAL(10,2),
    `Bingo_Net_Revenue` DECIMAL(10,2),
    `Casino_Number_Tickets` INT,
    `Casino_Turnover` DECIMAL(10,2),
    `Casino_Gross_Win` DECIMAL(10,2),
    `Casino_Bonus` DECIMAL(10,2),
    `Casino_Tax` DECIMAL(10,2),
    `Casino_Net_Revenue` DECIMAL(10,2),
    `Poker_Number_Tickets` INT,
    `Poker_Turnover` DECIMAL(10,2),
    `Poker_Gross_Win` DECIMAL(10,2),
    `Poker_Bonus` DECIMAL(10,2),
    `Poker_Tax` DECIMAL(10,2),
    `Poker_Net_Revenue` DECIMAL(10,2),
    `Psqf_Number_Tickets` INT,
    `Psqf_Turnover` DECIMAL(10,2),
    `Psqf_Gross_Win` DECIMAL(10,2),
    `Psqf_Bonus` DECIMAL(10,2),
    `Psqf_Tax` DECIMAL(10,2),
    `Psqf_Net_Revenue` DECIMAL(10,2),
    `Psr_Number_Tickets` INT,
    `Psr_Turnover` DECIMAL(10,2),
    `Psr_Gross_Win` DECIMAL(10,2),
    `Psr_Bonus` DECIMAL(10,2),
    `Psr_Tax` DECIMAL(10,2),
    `Psr_Net_Revenue` DECIMAL(10,2),
    `Qlit_Number_Tickets` INT,
    `Qlit_Turnover` DECIMAL(10,2),
    `Qlit_Gross_Win` DECIMAL(10,2),
    `Qlit_Bonus` DECIMAL(10,2),
    `Qlit_Tax` DECIMAL(10,2),
    `Skill_Number_Tickets` INT,
    `Skill_Turnover` DECIMAL(10,2),
    `Skill_Gross_Win` DECIMAL(10,2),
    `Skill_Bonus` DECIMAL(10,2),
    `Skill_Tax` DECIMAL(10,2),
    `Skill_Net_Revenue` DECIMAL(10,2),
    `Psv_Number_Tickets` INT,
    `Psv_Turnover` DECIMAL(10,2),
    `Psv_Gross_Win` DECIMAL(10,2),
    `Psv_Bonus` DECIMAL(10,2),
    `Psv_Tax` DECIMAL(10,2),
    `Psv_Net_Revenue` DECIMAL(10,2),
    `Gntn_Number_Tickets` INT,
    `Gntn_Turnover` DECIMAL(10,2),
    `Gntn_Gross_Win` DECIMAL(10,2),
    `Gntn_Bonus` DECIMAL(10,2),
    `Gntn_Tax` DECIMAL(10,2),
    `Ipp_Number_Tickets` INT,
    `Ipp_Turnover` DECIMAL(10,2),
    `Ipp_Gross_Win` DECIMAL(10,2),
    `Ipp_Bonus` DECIMAL(10,2),
    `Ipp_Tax` DECIMAL(10,2)
);

LOAD DATA LOCAL INFILE 'D:/Reinaldo/_FRA/db/PROCEDUREs/MyAffiliates - Advanced Reporting - Customer Report-4.csv'
INTO TABLE eurobet_input
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    `MA_ID`,
    `Customer`,
    `Client_Reference`,
    `Source_Group`,
    `Campaign`,
    `Customer_Country`,
    `IP_Address`,
    @customer_join_date,
    `Landing_Page_ID`,
    `Landing_Page_Description`,
    `Affiliate`,
    `Affiliate_ID`,
    `Affiliate_Status`,
    `Affiliate_Country`,
    `Customer_Join_Year_and_Month`,
    `Signups`,
    `First_Deposit_Count`,
    @first_deposit_amount,
    @deposits,
    @gross_win,
    @bonus,
    @tax,
    @turnover,
    @net_revenue,
    `Qualified_Players_Tier_1`,
    `Qualified_Players_Tier_2`,
    `Hits`,
    `First_Deposit_Count_2`,
    @first_deposit_amount_2,
    @bingo_number_tickets,
    @bingo_turnover,
    @bingo_gross_win,
    @bingo_bonus,
    @bingo_tax,
    @bingo_net_revenue,
    @casino_number_tickets,
    @casino_turnover,
    @casino_gross_win,
    @casino_bonus,
    @casino_tax,
    @casino_net_revenue,
    @poker_number_tickets,
    @poker_turnover,
    @poker_gross_win,
    @poker_bonus,
    @poker_tax,
    @poker_net_revenue,
    @psqf_number_tickets,
    @psqf_turnover,
    @psqf_gross_win,
    @psqf_bonus,
    @psqf_tax,
    @psqf_net_revenue,
    @psr_number_tickets,
    @psr_turnover,
    @psr_gross_win,
    @psr_bonus,
    @psr_tax,
    @psr_net_revenue,
    @qlit_number_tickets,
    @qlit_turnover,
    @qlit_gross_win,
    @qlit_bonus,
    @qlit_tax,
    @skill_number_tickets,
    @skill_turnover,
    @skill_gross_win,
    @skill_bonus,
    @skill_tax,
    @skill_net_revenue,
    @psv_number_tickets,
    @psv_turnover,
    @psv_gross_win,
    @psv_bonus,
    @psv_tax,
    @psv_net_revenue,
    @gntn_number_tickets,
    @gntn_turnover,
    @gntn_gross_win,
    @gntn_bonus,
    @gntn_tax,
    @ipp_number_tickets,
    @ipp_turnover,
    @ipp_gross_win,
    @ipp_bonus,
    @ipp_tax
)
SET
    `Customer_Join_Date` = STR_TO_DATE(@customer_join_date, '%Y-%m-%d'),
    `First_Deposit_Amount` = CAST(REPLACE(REPLACE(@first_deposit_amount, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Deposits` = CAST(REPLACE(REPLACE(@deposits, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Gross_Win` = CAST(REPLACE(REPLACE(@gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bonus` = CAST(REPLACE(REPLACE(@bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Tax` = CAST(REPLACE(REPLACE(@tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Turnover` = CAST(REPLACE(REPLACE(@turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Net_Revenue` = CAST(REPLACE(REPLACE(@net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `First_Deposit_Amount_2` = CAST(REPLACE(REPLACE(@first_deposit_amount_2, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bingo_Number_Tickets` = CAST(@bingo_number_tickets AS SIGNED),
    `Bingo_Turnover` = CAST(REPLACE(REPLACE(@bingo_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bingo_Gross_Win` = CAST(REPLACE(REPLACE(@bingo_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bingo_Bonus` = CAST(REPLACE(REPLACE(@bingo_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bingo_Tax` = CAST(REPLACE(REPLACE(@bingo_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Bingo_Net_Revenue` = CAST(REPLACE(REPLACE(@bingo_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Casino_Number_Tickets` = CAST(@casino_number_tickets AS SIGNED),
    `Casino_Turnover` = CAST(REPLACE(REPLACE(@casino_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Casino_Gross_Win` = CAST(REPLACE(REPLACE(@casino_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Casino_Bonus` = CAST(REPLACE(REPLACE(@casino_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Casino_Tax` = CAST(REPLACE(REPLACE(@casino_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Casino_Net_Revenue` = CAST(REPLACE(REPLACE(@casino_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Poker_Number_Tickets` = CAST(@poker_number_tickets AS SIGNED),
    `Poker_Turnover` = CAST(REPLACE(REPLACE(@poker_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Poker_Gross_Win` = CAST(REPLACE(REPLACE(@poker_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Poker_Bonus` = CAST(REPLACE(REPLACE(@poker_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Poker_Tax` = CAST(REPLACE(REPLACE(@poker_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Poker_Net_Revenue` = CAST(REPLACE(REPLACE(@poker_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psqf_Number_Tickets` = CAST(@psqf_number_tickets AS SIGNED),
    `Psqf_Turnover` = CAST(REPLACE(REPLACE(@psqf_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psqf_Gross_Win` = CAST(REPLACE(REPLACE(@psqf_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psqf_Bonus` = CAST(REPLACE(REPLACE(@psqf_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psqf_Tax` = CAST(REPLACE(REPLACE(@psqf_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psqf_Net_Revenue` = CAST(REPLACE(REPLACE(@psqf_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psr_Number_Tickets` = CAST(@psr_number_tickets AS SIGNED),
    `Psr_Turnover` = CAST(REPLACE(REPLACE(@psr_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psr_Gross_Win` = CAST(REPLACE(REPLACE(@psr_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psr_Bonus` = CAST(REPLACE(REPLACE(@psr_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psr_Tax` = CAST(REPLACE(REPLACE(@psr_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psr_Net_Revenue` = CAST(REPLACE(REPLACE(@psr_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Qlit_Number_Tickets` = CAST(@qlit_number_tickets AS SIGNED),
    `Qlit_Turnover` = CAST(REPLACE(REPLACE(@qlit_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Qlit_Gross_Win` = CAST(REPLACE(REPLACE(@qlit_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Qlit_Bonus` = CAST(REPLACE(REPLACE(@qlit_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Qlit_Tax` = CAST(REPLACE(REPLACE(@qlit_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Skill_Number_Tickets` = CAST(@skill_number_tickets AS SIGNED),
    `Skill_Turnover` = CAST(REPLACE(REPLACE(@skill_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Skill_Gross_Win` = CAST(REPLACE(REPLACE(@skill_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Skill_Bonus` = CAST(REPLACE(REPLACE(@skill_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Skill_Tax` = CAST(REPLACE(REPLACE(@skill_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Skill_Net_Revenue` = CAST(REPLACE(REPLACE(@skill_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psv_Number_Tickets` = CAST(@psv_number_tickets AS SIGNED),
    `Psv_Turnover` = CAST(REPLACE(REPLACE(@psv_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psv_Gross_Win` = CAST(REPLACE(REPLACE(@psv_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psv_Bonus` = CAST(REPLACE(REPLACE(@psv_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psv_Tax` = CAST(REPLACE(REPLACE(@psv_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Psv_Net_Revenue` = CAST(REPLACE(REPLACE(@psv_net_revenue, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Gntn_Number_Tickets` = CAST(@gntn_number_tickets AS SIGNED),
    `Gntn_Turnover` = CAST(REPLACE(REPLACE(@gntn_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Gntn_Gross_Win` = CAST(REPLACE(REPLACE(@gntn_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Gntn_Bonus` = CAST(REPLACE(REPLACE(@gntn_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Gntn_Tax` = CAST(REPLACE(REPLACE(@gntn_tax, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Ipp_Number_Tickets` = CAST(@ipp_number_tickets AS SIGNED),
    `Ipp_Turnover` = CAST(REPLACE(REPLACE(@ipp_turnover, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Ipp_Gross_Win` = CAST(REPLACE(REPLACE(@ipp_gross_win, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Ipp_Bonus` = CAST(REPLACE(REPLACE(@ipp_bonus, '€', ''), ',', '') AS DECIMAL(10,2)),
    `Ipp_Tax` = CAST(REPLACE(REPLACE(@ipp_tax, '€', ''), ',', '') AS DECIMAL(10,2));

-- Tabla de tipos de juego
CREATE TABLE IF NOT EXISTS game_types (
    game_type_id VARCHAR(10) PRIMARY KEY,
    game_type_name VARCHAR(50)
);
-- Tabla para acumulados por Source Group y Campaign
CREATE TABLE IF NOT EXISTS campaign_summary (
    source_group VARCHAR(50),
    campaign VARCHAR(50),
    total_signups INT,
    total_first_deposits INT,
    total_first_deposit_amount DECIMAL(10,2),
    total_deposits DECIMAL(10,2),
    total_gross_win DECIMAL(10,2),
    total_bonus DECIMAL(10,2),
    total_tax DECIMAL(10,2),
    total_turnover DECIMAL(10,2),
    total_net_revenue DECIMAL(10,2),
    PRIMARY KEY (source_group, campaign)
);

-- Tabla para acumulados por Client Reference, Source Group y Campaign
CREATE TABLE IF NOT EXISTS client_campaign_summary (
    client_reference VARCHAR(50),
    source_group VARCHAR(50),
    campaign VARCHAR(50),
    signups INT,
    first_deposits INT,
    first_deposit_amount DECIMAL(10,2),
    deposits DECIMAL(10,2),
    gross_win DECIMAL(10,2),
    bonus DECIMAL(10,2),
    tax DECIMAL(10,2),
    turnover DECIMAL(10,2),
    net_revenue DECIMAL(10,2),
    PRIMARY KEY (client_reference, source_group, campaign)
);

-- Tabla para acumulados por tipo de juego
CREATE TABLE IF NOT EXISTS game_type_summary (
    client_reference VARCHAR(50),
    game_type_id VARCHAR(10),
    number_tickets INT,
    turnover DECIMAL(10,2),
    gross_win DECIMAL(10,2),
    bonus DECIMAL(10,2),
    tax DECIMAL(10,2),
    net_revenue DECIMAL(10,2),
    PRIMARY KEY (client_reference, game_type_id)
);

TRUNCATE TABLE game_types;
TRUNCATE TABLE campaign_summary;
TRUNCATE TABLE client_campaign_summary;
TRUNCATE TABLE game_type_summary;   

-- Insertar tipos de juego
INSERT INTO game_types (game_type_id, game_type_name) VALUES
('BINGO', 'Bingo'),
('CASINO', 'Casino'),
('POKER', 'Poker'),
('PSQF', 'PSQF'),
('PSR', 'PSR'),
('QLIT', 'QLIT'),
('SKILL', 'Skill'),
('PSV', 'PSV'),
('GNTN', 'GNTN'),
('IPP', 'IPP');

-- 1. Insertar datos en campaign_summary
INSERT INTO campaign_summary (
    source_group,
    campaign,
    total_signups,
    total_first_deposits,
    total_first_deposit_amount,
    total_deposits,
    total_gross_win,
    total_bonus,
    total_tax,
    total_turnover,
    total_net_revenue
)
SELECT 
    `Source_Group`,
    Campaign,
    SUM(Signups),
    SUM(`First_Deposit_Count`),
    SUM(`First_Deposit_Amount`),
    SUM(Deposits),
    SUM(`Gross_Win`),
    SUM(Bonus),
    SUM(Tax),
    SUM(Turnover),
    SUM(`Net_Revenue`)
FROM eurobet_input
GROUP BY `Source_Group`, Campaign;

-- 2. Insertar datos en client_campaign_summary
INSERT INTO client_campaign_summary (
    client_reference,
    source_group,
    campaign,
    signups,
    first_deposits,
    first_deposit_amount,
    deposits,
    gross_win,
    bonus,
    tax,
    turnover,
    net_revenue
)
SELECT 
    `Client_Reference`,
    `Source_Group`,
    Campaign,
    Signups,
    `First_Deposit_Count`,
    `First_Deposit_Amount`,
    Deposits,
    `Gross_Win`,
    Bonus,
    Tax,
    Turnover,
    `Net_Revenue`
FROM eurobet_input;

-- 3. Insertar datos en game_type_summary
INSERT INTO game_type_summary (
    client_reference,
    game_type_id,
    number_tickets,
    turnover,
    gross_win,
    bonus,
    tax,
    net_revenue
)
SELECT 
    ei.client_reference,
    gt.game_type_id,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_number_tickets
        WHEN 'Casino' THEN ei.casino_number_tickets
        WHEN 'Poker' THEN ei.poker_number_tickets
        WHEN 'PSQF' THEN ei.psqf_number_tickets
        WHEN 'PSR' THEN ei.psr_number_tickets
        WHEN 'QLIT' THEN ei.qlit_number_tickets
        WHEN 'SKILL' THEN ei.skill_number_tickets
        WHEN 'PSV' THEN ei.psv_number_tickets
        WHEN 'GNTN' THEN ei.gntn_number_tickets
        WHEN 'IPP' THEN ei.ipp_number_tickets
    END as number_tickets,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_turnover
        WHEN 'Casino' THEN ei.casino_turnover
        WHEN 'Poker' THEN ei.poker_turnover
        WHEN 'PSQF' THEN ei.psqf_turnover
        WHEN 'PSR' THEN ei.psr_turnover
        WHEN 'QLIT' THEN ei.qlit_turnover
        WHEN 'SKILL' THEN ei.skill_turnover
        WHEN 'PSV' THEN ei.psv_turnover
        WHEN 'GNTN' THEN ei.gntn_turnover
        WHEN 'IPP' THEN ei.ipp_turnover
    END as turnover,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_gross_win
        WHEN 'Casino' THEN ei.casino_gross_win
        WHEN 'Poker' THEN ei.poker_gross_win
        WHEN 'PSQF' THEN ei.psqf_gross_win
        WHEN 'PSR' THEN ei.psr_gross_win
        WHEN 'QLIT' THEN ei.qlit_gross_win
        WHEN 'SKILL' THEN ei.skill_gross_win
        WHEN 'PSV' THEN ei.psv_gross_win
        WHEN 'GNTN' THEN ei.gntn_gross_win
        WHEN 'IPP' THEN ei.ipp_gross_win
    END as gross_win,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_bonus
        WHEN 'Casino' THEN ei.casino_bonus
        WHEN 'Poker' THEN ei.poker_bonus
        WHEN 'PSQF' THEN ei.psqf_bonus
        WHEN 'PSR' THEN ei.psr_bonus
        WHEN 'QLIT' THEN ei.qlit_bonus
        WHEN 'SKILL' THEN ei.skill_bonus
        WHEN 'PSV' THEN ei.psv_bonus
        WHEN 'GNTN' THEN ei.gntn_bonus
        WHEN 'IPP' THEN ei.ipp_bonus
    END as bonus,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_tax
        WHEN 'Casino' THEN ei.casino_tax
        WHEN 'Poker' THEN ei.poker_tax
        WHEN 'PSQF' THEN ei.psqf_tax
        WHEN 'PSR' THEN ei.psr_tax
        WHEN 'QLIT' THEN ei.qlit_tax
        WHEN 'SKILL' THEN ei.skill_tax
        WHEN 'PSV' THEN ei.psv_tax
        WHEN 'GNTN' THEN ei.gntn_tax
        WHEN 'IPP' THEN ei.ipp_tax
    END as tax,
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_net_revenue
        WHEN 'Casino' THEN ei.casino_net_revenue
        WHEN 'Poker' THEN ei.poker_net_revenue
        WHEN 'PSQF' THEN ei.psqf_net_revenue
        WHEN 'PSR' THEN ei.psr_net_revenue
        WHEN 'QLIT' THEN (ei.qlit_gross_win - ei.qlit_bonus - ei.qlit_tax)
        WHEN 'SKILL' THEN ei.skill_net_revenue
        WHEN 'PSV' THEN ei.psv_net_revenue
        WHEN 'GNTN' THEN (ei.gntn_gross_win - ei.gntn_bonus - ei.gntn_tax)
        WHEN 'IPP' THEN (ei.ipp_gross_win - ei.ipp_bonus - ei.ipp_tax)
    END as net_revenue
FROM eurobet_input ei
CROSS JOIN game_types gt
WHERE 
    CASE gt.game_type_name
        WHEN 'Bingo' THEN ei.bingo_number_tickets
        WHEN 'Casino' THEN ei.casino_number_tickets
        WHEN 'Poker' THEN ei.poker_number_tickets
        WHEN 'PSQF' THEN ei.psqf_number_tickets
        WHEN 'PSR' THEN ei.psr_number_tickets
        WHEN 'QLIT' THEN ei.qlit_number_tickets
        WHEN 'SKILL' THEN ei.skill_number_tickets
        WHEN 'PSV' THEN ei.psv_number_tickets
        WHEN 'GNTN' THEN ei.gntn_number_tickets
        WHEN 'IPP' THEN ei.ipp_number_tickets
    END > 0;