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
