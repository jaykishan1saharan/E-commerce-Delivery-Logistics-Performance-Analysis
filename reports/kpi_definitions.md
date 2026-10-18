# KPI Definitions

**Project:** E-commerce Delivery & Logistics Performance Analysis (Olist)
**Phase:** Week 2, KPI Engineering & Delay Pattern Analysis
**Owner:** Yashashvi Yash (Project Lead)
**Status:** Frozen on Day 1. Any change needs the lead's approval.

All KPIs are calculated from the master views in `sql/06_create_kpi_views.sql`:

| View | Contents | Used for |
|---|---|---|
| `kpi_orders_all` | All orders, one row per order (99,441) | Cancellation rate |
| `kpi_orders` | Delivered orders with valid dates (96,470) | All delay, duration and rating KPIs |

---

## 1. KPI Definitions

| KPI | Plain-English meaning | Formula | Column | Population |
|---|---|---|---|---|
| Delivery duration | Days from purchase to arrival at the customer | `delivered_customer_date - purchase_timestamp` | `delivery_days` | `kpi_orders` |
| Delay | Days between actual and promised delivery. Positive = late, negative = early | `delivered_customer_date - estimated_delivery_date` | `delay_days` | `kpi_orders` |
| On-time rate | Share of delivered orders that arrived on or before the promised date | `COUNT(is_on_time = 1) / COUNT(delivered orders)` | `is_on_time` | `kpi_orders` |
| Cancellation rate | Share of all orders that were cancelled | `COUNT(order_status = 'canceled') / COUNT(all orders)` | `is_canceled` | `kpi_orders_all` |
| Approval time | Days from purchase to payment approval | `approved_at - purchase_timestamp` | `approval_days` | `kpi_orders` |
| Carrier handling time | Days from approval to handover to the carrier | `delivered_carrier_date - approved_at` | `handling_days` | `kpi_orders` |
| Average rating | Mean review score (1 to 5) | `AVG(review_score)` | `review_score` | `kpi_orders` |
| Low-rating rate | Share of rated orders scoring 1 or 2 | `COUNT(review_score <= 2) / COUNT(rated orders)` | `is_low_rating` | `kpi_orders` |

**Processing time** in the project brief means approval time plus carrier handling time, reported as two separate metrics.

---

## 2. Rules Applied Everywhere

1. **Delay KPIs** use delivered orders with non-null delivery and estimated dates only (`kpi_orders`).
2. **Positive delay means late.** `is_on_time = 1` when delivered date is on or before the estimated date.
3. **One row per order.** Multi-item orders are collapsed (item count, total value, total freight). Order category is the category of the most expensive item.
4. **One review per order.** When an order has several reviews, the most recent one is kept.
5. **Blank values stay blank.** Missing categories, reviews and timestamps are not filled in. They are excluded from the KPI they affect.
6. **Raw data is never modified.** `data/raw/` is read-only.

---

## 3. Segment Rules

| Rule | Value |
|---|---|
| Regions | Five Brazilian regions mapped from `customer_state` (North, Northeast, Central-West, Southeast, South) |
| Weekday | From `order_purchase_timestamp` (Sun to Sat) |
| Category | English name from the translation file, top 15 by order volume |
| Delay buckets | On time or early, 1-3 days late, 4-7 days late, 8+ days late |
| Small sample | Every table shows `order_count`. Segments with n < 30 are flagged `small_sample = 1` |

---

## 4. Baseline Values (Overall)

Measured on the full dataset to give the team a reference. Segment results should be compared against these.

| KPI | Value |
|---|---|
| Orders in dataset | 99,441 |
| Delivered orders with valid dates | 96,470 |
| On-time rate | 91.89% |
| Late orders | 7,820 |
| Cancellation rate | 0.63% |
| Average delivery duration | 12.56 days |
| Average delay | -11.18 days (orders arrive about 11 days early on average) |
| Average approval time | 0.43 days |
| Average carrier handling time | 2.80 days |
| Average rating | 4.16 |
| Low-rating rate (1 or 2 stars) | 12.81% |
| Delivered orders with a review | 95,824 |

---

## 5. Known Limitations

- **No carrier field** exists in the data, so carrier comparison is not possible.
- **Distance bands** need the sellers and geolocation files, which are not included.
- **Estimated delivery dates** are set by the platform, so a high on-time rate partly reflects generous estimates.
- **Ratings and lateness** can only show association. They do not show that lateness causes low ratings.
- Some orders have no category or review score and are excluded from those specific KPIs.

---

## 6. Change Log

| Date | Change | Approved by |
|---|---|---|
| Day 1 | Initial definitions frozen | Yashashvi Yash |