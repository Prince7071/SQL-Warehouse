# Key Insights

Derived from `gold.fact_sales`, `gold.report_customers`, `gold.report_products`,
and the analytics scripts in `analytics/`. All figures below are exact query
results, not estimates.

## Revenue Is Heavily Concentrated in Bikes
Bikes account for **96.46% of total revenue** ($28,316,272 of $29,356,250),
with Accessories at 2.39% ($700,262) and Clothing at just 1.16% ($339,716) —
despite Accessories and Clothing together making up nearly half the product
catalog (110 products under $100, mostly accessories/clothing, vs. 84 products
over $500, mostly bikes). This means the business is almost entirely exposed
to Bikes-category risk (supply, pricing, demand shifts), while two-thirds of
the product catalog contributes under 4% of revenue combined — a strong
candidate for a cross-sell or bundling push rather than further SKU expansion.

## Order Volume Exploded While Average Order Value Collapsed
Between 2011 and 2013, order count grew nearly **10x** (2,216 → 21,287 orders)
while revenue grew only ~2.3x ($7.07M → $16.34M). The implied average order
value fell from **$3,193 in 2011 to $768 in 2013**. This lines up with the
product data: dozens of low-cost accessory/clothing SKUs (bottles, gloves,
caps, socks) first appear in 2012 and scale sharply in 2013, while bikes stay
high-value but roughly flat in unit count. The business didn't just grow — its
mix shifted from a small number of high-value bike sales toward a much larger
base of low-value accessory purchases, which is also visible directly in the
monthly average price, which fell from ~$3,200 in early 2011 to under $350 by
late 2013.

## Customer Base Is 79% New, Only 9% VIP
Of 18,484 total customers: **14,631 are New, 2,198 are Regular, and 1,655 are
VIP** (12+ month relationship, $5,000+ lifetime spend). A New-heavy base like
this signals strong acquisition but an open question on retention — the
natural follow-up analysis is what % of New customers convert to Regular/VIP
within their first year, which `gold.report_customers.lifespan` is already
tracking and would answer directly.

## 2014 Data Is Incomplete — a Deliberate Read, Not an Assumption
The year-over-year analysis (`analytics/03_performance_and_part_to_whole.sql`)
flags nearly every product as "Decrease" in 2014. Taken at face value this
would suggest a business collapse. It doesn't: 2014 contains only 45,642 in
sales and 871 orders — versus $16.3M and 21,287 orders across all of 2013 —
because the dataset simply ends in **January 2014**, not because demand
dropped. Any year-over-year figure involving 2014 should be treated as
partial-year and excluded from trend conclusions. The one YoY comparison
that *is* reliable is 2011 → 2012 → 2013, where products like the
**Mountain-200 Black-38** grew consistently across all three full years
($4,098 → $342,921 → $945,540) — a genuine, sustained growth story rather
than a single-year spike.

## The Two Total-Sales Figures That Don't Quite Match — On Purpose
`gold.fact_sales` sums to $29,356,250 in total, but the monthly trend query's
running total tops out at $29,351,258 — a $4,992 gap. This isn't a bug: the
monthly trend filters `WHERE order_date IS NOT NULL`, and 19 sales rows have
no usable order date (documented in `docs/requirements.md`). Their revenue is
correctly included in the overall total but excluded from any date-based
trend, which is the intended behavior — you can't put a row on a timeline
without a valid date, but you shouldn't drop its revenue from totals just
because the date is missing.