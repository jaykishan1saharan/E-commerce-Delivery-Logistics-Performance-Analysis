
# Baseline Data Quality Validation Test

## Validation file
`sql/07_validation.sql`

## Checks performed
- [ ] Row counts for staging and clean orders
- [ ] Missing and duplicate order IDs
- [ ] Unique order ID count
- [ ] Missing key timestamps for delivered orders
- [ ] Order status distribution

## Baseline expectations
- Total clean orders: 99,441
- Unique order IDs: 99,441
- Missing order IDs: 0
- Duplicate order IDs: 0
- Delivered orders: 96,478
- Canceled orders: 625

## Test results
Record actual SQL outputs and mark each check PASS or INVESTIGATE.

## Status
Pending execution against the project database.
