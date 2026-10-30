# Product Category Analysis — Limitations

- Categories are joined through order items, products, and the category translation file.
- An order is counted once within each category, even if it contains multiple items from that category.
- An order containing products from different categories appears in each relevant category. Therefore, category order counts must not be summed to estimate unique overall orders.
- Delivery duration uses delivered orders with valid purchase and delivery timestamps.
- On-time rate uses delivered orders with both actual and estimated delivery timestamps and compares calendar dates.
- Cancellation rate uses all orders assigned to the category as its denominator.
- Categories with fewer than 30 distinct orders are flagged as small samples.
- Missing or untranslated category names are retained as Unknown or the original category name.
- Carrier comparisons and distance-band analysis are not supported by the available files.
- These descriptive comparisons show associations, not causation.
