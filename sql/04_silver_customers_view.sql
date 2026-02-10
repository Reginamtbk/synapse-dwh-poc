-- 04_silver_customers_view.sql
-- Silver logical layer: cleaned & deduped Customers

USE poc_synapse_poc_za;
GO

-- 1) Create silver schema if it doesn't exist
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC('CREATE SCHEMA silver');
GO

-- 2) Drop + recreate view to keep script re-runnable
IF OBJECT_ID('silver.v_customers_clean', 'V') IS NOT NULL
    DROP VIEW silver.v_customers_clean;
GO

-- 3) Silver view: cleaning rules applied
CREATE VIEW silver.v_customers_clean AS
SELECT DISTINCT
    LTRIM(RTRIM(CustomerID))   AS CustomerID,
    LTRIM(RTRIM(CompanyName))  AS CompanyName,
    LTRIM(RTRIM(ContactName))  AS ContactName,
    LTRIM(RTRIM(ContactTitle)) AS ContactTitle,
    LTRIM(RTRIM(Address))      AS Address,
    LTRIM(RTRIM(City))         AS City,
    LTRIM(RTRIM(Region))       AS Region,
    LTRIM(RTRIM(PostalCode))   AS PostalCode,
    LTRIM(RTRIM(Country))      AS Country,
    LTRIM(RTRIM(Phone))        AS Phone,
    LTRIM(RTRIM(Fax))          AS Fax
FROM raw.v_customers
WHERE
    -- mandatory business keys: must not be null or blank
    NULLIF(LTRIM(RTRIM(CustomerID)), '')    IS NOT NULL
    AND NULLIF(LTRIM(RTRIM(CompanyName)), '') IS NOT NULL;
GO

-- 4) Quick check for the demo
SELECT TOP 10 * FROM silver.v_customers_clean;
GO
