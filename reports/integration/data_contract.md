# Shared Data Contract — Logistics Analysis

**Owner:** Lav Kumar (Member 5)
**Status:** Draft — Pending team confirmation
**Last updated:** 21 October 2026

## 1. Canonical Data Source

**Status: Pending confirmation from Yashashvi and Meghana.**

Candidate sources:
- `data/interim/kpi_orders.csv`
- `data/interim/kpi_orders_all.csv`
- The agreed SQL clean views or analytical query output.

Meghana reports that her analysis uses `data/interim/kpi_orders.csv`.
The final source must be agreed with Yashashvi before integration is
considered complete.

A discrepancy remains between reported datasets:
- Earlier validation: `kpi_orders.csv` — 96,470 rows and 19 columns.
- Meghana's update: `kpi_orders.csv` — 99,441 rows and 15 columns.
- Earlier validation: `kpi_orders_all.csv` — 99,441 rows and 19 columns.
- Madhu's validation report records 99,440 orders in its staging/clean-view checks.

**Pending:** Confirm the exact file, branch/commit, schema, and reason
for the different row and column counts. Do not silently alter counts.

## 2. Analytical Grain and Key

- Required grain: one row per `order_id`.
- Candidate key: `order_id`.
- Order IDs must be non-null and unique.
- Validate the final dataset after all joins and aggregations.

**Pending:** Revalidate these conditions against the agreed canonical input.

## 3. Candidate Columns and Types

The following 19 columns were reported in an earlier KPI CSV validation.
They are not yet confirmed as the schema of Meghana's current 15-column
dataset.

| Column | Proposed type |
|---|---|
| `order_id` | String |
| `order_status` | String |
| `customer_state` | String |
| `region` | String |
| `order_purchase_timestamp` | Datetime |
| `weekday_num` | Integer |
| `weekday` | String |
| `category` | String |
| `n_items` | Integer |
| `order_value` | Numeric/decimal |
| `freight_total` | Numeric/decimal |
| `review_score` | Numeric; nullable |
| `approval_days` | Numeric; nullable |
| `handling_days` | Numeric; nullable |
| `delivery_days` | Numeric; nullable |
| `delay_days` | Numeric; nullable |
| `is_on_time` | Boolean/integer flag |
| `is_canceled` | Boolean/integer flag |
| `is_low_rating` | Boolean/integer flag |

**Pending:** Confirm the exact column list, SQL types, nullability,
timestamp formats, and flag encodings for the canonical dataset.

## 4. Date and KPI Conventions

Use `reports/kpi_definitions.md` as the business reference.

- On-time and late delivery use calendar-date comparison.
- Missing or invalid actual/estimated delivery dates are unknown and
  excluded from the eligible on-time/late denominator.
- Undelivered orders are excluded from delivery timeliness rates.
- Delivery duration uses elapsed time between full timestamps.
- Negative durations must be flagged and investigated.
- Cancellation rates use the agreed eligible unique-order population.
- Review records must be aggregated according to the agreed definition
  before joining to order-level data.
- SQL and Python must use the same eligibility and exclusion rules.

**Pending:** Verify implementation consistency and confirm any additional
KPI definitions with the team.

## 5. Input and Output Paths

### Candidate inputs
- `data/interim/kpi_orders.csv`
- `data/interim/kpi_orders_all.csv`
- SQL clean views or analytical query output — exact interface pending.
- Raw source files are under `data/raw/`.

### Candidate outputs
- Existing KPI exports: `data/interim/`
- Python analysis outputs: confirm with Meghana.
- Validation evidence: `reports/data_quality/` and PR #8 files.

**Pending:** Confirm canonical input, output paths, and tested execution
commands.

## 6. Team Responsibilities

- Yashashvi (Member 1): confirm SQL schema, clean views, and canonical output.
- Meghana (Member 2): confirm Python input, loader tests, and output paths.
- Jaykishan (Member 3): maintain KPI definitions and clarify remaining rules.
- Madhu (Member 4): maintain validation evidence and investigate anomalies.
- Lav Kumar (Member 5): coordinate integration and maintain documentation.

## 7. Outstanding Checks

- [ ] Canonical source and schema agreed.
- [ ] Row-count and column-count discrepancies explained.
- [ ] One row per `order_id` verified on the agreed input.
- [ ] Loader missing-ID and missing-column rejection tests confirmed.
- [ ] SQL/Python KPI consistency verified.
- [ ] Join-grain and timestamp checks evidenced.
- [ ] Data-quality anomalies resolved or kept explicitly flagged.
- [ ] End-to-end workflow tested.
- [ ] README updated to match the tested workflow.

**Overall status:** In progress. Unconfirmed items remain Pending.
