# Final Submission Checklist

Do not mark an item complete until the corresponding file, output, or GitHub status has been verified.

## Repository and reproducibility
- [ ] README describes the actual repository structure and supported execution order.
- [ ] Raw source CSVs are preserved and not overwritten by cleaning.
- [ ] Required Python dependencies are documented and installation is tested.
- [ ] SQL scripts run in the approved order against the documented database.
- [ ] Python scripts/notebooks run with documented paths and dependencies.
- [ ] Generated outputs can be reproduced from the documented workflow.

## Data quality and metrics
- [ ] Data dictionary is present and reviewed.
- [ ] Cleaning log and data-quality summary are consistent with a fresh audit.
- [ ] Staging, clean-view, and exported row counts have been reconciled.
- [ ] Delivery KPI eligibility rules and denominators are documented.
- [ ] Late-delivery totals are reconciled across SQL, Python, and dashboard.
- [ ] Timestamp anomalies and orphan references are documented with disposition.
- [ ] Missing optional values are not presented as confirmed defects without context.

## Analysis and dashboard
- [ ] Week 3 SQL deep-analysis file exists on the intended branch.
- [ ] Validation SQL exists, has been reviewed, and passes its checks.
- [ ] Deep-analysis notebook executes from a clean kernel.
- [ ] Charts have readable labels, titles, and source/metric notes.
- [ ] Final Power BI `.pbix` file is present in the repository or its agreed delivery location.
- [ ] Dashboard guide documents pages, filters, KPIs, data source, and refresh process.
- [ ] Dashboard KPIs agree with the reconciled analysis outputs.

## Reporting
- [ ] `reports/project_summary.md` includes overview, data, metrics, findings, limitations, and conclusion.
- [ ] All reported numbers cite a reproducible query/output and use consistent definitions.
- [ ] Conflicting or unverified numbers are clearly marked as pending.
- [ ] Recommendations are supported by findings and do not claim causation without evidence.
- [ ] README links and paths have been tested.

## Week 3 Day 1 follow-up (27 October 2026)
- [ ] Lav Kumar daily log, decision log, and checklist are pushed on `LavKumar` and submitted via PR to `main`.
- [ ] Meghana confirms review/fixes for `sql/07_validation.sql` and PR status.
- [ ] Madhupriya confirms the dashboard guide and dashboard artifact and PR status.
- [ ] Jaykishan notebook presence and execution are verified.
- [ ] Yashashvi SQL analysis and baseline KPI outputs are verified.

## GitHub delivery
- [ ] Member contributions are committed on the correct branches.
- [ ] Pull requests have been reviewed and merged as required by the team.
- [ ] No unrelated SQL/Python changes are included in the documentation PR.
- [ ] Final branch and commit have been checked on GitHub.
- [ ] Team lead has approved the final submission.

## Outstanding blockers
- Reconcile the late-delivery discrepancy (7,826 in `member4_findings.md` versus 6,534 in a separate KPI validation output).
- Reconcile row-count differences between saved outputs and reports.
- Verify final Week 3 files and dashboard availability on the target branch.

## Friday Week 3 Handover Review — 30 October 2026

The following statuses reflect the Friday Git and file review. They do not replace technical testing or team-lead approval.

### Member deliverable status

- [ ] Yashashvi: confirm Friday SQL finalization, reproducible segment exports, and prioritized issue ranking.
- [ ] Meghana: review the full validation sign-off and rerun or independently verify the reported validation and sensitivity results.
- [ ] Jaykisan: execute the final notebook from a clean kernel and complete SQL-to-chart reconciliation.
- [ ] Madhupriya: confirm recommendations and Week 3 summary are integrated through the agreed workflow; reconcile dashboard KPIs with validated SQL results.
- [ ] Lav Kumar: commit and push Friday documentation and verify the final README and checklist.

### Remaining project-wide acceptance checks

- [ ] Reconcile the selected `kpi_orders.csv` population with `kpi_orders_all.csv` and other approved SQL outputs.
- [ ] Resolve or document the late-delivery discrepancy (7,826 versus 6,534) using agreed definitions and denominators.
- [ ] Confirm all KPI numerators, denominators, and eligible populations.
- [ ] Complete chart-to-SQL reconciliation and document any differences.
- [ ] Verify dashboard measures against the reconciled analysis outputs.
- [ ] Confirm operational recommendations are evidence-based and do not claim unproven causation.
- [ ] Confirm all final Week 3 reports and dashboard artifacts are on the target branch or agreed delivery location.
- [ ] Run the documented workflow and verify reproducibility.
- [ ] Obtain team-lead approval before marking the project complete.

**Handover status:** Substantial Week 3 work is committed, but final analytical reconciliation, integration checks, reproducibility, and approval remain open.
