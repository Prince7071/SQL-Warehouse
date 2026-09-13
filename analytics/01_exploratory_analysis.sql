USE DataWarehouse;
GO

-- ========== Database Exploration ==========
-- What tables/views exist in the warehouse
SELECT TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY TABLE_SCHEMA, TABLE_NAME;

-- ========== Dimension Exploration ==========
-- Which countries are customers in?
SELECT DISTINCT country FROM gold.dim_customers ORDER BY country;

-- Which product categories exist?
SELECT DISTINCT category, subcategory, product_name
FROM gold.dim_products
ORDER BY category, subcategory;

-- ========== Date Range Exploration ==========
-- First and last order, and how many years/months of data we actually have
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;

-- Youngest and oldest customer by birthdate
SELECT
    MIN(birthdate) AS oldest_customer,
    MAX(birthdate) AS youngest_customer
FROM gold.dim_customers;

-- ========== Core Business Measures (KPIs) ==========
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Products', COUNT(*) FROM gold.dim_products
UNION ALL
SELECT 'Total Customers', COUNT(*) FROM gold.dim_customers;