# SQL Data Warehouse & Analytics Project

An end-to-end data warehouse built in SQL Server using the **Medallion Architecture** (Bronze → Silver → Gold), integrating CRM and ERP source systems into a clean, analytics-ready star schema — plus a full analytics layer that turns the warehouse into actual business insights.

## Architecture

## Tech Stack
- **Database:** Microsoft SQL Server (Express)
- **Language:** T-SQL (CTEs, window functions, stored procedures, views)
- **Tooling:** VS Code + mssql extension, Git
- **Data Sources:** CRM & ERP CSV exports (customer info, product info, sales, demographics, location, category)

## Project Structure

## What Each Layer Does

**Bronze** — Ingests CRM & ERP CSVs exactly as-is via `BULK INSERT`, no changes applied. This is the auditable source of truth.

**Silver** — Cleans and standardizes the raw data: deduplicates customer records (`ROW_NUMBER()`), normalizes coded values (e.g. `M`/`F` → `Male`/`Female`), fixes invalid sales figures, parses malformed dates, and joins CRM/ERP identifiers into a consistent format.

**Gold** — Models the cleaned data into a star schema: `dim_customers`, `dim_products`, and `fact_sales`, plus two pre-aggregated reporting views, `report_customers` and `report_products`, that segment customers (VIP/Regular/New) and products (High/Mid/Low performer) for direct BI consumption.

**Analytics** — SQL scripts covering database exploration, core KPIs, time-series trends, cumulative running totals, year-over-year performance (`LAG()`), and part-to-whole revenue contribution.

## How to Run This Project
1. Run `scripts/00_init_database.sql` to create the database and schemas
2. Run `scripts/bronze/ddl_bronze.sql`, then `EXEC bronze.load_bronze;`
3. Run `scripts/silver/ddl_silver.sql`, then `EXEC silver.load_silver;`
4. Run `scripts/gold/ddl_gold.sql`, then `scripts/gold/report_customers.sql` and `report_products.sql`
5. Explore results using the scripts in `analytics/`

## Key Results
- Consolidated 27,659 orders totaling $29,356,250 in sales, across 6 source tables from CRM and ERP systems
- Modeled data for 18,484 customers and 295 products into 3 analytics-ready gold datasets (dim_customers, dim_products, fact_sales)
- 60,423 units sold at an average price of $486, segmented into VIP/Regular/New customer tiers and High/Mid/Low-performing products via the report views

## License
MIT