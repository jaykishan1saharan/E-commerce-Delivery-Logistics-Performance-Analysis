/*
--CREATED BY MEMBER 1 YASHASHVI YASH
===============================================================================
FILE: sql/06_deep_analysis.sql
PROJECT: Olist E-commerce Delivery & Operations Analytics
DIALECT: MySQL 8.0+
PURPOSE:
  Deep-dive analysis beyond the baseline KPIs in 04_kpi_queries.sql:
  data quality, delivery performance, delay drivers, cancellations, regional
  and time trends, order value/freight, and customer review relationships.

ASSUMED TABLES AND COLUMNS (standard Olist naming):
  orders:
    order_id, customer_id, order_status, order_purchase_timestamp,
    order_approved_at, order_delivered_carrier_date,
    order_delivered_customer_date, order_estimated_delivery_date
  customers:
    customer_id, customer_state, customer_city
  items:
    order_id, order_item_id, product_id, seller_id, price, freight_value,
    shipping_limit_date
  reviews:
    order_id, review_id, review_score, review_creation_date,
    review_answer_timestamp



-- Select the correct schema before running, if needed:
-- USE YASH;
-- USE olist;


-- ============================================================================
-- 0. QUICK SCHEMA / VOLUME CHECKS
-- ============================================================================

-- 0A. Row counts: compare with expected source-file sizes.*/
USE ecommerce_delivery;
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'items', COUNT(*) FROM items
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;

-- 0B. Inspect the latest purchase date in the dataset.
SELECT
    MIN(order_purchase_timestamp) AS first_purchase_timestamp,
    MAX(order_purchase_timestamp) AS last_purchase_timestamp,
    COUNT(*) AS total_order_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids
FROM orders;


-- ============================================================================
-- 1. DATA QUALITY AUDIT
-- ============================================================================

-- 1A. Duplicate order IDs. Expected: zero rows.
SELECT order_id, COUNT(*) AS row_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- 1B. Missing critical order fields.
SELECT
    COUNT(*) AS total_rows,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(order_status IS NULL OR TRIM(order_status) = '') AS missing_order_status,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamp,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_delivery
FROM orders;

-- 1C. Chronology problems. These should be investigated, not automatically deleted.
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE
        WHEN order_approved_at < order_purchase_timestamp
            THEN 'approval_before_purchase'
        WHEN order_delivered_carrier_date < order_approved_at
            THEN 'carrier_before_approval'
        WHEN order_delivered_customer_date < order_delivered_carrier_date
            THEN 'customer_delivery_before_carrier'
        WHEN order_delivered_customer_date < order_purchase_timestamp
            THEN 'delivery_before_purchase'
        WHEN order_estimated_delivery_date < order_purchase_timestamp
            THEN 'estimated_delivery_before_purchase'
        ELSE 'check_other'
    END AS issue_type
FROM orders
WHERE
       (order_approved_at < order_purchase_timestamp)
    OR (order_delivered_carrier_date < order_approved_at)
    OR (order_delivered_customer_date < order_delivered_carrier_date)
    OR (order_delivered_customer_date < order_purchase_timestamp)
    OR (order_estimated_delivery_date < order_purchase_timestamp)
ORDER BY order_purchase_timestamp;

-- 1D. Order status counts and share of all orders.
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM orders), 0), 2)
        AS pct_of_all_orders
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- 1E. Item-level quality: missing IDs, invalid prices/freight, duplicate item keys.
SELECT
    COUNT(*) AS item_rows,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(price IS NULL) AS missing_price,
    SUM(price < 0) AS negative_price_rows,
    SUM(freight_value IS NULL) AS missing_freight,
    SUM(freight_value < 0) AS negative_freight_rows
FROM items;

SELECT order_id, order_item_id, COUNT(*) AS row_count
FROM items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC;

-- 1F. Review quality.
SELECT
    COUNT(*) AS review_rows,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_score NOT BETWEEN 1 AND 5) AS invalid_review_score
FROM reviews;


-- ============================================================================
-- 2. BUILD A SAFE ORDER-LEVEL ANALYTICAL DATASET (CTE)
-- Reused independently in the queries below.
-- Aggregate items and reviews before joining to orders to avoid fan-out.
-- ============================================================================

-- 2A. Preview one row per order with customer, item totals and review score.
WITH
item_by_order AS (
    SELECT
        order_id,
        COUNT(*) AS item_rows,
        COUNT(DISTINCT product_id) AS distinct_products,
        COUNT(DISTINCT seller_id) AS distinct_sellers,
        SUM(COALESCE(price, 0)) AS merchandise_value,
        SUM(COALESCE(freight_value, 0)) AS freight_value,
        SUM(COALESCE(price, 0) + COALESCE(freight_value, 0)) AS order_value
    FROM items
    GROUP BY order_id
),
review_by_order AS (
    SELECT
        order_id,
        COUNT(*) AS review_count,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_state,
    c.customer_city,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
        AS purchase_to_delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)
        AS days_after_estimate,
    i.item_rows,
    i.distinct_products,
    i.distinct_sellers,
    i.merchandise_value,
    i.freight_value,
    i.order_value,
    r.review_count,
    r.avg_review_score
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN item_by_order i ON i.order_id = o.order_id
LEFT JOIN review_by_order r ON r.order_id = o.order_id
ORDER BY o.order_purchase_timestamp DESC
LIMIT 100;


-- ============================================================================
-- 3. DELIVERY PERFORMANCE: ON-TIME, LATE, AND DELIVERY DURATION
-- Only delivered orders are used for delivery-duration metrics.
-- ============================================================================

-- 3A. Core delivery KPIs. Late means actual customer delivery > estimated date.
WITH delivered AS (
    SELECT
        order_id,
        DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
            AS delivery_days,
        DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)
            AS days_vs_estimate
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
)
SELECT
    COUNT(*) AS delivered_orders_with_required_dates,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(days_vs_estimate), 2) AS avg_days_vs_estimate,
    SUM(days_vs_estimate <= 0) AS on_or_before_estimate,
    SUM(days_vs_estimate > 0) AS late_orders,
    ROUND(100.0 * SUM(days_vs_estimate <= 0) / NULLIF(COUNT(*), 0), 2)
        AS on_time_or_early_pct,
    ROUND(100.0 * SUM(days_vs_estimate > 0) / NULLIF(COUNT(*), 0), 2)
        AS late_delivery_pct
FROM delivered
WHERE days_vs_estimate IS NOT NULL;

-- 3B. Delivery-time distribution buckets.
WITH delivered AS (
    SELECT DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
        AS delivery_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
)
SELECT
    CASE
        WHEN delivery_days < 0 THEN 'Invalid: negative'
        WHEN delivery_days BETWEEN 0 AND 3 THEN '0-3 days'
        WHEN delivery_days BETWEEN 4 AND 7 THEN '4-7 days'
        WHEN delivery_days BETWEEN 8 AND 14 THEN '8-14 days'
        WHEN delivery_days BETWEEN 15 AND 21 THEN '15-21 days'
        ELSE '22+ days'
    END AS delivery_bucket,
    COUNT(*) AS orders,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM delivered), 0), 2)
        AS pct_of_delivered
FROM delivered
GROUP BY delivery_bucket
ORDER BY MIN(delivery_days);

-- 3C. Most delayed orders, useful for case-level investigation.
SELECT
    order_id,
    order_purchase_timestamp,
    order_estimated_delivery_date,
    order_delivered_customer_date,
    DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)
        AS days_late
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
  AND order_delivered_customer_date > order_estimated_delivery_date
ORDER BY days_late DESC
LIMIT 50;

-- 3D. Stage durations: approval, dispatch, and final delivery.
-- Each interval is NULL when either endpoint is missing.
SELECT
    COUNT(*) AS orders_with_purchase_timestamp,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, order_purchase_timestamp, order_approved_at) / 24.0), 2)
        AS avg_purchase_to_approval_days,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, order_approved_at, order_delivered_carrier_date) / 24.0), 2)
        AS avg_approval_to_carrier_days,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, order_delivered_carrier_date, order_delivered_customer_date) / 24.0), 2)
        AS avg_carrier_to_customer_days
FROM orders
WHERE order_purchase_timestamp IS NOT NULL;

-- 3E. Delivery performance by purchase month.
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 2)
        AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)), 2)
        AS avg_days_vs_estimate,
    ROUND(100.0 * SUM(order_delivered_customer_date <= order_estimated_delivery_date)
          / NULLIF(COUNT(*), 0), 2) AS on_time_or_early_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- 3F. Delivery performance by day of week of purchase.
SELECT
    DAYNAME(order_purchase_timestamp) AS purchase_day,
    DAYOFWEEK(order_purchase_timestamp) AS day_number,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)), 2)
        AS avg_delivery_days,
    ROUND(100.0 * SUM(order_delivered_customer_date <= order_estimated_delivery_date)
          / NULLIF(COUNT(*), 0), 2) AS on_time_or_early_pct
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY DAYNAME(order_purchase_timestamp), DAYOFWEEK(order_purchase_timestamp)
ORDER BY day_number;


-- ============================================================================
-- 4. REGIONAL PERFORMANCE
-- Customer state/city are used as the region proxy. They are not seller location.
-- ============================================================================

-- 4A. States ranked by delivery volume and on-time performance.
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2)
        AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 2)
        AS avg_days_vs_estimate,
    ROUND(100.0 * SUM(o.order_delivered_customer_date <= o.order_estimated_delivery_date)
          / NULLIF(COUNT(*), 0), 2) AS on_time_or_early_pct,
    SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date) AS late_orders
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_orders DESC;

-- 4B. Cities with at least 30 delivered orders; avoids overinterpreting tiny samples.
SELECT
    c.customer_state,
    c.customer_city,
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2)
        AS avg_delivery_days,
    ROUND(100.0 * SUM(o.order_delivered_customer_date <= o.order_estimated_delivery_date)
          / NULLIF(COUNT(*), 0), 2) AS on_time_or_early_pct
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state, c.customer_city
HAVING COUNT(*) >= 30
ORDER BY on_time_or_early_pct ASC, delivered_orders DESC
LIMIT 50;


-- ============================================================================
-- 5. CANCELLATIONS AND UNDELIVERED ORDERS
-- Do not treat undelivered orders as late deliveries unless an agreed business
-- rule explicitly defines them that way.
-- ============================================================================

-- 5A. Status mix by purchase month.
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    order_status,
    COUNT(*) AS order_count
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m'), order_status
ORDER BY purchase_month, order_count DESC;

-- 5B. Cancellation rate by month (all orders purchased in the month as denominator).
SELECT
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS total_orders,
    SUM(order_status = 'canceled') AS canceled_orders,
    ROUND(100.0 * SUM(order_status = 'canceled') / NULLIF(COUNT(*), 0), 2)
        AS cancellation_pct
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- 5C. Orders not delivered: status and timestamp completeness.
SELECT
    order_status,
    COUNT(*) AS order_count,
    SUM(order_delivered_customer_date IS NULL) AS missing_customer_delivery_date,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_date,
    MIN(order_purchase_timestamp) AS earliest_purchase,
    MAX(order_purchase_timestamp) AS latest_purchase
FROM orders
WHERE order_status <> 'delivered'
   OR order_status IS NULL
GROUP BY order_status
ORDER BY order_count DESC;


-- ============================================================================
-- 6. SALES, FREIGHT, AND ORDER COMPLEXITY
-- Items are aggregated to order level before joining to orders.
-- ============================================================================

-- 6A. Monthly merchandise value, freight, and average order value.
WITH item_by_order AS (
    SELECT
        order_id,
        SUM(COALESCE(price, 0)) AS merchandise_value,
        SUM(COALESCE(freight_value, 0)) AS freight_value,
        SUM(COALESCE(price, 0) + COALESCE(freight_value, 0)) AS order_value,
        COUNT(*) AS item_rows
    FROM items
    GROUP BY order_id
)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*) AS orders_with_purchase_date,
    ROUND(SUM(COALESCE(i.merchandise_value, 0)), 2) AS total_merchandise_value,
    ROUND(SUM(COALESCE(i.freight_value, 0)), 2) AS total_freight_value,
    ROUND(SUM(COALESCE(i.order_value, 0)), 2) AS merchandise_plus_freight,
    ROUND(AVG(i.order_value), 2) AS avg_order_value,
    ROUND(AVG(i.item_rows), 2) AS avg_item_rows_per_order
FROM orders o
LEFT JOIN item_by_order i ON i.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY purchase_month;

-- 6B. Freight burden: freight as a share of merchandise value by state.
WITH item_by_order AS (
    SELECT
        order_id,
        SUM(COALESCE(price, 0)) AS merchandise_value,
        SUM(COALESCE(freight_value, 0)) AS freight_value
    FROM items
    GROUP BY order_id
)
SELECT
    c.customer_state,
    COUNT(*) AS orders,
    ROUND(SUM(i.merchandise_value), 2) AS merchandise_value,
    ROUND(SUM(i.freight_value), 2) AS freight_value,
    ROUND(100.0 * SUM(i.freight_value) / NULLIF(SUM(i.merchandise_value), 0), 2)
        AS freight_pct_of_merchandise
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN item_by_order i ON i.order_id = o.order_id
GROUP BY c.customer_state
HAVING SUM(i.merchandise_value) > 0
ORDER BY freight_pct_of_merchandise DESC;

-- 6C. Order complexity buckets by number of item rows.
WITH item_by_order AS (
    SELECT order_id, COUNT(*) AS item_rows
    FROM items
    GROUP BY order_id
)
SELECT
    CASE
        WHEN COALESCE(i.item_rows, 0) = 0 THEN 'No item rows'
        WHEN i.item_rows = 1 THEN '1 item'
        WHEN i.item_rows BETWEEN 2 AND 3 THEN '2-3 items'
        WHEN i.item_rows BETWEEN 4 AND 6 THEN '4-6 items'
        ELSE '7+ items'
    END AS order_size_bucket,
    COUNT(*) AS orders,
    ROUND(AVG(CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_purchase_timestamp IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
    END), 2) AS avg_delivery_days,
    ROUND(AVG(CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)
    END), 2) AS avg_days_vs_estimate
FROM orders o
LEFT JOIN item_by_order i ON i.order_id = o.order_id
GROUP BY order_size_bucket
ORDER BY MIN(COALESCE(i.item_rows, 0));


-- ============================================================================
-- 7. CUSTOMER REVIEWS AND DELIVERY EXPERIENCE
-- Review data is aggregated by order before joining to avoid duplicate counts.
-- ============================================================================

-- 7A. Review score distribution.
SELECT
    review_score,
    COUNT(*) AS review_count,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM reviews), 0), 2)
        AS pct_of_reviews
FROM reviews
WHERE review_score BETWEEN 1 AND 5
GROUP BY review_score
ORDER BY review_score;

-- 7B. Average review score by on-time/late delivery group.
WITH review_by_order AS (
    SELECT order_id, AVG(review_score) AS avg_review_score
    FROM reviews
    WHERE review_score BETWEEN 1 AND 5
    GROUP BY order_id
)
SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL
          OR o.order_estimated_delivery_date IS NULL THEN 'Unknown / not delivered'
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
            THEN 'On time or early'
        ELSE 'Late'
    END AS delivery_group,
    COUNT(*) AS orders_with_reviews,
    ROUND(AVG(r.avg_review_score), 2) AS avg_review_score
FROM orders o
JOIN review_by_order r ON r.order_id = o.order_id
GROUP BY delivery_group
ORDER BY avg_review_score DESC;

-- 7C. Review score against days late. Positive means late; zero/negative means
-- delivered on or before estimate. This is association, not proof of causation.
WITH review_by_order AS (
    SELECT order_id, AVG(review_score) AS avg_review_score
    FROM reviews
    WHERE review_score BETWEEN 1 AND 5
    GROUP BY order_id
)
SELECT
    DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)
        AS days_vs_estimate,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(r.avg_review_score), 2) AS avg_review_score
FROM orders o
JOIN review_by_order r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY days_vs_estimate
ORDER BY days_vs_estimate;


-- ============================================================================
-- 8. HIGH-LEVEL OUTLIER / FOLLOW-UP QUEUES
-- ============================================================================

-- 8A. Delivered orders with very long purchase-to-delivery durations (>30 days).
SELECT
    order_id,
    customer_id,
    order_purchase_timestamp,
    order_delivered_customer_date,
    DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)
        AS delivery_days,
    DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date)
        AS days_vs_estimate
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND DATEDIFF(order_delivered_customer_date, order_purchase_timestamp) > 30
ORDER BY delivery_days DESC;

-- 8B. Potentially incomplete delivered records.
SELECT
    order_id,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
WHERE order_status = 'delivered'
  AND (
       order_purchase_timestamp IS NULL
    OR order_delivered_customer_date IS NULL
    OR order_estimated_delivery_date IS NULL
  )
ORDER BY order_purchase_timestamp;

-- 8C. Customers with the highest number of orders.
SELECT
    c.customer_id,
    c.customer_state,
    c.customer_city,
    COUNT(*) AS total_orders,
    SUM(o.order_status = 'delivered') AS delivered_orders,
    SUM(o.order_status = 'canceled') AS canceled_orders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_state, c.customer_city
HAVING COUNT(*) >= 2
ORDER BY total_orders DESC
LIMIT 100;


-- ============================================================================
-- 9. ANALYSIS NOTES / INTERPRETATION GUIDE
-- ============================================================================
/*n 06_deep_analysis.sql, we performed an in-depth analysis of the Olist E-commerce dataset using MySQL. The main areas covered were:
- Data Quality Audit: Checked missing values, duplicate order IDs, invalid timestamps, incorrect order sequences, negative prices, freight values, and invalid review scores.
- CTEs (Common Table Expressions): Used WITH clauses to structure complex queries and create an order-level analytical dataset.
- Joins and Aggregations: Combined orders, customers, items, and reviews using JOIN and LEFT JOIN, aggregating item and review data separately to prevent duplicate calculations.
- Delivery Performance Analysis: Calculated average delivery duration, on-time delivery percentage, late-delivery percentage, days of delay, and stage-wise processing times using DATEDIFF() and TIMESTAMPDIFF().
- Time-Based Analysis: Analyzed monthly delivery trends, purchase-day performance, order-status changes, and cancellation rates using DATE_FORMAT(), DAYNAME(), and DAYOFWEEK().
- Regional Analysis: Compared delivery performance across customer states and cities to identify regions with higher delays and lower on-time delivery rates.
- Cancellation Analysis: Evaluated cancelled and undelivered orders and calculated monthly cancellation percentages.
- Sales and Freight Analysis: Calculated merchandise value, freight costs, average order value, monthly sales-related metrics, freight-to-merchandise ratios, and order complexity based on item counts.
- Customer Review Analysis: Examined review-score distributions and compared average customer ratings between on-time and delayed deliveries.
- Outlier Detection: Identified orders taking more than 30 days to deliver, incomplete delivery records, and customers with multiple orders.
- Advanced SQL Functions: Applied CASE WHEN, COALESCE(), NULLIF(), ROUND(), conditional aggregation, subqueries, GROUP BY, HAVING, and ORDER BY to derive meaningful business metrics.
- Business Insights and Data Interpretation: Established rules for calculating KPIs, handling missing values, avoiding duplicate counts, and distinguishing correlation from causation.
Overall objective: To transform raw e-commerce data into reliable analytical insights, identify delivery and operational inefficiencies, understand customer satisfaction, and prepare the foundation for a Power BI dashboard and a professional Data Analyst portfolio project.
*/


-- ============================================================
-- DAY 2: REGIONAL AND PRODUCT-CATEGORY DEEP ANALYSIS
-- Owner: Member 1 - Yashashvi Yash
-- Source: vw_order_level_analytics
-- ============================================================

-- 11A. DELIVERY PERFORMANCE BY CUSTOMER STATE
-- Compare late rate, order volume, and average delay.
CREATE OR REPLACE VIEW vw_order_level_analytics AS
SELECT
    o.order_id,
    o.order_status,
    c.customer_state,

    CASE
        WHEN c.customer_state IN ('AM','RR','AP','PA','TO','RO','AC')
            THEN 'North'
        WHEN c.customer_state IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA')
            THEN 'Northeast'
        WHEN c.customer_state IN ('MT','MS','GO','DF')
            THEN 'Central-West'
        WHEN c.customer_state IN ('SP','RJ','MG','ES')
            THEN 'Southeast'
        WHEN c.customer_state IN ('PR','SC','RS')
            THEN 'South'
        ELSE 'Unknown'
    END AS region,

    CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME)
        AS order_purchase_timestamp,

    DAYOFWEEK(
        CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME)
    ) AS weekday_num,

    DAYNAME(
        CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME)
    ) AS weekday,

    ib.category,
    COALESCE(ib.n_items, 0) AS n_items,
    ib.order_value,
    ib.freight_total,
    rb.review_score,

    DATEDIFF(
        CAST(NULLIF(o.order_approved_at, '') AS DATETIME),
        CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME)
    ) AS approval_days,

    DATEDIFF(
        CAST(NULLIF(o.order_delivered_carrier_date, '') AS DATETIME),
        CAST(NULLIF(o.order_approved_at, '') AS DATETIME)
    ) AS handling_days,

    DATEDIFF(
        CAST(NULLIF(o.order_delivered_customer_date, '') AS DATETIME),
        CAST(NULLIF(o.order_purchase_timestamp, '') AS DATETIME)
    ) AS delivery_days,

    DATEDIFF(
        CAST(NULLIF(o.order_delivered_customer_date, '') AS DATETIME),
        CAST(NULLIF(o.order_estimated_delivery_date, '') AS DATETIME)
    ) AS delay_days,

    CASE
        WHEN o.order_status = 'delivered'
         AND NULLIF(o.order_delivered_customer_date, '') IS NOT NULL
         AND NULLIF(o.order_estimated_delivery_date, '') IS NOT NULL
        THEN CASE
            WHEN CAST(o.order_delivered_customer_date AS DATETIME)
                 <= CAST(o.order_estimated_delivery_date AS DATETIME)
            THEN 1
            ELSE 0
        END
        ELSE NULL
    END AS is_on_time,

    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END
        AS is_canceled,

    CASE
        WHEN rb.review_score IS NULL THEN NULL
        WHEN rb.review_score <= 2 THEN 1
        ELSE 0
    END AS is_low_rating

FROM orders o

LEFT JOIN customers c
    ON c.customer_id = o.customer_id

LEFT JOIN (
    SELECT
        i.order_id,
        COUNT(*) AS n_items,
        SUM(COALESCE(i.price, 0)) AS order_value,
        SUM(COALESCE(i.freight_value, 0)) AS freight_total,
        GROUP_CONCAT(
            DISTINCT COALESCE(
                NULLIF(t.product_category_name_english, ''),
                NULLIF(p.product_category_name, ''),
                'Unknown'
            )
            SEPARATOR ', '
        ) AS category
    FROM items i
    LEFT JOIN products p
        ON p.product_id = i.product_id
    LEFT JOIN translation t
        ON t.product_category_name = p.product_category_name
    GROUP BY i.order_id
) ib
    ON ib.order_id = o.order_id

LEFT JOIN (
    SELECT
        order_id,
        AVG(
            CASE
                WHEN review_score BETWEEN 1 AND 5
                THEN review_score
            END
        ) AS review_score
    FROM reviews
    GROUP BY order_id
) rb
    ON rb.order_id = o.order_id;

