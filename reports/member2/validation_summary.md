## Delivery Timestamp and Duration Validation

**Dataset:** `data/interim/kpi_orders.csv`  
**Total records:** 99,441

### Validation Results

- **Timestamp parsing:** No invalid nonblank purchase or delivery timestamps found.
- **Timestamp completeness:** 96,470 of 96,478 delivered orders have customer delivery timestamps. Eight delivered orders require investigation.
- **Missing timestamps by status:** Missing values were also identified among orders that were not delivered. Six canceled orders have delivery timestamps.
- **Negative and zero durations:** No negative or zero timestamp-derived delivery durations found.
- **Duration consistency:** All 96,476 comparable recorded durations matched calculated durations within 0.001 days.
- **Long-duration outliers:** 77 deliveries exceeded 90 days. The longest recorded duration was approximately 209.63 days. These records require further review.
- **Monthly trend impact:** Removing durations exceeding 90 days for sensitivity analysis produced the largest average reduction in March 2017: 0.79 days.
- **Monthly completeness:** Reported monthly delivery-duration completeness ranged from 99.95% to 100%.

### Output Files

- `reports/member2/monthly_delivery_validation.csv`
- `reports/member2/delivery_over_90_days.csv`
- `reports/member2/monthly_trend_impact.csv`

### Conclusion

Timestamp parsing and duration consistency checks passed. Eight delivered orders have missing delivery timestamps, and 77 unusually long delivery durations require investigation. Long-duration records influence monthly averages, particularly in March 2017. Missing-record bias has not been fully ruled out; results should be interpreted alongside completeness and sample counts.

**Overall status:** Validation executed; exceptions documented; further investigation required.