# Day 1 Data Quality Validation Summary

**Project:** E-commerce Delivery & Logistics Performance Analysis  
**Database:** `ecommerce_delivery`

## Completed checklist items

| # | Completed checklist item | Verification |
|---:|---|---|
| 1 | Inspected `sql/02_data_quality_audit.sql` | Reviewed staging counts and key, value, timestamp, and reference checks. |
| 2 | Inspected `sql/03_create_clean_views.sql` | Reviewed staging inputs, six clean-view definitions, filters, normalization, duplicate ranking, and validation queries. |
| 3 | Inspected `reports/data_quality/data_quality_report.csv` | Reviewed the existing file; did not change it. |
| 4 | Inspected `reports/data_quality/cleaning_log.csv` | Reviewed its recorded findings and cleaning decisions. |
| 5 | Inspected `reports/data_quality/data_dictionary.csv` | Reviewed documented columns and key notes. |
| 6 | Identified all six raw CSV filenames | Confirmed against files in `data/raw/`. |
| 9 | Counted raw CSV records, excluding headers | Counts recorded in the dataset baseline below. |
| 10 | Counted rows in all six staging tables | Saved MySQL output `query1.csv`. |
| 11 | Counted rows in all six existing clean views | Saved MySQL output `query21.csv`. |
| 17 | Compared raw, staging, and clean-view counts | Comparison recorded below for all six datasets. |
| 18 | Recorded verified findings and discrepancies | Audit log below records results and saved query evidence. |
| 20 | Created `reports/data_quality/day1_validation_summary.md` | This file. |
| 21 | Added raw-order timestamp-quality findings | Counts, status context, duration review criteria, and exception evidence are summarized below. |

## Dataset row-count baseline

| Dataset | Raw CSV file | Staging table | Raw rows | Staging rows | Clean view | Clean rows |
|---|---|---|---:|---:|---|---:|
| Customers | `olist_customers_dataset.csv` | `customers_stage` | 99,441 | 99,441 | `customers_clean` | 99,441 |
| Orders | `olist_orders_dataset.csv` | `orders_stage` | 99,441 | 99,440 | `orders_clean` | 99,440 |
| Order items | `olist_order_items_dataset.csv` | `items_stage` | 112,650 | 112,649 | `items_clean` | 112,649 |
| Reviews | `olist_order_reviews_dataset.csv` | `reviews_stage` | 99,224 | 99,223 | `reviews_clean` | 98,409 |
| Products | `olist_products_dataset.csv` | `products_stage` | 32,951 | 32,950 | `products_clean` | 32,950 |
| Category translations | `product_category_name_translation.csv` | `translation_stage` | 71 | 71 | `translation_clean` | 71 |
| **Total** |  |  | **443,778** | **443,774** |  | **443,660** |

## Audit log


| Dataset | Issue / check | Measure | Affected rows / result | Action taken | Reason / interpretation | Saved output |
|---|---|---|---:|---|---|---|
| Customers | Missing or blank checked customer fields | Rows | 0 | Checked and retained | No missing or blank customer ID, unique ID, postal prefix, city, or state values reported. | [query2.csv](../../data/interim/query2.csv) |
| Customers | Duplicate `customer_id` | Duplicate groups | 0 | Checked; no duplicate groups returned | Customer ID duplicate check. | [query8.csv](../../data/interim/query8.csv), [query20.csv](../../data/interim/query20.csv) |
| Orders | Missing/blank order fields | Rows | 0 | Checked and retained | Checked order/customer IDs, status, purchase timestamp, and estimated delivery timestamp. | [query3.csv](../../data/interim/query3.csv), [query25.csv](../../data/interim/query25.csv) |
| Orders | Duplicate `order_id` | Duplicate groups | 0 | Checked; no duplicate groups returned | Order ID duplicate check. | [query9.csv](../../data/interim/query9.csv), [query26.csv](../../data/interim/query26.csv) |
| Order items | Missing checked key and non-key fields | Rows | 0 | Checked and retained | Checked order and item IDs, product, seller, shipping limit, price, and freight. | [query4.csv](../../data/interim/query4.csv) |
| Order items | Duplicate `(order_id, order_item_id)` | Duplicate groups | 0 | Checked; no duplicate groups returned | Composite item key duplicate check. | [query10.csv](../../data/interim/query10.csv), [query27.csv](../../data/interim/query27.csv) |
| Reviews | Missing checked identifiers, score, and timestamps | Rows | 0 | Checked and retained | Review ID, order ID, score, creation timestamp, and answer timestamp checks. | [query5.csv](../../data/interim/query5.csv) |
| Reviews | Duplicate `review_id` | Duplicate groups; excess rows | 789 groups; 814 excess rows | Ranked by completeness in existing clean view | Duplicate review IDs account for the 814-row staging-to-clean reduction. | [query11.csv](../../data/interim/query11.csv), [query21.csv](../../data/interim/query21.csv) |
| Reviews | Blank or NULL optional title/message | Rows | 87,657 titles; 58,255 messages | Retained; no text imputed | Review text can be optional. | [query5.csv](../../data/interim/query5.csv) |
| Reviews | Invalid score outside 1–5 | Rows | 0 | Checked; none returned | All reported scores are within the valid range. | [query15.csv](../../data/interim/query15.csv) |
| Reviews | Score distribution | Counts by score | 1: 11,424; 2: 3,151; 3: 8,179; 4: 19,141; 5: 57,328 | Recorded distribution | Descriptive check. | [query14.csv](../../data/interim/query14.csv) |
| Products | Missing product ID | Rows | 0 | Checked and retained | No product IDs reported missing. | [query6.csv](../../data/interim/query6.csv) |
| Products | Blank or NULL category | Rows | 610 | Retained; no category imputed | Category cannot be inferred from this check. | [query6.csv](../../data/interim/query6.csv) |
| Products | NULL or non-positive dimensions | Field values | Length: 2; height: 2; width: 2; weight: 6 | Retained as reported in staging; clean-view logic normalizes non-positive values | Each result combines NULL and non-positive values. | [query6.csv](../../data/interim/query6.csv) |
| Products | Duplicate `product_id` | Duplicate groups | 0 | Checked; no duplicate groups returned | Product ID duplicate check. | [query12.csv](../../data/interim/query12.csv) |
| Order items | Negative price or freight | Rows | 0 negative prices; 0 negative freight | Checked; no negative values returned | Negative amounts are invalid; zero values are distinct. | [query13.csv](../../data/interim/query13.csv) |
| Order items | Zero freight | Rows | 383 | Retained | Zero freight can be a valid value. | [query13.csv](../../data/interim/query13.csv) |
| Translations | Missing or blank source/English fields | Rows | 0 | Checked and retained | No missing or blank category fields reported. | [query7.csv](../../data/interim/query7.csv) |
| Orders | Missing actual delivery timestamp | Orders | 2,965 of 99,440 | Retained | May include orders that have not been delivered. | [query25.csv](../../data/interim/query25.csv) |
| Orders | Delivery before purchase | Orders | 0 | Checked; none returned | No delivery-before-purchase cases reported. | [query16.csv](../../data/interim/query16.csv), [query28.csv](../../data/interim/query28.csv) |
| Orders | Carrier handover before purchase | Orders | 166 | Flagged for review; timestamps retained | Chronology anomalies require investigation. | [query16.csv](../../data/interim/query16.csv), [query28.csv](../../data/interim/query28.csv) |
| Orders | Customer delivery before carrier handover | Orders | 23 | Flagged for review; timestamps retained | Chronology anomalies require investigation. | [query28.csv](../../data/interim/query28.csv) |
| Orders to customers | Orphan order-customer references | Orders | 0 | Checked; no orphans returned | No unmatched customer references reported. | [query17.csv](../../data/interim/query17.csv), [query30.csv](../../data/interim/query30.csv) |
| Items to orders | Orphan item-order references | Items | 1 | Retained; reference flagged | Investigate the unmatched order reference; no row deleted. | [query18.csv](../../data/interim/query18.csv), [query29.csv](../../data/interim/query29.csv) |
| Items to products | Orphan item-product references | Items | 1 | Retained; reference flagged | Investigate the unmatched product reference; no row deleted. | [query19.csv](../../data/interim/query19.csv), [query31.csv](../../data/interim/query31.csv) |
| Clean-view references | Orphans in clean views | Orders/items | 0 orders without customer; 1 item without order; 1 item without product | Checked and recorded | Results agree with the corresponding staging reference checks. | [query23.csv](../../data/interim/query23.csv) |

## Saved output index

- `query1.csv`: staging row counts; `query21.csv`: clean-view row counts.
- `query2.csv`–`query7.csv`: missing, blank, and invalid field checks.
- `query8.csv`–`query12.csv`: staging duplicate-key checks; `query20.csv` and `query22.csv`: clean-view duplicate-key checks.
- `query13.csv`–`query16.csv`: amount, score, and timestamp checks.
- `query17.csv`–`query19.csv`: staging reference checks; `query23.csv`: clean-view reference checks; `query24.csv`: translation clean-view spot check.
- `query25.csv`–`query31.csv`: additional order key/timestamp, duplicate-key, chronology, and reference checks.

## Timestamp-quality findings (raw orders)

The timestamp audit checked all **99,441** rows and distinct order IDs in [`olist_orders_dataset.csv`](../../data/raw/olist_orders_dataset.csv). It examined `order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`, `order_delivered_customer_date`, and `order_estimated_delivery_date`, alongside `order_id` and `order_status`. This raw-file audit is separate from the staging counts above; no source records were changed or removed.

| Issue | Count | Assessment |
|---|---:|---|
| Missing purchase timestamp | 0 | None found. |
| Missing estimated-delivery timestamp | 0 | None found. |
| Non-empty timestamp values that failed parsing | 0 | None found across the five timestamp columns. |
| Missing approval timestamp | 160 total; 14 delivered and 146 non-delivered | Approval time is not required for the current delivery KPIs; review if approval timing is analyzed. |
| Missing carrier-related timestamp | 1,783 total; 2 delivered and 1,781 non-delivered | Missing values on non-delivered orders are status context; the 2 delivered orders need review for carrier-timing eligibility. |
| Missing actual-delivery timestamp | 2,965 total; 8 delivered and 2,957 non-delivered | The 8 delivered orders are delivery-KPI eligibility exceptions. The non-delivered cases are not automatically defects; this includes 619 canceled orders with no delivery timestamp. |
| Actual delivery before purchase | 0 | No negative purchase-to-delivery intervals found. |
| Carrier-related timestamp before purchase | 166 | Chronology exceptions: 165 delivered orders and 1 shipped order. |
| Carrier-related timestamp after actual delivery | 23 | Chronology exceptions for review. |
| Actual-delivery timestamp on a non-delivered order | 6 | All 6 are marked canceled; reconcile status and timestamp without changing either automatically. |
| Delivered orders after estimated calendar date | 6,534 | A late-delivery outcome, not an impossible chronology defect. |
| Valid delivered purchase-to-delivery durations | 96,470 | Purchase-to-actual-delivery elapsed time, using timestamps. |
| Durations above the exploratory 99th percentile | 965 | P99 is 46.050262 days; maximum is 209.628611 days. Investigation flags only—no deletion, exclusion, or winsorization rule was applied. |

Missing delivery-related timestamps for non-delivered statuses are separated from data-quality defects. Counts by status and order-level exceptions were reviewed in the timestamp audit; no records were changed, removed, or winsorized.

The checks align with current KPI draft: count unique orders, require applicable timestamps for delivered-order KPIs, report missing data separately, use timestamp subtraction for durations and calendar dates for lateness, and investigate rather than automatically exclude negative or extreme durations. KPI definitions remain subject to team approval. `order_delivered_carrier_date` is treated only as a recorded carrier-related timestamp; its interpretation as the exact physical handoff still needs confirmation.

## Key integrity and relationships

### Key columns and evidence

The logical keys below are confirmed by [`data_dictionary.csv`](data_dictionary.csv) and the partitioning/deduplication rules in [`03_create_clean_views.sql`](../../sql/03_create_clean_views.sql). 

| Dataset | Confirmed logical key | Relationship role |
|---|---|---|
| Customers | `customer_id` | Referenced by `orders.customer_id`; `customer_unique_id` is a separate person-level identifier and is not the row key. |
| Orders | `order_id` | Referenced by order items and reviews. |
| Order items | `(order_id, order_item_id)` | `order_id` references orders; `product_id` references products. |
| Reviews | `review_id` | `order_id` references orders; multiple reviews per order are allowed by this key definition. |
| Products | `product_id` | `product_category_name` should map to the translation source category when populated and covered by the translation table. |
| Category translations | `product_category_name` (source-language value) | Source category is the lookup key; English category is its label. |

### Rows, distinct keys, and duplicate keys

Raw counts and key counts below were independently measured from the six files in [`data/raw/`](../../data/raw/) using CSV headers and case-sensitive key values after trimming surrounding whitespace (UTF-8 BOM-aware read); blank key tuples are excluded from distinct counts. Staging counts are from [`query1.csv`](../../data/interim/query1.csv), clean counts from [`query21.csv`](../../data/interim/query21.csv), and duplicate checks from [`02_data_quality_audit.sql`](../../sql/02_data_quality_audit.sql), [`03_create_clean_views.sql`](../../sql/03_create_clean_views.sql), the saved duplicate-query outputs, and [`cleaning_log.csv`](cleaning_log.csv). “Duplicate excess” means rows beyond the first occurrence for each duplicated key.

| Dataset / key | Raw rows | Raw distinct keys | Raw duplicate groups / excess | Staging rows | Staging distinct keys | Staging duplicate groups / excess | Clean rows | Clean distinct keys | Clean duplicate groups / excess |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Customers / `customer_id` | 99,441 | 99,441 | 0 / 0 | 99,441 | 99,441 | 0 / 0 | 99,441 | 99,441 | 0 / 0 |
| Orders / `order_id` | 99,441 | 99,441 | 0 / 0 | 99,440 | 99,440 | 0 / 0 | 99,440 | 99,440 | 0 / 0 |
| Order items / `(order_id, order_item_id)` | 112,650 | 112,650 | 0 / 0 | 112,649 | 112,649 | 0 / 0 | 112,649 | 112,649 | 0 / 0 |
| Reviews / `review_id` | 99,224 | 98,410 | 789 / 814 | 99,223 | 98,409 | 789 / 814 | 98,409 | 98,409 | 0 / 0 |
| Products / `product_id` | 32,951 | 32,951 | 0 / 0 | 32,950 | 32,950 | 0 / 0 | 32,950 | 32,950 | 0 / 0 |
| Category translations / source `product_category_name` | 71 | 71 | 0 / 0 | 71 | 71 | 0 / 0 | 71 | 71 | 0 / 0 |

Staging distinct counts are derived from the saved row totals and duplicate checks; the staging audits report no blank required key values. Clean keys are distinct by the clean-view outputs and the views' required-key filters / `ROW_NUMBER()` deduplication. The `customer_unique_id` column is not a duplicate `customer_id`: in the raw customer file it has 96,096 distinct values, with 2,997 repeated groups and 3,345 excess rows. 

### Relationship checks

| Relationship | Raw CSV result | Staging / clean evidence | Assessment |
|---|---:|---:|---|
| Orders `customer_id` → customers `customer_id` | 0 unmatched order rows | Staging: 0 (`query17.csv`); clean: 0 (`query23.csv`) | Valid in the checked raw, staging, and clean results. |
| Items `order_id` → orders `order_id` | 0 unmatched item rows | Staging: 1 (`query18.csv`, `query29.csv`); clean: 1 (`query23.csv`, `query29.csv`) | **Unresolved staging discrepancy.** Raw source references all match, but the staged/clean result contains an orphan and the clean view retains it. |
| Items `product_id` → products `product_id` | 0 unmatched item rows | Staging: 1 (`query19.csv`, `query31.csv`); clean: 1 (`query23.csv`, `query31.csv`) | **Unresolved staging discrepancy.** Raw source references all match, but the staged/clean result contains an orphan and the clean view retains it. |
| Reviews `order_id` → orders `order_id` | 0 unmatched review rows | No saved staging or clean review-to-order result; the saved reference checks do not cover this relationship. | Valid in raw only; staging and clean relationship status is **unverified**. |
| Products `product_category_name` → translation source category | 13 product rows in 2 nonblank categories have no translation (`pc_gamer`: 3; `portateis_cozinha_e_preparadores_de_alimentos`: 10); 610 products have blank categories | `02_data_quality_audit.sql` contains a staging category anti-join, but no result export was found. | Raw has 13 unmatched populated category values; missing-category rows are separate. Staging/clean relationship status is **unverified**. |

Raw relationship results were counted by case-sensitive, nonblank key matching after trimming surrounding whitespace across the source CSVs. Staging results are the saved SQL results noted above. In particular, the raw item references do not reproduce the two staging orphans; the one-row raw-to-staging reductions for orders, items, and products could explain a missing staged parent, but without staging row-level data this explanation is not proven. No rows were removed from staging to hide either orphan.

### Count reconciliation and unresolved items

| Dataset | Raw → staging | Staging → clean | Finding |
|---|---:|---:|---|
| Customers | 99,441 → 99,441 | 99,441 → 99,441 | No count change. |
| Orders | 99,441 → 99,440 (**−1**) | 99,440 → 99,440 | One raw row is absent from staging; no row-level load/rejection evidence identifies why. |
| Order items | 112,650 → 112,649 (**−1**) | 112,649 → 112,649 | One raw row is absent from staging; cause unresolved. The staging orphan order/product references also need row-level reconciliation. |
| Reviews | 99,224 → 99,223 (**−1**) | 99,223 → 98,409 (**−814**) | The 814-row clean reduction is exactly the duplicate-key excess (789 groups), consistent with the view's one-row-per-`review_id` rule. The additional raw-to-staging loss of one row remains unexplained. |
| Products | 32,951 → 32,950 (**−1**) | 32,950 → 32,950 | One raw row is absent from staging; cause unresolved. |
| Category translations | 71 → 71 | 71 → 71 | No count change. |

The clean-view SQL explains the staging-to-clean behavior: it excludes missing required keys and ranks duplicate business keys, retaining the most complete row with deterministic tie-breaking. The existing key checks show no missing required keys in these staged datasets; the 814 review-row reduction is independently accounted for by review-key deduplication. No evidence explains the four raw-to-staging one-row reductions, so they remain unresolved rather than being attributed to expected filtering. Confirm by comparing source and staged key-level anti-joins and reviewing the original import logs / rejected-row settings.

## Summary

Order IDs are unique in the raw source and staged/clean order data, and every raw and staged order customer reference checked matched a customer row. Review IDs have 789 duplicate groups (814 excess rows), removed as expected in `reviews_clean`. Raw item-to-order and item-to-product references match, while staged and clean checks each retain one orphan for each relationship. Raw review-to-order references match; staging/clean review references were not checked in the saved results. Thirteen raw products use two categories absent from the translation mapping. Four one-row raw-to-staging count differences remain unexplained. Timestamp validation found no missing purchase or estimated-delivery timestamps, no unparseable timestamp values, and no actual delivery before purchase; it flagged carrier chronology exceptions, eight delivered orders missing actual delivery timestamps, six canceled orders with actual-delivery timestamps, and 965 unusually long durations for investigation. Late deliveries and missing timestamps on non-delivered orders are retained as business/status context, not automatically treated as defects. These gaps and all query/source evidence are recorded above; no source records were altered or deleted.
