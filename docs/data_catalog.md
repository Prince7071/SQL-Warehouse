# Data Catalog — Gold Layer

The gold layer is the only layer intended for direct querying by analysts or
BI tools. Everything below silver is implementation detail.

## gold.dim_customers
Customer dimension. Grain: one row per unique customer.

| Column | Type | Description |
|---|---|---|
| customer_key | INT | Surrogate key, generated via `ROW_NUMBER()`. Used to join to `fact_sales`. |
| customer_id | INT | Natural key from CRM (`cst_id`). |
| customer_number | NVARCHAR(50) | CRM's alternate customer key (`cst_key`), used to join against ERP tables. |
| first_name | NVARCHAR(50) | Trimmed from CRM source. |
| last_name | NVARCHAR(50) | Trimmed from CRM source. |
| country | NVARCHAR(50) | From ERP location table; normalized (`US`/`USA` → `United States`, blank → `n/a`). |
| marital_status | NVARCHAR(50) | `Single` / `Married` / `n/a`, expanded from CRM's single-letter code. |
| gender | NVARCHAR(50) | CRM value used first; falls back to ERP's value only when CRM has none. |
| birthdate | DATE | From ERP; future dates nulled out during silver load. |
| create_date | DATE | Date the customer record was first created in CRM. |

## gold.dim_products
Product dimension. Grain: one row per currently-active product (historical/discontinued versions excluded).

| Column | Type | Description |
|---|---|---|
| product_key | INT | Surrogate key, generated via `ROW_NUMBER()`. Used to join to `fact_sales`. |
| product_id | INT | Natural key from CRM (`prd_id`). |
| product_number | NVARCHAR(50) | CRM's product key, with the category prefix stripped off. |
| product_name | NVARCHAR(50) | From CRM. |
| category_id | NVARCHAR(50) | Extracted from the first 5 characters of CRM's `prd_key`; joins to ERP's category table. |
| category | NVARCHAR(50) | From ERP category table (e.g. Bikes, Components, Accessories). |
| subcategory | NVARCHAR(50) | From ERP category table. |
| maintenance | NVARCHAR(50) | From ERP; whether the product requires maintenance. |
| cost | INT | From CRM; defaults to 0 when missing. |
| product_line | NVARCHAR(50) | `Mountain` / `Road` / `Touring` / `Other Sales` / `n/a`, expanded from CRM's single-letter code. |
| start_date | DATE | Date this product version became active. |

## gold.fact_sales
Sales transaction fact table. Grain: one row per order line item.

| Column | Type | Description |
|---|---|---|
| order_number | NVARCHAR(50) | Natural order identifier from CRM. Not unique per row — one order can span multiple line items. |
| product_key | INT | FK to `dim_products.product_key`. |
| customer_key | INT | FK to `dim_customers.customer_key`. |
| order_date | DATE | Parsed from CRM's integer date format; NULL where the source value was invalid (19 rows). |
| shipping_date | DATE | Same parsing as order_date. |
| due_date | DATE | Same parsing as order_date. |
| sales_amount | INT | Recalculated as `quantity * price` during silver load where the source value was missing or inconsistent. |
| quantity | INT | Units sold in this line item. |
| price | INT | Unit price; derived from `sales_amount / quantity` where the source value was invalid. |

## gold.report_customers
Pre-aggregated customer report view — one row per customer, ready for direct BI consumption.

| Column | Type | Description |
|---|---|---|
| customer_key, customer_number, customer_name | — | Identity fields, carried from dim_customers. |
| age | INT | Calculated from birthdate as of query time. |
| age_group | NVARCHAR | Bucketed: Under 20 / 20-29 / 30-39 / 40-49 / 50 and above. |
| customer_segment | NVARCHAR | VIP (12+ month tenure, >$5,000 spend) / Regular / New. |
| last_order_date, recency_months | — | Most recent order and months since. |
| total_orders, total_sales, total_quantity, total_products | — | Lifetime aggregates. |
| lifespan | INT | Months between first and last order. |
| avg_order_value | INT | `total_sales / total_orders`. |
| avg_monthly_spend | INT | `total_sales / lifespan`. |

## gold.report_products
Pre-aggregated product report view — one row per product, ready for direct BI consumption.

| Column | Type | Description |
|---|---|---|
| product_key, product_name, category, subcategory, cost | — | Identity fields, carried from dim_products. |
| product_segment | NVARCHAR | High-Performer (>$50K sales) / Mid-Range (≥$10K) / Low-Performer. |
| last_sale_date, recency_months | — | Most recent sale and months since. |
| total_orders, total_sales, total_quantity, total_customers | — | Lifetime aggregates. |
| avg_order_revenue | INT | `total_sales / total_orders`. |
| avg_monthly_revenue | INT | `total_sales / lifespan`. |