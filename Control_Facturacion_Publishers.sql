/*																	
   Control_Facturacion_Publishers.sql
   10.10.2024
*/
									
-- FACTURAS EMITIDAS --------------------------------                           
DROP TABLE IF EXISTS campaign_publisher_invoice;
CREATE TABLE IF NOT EXISTS campaign_publisher_invoice (	   				 						      	
    `id`                int            not null AUTO_INCREMENT
   ,`Status`            varchar(1)     not null default '1'
   ,`Owner`             varchar(30)    not null               -- Empresa que emite la factura
   ,`Publisher_id`      int            not null               -- Empresa a la que se factura
   ,`Invoice_Number`    varchar(30)    not null               -- Número en la factura
   ,`Date`              date           null default null      -- Fecha de factura
   ,`Due_Date`          date           null default null      -- Fecha esperada de cobro
   ,`Invoiced_Month`    varchar(7)     not null               -- Mes de la actividad facturada
   ,`Ammount`           decimal (10,2) not null default '0'   -- Cantidad total facturada
   ,`Currency`          varchar(3)     not null default 'EUR' -- Moneda de la factura
   ,`Remarks`           text           null default null      -- Observaciones (texto libre)
   -- --------------------------------------------------------------------
   ,`Creation_Date`     datetime       null default CURRENT_TIMESTAMP               	
   ,`Last_Update`       datetime       null default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP   
   ,`Operator`          varchar(30)    null default null 
   
   ,PRIMARY KEY (`id`)
);
 
-- PAGOS RECIBIDOS POR FACTURAS EMITIDAS ---------------
DROP TABLE IF EXISTS campaign_publisher_receivable;
CREATE TABLE IF NOT EXISTS campaign_publisher_receivable (	   				 						      	
    `id`                int            not null AUTO_INCREMENT
   ,`Status`            varchar(1)     not null default '1'   -- 
   ,`Invoice_id`        int            not null               -- Id en campaign_publisher_invoice (NO ES EL `Invoice_Number`)
   -- Datos a informar por el usuario
   ,`Bank_account`      varchar(100)   null default null      -- Banco o cuenta donde se recibe el pago (texto libre)
   ,`Date`              date           null default null      -- Fecha en que el banco acredita el importe
   ,`Gross_Ammount`     decimal (10,2) not null default '0'   -- Importe bruto transferido por el Publisher
   ,`Transfer_Currency` varchar(3)     not null default 'EUR' -- Moneda del importe bruto transferido
   ,`Net_Ammount`       decimal (10,2) not null default '0'   -- Importe neto acreditado por el Banco
   ,`Currency`          varchar(3)     not null default 'EUR' -- Moneda del importe acreditado
   ,`Remarks`           text           null default null      -- Observaciones (texto libre)
   -- --------------------------------------------------
   ,`Creation_Date`     datetime       null default CURRENT_TIMESTAMP               	
   ,`Last_Update`       datetime       null default CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP   
   ,`Operator`          varchar(30)    null default null 	

   ,PRIMARY KEY (`id`)   
);							   				               

TRUNCATE `campaign_publisher_invoice`;
INSERT INTO `campaign_publisher_invoice` (`id`, `Status`, `Owner`, `Publisher_id`, `Invoice_Number`, `Date`, `Due_Date`, `Invoiced_Month`
          , `Ammount`, `Currency`, `Remarks`, `Operator`) -- , `Creation_Date`, `Last_Update`) 
VALUES 
(null, '1', '864',  1, 'Fact 005', '2023-04-18', '2023-05-10', '2023-03', 1000.00, 'EUR', NULL, '517'), 
(null, '1', '864',  2, 'Fact 006', '2023-05-18', '2023-06-10', '2023-04', 1006.00, 'EUR', NULL, '517'), 
(null, '1', '864',  3, 'Fact 007', '2023-06-18', '2023-07-10', '2023-05', 1007.00, 'EUR', NULL, '517'), 
(null, '1', '864',  4, 'Fact 008', '2023-07-18', '2023-08-10', '2023-06', 1008.00, 'EUR', NULL, '517'), 
(null, '1', '864', 13, 'Fact 009', '2023-08-18', '2023-09-10', '2023-07', 1009.00, 'EUR', NULL, '517'), 
(null, '1', '864', 14, 'Fact 010', '2023-09-18', '2023-10-10', '2023-08', 1010.00, 'EUR', NULL, '517'), 
(null, '1', '864', 15, 'Fact 011', '2023-10-18', '2023-11-10', '2023-09', 1011.00, 'EUR', NULL, '517'), 
(null, '1', '864', 16, 'Fact 012', '2023-11-18', '2023-12-10', '2023-10', 1012.00, 'EUR', NULL, '517'), 
(null, '1', '865', 17, 'Fact 013', '2023-12-18', '2024-01-10', '2023-11', 1013.00, 'EUR', NULL, '517'), 
(null, '1', '865', 27, 'Fact 014', '2024-01-18', '2024-02-10', '2023-12', 1014.00, 'EUR', NULL, '517'), 
(null, '1', '866', 52, 'Fact 015', '2024-02-18', '2024-03-10', '2024-01', 1015.00, 'EUR', NULL, '517')  
;
TRUNCATE `campaign_publisher_receivable`;
INSERT INTO `campaign_publisher_receivable` (`id`, `Status`, `Invoice_id`, `Bank_account`, `Date`, `Gross_Ammount`, `Transfer_Currency`
          , `Net_Ammount`, `Currency`, `Remarks`, `Operator`) -- , `Creation_Date`, `Last_Update`) 
VALUES 
(null, '1',  1, 'Santader', '2023-05-10', 1000.00, 'EUR', 1000.00, 'EUR', NULL, '517'),
(null, '1',  2, 'Santader', '2023-06-10',  500.00, 'EUR',  500.00, 'EUR', NULL, '517'),
(null, '1',  2, 'Santader', '2023-06-20',  506.00, 'EUR',  506.00, 'EUR', NULL, '517'),
(null, '1',  3, 'Santader', '2023-07-10', 1007.00, 'EUR', 1007.00, 'EUR', NULL, '517'),
(null, '1',  4, 'Santader', '2023-08-10', 1008.00, 'EUR', 1008.00, 'EUR', NULL, '517'),
(null, '1',  5, 'Santader', '2023-09-10', 1009.00, 'EUR', 1009.00, 'EUR', NULL, '517'),
(null, '1',  6, 'Santader', '2023-10-10', 1010.00, 'EUR', 1010.00, 'EUR', NULL, '517'),
(null, '1',  7, 'Santader', '2023-11-10', 1011.00, 'EUR', 1001.00, 'EUR', NULL, '517'),
(null, '1',  8, 'Santader', '2023-12-10', 1012.00, 'EUR', 1002.00, 'EUR', NULL, '517'),
(null, '1',  9, 'Santader', '2024-01-10', 1013.00, 'EUR', 1003.00, 'EUR', NULL, '517'),
(null, '1', 10, 'Santader', '2024-02-10', 1014.00, 'EUR', 1004.00, 'EUR', NULL, '517'),
(null, '1', 11, 'Santader', '2024-03-10', 1015.00, 'EUR', 1005.00, 'EUR', NULL, '517') 
;

SELECT i.`Status`,a.`username`,p.`Advertiser_Name`,i.`Invoice_Number`,i.`Date`,i.`Due_Date`
      ,i.`Invoiced_Month`,i.`Ammount`,i.`Currency`,i.`Remarks`
      ,r.`Bank_account`,r.`Date`,r.`Gross_Ammount`,r.`Transfer_Currency`
      ,r.`Net_Ammount`,r.`Currency`,r.`Remarks`
FROM `campaign_publisher_invoice` i
LEFT JOIN `campaign_publisher_receivable` r ON r.`Invoice_id`=i.id
INNER JOIN campaign_publisher  p     ON p.id=i.Publisher_id
INNER JOIN account_account     a     ON a.id=i.Owner
;
