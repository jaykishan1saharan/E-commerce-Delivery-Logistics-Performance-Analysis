
-- ============================================================
-- Project: E-commerce Delivery Logistics Performance Analysis
-- File: sql/04_kpi_queries.sql
-- Purpose: Delivery KPIs and order-level analysis
-- Database: ecommerce_delivery
-- Type: Read-only SELECT queries
-- ============================================================

USE ecommerce_delivery;


-- 1. SOURCE TABLE ROW COUNTS
SELECT 'orders_stage' AS table_name, COUNT(*) AS row_count
FROM orders_stage
UNION ALL
SELECT 'customers_stage', COUNT(*) FROM customers_stage
UNION ALL
SELECT 'items_stage', COUNT(*) FROM items_stage
UNION ALL
SELECT 'reviews_stage', COUNT(*) FROM reviews_stage;


-- 2. ORDER ID UNIQUENESS CHECK
SELECT
    COUNT(*) AS total_order_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_rows
FROM orders_stage;


-- 3. ORDER-LEVEL DELIVERY KPI DATASET
-- Aggregate items and reviews before joining to prevent
-- multiple items or reviews from duplicating order records.

WITH item_summary AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS total_item_value,
        SUM(freight_value) AS total_freight_value
    FROM items_stage
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score) AS average_review_score
    FROM reviews_stage
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

FROM orders_stage AS o
LEFT JOIN customers_stage AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN review_summary AS r
    ON o.order_id = r.order_id;


-- 4. MISSING TIMESTAMP CHECK
SELECT
    COUNT(*) AS total_orders,
    SUM(order_purchase_timestamp IS NULL)
        AS missing_purchase_timestamp,
    SUM(order_delivered_customer_date IS NULL)
        AS missing_delivery_timestamp,
    SUM(order_estimated_delivery_date IS NULL)
        AS missing_estimated_date
FROM orders_stage;


-- 5. DELIVERY CHRONOLOGY CHECK
-- Delivered date should not be earlier than purchase date.
SELECT COUNT(*) AS invalid_delivery_dates
FROM orders_stage
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date <
      order_purchase_timestamp;


-- 6. DUPLICATE CUSTOMER KEY CHECK
SELECT
    customer_id,
    COUNT(*) AS occurrences
FROM customers_stage
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 7. DELIVERY STATUS SUMMARY
SELECT
    order_status,
    COUNT(*) AS order_count
FROM orders_stage
GROUP BY order_status
ORDER BY order_count DESC;


-- 8. LATE DELIVERY KPI SUMMARY
SELECT
    COUNT(*) AS delivered_orders_with_dates,
    SUM(
        order_delivered_customer_date >
        order_estimated_delivery_date
    ) AS late_delivered_orders,
    ROUND(
        100.0 * SUM(
            order_delivered_customer_date >
            order_estimated_delivery_date
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_percentage
FROM orders_stage
WHERE order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;

-- End of KPI queries.
-- Run and validate against the actual database before reporting results.
--