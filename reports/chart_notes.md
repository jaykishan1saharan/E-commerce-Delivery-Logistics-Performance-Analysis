# Week 3 Chart Notes — Tuesday (Day 2)

Owner: Member 3 — Jaykisan Saharan

## Source files
- `data/interim/kpi_orders.csv` (used for both charts)
- `data/interim/kpi_orders_all.csv` is available for cross-checking but was not used to silently replace the selected analysis source.

## Chart 1: `charts/late_rate_by_state.png`
- **Metric:** late delivery rate by `customer_state`.
- **Population:** rows where `order_status` is `delivered` and `is_on_time` is exactly 0 or 1.
- **Numerator:** delivered orders with `is_on_time = 0`.
- **Denominator:** distinct `order_id` values in each state with a known binary `is_on_time` flag.
- **Rate:** numerator / denominator × 100.
- **Caution:** the chart uses the current interim export; compare counts and definitions with the validated SQL output before treating the rates as final. The export has a smaller row count than `kpi_orders_all.csv`, so export reconciliation remains open.

## Chart 2: `charts/delivery_delay_by_segment.png`
- **Segment:** `category` (product category).
- **Metric:** mean `delay_days` for delivered rows with a non-missing numeric delay.
- **Interpretation:** negative values indicate delivery before the estimated delivery date, assuming the source's `delay_days` convention. Positive values indicate lateness.
- **Caution:** the available export is an order-level KPI view with a category field; verify category grain and one-row-per-order assumptions before interpreting category comparisons. Categories with fewer orders may be less stable; counts are available in the calculation below.

## Reproducibility and limitations
- Figures were generated from the saved interim CSV using pandas and Matplotlib.
- Missing/unknown on-time flags are excluded from the late-rate denominator.
- Non-delivered orders are excluded from both delivery performance charts.
- These figures are exploratory, not final validated findings. Do not infer causation from category/state differences.


# Chart Notes — Wednesday: Time Trends

## `charts/monthly_delivery_trend.png`
- **Source:** `data/interim/kpi_orders.csv` (aggregate order-level export).
- **Period:** 2016-09 to 2018-08.
- **Population:** rows with `order_status = delivered`, a valid `order_purchase_timestamp`, and non-missing `delivery_days`.
- **Metric 1:** monthly average `delivery_days`; each point is the mean for the month.
- **Metric 2:** monthly on-time rate, calculated as the mean of `is_on_time` among eligible delivered orders, shown as a percentage.
- **Volume context:** monthly eligible order counts are calculated in the notebook's `monthly` table; interpret rate changes alongside sample size.

## Initial observations
- Highest monthly average delivery time: 2016-09 (54.81 days; 1 orders).
- Lowest monthly average delivery time: 2016-12 (4.69 days; 1 orders).
- These are descriptive comparisons; they do not establish causes.

## `processing_vs_transit.png`
Not generated. The available export contains `approval_days`, `handling_days`, and `delivery_days`, but no carrier handoff timestamp. Without a validated handoff event and agreed definitions, processing time versus transit time cannot be separated reliably. Do not infer transit time by subtracting potentially overlapping fields.

## Limitations and checks
- The source export has 96,470 rows and its observed `order_status` is delivered for all rows; it is not a complete status history.
- Reconcile monthly counts and rates against the validated SQL output before final submission.
- Confirm that `delivery_days` and `is_on_time` definitions match the team metric definitions.


# Chart Notes — Week 3, Thursday (Day 4): Robustness and Verification

**Owner:** Member 3 — Jaykisan Saharan

## 1. Refreshed Chart Outputs
- `charts/late_rate_by_state.png` — Shows the top 15 states by late-delivery rate, including eligible order counts.
- `charts/delivery_delay_by_segment.png` — Shows the top 15 product categories by average delivery duration, including eligible order counts.
- `charts/monthly_delivery_trend.png` — Shows monthly average delivery duration and on-time delivery rate.

## 2. Data Source and Methodology

**Source file:** `data/interim/kpi_orders.csv`

Before refreshing the charts, the notebook checks the total row count, unique order IDs, duplicate order IDs, missing purchase timestamps, and order-status distribution.

The calculations use the following definitions:

- **Late-delivery rate by state:** Number of delivered orders with `is_on_time = 0`, divided by the number of distinct delivered orders with `is_on_time` equal to 0 or 1, multiplied by 100.
- **Average delivery duration by category:** Mean `delivery_days` for distinct delivered orders with a non-missing numeric delivery duration.
- **Monthly delivery trend:** Monthly average `delivery_days` and on-time delivery rate for distinct delivered orders with valid purchase timestamps and non-missing delivery duration.

The notebook removes duplicate `order_id` values before grouping to reduce accidental inflation of order counts. The exact population, missing-value handling, and metric definitions must be checked against the team's validated SQL outputs.

## 3. Validation Status and Limitations

**SQL reconciliation status: Pending.**

The charts are reproducible from the current interim CSV, but they have not yet been confirmed against the team's validated SQL aggregates.

The following checks are required before final sign-off:

- Confirm the validated SQL output file and query version with Members 1 and 2.
- Compare delivered-order populations and distinct `order_id` counts.
- Compare state-level late-order numerators, eligible denominators, and percentages.
- Compare category-level average delivery duration, eligible order counts, and missing-value handling.
- Compare monthly average delivery duration, on-time-rate numerators and denominators, and sample sizes.
- Investigate and document any discrepancies instead of silently changing the source data.
- Rerun the notebook from beginning to end after any corrections.
- Confirm that all three PNG charts have been refreshed and are readable.

The `processing_vs_transit.png` chart has not been generated because the available source does not establish a reliable carrier handoff timestamp. Processing time and transit time therefore cannot be separated reliably from the available fields.

The current export may have a different row count from other project exports. This difference requires reconciliation and should not automatically be treated as an error. Small sample sizes and differences in source populations may also affect comparisons.

State, category, and monthly differences are descriptive findings; they do not establish the causes of delivery delays.

## 4. Final Sign-Off

The notebook contains the chart-refresh code and data-integrity checks. The analysis can be considered ready for final sign-off only after the SQL reconciliation checks are completed, discrepancies are documented, and the refreshed charts are verified against the validated outputs.


# Chart Notes — Week 3, Friday (Day 5): Final Review and Handover

**Owner:** Member 3 — Jaykisan Saharan

## 1. Finalized Analysis Outputs

The Friday final-review notebook section reruns the analysis checks and regenerates the following three charts from `data/interim/kpi_orders.csv`:

- `charts/late_rate_by_state.png` — Final state-wise late-delivery-rate chart, showing the eligible order count for each displayed state.
- `charts/delivery_delay_by_segment.png` — Final category-wise average delivery-duration chart, showing the eligible order count for each displayed category.
- `charts/monthly_delivery_trend.png` — Final monthly average delivery-duration and on-time-rate chart.

The `notebooks/week3_deep_analysis.ipynb` notebook retains the previous Week 3 analysis sections and adds the Friday final-review and handover section.

## 2. Friday Final Data Checks

Before regenerating the charts, the notebook checks:

- Total source row count.
- Number of unique order IDs.
- Duplicate order IDs and missing order IDs.
- Invalid or missing purchase timestamps.
- Missing delivery-duration values.
- Missing or non-binary `is_on_time` flags.
- Order-status distribution.

For the descriptive chart calculations, duplicate order IDs are reported and then removed so that each order contributes at most once. The notebook displays the integrity summary and status counts for review.

## 3. Final Metric Definitions

- **State-wise late-delivery rate:** Delivered orders with `is_on_time = 0` divided by delivered orders with a binary `is_on_time` value (0 or 1), multiplied by 100. The denominator is based on distinct eligible order IDs within each state.
- **Category-wise average delivery duration:** Mean numeric `delivery_days` for distinct delivered orders with a non-missing delivery duration, grouped by product `category`.
- **Monthly average delivery duration:** Mean `delivery_days` for distinct delivered orders with a valid `order_purchase_timestamp` and non-missing delivery duration, grouped by purchase month.
- **Monthly on-time rate:** Number of delivered orders with `is_on_time = 1` divided by the number of delivered orders with a binary `is_on_time` value (0 or 1), grouped by purchase month. Missing and non-binary flags are excluded from this rate's denominator.

## 4. Final Source and Reproducibility Notes

- The final notebook regenerates the three charts using pandas and Matplotlib from the repository-relative source `data/interim/kpi_orders.csv`.
- The analysis uses the interim order-level KPI export. The notebook reports source row counts and distinct order IDs so that the source population can be reviewed.
- `data/interim/kpi_orders_all.csv` is a separate available export for cross-checking. It must not be silently substituted for the selected source.
- Run the notebook from top to bottom in the project's Python environment to reproduce the analysis tables and chart files.

## 5. Remaining Limitations and Validation Status

**SQL reconciliation status: Pending until direct comparison with the team's validated SQL outputs is completed.**

Before the charts can be described as SQL-verified, compare:

- Delivered-order populations and distinct order counts.
- State-wise late-order numerators, eligible denominators, and percentages.
- Category-wise eligible order counts, average delivery duration, and missing-value handling.
- Monthly eligible order counts, average delivery duration, on-time numerators, denominators, and rates.
- Metric definitions and filtering rules used by the notebook and validated SQL queries.

Any mismatch must be investigated and documented rather than silently changing the source or metric definition.

The `processing_vs_transit.png` chart remains ungenerated because the available source does not establish a reliable carrier handoff timestamp. Processing time and transit time therefore cannot be separated reliably from the available fields.

Differences between interim exports must be investigated by order ID and inclusion rule. A difference in row counts alone does not prove which export is correct. State, category, and monthly differences are descriptive and do not establish causes; small samples may make subgroup averages and rates unstable.

## 6. Friday Handover Checklist

- [ ] Run `notebooks/week3_deep_analysis.ipynb` from top to bottom.
- [ ] Confirm the final data-integrity summary and status counts display correctly.
- [ ] Confirm all three PNG charts are regenerated in the `charts/` folder.
- [ ] Inspect chart titles, labels, units, and sample counts for readability.
- [ ] Confirm this `reports/chart_notes.md` file describes the actual source, populations, denominators, and limitations.
- [ ] Compare chart aggregates with the team's validated SQL outputs when they are available.
- [ ] Document and investigate any differences before final sign-off.
- [ ] Stage only Member 3's intended Friday files, review the staged changes, make one meaningful commit, and push it.
- [ ] Share the Friday commit hash with the team for the final daily review.

**Final status:** The Friday notebook section and chart documentation are prepared for reproducible analysis and handover. SQL reconciliation must still be completed before final analytical sign-off.
