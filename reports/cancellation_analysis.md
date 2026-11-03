# Cancellation Analysis

> **Status:** Outline and source-data inspection. Validate SQL outputs against
> the imported database before treating the findings as final.

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
- The current source has a unique `order_id` on every order row, so the
  denominator equals the order-row count. Recheck uniqueness and missing IDs
  in the imported database before publication.

## 3. Source inspection — preliminary

- 99,441 order rows and 99,441 distinct order IDs.
- Status counts: delivered 96,478; shipped 1,107; canceled 625; unavailable
  609; invoiced 314; processing 301; created 5; approved 2.
- Preliminary cancellation rate: **0.63%** (625 / 99,441).
- `unavailable` is not counted as canceled; do not combine the two statuses.
- 2,957 non-delivered orders have no customer-delivery timestamp, which is
  expected for undelivered statuses. Eight delivered orders lack that date.
  Six canceled orders do have a delivery timestamp; investigate these
  status/date exceptions rather than reclassifying them.

## 4. Analysis and reporting outline

1. Validate source row count, distinct/missing order IDs, and status values.
2. Present status counts and share of the all-orders denominator.
3. Report canceled count, denominator, cancellation rate, and the exact status
   rule.
4. Optionally break the cancellation rate down by purchase period or other
   approved segments, retaining the same all-orders denominator within each
   segment.
5. Summarize anomalies, exclusions, and limitations; do not infer causes from
   descriptive status rates.

## 5. Data gaps and validation before sign-off

- Confirm whether the loaded clean view has removed duplicate or blank IDs;
  document exclusions if present.
- Inspect the six canceled orders with delivery timestamps and the 609
  `unavailable` orders separately.
- Confirm that reporting uses `canceled` exactly (one `l` in the source value)
  and does not silently remap status categories.
- Add final SQL execution date, database row counts, validated rate, and any
  segment results here.
