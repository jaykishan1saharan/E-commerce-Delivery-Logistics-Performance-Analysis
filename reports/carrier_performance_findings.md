# Carrier Performance Findings — Week 4 (Monday & Tuesday)

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis  
**Reporting period:** Week 4 — Monday source audit and Tuesday follow-up  
**Status:** Preliminary source inspection; final schema confirmation and query outputs are still required.

---

## 1. Monday — Source audit and initial outline

### 1.1 Source-field availability observed
- Carrier name / carrier identifier: **Not identified in the uploaded source files inspected so far.**
- `orders.order_delivered_carrier_date`: available; this is a carrier-handoff timestamp, not a carrier identity.
- `items.seller_id`: available; this identifies a seller and must not be treated as the delivery carrier.

### 1.2 Monday analysis decision
A carrier comparison should be produced only if a genuine carrier identity field is confirmed in the active MySQL database. If no such field exists, carrier comparison must be marked unavailable. The supported alternatives are delivery-stage analysis and, only if useful and clearly labelled, seller-level analysis.

### 1.3 Monday checks planned
- Confirm the columns in the active MySQL schema.
- Count orders with a carrier-handoff timestamp.
- Check timestamp coverage and negative approval-to-handoff intervals.
- Record the source table, analysis population and exclusions.

### 1.4 Monday findings status
No carrier-performance conclusion was approved on Monday. Findings were left open until SQL inspection and reconciliation.

---

## 2. Tuesday — Carrier / seller data availability follow-up

### 2.1 Source availability recorded
- The order data contains `order_delivered_carrier_date`, which records a carrier-handoff timestamp.
- The known source order schema does not contain a carrier company name or carrier identifier.
- The order-items data contains `seller_id`. This identifies a seller, not the logistics carrier.

### 2.2 Tuesday analysis decision
A true carrier-to-carrier performance comparison is **not supported by the source fields currently identified**. Do not rename seller-level analysis as carrier analysis and do not invent carrier values.

If the team later approves a seller-level comparison:
- Label it explicitly as **seller-level**, not carrier-level.
- Aggregate item rows to one row per order before joining them to order-level delivery metrics.
- Avoid joins that multiply order counts.

### 2.3 Tuesday checks still to complete
- Confirm carrier identifier availability using the active database's `SHOW COLUMNS` output and the relevant SQL inspection query.
- Populate seller coverage from Query 4 in `sql/09_carrier_regional_analysis.sql`.
- Retain regional/state analysis and delivery-stage duration analysis as the supported alternatives.

**Important:** The Tuesday report itself says final confirmation depends on running Query 4 and Query 5. Until those outputs are checked, describe carrier identity as *not identified in the inspected schema / pending final confirmation*, rather than claiming the database-wide check is complete.

---

## 3. Combined conclusion after Monday and Tuesday

Based on the source inspection documented across the two daily reports:

1. A carrier-handoff timestamp is available, but it does not identify which carrier handled an order.
2. `seller_id` identifies the seller and is not a valid substitute for a carrier identifier.
3. A genuine carrier-to-carrier comparison is not currently supported by the identified fields.
4. Regional/state delivery performance and delivery-stage duration are the appropriate analysis tracks to continue.
5. Seller-level analysis may be considered separately, provided it is clearly labelled and item-level rows are aggregated to order level before joining.

---

## 4. Data-quality caution

The Monday report notes that Week 3 reported **1,359 negative carrier-handoff intervals**. Their timestamp semantics must be investigated before interpreting approval-to-handoff stage averages. Do not silently remove these records or treat the issue as resolved without documenting the check, exclusions and impact.

---

## 5. Evidence and next actions

| Item | Current status | Evidence / next action |
|---|---|---|
| Carrier name or identifier | Not identified in inspected source fields | Verify with `SHOW COLUMNS` and Query 5 |
| Carrier-handoff timestamp | Available | Count non-null values and document coverage |
| Seller identifier | `items.seller_id` available | Query 4; label any analysis seller-level |
| Regional/state analysis | Supported by identified project fields | Continue regional and state summaries |
| Delivery-stage analysis | Supported where timestamps are present | Check coverage, negative intervals and valid populations |
| Negative handoff intervals | Week 3 reported 1,359 | Investigate timestamp semantics and document treatment |

### Next steps for Jaykishan
1. Run the relevant schema inspection plus Query 4 and Query 5 from `sql/09_carrier_regional_analysis.sql`.
2. Record the actual outputs and date/population scope in this report.
3. Continue regional/state and delivery-stage calculations.
4. Do not publish a carrier comparison unless a genuine carrier identifier is confirmed.

---

**Report note:** This document consolidates the Monday and Tuesday carrier-performance source reports. It does not add unverified query results or claim that pending checks have been completed.
