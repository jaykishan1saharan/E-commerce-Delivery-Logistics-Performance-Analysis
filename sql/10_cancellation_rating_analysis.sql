-- =========================================================
-- Cancellation and customer-rating analysis
-- Database: ecommerce_delivery
-- Dialect: MySQL 8.0+
--
-- Grain: one row per order for order-level measures.
-- Use orders_clean for the unique order population. Read reviews_stage
-- at the (order_id, review_id) relationship grain: review_id alone is
-- not unique across orders in this source.
-- =========================================================

USE ecommerce_delivery;

-- 1. Order-status distribution. The cancellation denominator includes
--    every order in orders_clean, regardless of its status.
SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(
        100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM orders_clean), 0),
        2
    ) AS pct_of_all_orders
FROM orders_clean
GROUP BY order_status
ORDER BY order_count DESC;

-- Status-specific counts and status share of all orders, by customer state.
-- This preserves every order and assigns missing/unmatched states to Unknown.
WITH orders_by_state AS (
    SELECT
        o.order_id,
        o.order_status,
        COALESCE(NULLIF(UPPER(TRIM(c.customer_state)), ''), 'Unknown')
            AS customer_state
    FROM orders_clean AS o
    LEFT JOIN customers_clean AS c
        ON c.customer_id = o.customer_id
)
SELECT
    customer_state,
    order_status,
    COUNT(*) AS order_count,
    SUM(order_status = 'canceled') AS canceled_orders_in_status,
    ROUND(
        100.0 * COUNT(*) /
            NULLIF(SUM(COUNT(*)) OVER (PARTITION BY customer_state), 0),
        2
    ) AS pct_of_state_orders
FROM orders_by_state
GROUP BY customer_state, order_status
ORDER BY customer_state, order_count DESC, order_status;

-- Cancellation rate by customer state. Denominator is all orders assigned
-- to that state, including unavailable and non-final statuses.
WITH orders_by_state AS (
    SELECT
        o.order_status,
        COALESCE(NULLIF(UPPER(TRIM(c.customer_state)), ''), 'Unknown')
            AS customer_state
    FROM orders_clean AS o
    LEFT JOIN customers_clean AS c
        ON c.customer_id = o.customer_id
)
SELECT
    customer_state,
    COUNT(*) AS total_orders,
    SUM(order_status = 'canceled') AS canceled_orders,
    ROUND(
        100.0 * SUM(order_status = 'canceled') / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct
FROM orders_by_state
GROUP BY customer_state
ORDER BY cancellation_rate_pct DESC, total_orders DESC;

-- 2. Cancellation rate:
--    numerator = orders whose normalized status is exactly 'canceled';
--    denominator = all unique orders, including unavailable and
--    non-final statuses. 'Unavailable' is not a cancellation.
SELECT
    COUNT(*) AS total_orders,
    SUM(order_status = 'canceled') AS canceled_orders,
    ROUND(
        100.0 * SUM(order_status = 'canceled') / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct
FROM orders_clean;

-- 3. Order and delivery-date coverage. Missing actual delivery dates on
--    undelivered orders are expected; report delivered-order gaps separately.
SELECT
    order_status,
    COUNT(*) AS order_count,
    SUM(order_delivered_customer_date IS NULL) AS missing_actual_delivery_date,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_delivery_date,
    SUM(
        order_status = 'delivered'
        AND order_delivered_customer_date IS NULL
    ) AS delivered_missing_actual_date,
    SUM(
        order_status = 'delivered'
        AND order_estimated_delivery_date IS NULL
    ) AS delivered_missing_estimated_date
FROM orders_clean
GROUP BY order_status
ORDER BY order_status;

-- 4. Review source/linkage audit. Keep this check: reviews_clean currently
--    deduplicates on review_id alone, but source review IDs may link to
--    multiple orders. Do not join reviews to orders on review_id.
SELECT
    COUNT(*) AS review_rows,
    COUNT(DISTINCT review_id) AS distinct_review_ids,
    COUNT(DISTINCT order_id) AS distinct_reviewed_orders,
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(review_id IS NULL OR TRIM(review_id) = '') AS missing_review_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_score IS NOT NULL AND review_score NOT BETWEEN 1 AND 5)
        AS invalid_review_score
FROM reviews_stage;

-- Duplicate source rows at the order-review relationship grain should be
-- reconciled before using review rows in the score comparison.
SELECT
    order_id,
    review_id,
    COUNT(*) AS source_row_count
FROM reviews_stage
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
  AND NULLIF(TRIM(review_id), '') IS NOT NULL
GROUP BY order_id, review_id
HAVING COUNT(*) > 1
ORDER BY source_row_count DESC, order_id, review_id;

-- Profile review IDs linked to multiple orders. This is not a duplicate
-- order-review pair; preserve each distinct order_id/review_id relationship.
SELECT
    COUNT(*) AS review_ids_linked_to_multiple_orders
FROM (
    SELECT review_id
    FROM reviews_stage
    WHERE NULLIF(TRIM(review_id), '') IS NOT NULL
      AND NULLIF(TRIM(order_id), '') IS NOT NULL
    GROUP BY review_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS multi_order_review_ids;

-- Check for review links that do not resolve to an order.
SELECT
    COUNT(DISTINCT r.order_id) AS orphaned_review_order_ids
FROM reviews_stage AS r
LEFT JOIN orders_clean AS o
    ON o.order_id = NULLIF(TRIM(r.order_id), '')
WHERE NULLIF(TRIM(r.order_id), '') IS NOT NULL
  AND o.order_id IS NULL;

-- 4B. Review-score distribution at the source review-row grain.
SELECT
    CASE
        WHEN review_score BETWEEN 1 AND 5 THEN CAST(review_score AS CHAR)
        WHEN review_score IS NULL THEN 'missing_score'
        ELSE 'invalid_score'
    END AS score_category,
    COUNT(*) AS review_records,
    COUNT(DISTINCT NULLIF(TRIM(order_id), '')) AS distinct_orders,
    ROUND(
        100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM reviews_stage), 0),
        2
    ) AS pct_of_review_records
FROM reviews_stage
GROUP BY score_category
ORDER BY
    CASE
        WHEN score_category REGEXP '^[1-5]$' THEN CAST(score_category AS UNSIGNED)
        WHEN score_category = 'missing_score' THEN 6
        ELSE 7
    END;

-- 4C. Order-level review coverage by status. An order is covered when it has
--     at least one linked review row; this is separate from score validity.
WITH review_orders AS (
    SELECT DISTINCT NULLIF(TRIM(order_id), '') AS order_id
    FROM reviews_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
)
SELECT
    o.order_status,
    COUNT(*) AS total_orders,
    SUM(r.order_id IS NOT NULL) AS orders_with_review,
    SUM(r.order_id IS NULL) AS orders_without_review,
    ROUND(
        100.0 * SUM(r.order_id IS NOT NULL) / NULLIF(COUNT(*), 0),
        2
    ) AS review_coverage_pct
FROM orders_clean AS o
LEFT JOIN review_orders AS r
    ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY o.order_status;

-- 4D. Overall order-level average rating and review-score coverage.
--     Multiple valid review rows are averaged per order before averaging
--     across orders, so a multi-review order does not receive extra weight.
WITH review_by_order AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
      AND review_score BETWEEN 1 AND 5
    GROUP BY NULLIF(TRIM(order_id), '')
)
SELECT
    (SELECT COUNT(*) FROM orders_clean) AS total_orders,
    COUNT(r.order_id) AS orders_with_valid_rating,
    (SELECT COUNT(*) FROM orders_clean) - COUNT(r.order_id)
        AS orders_without_valid_rating,
    ROUND(AVG(r.avg_review_score), 2) AS mean_order_level_review_score,
    ROUND(
        100.0 * COUNT(r.order_id) /
            NULLIF((SELECT COUNT(*) FROM orders_clean), 0),
        2
    ) AS valid_rating_coverage_pct
FROM orders_clean AS o
LEFT JOIN review_by_order AS r
    ON r.order_id = o.order_id;

-- 5. Comparison population:
--    delivered orders with actual and estimated dates, classified by
--    calendar date (not timestamp time-of-day). Only scores 1-5 are valid.
--    Multiple valid reviews are averaged per order before group averages,
--    so each rated order contributes once to the on-time/delayed comparison.
WITH review_by_order AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        COUNT(*) AS valid_review_count,
        AVG(review_score) AS avg_review_score
    FROM reviews_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
      AND review_score BETWEEN 1 AND 5
    GROUP BY NULLIF(TRIM(order_id), '')
),
delivered_with_dates AS (
    SELECT
        order_id,
        CASE
            WHEN DATE(order_delivered_customer_date)
                 > DATE(order_estimated_delivery_date)
                THEN 'delayed'
            ELSE 'on_time'
        END AS delivery_group
    FROM orders_clean
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),
comparison_population AS (
    SELECT
        d.order_id,
        d.delivery_group,
        r.valid_review_count,
        r.avg_review_score
    FROM delivered_with_dates AS d
    LEFT JOIN review_by_order AS r
        ON r.order_id = d.order_id
)
SELECT
    delivery_group,
    COUNT(*) AS delivered_orders_with_valid_dates,
    SUM(avg_review_score IS NOT NULL) AS rated_orders,
    SUM(avg_review_score IS NULL) AS orders_without_valid_rating,
    ROUND(AVG(avg_review_score), 2) AS mean_order_level_review_score,
    ROUND(
        100.0 * SUM(avg_review_score IS NOT NULL) / NULLIF(COUNT(*), 0),
        2
    ) AS rated_order_coverage_pct
FROM comparison_population
GROUP BY delivery_group
ORDER BY delivery_group;

-- 6. Rating-score distribution among valid review records linked to
--    eligible delivered orders. The inner join and score predicate exclude
--    orphaned links, non-delivered orders, missing-date orders, and invalid
--    scores. Group sizes are included for context; review rows remain at
--    review-record grain here and are not used to calculate group means.
WITH delivered_with_dates AS (
    SELECT
        order_id,
        CASE
            WHEN DATE(order_delivered_customer_date)
                 > DATE(order_estimated_delivery_date)
                THEN 'delayed'
            ELSE 'on_time'
        END AS delivery_group
    FROM orders_clean
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
),
review_by_order AS (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
      AND review_score BETWEEN 1 AND 5
    GROUP BY NULLIF(TRIM(order_id), '')
),
group_sizes AS (
    SELECT
        d.delivery_group,
        COUNT(*) AS eligible_delivered_orders,
        SUM(r.order_id IS NOT NULL) AS rated_orders
    FROM delivered_with_dates AS d
    LEFT JOIN review_by_order AS r
        ON r.order_id = d.order_id
    GROUP BY d.delivery_group
),
valid_linked_reviews AS (
    SELECT
        d.delivery_group,
        r.order_id,
        r.review_score
    FROM delivered_with_dates AS d
    INNER JOIN reviews_stage AS r
        ON r.order_id = d.order_id
    WHERE r.review_score BETWEEN 1 AND 5
),
score_counts AS (
    SELECT
        delivery_group,
        review_score,
        COUNT(*) AS valid_review_records,
        COUNT(DISTINCT order_id) AS distinct_orders_with_score
    FROM valid_linked_reviews
    GROUP BY delivery_group, review_score
)
SELECT
    s.delivery_group,
    g.eligible_delivered_orders,
    g.rated_orders,
    g.eligible_delivered_orders - g.rated_orders
        AS orders_without_valid_rating,
    s.review_score,
    s.valid_review_records,
    s.distinct_orders_with_score,
    ROUND(
        100.0 * s.valid_review_records /
            NULLIF(SUM(s.valid_review_records) OVER (
                PARTITION BY s.delivery_group
            ), 0),
        2
    ) AS pct_valid_review_records
FROM score_counts AS s
INNER JOIN group_sizes AS g
    ON g.delivery_group = s.delivery_group
ORDER BY s.delivery_group, s.review_score;

-- End of analysis.
