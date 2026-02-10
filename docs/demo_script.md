# Azure Synapse Data Warehouse POC

This repository contains a small end-to-end data warehouse proof-of-concept built on Azure Synapse and Azure Data Lake.

## Objective

Show how I design and build a simple data warehouse in Synapse, including:

- Raw → Silver → Gold data layering
- ETL logic in Synapse serverless SQL (views over Data Lake)
- Basic data quality rules (null handling, type casting, filtering)
- Star schema model: `fact_sales`, `dim_customer`, `dim_product`
- SCD Type 2 demo on the customer dimension
- GitHub-based code organisation that is ready for CI/CD

## Structure

- `sql/`  
  All Synapse SQL scripts:
  - `03_raw_customers_view.sql` – raw customer view
  - `04_silver_customers_view.sql` – cleaned customer view (Silver)
  - `05_silver_orders_orderdetails_views.sql` – raw & Silver orders + order details
  - `06_gold_sales_model_views.sql` – Gold layer: fact_sales + dimensions
  - `07_scd2_customer_demo.sql` – SCD Type 2 demo on customers

- `docs/`  
  - `demo_script.md` – outline of how I present the POC
  - `deploy_manual.md` – manual deployment steps from GitHub to Synapse

## High-level architecture

- **Storage:** Azure Data Lake Gen2  
  - `datalake/raw` – CSV landing zone  
- **Compute:** Azure Synapse serverless SQL  
  - Database: `poc_synapse_poc_za`
- **Layers:**
  - `raw.*` views – files as they land in the lake
  - `silver.*` views – cleaned / typed data with DQ filters
  - `gold.*` views – star schema for reporting

## CI/CD (concept)

In a production setup, these SQL scripts would be:

- Committed to GitHub,
- Validated via pull requests, and
- Deployed to Synapse dev/test/prod workspaces via a CI/CD pipeline (GitHub Actions or Azure DevOps).

For this POC, I demonstrate the structure and manual deployment process, but the repo is organised to plug into CI/CD easily.
