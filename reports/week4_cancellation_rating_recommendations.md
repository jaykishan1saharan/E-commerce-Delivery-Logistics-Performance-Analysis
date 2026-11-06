# Week 4 Cancellation and Rating Recommendations — Draft

> **Evidence status:** Candidate metrics reproduced from the repository's raw
> CSV files. 

## Measured findings

- **Cancellations:** 625 of 99,441 unique orders were labeled `canceled`
  (0.63%). `unavailable` is a separate status and is not included in this
  numerator.
- **Cancellation concentration:** São Paulo had the largest count
  (327 / 41,746; 0.78%). Roraima's rate was highest (1 / 46; 2.17%), but is
  based on a small denominator.
- **Ratings:** The source contains 99,224 valid score records (1–5), linked
  to 98,673 orders. The source-record distribution is 57.78% five-star and
  11.51% one-star.
- **Delivery-linked ratings:** Among delivered orders with both dates,
  89,936 were on time and 6,534 delayed. Per-order mean scores were 4.29 and
  2.27, respectively. Valid-rating coverage was 99.45% on time and 97.66%
  delayed. The 2.02-point gap does not establish a causal effect.

## Recommendations

| Priority | Recommendation | Link to measured evidence | Next step and measure | Guardrail |
|---|---|---|---|---|
| 1 | Review the delayed-delivery customer experience. | Delayed orders averaged 2.27 / 5 versus 4.29 / 5 on time, across 6,381 and 89,443 rated orders. | Review a sample of delayed orders with low scores; track valid-rating coverage, score distribution, and order-level mean by comparable time cohort. | Do not claim that delay caused the rating gap. Review free-text/reason data and other order differences before selecting an intervention. |
| 2 | Audit cancellation reasons in the highest-volume state before proposing a state-specific change. | São Paulo accounts for 327 of 625 canceled orders; its rate is 0.78% (327 / 41,746). | Join canceled orders to approved reason or support data, validate those fields, and report count and rate by state and period. | The current status file contains no cancellation reason or causal evidence. Do not target a process solely from status rates. |
| 3 | Keep small-state cancellation rates in a monitored, not ranked, view. | Roraima is 1 / 46 (2.17%); Rondônia is 3 / 253 (1.19%). | Use minimum-volume context and compare additional periods before escalation; preserve numerator and denominator in every display. | One to three events can move rates sharply; these observations are not stable performance estimates. |
| 4 | Improve the valid-rating follow-up for delayed orders if operationally appropriate. | Rating coverage is 97.66% for delayed versus 99.45% for on-time eligible deliveries (153 vs. 493 unrated orders). | Check whether survey delivery, response timing, or review linkage differs for delayed orders; monitor valid-score coverage by group. | Coverage differences are modest and do not explain the score difference; do not impute missing scores. |

## Monitoring and release checks

1. Reconcile all three candidate exports to the approved MySQL snapshot.
2. Keep the order-level group sizes, review-record counts, and rating
   denominators visible; do not mix review-record and order-level means.
3. Use a consistent calendar-date delay rule and preserve missing-date counts.
4. Reassess recommendations only after cancellation-reason evidence and
   comparable follow-up cohorts are available.
