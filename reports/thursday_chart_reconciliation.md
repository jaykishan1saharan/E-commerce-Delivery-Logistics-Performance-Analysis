# Thursday Chart Reconciliation Checklist

Owner: Member 3 — Jaykisan Saharan

## Before final sign-off
- [ ] Confirm the exact validated SQL output file and query version with Member 1/2.
- [ ] Compare delivered-order population and distinct `order_id` counts.
- [ ] Compare state late-order numerator, eligible denominator, and percentage.
- [ ] Compare category mean `delivery_days`, eligible order count, and missing-value handling.
- [ ] Compare monthly average delivery duration, on-time numerator/denominator, and sample count.
- [ ] Investigate any mismatch; document the cause rather than silently changing the source.
- [ ] Rerun the notebook top to bottom after changes.
- [ ] Confirm all three PNG charts were refreshed and are readable.

## Current status
The notebook regenerates charts from the current interim CSV and prints data-integrity checks. SQL reconciliation is pending until matching validated SQL aggregate results are available for direct comparison.
