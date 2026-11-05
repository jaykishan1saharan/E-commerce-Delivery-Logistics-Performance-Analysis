# Power BI Dashboard User Guide

**Status: Draft — requires hands-on verification by the dashboard owner (Meghana).**

## Before opening
- Locate the current `.pbix` file in the repository's `powerbi/` folder or the confirmed dashboard artifact location.
- Record the exact file path, last commit, file size and last modified date.
- Confirm the source data location and whether the dashboard is connected to MySQL, CSV exports or another source.
- Do not assume the dashboard is refreshed because the PBIX file exists.

## Verification procedure
1. Open the PBIX in Power BI Desktop.
2. Confirm that all pages render without errors.
3. Use **Refresh** only after confirming the correct source credentials and data snapshot.
4. Record refresh completion or capture the exact error message.
5. Check KPI cards for total orders, delivered orders, late/on-time delivery and cancellations.
6. Verify KPI definitions and denominators against `KPI_definitions.md` and `kpi_reconciliation.md`.
7. Test every slicer/filter (date, region/state, order status, review score, or other available filters).
8. Confirm visuals respond consistently and totals do not multiply due to joins.
9. Check blanks, nulls and excluded records; do not display missing metrics as zero.
10. Save screenshots of every dashboard page and note the test date.

## Evidence to attach
- Screenshot of each dashboard page.
- Screenshot of refresh success or refresh error.
- Screenshot of slicers in at least two different selections.
- KPI comparison table showing dashboard values beside the approved SQL output.
- PBIX file path and commit hash.

## Sign-off
Dashboard owner: Meghana
Reviewer: Lav Kumar
Status: Pending until the steps above are completed and evidence is attached.
