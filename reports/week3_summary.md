# Week 3 Summary

- **Project:** E-commerce Delivery & Logistics Performance Analysis
- **Reporting date:** 30 October 2026
- **Status:** Week 3 artifacts are present; cross-source reconciliation and formal team approval remain open.

## Executive summary

Week 3 added delivery-stage, geographic, category, and time-based analyses, refreshed exploratory charts, and documented KPI validation. The strongest operational signal in the saved regional export is a higher late-delivery rate in the Northeast than in the other listed regions. The delivery-stage export also shows a longer average carrier-to-customer interval than the other two intervals. These are descriptive leads for investigation, not evidence of causes.

The validated overall delivery KPI results are **6,534 late orders out of 96,470 eligible delivered orders (6.77%)** and **89,936 on-time orders (93.23%)**. SQL and Python results match for nine directly compared checks, and independent Python checks of the stored `on_time_eligible` and `on_time` flags report zero mismatches. Team approval and reconciliation of all Week 3 exports against this baseline are still pending. See the [validation sign-off](validation_signoff.md), [SQL/Python comparison](member2/sql_python_kpi_comparison.csv), and [independent flag validation summary](member2/validation_summary.md).

## Week 3 analysis and evidence

### Delivery-stage intervals

The [delivery-stage export](../exports/week3_delivery_stage_analysis.csv) reports 75,840 total orders in its analysis population and these mean intervals:

| Interval in export | Valid stages | Mean days |
|---|---:|---:|
| Purchase to approval | 75,714 | 0.43 |
| Approval to carrier | 73,451 | 2.86 |
| Carrier to customer | 73,568 | 9.33 |

The carrier-to-customer interval is the longest of the three in this export. The intervals have different valid-record counts, and the operational meaning of the carrier timestamp has not been confirmed. Treat them as timestamp-based descriptive intervals, not a confirmed decomposition of warehouse or carrier responsibility. The unresolved timestamp-order issue is documented in the [validation report](validation_report.md).

### Geographic delivery performance

The [regional export](../exports/week3_region_analysis.csv) reports the highest late-delivery rate in the **Northeast: 14.24% (990 late / 6,951 eligible)**. The other regional rates are South 7.07%, Southeast 7.36%, Central-West 8.36%, and North 9.67%. These values come from this export's own population and have not been reconciled to the validated overall KPI output.

At state level, the [state export](../exports/week3_state_analysis.csv) includes large and small eligible populations. For example, AL reports 23.10% (70 / 303), MA 19.12% (104 / 544), and BA 14.14% (357 / 2,524). Small-denominator states are less stable; do not rank them without showing counts or treat these differences as causal.

The corresponding [state chart](../charts/late_rate_by_state.png) is exploratory. Its [chart notes](chart_notes.md) specify that the charts use an interim export and require SQL reconciliation.

### Category analysis

The [Week 3 category export](../exports/week3_category_analysis.csv) contains only an `Unknown` category row: 192 total orders, 189 eligible delivered orders, and 18 late orders (9.52%). It does not provide usable category-to-category evidence. Do not use this export to prioritize or deprioritize product categories until the category join and coverage are corrected and checked. Earlier category findings in the [interim report](interim_findings.md) are from a different analysis artifact and are not a substitute for validating this Week 3 export.

### Time trends

The [monthly export](../exports/week3_monthly_trends.csv) reports monthly purchase cohorts. For example, August 2018 has 4,887 delivered orders and an average delivery duration of 7.65 days; September and October 2018 have no delivered orders and therefore no reported average. The [weekly export](../exports/week3_weekly_trends.csv) provides a finer-grained view.

These are descriptive cohort summaries, not a final trend KPI. Recent cohorts are incomplete, duration is conditioned on delivery, and the exports have not been reconciled to the approved KPI population. The [chart notes](chart_notes.md) further document the interim-source and denominator limitations.

## Validation and delivery status

- The [Week 3 deep-analysis notebook](../notebooks/week3_deep_analysis.ipynb), [deep-analysis SQL](../sql/06_deeper_analysis.sql), and [validation SQL](../sql/07_validation.sql) are present.
- Three exploratory charts are present: [state late rate](../charts/late_rate_by_state.png), [delivery delay by segment](../charts/delivery_delay_by_segment.png), and [monthly delivery trend](../charts/monthly_delivery_trend.png). Chart generation and source details are described in the [chart notes](chart_notes.md).
- The [validation sign-off](validation_signoff.md) records matching SQL/Python results for nine directly compared checks and zero mismatches in two independent Python flag checks. Formal cross-member approval is pending.
- The validation evidence flags **1,359 records with negative carrier-handoff durations**. The records are retained; their timestamp ordering and upstream derivation need investigation. See the [validation report](validation_report.md).
- The project still records an unresolved difference between 7,826 late deliveries in an earlier report and 6,534 in the validated KPI results. The source population, filters, and definitions must be reconciled before publishing a single final figure; see the [project summary](project_summary.md) and [decision log](decision_log.md).

## Handover priorities

1. Reconcile each Week 3 aggregate to an approved source, query version, order grain, and denominator; record any remaining differences.
2. Investigate the carrier timestamp semantics and the 1,359 negative handoff intervals without altering source records by assumption.
3. Repair and validate the category export before drawing category-level conclusions.
4. Confirm notebook execution, refreshed chart outputs, dashboard availability, and formal team approval before marking final submission complete. The [submission checklist](../docs/final_submission_checklist.md) tracks the outstanding release checks.

## Interpretation

The geographic and interval comparisons identify where to investigate next; they do not establish why delays occur. Keep validated KPI results separate from exploratory Week 3 exports, show denominators with rates, and label incomplete cohorts and unresolved data-quality issues whenever these findings are reused.
