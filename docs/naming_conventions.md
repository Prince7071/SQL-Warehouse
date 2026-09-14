# Naming Conventions

## Schemas
- `bronze`, `silver`, `gold` — one per medallion layer

## Tables (bronze & silver)
Pattern: `<source_system>_<entity>`
- `crm_cust_info`, `crm_prd_info`, `crm_sales_details`
- `erp_cust_az12`, `erp_loc_a101`, `erp_px_cat_g1v2`

## Views (gold)
Pattern: `<type>_<entity>`
- `dim_customers`, `dim_products` — dimension views
- `fact_sales` — fact view
- `report_customers`, `report_products` — pre-aggregated reporting views

## Columns
- Surrogate keys: `<entity>_key` (e.g. `customer_key`, `product_key`) — generated via `ROW_NUMBER()`, used only in gold
- Natural/source keys: `<entity>_id` or `<entity>_number` (e.g. `customer_id`, `product_number`) — preserved from source systems
- Foreign keys: `<referenced_entity>_key` (e.g. `fact_sales.customer_key` references `dim_customers.customer_key`)
- Metadata: `dwh_create_date` — timestamp of when a row was loaded into silver

## Stored Procedures
Pattern: `<layer>.load_<layer>` — e.g. `bronze.load_bronze`, `silver.load_silver`

## Scripts
- `ddl_<layer>.sql` — table/view definitions
- `proc_load_<layer>.sql` — load/transform procedures
- Numbered analytics scripts (`01_`, `02_`...) reflect the order they're meant to be run in