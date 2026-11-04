# Regional Delay Findings — Week 4 (Monday, Tuesday & Wednesday)

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis  
**Reporting period:** Week 4 — Monday to Wednesday  
**Status:** Consolidated methodology and findings handoff. Week 4 SQL exports and numerical results remain pending.

---

## 1. Executive Summary

This report consolidates the Monday/Tuesday regional findings report and the Wednesday regional findings report. The analysis compares order volume, eligible delivered orders, late orders, on-time orders, late-delivery rate, and delivery duration by customer state and derived region.

The regional and state-level results for Week 4 have not yet been supplied in the reports. Therefore, the Week 3 figures below are retained only as historical reference values and must not be presented as validated Week 4 results.

## 2. Monday — Objective and Initial Regional Reference

### 2.1 Objective

Compare order volume, eligible delivered orders, late orders, late-delivery rate, and average delivery duration by customer state and derived region.

### 2.2 Existing Week 3 reference values (not yet revalidated)

| Region | Eligible delivered orders | Late orders | Late-delivery rate |
|---|---:|---:|---:|
| Northeast | 6,951 | 990 | 14.24% |
| North | 1,376 | 133 | 9.67% |
| Central-West | 4,282 | 358 | 8.36% |
| Southeast | 50,447 | 3,715 | 7.36% |
| South | 10,528 | 744 | 7.07% |

**Interpretation limited to the existing Week 3 reference:** Northeast has the highest listed late-delivery rate (14.24%), while Southeast has the largest eligible delivered-order count (50,447). These are historical reference figures only, not confirmed Week 4 results.

### 2.3 Planned methodology

- Use one row per order for order counts.
- Join orders to customers by `customer_id` to obtain `customer_state`.
- Derive region using the state mapping already used in Week 3.
- Eligible delivered denominator: delivered orders with both actual customer-delivery and estimated-delivery timestamps.
- Late order: delivered order where actual customer-delivery timestamp is later than estimated-delivery timestamp.
- Show counts alongside rates; flag small denominators rather than ranking them without context.

### 2.4 Monday chart handoff requirements

- State-wise late-delivery rate, including eligible-order counts.
- Region-wise late-delivery rate, including late and eligible counts.
- Average delivery duration by region, with the eligible population clearly stated.

### 2.5 Monday limitations

- Region is derived from customer state, not a carrier operating region.
- Regional differences are descriptive and do not establish causes.
- Week 3 exports require SQL reconciliation before their values are presented as final.

## 3. Tuesday — Regional Delivery Analysis Method and Execution Handoff

### 3.1 Source and grain

Use `orders_clean` joined to `customers_clean` at one row per order.

### 3.2 Method

- Region is derived from customer state using the same mapping used in Week 3.
- Total orders are distinct order IDs.
- Eligible delivered orders require delivered status plus non-null actual and estimated delivery timestamps.
- Late means actual customer delivery timestamp is later than estimated delivery timestamp.
- Late-delivery rate = late orders / eligible delivered orders × 100.
- State-level and regional results are descriptive; rates should always be shown with their denominators.

### 3.3 Regional results

**Pending:** Populate from the exported result of Query 1 in `sql/09_carrier_regional_analysis.sql`. Do not copy Week 3 values as new Week 4 results.

### 3.4 State-level observations

**Pending:** Populate from the exported result of Query 2. Highlight high rates only alongside eligible-order counts; small populations can produce unstable percentages.

### 3.5 Initial findings status

- Highest regional late-delivery rate: **Pending SQL execution**.
- Highest-volume region: **Pending SQL execution**.
- States requiring follow-up: **Pending SQL execution and denominator review**.

### 3.6 Tuesday limitations

- Region represents customer geography, not seller or carrier location.
- The source dataset does not provide an actual carrier name/identifier in the known order fields. Seller ID is not a carrier ID.
- Results should be reconciled with Week 3 exports and the approved KPI population before final publication.

## 4. Wednesday — Consolidated Analysis Method and Results Template

### 4.1 Method

- Source: `orders_clean` joined to `customers_clean` at one row per order.
- Region is derived from customer state using the project’s Week 3 mapping.
- Eligible delivered orders require delivered status and non-null actual and estimated delivery timestamps.
- Late means actual customer delivery is later than estimated delivery.
- Late-delivery rate = late orders / eligible delivered orders × 100.

### 4.2 Regional results

Populate only from `week4_regional_delay_analysis.csv`.

| Region | Total orders | Eligible delivered | Late orders | On-time orders | Late rate (%) |
|---|---:|---:|---:|---:|---:|
| Pending SQL export | | | | | |

### 4.3 State-level findings

Populate from `week4_state_delay_analysis.csv`. Report rates alongside eligible-order counts.

### 4.4 Evidence-based observations

- Highest regional late-delivery rate: **Pending actual SQL export**.
- Highest-volume region: **Pending actual SQL export**.
- States requiring follow-up: **Pending actual SQL export and denominator review**.

## 5. Combined Monday–Wednesday Summary

1. The analysis is designed around one row per order, with customer state obtained through `customer_id`.
2. Region is a derived customer-geography grouping using the Week 3 state mapping.
3. Late-delivery rate must use eligible delivered orders with both actual and estimated delivery timestamps as its denominator.
4. Rates must be presented with their underlying counts; small populations should not be ranked without context.
5. The Week 3 figures are useful only as preliminary comparison references until Week 4 SQL outputs are reconciled.
6. No Week 4 highest-performing or worst-performing region/state conclusion can yet be made from the supplied reports because the SQL exports and actual results are still pending.
7. Regional differences are descriptive and do not establish causes.
8. Region represents customer geography, not seller or carrier location.

## 6. Limitations and Data-Quality Notes

- Week 3 reference values have not been revalidated for Week 4.
- Week 4 regional and state query results were not included in the supplied reports.
- Small eligible-order populations can produce unstable percentages; show denominators with rates.
- Reconcile Week 4 figures with the approved KPI population before final publication.
- Do not interpret regional differences as causal explanations.

## 7. Evidence and Next Actions

1. Run `sql/09_carrier_regional_analysis.sql` in MySQL Workbench.
2. Export Query 1 as `data/exports/week4_regional_delay_analysis.csv`.
3. Export Query 2 as `data/exports/week4_state_delay_analysis.csv`.
4. Populate the regional results table from the actual regional CSV.
5. Populate state-level findings from the actual state CSV.
6. Reconcile counts and denominators against the approved KPI population and Week 3 exports.
7. Update chart titles and evidence-based observations only after checking the exported values.

---

**Report note:** This document consolidates the supplied Monday/Tuesday and Wednesday regional findings reports. It preserves the Week 3 reference figures and all pending statuses. It does not invent Week 4 query results or claim that SQL exports have been executed.
