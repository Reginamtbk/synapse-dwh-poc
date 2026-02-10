-- 03_raw_customers_view.sql
-- Raw logical layer: view over Customers.csv in ADLS

USE poc_synapse_poc_za;
GO

-- Create raw schema if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');
GO

-- Drop + recreate view to keep script re-runnable
IF OBJECT_ID('raw.v_customers', 'V') IS NOT NULL
    DROP VIEW raw.v_customers;
GO

CREATE VIEW raw.v_customers AS
SELECT *
FROM OPENROWSET(
    BULK 'https://stsynpocreginaeu01za.dfs.core.windows.net/datalake/raw/Customers.csv',
    FORMAT = 'CSV',
    PARSER_VERSION = '2.0',
    FIRSTROW = 2
) WITH (
    CustomerID   NVARCHAR(15),
    CompanyName  NVARCHAR(100),
    ContactName  NVARCHAR(100),
    ContactTitle NVARCHAR(100),
    Address      NVARCHAR(100),
    City         NVARCHAR(50),
    Region       NVARCHAR(50),
    PostalCode   NVARCHAR(20),
    Country      NVARCHAR(50),
    Phone        NVARCHAR(30),
    Fax          NVARCHAR(30)
) AS r;
GO

-- Quick check (you can run this part during the demo)
SELECT TOP 10 * FROM raw.v_customers;
GO
