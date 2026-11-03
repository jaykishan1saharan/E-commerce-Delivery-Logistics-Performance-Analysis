# Customer Rating Analysis: On-Time vs. Delayed Orders

> **Status:** Outline and source-data inspection. Preliminary results are
> descriptive and require validation against the imported database.

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

- Include only orders with `order_status = 'delivered'`, both actual and
  estimated delivery dates present, and at least one linked valid review
  score.
- Classify using **calendar dates**: delayed when
  `DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)`;
  otherwise on time. Same-day delivery is on time regardless of timestamp
  time-of-day.
- Exclude canceled, unavailable, and other non-delivered statuses; exclude
  delivered orders with either date missing from the timeliness comparison.
- Report eligible delivered orders, rated orders, and missing-rating orders
  for each group so the rating denominator and coverage are explicit.

## 4. Source inspection and preliminary results

- 99,224 review rows link to 98,673 distinct orders; 768 source orders have no
  review row. All review rows have an order ID and score, and all scores are in
  the 1–5 range.
- The raw file has no duplicate `(order_id, review_id)` pairs, but 789 review
  IDs are linked to multiple orders. This key behavior is material to the
  order-review join and must be retained.
- Of 96,478 delivered orders, 96,470 have both delivery dates; eight lack an
  actual delivery date. There are no missing estimated dates in the source.
- Calendar-date groups among delivered orders with both dates: **89,936 on
  time** and **6,534 delayed**.
- Preliminary rated-order population and mean of per-order average scores:
  - On time: 89,443 rated orders; **4.29 / 5**.
  - Delayed: 6,381 rated orders; **2.27 / 5**.
- Missing valid rating within the date-eligible groups: 493 on-time orders and
  153 delayed orders. The group mean excludes these unrated orders; report
  their counts and coverage.

## 5. Analysis and reporting outline

1. Validate status/date coverage, score validity, order-review orphan links,
   duplicate composite keys, and review IDs associated with multiple orders.
2. Confirm one row per order in the comparison population.
3. Present eligible and rated order counts, rating coverage, mean per-order
   score, and score distribution by delivery group.
4. Include a clear note on date-level classification, multi-review
   aggregation, missing ratings, and non-causal interpretation.
5. Replace preliminary source-file figures with validated SQL outputs and
   record the extraction date before final publication.

## 6. Limitations and open checks

- Confirm database import and cleaning reproduce source-file coverage.
- Investigate whether repeated `review_id` values across orders represent
  intentional source linkage or a source-system artifact; preserve order
  links unless the source owner specifies otherwise.
- Review score coverage may differ by delivery group; do not interpret group
  means without counts and coverage.
- Validate the date-level late rule against the project KPI definition and
  use it consistently in SQL and reporting.
