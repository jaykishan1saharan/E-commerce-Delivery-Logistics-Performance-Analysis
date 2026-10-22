# Day 1 Data Validation Summary

- Raw orders CSV rows: 99,441
- Unique order IDs: 99,441
- Blank order IDs: 0
- KPI dataset rows: 99,441
- Delivered orders: 96,478
- On-time eligible orders: 96,470
- On-time deliveries: 89,936
- On-time rate: 93.23%
- Cancelled orders: 625
- Average delivery duration: 12.56 days

## Validation tests
- Missing required column: rejected
- Missing order ID: rejected

## Execution status
- `python run_analysis.py` completed successfully.
- Source used: CSV workflow.

## Raw-to-KPI reconciliation
- Raw and KPI rows: 99,441 each
- Unique order IDs: 99,441 in each dataset
- Raw IDs missing from KPI: 0
- KPI IDs missing from raw: 0
- Order-status counts: match

## SQL/Python reconciliation status
- Pending: SQL staging tables and comparable SQL KPI results have not been validated. SQL/Python KPI reconciliation is not yet confirmed.
