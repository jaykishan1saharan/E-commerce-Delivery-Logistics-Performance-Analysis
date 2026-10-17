# Cleaning summary

## Scope and method

The 24 CSV outputs in [`data/interim/`](../data/interim/) were reviewed against the profiling and clean-view checks in [`standard_data_cleaning.sql`](../SQL/standard_data_cleaning.sql). The original `*_stage` tables are retained; cleaning is performed in `*_clean` views rather than by updating or deleting imported CSV data.

Run [`cleaning_log_export.sql`](../SQL/cleaning_log_export.sql) in MySQL Workbench after creating the clean views. It returns one result set with issue, affected-row measure, action, reason, counts before and after, and a verification note. Export that result grid as `cleaning_log.csv`. The query re-runs the checks against the current stage tables and clean views, so its counts reflect the database when it is run.

The translation source key is referenced as `translation_stage.product_category_name` (without a BOM), matching the column name available to the SQL query.

## Findings from the saved outputs

| Area | Findings |
|---|---|
| Imported row counts | Customers 99,441; orders 99,440; items 112,649; reviews 99,223; products 32,950; translations 71. These are the observed loaded counts; no expected-row manifest was provided to establish an import failure. |
| Required keys and general missing fields | The saved customer, order, item, review, product, and translation profile outputs report zero missing/blank key or required fields, except review comments, product categories, and product dimensions described below. |
| Customer/order/item/product duplicates | The staged duplicate-key query outputs for customers, orders, items, and products were empty. Their clean outputs also showed no duplicate customer IDs, order IDs, or order-item keys. |
| Review comments | The audit reported 87,657 missing/blank comment titles and 58,255 missing/blank comment messages. These are optional fields: blank strings are represented as `NULL`; missing comments are retained and are not fabricated. |
| Product categories | The profile reported 610 missing/blank product category values. Blank values become `NULL`; unknown categories are retained as unknown rather than guessed. |
| Product dimensions | The output reported 2 length, 2 height, 2 width, and 6 weight values as `NULL` or nonpositive. These are field counts, can overlap on a product row, and do not distinguish an existing `NULL` from a nonpositive number. Clean views retain missing values as `NULL` and convert nonpositive numbers to `NULL`. |
| Review IDs | There were 789 duplicated review IDs: 764 IDs appeared twice and 25 appeared three times. That represents 814 excess rows beyond one per ID. Review rows went from 99,223 in `reviews_stage` to 98,409 in `reviews_clean`, a reduction of exactly 814, consistent with deduplication. |
| Review scores | All 99,223 scores were in the valid range: 1 = 11,424; 2 = 3,151; 3 = 8,179; 4 = 19,141; 5 = 57,328. The invalid-score result was empty. |
| Item amounts | No negative prices or freight amounts were reported. There were 383 zero-freight rows; zero freight can be legitimate, so the clean view retains it. |
| Order chronology | 166 orders were flagged because carrier delivery was earlier than purchase (165 delivered and 1 shipped). The other tested timestamp-order conditions did not account for these rows. No timestamp correction was inferred; the records are retained for source/time-zone review. |
| Relationships | No orders referenced an unknown customer. One item referenced an unknown order, and one referenced an unknown product. These are retained for investigation rather than deleted or assigned a guessed reference. |
| Clean-view row counts | Customers 99,441; orders 99,440; items 112,649; reviews 98,409; products 32,950; translations 71. The only observed row-count reduction was 814 duplicate review rows. |

## Verification and follow-up

The saved post-clean outputs confirm the clean row counts above and show no duplicate customer IDs, order IDs, or `(order_id, order_item_id)` keys in the corresponding clean views. The review count reduction matches the duplicate excess-row count exactly. Review scores and item amount checks showed no invalid values, and zero-freight rows were preserved.

The timestamp anomalies and two orphan item references are **not resolved** by the cleaning views. This is intentional: there is no reliable value to substitute, and deleting those rows could discard valid transaction data. The export query re-runs these checks and reports their current before/after counts. A nonzero after count is marked for review, not as a successful correction.

The dimension counts in the saved profile combine `NULL` and nonpositive values, so they cannot prove how many numeric values were changed. The export query separates actual nonpositive numbers from existing `NULL`s and verifies that no nonpositive dimension remains in `products_clean`. Missing optional comments, categories, or dimensions are expected to remain missing; the query reports these separately rather than counting them as failed validation.

## Exporting `cleaning_log.csv`

1. Run [`standard_data_cleaning.sql`](../SQL/standard_data_cleaning.sql) in MySQL Workbench to create or refresh the clean views.
2. Run [`cleaning_log_export.sql`](../SQL/cleaning_log_export.sql) and wait for its single result set.
3. In the result grid, choose **Export recordset** (or the Workbench CSV export option) and save the result as `data/interim/cleaning_log.csv`.
4. Review rows marked `REVIEW_REQUIRED` and retain the CSV alongside the analysis outputs.

The saved SQL outputs are a snapshot. Run the export query to produce the authoritative `cleaning_log.csv` from the current database state; this report does not claim that a CSV was generated from a live database session.