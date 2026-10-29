-- KPI validation using materialized temporary tables.

-- ============================================================
-- Project: E-commerce Delivery Logistics Performance Analysis
-- File: sql/04_kpi_queries.sql
-- Purpose: Validate order grain, timestamps, and delivery KPIs
-- Database: ecommerce_delivery
-- ============================================================

USE ecommerce_delivery;

-- Materialize expensive clean views once per session.
DROP TEMPORARY TABLE IF EXISTS tmp_customers;
DROP TEMPORARY TABLE IF EXISTS tmp_orders;
DROP TEMPORARY TABLE IF EXISTS tmp_items;
DROP TEMPORARY TABLE IF EXISTS tmp_reviews;

CREATE TEMPORARY TABLE tmp_customers AS
SELECT * FROM customers_clean;

CREATE TEMPORARY TABLE tmp_orders AS
SELECT * FROM orders_clean;

CREATE TEMPORARY TABLE tmp_items AS
SELECT * FROM items_clean;

CREATE TEMPORARY TABLE tmp_reviews AS
SELECT * FROM reviews_clean;

CREATE INDEX idx_tmp_customers_id ON tmp_customers(customer_id(32));
CREATE INDEX idx_tmp_orders_id ON tmp_orders(order_id(32));
CREATE INDEX idx_tmp_orders_customer ON tmp_orders(customer_id(32));
CREATE INDEX idx_tmp_items_order ON tmp_items(order_id(32));
CREATE INDEX idx_tmp_reviews_order ON tmp_reviews(order_id(32));

-- 1. SOURCE TABLE ROW COUNTS
SELECT 'orders' AS table_name, COUNT(*) AS row_count
FROM tmp_orders
UNION ALL
SELECT 'customers', COUNT(*) FROM tmp_customers
UNION ALL
SELECT 'items', COUNT(*) FROM tmp_items
UNION ALL
SELECT 'reviews', COUNT(*) FROM tmp_reviews;


-- 2. CHECK ORDER GRAIN BEFORE JOINING
SELECT
    COUNT(*) AS total_order_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COALESCE(SUM(order_id IS NULL), 0) AS missing_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        - COALESCE(SUM(order_id IS NULL), 0)
        AS duplicate_order_rows
FROM tmp_orders;


-- 3. FIND DUPLICATE ORDER IDS
SELECT
    order_id,
    COUNT(*) AS rows_per_order
FROM tmp_orders
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 4. CHECK CUSTOMER KEY UNIQUENESS
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM tmp_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 5. CHECK CHILD-TABLE CARDINALITY
-- Multiple items or reviews per order can be valid.

SELECT
    order_id,
    COUNT(*) AS item_rows
FROM tmp_items
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    order_id,
    COUNT(*) AS review_rows
FROM tmp_reviews
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
    FROM tmp_items
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score) AS average_review_score
    FROM tmp_reviews
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
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN
            CASE
                WHEN DATE(o.order_delivered_customer_date) >
                     DATE(o.order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        ELSE NULL
    END AS is_late_delivery,

    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_customer_date >=
             o.order_purchase_timestamp
        THEN TIMESTAMPDIFF(
            SECOND,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        ) / 86400.0
        ELSE NULL
    END AS delivery_days,

    CASE
        WHEN o.order_status <> 'delivered'
          OR o.order_status IS NULL
            THEN 'Not delivered'
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL
            THEN 'Unknown'
        WHEN DATE(o.order_delivered_customer_date) >
             DATE(o.order_estimated_delivery_date)
            THEN 'Late'
        ELSE 'On time'
    END AS delivery_performance

FROM tmp_orders AS o
LEFT JOIN tmp_customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN review_summary AS r
    ON o.order_id = r.order_id;


-- 7. CHECK ORDER GRAIN AFTER JOINS
-- Aggregation prevents item/review multiplicity from multiplying orders.

WITH item_summary AS (
    SELECT order_id
    FROM tmp_items
    GROUP BY order_id
),
review_summary AS (
    SELECT order_id
    FROM tmp_reviews
    GROUP BY order_id
),
analytical_orders AS (
    SELECT o.order_id
    FROM tmp_orders AS o
    LEFT JOIN tmp_customers AS c
        ON o.customer_id = c.customer_id
    LEFT JOIN item_summary AS i
        ON o.order_id = i.order_id
    LEFT JOIN review_summary AS r
        ON o.order_id = r.order_id
)
SELECT
    COUNT(*) AS joined_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COALESCE(SUM(order_id IS NULL), 0) AS missing_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        - COALESCE(SUM(order_id IS NULL), 0)
        AS duplicate_order_rows
FROM analytical_orders;


-- 8. MISSING TIMESTAMP CHECK
SELECT
    COUNT(*) AS total_orders,
    COALESCE(SUM(order_purchase_timestamp IS NULL), 0)
        AS missing_purchase_timestamp,
    COALESCE(SUM(order_delivered_customer_date IS NULL), 0)
        AS missing_delivery_timestamp,
    COALESCE(SUM(order_estimated_delivery_date IS NULL), 0)
        AS missing_estimated_date
FROM tmp_orders;


-- 9. DELIVERY CHRONOLOGY CHECKS

SELECT COUNT(*) AS invalid_delivery_dates
FROM tmp_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date <
      order_purchase_timestamp;

SELECT COUNT(*) AS approval_before_purchase
FROM tmp_orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

SELECT COUNT(*) AS carrier_before_purchase
FROM tmp_orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;

SELECT COUNT(*) AS delivery_before_carrier
FROM tmp_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

SELECT COUNT(*) AS estimate_before_purchase
FROM tmp_orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_estimated_delivery_date < order_purchase_timestamp;


-- 10. DELIVERY STATUS SUMMARY
SELECT
    order_status,
    COUNT(*) AS order_count
FROM tmp_orders
GROUP BY order_status
ORDER BY order_count DESC;


-- 11. LATE-DELIVERY KPI SUMMARY
-- Eligible denominator: delivered orders with valid actual and
-- estimated delivery timestamps. Compare calendar dates.

SELECT
    COUNT(*) AS eligible_delivered_orders,

    SUM(
        CASE
            WHEN DATE(order_delivered_customer_date) >
                 DATE(order_estimated_delivery_date)
            THEN 1
            ELSE 0
        END
    ) AS late_delivered_orders,

    SUM(
        CASE
            WHEN DATE(order_delivered_customer_date) <=
                 DATE(order_estimated_delivery_date)
            THEN 1
            ELSE 0
        END
    ) AS on_time_delivered_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(order_delivered_customer_date) >
                     DATE(order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN DATE(order_delivered_customer_date) <=
                     DATE(order_estimated_delivery_date)
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS on_time_delivery_percentage

FROM tmp_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- End of queries.
-- Record actual query results and exceptions after execution.
-- These checks do not delete or modify source records.
