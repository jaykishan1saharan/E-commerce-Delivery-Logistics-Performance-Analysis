# Friday Validation Summary

## Dataset integrity
- Source: `data\interim\kpi_orders.csv`
- Rows: 99441
- Unique order IDs: 99441
- Duplicate order IDs: 0
- Missing order IDs: 0
- One row per order: PASS

## Delivery KPI checks
- Delivered orders: 96478
- Cancelled orders: 625
- Late by calendar-date rule: 6534
- Late by existing flags: 6534
- Eligible delivered orders: 96470

## Missing values
- `order_approved_at`: 160
- `order_delivered_carrier_date`: 1783
- `order_delivered_customer_date`: 2965
- `approval_days`: 160
- `carrier_handoff_days`: 1797
- `delivery_days`: 2965

## Outstanding items
- Review the timestamp_validation.csv output.
- Reconcile date-based late counts with existing flags.
- Populate SQL values only from verified SQL query results.
- Compare SQL and Python using identical definitions and filters.

## Reproduction
- Run `python run_analysis.py`
- Run `python validate_friday.py`
