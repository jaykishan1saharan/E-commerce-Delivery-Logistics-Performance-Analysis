
-- =====================================================
-- FILE: sql/08_week4_dashboard_validation.sql
-- PROJECT: Olist E-commerce Delivery Analysis
-- WEEK 4: Dashboard Validation
-- =====================================================

USE ecommerce_delivery;

-- 1. CHECK TOTAL ORDERS
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_level_analytics;


-- 2. CHECK DUPLICATE ORDER IDs
SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM vw_order_level_analytics
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 3. CHECK NULL VALUES
SELECT
    SUM(order_id IS NULL) AS null_order_id,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(order_status IS NULL) AS null_status,
    SUM(order_purchase_timestamp IS NULL) AS null_purchase_date,
    SUM(customer_state IS NULL) AS null_state
FROM vw_order_level_analytics;


-- 4. ORDER STATUS DISTRIBUTION
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM vw_order_level_analytics), 2
    ) AS percentage
FROM vw_order_level_analytics
GROUP BY order_status
ORDER BY total_orders DESC;


-- 5. DELIVERY PERFORMANCE
SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        )
    ), 2) AS avg_delivery_days
FROM vw_order_level_analytics
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL;


-- 6. ON-TIME DELIVERY RATE
SELECT
    COUNT(*) AS total_delivered,
    SUM(
        order_delivered_customer_date
        <= order_estimated_delivery_date
    ) AS on_time_orders,
    ROUND(
        SUM(
            order_delivered_customer_date
            <= order_estimated_delivery_date
        ) * 100.0 / COUNT(*), 2
    ) AS on_time_delivery_percentage
FROM vw_order_level_analytics
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL
AND order_estimated_delivery_date IS NOT NULL;


-- 7. LATE DELIVERY ANALYSIS
SELECT
    COUNT(*) AS late_orders,
    ROUND(AVG(
        DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        )
    ), 2) AS avg_days_late
FROM vw_order_level_analytics
WHERE order_status = 'delivered'
AND order_delivered_customer_date >
    order_estimated_delivery_date;


-- 8. STATE-WISE ORDER DISTRIBUTION
SELECT
    customer_state,
    COUNT(*) AS total_orders
FROM vw_order_level_analytics
GROUP BY customer_state
ORDER BY total_orders DESC;


-- 9. MONTHLY ORDER TREND
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
        AS order_month,
    COUNT(*) AS total_orders
FROM vw_order_level_analytics
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month;


-- 10. INVALID DATE VALIDATION
SELECT
    COUNT(*) AS invalid_delivery_dates
FROM vw_order_level_analytics
WHERE order_delivered_customer_date
      < order_purchase_timestamp;


-- 11. REVIEW SCORE VALIDATION
SELECT
    COUNT(*) AS invalid_review_scores
FROM vw_order_level_analytics
WHERE review_score NOT BETWEEN 1 AND 5;


-- 12. DASHBOARD KPI SUMMARY
SELECT
    COUNT(*) AS total_orders,

    SUM(order_status = 'delivered')
        AS delivered_orders,

    SUM(order_status = 'canceled')
        AS canceled_orders,

    ROUND(
        SUM(order_status = 'delivered') * 100.0 /
        NULLIF(COUNT(*), 0), 2
    ) AS delivery_percentage,

    ROUND(
        AVG(
            CASE
                WHEN order_status = 'delivered'
                THEN DATEDIFF(
                    order_delivered_customer_date,
                    order_purchase_timestamp
                )
            END
        ), 2
    ) AS average_delivery_days

FROM vw_order_level_analytics;

-- =====================================================
-- END OF WEEK 4 DASHBOARD VALIDATION
-- =====================================================

-- =========================================================
-- 7. CLEAN ORDER-LEVEL ANALYTICAL DATASET
-- One row per order
-- =========================================================

WITH review_summary AS (
    SELECT
        order_id,
        ROUND(AVG(review_score), 2) AS review_score
    FROM reviews
    GROUP BY order_id
),

order_data AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.customer_state,

        LOWER(TRIM(o.order_status)) AS order_status,

        STR_TO_DATE(
            o.order_purchase_timestamp,
            '%Y-%m-%d %H:%i:%s'
        ) AS purchase_timestamp,

        STR_TO_DATE(
            o.order_estimated_delivery_date,
            '%Y-%m-%d %H:%i:%s'
        ) AS estimated_delivery_timestamp,

        STR_TO_DATE(
            o.order_delivered_customer_date,
            '%Y-%m-%d %H:%i:%s'
        ) AS actual_delivery_timestamp

    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
)

SELECT
    od.order_id,
    od.order_status,
    od.purchase_timestamp,
    od.estimated_delivery_timestamp,
    od.actual_delivery_timestamp,
    od.customer_id,
    od.customer_state,
    rs.review_score,

    CASE
        WHEN od.purchase_timestamp IS NOT NULL
         AND od.actual_delivery_timestamp IS NOT NULL
         AND od.actual_delivery_timestamp >= od.purchase_timestamp
        THEN ROUND(
            TIMESTAMPDIFF(
                SECOND,
                od.purchase_timestamp,
                od.actual_delivery_timestamp
            ) / 86400.0,
            2
        )
        ELSE NULL
    END AS delivery_duration_days,

    CASE
        WHEN od.order_status = 'delivered'
         AND od.actual_delivery_timestamp IS NOT NULL
         AND od.estimated_delivery_timestamp IS NOT NULL
         AND od.actual_delivery_timestamp > od.estimated_delivery_timestamp
        THEN 1
        WHEN od.order_status = 'delivered'
         AND od.actual_delivery_timestamp IS NOT NULL
         AND od.estimated_delivery_timestamp IS NOT NULL
        THEN 0
        ELSE NULL
    END AS is_late_delivery

FROM order_data od
LEFT JOIN review_summary rs
    ON od.order_id = rs.order_id
ORDER BY od.purchase_timestamp, od.order_id;
