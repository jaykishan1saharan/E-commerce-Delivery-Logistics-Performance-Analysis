# Dashboard Metric Definitions and Caveats

These definitions describe the time trends on the Week 3 delivery dashboard. They follow the eligibility rules in [`kpi_definitions.md`](kpi_definitions.md); the imported CSV snapshot and its implementation remain provisional pending source and KPI validation.

## Time-trend visuals

| Visual | Definition | Population |
|---|---|---|
| **Unique order volume by purchase month** | Distinct count of `order_id`, grouped by the `yyyy-MM` month derived from `order_purchase_timestamp`. | All source order statuses. Orders without a usable purchase timestamp cannot be assigned to a month. |
| **Average reported delivery days by purchase month (provisional)** | Average of exported `delivery_days`, grouped by purchase month. | Delivered orders with a non-null, non-negative `delivery_days` value, as implemented by `Average Delivery Days (Provisional)`. |

## Caveats

- The report uses the imported `data/interim/kpi_orders_all.csv` snapshot. Its schema and status as the canonical input are not signed off. Validation evidence reports 99,441 unique orders in one snapshot and 99,440 rows in another; resolve this discrepancy before treating monthly counts as reconciled.
- The delivery-duration trend is based on the exported `delivery_days` field. The dashboard does not independently recompute elapsed time from source timestamps or validate the field’s duration implementation. Treat the trend as provisional, not as a confirmed delivery-service KPI.
- Delivery duration is conditioned on an order being delivered and having a valid, non-negative exported duration. Undelivered orders and missing or negative durations do not contribute. Recent purchase-month cohorts may therefore have fewer eligible deliveries and can change as more orders are delivered; do not compare them as if they were complete.
- The existing `is_on_time` export has not been validated against the agreed calendar-date rule. No on-time-rate trend is shown. If added after validation, its denominator must include only delivered orders with valid actual and estimated delivery dates, and excluded/missing-date counts should be reported.
- Grouping is by purchase month, not delivery month. The duration chart describes outcomes for purchase cohorts; it is not a count of deliveries completed in each month.
- `unavailable` is a distinct source status, not a cancellation. Order-volume counts include each status; cancellation-rate definitions and denominators are documented separately in [`kpi_definitions.md`](kpi_definitions.md).

Before publishing these metrics as final, confirm the canonical source, timestamp and flag semantics, unique-order grain, missing/invalid-value handling, and consistency with the KPI contract.
