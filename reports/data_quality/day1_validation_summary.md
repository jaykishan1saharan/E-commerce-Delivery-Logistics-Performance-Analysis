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

## Dataset row-count baseline

| Dataset | Raw CSV file | Staging table | Raw rows | Staging rows | Clean view | Clean rows |
|---|---|---|---:|---:|---|---:|
| Customers | `olist_customers_dataset.csv` | `customers_stage` | 99,441 | 99,441 | `customers_clean` | 99,441 |
| Orders | `olist_orders_dataset.csv` | `orders_stage` | 99,441 | 99,441 | `orders_clean` | 99,441 |
| Order items | `olist_order_items_dataset.csv` | `items_stage` | 112,650 | 112,650 | `items_clean` | 112,650 |
| Reviews | `olist_order_reviews_dataset.csv` | `reviews_stage` | 99,224 | 99,224 | `reviews_clean` | 98,410 |
| Products | `olist_products_dataset.csv` | `products_stage` | 32,951 | 32,951 | `products_clean` | 32,951 |
| Category translations | `product_category_name_translation.csv` | `translation_stage` | 71 | 71 | `translation_clean` | 71 |
| **Total** |  |  | **443,778** | **443,778** |  | **442,964** |

**Count reconciliation:** Raw CSV record counts were verified using `csv.reader` and compared with the current MySQL staging tables and clean views. The reviews clean view removes 814 excess duplicate `review_id` records. Previously saved query exports may reflect an earlier run.


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
| Reviews | Blank or NULL optional title/message | Rows | 87,658 titles; 58,256 messages | Retained; no text imputed | Review text can be optional. | [query5.csv](../../data/interim/query5.csv) |
| Reviews | Invalid score outside 1–5 | Rows | 0 | Checked; none returned | All reported scores are within the valid range. | [query15.csv](../../data/interim/query15.csv) |
| Reviews | Score distribution | Counts by score | 1: 11,424; 2: 3,151; 3: 8,179; 4: 19,142; 5: 57,328 | Recorded distribution | Descriptive check. | [query14.csv](../../data/interim/query14.csv) |
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

## Summary

The saved outputs document raw, staging, and clean-view counts for all six datasets, along with key, duplicate, value, timestamp, and reference checks. The main findings are 814 excess duplicate review rows reflected in the reviews clean-view count, four one-row raw-to-staging count differences, 166 carrier-before-purchase cases, 23 deliveries before carrier handover, and two orphan item references. The unmatched references and chronology findings are recorded for investigation; no source records were altered or deleted.
