Week 2 — KPI Definitions and Analytical Data Contract
Project: E-commerce Delivery & Logistics Performance Analysis
Phase: Week 2, Day 1
Owner: Member 3 — KPI Specification
Status: Draft for team review; technical verification pending
1. Purpose
This document defines the business meaning, formulas, eligible populations, source fields, missing-data rules, and validation requirements for the project's analytical KPIs.

Its purpose is to ensure that SQL queries, Python calculations, analytical reports, and the eventual Power BI dashboard use consistent definitions.

No KPI should be published until its formula, denominator, source fields, and exclusions have been agreed upon and its implementation has been validated.
2. Analytical Grain and Source Datasets
2.1 Primary analytical grain
The primary delivery-performance dataset must contain exactly one row per unique order. The order identifier is the key used to count orders and calculate order-level delivery rates.
2.2 Source datasets
The project uses six source datasets:
1. Customers
2. Orders
3. Order items
4. Order reviews
5. Products
6. Product-category name translations
   The current SQL clean-view implementation defines the following views:
   - customers_clean
   - orders_clean
   - items_clean
   - reviews_clean
   - products_clean
   - translation_clean
2.3 Join requirements
- Orders are the primary source for order status and delivery timestamps.
- Customer data supplies customer geography.
- Order-item data must be aggregated to the appropriate grain before joining to an order-level dataset.
- Review data must be aggregated to the intended grain before joining to an order-level dataset.
- Product-category analysis may use a separate order-category grain because one order can contain multiple products or categories.
- Joins must not unintentionally multiply order counts.
- The final analytical dataset must be validated after joins, not just before joins.
3. KPI Definitions
KPI 1 — On-Time Delivery Rate
Business question: What percentage of eligible delivered orders reached customers on or before the estimated delivery date?

Formula:

On-Time Delivery Rate (%) = Eligible On-Time Delivered Orders / Eligible Delivered Orders × 100

Numerator: Number of unique eligible delivered orders whose actual delivery calendar date is on or before the estimated delivery calendar date.

Denominator: Number of unique delivered orders with valid actual and estimated delivery dates.

Eligibility rules:
- The order must have delivered status.
- The actual delivery date must be present and valid.
- The estimated delivery date must be present and valid.
- The order identifier must be valid and unique in the analytical dataset.
  Exclusions and exceptions:
- Undelivered orders are excluded.
- Orders with missing actual or estimated delivery dates are excluded from the rate denominator and reported separately.
- Invalid or duplicate order records must be resolved or explicitly documented.
  Validation rule: Eligible on-time orders plus eligible late orders must equal the eligible delivered-order denominator.
KPI 2 — Late-Delivery Rate
Business question: What percentage of eligible delivered orders arrived after the estimated delivery date?

Formula:

Late-Delivery Rate (%) = Eligible Late Delivered Orders / Eligible Delivered Orders × 100

Numerator: Number of unique eligible delivered orders whose actual delivery calendar date is after the estimated delivery calendar date.

Denominator: The same eligible delivered-order population used for the on-time delivery rate.

Classification rules:
- Actual date before estimated date: on time or early.
- Actual date equal to estimated date: on time or early.
- Actual date after estimated date: late.
- Missing actual or estimated date: unknown for delivery-timeliness classification.
  Validation rule: On-time and late delivery rates should sum to 100%, subject to ordinary rounding, because both use the same eligible population. Unknown and excluded records must be reported separately.
KPI 3 — Average Delivery Duration
Business question: How long does it take for an order to travel from purchase to actual customer delivery?

Formula:

Delivery Duration = Actual Customer Delivery Timestamp − Purchase Timestamp

Average Delivery Duration (days) = Sum of Eligible Delivery Durations in Days / Number of Eligible Delivered Orders

Source columns:
- Purchase timestamp: orders_clean.order_purchase_timestamp
- Actual customer delivery timestamp: orders_clean.order_delivered_customer_date
  Eligible population:
- Delivered orders with valid purchase and actual customer delivery timestamps.
- Each unique order is counted once.
  Rules:
- Calculate elapsed time from timestamps, not merely the difference between calendar dates.
- Convert results to days consistently.
- Missing timestamps must not be silently replaced with zero.
- Negative intervals must be flagged as invalid.
- Extreme positive durations must be investigated and documented rather than automatically deleted.
  Required outputs:
- Average delivery duration.
- Number of eligible orders.
- Number of missing or invalid timestamp records.
- Minimum, median, and maximum duration where useful for diagnostic analysis.
KPI 4 — Cancellation Rate
Business question: What percentage of valid unique orders in the canonical order dataset were recorded as cancelled?

Formula:

Cancellation Rate (%) = Cancelled Orders / All Valid Unique Orders in the Canonical Order Dataset × 100

Numerator: Number of unique valid orders whose recorded source status is exactly canceled.

Observed status count: 625 orders currently have the status canceled in orders_clean.

Denominator: All valid unique orders in the canonical order dataset, including orders with canceled and unavailable status.

Current observed denominator: 99,441 unique orders in orders_clean, with no missing order IDs. This denominator remains subject to any documented exclusions established by further data-quality validation; exclusions must not be applied silently.

Project business-rule decision: Unavailable orders remain in the denominator but are not included in the canceled-order numerator. The numerator includes only valid unique orders whose source status is exactly canceled. Do not calculate this rate using delivered orders alone. Document any later change to this definition explicitly.

Additional rules:
- Count unique orders, not order items.
- Keep unavailable orders distinct from canceled orders.
- Exclude malformed or duplicate order records only under documented data-quality rules.
KPI 5 — Purchase-to-Carrier Timestamp Duration
Business question: How much time elapsed between purchase and the recorded carrier-related timestamp?

Formula:

Purchase-to-Carrier Timestamp Duration = order_delivered_carrier_date − order_purchase_timestamp

Source columns:
- Purchase timestamp: orders_clean.order_purchase_timestamp
- Carrier-related timestamp: orders_clean.order_delivered_carrier_date
  Eligibility rules:
- Both timestamps must be present and valid.
- The carrier-related timestamp must not precede the purchase timestamp.
- The order must be counted once.
- Missing and invalid intervals must be reported separately.
  Interpretation and limitation: This measures the recorded elapsed time between purchase and the carrier-related timestamp. It is not a direct measurement of warehouse processing time and does not, by itself, prove the exact physical carrier-handoff event. Confirm the operational meaning of order_delivered_carrier_date before interpreting this KPI as a direct carrier-handoff measurement.
KPI 6 — Carrier-Timestamp-to-Customer-Delivery Duration
Business question: How much time elapsed between the recorded carrier-related timestamp and actual customer delivery?

Formula:

Carrier-to-Customer Duration = order_delivered_customer_date − order_delivered_carrier_date

Source columns:
- Carrier-related timestamp: orders_clean.order_delivered_carrier_date
- Actual customer delivery timestamp: orders_clean.order_delivered_customer_date
  Eligibility rules:
- Both timestamps must be present and valid.
- Actual customer delivery must not precede the carrier-related timestamp.
- The order must have a valid delivered outcome.
- Each order must be counted once.
- Missing and invalid intervals must be reported separately.
  Interpretation and limitation: This measures the observed elapsed interval between the available carrier-related timestamp and actual customer delivery. It is a transit-time proxy, not proof of the exact time spent physically in transit. Confirm the suitability of the carrier-related timestamp before treating this as a direct transit-time measurement.
KPI 7 — Customer Review Analysis
Business questions:
- What is the distribution of customer review scores?
- Do observed review scores differ between eligible on-time and late deliveries?
Part A — Review-score distribution
Report the count and percentage of valid review scores for each supported score value.

Formula:

Review Score Share (%) = Reviews with That Score / Valid Reviews Included in the Distribution × 100

Rules:
- Confirm the score range and missing-value representation in the actual dataset.
- Do not treat missing scores as zero.
- Count review records for the raw review-score distribution.
- Document any filters or exclusions applied.
Part B — Delivery-outcome comparison
Compare review outcomes for eligible on-time and late delivered orders.

Rules:
- Verify how reviews are linked to orders.
- Investigate multiple review records associated with the same order.
- For the order-level delivery-outcome comparison, calculate the mean of valid review scores for each order, then join that one-row-per-order review aggregate to the order-level delivery dataset.
- Preserve the original review records; do not delete records just to force one review per order.
- Report the number of orders included in each comparison group and the number of orders associated with multiple review records.
- Avoid claiming that delivery delays caused lower scores based only on a descriptive comparison.
  Observed validation finding: The current review aggregate returned 98,410 review rows with non-null order IDs and 98,096 distinct reviewed orders with non-null order IDs, a difference of 314 rows. This difference does not establish the exact number of orders affected by multiple reviews. A multiple-review query also returned orders associated with more than one review record.
Required actions:
1. Preserve the original review records.
2. Verify the number of orders affected by multiple reviews.
3. Investigate whether repeated records represent legitimate reviews or a data-quality issue.
4. Use the mean of valid review scores per order for the order-level delivery-outcome comparison, and document the aggregation in SQL and Python.
5. Do not silently delete records merely because they share an order ID.
4. Shared Date and Data-Quality Rules
The following rules apply to all relevant KPIs:
1. Missing estimated delivery dates must never be automatically classified as on time.
2. Undelivered orders must not enter on-time or late-delivery denominators.
3. Calendar-date comparison determines whether a delivery was late or on time.
4. Timestamp subtraction determines elapsed delivery durations.
5. Negative time intervals must be flagged and investigated.
6. Extreme durations must be reviewed before any exclusion is made.
7. Missing, invalid, and excluded records must be counted and documented.
8. Rates must use unique orders at the appropriate analytical grain.
9. SQL and Python implementations must use the same eligibility and exclusion rules.
10. A zero denominator must return an undefined result or a documented null, not a fabricated zero-percent rate.
11. All source status values must be mapped explicitly and documented.
12. Source data must remain unchanged; cleaning and analytical transformations must be reproducible.
13. All exclusions must be documented so that reported rates can be reconciled to the source population.
5. Required Source-Column Mapping
The following field names are present in the current sql/03_create_clean_views.sql definitions. Their presence in the SQL script is confirmed; runtime availability and suitability still need to be checked by executing the views and agreeing the final analytical dataset with Member 1.
5.1 KPI fields needed for Monday's requirements review
KPI area	Source view	Required fields	Purpose and notes
Delivery timeliness	orders_clean	order_id, order_status, order_delivered_customer_date, order_estimated_delivery_date	Compare actual and estimated calendar dates for delivered orders. Missing either date means unknown/excluded from the eligible rate denominator.
Purchase-to-customer-delivery duration	orders_clean	order_id, order_status, order_purchase_timestamp, order_delivered_customer_date	Subtract timestamps to calculate elapsed time in days. Delivered orders only; negative intervals are invalid and must be reported.
Purchase-to-carrier timestamp duration	orders_clean	order_id, order_purchase_timestamp, order_delivered_carrier_date	Measures the recorded interval to the carrier-related timestamp. Do not call this warehouse processing time or a confirmed physical handoff without operational confirmation.
Carrier timestamp to customer delivery	orders_clean	order_id, order_status, order_delivered_carrier_date, order_delivered_customer_date	Calculates the interval between the two available timestamps for delivered orders. It is a proxy, not proof of exact physical transit time.
Cancellation rate	orders_clean	order_id, order_status	Numerator: unique orders with source status exactly canceled. Denominator: all valid unique orders in the canonical order dataset under the documented project rule.
Review-score distribution	reviews_clean	review_id, order_id, review_score	Count raw valid review records by score; missing or invalid scores are not zero. The current clean view converts scores outside 1–5 to NULL.
Delivery outcome versus review score	reviews_clean + orders_clean	review_id, order_id, review_score, order-level delivery classification	Average valid review scores per order before joining to order-level delivery data. Preserve raw review rows and report multiple-review cases.
Customer geography (if used)	customers_clean	customer_id, customer_state (also customer_city if needed)	Join via the verified customer key; geography analysis is optional and must not multiply order rows.
Product/category analysis (if used)	items_clean, products_clean, translation_clean	order_id, order_item_id, product_id, product_category_name, source_category, english_category	Aggregate to an explicit order-category grain. Keep category analysis separate when an order contains multiple categories.


5.2 Verified order-view column list
Concept	Source view	Column	Current evidence/status
Order identifier	orders_clean	order_id	Runtime query previously returned 99,441 rows, 99,441 distinct IDs, and zero missing IDs. Recheck after any view changes.
Customer key	orders_clean	customer_id	Identified in the SQL view definition; relationship checks remain part of integration validation.
Order status	orders_clean	order_status	Runtime status distribution was queried; values include delivered, canceled, and unavailable.
Purchase timestamp	orders_clean	order_purchase_timestamp	Identified in the SQL view definition.
Approval timestamp	orders_clean	order_approved_at	Identified in the SQL view definition; not currently required for the seven listed KPIs.
Carrier-related timestamp	orders_clean	order_delivered_carrier_date	Identified in the SQL view definition; operational meaning needs confirmation.
Actual customer delivery timestamp	orders_clean	order_delivered_customer_date	Identified in the SQL view definition.
Estimated delivery date	orders_clean	order_estimated_delivery_date	Identified in the SQL view definition.


If a required field is unavailable or its meaning cannot be confirmed, document the limitation and adjust the KPI scope. Do not invent a field or silently substitute an unrelated timestamp.
6. SQL and Python Consistency Requirements
- Member 1 is responsible for implementing the agreed analytical SQL queries.
- Member 2 is responsible for implementing the corresponding Python calculations using the canonical MySQL database or verified exports.
- Member 4 must validate the results.
  Both implementations must agree on:
- Source population and analytical grain.
- Status eligibility.
- Numerators and denominators.
- Missing-date treatment.
- Duplicate handling.
- Timestamp and calendar-date semantics.
- Rounding and displayed units.
  Counts must match exactly for the same population. Rates and averages must match within a documented numerical tolerance.
7. Acceptance Criteria
The KPI specification is ready for implementation when:
- Every KPI has a documented business meaning and formula.
- Numerators, denominators, and eligible populations are explicit.
- Missing dates and invalid intervals have defined behavior.
- Required source fields have been mapped to actual columns.
- The primary dataset has a documented one-row-per-order grain.
- Review and item joins cannot silently multiply order counts.
- Members 1 and 2 agree to use the same definitions.
- Member 4 has clear validation rules.
- Any unavailable KPI or unresolved technical definition is explicitly recorded.
- Final team decisions are documented in this file.
8. Validation Evidence and Outstanding Technical Checks
8.1 Observed MySQL validation results — 19 October 2026
The following results were obtained from the current MySQL clean views.

Order-level dataset
Validation	Result
Total rows in orders_clean	99,441
Distinct order IDs	99,441
Missing order IDs	0


The current order view satisfies the one-row-per-order requirement for the observed order identifiers.

Observed order-status distribution
Status	Count
delivered	96,478
shipped	1,107
canceled	625
unavailable	609
invoiced	314
processing	301
created	5
approved	2
Total	99,441


The counts sum to 99,441 and match the observed row count of orders_clean.

Review-data validation
Validation	Result
Review rows with non-null order IDs	98,410
Distinct reviewed orders with non-null order IDs	98,096
Difference between these counts	314


The difference indicates additional review rows beyond the distinct reviewed-order count. It does not establish the exact number of orders affected by multiple reviews.
8.2 Outstanding technical checks
The following checks must be completed before the corresponding KPI implementations are considered technically validated:
1. Confirm the operational interpretation and suitability of the carrier-related timestamp.
2. Verify the final mapping of all customer, review, item, product, and translation fields against the clean-view definitions and actual query results.
3. Confirm the final analytical dataset name and agreed source interface between SQL and Python.
4. Verify that the documented KPI definitions produce consistent results in SQL and Python and that joins do not multiply order counts.
5. Confirm any additional record exclusions through documented data-quality validation; do not apply exclusions silently.
8.3 Implementation dependencies
- Member 1: Confirm source mappings and the analytical SQL dataset.
- Member 2: Confirm the definitions can be implemented consistently in Python using the canonical MySQL data or verified exports.
- Member 4: Validate source populations, date handling, joins, and KPI calculations.
- Member 5: Coordinate documentation and record approved team decisions.
9. Final Status
Deliverable: KPI Definitions and Analytical Data Contract
Current status: Monday KPI requirements draft prepared; team review and technical verification pending.

This Monday draft documents the proposed KPI formulas, eligible populations, numerator and denominator rules, missing-data handling, and review aggregation rule for team review. The current observed order population is 99,441 unique orders, subject to any exclusions established by documented data-quality validation.

Before the KPIs are marked as technically validated, the team must verify the remaining source-column mappings, confirm the operational interpretation of the carrier-related timestamp, validate analytical joins and the one-row-per-order grain, and reconcile SQL and Python results. Any changes to the documented business definitions must be recorded explicitly.

After team review and source-schema confirmation, the agreed definitions should be used consistently by SQL, Python, analytical reports, and the eventual Power BI dashboard.