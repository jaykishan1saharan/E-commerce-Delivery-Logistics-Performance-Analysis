# E-commerce Delivery & Logistics Performance Analysis

## Project overview
This project analyzes the Olist e-commerce dataset to understand order status, delivery performance, data quality, cancellations, and customer review patterns. The repository contains source data, SQL cleaning/audit scripts, saved analysis outputs, and Python-generated charts and summaries.

## Project status
The repository contains initial data-quality reports and exploratory analysis outputs. Treat the project as **in progress** until the team has rerun the current SQL/Python workflows, reconciled differing counts, verified dashboard outputs, and approved the final report.

## Repository structure
- `data/raw/` — source CSV files; preserve these files unchanged.
- `data/interim/` — saved query outputs and intermediate analysis files.
- `SQL/` — SQL cleaning, audit, and export scripts.
- `reports/` — data dictionary, cleaning log, quality summaries, and analysis outputs.
- `reports/member4/` — charts and CSV outputs for order status, delivery duration, cancellations, and review scores.
- `docs/` — project daily log, decision log, meeting notes, and submission checklist.
- `load_data.py`, `run_analysis.py`, `export_member4_results.py` — Python scripts for loading/analysis/export; check their current requirements and paths before running.

## Data and analysis notes
The source data represents Olist e-commerce orders. Existing reports include order status, review-score distribution, delivery duration, cancellation analysis, and data-quality checks.

**Important reconciliation note:** Existing artifacts report different row counts and late-delivery totals. For example, `reports/cleaning_summary.md` describes saved cleaning outputs, `reports/data_quality_summary.md` describes staging-table audit results, and `member4_findings.md` reports 7,826 late deliveries while a separate KPI validation result reported 6,534. These may use different snapshots, filters, or definitions. Do not treat them as directly comparable or publish one as the final KPI until the team reruns the current workflows and agrees on the denominator and eligibility rules.

## Setup
Use a Python virtual environment where possible:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

The analysis also depends on the SQL database/workflow used by the team. Review the relevant SQL script comments and confirm the database name, source paths, and required table/view creation order before execution. Do not assume that running the Python scripts alone rebuilds the MySQL staging and clean views.

## Suggested execution and verification order
1. Confirm source CSV files exist in `data/raw/`.
2. Review and run the approved SQL import/staging and cleaning scripts in the documented order.
3. Run the audit and cleaning-log export against the current database.
4. Run the Python analysis/export scripts with their required paths and dependencies.
5. Compare row counts and KPI definitions across SQL, CSV outputs, Python reports, and dashboard.
6. Record discrepancies and unresolved anomalies in `docs/decision_log.md` and `reports/project_summary.md`.
7. Update final findings only after the team lead and analysis owners confirm the results.

## Documentation
- `docs/week3_daily_log.md` — day-by-day work and verification status.
- `docs/decision_log.md` — confirmed assumptions, definitions, and unresolved decisions.
- `docs/meeting_notes.md` — review outcomes and handoffs.
- `docs/final_submission_checklist.md` — final quality and submission checks.
- `reports/project_summary.md` — project overview, verified findings, limitations, and pending reconciliation.

## Limitations
- Saved CSV/report outputs are snapshots and may not reflect the current database.
- Delivery KPI counts depend on order eligibility, timestamp validity, and the agreed on-time definition.
- Existing reports identify anomalies but do not establish their causes.
- Final dashboard availability and consistency must be verified against the current branch before marking the project complete.
