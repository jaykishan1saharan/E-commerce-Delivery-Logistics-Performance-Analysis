\# Final Validation Sign-off

\*\*Project:\*\* E-commerce Delivery \& Logistics Performance Analysis

\*\*Date:\*\* 30 October 2026

\*\*Owner:\*\* Katta Meghana — Member 2 (Delivery Logistics Validation)

\*\*Status:\*\* Evidence-based validation completed; team approval pending



\## 1. Purpose



This document records the agreed KPI definitions, completed validation checks, SQL/Python comparison results, and unresolved data-quality issues.



The sign-off distinguishes completed technical checks from outstanding investigations and team approvals.



\## 2. KPI Definition Sign-off



The following calculation rules are documented in `reports/kpi\_definitions.md`:



| KPI | Agreed definition |

|---|---|

| On-time delivery rate | Eligible on-time delivered orders / eligible delivered orders × 100 |

| Late-delivery rate | Eligible late delivered orders / eligible delivered orders × 100 |

| Average delivery duration | Average elapsed time between purchase and actual customer delivery |

| Cancellation rate | Unique canceled orders / all valid unique orders × 100 |

| Purchase-to-carrier duration | Carrier-related timestamp minus purchase timestamp |

| Carrier-to-customer duration | Actual customer delivery timestamp minus carrier-related timestamp |

| Review-score distribution | Valid review records grouped by review score |



\### Common calculation rules



\- Count unique orders at order-level grain.

\- Use calendar dates for on-time and late classification.

\- Use full timestamps for elapsed-duration calculations.

\- Exclude missing or invalid delivery dates from delivery-rate denominators and report them separately.

\- Flag and report negative durations; do not silently correct timestamps.

\- Keep unavailable orders separate from canceled orders.

\- Aggregate reviews to one row per order for delivery-outcome comparisons.

\- Return NULL/undefined when a calculation has a zero denominator.

\- Preserve original source records.



\*\*Definition status:\*\* Documented and ready for team review. Formal cross-member approval is pending.



\## 3. Validation Results



\### Source population checks



| Check | Result | Status |

|---|---:|---|

| Total source orders |99,441|PASS|

| Unique order IDs |99,441|PASS|

| Duplicate order IDs |0|PASS|

| Missing order IDs |0|PASS|

| Delivered orders |96,478|PASS|

| Canceled orders |625|PASS|



\### Delivery KPI checks



| Metric | Validated result |

|---|---:|

| Eligible delivered orders |96,470|

| On-time delivered orders |89,936|

| Late delivered orders |6,534|

| On-time delivery rate |93.23%|

| Late-delivery rate |6.77%|



The on-time and late counts reconcile to the eligible delivered population:



89,936+6,534=96,470.



\### SQL/Python comparison



The comparison in `reports/member2/sql\_python\_kpi\_comparison.csv` records nine directly compared checks with matching Python and SQL results and zero differences.



The checks cover:

\- Total orders

\- Unique order IDs

\- Duplicate order IDs

\- Missing order IDs

\- Delivered orders

\- Canceled orders

\- Late deliveries

\- On-time deliveries

\- Eligible delivered orders



The stored late-delivery flag comparison remains marked NOT INDEPENDENTLY VERIFIED.



\### Independent Python flag validation



Evidence in `reports/member2/validation\_summary.md`:



\- Rows checked:99,441.

\- `on\_time\_eligible`:96,470 expected and stored; zero mismatches.

\- `on\_time`:89,936 expected and stored; zero mismatches.



Both checks passed.



\## 4. Unresolved Data-Quality Issues



\### 4.1 Negative carrier-handoff durations



\- Flagged records:1,359.

\- The carrier delivery timestamps occur before approval timestamps.

\- This indicates a timestamp-order inconsistency.

\- The records are preserved in the source dataset.

\- Filtered KPI results are sensitivity analysis only.

\- The upstream timestamp and duration-generation logic requires investigation.



These records must not be silently corrected or described as confirmed invalid orders.



\### 4.2 Carrier timestamp interpretation



The operational meaning of `order\_delivered\_carrier\_date` requires confirmation.



Purchase-to-carrier and carrier-to-customer durations must be described as timestamp-based proxy intervals until their operational meaning is verified.



\### 4.3 Review-data duplication



\- Review rows with non-null order IDs:98,410.

\- Distinct reviewed orders:98,096.

\- Difference:314 rows.



This difference does not establish the exact number of orders with multiple reviews. The affected-order count requires a separate query.



\### 4.4 Technical integration approval



The final SQL analytical dataset, field aliases, Python loader mapping, and post-join order-grain checks require cross-member confirmation.



\### 4.5 Stored late-delivery flags



The existing comparison file does not independently verify `late\_deliveries\_existing\_flags`. The matching SQL calendar-date result must not be represented as an independent validation of that stored flag.



\## 5. Sensitivity Analysis



The existing validation report records:



| Metric | All source rows | Filtered population |

|---|---:|---:|

| Total orders |99,441|98,082|

| Delivered |96,478|95,128|

| Eligible delivered |96,470|95,120|

| On-time |89,936|88,610|

| Late |6,534|6,510|

| On-time rate |93.23%|93.16%|

| Late rate |6.77%|6.84%|



The filtered population excludes flagged rows and is presented only to demonstrate sensitivity to data-quality exclusions. It is not a replacement for the original source population or an automatically approved reporting baseline.



\## 6. Final Validation Decision



\*\*Completed:\*\*

\- KPI business definitions documented.

\- Eligibility and exclusion rules documented.

\- Source order ID uniqueness checks passed.

\- SQL/Python KPI comparison passed for nine directly compared metrics.

\- Independent Python on-time flag validation passed.

\- Sensitivity analysis documented.

\- Unresolved quality issues identified and disclosed.



\*\*Pending:\*\*

\- Investigation of 1,359 negative carrier-handoff durations.

\- Confirmation of carrier timestamp semantics.

\- Investigation of multiple-review orders.

\- Final SQL/Python schema and integration confirmation.

\- Independent verification of the stored late-delivery flag.

\- Formal team-lead and cross-member approval.



\## 7. Sign-off Statement



The available evidence supports the documented order-level validation results and the specified delivery KPI calculations.



This is a technical validation record, not a declaration that every source-data issue has been resolved or that every team member has approved the final definitions.



Unresolved issues remain explicitly documented. Original records have not been silently altered to force KPI agreement.



\*\*Prepared by:\*\* Katta Meghana

\*\*Role:\*\* Member 2 — Delivery Logistics Validation

\*\*Date:\*\* 30 October 2026

\*\*Technical status:\*\* Validation evidence documented; final team approval pending.



\*\*Reference documents:\*\*

\- `reports/kpi\_definitions.md`

\- `reports/validation\_report.md`

\- `reports/member2/validation\_summary.md`

\- `reports/member2/sql\_python\_kpi\_comparison.csv`

\- `reports/member2/flag\_validation.csv`
