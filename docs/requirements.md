# Project Requirements

## 1. Building the Data Warehouse (Data Engineering)

### Objective
Develop a modern data warehouse to consolidate sales data, enabling analytical
reporting and informed decision-making.

### Specifications

| # | Requirement | How it is met |
|---|---|---|
| 1 | **Data Sources** — import from two source systems (ERP and CRM) provided as CSV files | Six CSVs land in `dataset/source_crm/` and `dataset/source_erp/`, loaded by `scripts/bronze/proc_load_bronze.sql` |
| 2 | **Data Quality** — cleanse and resolve quality issues prior to analysis | `silver.load_silver` applies deduplication, trimming, code expansion, date repair and category correction; `tests/quality_checks_silver.sql` proves each rule holds |
| 3 | **Integration** — combine both sources into a single, user-friendly model | The gold layer joins CRM and ERP on conformed keys into `dim_customers`, `dim_products`, `fact_sales` |
| 4 | **Scope** — latest dataset only, no historisation | All loads are full-refresh (`TRUNCATE` + `INSERT`); `dim_products` exposes current products only |
| 5 | **Documentation** — clear documentation of the data model | `docs/data_catalog.md` documents every gold field; `docs/data_architecture.md` documents the flow |

### Data quality issues found and resolved

| Source | Issue | Resolution |
|---|---|---|
| `cust_info.csv` | `cst_id` duplicated across rows | Keep the most recent record per customer via `ROW_NUMBER()` ordered by `cst_create_date DESC` — verified 0 duplicate `cst_id` remain in `silver.crm_cust_info` |
| `cust_info.csv` | Names inconsistently padded with whitespace | `TRIM()` applied on first and last name |
| `cust_info.csv` | Gender/marital status stored as single-letter codes | Expanded to `Male`/`Female`, `Single`/`Married`; unknowns become `n/a` |
| `prd_info.csv` | `prd_cost` blank on some rows | Defaulted to `0` so revenue math never nulls out |
| `prd_info.csv` | `prd_key` is a composite of category id + product key | Split: chars 1-5 become `cat_id`, chars 7+ become `prd_key` |
| `prd_info.csv` | `prd_end_dt` unreliable | Recalculated as the day before the next start date for the same product, via `LEAD()` |
| `sales_details.csv` | Order/ship/due dates stored as integers (e.g. `20101229`) | Converted to `DATE`; invalid values (0 or wrong length) become `NULL` — verified 19 rows affected (`sls_order_dt`), revenue retained since only the date is nulled, not the row |
| `sales_details.csv` | `sales_amount <> quantity * price` on some rows; invalid prices | Recomputed from the identity, using `ABS(price)` |
| `CUST_AZ12.csv` | `cid` carries a `NAS` prefix absent from CRM's key | Prefix stripped so the key joins |
| `CUST_AZ12.csv` | Some birthdates in the future | Set to `NULL` |
| `LOC_A101.csv` | `cid` contains hyphens absent from CRM's key | Hyphens removed |
| `LOC_A101.csv` | Country codes inconsistent (`DE`, `US`, `USA`, blank) | Normalized to full names; blanks become `n/a` |
| `prd_info.csv` vs `PX_CAT_G1V2.csv` | CRM codes pedal products `CO_PE`; ERP's category table has no `CO_PE`, only `CO_PD` (Components / Pedals) — 7 products resolved to no category | `CO_PE` remapped to `CO_PD` in `silver.load_silver` — see assumption below |

### Assumption: CO_PE → CO_PD

This mapping is inferred, not supplied by either source system. Evidence: all
seven affected products are named `...Pedal` (`LL Mountain Pedal`, `Touring
Pedal`, etc.), ERP's `CO_PD` is exactly `Components / Pedals`, and no other
ERP category code is a plausible match. Verified by direct query before and
after the fix:
```sql
SELECT DISTINCT p.prd_nm, p.cat_id
FROM silver.crm_prd_info p
LEFT JOIN silver.erp_px_cat_g1v2 c ON p.cat_id = c.id
WHERE c.id IS NULL;
```
Before the fix: 7 rows returned (all pedal products). After: 0 rows.

If this assumption turns out to be wrong, the single `CASE` in
`silver.load_silver` that performs it can be removed without touching
anything else — `tests/quality_checks_silver.sql` would then flag those 7
rows again automatically.

## 2. BI: Analytics & Reporting (Data Analysis)

### Objective
Develop SQL-based analytics delivering insight into:

- **Sales Trends** — headline KPIs, monthly trends, running totals and moving averages (`analytics/01_exploratory_analysis.sql`, `analytics/02_trends_and_cumulative.sql`)
- **Product & Customer Performance** — year-over-year change, part-to-whole revenue contribution (`analytics/03_performance_and_part_to_whole.sql`)
- **Segmentation** — customer VIP/Regular/New tiers, product cost banding (`analytics/04_segmentation.sql`, `scripts/gold/report_customers.sql`, `scripts/gold/report_products.sql`)

### Headline KPIs (verified against gold.fact_sales)
- Total Sales: $29,356,250
- Total Orders: 27,659
- Total Customers: 18,484
- Total Products: 295
- Total Quantity Sold: 60,423
- Average Price: $486