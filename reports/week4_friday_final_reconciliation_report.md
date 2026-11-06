# Week 4 Friday — Final Reconciliation and Submission

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis

## Friday objective
Regenerate final regional, state, and delivery-stage exports; reconcile figures; update findings; check screenshots; and prepare the branch for team review.

## Deliverables
- `sql/11_week4_friday_final_reconciliation.sql`
- `data/exports/week4_regional_delay_analysis.csv`
- `data/exports/week4_state_delay_analysis.csv`
- `data/exports/week4_delivery_stage_analysis.csv`
- Updated `reports/regional_delay_findings.md`
- Updated `reports/carrier_performance_findings.md`
- Final screenshots and updated `docs/week4_daily_log.md`

## Final validation checklist
- [ ] Run the final SQL against the current clean views.
- [ ] Regenerate all three CSV exports from the final SQL.
- [ ] Reconcile regional and state eligible counts (check `Unknown` grouping).
- [ ] Verify late + on-time = eligible delivered.
- [ ] Recalculate late rate from counts.
- [ ] Verify valid + negative intervals = records with both timestamps for each stage.
- [ ] Confirm stage averages use valid non-negative intervals only.
- [ ] Investigate and document negative intervals.
- [ ] Confirm orders/customer join does not multiply order rows.
- [ ] Confirm carrier identity from actual schema; never use `seller_id` as carrier ID.
- [ ] Update findings using verified outputs only.
- [ ] Ensure dashboard/chart values match final CSVs.
- [ ] Update daily log, commit, push, and open/update PR to `main` for review.

## Results — populate from actual exports

### Regional findings
Paste final regional CSV output here. Identify the highest late-rate region only after checking the eligible-order denominator.

### State findings
Paste final state CSV output here. Discuss rates alongside eligible-order counts.

### Delivery-stage results
| Stage | Both timestamps | Valid intervals | Negative intervals | Average days |
|---|---:|---:|---:|---:|
| Purchase to approval | | | | |
| Approval to carrier handoff | | | | |
| Carrier handoff to customer delivery | | | | |

### Carrier decision
Record the actual `SHOW COLUMNS FROM orders_clean` result. If no genuine carrier identifier exists, state that carrier-to-carrier comparison is unavailable. The handoff timestamp is not carrier identity, and `seller_id` identifies sellers.

**Status:** This is a Friday execution template. Numerical findings and completion status must be filled only after running SQL and checking actual exports. No query execution or validation is claimed here.
