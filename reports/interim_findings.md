\# Week 2 — Interim Findings



\## 1. Product Category Analysis



The analysis covered 74 product categories and generated a top-15 category KPI table and visualization.



\### Key observations

\- \*\*Highest order volume:\*\* bed\_bath\_table — 9,417 distinct orders.

\- \*\*Second highest:\*\* health\_beauty — 8,836 distinct orders.

\- \*\*Third highest:\*\* sports\_leisure — 7,720 distinct orders.

\- \*\*Longest average delivery duration among the top 15:\*\* garden\_tools — 13.63 days.

\- \*\*Shortest average delivery duration among the top 15:\*\* housewares — 11.09 days.

\- \*\*Highest on-time delivery rate among the top 15:\*\* housewares — 94.64%.

\- \*\*Lowest on-time delivery rate among the top 15:\*\* baby — 91.95%.



These are descriptive comparisons and do not establish that product category causes delivery delays.



\## 2. Generated Deliverables



\- `reports/tables/kpi\_by\_category.csv`

\- `reports/figures/category\_top15\_order\_count.png`

\- `reports/limitations.md`

\- `reports/kpi\_definitions.md`



\## 3. Methodology



Order items were joined to product details and category translations, then matched to order status and delivery timestamps. Orders were counted once within each category. Delivery duration was calculated using purchase and actual delivery timestamps.



\## 4. Limitations



\- Orders containing products from multiple categories may appear in multiple category groups.

\- Missing timestamps can exclude orders from delivery metrics.

\- Category-level comparisons are descriptive, not causal.

\- Carrier and distance analyses require additional validated data.

\- Category sample sizes should be considered when interpreting results.



\## 5. Validation Still Required



\- Cross-validate key KPIs against SQL results.

\- Confirm that the team’s shared KPI dataset is generated and validated.

\- Review all team deliverables before marking Week 2 complete.





