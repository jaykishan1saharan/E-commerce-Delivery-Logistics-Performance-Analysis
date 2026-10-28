## Follow-up: Delivery Timestamp and Duration Exceptions

### 1. Delivered orders with missing timestamps

Investigated 8 orders marked `delivered` with missing customer-delivery timestamps. All 8 records were found in `data/raw/olist_orders_dataset.csv`, with matching statuses and missing delivery timestamps in the processed KPI data. Seven orders have carrier-handoff timestamps; one lacks both carrier-handoff and customer-delivery timestamps. All 8 have estimated delivery dates.

**Conclusion:** The missing timestamps are present in the original source data. The actual delivery completion and reason for missing timestamps could not be independently verified. Records were retained without imputation or deletion.

### 2. Deliveries exceeding 90 days

Investigated 77 deliveries with calculated durations exceeding 90 days. All 77 orders matched the original source dataset, with zero status mismatches and zero delivery-timestamp mismatches.

The recorded delivery dates show a concentration of 24 orders on 2017-09-19. The delays beyond estimated delivery dates range from 38 to 188 days, with a mean of 106.77 days and a median of 104 days.

**Conclusion:** The long durations are consistent between the source and processed files, but their real-world validity has not been independently established. The repeated-date pattern is a potential source-data anomaly requiring further investigation. No records were removed or altered based solely on duration.

### Overall assessment

Timestamp parsing passed, and no negative or zero delivery durations were identified in the validation checks. Monthly timestamp completeness ranged from 99.95% to 100%. However, the 8 missing delivery timestamps and 77 unusually long deliveries remain documented data-quality exceptions. Delivery-duration trends should be interpreted with these limitations in mind.