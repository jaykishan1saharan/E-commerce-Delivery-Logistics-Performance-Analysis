# Cancellation Analysis

> **Status:** Candidate findings reproduced from the checked-in raw CSVs.
>

## 1. Objective and scope

- Describe order-status mix and the observed cancellation rate.
- Source: `orders_stage` / `orders_clean`; analytical grain: one unique order.
- Treat the source status `canceled` as the cancellation label. Keep
  `unavailable` and non-final statuses separate.

## 2. Metric definition

- **Numerator:** distinct orders with `order_status = 'canceled'`.
- **Denominator:** all unique orders with a usable `order_id`, across every
  recorded status, including `unavailable`, `shipped`, `processing`, and other
  non-final statuses.
- **Cancellation rate:** `canceled orders / all unique orders * 100`.
- All 99,441 raw order rows have a nonblank unique `order_id`; thus the
  denominator equals the source row count. The SQL includes a separate
  population check for `orders_clean`.

## 3. Validated source-file findings

- 99,441 order rows and 99,441 distinct order IDs.
- Status counts: delivered 96,478; shipped 1,107; canceled 625; unavailable
  609; invoiced 314; processing 301; created 5; approved 2.
- Cancellation rate: **0.63%** (625 / 99,441 unique orders).
- `unavailable` is not counted as canceled; do not combine the two statuses.
- 2,957 non-delivered orders have no customer-delivery timestamp, which is
  expected for undelivered statuses. Eight delivered orders lack that date.
  Six canceled orders do have a delivery timestamp; investigate these
  status/date exceptions rather than reclassifying them.
- Customer-state summaries retain the all-order denominator within each
  state. São Paulo has the largest cancellation count (327 / 41,746; 0.78%).
  Roraima has the highest observed state rate (1 / 46; 2.17%), which is a
  small denominator and should not be treated as a stable ranking.
- The candidate export is
  [`data/exports/week4_cancellation_analysis.csv`](../data/exports/week4_cancellation_analysis.csv).

## 4. Reporting method and limitations

- Raw-file checks found 99,441 rows, 99,441 distinct nonmissing order IDs,
  and eight distinct source statuses. The 625 canceled orders are divided by
  all 99,441 unique orders (including the 609 `unavailable` and all
  non-final statuses), not just delivered orders. Candidate export status and
  state totals reconcile to 99,441.
- State comparisons are descriptive and include denominator counts. Small
  state samples can produce volatile rates.
- The all-period cancellation rate is a descriptive baseline, not a
  target-period estimate. Follow-up comparisons should use matching purchase
  cohorts and the same all-status denominator rule.
- Inspect the six canceled orders with delivery timestamps and the 609
  `unavailable` orders separately. Do not reclassify either group based on
  timestamp anomalies.
