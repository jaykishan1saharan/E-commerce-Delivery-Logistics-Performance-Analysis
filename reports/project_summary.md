# Project Summary — E-commerce Delivery & Logistics Performance Analysis

## 1. Overview

This project analyzes the Brazilian E-Commerce Public Dataset by Olist to understand order fulfilment, delivery performance, late deliveries, cancellations, customer reviews, and data-quality limitations.

The project uses Python, SQL, SQLite, MySQL, statistical analysis, and Power BI to examine logistics performance and identify operational improvement opportunities.

## 2. Data Sources and Workflow

The repository contains six primary source CSV files under `data/raw/`:

- Orders
- Customers
- Order items
- Order reviews
- Products
- Product category translations

The workflow includes data ingestion, quality audits, SQL cleaning views, KPI generation, statistical analysis, visualizations, and dashboard reporting.

Original source files should remain unchanged. MySQL and SQLite workflows are separate and their outputs should not be assumed identical without matching schemas, filters, and data snapshots.

## 3. Validated Delivery KPI Results

The following results were independently validated using the SQLite KPI workflow and calendar-date delivery classification:

| Metric | Validated result |
|---|---:|
| Total unique orders | 99,441 |
| Delivered-status orders | 96,478 |
| Eligible delivered orders | 96,470 |
| Delivered orders missing actual delivery dates | 8 |
| On-time or early deliveries | 89,936 |
| Late deliveries | 6,534 |
| On-time/early rate | 93.23% |
| Late-delivery rate | 6.77% |

The eligible population excludes delivered-status orders with missing actual delivery dates.

**Delivery classification:** A delivery is on time when its actual delivery calendar date is earlier than or equal to its estimated delivery calendar date. `delay_days` is calculated using calendar dates. Missing dates are retained as unknown rather than treated as on-time or late.

## 4. Customer Review and Late-Delivery Analysis

Review scores were aggregated at order level using the average of valid scores between 1 and 5.

The latest statistical analysis reported:

| Metric | Result |
|---|---:|
| Mean review score — on-time/early | 4.2906 |
| Mean review score — late | 2.2718 |
| Mann–Whitney U statistic | 467,426,830.5 |
| Chi-square statistic | 15,384.20 |
| Chi-square degrees of freedom | 2 |
| Cramer's V | 0.4007 |
| Statistical test p-values | < 0.001 |

The analysis indicates a statistically significant association between delivery timeliness and customer review scores in this dataset. It does not establish that delivery delay alone caused lower ratings.

## 5. Week 3 Regional and State Export Discrepancy

The saved regional and state exports agree with each other but differ from the independently validated KPI population.

| Metric | Canonical KPI | Week 3 exports |
|---|---:|---:|
| Total orders | 99,441 | 75,840 |
| Eligible delivered orders | 96,470 | 73,584 |
| Late deliveries | 6,534 | 5,940 |
| Late-delivery rate | 6.77% | 8.07% |

The difference remains unresolved. The analysis owner should confirm the source population, filters, date calculation, and eligibility rules before the regional/state figures are treated as reconciled.

## 6. Other Reported Findings

Earlier saved artifacts report:

- 625 cancellations (0.63% of all orders).
- Average delivery duration of 12.56 days.
- Maximum delivery duration of 209.63 days.

These figures are retained as previously reported findings and should be checked against the final approved analysis outputs before being treated as freshly verified.

## 7. Dashboard and Presentation Status

- The Power BI dashboard file `powerbi/Olist_Logistics_Dashboard.pbix` is present on `origin/main`.
- Its file blob is identical to the version on `origin/fix-validation-script-structure`.
- Dashboard opening, refresh, slicer testing, and KPI reconciliation have not been independently verified here.
- The final presentation file is present at `presentation/QVETO_Technologies_Olist_Ecommerce_Logistics_Final_Presentation.pptx`.
- The presentation outline records 17 slides; slide-by-slide content review remains pending.

## 8. Limitations and Open Items

1. Reconcile the Week 3 regional/state exports with the canonical KPI population.
2. Obtain dashboard-owner evidence for PBIX opening, refresh, filters, and KPI comparisons.
3. Review the final presentation slides against approved findings.
4. Confirm that the documented workflows can be reproduced using the approved environment and database.
5. Obtain analysis-owner and team-lead confirmation of the final metrics.
6. Complete the documentation PR and verify its merge into `main`.

## 9. Conclusion

The project contains data-ingestion workflows, SQL and Python analysis, validated delivery KPIs, statistical review analysis, dashboard artifacts, and final presentation documentation.

The independently validated delivery KPI and review-analysis results provide a useful basis for understanding logistics performance. However, the Week 3 regional/state discrepancy, dashboard functional verification, reproducibility checks, and team sign-off remain open.

**Project status: Substantial implementation and documentation completed; final acceptance and submission checks pending.**

**Documentation and coordination:** Lav Kumar — Member 5.
