# Validation and Sensitivity Report

## 1. Scope and method

- Source: `data/interim/kpi_orders.csv`
- Baseline includes every source row.
- Sensitivity population excludes rows flagged for missing key fields,
  duplicate order IDs, malformed nonblank timestamps, or negative
  numeric duration values.
- A missing timestamp alone is not automatically treated as invalid;
  it may be legitimate for a cancelled or incomplete order.
- Duplicate IDs are flagged on every occurrence, not just later rows.

## 2. Record-quality checks

- Source rows: **99,441**
- Rows with at least one quality flag: **1,359**
- Rows retained after exclusion: **98,082**

| Quality check | Flagged records |
|---|---:|
| `missing_order_id` | 0 |
| `missing_customer_id` | 0 |
| `missing_order_status` | 0 |
| `duplicate_order_id` | 0 |
| `invalid_order_purchase_timestamp` | 0 |
| `invalid_order_delivered_carrier_date` | 0 |
| `invalid_order_delivered_customer_date` | 0 |
| `invalid_order_estimated_delivery_date` | 0 |
| `negative_approval_days` | 0 |
| `negative_carrier_handoff_days` | 1,359 |
| `negative_delivery_days` | 0 |

Counts by check can overlap; do not sum them to obtain unique flagged rows.

## 3. KPI sensitivity comparison

| Metric | All source rows | Excluding flagged rows | Change |
|---|---:|---:|---:|
| total_orders | 99,441 | 98,082 | -1,359 |
| delivered | 96,478 | 95,128 | -1,350 |
| cancelled | 625 | 625 | +0 |
| eligible_delivered | 96,470 | 95,120 | -1,350 |
| on_time | 89,936 | 88,610 | -1,326 |
| late | 6,534 | 6,510 | -24 |
| on_time_rate_pct | 93.23% | 93.16% | -0.07000000000000739% |
| late_rate_pct | 6.77% | 6.84% | +0.07000000000000028% |

## 4. Reconciliation against established baseline

| Metric | Expected baseline | Recomputed | Result |
|---|---:|---:|---|
| total_orders | 99,441 | 99,441 | PASS |
| delivered | 96,478 | 96,478 | PASS |
| cancelled | 625 | 625 | PASS |
| eligible_delivered | 96,470 | 96,470 | PASS |
| late | 6,534 | 6,534 | PASS |
| on_time | 89,936 | 89,936 | PASS |

The expected values are the previously recorded project validation totals.
A CHECK means the source file or KPI definitions need investigation; it
must not be silently adjusted to force a match.

## 5. Interpretation and limitations

- Compare the all-row KPIs with the filtered KPIs before deciding whether
  flagged records materially affect the conclusions.
- Quality flags can overlap, so the unique excluded-row count is reported
  separately from individual check counts.
- If `on_time_eligible` or `on_time` is absent, the report uses available
  delivery dates when possible; unavailable metrics may not reconcile.
- SQL parity must be confirmed against the latest SQL validation output.
  Python-only flags are not evidence that the same flags exist in SQL.
- Review every CHECK and investigate differences before sign-off.
**Investigation finding:** The 1,359 records flagged for negative `carrier_handoff_days` have carrier delivery timestamps earlier than their approval timestamps. This is a timestamp-order inconsistency in the source data, not proof that the records themselves are invalid. The original records are preserved, and the filtered KPI results are presented only as a sensitivity analysis. Investigate the upstream timestamp and duration-generation logic before deciding whether to exclude these records from official reporting.

## 6. Conclusion

- **1,359** records are flagged for sensitivity analysis.
- **98,082** records remain in the filtered population.
- Use the sensitivity table to document whether KPI conclusions change.
- Complete final SQL comparison and reviewer sign-off after investigating
  any baseline mismatch.
