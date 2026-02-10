# Manual Deployment Guide – Synapse DWH POC

Target database: `poc_synapse_poc_za` (serverless SQL in Azure Synapse)

## Prerequisites

- Azure Synapse workspace available.
- Linked Azure Data Lake Gen2 with raw CSV files (Customers, Orders, OrderDetails).
- Serverless SQL endpoint accessible from Synapse Studio.

## Deployment steps

1. Open **Synapse Studio** and connect to the workspace.
2. In the Data hub, select the **SQL database** `poc_synapse_poc_za`.
3. For each script in the `sql/` folder, in order:

   1. `03_raw_customers_view.sql`  
   2. `04_silver_customers_view.sql`  
   3. `05_silver_orders_orderdetails_views.sql`  
   4. `06_gold_sales_model_views.sql`  
   5. `07_scd2_customer_demo.sql` (for demo only)

   - Open a new SQL script tab.
   - Paste the contents from GitHub.
   - Make sure `USE poc_synapse_poc_za;` is at the top.
   - Execute the script.

4. In Synapse Studio, click **Publish all** to save the scripts in the workspace.
5. Validate deployment by running during demo:
   - `SELECT TOP 10 * FROM raw.v_orders;`
   - `SELECT TOP 10 * FROM silver.v_orders_clean;`
   - `SELECT TOP 10 * FROM gold.v_fact_sales;`.

## Notes

- In a real project, these steps would be automated via a CI/CD pipeline (e.g. GitHub Actions) instead of manual execution.
- The SQL scripts are written to be **idempotent** where possible (DROP/CREATE), so re-running them is safe.
