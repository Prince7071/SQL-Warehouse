/*
===============================================================================
Quality Checks: Silver Layer
===============================================================================
Purpose:
    Verifies that every cleansing rule in silver.load_silver actually held.

How to read the output:
    Each check returns a single row with a violations count. EVERY count must
    be 0. A non-zero value means that rule failed and gold should not be
    trusted until it's fixed.

Run: open in VS Code (mssql extension) connected to DataWarehouse, run the file.
===============================================================================
*/
USE DataWarehouse;
GO

-- ===== crm_cust_info =====

-- 1. Primary key must be unique and never NULL
SELECT 'crm_cust_info: duplicate or null cst_id' AS check_name, COUNT(*) AS violations
FROM (
    SELECT cst_id FROM silver.crm_cust_info
    GROUP BY cst_id HAVING COUNT(*) > 1 OR cst_id IS NULL
) d;

-- 2. No leading/trailing whitespace should survive cleansing
SELECT 'crm_cust_info: untrimmed names' AS check_name, COUNT(*) AS violations
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname)
   OR cst_lastname  <> TRIM(cst_lastname);

-- 3. Coded columns must only contain the expanded vocabulary
SELECT 'crm_cust_info: unmapped marital_status' AS check_name, COUNT(*) AS violations
FROM silver.crm_cust_info
WHERE cst_marital_status NOT IN ('Single', 'Married', 'n/a');

SELECT 'crm_cust_info: unmapped gender' AS check_name, COUNT(*) AS violations
FROM silver.crm_cust_info
WHERE cst_gndr NOT IN ('Female', 'Male', 'n/a');

-- ===== crm_prd_info =====

-- 4. Sales amount must always equal quantity * price (the recalculation rule)
SELECT 'crm_sales_details: sales != quantity * price' AS check_name, COUNT(*) AS violations
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price;

-- 5. No negative or zero prices/quantities
SELECT 'crm_sales_details: invalid price or quantity' AS check_name, COUNT(*) AS violations
FROM silver.crm_sales_details
WHERE sls_price <= 0 OR sls_quantity <= 0;

-- 6. Product line must only contain the expanded vocabulary
SELECT 'crm_prd_info: unmapped product_line' AS check_name, COUNT(*) AS violations
FROM silver.crm_prd_info
WHERE prd_line NOT IN ('Mountain', 'Road', 'Other Sales', 'Touring', 'n/a');

-- ===== crm_sales_details =====

-- 7. Sales amount must always equal quantity * price (the recalculation rule)
SELECT 'crm_sales_details: sales != quantity * price' AS check_name, COUNT(*) AS violations
FROM silver.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price;

-- 8. No negative or zero prices/quantities
SELECT 'crm_sales_details: invalid price or quantity' AS check_name, COUNT(*) AS violations
FROM silver.crm_sales_details
WHERE sls_price <= 0 OR sls_quantity <= 0;

-- 9. Order date should never be after ship date or due date
SELECT 'crm_sales_details: order date after ship/due date' AS check_name, COUNT(*) AS violations
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

-- ===== erp_cust_az12 =====

-- 10. No future birthdates
SELECT 'erp_cust_az12: future birthdate' AS check_name, COUNT(*) AS violations
FROM silver.erp_cust_az12
WHERE bdate > GETDATE();

-- 11. Gender must only contain the expanded vocabulary
SELECT 'erp_cust_az12: unmapped gender' AS check_name, COUNT(*) AS violations
FROM silver.erp_cust_az12
WHERE gen NOT IN ('Female', 'Male', 'n/a');

-- ===== erp_loc_a101 =====

-- 12. Country should never be blank — must be a real name or 'n/a'
SELECT 'erp_loc_a101: blank country' AS check_name, COUNT(*) AS violations
FROM silver.erp_loc_a101
WHERE cntry = '' OR cntry IS NULL;

-- ===== erp_px_cat_g1v2 =====

-- 13. Category ID should never be null (join key into products)
SELECT 'erp_px_cat_g1v2: null id' AS check_name, COUNT(*) AS violations
FROM silver.erp_px_cat_g1v2
WHERE id IS NULL;
