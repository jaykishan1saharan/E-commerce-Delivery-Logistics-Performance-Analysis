# Week 4 Thursday — Regional / State / Delivery-Stage Validation

**Owner:** Jaykishan (Member 3)  
**Project:** Olist E-commerce Delivery Analysis

## Objective
Validate regional/state chart values and totals, verify delivery-stage metrics, finalize findings reports, and prepare evidence screenshots.

## Outputs to validate

| File | Validation |
|---|---|
| `week4_regional_delay_analysis.csv` | Region totals, eligible counts, late/on-time split, late rate |
| `week4_state_delay_analysis.csv` | State totals, eligible counts, late/on-time split, late rate |
| `week4_delivery_stage_analysis.csv` | Timestamp coverage, valid/negative intervals, average durations |

## Validation rules
1. Keep order-level calculations at one row per order.
2. Eligible delivered orders require delivered status and both actual and estimated customer-delivery timestamps.
3. Late = actual delivery later than estimated delivery; on-time = actual delivery earlier than or equal to estimated delivery.
4. Check `late_orders + on_time_orders = eligible_delivered_orders`.
5. Recalculate late rate as `late_orders / eligible_delivered_orders * 100`.
6. Check regional totals against state-level totals, accounting for any `Unknown` state grouping.
7. For each delivery stage, check `valid_intervals + negative_intervals = records_with_both_timestamps`.
8. Average durations should use valid non-negative intervals; report valid and negative counts.
9. Investigate negative intervals; do not silently remove them or claim the issue is resolved.
10. Confirm the orders/customer join does not multiply order rows.
11. Do not treat `seller_id` as a carrier identifier or the handoff timestamp as carrier identity.

## Results to populate after running SQL

### Regional results
Paste actual `week4_regional_delay_analysis.csv` results here. Do not reuse Week 3 values as Week 4 results.

### State-level findings
Paste actual `week4_state_delay_analysis.csv` results here. Show eligible counts with rates.

### Delivery-stage results

| Stage | Both timestamps | Valid intervals | Negative intervals | Average days |
|---|---:|---:|---:|---:|
| Purchase to approval | | | | |
| Approval to carrier handoff | | | | |
| Carrier handoff to customer delivery | | | | |

### Validation status
- Regional totals: Pending SQL run
- State totals: Pending SQL run
- Late/on-time partition: Pending SQL run
- Stage interval reconciliation: Pending SQL run
- Join grain check: Pending SQL run
- Carrier schema check: Pending SQL run

## Screenshot evidence checklist
Capture readable screenshots of:
- Regional query output.
- State query output.
- Delivery-stage output with valid and negative interval counts.
- Late/on-time partition validation.
- `SHOW COLUMNS FROM orders_clean` and relevant `items_clean` schema output.
- Final dashboard charts after confirming they match the exported CSVs.

Suggested filenames:
- `week4_thursday_regional_validation.png`
- `week4_thursday_state_validation.png`
- `week4_thursday_delivery_stage_validation.png`
- `week4_thursday_schema_check.png`
- `week4_thursday_dashboard_evidence.png`

## Thursday checklist
- [ ] Run `sql/10_week4_thursday_validation.sql` after clean views are created.
- [ ] Export fresh regional, state, and delivery-stage CSVs.
- [ ] Validate totals, denominators, and late/on-time partition.
- [ ] Validate stage interval counts and document negative intervals.
- [ ] Confirm one-row-per-order join grain.
- [ ] Verify carrier identity limitation from the actual schema.
- [ ] Update regional and carrier findings using verified outputs only.
- [ ] Capture screenshots and update the Week 4 daily log.
- [ ] Commit and push Thursday work.

**Limitation:** The database and Thursday query outputs were not supplied when this package was prepared. Results remain pending; no figures or successful validation claims have been fabricated.
