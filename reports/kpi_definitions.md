\# KPI Definitions — E-commerce Delivery Logistics



\## 1. Order Volume by Status

\- \*\*Definition:\*\* Count of distinct orders grouped by order status.

\- \*\*Source:\*\* `olist\_orders\_dataset.csv`

\- \*\*Purpose:\*\* Understand order completion and operational workload.



\## 2. Delivery Duration

\- \*\*Definition:\*\* Time in days between purchase timestamp and actual customer delivery timestamp.

\- \*\*Eligible records:\*\* Delivered orders with valid purchase and delivery timestamps.

\- \*\*Purpose:\*\* Measure customer delivery speed.



\## 3. On-Time Delivery Rate

\- \*\*Definition:\*\* Percentage of eligible delivered orders where the actual delivery date is on or before the estimated delivery date.

\- \*\*Eligible records:\*\* Delivered orders with valid actual and estimated delivery timestamps.

\- \*\*Purpose:\*\* Measure delivery reliability.



\## 4. Cancellation Rate

\- \*\*Definition:\*\* Canceled distinct orders divided by all distinct orders, multiplied by 100.

\- \*\*Purpose:\*\* Monitor order cancellation levels.



\## 5. Product Category KPIs

\- \*\*Definition:\*\* Category-level distinct order count, cancellation rate, average delivery duration, and on-time delivery rate.

\- \*\*Sources:\*\* Order items, products, category translations, and orders datasets.

\- \*\*Counting rule:\*\* An order is counted once per category. Orders containing multiple categories may appear in multiple category groups.



\## 6. Small-Sample Flag

\- \*\*Definition:\*\* `small\_sample = True` when a category has fewer than 30 distinct orders.

\- \*\*Purpose:\*\* Warn readers that estimates for low-volume categories may be less stable.



\## Data Limitations

\- Missing timestamps can reduce the number of records eligible for delivery metrics.

\- Category-level order counts are not additive across categories.

\- Descriptive comparisons do not establish causation.

\- Carrier and distance comparisons require suitable, validated data.



