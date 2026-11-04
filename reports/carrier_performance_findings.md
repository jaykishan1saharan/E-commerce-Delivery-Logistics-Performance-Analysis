# Carrier Performance Findings — Week 4

**Owner:** Jaykishan (Member 3)  
**Status:** Monday source audit / outline; no carrier-performance conclusion approved yet.

## 1. Source-field availability
- Carrier name / carrier identifier: **Not identified in the uploaded source files inspected so far.**
- `orders.order_delivered_carrier_date`: available; this is a carrier-handoff timestamp, not a carrier identity.
- `items.seller_id`: available; seller is not the delivery carrier.

## 2. Analysis decision
A carrier comparison will be produced only if the team confirms a genuine carrier identity field in the active database. Otherwise, mark carrier comparison as unavailable and use delivery-stage analysis (and seller analysis only if it can be attributed without misleading interpretation).

## 3. Planned checks
- Confirm columns in the active MySQL schema.
- Count orders with a carrier-handoff timestamp.
- Check timestamp coverage and negative approval-to-handoff intervals.
- Record the exact source table, population, and exclusions.

## 4. Findings
_To be completed after SQL execution and reconciliation._

## 5. Limitations
- A handoff timestamp does not identify the carrier.
- Seller ID must not be presented as carrier ID.
- Week 3 reported 1,359 negative carrier-handoff intervals; investigate their timestamp semantics before interpreting stage averages.
