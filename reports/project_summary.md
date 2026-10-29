# Project Summary — E-commerce Delivery & Logistics Performance Analysis

## Overview
This project examines Olist e-commerce order data to describe order status, delivery duration, delivery delays, cancellations, customer review scores, and data-quality issues.

## Data sources and workflow
The repository includes raw CSVs in `data/raw/`, saved query outputs in `data/interim/`, SQL cleaning and audit scripts under `SQL/`, and analysis outputs in `reports/`. The cleaning summary describes an approach that retains staging tables and applies cleaning rules through SQL clean views rather than modifying source CSVs.

## Metrics and current findings
Existing artifacts report:
- 99,441 total orders and 96,478 delivered orders in the member analysis summary.
- A cancellation count of 625 (0.63% of all orders) in `member4_findings.md`.
- Review-score counts in the existing analysis outputs, with 5-star reviews most frequent.
- Average delivery duration of 12.56 days and a maximum of 209.63 days in `member4_findings.md`.

These figures are **reported in existing saved artifacts and have not been reconciled here against a fresh end-to-end run**.

## Data-quality observations
The existing cleaning summary reports missing/blank review text, missing product categories and dimensions, duplicated review IDs, 166 carrier-before-purchase timestamp anomalies, and two orphan item references. It states that anomalies and orphan references are retained for investigation rather than corrected using guessed values.

## Important reconciliation items
- `member4_findings.md` reports 7,826 late deliveries.
- A separate KPI validation result shared by the team reported 6,534 late deliveries, with a 6.77% late rate among 96,470 eligible delivered orders.
- `reports/cleaning_summary.md` and `reports/data_quality_summary.md` contain counts from different snapshots/stages. Their totals should not be mixed without identifying the query, table, and execution date.
- The dashboard file and final refresh status must be checked in the current GitHub branch.

Before final submission, rerun the approved SQL and Python workflows, agree on KPI definitions and denominators, reconcile outputs, and replace this section with team-approved final numbers.

## Limitations
- Saved reports may reflect different snapshots.
- Late/on-time classification depends on the agreed definition and valid dates.
- Data-quality anomalies identify records for review but do not prove the underlying cause.
- Descriptive patterns do not establish that a particular factor caused a delay or cancellation.

## Conclusion
The repository contains useful initial data-quality and exploratory-analysis artifacts, but the final report should remain provisional until KPI counts, row counts, execution instructions, and dashboard outputs are reconciled and reviewed.
