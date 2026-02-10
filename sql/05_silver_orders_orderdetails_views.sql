-- 05_silver_orders_orderdetails_views.sql
-- Raw + Silver logical layers for Orders and OrderDetails

USE poc_synapse_poc_za;
GO

------------------------------------------------------------
-- 1) Ensure schemas exist (raw + silver)
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO

------------------------------------------------------------
-- 2) RAW: Orders view over Orders.csv
------------------------------------------------------------
IF OBJECT_ID('raw.v_orders', 'V') IS NOT NULL
    DROP VIEW raw.v_orders;
GO

CREATE VIEW raw.v_orders AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/Orders.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    OrderID        INT,
    CustomerID     NVARCHAR(15),
    EmployeeID     INT,
    OrderDate      NVARCHAR(30),
    RequiredDate   NVARCHAR(30),
    ShippedDate    NVARCHAR(30),
    ShipVia        INT,
    Freight        NVARCHAR(30),
    ShipName       NVARCHAR(100),
    ShipAddress    NVARCHAR(100),
    ShipCity       NVARCHAR(50),
    ShipRegion     NVARCHAR(50),
    ShipPostalCode NVARCHAR(20),
    ShipCountry    NVARCHAR(50)
) AS r;
GO

------------------------------------------------------------
-- 3) RAW: OrderDetails view over OrderDetails.csv
------------------------------------------------------------
IF OBJECT_ID('raw.v_order_details', 'V') IS NOT NULL
    DROP VIEW raw.v_order_details;
GO

CREATE VIEW raw.v_order_details AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/OrderDetails.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    OrderID   INT,
    ProductID INT,
    UnitPrice DECIMAL(18,2),
    Quantity  INT,
    Discount  FLOAT
) AS r;
GO

------------------------------------------------------------
-- 4) SILVER: Cleaned Orders
--    - Valid OrderID, CustomerID, OrderDate
--    - Proper date & numeric types
--    - Trimmed text fields
------------------------------------------------------------
IF OBJECT_ID('silver.v_orders_clean', 'V') IS NOT NULL
    DROP VIEW silver.v_orders_clean;
GO

CREATE VIEW silver.v_orders_clean AS
SELECT DISTINCT
    OrderID,
    LTRIM(RTRIM(CustomerID)) AS CustomerID,
    EmployeeID,
    TRY_CAST(OrderDate    AS DATE)         AS OrderDate,
    TRY_CAST(RequiredDate AS DATE)         AS RequiredDate,
    TRY_CAST(ShippedDate  AS DATE)         AS ShippedDate,
    ShipVia,
    TRY_CAST(Freight AS DECIMAL(18,2))     AS Freight,
    LTRIM(RTRIM(ShipName))                 AS ShipName,
    LTRIM(RTRIM(ShipAddress))              AS ShipAddress,
    LTRIM(RTRIM(ShipCity))                 AS ShipCity,
    LTRIM(RTRIM(ShipRegion))               AS ShipRegion,
    LTRIM(RTRIM(ShipPostalCode))           AS ShipPostalCode,
    LTRIM(RTRIM(ShipCountry))              AS ShipCountry
FROM raw.v_orders
WHERE
    OrderID IS NOT NULL
    AND NULLIF(LTRIM(RTRIM(CustomerID)), '') IS NOT NULL
    AND TRY_CAST(OrderDate AS DATE) IS NOT NULL;
GO

------------------------------------------------------------
-- 5) SILVER: Cleaned OrderDetails
--    - Valid OrderID, ProductID
--    - Positive Quantity
------------------------------------------------------------
USE poc_synapse_poc_za;
GO

IF OBJECT_ID('raw.v_orders', 'V') IS NOT NULL
    DROP VIEW raw.v_orders;
GO

CREATE VIEW raw.v_orders AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/Orders.csv',  -- 🔴 REPLACE with the exact URL from your auto script
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    OrderID        INT,
    CustomerID     NVARCHAR(15),
    EmployeeID     INT,
    OrderDate      NVARCHAR(30),
    RequiredDate   NVARCHAR(30),
    ShippedDate    NVARCHAR(30),
    ShipVia        INT,
    Freight        NVARCHAR(30),
    ShipName       NVARCHAR(100),
    ShipAddress    NVARCHAR(100),
    ShipCity       NVARCHAR(50),
    ShipRegion     NVARCHAR(50),
    ShipPostalCode NVARCHAR(20),
    ShipCountry    NVARCHAR(50)
) AS r;
GO

------------------------------------------------------------
-- 6) Quick checks for the demo
------------------------------------------------------------

SELECT TOP 10 * FROM raw.v_orders;
SELECT COUNT(*) AS OrdersRowCount FROM raw.v_orders;

SELECT TOP 10 * FROM silver.v_orders_clean;
SELECT TOP 10 * FROM silver.v_order_details_clean;
GO
