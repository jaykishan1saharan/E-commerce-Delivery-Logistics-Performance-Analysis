# Project Decision Log

**Project:** E-commerce Delivery & Logistics Performance Analysis

This log records confirmed choices and unresolved questions that affect analysis or reporting. Do not mark a proposal as an approved decision until the team confirms it.

| ID | Decision / question | Rationale / impact | Status | Owner / next action |
|---|---|---|---|---|
| D-01 | Preserve original source CSV files in `data/raw/`. | Protects source data and makes the workflow reproducible. | Existing project practice | All members |
| D-02 | Use SQL clean views for cleaning rather than modifying source files. | Preserves imported staging data and makes cleaning logic inspectable. | Documented in cleaning summary | SQL owner to reconfirm current workflow |
| D-03 | Define the eligible order population for delivery KPIs. | On-time and late-delivery rates depend on the denominator and valid timestamps. | Needs team confirmation | SQL/KPI owner |
| D-04 | Reconcile different reported late-delivery totals before final reporting. | `member4_findings.md` reports 7,826 late deliveries; a separate KPI validation output reported 6,534. | Open | Compare query logic, filters, snapshot, and denominator |
| D-05 | Reconcile row counts across staging, cleaning outputs, and saved CSV snapshots. | Existing reports contain different counts, which may reflect different runs or stages. | Open | Rerun approved SQL workflow and update reports |
| D-06 | Keep timestamp anomalies and orphan references visible until validated. | Correcting or deleting records without evidence could distort results. | Documented in cleaning summary | SQL/data-quality owner |
| D-07 | Mark a task complete only after the artifact and review status are verified. | Prevents chat updates from being mistaken for merged or tested work. | Documentation rule | Documentation owner / team lead |
| D-08 | Publish final dashboard and recommendations only after cross-checking KPIs. | Avoids contradictions between SQL, Python, reports, and Power BI. | Open | Dashboard and analysis owners |

## Change history
Add new entries with date, decision, reason, owner, and evidence. If a decision changes, retain the previous entry and add a superseding entry rather than silently deleting history.


## Week 4 decisions

| ID | Decision / issue | Rationale / impact | Status | Owner / next action |
|---|---|---|---|---|
| W4-01 | Keep `canceled` and `unavailable` as separate statuses. | They represent different source outcomes. | Confirmed for reporting | Analysis team |
| W4-02 | Use one row per `order_id` for order-level delivery KPIs. | Prevents item and review joins from multiplying orders. | Required validation | SQL / KPI owner |
| W4-03 | Use 6,534 late deliveries (6.77%) for the reviewed raw-data snapshot. | Matches the saved MySQL validation and raw-source calculation. | Validated for this snapshot | SQL / KPI owner |
| W4-04 | Regenerate `kpi_orders.csv` before dashboard use. | Existing exported late flags do not match the validated result. | Pending | SQL / KPI owner |
| W4-05 | Reconcile review summaries before dashboard sign-off. | Exploratory output and clean review view differ. | Pending | Review analysis owner |
| W4-06 | Avoid unsupported carrier-level claims. | Carrier performance requires a validated carrier field and analysis output. | Pending evidence | Carrier analysis owner |
| W4-07 | Test the PBIX by opening, refreshing and checking pages and slicers. | File presence alone does not prove dashboard functionality. | Pending | Dashboard owner |
