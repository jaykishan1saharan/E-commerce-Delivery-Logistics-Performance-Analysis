
-- ============================================================
-- Project: E-commerce Delivery Logistics Performance Analysis
-- File: sql/04_kpi_queries.sql
-- Purpose: Prevent duplicate orders and preserve order-level grain
-- Database: ecommerce_delivery
-- Member 1 — Wednesday
-- ============================================================

USE ecommerce_delivery;




-- 1. SOURCE TABLE ROW COUNTS
SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'items', COUNT(*) FROM items
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;


-- 2. CHECK ORDER GRAIN BEFORE JOINING
SELECT
    COUNT(*) AS total_order_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    SUM(order_id IS NULL) AS missing_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_rows
FROM orders;


-- 3. FIND DUPLICATE ORDER IDS
SELECT
    order_id,
    COUNT(*) AS rows_per_order
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 4. CHECK CUSTOMER KEY UNIQUENESS
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 5. CHECK CHILD-TABLE CARDINALITY
-- Multiple items or reviews per order are possible.
-- These checks identify orders with multiple child rows.

SELECT
    order_id,
    COUNT(*) AS item_rows
FROM items
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS review_rows
FROM reviews
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 6. BUILD ORDER-LEVEL DATASET
-- Aggregate one-to-many tables before joining.
-- This query returns results; it does not create a table.

WITH item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_item_value,
        SUM(freight_value) AS total_freight_value
    FROM items
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score) AS average_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.total_item_value, 0) AS total_item_value,
    COALESCE(i.total_freight_value, 0) AS total_freight_value,

    r.review_count,
    r.average_review_score,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date >
             o.order_estimated_delivery_date
        THEN 1
        ELSE 0
    END AS is_late_delivery,

    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_purchase_timestamp IS NOT NULL
        THEN TIMESTAMPDIFF(
            HOUR,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        )
        ELSE NULL
    END AS delivery_hours,

    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Not delivered'
        WHEN o.order_estimated_delivery_date IS NULL
            THEN 'Missing estimate'
        WHEN o.order_delivered_customer_date >
             o.order_estimated_delivery_date
            THEN 'Late'
        ELSE 'On time'
    END AS delivery_performance

FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN review_summary AS r
    ON o.order_id = r.order_id;


-- 7. CHECK ORDER GRAIN AFTER JOINS
-- Use the same CTEs and joins as Section 6.
-- This version measures whether the join multiplies order rows.

WITH item_summary AS (
    SELECT order_id
    FROM items
    GROUP BY order_id
),
review_summary AS (
    SELECT order_id
    FROM reviews
    GROUP BY order_id
),
analytical_orders AS (
    SELECT o.order_id
    FROM orders AS o
    LEFT JOIN customers AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN item_summary AS i
        ON o.order_id = i.order_id
    LEFT JOIN review_summary AS r
        ON o.order_id = r.order_id
)
SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    SUM(order_id IS NULL) AS missing_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) -SUM(order_id is NULL)
        AS duplicate_order_rows
FROM analytical_orders;


-- 8. MISSING TIMESTAMP CHECK
SELECT
    COUNT(*) AS total_orders,
    SUM(order_purchase_timestamp IS NULL)
        AS missing_purchase_timestamp,
    SUM(order_delivered_customer_date IS NULL)
        AS missing_delivery_timestamp,
    SUM(order_estimated_delivery_date IS NULL)
        AS missing_estimated_date
FROM orders;


-- 9. DELIVERY CHRONOLOGY CHECK
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date <
      order_purchase_timestamp;
-- 9B. ADDITIONAL TIMESTAMP CHRONOLOGY CHECKS

-- Approval before purchase
SELECT COUNT(*) AS approval_before_purchase
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

-- Carrier handoff before purchase
SELECT COUNT(*) AS carrier_before_purchase
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;

-- Customer delivery before carrier handoff
SELECT COUNT(*) AS delivery_before_carrier
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

  -- 9C. ESTIMATED DELIVERY VALIDATION

SELECT COUNT(*) AS estimate_before_purchase
FROM orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp;


-- 10. DELIVERY STATUS SUMMARY
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 11. LATE DELIVERY KPI SUMMARY
SELECT
    COUNT(*) AS delivered_orders_with_dates,
    SUM(
        CASE
            WHEN order_delivered_customer_date >
                 order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_delivered_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- End of queries.
-- Record actual before/after counts and exceptions.
-- Do not claim validation passed until results are checked.
