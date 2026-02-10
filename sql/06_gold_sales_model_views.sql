USE poc_synapse_poc_za;
GO

------------------------------------------------------------
-- 1) Ensure gold schema exists
------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO


------------------------------------------------------------
-- 2) (Optional) RAW: Products and Categories views
--    Adjust mappings to match your CSVs if needed.
------------------------------------------------------------

IF OBJECT_ID('raw.v_products', 'V') IS NOT NULL
    DROP VIEW raw.v_products;
GO

CREATE VIEW raw.v_products AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/Products.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    ProductID       INT,
    ProductName     NVARCHAR(80),
    SupplierID      INT,
    CategoryID      INT,
    QuantityPerUnit NVARCHAR(40),
    UnitPrice       DECIMAL(18,2),
    UnitsInStock    SMALLINT,
    UnitsOnOrder    SMALLINT,
    ReorderLevel    SMALLINT,
    Discontinued    BIT
) AS r;
GO

IF OBJECT_ID('raw.v_categories', 'V') IS NOT NULL
    DROP VIEW raw.v_categories;
GO

CREATE VIEW raw.v_categories AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/Categories.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    CategoryID   INT,
    CategoryName NVARCHAR(50),
    Description  NVARCHAR(255)
) AS r;
GO


------------------------------------------------------------
-- 3) GOLD: Customer dimension (from Silver Customers)
--    (assuming you already have silver.v_customers_clean)
------------------------------------------------------------

IF OBJECT_ID('gold.v_dim_customer', 'V') IS NOT NULL
    DROP VIEW gold.v_dim_customer;
GO

CREATE VIEW gold.v_dim_customer AS
SELECT DISTINCT
    CustomerID,
    CompanyName,
    ContactName,
    ContactTitle,
    Address,
    City,
    Region,
    PostalCode,
    Country,
    Phone,
    Fax
FROM silver.v_customers_clean;
GO


------------------------------------------------------------
-- 4) GOLD: Product dimension (Products + Categories)
------------------------------------------------------------

IF OBJECT_ID('gold.v_dim_product', 'V') IS NOT NULL
    DROP VIEW gold.v_dim_product;
GO

CREATE VIEW gold.v_dim_product AS
SELECT DISTINCT
    p.ProductID,
    LTRIM(RTRIM(p.ProductName))     AS ProductName,
    p.CategoryID,
    c.CategoryName,
    LTRIM(RTRIM(p.QuantityPerUnit)) AS QuantityPerUnit,
    p.UnitPrice,
    p.Discontinued
FROM raw.v_products p
LEFT JOIN raw.v_categories c
    ON p.CategoryID = c.CategoryID;
GO


------------------------------------------------------------
-- 5) GOLD: Fact Sales (Orders x OrderDetails)
--    Uses ONLY the columns we actually have in Orders.csv:
--    OrderID, CustomerID, OrderDate, ShippedDate, Freight,
--    ShipCity, ShipCountry
------------------------------------------------------------

IF OBJECT_ID('gold.v_fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.v_fact_sales;
GO

CREATE VIEW gold.v_fact_sales AS
SELECT
    od.OrderID,
    o.OrderDate,
    o.ShippedDate,
    o.CustomerID,
    od.ProductID,

    od.Quantity,
    od.UnitPrice,
    od.Discount,

    -- Measure: line amount after discount
    CAST(od.Quantity * od.UnitPrice * (1 - od.Discount) AS DECIMAL(18,2))
        AS LineAmount,

    o.Freight,
    o.ShipCity,
    o.ShipCountry
FROM silver.v_order_details_clean od
JOIN silver.v_orders_clean o
    ON od.OrderID = o.OrderID;
GO


------------------------------------------------------------
-- 6) Quick checks for the demo
------------------------------------------------------------

-- Fact sample
SELECT TOP 10 * FROM gold.v_fact_sales;

-- Dimension samples
SELECT TOP 10 * FROM gold.v_dim_customer;
SELECT TOP 10 * FROM gold.v_dim_product;
GO
