# Data Architecture

The warehouse follows the **Medallion Architecture**: three layers, each with a single responsibility, each consuming only the layer directly below it.

```mermaid
flowchart LR
    subgraph SRC["Sources"]
        CRM["CRM<br/>cust_info<br/>prd_info<br/>sales_details"]
        ERP["ERP<br/>CUST_AZ12<br/>LOC_A101<br/>PX_CAT_G1V2"]
    end

    subgraph BRZ["Bronze — Raw"]
        B["6 tables, as-is<br/>no transformation"]
    end

    subgraph SLV["Silver — Cleansed"]
        S["6 tables<br/>deduplicated, trimmed,<br/>typed, standardised"]
    end

    subgraph GLD["Gold — Business-Ready"]
        D1["dim_customers"]
        D2["dim_products"]
        F["fact_sales"]
    end

    subgraph BI["Consumption"]
        R["SQL analytics<br/>report_customers / report_products"]
    end

    CRM -->|BULK INSERT| B
    ERP -->|BULK INSERT| B
    B -->|silver.load_silver| S
    S -->|CREATE VIEW| D1
    S -->|CREATE VIEW| D2
    S -->|CREATE VIEW| F
    D1 --> R
    D2 --> R
    F --> R
```

## Layer responsibilities

| | Bronze | Silver | Gold |
|---|---|---|---|
| **Purpose** | Faithful landing zone | Cleansing and conforming | Business consumption |
| **Object type** | Tables | Tables | Views |
| **Transformation** | None | Dedup, trim, type-cast, standardise, derive | Joins, surrogate keys, segmentation |
| **Load method** | `BULK INSERT`, full refresh | Stored procedure, full refresh | Recomputed on query |
| **Audience** | Data engineers | Data engineers, analysts | Analysts, BI tools, stakeholders |

### Why bronze doesn't clean anything

Every value in the warehouse needs to be traceable back to the exact CSV row it came from. If bronze applied cleaning logic, that traceability breaks the moment a cleaning rule has a bug — there's no way to tell whether bad data came from the source or from the transformation. That's why raw sales dates land in bronze as plain integers (e.g. `20101229`) instead of proper dates — the invalid ones need to survive long enough for silver to actually validate and fix them, rather than being silently reshaped on the way in.

### Why gold is views, not tables

Gold doesn't introduce new data — it renames columns, joins silver tables together, and assigns surrogate keys. Making these physical tables would mean storing the same data twice and adding a second refresh step that could drift out of sync with silver. As views, they recompute on every read, so they're always guaranteed to match the layer underneath them.

The trade-off is query cost: `fact_sales` joins two dimension views every time it's queried. At this project's scale (27,659 orders, 60,423 units) that's negligible. At real production volume, the fix would be materializing gold into tables loaded by a `gold.load_gold` procedure — same object names, so nothing downstream (reports, BI tools) would need to change.

## Data flow

```mermaid
flowchart TD
    A1["cust_info.csv"] --> B1["bronze.crm_cust_info"] --> C1["silver.crm_cust_info"]
    A2["prd_info.csv"] --> B2["bronze.crm_prd_info"] --> C2["silver.crm_prd_info"]
    A3["sales_details.csv"] --> B3["bronze.crm_sales_details"] --> C3["silver.crm_sales_details"]
    A4["CUST_AZ12.csv"] --> B4["bronze.erp_cust_az12"] --> C4["silver.erp_cust_az12"]
    A5["LOC_A101.csv"] --> B5["bronze.erp_loc_a101"] --> C5["silver.erp_loc_a101"]
    A6["PX_CAT_G1V2.csv"] --> B6["bronze.erp_px_cat_g1v2"] --> C6["silver.erp_px_cat_g1v2"]

    C1 --> D1["gold.dim_customers"]
    C4 --> D1
    C5 --> D1
    C2 --> D2["gold.dim_products"]
    C6 --> D2
    C3 --> D3["gold.fact_sales"]
    D1 --> D3
    D2 --> D3
    D1 --> RC["gold.report_customers"]
    D2 --> RP["gold.report_products"]
    D3 --> RC
    D3 --> RP
```

## Star schema

`fact_sales` sits at the centre, referencing two conformed dimensions by surrogate key.

```mermaid
erDiagram
    dim_customers ||--o{ fact_sales : "customer_key"
    dim_products  ||--o{ fact_sales : "product_key"

    dim_customers {
        int customer_key PK
        int customer_id
        varchar customer_number
        varchar first_name
        varchar last_name
        varchar country
        varchar marital_status
        varchar gender
        date birthdate
        date create_date
    }
    dim_products {
        int product_key PK
        int product_id
        varchar product_number
        varchar product_name
        varchar category_id
        varchar category
        varchar subcategory
        varchar maintenance
        int cost
        varchar product_line
        date start_date
    }
    fact_sales {
        varchar order_number
        int product_key FK
        int customer_key FK
        date order_date
        date shipping_date
        date due_date
        int sales_amount
        int quantity
        int price
    }
```

## Key integration decisions

**Customer keys differ across all three sources.** CRM uses a key like `AW00011000`, the ERP customer table prefixes it with `NAS`, and the ERP location table hyphenates it (`AW-00011000`). Silver strips the `NAS` prefix and removes hyphens so all three conform to the CRM key, which is treated as the master identifier.

**Gender is mastered by CRM, with ERP as fallback.** Both systems capture gender and they sometimes disagree. `gold.dim_customers` uses the CRM value by default and only falls back to the ERP value when CRM has none — rather than trusting ERP first or trying to reconcile conflicts.

**Product category isn't an explicit foreign key — it's embedded in the key itself.** The first 5 characters of `prd_key` in CRM double as the category ID used in the ERP category table. Silver extracts that substring into `cat_id` and normalizes the separator so it joins cleanly against `erp_px_cat_g1v2.id`.