# KPI Reconciliation Record

**Review date:** 05 November 2026
**Owner:** Member 5 — Lav Kumar
**Status:** LATE-DELIVERY KPI RECONCILED FROM ORIGINAL SOURCE CSV. Interim export flags still require regeneration.

## Canonical source check
The original `data/raw/olist_orders_dataset.csv` was independently re-read and the KPI recomputed using the documented calendar-date rule:
- Filter `order_status = 'delivered'`.
- Require non-null actual customer-delivery date and estimated-delivery date.
- Late if `DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)`.
- On time/early if actual calendar date is less than or equal to estimated calendar date.

## Approved late-delivery KPI
| Measure | Validated value |
|---|---:|
| Total unique orders | 99,441 |
| Delivered-status orders | 96,478 |
| Eligible delivered orders (both dates present) | 96,470 |
| Missing actual delivery dates among delivered orders | 8 |
| Missing estimated delivery dates among delivered orders | 0 |
| Late delivered orders | 6,534 |
| On-time/early delivered orders | 89,936 |
| Late-delivery rate | 6.77% |
| On-time/early rate | 93.23% |

Validation identity: **6,534 + 89,936 = 96,470**.

The saved MySQL KPI validation output reports the same counts. The independent raw CSV recomputation reproduces them, so 6,534 and 6.77% are the approved source-based result for this snapshot.

## Conflicting interim export values
| Source | Late count | Interpretation |
|---|---:|---|
| MySQL validation output | 6,534 | Matches independent raw-source recomputation |
| Raw CSV recomputation | 6,534 | Canonical approved result |
| `kpi_orders.csv`, `is_on_time = 0` | 7,826 | Incorrect/inconsistent flag in saved export |
| `kpi_orders.csv`, `delay_days > 0` | 7,820 | Inconsistent with documented calendar-date KPI |
| Earlier `reports/interim_findings.md` | 7,826 | Superseded preliminary figure |

**Required correction:** regenerate `kpi_orders.csv` so `is_on_time` and `delay_days` follow the same documented rule and match the canonical source calculation. Do not use the stale flags in the dashboard.

## Other consistency checks
- `kpi_orders.csv`: 96,470 rows and 96,470 distinct order IDs.
- `kpi_orders_all.csv`: 99,441 rows and 99,441 distinct order IDs.
- Status summary delivered count (96,478) differs from eligible delivered rows (96,470) by eight; all eight delivered orders have missing actual customer-delivery dates.
- Review distribution table and clean review view are different saved outputs/grains. Reconcile review population before final review-score cards are signed off.

## Sign-off
Late-delivery KPI: **validated for this raw-data snapshot**.
Interim export correction: **pending**.
Review distribution reconciliation: **pending**.
Dashboard DAX comparison: **pending**.
