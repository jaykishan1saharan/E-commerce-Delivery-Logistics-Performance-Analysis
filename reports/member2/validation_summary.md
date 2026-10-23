# Friday Validation Summary

## Dataset Integrity
- **Source:** `data\interim\kpi_orders.csv`
- Total rows: 99,441
- Unique order IDs: 99,441
- Duplicate order IDs: 0
- Missing order IDs: 0
- One row per order: **PASS**

## Delivery KPI Checks
- Delivered orders: 96,478
- Cancelled orders: 625
- Eligible delivered orders: 96,470
- Late deliveries by calendar-date rule: 6,534
- Late deliveries by existing flags: 6,534
- On-time or early deliveries: 89,936
- Late-delivery validation: **PASS** — both methods agree.

## Timestamp Validation
- All five timestamp columns checked.
- Invalid nonblank timestamps: 0 across all checked columns.
- Missing timestamps are documented in `timestamp_validation.csv`.

## Missing Values
- `order_approved_at`: 160
- `order_delivered_carrier_date`: 1,783
- `order_delivered_customer_date`: 2,965
- `approval_days`: 160
- `carrier_handoff_days`: 1,797
- `delivery_days`: 2,965

## Outstanding Items
- SQL-versus-Python KPI comparison is pending verified SQL query results.
- Compare SQL and Python using identical definitions, filters, and date rules.
- Do not mark SQL comparison as passed until the results are verified.

## Reports Generated
- `python_kpi_results.csv`
- `timestamp_validation.csv`
- `sql_python_kpi_comparison.csv`
- `validation_summary.md`

## Reproduction
1. Run `python run_analysis.py`
2. Run `python validate_friday.py`
