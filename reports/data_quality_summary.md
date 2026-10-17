# Data Quality Audit Summary

**Project:** E-commerce Delivery & Logistics Performance Analysis  
**Database:** `ecommerce_delivery` (MySQL)  
**Audit tables:** six imported `*_stage` tables  
**Approach:** read-only SQL checks; no records were modified or deleted.

## 1. Import row-count validation

All six staging tables match the expected source row counts.

| Staging table | Actual rows | Expected rows | Status |
|---|---:|---:|---|
| `customers_stage` | 99,441 | 99,441 | Pass |
| `items_stage` | 112,650 | 112,650 | Pass |
| `orders_stage` | 99,441 | 99,441 | Pass |
| `reviews_stage` | 99,224 | 99,224 | Pass |
| `products_stage` | 32,951 | 32,951 | Pass |
| `translation_stage` | 71 | 71 | Pass |
| **Total** | **443,778** | **443,778** | **Pass** |

## 2. Referential integrity

The three executed checks returned zero unmatched references:

- Orders with unknown customers: **0**
- Items with unknown orders: **0**
- Items with unknown products: **0**

These results indicate no unmatched references were found by these specific checks.

## 3. Findings requiring review

- `products_stage`: **610** products have a blank category value.
- Product dimensions: the checks for NULL or non-positive values returned **2** for length, **2** for height, **2** for width, and **6** for weight. These counts combine NULL and non-positive values; they are not counts of negative values alone.
- Negative product dimensions: **0** negative length, **0** negative height, **0** negative width, and **0** negative weight values.
- Review title is blank/NULL for **87,658** rows and review message is blank/NULL for **58,256** rows. Review text can be optional, so these are informational rather than automatic errors.
- Invalid review scores outside the 1–5 range: **0**.
- Translation fields: the corrected audit query against the actual BOM-prefixed source-category column returned zero missing/blank values.

## 4. Notes and limitations

- The first column in `translation_stage` was imported with a UTF-8 BOM prefix in its column name. The audit query uses the actual name shown by `DESCRIBE`; a future clean schema could rename it after team approval.
- Duplicate-ID and duplicate-key queries are included in the SQL audit script. Their full results should be reviewed before describing duplicates as confirmed defects.
- This report records verified results from the executed checks. Checks not explicitly shown as executed should be treated as pending.
- No records were cleaned, changed, or deleted. Any remediation should be discussed with the team first.

## 5. Files

- `03_data_quality_audit.sql` — read-only audit queries.
- `data_quality_report.csv` — check-level results and notes.
- `data_quality_summary.md` — this is summary file.
