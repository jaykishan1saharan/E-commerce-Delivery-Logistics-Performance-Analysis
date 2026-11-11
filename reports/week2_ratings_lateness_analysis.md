# Week 2 — Ratings vs. Delivery Lateness Analysis

## 1. Objective

Investigate whether customer review scores differ between on-time
and late deliveries and whether delivery timeliness is associated
with customer rating categories.

## 2. Dataset

- Source: `data/interim/kpi_orders.csv`
- Total eligible delivered orders: 96,470
- Unique order IDs: 96,470
- Valid review scores: 95,824
- Missing or invalid review scores: 646
- On-time orders: 88,644
- Late orders: 7,826

## 3. Delay Buckets

Delay buckets use the existing `is_on_time` flag for on-time
classification and positive `delay_days` values for late-order
grouping.

Orders with a late flag but non-positive or missing delay values
are kept in a separate verification bucket.

See `tables/delay_bucket_analysis.csv`.

## 4. Descriptive Rating Comparison

delivery_group  order_count  mean_rating  median_rating  standard_deviation
       On-time        88163     4.294114            5.0            1.147252
          Late         7661     2.565070            2.0            1.658462

## 5. Mann–Whitney U Test

- Null hypothesis: On-time and late deliveries have the same
  review-score distributions.
- Alternative hypothesis: Their review-score distributions differ.
- On-time sample size: 88,163
- Late sample size: 7,661
- U statistic: 524709892.5000
- p-value: <0.001
- Rank-biserial correlation: 0.553737
- Significance level: 0.05

**Interpretation:** Statistically significant difference detected.

## 6. Chi-Square Test of Independence

- Null hypothesis: Delivery timeliness and review-score category
  are independent.
- Alternative hypothesis: They are associated.
- Chi-square statistic: 14221.1053
- Degrees of freedom: 4
- p-value: <0.001
- Cramer's V: 0.385238

**Interpretation:** Statistically significant association detected.
- Minimum expected cell frequency: 233.53

See `tables/delivery_status_rating_contingency.csv`.

## 7. Data Quality Notes

- Delay-sign versus timeliness-flag discrepancies: 6
- The existing `is_on_time` flag was used for group assignment.
- Missing review scores were excluded from statistical tests.
- Original source data was not modified.
- Delay-sign discrepancies should be reconciled with the SQL
  calendar-date timeliness definition.

## 8. Limitations

These tests identify differences or associations, not causation.
Other factors may influence customer ratings. The analysis depends
on the correctness of the existing KPI flags and source dataset.

## 9. Output Files

- `tables/delay_bucket_analysis.csv`
- `tables/ratings_by_delivery_status.csv`
- `tables/delivery_status_rating_contingency.csv`
- `tables/statistical_test_results.csv`
- `figures/delay_bucket_distribution.png`
- `figures/ratings_by_delivery_status.png`
