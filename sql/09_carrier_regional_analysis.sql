-- =============================================================
-- FILE: sql/09_carrier_regional_analysis.sql
-- OWNER: Jaykishan (Member 3)
-- PROJECT: Olist E-commerce Delivery & Logistics Performance
-- DIALECT: MySQL 8.0+
-- MONDAY: Source-field audit and analysis setup
-- =============================================================

USE ecommerce_delivery;

-- IMPORTANT:
-- The uploaded repository's Week 3 work uses orders, customers and items.
-- Run the checks below against the same approved database/snapshot used by
-- the team. Do not modify source/staging tables.

-- 1. Confirm relevant table columns before analysis.
DESCRIBE orders;
DESCRIBE customers;
DESCRIBE items;

-- 2. Confirm state and delivery timestamp coverage.
SELECT
    COUNT(*) AS order_rows,
    COUNT(DISTINCT o.order_id) AS distinct_orders,
    COUNT(c.customer_state) AS orders_with_state,
    SUM(o.order_purchase_timestamp IS NOT NULL) AS with_purchase_timestamp,
    SUM(o.order_approved_at IS NOT NULL) AS with_approval_timestamp,
    SUM(o.order_delivered_carrier_date IS NOT NULL) AS with_carrier_handoff_timestamp,
    SUM(o.order_delivered_customer_date IS NOT NULL) AS with_customer_delivery_timestamp,
    SUM(o.order_estimated_delivery_date IS NOT NULL) AS with_estimated_delivery_timestamp
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id;

-- 3. Check whether a carrier-name field exists in the available schema.
-- Olist's standard order table provides a carrier-handoff timestamp, not
-- necessarily a carrier identity. The supplied items table has seller_id.
SHOW COLUMNS FROM orders;
SHOW COLUMNS FROM items;

-- 4. Inspect seller coverage. Seller ID is not the same as carrier ID.
SELECT
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    SUM(seller_id IS NULL OR TRIM(seller_id) = '') AS rows_without_seller_id
FROM items;

-- 5. Preview state-level delivery eligibility and late-delivery rates.
-- One row per order is preserved by aggregating from orders + customers only.
SELECT
    UPPER(c.customer_state) AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
            THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) END), 2) AS avg_delay_days
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
GROUP BY UPPER(c.customer_state)
ORDER BY late_delivery_rate_pct DESC;

-- 6. Delivery-stage timestamp coverage and interval checks.
-- Negative intervals are flagged for investigation, not silently removed.
SELECT
    COUNT(*) AS total_orders,
    SUM(o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL) AS valid_purchase_to_approval,
    ROUND(AVG(CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_approved_at IS NOT NULL
         AND o.order_approved_at >= o.order_purchase_timestamp
        THEN TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp,
                           o.order_approved_at) / 24.0 END), 2)
        AS avg_purchase_to_approval_days,
    SUM(o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL) AS valid_approval_to_handoff,
    ROUND(AVG(CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_carrier_date >= o.order_approved_at
        THEN TIMESTAMPDIFF(HOUR, o.order_approved_at,
                           o.order_delivered_carrier_date) / 24.0 END), 2)
        AS avg_approval_to_handoff_days,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL) AS valid_handoff_to_delivery,
    ROUND(AVG(CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
        THEN TIMESTAMPDIFF(HOUR, o.order_delivered_carrier_date,
                           o.order_delivered_customer_date) / 24.0 END), 2)
        AS avg_handoff_to_delivery_days,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date < o.order_approved_at)
        AS negative_approval_to_handoff_intervals
FROM orders o;

-- 7. Region summary using the same state mapping used in Week 3.
SELECT
    CASE
        WHEN UPPER(c.customer_state) IN ('AM','RR','AP','PA','TO','RO','AC') THEN 'North'
        WHEN UPPER(c.customer_state) IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA') THEN 'Northeast'
        WHEN UPPER(c.customer_state) IN ('MT','MS','GO','DF') THEN 'Central-West'
        WHEN UPPER(c.customer_state) IN ('SP','RJ','MG','ES') THEN 'Southeast'
        WHEN UPPER(c.customer_state) IN ('PR','SC','RS') THEN 'South'
        ELSE 'Unknown'
    END AS region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE
            WHEN o.order_status = 'delivered'
             AND o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
            THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_purchase_timestamp) END), 2)
        AS avg_purchase_to_delivery_days
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
GROUP BY region
ORDER BY late_delivery_rate_pct DESC;

-- 8. TODO before final exports:
-- Reconcile these results with Week 3 exports and the approved Week 4 KPI
-- population/denominator. Do not label seller-level results as carrier results.
-- Do not join raw items directly to orders for order counts; aggregate items
-- to one row per order first if item attributes are needed.
