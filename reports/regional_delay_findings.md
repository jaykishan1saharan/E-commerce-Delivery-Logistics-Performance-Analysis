# Regional Delay Findings — Week 4

**Owner:** Jaykishan (Member 3)  
**Status:** Monday outline; Week 3 values below are preliminary reference values pending Week 4 SQL reconciliation.

## 1. Objective
Compare order volume, eligible delivered orders, late orders, late-delivery rate, and average delivery duration by customer state and derived region.

## 2. Existing Week 3 reference (not yet revalidated)
| Region | Eligible delivered orders | Late orders | Late-delivery rate |
|---|---:|---:|---:|
| Northeast | 6,951 | 990 | 14.24% |
| North | 1,376 | 133 | 9.67% |
| Central-West | 4,282 | 358 | 8.36% |
| Southeast | 50,447 | 3,715 | 7.36% |
| South | 10,528 | 744 | 7.07% |

## 3. Planned methodology
- Use one row per order for order counts.
- Join orders to customers by `customer_id` to obtain `customer_state`.
- Derive region using the state mapping already used in Week 3.
- Eligible delivered denominator: delivered orders with both actual customer-delivery and estimated-delivery timestamps.
- Late order: delivered order where actual customer-delivery timestamp is later than estimated-delivery timestamp.
- Show counts alongside rates; flag small denominators rather than ranking them without context.

## 4. Week 4 findings
_To be completed after running `sql/09_carrier_regional_analysis.sql` and reconciling with the approved KPI population._

## 5. Chart handoff
- State-wise late-delivery rate (include eligible-order counts).
- Region-wise late-delivery rate (include late and eligible counts).
- Average delivery duration by region, with a clearly stated eligible population.

## 6. Limitations
- Region is derived from customer state, not a carrier operating region.
- Regional differences are descriptive and do not establish causes.
- Week 3 exports require SQL reconciliation before their values are presented as final.
