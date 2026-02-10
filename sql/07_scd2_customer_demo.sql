USE poc_synapse_poc_za;
GO

------------------------------------------------------------
-- SCD TYPE 2 DEMO: Customer dimension
-- - previous_snapshot  = "yesterday" (simulated)
-- - current_snapshot   = today (silver.v_customers_clean)
-- For demo: we force CustomerID = 1 to have a changed ContactName.
------------------------------------------------------------

-- You can change these dates to fit your story
DECLARE @InitialStartDate  date = '2024-01-01';  -- when history starts
DECLARE @ChangeDate        date = '2025-02-01';  -- date when new version becomes active
DECLARE @EndOfTime         date = '9999-12-31';

------------------------------------------------------------
-- 1) Current snapshot (today) from Silver layer
------------------------------------------------------------
WITH current_snapshot AS (
    SELECT
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
    FROM silver.v_customers_clean
),

------------------------------------------------------------
-- 2) Previous snapshot (yesterday) – simulated
--    For demo we say: customer with CustomerID = 1 had an
--    older ContactName ("Old <name>").
------------------------------------------------------------
previous_snapshot AS (
    SELECT
        CustomerID,
        CompanyName,
        CASE 
            WHEN CustomerID = 1 
                 THEN CONCAT('Old ', ContactName)   -- force a change for demo
            ELSE ContactName
        END AS ContactName,
        ContactTitle,
        Address,
        City,
        Region,
        PostalCode,
        Country,
        Phone,
        Fax
    FROM current_snapshot
),

------------------------------------------------------------
-- 3) Join previous vs current to detect changed vs unchanged
------------------------------------------------------------
joined AS (
    SELECT
        p.CustomerID,
        p.CompanyName,
        p.ContactName AS PrevContactName,
        c.ContactName AS CurContactName,
        p.ContactTitle,
        p.Address,
        p.City,
        p.Region,
        p.PostalCode,
        p.Country,
        p.Phone,
        p.Fax
    FROM previous_snapshot p
    JOIN current_snapshot  c
      ON p.CustomerID = c.CustomerID
),

------------------------------------------------------------
-- 4) Build SCD2 rows (old + new + unchanged)
------------------------------------------------------------
scd2_rows AS (
    -- a) Unchanged customers: 1 row, open-ended
    SELECT
        j.CustomerID,
        j.CompanyName,
        j.CurContactName AS ContactName,
        j.ContactTitle,
        j.Address,
        j.City,
        j.Region,
        j.PostalCode,
        j.Country,
        j.Phone,
        j.Fax,
        @InitialStartDate AS EffectiveFrom,
        @EndOfTime       AS EffectiveTo,
        1                AS IsCurrent
    FROM joined j
    WHERE j.PrevContactName = j.CurContactName

    UNION ALL

    -- b) Changed customers: OLD version (closed)
    SELECT
        j.CustomerID,
        j.CompanyName,
        j.PrevContactName AS ContactName,  -- old value
        j.ContactTitle,
        j.Address,
        j.City,
        j.Region,
        j.PostalCode,
        j.Country,
        j.Phone,
        j.Fax,
        @InitialStartDate AS EffectiveFrom,
        @ChangeDate       AS EffectiveTo,   -- closed on change date
        0                 AS IsCurrent
    FROM joined j
    WHERE j.PrevContactName <> j.CurContactName

    UNION ALL

    -- c) Changed customers: NEW version (current)
    SELECT
        j.CustomerID,
        j.CompanyName,
        j.CurContactName AS ContactName,   -- new value
        j.ContactTitle,
        j.Address,
        j.City,
        j.Region,
        j.PostalCode,
        j.Country,
        j.Phone,
        j.Fax,
        @ChangeDate AS EffectiveFrom,      -- starts on change date
        @EndOfTime  AS EffectiveTo,
        1           AS IsCurrent
    FROM joined j
    WHERE j.PrevContactName <> j.CurContactName
),

------------------------------------------------------------
-- 5) Add surrogate key and return final SCD2 dimension
------------------------------------------------------------
final_scd2 AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY CustomerID, EffectiveFrom
        ) AS CustomerSK,          -- surrogate key

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
        Fax,
        EffectiveFrom,
        EffectiveTo,
        IsCurrent
    FROM scd2_rows
)

SELECT *
FROM final_scd2
ORDER BY CustomerID, EffectiveFrom;
GO
