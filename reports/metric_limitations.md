# KPI and Metric Limitations

**Project:** E-commerce Delivery Logistics Performance Analysis  
**Updated:** 28 October 2026  
**Owner:** Member 5 — Documentation and Coordination

This log records interpretation and validation limits. It does not claim unresolved checks have passed.

## 1. On-time and late-delivery rates
- Compare calendar dates, not full timestamps.
- Include only delivered orders with valid actual and estimated delivery dates.
- Treat missing or invalid dates as unknown/excluded, not on time.
- Eligible on-time plus eligible late orders must equal the eligible delivered-order denominator.
- The two rates should sum to 100%, subject to rounding, because they share the same denominator.

**Pending:** Reconcile the latest eligible, on-time, late, and excluded counts against approved query output.

## 2. Delivery duration
- Calculate elapsed time from full timestamps and use a consistent unit of days.
- Report missing or invalid timestamps.
- Flag and exclude negative durations from averages.
- Investigate extreme positive durations before deciding whether to exclude them.

**Previously recorded preliminary results:** `reports/interim_findings.md` reports an average of 12.56 days and maximum of 209.63 days. These are not freshly validated Wednesday results.

## 3. Carrier-related intervals
- The exact operational meaning of `order_delivered_carrier_date` requires confirmation.
- Purchase-to-carrier duration is not automatically warehouse processing time.
- Carrier-to-customer duration is a proxy interval unless timestamp semantics are confirmed.
- Missing timestamps and negative intervals must be reported, not silently repaired.

## 4. Cancellation rate
- Count unique orders, not item rows.
- The numerator contains only valid unique orders whose source status is exactly `canceled`.
- Keep `unavailable` distinct and apply the documented denominator rule.
- A zero denominator produces NULL/undefined, not a fabricated 0% rate.

**Previously recorded figures:** 625 canceled orders out of 99,441 orders (approximately 0.63%) appear in existing documentation. Recheck against the latest approved output before final publication.

## 5. Customer reviews
- Review-row counts do not equal distinct reviewed-order counts.
- Existing KPI documentation records 98,410 review rows with non-null order IDs and 98,096 distinct reviewed orders, a difference of 314 rows.
- This difference does not establish the number of orders with multiple reviews.
- Preserve original records; aggregate valid review scores per order for order-level comparisons.
- Descriptive differences do not establish that delays caused lower review scores.

## 6. SQL/Python consistency and join grain
- Confirm both implementations use the same population, eligibility rules, date semantics, exclusions, units, and rounding.
- Validate the order grain after joins.
- Do not claim technical validation until counts and numerical results have been checked.

## 7. Current evidence limitations
- Wednesday commits and relevant filenames were identified for Meghana, Jaykishan, and Madhupriya.
- Code, notebook results, chart calculations, and dashboard measures still need content-level review.
- Yashashvi said her current work will be committed on 29 October; that new commit remains unconfirmed.
- Historical figures should remain labelled preliminary or previously observed until refreshed and reconciled.

## 8. Acceptance checklist
- [ ] Refresh KPI counts from the approved analytical dataset.
- [ ] Verify timestamp validity and negative-duration checks.
- [ ] Reconcile SQL and Python outputs.
- [ ] Confirm one row per order after joins.
- [ ] Inspect chart notes, notebook findings, and dashboard metric definitions.
- [ ] Update team tracking when outstanding evidence is reviewed.
