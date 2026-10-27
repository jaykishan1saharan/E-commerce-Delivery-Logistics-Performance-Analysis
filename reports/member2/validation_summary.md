## Day 2 — Join Grain and Segment Validation

### Join validation
- Orders: 99,441 unique order IDs.
- Order items: 112,650 rows and 112,650 unique `(order_id, order_item_id)` pairs.
- Orders-to-items LEFT JOIN: 113,425 rows, retaining all 99,441 orders and all 112,650 order-item rows.
- Unmatched orders: 775.

### Segment denominator validation
- Verified that total order counts match distinct order IDs for every order-status segment.
- Validation: PASS.

### Small-sample validation
- Proposed threshold: `n < 30` (pending team agreement).
- `approved`: n = 2, small-sample flag = 1.
- `created`: n = 5, small-sample flag = 1.
- All other order-status segments: flag = 0.

### Status
- SQL validation completed.
- Small-sample threshold pending team agreement.