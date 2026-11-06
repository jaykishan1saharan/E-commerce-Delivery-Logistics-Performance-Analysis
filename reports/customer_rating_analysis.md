# Customer Rating Analysis: On-Time vs. Delayed Orders

> **Status:** Candidate findings reproduced from the checked-in raw CSVs.
## 1. Objective and scope

- Compare order-level customer review scores for delivered orders classified
  as on time or delayed.
- This comparison is descriptive; it does not establish that delay caused a
  lower rating.
- Source order dates/status: `orders_stage` / `orders_clean`. Review source:
  `reviews_stage`.

## 2. Linkage and grain

- Link reviews to orders by `order_id`, not `review_id`.
- Preserve the `(order_id, review_id)` relationship. In the source,
  `review_id` is not globally unique: 789 review IDs occur against multiple
  order IDs. The existing `reviews_clean` view deduplicates on `review_id`
  alone and therefore drops valid order links; do not use that view for this
  comparison without correcting its key.
- No duplicate `(order_id, review_id)` pairs were found in the raw review
  file. There are 547 orders with multiple review rows (543 with two and four
  with three).
- Use only valid scores 1–5. Average multiple valid review scores per order
  first, then average the resulting order-level scores within each delivery
  group. Each order contributes at most once to the group mean.

## 3. Comparison population and classification

- The **eligible delivery population** includes every order with
  `order_status = 'delivered'` and both actual and estimated delivery dates
  present. Keep orders without a valid rating in this population and report
  them as unrated.
- The **rated subset** includes eligible deliveries with at least one linked
  valid review score (1–5). Calculate the order-level rating mean only from
  this subset, averaging multiple valid reviews per order first.
- Classify using **calendar dates**: delayed when
  `DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)`;
  otherwise on time. Same-day delivery is on time regardless of timestamp
  time-of-day.
- Exclude canceled, unavailable, and other non-delivered statuses; exclude
  delivered orders with either date missing from both the timeliness and
  rating comparison.
- Report eligible delivered orders, rated orders, and missing-rating orders
  for each group so the rating denominator and coverage are explicit.

## 4. Validated source-file findings

- 99,224 review rows link to 98,673 distinct orders; the remaining 768 of
  99,441 source orders have no review row. The 99,224 linked review rows all
  have nonblank IDs and valid scores from 1–5.
- The raw file has no duplicate `(order_id, review_id)` pairs, but 789 review
  IDs are linked to multiple orders. This key behavior is material to the
  order-review join and must be retained.
- Of 96,478 delivered orders, 96,470 have both delivery dates; eight lack an
  actual delivery date. There are no missing estimated dates in the source.
- Calendar-date groups among delivered orders with both dates: **89,936 on
  time** and **6,534 delayed**.
- Eligible rated-order population and mean of per-order average scores:
  - On time: 89,443 rated orders; **4.29 / 5**.
  - Delayed: 6,381 rated orders; **2.27 / 5**.
- Missing valid rating within the date-eligible groups: 493 on-time orders and
  153 delayed orders. The group mean excludes these unrated orders; report
  their counts and coverage.
- Rating coverage is 99.45% on time (89,443 / 89,936) and 97.66% delayed
  (6,381 / 6,534). The mean order-level score is 2.02 points lower among
  delayed orders; this is an association, not evidence that delay caused the
  difference.
- The candidate source-review distribution is in
  [`data/exports/week4_rating_analysis.csv`](../data/exports/week4_rating_analysis.csv).
  The linked delayed/on-time distribution and group sizes are in
  [`data/exports/week4_delay_rating_comparison.csv`](../data/exports/week4_delay_rating_comparison.csv).
- In the valid linked delivery comparison, 6,409 review records cover 6,381
  delayed rated orders; 89,944 records cover 89,443 on-time rated orders.
  Record counts exceed rated-order counts because some orders have multiple
  valid reviews. Keep both denominators visible; do not describe review-record
  percentages as order percentages.

## 5. Reporting method and limitations

- Delivery-group eligibility includes all delivered orders with both dates.
  Rating means use only the subset with linked valid scores (1–5); eligible
  orders without a valid score remain in the group-size denominator and are
  counted as unrated.
- Calendar-day classification is intentional and matches the project KPI
  definition. A delivery later in the day than an estimate on the same
  calendar date is classified as on time.
- Score distributions count valid linked review records. Group means first
  average valid review scores within each order, so every rated order has
  equal weight. The 547 multiple-review orders make these two grains distinct.
- Raw-file checks found no duplicate `(order_id, review_id)` pairs and no
  orphan review order IDs. The 789 review IDs associated with multiple
  orders are retained as separate order links.
- The clean-view definition partitions reviews by `review_id` alone. Because
  that key is not unique across orders in this source, the SQL comparison
  reads `reviews_stage` and joins on the trimmed `order_id`; do not substitute
  `reviews_clean` unless its deduplication key is corrected and validated.
- Confirm database import and cleaning reproduce raw-file coverage before
  treating these candidates as approved MySQL outputs. The group difference
  is descriptive and may reflect factors beyond delivery timeliness.
