# Carrier Performance Findings — Week 4 (Monday, Tuesday & Wednesday)

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis  
**Reporting period:** Week 4 — Monday to Wednesday  
**Status:** Consolidated findings and analysis decisions. Final database schema confirmation and numerical query outputs remain pending where noted below.

---

## 1. Executive Summary

A carrier-to-carrier performance comparison is not supported by the source fields identified in the reports reviewed so far. The available `order_delivered_carrier_date` field records when an order was handed over to the carrier; it does not identify the carrier company. The `seller_id` field identifies a seller and must not be used as a carrier identifier.

The supported analysis tracks are:

- Regional and state-level delivery performance.
- Delivery-stage duration and timestamp-quality analysis.
- Seller-level analysis only if separately approved and explicitly labelled as seller-level.

No carrier rankings or carrier-performance CSV should be produced unless a genuine carrier identity field is confirmed in the active database.

## 2. Monday — Initial Source Audit

### 2.1 Source fields identified

- Carrier name / carrier identifier: **Not identified in the source files inspected so far.**
- `orders.order_delivered_carrier_date`: available; represents the carrier-handoff timestamp, not carrier identity.
- `items.seller_id`: available; identifies the seller, not the logistics carrier.

### 2.2 Monday analysis decisions

A carrier comparison should be produced only if a genuine carrier identity field is confirmed in the active MySQL database. If no such field exists, carrier comparison must be marked unavailable.

The supported alternatives are delivery-stage analysis and regional/state delivery analysis. Seller-level analysis may be considered separately if useful and clearly labelled.

### 2.3 Monday checks planned

- Confirm columns in the active MySQL schema.
- Count orders with a carrier-handoff timestamp.
- Check timestamp coverage and negative approval-to-handoff intervals.
- Record the source table, analysis population and exclusions.

### 2.4 Monday status

No carrier-performance conclusion was approved on Monday. Findings remained open pending SQL inspection and reconciliation.

## 3. Tuesday — Carrier / Seller Availability Follow-up

### 3.1 Source availability recorded

- The order data contains `order_delivered_carrier_date`, which records a carrier-handoff timestamp.
- The known order schema does not contain a carrier company name or carrier identifier.
- The order-items data contains `seller_id`, which identifies a seller, not the logistics carrier.

### 3.2 Tuesday analysis decision

A true carrier-to-carrier performance comparison is **not supported by the source fields currently identified**. Seller-level analysis must not be renamed as carrier analysis, and carrier values must not be invented.

If the team later approves a seller-level comparison:

- Label it explicitly as **seller-level**, not carrier-level.
- Aggregate item rows to one row per order before joining them to order-level delivery metrics.
- Avoid joins that multiply order counts.

### 3.3 Tuesday checks still to complete

- Confirm carrier identifier availability using the active database's `SHOW COLUMNS` output and the relevant schema-inspection query.
- Populate seller coverage from Query 4 in `sql/09_carrier_regional_analysis.sql`.
- Retain regional/state analysis and delivery-stage duration analysis as the supported alternatives.

**Important:** The Monday/Tuesday report states that final confirmation depends on running Query 4 and Query 5. Until those outputs are checked, describe carrier identity as *not identified in the inspected schema / pending final confirmation*, rather than claiming the database-wide check is complete.

## 4. Wednesday — Consolidated Analysis Direction

### 4.1 Wednesday source-field decision

The Wednesday report reiterates the following distinctions:

- `order_delivered_carrier_date` is a carrier-handoff timestamp, not carrier identity.
- `seller_id` identifies a seller, not the logistics carrier.
- Carrier rankings and carrier CSVs must not be created from seller IDs.

### 4.2 Wednesday outcome

- Carrier identifier availability must be confirmed from `SHOW COLUMNS FROM orders_clean` and the result documented.
- Supported analysis remains regional/state delivery performance and delivery-stage duration.
- Carrier comparison must be marked unavailable if no genuine carrier identifier exists.

### 4.3 Delivery-stage findings status

The Wednesday report does not provide numerical delivery-stage results. Populate this section only after checking `week4_delivery_stage_analysis.csv`, including:

- Valid record counts for each delivery stage.
- Negative interval counts for each stage.
- Average durations and the population used for each average.

Do not insert unverified figures.

## 5. Combined Conclusion After Three Days

1. A carrier-handoff timestamp is available, but it does not identify which carrier handled an order.
2. `seller_id` identifies the seller and is not a valid substitute for a carrier identifier.
3. A genuine carrier-to-carrier comparison is not supported by the fields identified in the reports so far; final confirmation from the active clean-view schema is still required.
4. Regional/state delivery performance and delivery-stage duration are the appropriate analysis tracks to continue.
5. Seller-level analysis may be considered separately, provided it is clearly labelled and item-level rows are aggregated to order level before joining.
6. No carrier ranking or carrier CSV should be published without a confirmed carrier identifier and valid supporting data.

## 6. Data-Quality Cautions

The Monday/Tuesday report notes that Week 3 reported **1,359 negative approval-to-handoff intervals**. Their timestamp semantics must be investigated before interpreting approval-to-handoff stage averages.

- Do not silently remove negative intervals.
- Document the number of negative intervals and the treatment used in each calculation.
- State the valid population and exclusions for every reported average.
- Do not treat the issue as resolved until the check is completed and recorded.
- Descriptive comparisons do not establish causation.

## 7. Evidence and Current Action Tracker

| Item | Current status | Evidence / next action |
|---|---|---|
| Carrier name or identifier | Not identified in inspected source fields; final confirmation pending | Run `SHOW COLUMNS FROM orders_clean` / Query 5 and document the actual output |
| Carrier-handoff timestamp | Identified as available | Count non-null values and document coverage |
| Seller identifier | `items.seller_id` available | Run Query 4; label any analysis seller-level |
| Regional/state analysis | Supported by identified project fields | Continue regional and state summaries and validate exported totals |
| Delivery-stage analysis | Supported where timestamps are present | Check coverage, negative intervals, valid populations and average durations |
| Negative handoff intervals | Week 3 report cited 1,359 | Investigate timestamp semantics and document treatment |
| Carrier comparison | Not currently supported | Do not publish unless a genuine carrier identifier is confirmed |

## 8. Next Steps

1. Run the schema inspection against the active database, including `SHOW COLUMNS FROM orders_clean`, and record the actual output.
2. Run Query 4 to populate seller coverage and Query 5 to inspect the clean-view schema.
3. Execute the regional/state and delivery-stage SQL queries.
4. Export and validate `week4_regional_delay_analysis.csv`, `week4_state_delay_analysis.csv`, and `week4_delivery_stage_analysis.csv`.
5. Populate numerical findings only from the verified CSV/query outputs.
6. Keep carrier comparison marked unavailable if the schema contains no genuine carrier identifier.

---

**Report note:** This document consolidates the Monday/Tuesday carrier findings report and the Wednesday carrier findings report. It preserves pending checks as pending and does not add unverified query results or claim that the database-wide schema check has been completed.
