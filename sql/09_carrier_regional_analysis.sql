-- =====================================================================
-- WEEK 4 - MONDAY: SOURCE-FIELD AUDIT AND ANALYSIS SETUP
-- Owner: Jaykishan (Member 3)
-- Project: Olist E-commerce Delivery & Logistics Performance
-- Dialect: MySQL 8.0+
-- =====================================================================
USE ecommerce_delivery;

-- MONDAY: Run against the team's approved database/snapshot.
-- These checks are read-only and do not modify source/staging tables.

-- M1. Confirm relevant source table columns.
DESCRIBE orders;
DESCRIBE customers;
DESCRIBE items;

-- M2. Confirm state and delivery timestamp coverage.
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

-- M3. Inspect available columns; handoff timestamp is not carrier identity.
SHOW COLUMNS FROM orders;
SHOW COLUMNS FROM items;

-- M4. Inspect seller coverage. Seller ID is not carrier ID.
SELECT
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    SUM(seller_id IS NULL OR TRIM(seller_id) = '') AS rows_without_seller_id
FROM items;

-- M5. Initial state-level delivery performance on source tables.
-- Eligible delivered denominator requires both actual and estimated dates.
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
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
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

-- M6. Delivery-stage timestamp coverage and interval checks.
-- Negative intervals are flagged, not silently removed.
SELECT
    COUNT(*) AS total_orders,
    SUM(o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL) AS rows_with_purchase_and_approval,
    SUM(o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at < o.order_purchase_timestamp)
        AS negative_purchase_to_approval_intervals,
    ROUND(AVG(CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_approved_at IS NOT NULL
         AND o.order_approved_at >= o.order_purchase_timestamp
        THEN TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp,
                           o.order_approved_at) / 86400.0 END), 2)
        AS avg_purchase_to_approval_days,
    SUM(o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date < o.order_approved_at)
        AS negative_approval_to_handoff_intervals,
    ROUND(AVG(CASE
        WHEN o.order_approved_at IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_carrier_date >= o.order_approved_at
        THEN TIMESTAMPDIFF(SECOND, o.order_approved_at,
                           o.order_delivered_carrier_date) / 86400.0 END), 2)
        AS avg_approval_to_handoff_days,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date < o.order_delivered_carrier_date)
        AS negative_handoff_to_delivery_intervals,
    ROUND(AVG(CASE
        WHEN o.order_delivered_carrier_date IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
        THEN TIMESTAMPDIFF(SECOND, o.order_delivered_carrier_date,
                           o.order_delivered_customer_date) / 86400.0 END), 2)
        AS avg_handoff_to_delivery_days
FROM orders o;

-- M7. Initial region summary using the Week 3 state mapping.
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
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
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
         AND o.order_purchase_timestamp IS NOT NULL
        THEN TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp,
                           o.order_delivered_customer_date) / 86400.0 END), 2)
        AS avg_purchase_to_delivery_days
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
GROUP BY region
ORDER BY late_delivery_rate_pct DESC;

-- =====================================================================
-- WEEK 4 - TUESDAY: CLEAN-VIEW REGIONAL / STATE / STAGE ANALYSIS
-- Owner: Jaykishan (Member 3)
-- Requires clean views created by sql/03_create_clean_views.sql.
-- =====================================================================
USE ecommerce_delivery;

-- QUERY 1: REGION-LEVEL DELIVERY PERFORMANCE
-- One row per order is preserved: orders_clean joined to customers_clean.
-- Region mapping matches the Week 3 project mapping.
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
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id END) AS on_time_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
        THEN TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp,
                           o.order_delivered_customer_date) / 24.0 END), 2)
        AS avg_purchase_to_delivery_days
FROM orders_clean o
LEFT JOIN customers_clean c ON c.customer_id = o.customer_id
GROUP BY region
ORDER BY late_delivery_rate_pct DESC;

-- QUERY 2: STATE-LEVEL DELIVERY PERFORMANCE
-- Export this result separately if the team wants a state drill-down.
SELECT
    UPPER(COALESCE(c.customer_state, 'UNKNOWN')) AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id END) AS on_time_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) END), 2) AS avg_delay_days
FROM orders_clean o
LEFT JOIN customers_clean c ON c.customer_id = o.customer_id
GROUP BY UPPER(COALESCE(c.customer_state, 'UNKNOWN'))
ORDER BY late_delivery_rate_pct DESC, eligible_delivered_orders DESC;

-- QUERY 3: DELIVERY-STAGE DURATION SUMMARY
-- Invalid/negative intervals are counted separately and excluded from averages.
SELECT
    COUNT(*) AS total_orders,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL)
        AS rows_with_purchase_and_approval,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at >= o.order_purchase_timestamp)
        AS valid_purchase_to_approval_stages,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at < o.order_purchase_timestamp)
        AS negative_purchase_to_approval_stages,
    ROUND(AVG(CASE WHEN o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at >= o.order_purchase_timestamp
        THEN TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp,
                           o.order_approved_at) / 86400.0 END), 2)
        AS avg_purchase_to_approval_days,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL)
        AS rows_with_approval_and_handoff,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date >= o.order_approved_at)
        AS valid_approval_to_handoff_stages,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date < o.order_approved_at)
        AS negative_approval_to_handoff_stages,
    ROUND(AVG(CASE WHEN o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date >= o.order_approved_at
        THEN TIMESTAMPDIFF(SECOND, o.order_approved_at,
                           o.order_delivered_carrier_date) / 86400.0 END), 2)
        AS avg_approval_to_handoff_days,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL)
        AS rows_with_handoff_and_delivery,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date >= o.order_delivered_carrier_date)
        AS valid_handoff_to_delivery_stages,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date < o.order_delivered_carrier_date)
        AS negative_handoff_to_delivery_stages,
    ROUND(AVG(CASE WHEN o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
        THEN TIMESTAMPDIFF(SECOND, o.order_delivered_carrier_date,
                           o.order_delivered_customer_date) / 86400.0 END), 2)
        AS avg_handoff_to_delivery_days
FROM orders_clean o;

-- QUERY 4: CHECK SELLER COVERAGE (SELLER IS NOT A CARRIER)
-- Item-level rows are aggregated for coverage only; do not label this carrier data.
SELECT
    COUNT(*) AS item_rows,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT seller_id) AS distinct_sellers,
    SUM(seller_id IS NULL OR TRIM(seller_id) = '') AS rows_without_seller_id
FROM items_clean;

-- QUERY 5: CHECK WHETHER AN ACTUAL CARRIER IDENTIFIER EXISTS IN THE ORDER SCHEMA
-- Inspect columns in Workbench; the standard source has a carrier handoff timestamp,
-- not a carrier-name field. Never fabricate carrier performance from seller_id.
SHOW COLUMNS FROM orders_clean;

-- =====================================================================
-- WEEK 4 - WEDNESDAY: FINAL-CANDIDATE REGIONAL / STATE / STAGE ANALYSIS
-- Owner: Jaykishan (Member 3)
-- Requires clean views created by sql/03_create_clean_views.sql.
-- Run after Tuesday analysis; export these final-candidate result sets.
-- =====================================================================
USE ecommerce_delivery;

-- QUERY 1: REGION-LEVEL DELIVERY PERFORMANCE
-- One row per order is preserved: orders_clean joined to customers_clean.
-- Region mapping matches the Week 3 project mapping.
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
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id END) AS on_time_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_purchase_timestamp IS NOT NULL
        THEN TIMESTAMPDIFF(HOUR, o.order_purchase_timestamp,
                           o.order_delivered_customer_date) / 24.0 END), 2)
        AS avg_purchase_to_delivery_days
FROM orders_clean o
LEFT JOIN customers_clean c ON c.customer_id = o.customer_id
GROUP BY region
ORDER BY late_delivery_rate_pct DESC;

-- WEDNESDAY EXPORT: data/exports/week4_regional_delay_analysis.csv

-- QUERY 2: STATE-LEVEL DELIVERY PERFORMANCE
-- Export this result separately if the team wants a state drill-down.
SELECT
    UPPER(COALESCE(c.customer_state, 'UNKNOWN')) AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END) AS eligible_delivered_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END) AS late_orders,
    COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date <= o.order_estimated_delivery_date
        THEN o.order_id END) AS on_time_orders,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_id END), 0), 2) AS late_delivery_rate_pct,
    ROUND(AVG(CASE WHEN LOWER(o.order_status) = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
        THEN DATEDIFF(o.order_delivered_customer_date,
                      o.order_estimated_delivery_date) END), 2) AS avg_delay_days
FROM orders_clean o
LEFT JOIN customers_clean c ON c.customer_id = o.customer_id
GROUP BY UPPER(COALESCE(c.customer_state, 'UNKNOWN'))
ORDER BY late_delivery_rate_pct DESC, eligible_delivered_orders DESC;

-- WEDNESDAY EXPORT: data/exports/week4_state_delay_analysis.csv

-- QUERY 3: DELIVERY-STAGE DURATION SUMMARY
-- Invalid/negative intervals are counted separately and excluded from averages.
SELECT
    COUNT(*) AS total_orders,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL)
        AS rows_with_purchase_and_approval,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at >= o.order_purchase_timestamp)
        AS valid_purchase_to_approval_stages,
    SUM(o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at < o.order_purchase_timestamp)
        AS negative_purchase_to_approval_stages,
    ROUND(AVG(CASE WHEN o.order_purchase_timestamp IS NOT NULL
        AND o.order_approved_at IS NOT NULL
        AND o.order_approved_at >= o.order_purchase_timestamp
        THEN TIMESTAMPDIFF(SECOND, o.order_purchase_timestamp,
                           o.order_approved_at) / 86400.0 END), 2)
        AS avg_purchase_to_approval_days,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL)
        AS rows_with_approval_and_handoff,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date >= o.order_approved_at)
        AS valid_approval_to_handoff_stages,
    SUM(o.order_approved_at IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date < o.order_approved_at)
        AS negative_approval_to_handoff_stages,
    ROUND(AVG(CASE WHEN o.order_approved_at IS NOT NULL
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_carrier_date >= o.order_approved_at
        THEN TIMESTAMPDIFF(SECOND, o.order_approved_at,
                           o.order_delivered_carrier_date) / 86400.0 END), 2)
        AS avg_approval_to_handoff_days,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL)
        AS rows_with_handoff_and_delivery,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date >= o.order_delivered_carrier_date)
        AS valid_handoff_to_delivery_stages,
    SUM(o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date < o.order_delivered_carrier_date)
        AS negative_handoff_to_delivery_stages,
    ROUND(AVG(CASE WHEN o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_delivered_customer_date >= o.order_delivered_carrier_date
        THEN TIMESTAMPDIFF(SECOND, o.order_delivered_carrier_date,
                           o.order_delivered_customer_date) / 86400.0 END), 2)
        AS avg_handoff_to_delivery_days
FROM orders_clean o;

-- WEDNESDAY EXPORT: data/exports/week4_delivery_stage_analysis.csv

-- Carrier comparison remains unavailable unless a genuine carrier identifier
-- is confirmed. A handoff timestamp is not carrier identity; seller_id is not
-- a carrier ID. Do not fabricate carrier-level results.

-- =====================================================================
-- EXECUTION ORDER AND DATA SAFEGUARDS
-- =====================================================================
-- MONDAY:
--   Run M1-M7 against source tables orders, customers and items.
-- TUESDAY:
--   First ensure sql/03_create_clean_views.sql has been run successfully.
--   Run Tuesday Queries 1-5 against *_clean views.
-- WEDNESDAY:
--   Re-run Wednesday Queries 1-3 as final-candidate exports.
--
-- EXPORTS:
--   Tuesday Query 1 / Wednesday Query 1:
--     data/exports/week4_regional_delay_analysis.csv
--   Tuesday Query 2 / Wednesday Query 2:
--     data/exports/week4_state_delay_analysis.csv
--   Tuesday Query 3 / Wednesday Query 3:
--     data/exports/week4_delivery_stage_analysis.csv
--
-- VALIDATION NOTES:
-- 1. Monday uses source tables; Tuesday/Wednesday use clean views. Counts may
--    differ due to cleaning/view filters. Reconcile before publishing.
-- 2. Monday M5 and Tuesday/Wednesday Q2 use delivered orders with both actual
--    and estimated delivery timestamps as the eligible denominator.
-- 3. Tuesday/Wednesday Q3 counts negative intervals separately and excludes
--    them from stage averages.
-- 4. A carrier handoff timestamp is not a carrier name/identifier.
-- 5. seller_id identifies a seller, not a logistics carrier.
-- 6. Keep one row per order for order-level counts. Do not join raw item rows
--    directly to orders without first aggregating items to one row per order.
-- 7. Regional grouping is derived from customer_state, not carrier geography.
-- 8. Treat Week 3 values as historical references until reconciled with these
--    Week 4 query outputs and the approved KPI population.
-- 9. All queries are intended to be read-only; no source tables are modified.
