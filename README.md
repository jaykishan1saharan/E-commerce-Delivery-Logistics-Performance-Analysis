# E-commerce Delivery & Logistics Performance Analysis

## 1. Project Overview

This team project analyzes the Brazilian E-Commerce Public Dataset by Olist to understand order fulfilment, delivery performance, late deliveries, cancellations, customer reviews, and data-quality limitations.

The analysis uses Python, SQL, MySQL, SQLite, and exploratory visualizations. The project is descriptive: observed relationships should not be interpreted as proof of causation, and missing operational data must not be invented.

## 2. Project Status

The repository contains source datasets, data-ingestion scripts, MySQL staging and clean-view workflows, SQLite analysis scripts, KPI validation outputs, exploratory reports, and project documentation.

Week 4 documentation and the final presentation have been added to the Member 5 working branch. Dashboard verification, final KPI export reconciliation, team review, and pull-request approval must be confirmed before the project is declared fully complete.

## 3. Dataset

**Source:** [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The `data/raw/` directory contains six source files:

- `olist_customers_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `product_category_name_translation.csv`

Preserve the original CSV files unchanged. The complete Olist dataset includes other tables that may not be present in this repository.

## 4. Repository Structure

- `data/raw/` — original source CSV files.
- `data/interim/` — saved SQL query outputs.
- `sql/` — MySQL audit, cleaning, KPI, and validation scripts.
- `src/scripts/` — Python ingestion, analysis, and export scripts.
- `notebooks/` — analysis notebooks.
- `reports/` — data-quality reports, findings, tables, and figures.
- `docs/` — KPI definitions, decision log, meeting notes, daily logs, reconciliation notes, dashboard guide, refresh limitations, and submission checklist.
- `presentation/` — final project presentation.
- `exports/` — generated project exports.

## Data and KPI Reconciliation

Existing saved artifacts contain different row counts and late-delivery totals. In particular, earlier findings report 7,826 late deliveries, while an independent raw-source calendar-date validation reports 6,534 late deliveries among 96,470 eligible delivered orders (6.77%).

These figures must not be mixed without checking their source, snapshot, eligibility rules, and calculation method. The saved KPI export flags require regeneration and review before dashboard use. See `docs/kpi_reconciliation.md` and `docs/data_refresh_limitations.md` for the current reconciliation notes.

## 5. Environment Setup

Python 3.9 or newer is recommended. Use a virtual environment.

### macOS / Linux

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

- `docs/KPI_definitions.md` — KPI definitions and calculation rules.
- `docs/week3_daily_log.md` — Week 3 daily progress and verification status.
- `docs/week4_daily_log.md` — Week 4 daily progress and handover status.
- `docs/decision_log.md` — confirmed assumptions and unresolved decisions.
- `docs/meeting_notes.md` — review outcomes and team handoffs.
- `docs/kpi_reconciliation.md` — late-delivery KPI reconciliation.
- `docs/dashboard_user_guide.md` — dashboard usage and verification guidance.
- `docs/data_refresh_limitations.md` — refresh procedures and known limitations.
- `docs/final_presentation_outline.md` — final presentation structure.
- `docs/pull_request_merge_steps.md` — GitHub pull-request and merge procedure.
- `docs/final_submission_checklist.md` — final quality and submission checks.
- `presentation/QVETO_Technologies_Olist_Ecommerce_Logistics_Final_Presentation.pptx` — final project presentation.
- `reports/project_summary.md` — project overview, findings, limitations, and pending reconciliation.

## Limitations
- Saved CSV/report outputs are snapshots and may not reflect the current database.
- Delivery KPI counts depend on order eligibility, timestamp validity, and the agreed on-time definition.
- Existing reports identify anomalies but do not establish their causes.
- Final dashboard availability and consistency must be verified against the current branch before marking the project complete.
### Windows PowerShell

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

The MySQL workflow also requires a running MySQL server, access to the `ecommerce_delivery` database, and the Python MySQL connector used by the import script. Confirm that all required Python packages are installed before running the MySQL import.

## 6. MySQL Workflow

The MySQL workflow uses the `ecommerce_delivery` database and six staging tables:

- `customers_stage`
- `orders_stage`
- `items_stage`
- `reviews_stage`
- `products_stage`
- `translation_stage`

### Step 1: Import the raw CSV files

Run the following from the repository root:

```bash
python src/scripts/import_mysql_staging.py
```

The script imports the six source datasets into MySQL staging tables. Keep the original CSV files unchanged.

### Step 2: Run the data-quality audit

Execute:

```text
sql/02_data_quality_audit.sql
```

This script contains checks for data completeness, duplicates, invalid values, timestamps, and table relationships.

### Step 3: Create or refresh clean views

Execute:

```text
sql/03_create_clean_views.sql
```

Review the SQL and its assumptions before execution. The clean views provide a transformed analytical layer while retaining the staging tables as source inputs.

### Step 4: Run KPI queries

Execute:

```text
sql/04_kpi_queries.sql
```

These queries support delivery and logistics KPI analysis. Review the definitions, eligibility rules, and denominators before reporting results.

### Step 5: Export the cleaning log

Execute:

```text
sql/05_export_cleaning_log.sql
```

Review the query results and export them as required by the script's instructions.

### Step 6: Validate the KPI results

The repository includes two validation scripts:

```text
sql/06_kpi_validation_clean.sql
sql/07_kpi_validation_optimized.sql
```

Review and run the appropriate script against the current database. The optimized validation workflow uses temporary tables and indexing techniques to support validation.

Saved MySQL outputs are available in:

- `reports/data_quality/mysql_audit_output.txt`
- `reports/kpi_validation/mysql_kpi_validation_output.txt`

These files are saved snapshots. Rerun the corresponding checks when the underlying data or SQL logic changes.

## 7. SQLite Analysis Workflow

The SQLite workflow is separate from the MySQL workflow. It must not be assumed to refresh MySQL staging tables, clean views, or saved audit results.

Run the following commands from the repository root:

```bash
python src/scripts/load_data.py
python src/scripts/run_analysis.py
python src/scripts/export_analysis_results.py
```

The existing Python workflow loads selected orders and reviews data into SQLite, runs summary SQL queries, and exports analysis results.

The repository also contains:

```bash
python src/scripts/build_kpi_sqlite.py
```

This is a separate SQLite KPI-building workflow. Check the script's configuration and expected input files before running it.

Do not assume the SQLite database contains all six source datasets or that outputs from SQLite and MySQL will be identical without matching schemas, cleaning rules, and data snapshots.

## 8. Verified MySQL Data Counts

The latest documented MySQL staging and clean-view counts are:

| Dataset | Raw rows | Staging rows | Clean-view rows |
|---|---:|---:|---:|
| Customers | 99,441 | 99,441 | 99,441 |
| Orders | 99,441 | 99,441 | 99,441 |
| Order items | 112,650 | 112,650 | 112,650 |
| Reviews | 99,224 | 99,224 | 98,410 |
| Products | 32,951 | 32,951 | 32,951 |
| Category translations | 71 | 71 | 71 |
| **Total** | **443,778** | **443,778** | **442,964** |

The clean-view review count is lower because the existing clean-view logic removes excess duplicate `review_id` records.

The review audit recorded:

- Duplicate review ID groups: **789**
- Excess duplicate review rows: **814**
- Review score 1: 11,424
- Review score 2: 3,151
- Review score 3: 8,179
- Review score 4: 19,142
- Review score 5: 57,328

These counts describe the verified database snapshot used for the audit. Rerun the checks if the staging data or cleaning logic changes.

## 9. Reports and Outputs

Important project artifacts include:

- `reports/data_quality/day1_validation_summary.md` — reconciled row counts and data-quality summary.
- `reports/data_quality/mysql_audit_output.txt` — saved MySQL audit output.
- `reports/data_quality/data_quality_summary.md` — data-quality summary from a saved run.
- `reports/data_quality/cleaning_summary.md` — cleaning observations and follow-up items.
- `reports/data_quality/data_dictionary.csv` — field descriptions and validation notes.
- `reports/data_quality/data_quality_report.csv` — saved check-level results.
- `reports/data_quality/cleaning_log.csv` — saved cleaning/audit log.
- `reports/kpi_validation/mysql_kpi_validation_output.txt` — saved KPI validation output.
- `reports/interim_findings.md` — preliminary descriptive findings.
- `reports/tables/` — summary tables.
- `reports/figures/` — exploratory visualizations.
- `data/interim/` — saved SQL query result CSVs.

Saved files may represent different runs. Check their source and timestamp before combining their results into one report.

## 10. Methodology and Data-Quality Principles

- Preserve original source CSV files.
- Document transformations and retain traceability to staging data.
- Check missing values, duplicate keys, invalid statuses, timestamps, chronology, and table relationships.
- Treat review titles and comments as optional fields.
- Investigate unusual delivery durations and timestamp anomalies before excluding records.
- Define cancellation and late-delivery denominators explicitly.
- Exclude cancelled orders from delivered-order punctuality calculations.
- Account for missing review scores and the relationship between review records and orders.
- Calculate geographic or carrier-related KPIs only when the required source fields are available.
- Validate KPI results against the current database before publishing final metrics.

## 11. Team and Project Plan

The project team comprises Yashashvi Yash (Lead), Jaykishan Saharan, Madhupriya Naga, Katta Meghana, and Lav Kumar.

The project phases are:

1. **Week 1 — Data ingestion, validation, and initial EDA:** foundational data and analysis artifacts are available.
2. **Week 2 — KPI development and analysis:** SQL and KPI analysis artifacts are available; final consistency checks remain important.
3. **Week 3 — Delivery-delay analysis:** preliminary findings and validation outputs are documented.
4. **Week 4 — Final reporting, dashboard, and recommendations:** Member 5 documentation and presentation artifacts have been prepared on the `LavKumar` branch. Final dashboard testing, KPI export regeneration, team approval, and pull-request merge still require confirmation.

### Team responsibilities

- **Yashashvi Yash (Lead):** SQL validation, KPI definitions, and dashboard data preparation.
- **Katta Meghana:** Power BI dashboard and DAX measures.
- **Jaykishan Saharan:** carrier, regional, and delivery-stage analysis.
- **Madhupriya Naga:** cancellation analysis, customer ratings, and operational recommendations.
- **Lav Kumar:** documentation, repository integration, and final presentation.

Project completion should be confirmed only after the responsible team members verify their deliverables, reconcile the final KPI outputs, test the dashboard, and approve the final submission.

## 12. License and Attribution

The source dataset is provided by Olist through Kaggle. Review the dataset page's terms and attribution requirements before redistributing the data. The repository's own license has not yet been specified.
