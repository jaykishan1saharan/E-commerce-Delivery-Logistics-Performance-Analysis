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
