# Data Refresh and Known Limitations

## Refresh workflow
The repository contains separate MySQL and SQLite workflows. They are not interchangeable:
- MySQL staging, audit, clean views and KPI validation are run through SQL scripts and the MySQL import script.
- SQLite analysis scripts create or use a separate SQLite database and export their own interim results.

Always record which workflow produced a given CSV or dashboard refresh.

## Known limitations and risks
- Saved reports may represent different runs or cleaning stages.
- Late-delivery figures conflict: 6,534 in the saved MySQL validation output versus 7,826 in the KPI export flag and 7,820 positive delay values.
- The order-status table has 96,478 delivered orders, while the delivered KPI export has 96,470 rows. The eight-row difference needs an explicit eligibility explanation.
- The full order population contains 2,965 missing customer-delivery timestamps in the saved audit.
- Review-score summary values differ from the deduplicated review clean-view row count; document the review grain and missing review population.
- Very long delivery durations should be investigated, not automatically deleted.
- The available source tables do not establish carrier performance unless a carrier identifier is present and validated.
- Review-score association with delivery performance is not proof of causation.

## Refresh controls
Before every refresh:
1. Confirm source files/database and snapshot date.
2. Run the data-quality audit.
3. Rebuild clean views and KPI exports.
4. Validate order grain and KPI denominators.
5. Reconcile MySQL, Python and dashboard totals.
6. Record refresh date, SQL commit and exclusions.
7. Archive or label superseded outputs to avoid mixing runs.
