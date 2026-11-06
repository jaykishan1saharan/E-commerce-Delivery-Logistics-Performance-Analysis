# Week 4 Operational Improvement Report

**Status:** Candidate report based on the checked-in raw Olist CSVs. The
counts, joins, and calculations below were independently reproduced from
those files. Execute [`sql/10_cancellation_rating_analysis.sql`](../sql/10_cancellation_rating_analysis.sql)
against the approved MySQL snapshot before external publication.

## Executive summary

- **Cancellations:** 625 of 99,441 unique orders were `canceled` (**0.63%**).
  The denominator includes every status; `unavailable` (609 orders) remains
  separate. The cancellation export's status and state rows reconcile to the
  same 99,441-order population.
- **Review linkage:** 99,224 review rows link to 98,673 orders; 768 orders have
  no review row. There are no missing/orphan order links or duplicate
  `(order_id, review_id)` pairs. The 789 review IDs reused across multiple
  orders require joining on `order_id`, not `review_id`.
- **Delivery-linked ratings:** Of 96,478 delivered orders, 96,470 have both
  actual and estimated dates. Calendar-date grouping yields 89,936 on-time
  and 6,534 delayed eligible orders. The mean per-order score is **4.2906**
  (89,443 rated orders) on time and **2.2718** (6,381 rated orders) delayed.
  The difference is descriptive; it does not prove delay caused lower
  ratings.

## Validated measures and sample sizes

| Measure | Numerator / sample | Denominator | Result |
|---|---:|---:|---:|
| Overall cancellation rate | 625 canceled unique orders | 99,441 unique orders, all statuses | 0.63% |
| São Paulo cancellation rate | 327 canceled unique orders | 41,746 unique orders | 0.78% |
| Roraima cancellation rate | 1 canceled unique order | 46 unique orders | 2.17% |
| Orders with a linked review | 98,673 orders | 99,441 unique orders | 99.23% |
| On-time valid-rating coverage | 89,443 rated orders | 89,936 eligible orders | 99.45% |
| Delayed valid-rating coverage | 6,381 rated orders | 6,534 eligible orders | 97.66% |
| On-time mean order-level score | 89,443 rated orders | Mean over per-order averages | 4.2906 / 5 |
| Delayed mean order-level score | 6,381 rated orders | Mean over per-order averages | 2.2718 / 5 |
| On-time one-star records | 5,961 review records | 89,944 valid linked review records | 6.63% |
| Delayed one-star records | 3,444 review records | 6,409 valid linked review records | 53.74% |

Review-score distributions count review records; means and coverage count
orders. The one-star shares above must not be interpreted as the percentage
of orders with a one-star rating because a multi-review order can contribute
more than one record. The raw source contains 547 orders with multiple review
rows. All delivered orders without valid ratings remain in eligible-group
denominators and are reported as unrated: 493 on time and 153 delayed.

## Operational actions and follow-up KPIs

| Priority / action | Evidence and scope | Follow-up KPI (definition and baseline) | Proposed follow-up / decision rule |
|---|---|---|---|
| **1. Pilot proactive recovery for at-risk deliveries.** Select an at-risk cohort using an operationally approved trigger, notify affected customers before the promised date is missed, and retain a comparable usual-process group where feasible. | 6,534 delayed eligible deliveries; delayed rated-order mean 2.2718 / 5 (n=6,381) versus on-time 4.2906 / 5 (n=89,443). The observed gap is a diagnostic signal, not causal evidence. | **Primary:** mean per-order valid score among delivered, date-eligible orders in each pilot arm; baseline delayed cohort 2.2718 / 5 (n=6,381). **Secondary:** late-delivery rate = delayed / delivered with both dates; source baseline 6,534 / 96,470 = 6.77%. **Execution:** qualifying at-risk orders contacted before promise breach / all qualifying at-risk orders. | Pre-register the trigger, cohorts, period, and a minimum sample based on a power calculation. Proposed pilot service threshold: contact at least 95% of qualifying at-risk orders before the promise date. Compare mature cohorts and report group sizes, rating coverage, mean score, and late rate; do not attribute change to the pilot without a suitable comparison. |
| **2. Add structured cancellation-reason capture and investigate high-volume segments.** Record a standardized reason for every future cancellation; review São Paulo first as a volume-led audit, not a presumed cause. | São Paulo has 327 of 625 cancellations and a 0.78% rate (41,746-order denominator); Roraima's 2.17% is only 1 / 46 and is too small to rank as stable performance. No cancellation reason is present in the current analysis. | **Reason completeness:** canceled orders with a standardized reason (or explicit `unknown`) / all canceled orders. **Baseline:** unavailable in current source. **Cancellation rate:** canceled unique orders / all unique orders in the same purchase cohort; all-status denominator. Current cumulative baseline 625 / 99,441 = 0.63%; São Paulo 327 / 41,746 = 0.78%. | Set a process target of 100% reason-field completion for new cancellations, reviewed weekly. After at least one complete, mature cohort, publish rate, counts, reasons, and denominators by segment. Set a rate-reduction target only after reason validation and a comparable baseline; do not infer causes from geography. |
| **3. Monitor rating coverage and score distribution together.** Check review delivery/linkage for delayed orders without imputing scores. | Valid-rating coverage: 97.66% delayed (6,381 / 6,534) and 99.45% on time (89,443 / 89,936). Missing valid ratings: 153 delayed and 493 on time. | **Coverage by delivery group:** rated eligible orders / eligible delivered orders. **Baseline:** 97.66% delayed; 99.45% on time. **Completeness gap:** on-time coverage minus delayed coverage = 1.79 percentage points. | Recompute monthly on mature delivery cohorts; investigate changes greater than 1 percentage point versus the baseline, while reporting both denominators. Do not treat coverage differences as an explanation for the rating gap. |
| **4. Keep cancellation reporting denominator-safe.** Publish numerator and all-status denominator on every overall and state summary. | The cancellation label is exactly `canceled`; `unavailable` remains distinct. Overall candidate: 625 / 99,441 = 0.63%. | **Reconciliation check:** total status counts = total unique orders; sum of state orders = same all-order total; overall cancellation numerator equals sum of state canceled counts. | Require all three checks to pass before release. If a data refresh changes them, stop publication and reconcile IDs/status mappings rather than adjusting the rate silently. |

The numeric pilot threshold above is a proposed operational service level, not
an approved organizational commitment. Any rating or cancellation outcome
threshold should be agreed before pilot launch using matched cohorts and
available sample sizes.

## Definitions and quality controls

1. **Cancellation denominator:** all distinct usable order IDs across all
   recorded statuses. The raw order source has 99,441 rows, 99,441 distinct
   nonmissing IDs, and eight statuses.
2. **Review linkage:** use `order_id`; preserve distinct
   `(order_id, review_id)` relationships. Do not use `reviews_clean` for this
   comparison because it keeps one row per `review_id`, and 789 review IDs
   occur against multiple orders.
3. **Timeliness:** only `delivered` orders with both date fields qualify;
   delayed means actual customer delivery calendar date is after estimated
   calendar date. Same-day deliveries are on time.
4. **Rating comparison:** include linked scores 1–5. Average multiple valid
   review scores per order, then average the order-level means so a
   multi-review order does not receive additional weight. Report coverage
   and eligible/rated/unrated group counts.
5. **No causal interpretation:** the historical group difference may reflect
   other order, customer, or service characteristics. Use a prospective
   controlled pilot to evaluate an intervention.
6. **Publication check:** reconcile candidate files with the approved MySQL
   snapshot. Existing exports are candidate outputs from repository raw
   files, not evidence that the MySQL import has been rerun.

## Deliverables

- [Cancellation distribution](../data/exports/week4_cancellation_analysis.csv)
- [Review-score distribution and coverage](../data/exports/week4_rating_analysis.csv)
- [Delayed/on-time rating comparison](../data/exports/week4_delay_rating_comparison.csv)
- [Reproducible analysis notebook](../notebooks/week4_cancellation_rating_analysis.ipynb)
- [Cancellation analysis](cancellation_analysis.md)
- [Customer rating analysis](customer_rating_analysis.md)
- [SQL queries and denominator/linkage checks](../sql/10_cancellation_rating_analysis.sql)
