# Project Decision Log

**Project:** E-commerce Delivery Logistics Performance Analysis  
**Updated:** 28 October 2026  
**Owner:** Member 5 — Documentation and Coordination

## D-001 — Order-level analytical grain
Use one validated row per unique order for order-level KPIs. Aggregate item and review data to the intended grain before joining. Verify uniqueness after joins.

**Status:** Defined in existing KPI documentation; implementation still requires verification.

## D-002 — Timeliness versus duration
Compare calendar dates for on-time/late classification. Use full timestamp subtraction for elapsed durations.

**Status:** Defined; SQL/Python consistency needs verification.

## D-003 — Missing dates and invalid intervals
Missing or invalid delivery dates produce unknown timeliness and are excluded from the eligible rate denominator. Negative duration intervals must be flagged, reported, and excluded from duration averages.

**Status:** Defined; latest execution evidence pending.

## D-004 — Cancellation and unavailable statuses
Count source status exactly equal to `canceled` in the numerator. Keep `unavailable` distinct and follow the documented denominator rule.

**Status:** Defined; confirm against approved implementation.

## D-005 — Carrier-related timestamps
Treat purchase-to-carrier and carrier-to-customer intervals as recorded timestamp intervals. Do not describe them as confirmed warehouse processing or physical transit measurements without operational confirmation.

**Status:** Timestamp semantics remain to be confirmed.

## D-006 — Review aggregation
Preserve source review records. Use valid review records for score distributions and aggregate valid review scores per order for order-level comparisons. Investigate multiple reviews per order.

**Status:** Defined; exact affected-order count remains to be queried.

## D-007 — Evidence and acceptance
A commit or filename establishes that a change was committed, not that the analysis is correct. Review code, outputs, and dashboard calculations separately.

**Status:** Applied to the Wednesday review.

## D-008 — Documentation workflow
Make this documentation update on `LavKumar`, then submit it through a pull request to `main`. Do not merge entire member branches for this task.

**Status:** Current workflow decision.
