# Week 2 — KPI Definitions and Analytical Data Contract

**Project:** E-commerce Delivery & Logistics Performance Analysis  
**Phase:** Week 2, Day 1  
**Owner:** Member 3 — KPI Specification  
**Status:** Draft — pending team approval and source-column verification

---

## 1. Purpose

This document defines the business meaning, calculation formulas, eligible populations, required fields, missing-data rules, and validation requirements for the project's analytical KPIs.

The objective is to ensure that SQL queries, Python calculations, analytical reports, and the eventual Power BI dashboard use consistent definitions.

No KPI should be published until its formula, denominator, source fields, and exclusions have been agreed upon.

## 2. Analytical Grain

### 2.1 Primary analytical grain

The primary delivery-performance dataset must contain exactly one row per unique order.

The order identifier is the key used to count orders and calculate order-level delivery rates.

### 2.2 Source datasets

The project uses six source datasets:

1. Customers
2. Orders
3. Order items
4. Order reviews
5. Products
6. Product-category name translations

The exact clean-view names and source-column names must be verified against the current SQL implementation.

### 2.3 Join requirements

- Orders are the primary source for order status and delivery timestamps.
- Customer data supplies customer geography.
- Order-item data must be aggregated before joining to an order-level dataset when item-level metrics are needed.
- Review data must be aggregated to the intended grain before joining to order-level data.
- Product-category analysis may use a separate order-category grain because an order can contain multiple products or categories.
- Joins must not unintentionally multiply order counts.

---

## 3. KPI Definitions

### KPI 1 — On-Time Delivery Rate

**Business question:** What percentage of eligible delivered orders reached customers on or before the estimated delivery date?

**Formula:**

On-Time Delivery Rate (%) = Eligible On-Time Delivered Orders / Eligible Delivered Orders × 100

**Numerator:** Number of unique eligible delivered orders whose actual delivery calendar date is on or before the estimated delivery calendar date.

**Denominator:** Number of unique delivered orders with both valid actual and estimated delivery dates.

**Eligibility rules:**

- The order must have delivered status.
- The actual delivery date must be present and valid.
- The estimated delivery date must be present and valid.
- The order identifier must be valid and unique in the analytical dataset.

**Exclusions and exceptions:**

- Undelivered orders are excluded.
- Orders with missing actual or estimated delivery dates are excluded from the rate denominator and reported separately.
- Invalid or duplicate order records must be resolved or explicitly documented.

**Validation rule:** Eligible on-time orders plus eligible late orders must equal the eligible delivered-order denominator.

### KPI 2 — Late-Delivery Rate

**Business question:** What percentage of eligible delivered orders arrived after the estimated delivery date?

**Formula:**

Late-Delivery Rate (%) = Eligible Late Delivered Orders / Eligible Delivered Orders × 100

**Numerator:** Number of unique eligible delivered orders whose actual delivery calendar date is after the estimated delivery calendar date.

**Denominator:** The same eligible delivered-order population used for the on-time delivery rate.

**Classification rules:**

- Actual date before estimated date: On time or early.
- Actual date equal to estimated date: On time or early.
- Actual date after estimated date: Late.
- Missing actual or estimated date: Unknown for delivery-timeliness classification.

**Validation rule:** On-time and late delivery rates should sum to 100%, subject to the same eligible population and ordinary rounding.

The number of unknown or excluded records must be reported separately.

### KPI 3 — Average Delivery Duration

**Business question:** How long does it take for an order to travel from purchase to actual customer delivery?

**Formula:**

Delivery Duration (days) = Actual Customer Delivery Timestamp − Purchase Timestamp

Average Delivery Duration = Sum of Eligible Delivery Durations / Number of Eligible Delivered Orders

**Eligible population:**

- Delivered orders with valid purchase and actual customer delivery timestamps.
- Each unique order is counted once.

**Rules:**

- Calculate elapsed time from timestamps, not merely the difference between calendar dates.
- Convert the result to days consistently.
- Missing timestamps must not be silently replaced with zero.
- Negative intervals must be flagged as invalid.
- Extreme positive durations must be investigated and documented rather than automatically deleted.

**Required outputs:**

- Average delivery duration.
- Number of eligible orders.
- Number of missing or invalid timestamp records.
- Minimum, median, and maximum duration for diagnostic analysis where useful.

### KPI 4 — Cancellation Rate

**Business question:** What percentage of valid placed orders were recorded as cancelled?

**Proposed formula:**

Cancellation Rate (%) = Cancelled Orders / Eligible Placed Orders × 100

**Numerator:** Number of unique valid orders whose final recorded status is `canceled` or the equivalent status in the verified source data.

**Proposed denominator:** All valid unique placed orders in the canonical order dataset, including cancelled orders and unavailable orders unless the team explicitly approves a different business definition.

**Rules:**

- Count unique orders, not order items.
- Document the source status values and their meanings.
- Report unavailable orders separately so that unavailable and cancelled orders are not confused.
- Exclude malformed or duplicate order records only under documented data-quality rules.
- Do not calculate the rate from delivered orders alone.

**Approval required:** The team must confirm the eligible denominator and the meaning of final order statuses against the actual source data.

### KPI 5 — Purchase-to-Carrier-Handoff Duration

**Business question:** How much time elapsed between purchase and the recorded carrier handoff?

**Formula:**

Processing-Time Proxy = Carrier Handoff Timestamp − Purchase Timestamp

**Required fields:** Purchase timestamp and carrier-handoff timestamp, using the verified source-column names.

**Eligibility rules:**

- Both timestamps must be present and valid.
- The handoff timestamp must not precede the purchase timestamp.
- The order must be counted only once.

**Interpretation:** This is a proxy for the elapsed time between purchase and carrier handoff. It must not be presented as a direct measurement of warehouse processing time because the available timestamps may not identify each internal operational stage.

**Important:** Confirm that the chosen handoff field actually represents carrier handoff. Do not assume that a shipping timestamp and a carrier-handoff timestamp are always interchangeable.

### KPI 6 — Carrier-Handoff-to-Customer-Delivery Duration

**Business question:** How much time elapsed between the recorded carrier handoff and actual customer delivery?

**Formula:**

Transit-Time Proxy = Actual Customer Delivery Timestamp − Carrier Handoff Timestamp

**Eligibility rules:**

- Both timestamps must be present and valid.
- Actual delivery must not precede carrier handoff.
- The order must have a valid delivered outcome.
- Each order is counted once.

**Interpretation:** This measures the observed elapsed interval between the available timestamps. It does not establish the exact cause of delays or identify individual carrier performance.

**Required validation:** Confirm that the source contains a suitable handoff timestamp. If not, mark this KPI unavailable rather than substituting an unrelated date.

### KPI 7 — Customer Review Analysis

**Business questions:**

- What is the distribution of customer review scores?
- Do observed review scores differ between eligible on-time and late deliveries?

**Part A — Review-score distribution**

Report the count and percentage of valid review scores for each supported score value.

For each score:

Review Score Share (%) = Reviews with That Score / Valid Reviews Included in the Distribution × 100

Document whether the distribution counts review records or unique orders.

**Part B — Delivery outcome comparison**

Compare review outcomes for eligible on-time and late delivered orders.

**Rules:**

- Confirm the score range and missing-value representation in the actual dataset.
- Do not treat missing scores as zero.
- Verify how reviews are linked to orders.
- If multiple reviews exist for one order, document the aggregation method before conducting an order-level comparison.
- Report the number of orders and reviews included in each group.
- Avoid claiming that delivery delays caused a lower score based only on a descriptive comparison.

**Proposed comparison method:** Use one documented review score per eligible order, such as the mean of valid linked scores, if multiple reviews exist. Also retain the raw review-record distribution as a separate descriptive output.

---

## 4. Shared Date and Data-Quality Rules

The following rules apply to all relevant KPIs.

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

---

## 5. Required Source-Column Mapping

The following fields are required conceptually. The exact SQL view names and column names must be verified by Member 1 against the current project.

| Concept | Purpose |
|---|---|
| Order identifier | Unique order-level counting |
| Order status | Delivery and cancellation eligibility |
| Purchase timestamp | Delivery duration and processing-time proxy |
| Estimated delivery timestamp | On-time and late classification |
| Actual delivery timestamp | Delivery outcome and elapsed duration |
| Carrier-handoff timestamp | Processing/transit analysis, if available |
| Customer identifier | Customer relationship and validation |
| Customer state or region | Geographic comparison |
| Review identifier and order relationship | Review linkage and duplication checks |
| Review score | Review distribution and delivery-outcome comparison |
| Order-item identifier and order relationship | Item aggregation and join-grain validation |
| Product identifier and category mapping | Product-category analysis |

If a required field is missing from the source, the team must document the limitation and adjust the scope rather than inventing the field.

---

## 6. SQL and Python Consistency Requirements

Member 1 is responsible for implementing the agreed analytical SQL queries.

Member 2 is responsible for implementing the corresponding Python calculations using the canonical MySQL data or verified exports.

Member 4 must validate the results.

The implementations must agree on:

- Source population and order grain.
- Status eligibility.
- Numerators and denominators.
- Missing-date treatment.
- Duplicate handling.
- Timestamp and calendar-date semantics.
- Rounding and displayed units.

Counts must match exactly for the same population. Rates and averages must match within a documented numerical tolerance.

---

## 7. Acceptance Criteria

The KPI specification is ready for implementation when:

- Every KPI has a documented business meaning and formula.
- Numerators, denominators, and eligible populations are explicit.
- Missing dates and invalid intervals have defined behavior.
- Required source fields have been mapped to actual columns.
- The primary dataset has a documented one-row-per-order grain.
- Review and item joins cannot silently multiply order counts.
- Members 1 and 2 agree to use the same definitions.
- Member 4 has clear validation rules.
- Any unavailable KPI or unresolved business definition is explicitly recorded.

---

## 8. Outstanding Decisions

The following decisions must be confirmed before the relevant calculations are finalized:

1. Actual clean-view names and column mappings.
2. The precise status values and cancellation-rate denominator.
3. Whether the source contains a suitable carrier-handoff timestamp.
4. Whether multiple reviews per order exist and the approved aggregation rule.
5. The team's approved exclusions for invalid or anomalous records.
6. The final analytical dataset name and source interface.

**Day 1 deliverable status:** KPI specification drafted. Final approval is pending source-schema verification and team agreement on outstanding definitions.