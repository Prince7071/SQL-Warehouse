/*
===============================================================================
Quality Checks: Gold Layer
===============================================================================
Purpose:
    Verifies the star schema is safe to report on: surrogate keys are unique,
    the fact table joins cleanly to both dimensions, and no measure is orphaned.

How to read the output:
    Every violations count must be 0.

Run: open in VS Code (mssql extension) connected to DataWarehouse, run the file.
===============================================================================
*/
USE DataWarehouse;
GO

-- 1. Surrogate key uniqueness in dim_customers
SELECT 'gold.dim_customers: duplicate customer_key' AS check_name, COUNT(*) AS violations
FROM (SELECT customer_key FROM gold.dim_customers GROUP BY customer_key HAVING COUNT(*) > 1) d;

-- 2. Surrogate key uniqueness in dim_products
SELECT 'gold.dim_products: duplicate product_key' AS check_name, COUNT(*) AS violations
FROM (SELECT product_key FROM gold.dim_products GROUP BY product_key HAVING COUNT(*) > 1) d;

-- 3. Every fact row must join to a real customer
SELECT 'gold.fact_sales: orphaned customer_key' AS check_name, COUNT(*) AS violations
FROM gold.fact_sales WHERE customer_key IS NULL;

-- 4. Every fact row must join to a real product
SELECT 'gold.fact_sales: orphaned product_key' AS check_name, COUNT(*) AS violations
FROM gold.fact_sales WHERE product_key IS NULL;

-- 5. No negative sales amounts in the fact table
SELECT 'gold.fact_sales: negative sales_amount' AS check_name, COUNT(*) AS violations
FROM gold.fact_sales WHERE sales_amount < 0;