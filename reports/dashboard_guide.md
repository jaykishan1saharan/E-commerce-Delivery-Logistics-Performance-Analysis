# Power BI Dashboard Guide

**Status:** The editable Week 3 PBIP source has been refreshed in Power BI Desktop and visually reviewed. The six visual aggregations have been checked against the imported CSV snapshot; source-level comparisons are recorded in [`dashboard_source_reconciliation.csv`](dashboard_source_reconciliation.csv), and snapshot-level results in [`dashboard_sql_reconciliation.csv`](dashboard_sql_reconciliation.csv) using [`08_week3_dashboard_reconciliation.sql`](../sql/08_week3_dashboard_reconciliation.sql). Counts by source status, purchase month, and region match. The assigned-category visual remains incomplete: 2,175 of 99,441 per-order category sets differ from the raw item/product/translation join. 

There are two separate Power BI projects in the repository. The original [`../E-commerce-Delivery-Logistics-Dashboard.pbip`](../E-commerce-Delivery-Logistics-Dashboard.pbip) is an unbound starter shell with blank pages. The Week 3 deliverable is [`../powerbi/week3_delivery_dashboard.pbix`](../powerbi/week3_delivery_dashboard.pbix), with editable source at [`../powerbi/week3_delivery_dashboard.pbip`](../powerbi/week3_delivery_dashboard.pbip). The updated PBIP visuals were rendered and reviewed in Power BI Desktop; that review does not mean the existing PBIX file has been regenerated.

## Week 3 dashboard contents and validation

The single **Regional & Segment Performance** page contains six visuals: unique orders by region, orders by assigned category, average elapsed delivery days by region, unique order volume by purchase month, average elapsed delivery days by purchase month, and unique orders by source status. The duration measure `Average Elapsed Delivery Days` averages the imported `delivery_days` for delivered orders with a nonblank, non-negative value. The measure now explicitly excludes blanks. It is a descriptive elapsed-duration measure, not the approved calendar-date timeliness KPI. The category visual title includes a coverage warning because the assigned category field does not preserve every category present in the raw order items.

### SQL validation cross-check

The PBIX's `Unique Orders` measure is `DISTINCTCOUNT(Orders[order_id])`. Its imported [`kpi_orders_all.csv`](../data/interim/kpi_orders_all.csv) contains 99,441 rows and 99,441 unique order IDs. The saved [SQL/Python KPI comparison](member2/sql_python_kpi_comparison.csv) independently reports 99,441 total and unique orders, 96,478 delivered orders, and 625 canceled orders, with SQL and Python matching for each. These checks support the dashboard's overall distinct-order basis and the delivered/canceled population totals.

The validated SQL timeliness baseline is 6,534 late and 89,936 on-time orders out of 96,470 eligible delivered orders (6.77% and 93.23%). Recomputing by calendar date from raw order timestamps produces the same result, with 2,971 of 99,441 orders ineligible/unknown. Those measures are **not** shown in the PBIX. Its imported `is_on_time` field has 7,827 zeroes, 88,649 ones, and 2,965 nulls; it must not be used as a substitute. The independent [flag validation summary](member2/validation_summary.md) applies to the separate `kpi_orders.csv` export and reports zero mismatches for its `on_time_eligible` and `on_time` fields. The side-by-side flag totals are preserved in [`dashboard_timeliness_reconciliation.csv`](dashboard_timeliness_reconciliation.csv).

The [SQL reconciliation output](dashboard_sql_reconciliation.csv) contains **142 segment rows** covering all six visuals. The updated duration measure's SQL equivalent includes **96,470** eligible orders after delivered-status, nonblank, and non-negative-duration filters. The source-level comparison matches order counts by status, month, and region; duration averages differ only slightly because the CSV duration values are rounded before import. Category blanks are mapped to `Unclassified`; per-order distinct category sets match the raw item/product/translation join for 97,266 of 99,441 orders, leaving 2,175 mismatches. The category chart is therefore not a source-reconciled category KPI.

The imported snapshot uses `data/interim/kpi_orders_all.csv` at the absolute path recorded in the PBIP source project's `Orders.tmdl` partition. If the PBIP source project is opened from another checkout, update its `File.Contents` path before refreshing. The updated project was refreshed and rendered in Power BI Desktop, but its latest changes still need to be saved/exported to [`../powerbi/week3_delivery_dashboard.pbix`](../powerbi/week3_delivery_dashboard.pbix). A fresh live MySQL source-to-export rerun and formal approval also remain pending.

## Original starter-shell plan (not the Week 3 PBIX)

| Page | Purpose | Planned content |
|---|---|---|
| **Overview** | Summarize order volume and headline logistics outcomes. | KPI cards for valid unique orders, cancellation rate, on-time rate, and average delivery duration; order volume by purchase month; a small set of state/region comparisons. |
| **Delivery Performance** | Explain delivery timeliness and elapsed delivery duration. | On-time/late counts and rates, delivery-duration distribution and trend, and state/region breakdowns. Include the eligible delivered-order count and missing-date diagnostics alongside rates. |
| **Order Status & Cancellations** | Show the full order-status mix and cancellation context. | Orders by source status, canceled-order count, and cancellation rate. Keep `unavailable` separate from `canceled`. |
| **Customer Reviews** | Describe review scores and their relationship to delivery outcomes. | Review-score distribution and, after review records have been averaged per order, comparison of average scores for eligible on-time and late delivered orders. |
| **Data Quality & Definitions** | Make population rules, exceptions, and limitations visible. | Data-source/snapshot note, key and grain checks, missing/invalid timestamp counts, unresolved reconciliation items, KPI definitions, and caveats. |

Date, customer state/region, order status, and category are candidate slicers. Add only slicers whose fields exist in the agreed model and preserve the KPI eligibility rules when they are applied.

## Data-source notes

### Preferred source after team confirmation

Use the agreed SQL clean views or an approved analytical output, with one row per `order_id` for order-level measures. Aggregate order items and reviews to their intended grain before joining them to orders. The shared interface is still pending confirmation; see [`integration/data_contract.md`](integration/data_contract.md). Do not connect a report to raw item or review detail and then count order rows without controlling for join fan-out.

### Available CSV candidates

| File | Grain / role | Guidance |
|---|---|---|
| `data/interim/kpi_orders_all.csv` | All order statuses; 19 fields and 99,441 unique order IDs in the current snapshot. This is the file imported by the Week 3 PBIX. | Use only with the validation caveats above. Its `is_on_time` field does not match the validated SQL timeliness totals. |
| `data/interim/kpi_orders.csv` | Current file has 99,441 rows across source order statuses and includes timestamp, `on_time_eligible`, and `on_time` fields; one row per `order_id` in the checked snapshot. | Its two flags have independent Python validation evidence. Do not assume it is the PBIX input or the source for every saved chart. |
| `data/raw/olist_orders_dataset.csv` | One source row per order; status and purchase, carrier, actual-delivery, and estimated-delivery timestamps. | Base source for order status and delivery timestamps. Keep the source unchanged. |
| `data/raw/olist_customers_dataset.csv` | Customer records keyed by `customer_id`. | Geography enrichment. Join on the validated customer key. |
| `data/raw/olist_order_items_dataset.csv` | Item rows keyed by `(order_id, order_item_id)`. | Aggregate to order or order-category grain before joining to order-level data. |
| `data/raw/olist_order_reviews_dataset.csv` | Review records; multiple records can be associated with an order. | Preserve review rows; aggregate valid scores to mean score per order for order-level outcome comparisons. Use review rows for a review-record score distribution. |
| `data/raw/olist_products_dataset.csv` | Product attributes keyed by `product_id`. | Optional product/category enrichment after validating item-to-product references. |
| `data/raw/product_category_name_translation.csv` | Source-to-English product-category mapping. | Optional category labels; some source categories may not have a translation. |

The current two KPI exports do **not** have matching schemas. The PBIX input `kpi_orders_all.csv` contains the order-level summary fields `order_id`, `order_status`, `customer_state`, `region`, `order_purchase_timestamp`, `weekday_num`, `weekday`, `category`, `n_items`, `order_value`, `freight_total`, `review_score`, `approval_days`, `handling_days`, `delivery_days`, `delay_days`, `is_on_time`, `is_canceled`, and `is_low_rating`. The separate `kpi_orders.csv` contains source timestamps and independently checked `on_time_eligible` and `on_time` flags. These observed schemas are not a signed-off shared data contract.

### Reproducing the dashboard aggregation cross-check

The committed SQL query uses SQLite syntax. Load the PBIX input CSV into an in-memory or temporary SQLite table named `dashboard_orders` with its header names, then run `sql/08_week3_dashboard_reconciliation.sql`. The query returns the distinct-order totals, eligible duration counts, and average duration for every segment displayed by the six report visuals. The checked output is saved in `reports/dashboard_sql_reconciliation.csv`. This check deliberately uses the same imported snapshot as the report: it validates DAX-equivalent visual calculations and is not an independent MySQL rebuild of that snapshot from raw source tables.

### Reconciliation and quality cautions

- The current checked snapshots contain 99,441 unique order IDs in each KPI CSV. Other saved SQL evidence reports 99,440 rows in a clean order view; resolve this source/snapshot discrepancy before declaring the dataset canonical.
- The KPI contract requires on-time/late classification by **calendar date**, for delivered orders with valid actual and estimated dates. The PBIX input's `is_on_time` totals do not match the validated SQL baseline. The PBIX does not visualize that field; keep it excluded unless its source and definition are reconciled.
- Duration uses elapsed time between full timestamps. Missing or invalid required timestamps are excluded and reported; negative intervals are flagged, not silently corrected. Investigate extreme positive durations before considering exclusions.
- Cancellation rate is canceled orders divided by all valid unique orders under the documented project rule. `unavailable` remains a distinct status in the denominator, not part of the canceled numerator.
- Review records are not necessarily one-per-order. For delivery-outcome comparisons, average valid scores by order before joining; do not interpret an association as causation.
- The SQLite reconciliation validates visual aggregation against the PBIX CSV. The raw-CSV comparisons in `dashboard_source_reconciliation.csv` add a source-level cross-check but do not replace a fresh MySQL source-to-export rerun.
- Existing tables and figures under `reports/` are preliminary analysis outputs, not canonical model inputs.

See [`kpi_definitions.md`](kpi_definitions.md), [`data_quality/data_validation_summary.md`](data_quality/data_validation_summary.md), and [`integration/data_contract.md`](integration/data_contract.md) for definitions, evidence, and outstanding source decisions.
