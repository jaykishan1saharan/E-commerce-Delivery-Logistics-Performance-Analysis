# E-commerce Delivery & Logistics Performance Analysis

**Project status:** Week 1 — data ingestion, initial validation, data-quality review, and exploratory analysis are in progress/completed for the artifacts currently present in this repository. Weeks 2–4 are planned, not yet complete.

## 1. Project overview

This team project analyzes the Brazilian E-Commerce Public Dataset by Olist to understand order fulfilment, delivery duration, late deliveries, cancellations, customer review scores, and data-quality limitations. The current repository contains source CSV files, saved SQL audit/clean-view scripts, exported query results, data-quality documentation, four exploratory charts, and Python scripts for a small SQLite-based analysis workflow.

The analysis is descriptive. Observed associations should not be interpreted as proof of causation, and missing operational fields must not be invented.

## 2. Dataset

Source: [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

The `data/raw/` directory currently includes these six source files:

- `olist_customers_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `product_category_name_translation.csv`

Keep these source files unchanged. The full Olist dataset may include additional tables (for example, sellers and geolocation) that are not currently present in this repository snapshot.

## 3. Current project status

### Completed / available in the repository

- [x] Organized raw CSV files under `data/raw/`.
- [x] Added SQL scripts for MySQL data-quality checks and clean views.
- [x] Saved interim SQL query outputs under `data/interim/`.
- [x] Added a data dictionary, data-quality report, cleaning log, and written audit/cleaning summaries.
- [x] Saved initial EDA summary tables for order status, delivery duration, cancellation comparison, and review-score distribution.
- [x] Saved four initial visualizations under `reports/figures/`.
- [x] Added Python scripts for loading selected CSVs into SQLite, running summary queries, and exporting analysis results.
- [x] Added a reproducible environment specification in `requirements.txt`.

### Still to do / verify

- [ ] Reconcile differences between saved data-quality snapshots before using them as one final, authoritative audit. For example, `data_quality_summary.md` and `cleaning_summary.md` report different import/review row counts because they represent different saved runs/stages.
- [ ] Run the full workflow from a clean environment and verify every script end-to-end.
- [ ] Finalize and document the agreed cleaning rules and regenerate all outputs from the same database/data snapshot.
- [ ] Complete the data dictionary and ensure it matches the exact files and schemas used in the final run.
- [ ] Complete the remaining project phases: expanded KPI analysis, time/region comparisons where supported by available fields, and final recommendations/dashboard.
- [ ] Add final project conclusions only after the analysis has been rerun and reviewed.

**Important:** The repository is not yet a completed four-week project. Current reports are preliminary/interim outputs and should be treated as snapshots until regenerated and reconciled.

## 4. Current findings (preliminary)

The saved interim findings report records the following results from its analysis run:

- Total orders: **99,441**
- Delivered orders: **96,478**
- Average delivery duration: **12.56 days**
- Late deliveries: **7,826**
- Cancelled orders: **625**
- Cancellation rate: **0.63% of all orders**
- Five-star reviews were the most frequent review score.

These figures are copied from `reports/interim_findings.md`; they have not been independently recomputed as part of this README update. Check the denominator and source snapshot before treating rates as final. Very long delivery durations and timestamp anomalies should be investigated rather than removed automatically.

## 5. Repository structure

```text
E-commerce-Delivery-Logistics-Performance-Analysis/
├── data/
│   ├── raw/                     # Original Olist CSV files; do not overwrite
│   └── interim/                 # Saved SQL query outputs (CSV)
├── reports/
│   ├── data_quality/            # Audit, data dictionary, cleaning log and summaries
│   ├── figures/                 # Initial EDA charts
│   ├── tables/                  # Saved summary tables
│   └── interim_findings.md      # Preliminary findings
├── sql/
│   ├── 02_data_quality_audit.sql
│   ├── 03_create_clean_views.sql
│   ├── 05_export_cleaning_log.sql
│   └── archive/                 # Earlier/alternate SQL drafts
├── src/
│   └── scripts/
│       ├── load_data.py         # Load orders and reviews into SQLite
│       ├── run_analysis.py      # Run summary SQL queries
│       └── export_analysis_results.py  # Export tables and charts
├── requirements.txt
├── .gitignore
└── README.md
```

## 6. Environment setup

Python **3.9 or newer** is recommended. Use a virtual environment.

### macOS / Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### Windows (PowerShell)

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## 7. Run the Python analysis workflow

Run commands from the repository root (the directory containing this README):

```bash
python src/scripts/load_data.py
python src/scripts/run_analysis.py
python src/scripts/export_analysis_results.py
```

`load_data.py` currently loads the orders and reviews CSVs into `delivery_analysis.db` using Python's built-in SQLite support. `run_analysis.py` runs the summary queries against that database. `export_analysis_results.py` writes the resulting CSV tables and charts to the reports directory.

The Python workflow is separate from the MySQL audit workflow below. Do not assume the SQLite tables contain the six source tables or that running the Python scripts refreshes the MySQL query outputs.

## 8. Run the MySQL data-quality workflow

The SQL scripts target **MySQL 8.0+** and expect a database named `ecommerce_delivery` with staging tables named:

- `customers_stage`
- `orders_stage`
- `items_stage`
- `reviews_stage`
- `products_stage`
- `translation_stage`

Import the raw CSVs into these staging tables first, preserving the original files. Then run the SQL scripts in MySQL Workbench in this order:

1. `sql/02_data_quality_audit.sql` — read-only audit queries.
2. `sql/03_create_clean_views.sql` — profiling queries and creation/refresh of clean views. Review the script and schema-specific assumptions before execution.
3. `sql/05_export_cleaning_log.sql` — export current audit comparisons as a CSV using the result grid.

The clean-view approach is intended to retain staging data and make transformations traceable. Review any nonzero unresolved anomalies before final reporting. Some archived SQL files are earlier drafts and are not part of the recommended execution sequence.

## 9. Reports and visualizations

- `reports/data_quality/data_quality_summary.md` — saved data-quality audit summary.
- `reports/data_quality/cleaning_summary.md` — saved clean-view observations and follow-up items.
- `reports/data_quality/data_dictionary.csv` — field descriptions and validation notes.
- `reports/data_quality/data_quality_report.csv` — check-level results.
- `reports/data_quality/cleaning_log.csv` — saved cleaning/audit log snapshot.
- `reports/interim_findings.md` — preliminary descriptive findings.
- `reports/tables/` — saved summary tables.
- `reports/figures/` — saved exploratory charts.

The audit summary and cleaning summary currently contain different counts from different saved runs/stages. Re-run the workflow against one consistent database snapshot and update these files together before publishing final metrics.

## 10. Methodology and data-quality principles

- Preserve source CSVs and document transformations.
- Check missingness, duplicate keys, allowed status values, timestamp validity/chronology, delivery duration, and table relationships.
- Do not treat optional review comments as mandatory data.
- Do not automatically delete unusual durations or timestamp anomalies; investigate and document the decision.
- Define cancellation and late-delivery denominators explicitly. Cancelled orders must not be included in delivered-order punctuality calculations.
- Review scores may be missing and review records may not map one-to-one to orders; report the count used for each calculation.
- Only calculate geographic or carrier KPIs if the necessary source columns are actually available.

## 11. Team and project plan

The Week 1 kick-off report lists Group 3 and these team members: Yashashvi Yash (Lead), Jaykishan Saharan, Madhupriya Naga, Katta Meghana, and Lav Kumar. The planned four-week workflow is:

1. **Week 1 — Data ingestion, validation and initial EDA:** current repository focus.
2. **Week 2 — Time-series analysis and additional KPI development:** planned.
3. **Week 3 — Delivery-delay analysis/modeling, if supported by the available fields and scope:** planned.
4. **Week 4 — Final reporting, dashboard and recommendations:** planned.

Update this section as each phase is completed and merge reviewed work into the shared branch. Commit meaningful changes regularly; do not fabricate commit history or mark planned work as complete.

## 12. License and attribution

The source dataset is provided by Olist via Kaggle. Review the dataset page's terms and attribution requirements before redistribution. This repository's own license has not been specified yet.
