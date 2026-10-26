# Power BI Dashboard Guide

**Status:** Initial PBIP shell; source binding, semantic model, measures, visuals, and validation are pending.

The project entry point is [`../E-commerce-Delivery-Logistics-Dashboard.pbip`](../E-commerce-Delivery-Logistics-Dashboard.pbip). It contains five blank report pages and an empty semantic model. Open it in a current version of Power BI Desktop to continue authoring. The shell intentionally has no machine-specific file paths, credentials, measures, or visuals.

## Planned pages

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
| `data/interim/kpi_orders_all.csv` | All order statuses; 19 reported fields and one row per `order_id` in the snapshot checked for this shell (99,441 rows). | Best CSV candidate for status and cancellation analysis, subject to team approval and KPI/date-rule validation. |
| `data/interim/kpi_orders.csv` | Delivered orders only; same reported 19 fields and one row per `order_id` in the checked snapshot (96,470 rows). | Candidate for delivery analysis only. Do not use it as the denominator for all-order cancellation rate or as a substitute for diagnostics on excluded orders. |
| `data/raw/olist_orders_dataset.csv` | One source row per order; status and purchase, carrier, actual-delivery, and estimated-delivery timestamps. | Base source for order status and delivery timestamps. Keep the source unchanged. |
| `data/raw/olist_customers_dataset.csv` | Customer records keyed by `customer_id`. | Geography enrichment. Join on the validated customer key. |
| `data/raw/olist_order_items_dataset.csv` | Item rows keyed by `(order_id, order_item_id)`. | Aggregate to order or order-category grain before joining to order-level data. |
| `data/raw/olist_order_reviews_dataset.csv` | Review records; multiple records can be associated with an order. | Preserve review rows; aggregate valid scores to mean score per order for order-level outcome comparisons. Use review rows for a review-record score distribution. |
| `data/raw/olist_products_dataset.csv` | Product attributes keyed by `product_id`. | Optional product/category enrichment after validating item-to-product references. |
| `data/raw/product_category_name_translation.csv` | Source-to-English product-category mapping. | Optional category labels; some source categories may not have a translation. |

The two KPI exports have matching headers in the snapshot examined: `order_id`, `order_status`, `customer_state`, `region`, `order_purchase_timestamp`, `weekday_num`, `weekday`, `category`, `n_items`, `order_value`, `freight_total`, `review_score`, `approval_days`, `handling_days`, `delivery_days`, `delay_days`, `is_on_time`, `is_canceled`, and `is_low_rating`. Treat this as an observed file schema, not a signed-off contract. Recheck uniqueness, data types, nullability, flags, date logic, and measure eligibility when binding the source.

### Reconciliation and quality cautions

- The checked CSV snapshot contains 99,441 unique order IDs in `kpi_orders_all.csv` and 96,470 unique delivered-order IDs in `kpi_orders.csv`. Saved SQL validation evidence also reports a 99,440-row order view in another snapshot. Resolve this one-row/source-snapshot discrepancy before declaring the dataset canonical.
- The KPI contract requires on-time/late classification by **calendar date**, for delivered orders with valid actual and estimated dates. The validation report documents that an existing SQL query uses a full-timestamp comparison in one result; do not assume the exported `is_on_time` flag follows the agreed rule until verified.
- Duration uses elapsed time between full timestamps. Missing or invalid required timestamps are excluded and reported; negative intervals are flagged, not silently corrected. Investigate extreme positive durations before considering exclusions.
- Cancellation rate is canceled orders divided by all valid unique orders under the documented project rule. `unavailable` remains a distinct status in the denominator, not part of the canceled numerator.
- Review records are not necessarily one-per-order. For delivery-outcome comparisons, average valid scores by order before joining; do not interpret an association as causation.
- Existing tables and figures under `reports/` are preliminary analysis outputs, not canonical model inputs.

See [`kpi_definitions.md`](kpi_definitions.md), [`data_quality/data_validation_summary.md`](data_quality/data_validation_summary.md), and [`integration/data_contract.md`](integration/data_contract.md) for definitions, evidence, and outstanding source decisions.

