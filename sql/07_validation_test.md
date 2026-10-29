# Baseline Data Quality Validation Test

**Database:** `ecommerce_delivery` (MySQL)  
**Table:** `olist_orders_dataset`

## Validation Results

| Check | Actual Result | Status |
|---|---:|---|
| Total order rows | 99,441 | PASS |
| Unique order IDs | 99,441 | PASS |
| Duplicate order IDs | 0 | PASS |
| Missing order IDs | 0 | PASS |
| Missing purchase timestamps | 0 | PASS |
| Delivered orders missing delivery dates | 0 | PASS |
| Order status distribution total | 99,441 | PASS |

## Order Status Distribution

| Order Status | Count |
|---|---:|
| delivered | 96,478 |
| shipped | 1,107 |
| canceled | 625 |
| unavailable | 609 |
| invoiced | 314 |
| processing | 301 |
| created | 5 |
| approved | 2 |
| **Total** | **99,441** |

## Conclusion

All listed baseline validation checks passed based on the MySQL query results obtained.

The checks cover row counts, order ID uniqueness, missing key fields, and order status distribution.