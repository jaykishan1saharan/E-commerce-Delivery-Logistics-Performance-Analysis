
-- ============================================================
-- Project: E-commerce Delivery Logistics Performance Analysis
-- File: sql/04_kpi_queries.sql
-- Purpose: Validate order grain, timestamps, and delivery KPIs
-- Database: ecommerce_delivery
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
    COALESCE(SUM(order_id IS NULL), 0) AS missing_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id)
        - COALESCE(SUM(order_id IS NULL), 0)
        AS duplicate_order_rows
FROM orders;


-- 3. FIND DUPLICATE ORDER IDS
SELECT
    order_id,
    COUNT(*) AS rows_per_order
FROM orders
WHERE order_id IS NOT NULL
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
-- Multiple items or reviews per order can be valid.

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

FROM orders AS o
LEFT JOIN customers AS c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary AS i
    ON o.order_id = i.order_id
LEFT JOIN review_summary AS r
    ON o.order_id = r.order_id;


-- 7. CHECK ORDER GRAIN AFTER JOINS
-- Aggregation prevents item/review multiplicity from multiplying orders.

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
FROM orders;


-- 9. DELIVERY CHRONOLOGY CHECKS

SELECT COUNT(*) AS invalid_delivery_dates
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date <
      order_purchase_timestamp;

SELECT COUNT(*) AS approval_before_purchase
FROM orders
WHERE order_approved_at IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_approved_at < order_purchase_timestamp;

SELECT COUNT(*) AS carrier_before_purchase
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_carrier_date < order_purchase_timestamp;

SELECT COUNT(*) AS delivery_before_carrier
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date < order_delivered_carrier_date;

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

FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- End of queries.
-- Record actual query results and exceptions after execution.
-- These checks do not delete or modify source records.
-----Day 4 week 3 work starts here

USE ecommerce_delivery;

-- 1. Overall order KPIs
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        AS delivered_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
        AS canceled_orders,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS delivered_order_pct,
    ROUND(
        100.0 * SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 2
    ) AS canceled_order_pct
FROM orders;


-- 2. Delivery performance KPIs
SELECT
    COUNT(*) AS eligible_delivered_orders,
    SUM(
        CASE
            WHEN STR_TO_DATE(
                order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'
            ) >
            STR_TO_DATE(
                order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s'
            )
            THEN 1 ELSE 0
        END
    ) AS late_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN STR_TO_DATE(
                    order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'
                ) >
                STR_TO_DATE(
                    order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s'
                )
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0), 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(
        TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(
                order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s'
            ),
            STR_TO_DATE(
                order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'
            )
        ) / 86400.0
    ), 2) AS avg_delay_days
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
  AND order_estimated_delivery_date IS NOT NULL
  AND order_estimated_delivery_date <> ''
  AND STR_TO_DATE(
      order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'
  ) IS NOT NULL
  AND STR_TO_DATE(
      order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s'
  ) IS NOT NULL;


-- 3. Average actual delivery duration
SELECT
    COUNT(*) AS eligible_orders,
    ROUND(AVG(
        TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    ), 2) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_purchase_timestamp <> ''
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date <> ''
  AND STR_TO_DATE(
      order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'
  ) IS NOT NULL
  AND STR_TO_DATE(
      order_delivered_customer_date, '%Y-%m-%d %H:%i:%s'
  ) IS NOT NULL;


-- 4. Order volume by status
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 5. Customer-state order distribution
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY total_orders DESC;


SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND STR_TO_DATE(o.order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(o.order_estimated_delivery_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
        THEN o.order_id
    END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND STR_TO_DATE(o.order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s')
             > STR_TO_DATE(o.order_estimated_delivery_date,
                           '%Y-%m-%d %H:%i:%s')
        THEN o.order_id
    END) AS late_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND STR_TO_DATE(o.order_delivered_customer_date,
                             '%Y-%m-%d %H:%i:%s')
                 > STR_TO_DATE(o.order_estimated_delivery_date,
                               '%Y-%m-%d %H:%i:%s')
            THEN o.order_id
        END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND STR_TO_DATE(o.order_delivered_customer_date,
                             '%Y-%m-%d %H:%i:%s') IS NOT NULL
             AND STR_TO_DATE(o.order_estimated_delivery_date,
                             '%Y-%m-%d %H:%i:%s') IS NOT NULL
            THEN o.order_id
        END), 0), 2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(CASE
        WHEN o.order_status = 'delivered'
         AND STR_TO_DATE(o.order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s')
             > STR_TO_DATE(o.order_estimated_delivery_date,
                           '%Y-%m-%d %H:%i:%s')
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(o.order_estimated_delivery_date,
                        '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(o.order_delivered_customer_date,
                        '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_delay_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY late_delivery_rate_pct DESC;

----REGION-WISE DELIVERY ANALYSIS
---3. PRODUCT-CATEGORY DELIVERY ANALYSIS

SELECT
    COALESCE(
        NULLIF(t.product_category_name_english, ''),
        NULLIF(p.product_category_name, ''),
        'Unknown'
    ) AS product_category,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND STR_TO_DATE(o.order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(o.order_estimated_delivery_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
        THEN o.order_id
    END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND STR_TO_DATE(o.order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s')
             > STR_TO_DATE(o.order_estimated_delivery_date,
                           '%Y-%m-%d %H:%i:%s')
        THEN o.order_id
    END) AS late_orders,
    ROUND(
        100.0 * COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND STR_TO_DATE(o.order_delivered_customer_date,
                             '%Y-%m-%d %H:%i:%s')
                 > STR_TO_DATE(o.order_estimated_delivery_date,
                               '%Y-%m-%d %H:%i:%s')
            THEN o.order_id
        END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND STR_TO_DATE(o.order_delivered_customer_date,
                             '%Y-%m-%d %H:%i:%s') IS NOT NULL
             AND STR_TO_DATE(o.order_estimated_delivery_date,
                             '%Y-%m-%d %H:%i:%s') IS NOT NULL
            THEN o.order_id
        END), 0), 2
    ) AS late_delivery_rate_pct
FROM orders o
JOIN items i ON o.order_id = i.order_id
JOIN products p ON i.product_id = p.product_id
LEFT JOIN translation t
    ON p.product_category_name = t.product_category_name
GROUP BY product_category
ORDER BY late_delivery_rate_pct DESC;

-- 4. MONTHLY ORDER TRENDS
SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
        '%Y-%m'
    ) AS purchase_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        AS delivered_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
        AS canceled_orders,
    ROUND(AVG(CASE
        WHEN order_status = 'delivered'
         AND STR_TO_DATE(order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(order_purchase_timestamp,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_delivery_days
FROM orders
WHERE STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') IS NOT NULL
GROUP BY purchase_month
ORDER BY purchase_month;
-- 5. WEEKLY ORDER TRENDS
SELECT
    YEARWEEK(
        STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
        3
    ) AS purchase_year_week,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        AS delivered_orders,
    SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
        AS canceled_orders,
    ROUND(AVG(CASE
        WHEN order_status = 'delivered'
         AND STR_TO_DATE(order_delivered_customer_date,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(order_purchase_timestamp,
                         '%Y-%m-%d %H:%i:%s') IS NOT NULL
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_delivery_days
FROM orders
WHERE STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') IS NOT NULL
GROUP BY purchase_year_week
ORDER BY purchase_year_week;

-- 6. DELIVERY-STAGE DURATION ANALYSIS


SELECT
    ROUND(AVG(CASE
        WHEN STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s')
             >= STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s')
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_purchase_to_approval_days,

    ROUND(AVG(CASE
        WHEN STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s')
             >= STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s')
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_approved_at, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_approval_to_carrier_days,

    ROUND(AVG(CASE
        WHEN STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
             >= STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s')
        THEN TIMESTAMPDIFF(
            SECOND,
            STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s')
        ) / 86400.0
    END), 2) AS avg_carrier_to_customer_days
FROM orders
WHERE order_status = 'delivered';
