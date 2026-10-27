
USE ecommerce_delivery;

-- 1. Total order count
SELECT COUNT(*) AS total_orders
FROM olist_orders_dataset;

-- 2. Check order ID uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_ids
FROM olist_orders_dataset;

-- 3. Check missing key fields
SELECT
    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamps
FROM olist_orders_dataset;

-- 4. Delivered orders missing delivery timestamps
SELECT COUNT(*) AS delivered_orders_missing_delivery_dates
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- 5. Order status distribution
SELECT
    order_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;
