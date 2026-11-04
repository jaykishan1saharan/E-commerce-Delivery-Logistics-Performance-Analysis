# Regional Delay Findings — Week 4 (Monday & Tuesday)

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis  
**Reporting period:** Week 4 — Monday source/methodology outline and Tuesday analysis handoff  
**Status:** Preliminary. Week 3 reference figures are not yet revalidated; Week 4 regional and state results remain pending SQL execution/export.

---

## 1. Monday — Objective and initial regional reference

### 1.1 Objective
Compare order volume, eligible delivered orders, late orders, late-delivery rate, and average delivery duration by customer state and derived region.

### 1.2 Existing Week 3 reference values (not yet revalidated)

| Region | Eligible delivered orders | Late orders | Late-delivery rate |
|---|---:|---:|---:|
| Northeast | 6,951 | 990 | 14.24% |
| North | 1,376 | 133 | 9.67% |
| Central-West | 4,282 | 358 | 8.36% |
| Southeast | 50,447 | 3,715 | 7.36% |
| South | 10,528 | 744 | 7.07% |

**Interpretation limited to the existing Week 3 reference:** Northeast has the highest listed late-delivery rate (14.24%), while Southeast has the largest eligible delivered-order count (50,447). These are historical reference figures only, not confirmed Week 4 results.

### 1.3 Planned methodology
- Use one row per order for order counts.
- Join orders to customers by `customer_id` to obtain `customer_state`.
- Derive region using the state mapping already used in Week 3.
- Eligible delivered denominator: delivered orders with both actual customer-delivery and estimated-delivery timestamps.
- Late order: delivered order where actual customer-delivery timestamp is later than estimated-delivery timestamp.
- Show counts alongside rates; flag small denominators rather than ranking them without context.

### 1.4 Monday chart handoff requirements
- State-wise late-delivery rate, including eligible-order counts.
- Region-wise late-delivery rate, including late and eligible counts.
- Average delivery duration by region, with the eligible population clearly stated.

### 1.5 Monday limitations
- Region is derived from customer state, not a carrier operating region.
- Regional differences are descriptive and do not establish causes.
- Week 3 exports require SQL reconciliation before their values are presented as final.

---

## 2. Tuesday — Regional delivery analysis method and execution handoff

### 2.1 Source and grain
The Tuesday report specifies `orders_clean` joined to `customers_clean` at one row per order.

### 2.2 Method
- Region is derived from customer state using the same mapping used in Week 3.
- Total orders are distinct order IDs.
- Eligible delivered orders require delivered status plus non-null actual and estimated delivery timestamps.
- Late means actual customer delivery timestamp is later than estimated delivery timestamp.
- Late-delivery rate = late orders / eligible delivered orders × 100.
- State-level and regional results are descriptive; rates should always be shown with their denominators.

### 2.3 Regional results
**Pending:** Paste the exported result from Query 1 of `sql/09_carrier_regional_analysis.sql` here. Do not copy Week 3 values as new Week 4 results.

### 2.4 State-level observations
**Pending:** Paste the exported result from Query 2 here. Highlight high rates only alongside eligible-order counts; small populations can produce unstable percentages.

### 2.5 Initial findings status
- Highest regional late-delivery rate: **Pending SQL execution**.
- Highest-volume region: **Pending SQL execution**.
- States requiring follow-up: **Pending SQL execution and denominator review**.

### 2.6 Tuesday limitations
- Region represents customer geography, not seller or carrier location.
- The source dataset does not provide an actual carrier name/identifier in the known order fields. Seller ID is not a carrier ID.
- Results should be reconciled with Week 3 exports and the approved KPI population before final publication.

---

## 3. Combined Monday–Tuesday summary

1. The analysis is designed around one row per order, with customer state obtained through `customer_id`.
2. Region is a derived customer-geography grouping using the Week 3 state mapping.
3. Late-delivery rate must use eligible delivered orders with both actual and estimated delivery timestamps as its denominator.
4. Rates must be presented with their underlying counts; small populations should not be ranked without context.
5. The Week 3 figures are useful only as preliminary comparison references until the Week 4 SQL outputs are reconciled.
6. No Week 4 highest-performing or worst-performing region/state conclusion can yet be made from these two reports because the Tuesday SQL exports are still pending.

---

## 4. Next actions

1. Run `sql/09_carrier_regional_analysis.sql` in MySQL Workbench.
2. Export Query 1 as `data/exports/week4_regional_delay_analysis.csv`.
3. Export Query 2 as the state-level analysis CSV.
4. Paste the actual query outputs into the Regional results and State-level observations sections above.
5. Reconcile counts and denominators against the approved KPI population and Week 3 exports.
6. Update chart titles and findings only after checking the exported values.

**Report note:** This document consolidates the two supplied Monday and Tuesday regional findings files. It preserves their reported Week 3 reference figures and pending statuses; it does not invent Week 4 query results.
