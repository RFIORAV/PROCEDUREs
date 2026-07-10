TRUNCATE wrk_Operaciones;

CREATE TABLE IF NOT EXISTS wrk_Operaciones (
    Operacion_id INT,
    Fecha DATE,
    Id_afiliado INT,
    Client_type TINYINT, -- 1 = nuevo, 0 = antiguo
    Publisher_id VARCHAR(10),
    Brand_id VARCHAR(10),
    Account_id CHAR(1), -- A/B/C/D
    CPA INT, -- puede ser negativo
    Net_Revenue DECIMAL(10, 2) -- puede ser negativo
    Val_CPA  DECIMAL(10, 2),
    Val_CPA  DECIMAL(10, 2),
    Val_CPA  DECIMAL(10, 2),
    Val_CPA  DECIMAL(10, 2),
);

INSERT IGNORE INTO wrk_Operaciones (Fecha,Id_afiliado,Publisher_id,Brand_id,Account_id,CPA,Net_Revenue)
SELECT Date,Affiliate_id,ifnull(Publisher_id,0),Advertiser_id,Username_id,Sum(Qualified_players) as CPA, Sum(Net_Revenue) as Net_Revenue
FROM Snapshot_day_by_day_fact2
WHERE DATE>="2024-07-01"
GROUP BY left(DATE,7),Affiliate_id,ifnull(Publisher_id,0),Advertiser_id,Username_id
;


DROP TABLE IF EXISTS wrk_SaldoComisiones;
CREATE TABLE IF NOT EXISTS wrk_SaldoComisiones (
    Id_afiliado INT,
    Publisher_id VARCHAR(10),
    Brand_id VARCHAR(10),
    Account_id CHAR(1),
    Mes VARCHAR(7), -- Formato aaaa-mm
    Saldo_comm DECIMAL(10, 2)
);



WITH OperacionesPorMes AS (
    SELECT 
        DATE_FORMAT(Fecha, '%Y-%m') AS Mes, 
        Id_afiliado, 
        Publisher_id, 
        Brand_id, 
        Account_id,
        SUM(CASE 
            WHEN Client_type = 0 THEN CPA -- Solo se cuentan nuevos clientes
            ELSE 1 
        END) AS NuevosClientes,
        SUM(Net_Revenue) AS TotalNet_Revenue
    FROM wrk_Operaciones
    GROUP BY Mes, Id_afiliado, Publisher_id, Brand_id, Account_id
),
ComisionesCalculadas AS (
    SELECT 
        O.Mes,
        O.Id_afiliado, 
        O.Publisher_id, 
        O.Brand_id, 
        O.Account_id,
        -- Comisión por nuevos clientes según el Account
        CASE 
            WHEN O.Account_id = 'A' THEN O.NuevosClientes * 10
            WHEN O.Account_id = 'B' THEN O.NuevosClientes * 15
            WHEN O.Account_id = 'C' THEN O.NuevosClientes * 20
            WHEN O.Account_id = 'D' THEN O.NuevosClientes * 25
            ELSE 0
        END AS ComisionClientes,
        -- Comisión por Net_Revenue según el Account
        CASE 
            WHEN O.Account_id = 'A' THEN O.TotalNet_Revenue * 0.05
            WHEN O.Account_id = 'B' THEN O.TotalNet_Revenue * 0.06
            WHEN O.Account_id = 'C' THEN O.TotalNet_Revenue * 0.07
            WHEN O.Account_id = 'D' THEN O.TotalNet_Revenue * 0.08
            ELSE 0
        END AS ComisionNet_Revenue
    FROM OperacionesPorMes O
),
ComisionConSaldo AS (
    SELECT 
        C.Mes,
        C.Id_afiliado,
        C.Publisher_id,
        C.Brand_id,
        C.Account_id,
        C.ComisionClientes,
        C.ComisionNet_Revenue,
        (C.ComisionClientes + C.ComisionNet_Revenue) AS ComisionTotal,
        COALESCE(SC.Saldo_comm, 0) AS SaldoAnterior
    FROM ComisionesCalculadas C
    LEFT JOIN wrk_SaldoComisiones SC 
        ON C.Id_afiliado = SC.Id_afiliado 
        AND C.Publisher_id = SC.Publisher_id
        AND C.Brand_id = SC.Brand_id
        AND C.Account_id = SC.Account_id
        AND SC.Mes = (SELECT MAX(Mes) FROM wrk_SaldoComisiones WHERE Mes < C.Mes) -- Saldo acumulado de meses anteriores
)
SELECT 
    Mes,
    Id_afiliado,
    Publisher_id,
    Brand_id,
    Account_id,
    CASE 
        -- Para Account C, si la comisión total es negativa y la de clientes es positiva, compensar
        WHEN Account_id = 'C' AND ComisionNet_Revenue < 0 AND ComisionClientes > 0 THEN 
            CASE 
                WHEN ComisionClientes + ComisionNet_Revenue + SaldoAnterior >= 0 THEN ComisionClientes + ComisionNet_Revenue + SaldoAnterior
                ELSE 0 
            END
        -- Si la comisión total + saldo anterior es positiva, se paga la comisión restante
        WHEN ComisionTotal + SaldoAnterior >= 0 THEN ComisionTotal + SaldoAnterior
        -- Si no, no se paga nada y se arrastra el saldo negativo
        ELSE 0 
    END AS ComisionAPagar,
    CASE 
        -- Si la comisión total + saldo anterior es negativa, se arrastra el saldo
        WHEN ComisionTotal + SaldoAnterior < 0 THEN ComisionTotal + SaldoAnterior
        ELSE 0
    END AS Saldo_comm
FROM ComisionConSaldo;
