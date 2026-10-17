-- 03_data_quality_audit.sql
-- E-commerce Delivery & Logistics Performance Analysis
-- Purpose: Reproducible, read-only data-quality audit for the currently imported staging tables.
-- Database: ecommerce_delivery | SQL dialect: MySQL 8
--
-- CURRENT DATABASE STATE (verified by Workbench row-count screenshot on 2026-10-17):
-- customers_stage  99,441
-- items_stage     112,650
-- orders_stage     99,441
-- reviews_stage    99,224
-- products_stage   32,951
-- translation_stage    71
--
-- IMPORTANT:
-- 1) This script performs SELECT/SHOW/DESCRIBE only. It does not UPDATE, DELETE, DROP, or TRUNCATE.
-- 2) All six source datasets are currently named *_stage (translation_stage included).
-- 3) Run this script against these exact names. Do not run older queries that reference dropped
--    tables customers, items, orders, reviews, or products.
-- 4) Row counts above verify import volume only; they do not prove data quality.
-- 5) Record issue counts from actual query results in data_quality_report.csv. Do not guess.
-- 6) NULL timestamps must be interpreted by order status; do not automatically label all NULLs as errors.
-- 7) A repeated order_id in items_stage is expected when an order has multiple line items.
--    Check the pair (order_id, order_item_id) for duplicate line-item keys.

USE ecommerce_delivery;

-- =========================================================
-- 0. Inventory and row-count verification
-- =========================================================
SHOW TABLES;

SELECT 'customers_stage' AS table_name, COUNT(*) AS actual_rows, 99441 AS expected_rows,
       IF(COUNT(*) = 99441, 'PASS', 'CHECK') AS import_count_check FROM customers_stage
UNION ALL
SELECT 'items_stage', COUNT(*), 112650, IF(COUNT(*) = 112650, 'PASS', 'CHECK') FROM items_stage
UNION ALL
SELECT 'orders_stage', COUNT(*), 99441, IF(COUNT(*) = 99441, 'PASS', 'CHECK') FROM orders_stage
UNION ALL
SELECT 'reviews_stage', COUNT(*), 99224, IF(COUNT(*) = 99224, 'PASS', 'CHECK') FROM reviews_stage
UNION ALL
SELECT 'products_stage', COUNT(*), 32951, IF(COUNT(*) = 32951, 'PASS', 'CHECK') FROM products_stage
UNION ALL
SELECT 'translation_stage', COUNT(*), 71, IF(COUNT(*) = 71, 'PASS', 'CHECK') FROM translation_stage;

-- Inspect actual column names/types before interpreting later checks.
DESCRIBE customers_stage;
DESCRIBE items_stage;
DESCRIBE orders_stage;
DESCRIBE reviews_stage;
DESCRIBE products_stage;
DESCRIBE translation_stage;

-- =========================================================
-- 1. CUSTOMERS
-- =========================================================
SELECT COUNT(*) AS total_customers FROM customers_stage;

SELECT
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(customer_unique_id IS NULL) AS missing_customer_unique_id,
    SUM(customer_zip_code_prefix IS NULL) AS missing_zip_prefix,
    SUM(customer_city IS NULL) AS missing_city,
    SUM(customer_state IS NULL) AS missing_state,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS blank_customer_id,
    SUM(TRIM(COALESCE(customer_city, '')) = '') AS blank_city,
    SUM(TRIM(COALESCE(customer_state, '')) = '') AS blank_state
FROM customers_stage;

SELECT customer_id, COUNT(*) AS occurrence_count
FROM customers_stage
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- customer_unique_id can legitimately repeat across multiple customer_id records;
-- use this output for investigation, not automatic deletion.
SELECT customer_unique_id, COUNT(*) AS occurrence_count
FROM customers_stage
GROUP BY customer_unique_id
HAVING COUNT(*) > 1
ORDER BY occurrence_count DESC;

SELECT customer_state, COUNT(*) AS customer_count
FROM customers_stage
GROUP BY customer_state
ORDER BY customer_count DESC;

-- =========================================================
-- 2. ORDERS
-- =========================================================
SELECT COUNT(*) AS total_orders FROM orders_stage;

SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(order_status IS NULL) AS missing_order_status,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamp,
    SUM(order_approved_at IS NULL) AS missing_approval_timestamp,
    SUM(order_delivered_carrier_date IS NULL) AS missing_carrier_timestamp,
    SUM(order_delivered_customer_date IS NULL) AS missing_actual_delivery_timestamp,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_delivery_timestamp,
    SUM(TRIM(COALESCE(order_id, '')) = '') AS blank_order_id,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS blank_customer_id,
    SUM(TRIM(COALESCE(order_status, '')) = '') AS blank_order_status
FROM orders_stage;

SELECT order_id, COUNT(*) AS occurrence_count
FROM orders_stage
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_status, COUNT(*) AS status_count
FROM orders_stage
GROUP BY order_status
ORDER BY status_count DESC;

-- Timestamp chronology anomalies; inspect returned rows before deciding treatment.
SELECT order_id, order_status, order_purchase_timestamp, order_approved_at,
       order_delivered_carrier_date, order_delivered_customer_date,
       order_estimated_delivery_date
FROM orders_stage
WHERE
    (order_approved_at IS NOT NULL AND order_purchase_timestamp IS NOT NULL
     AND order_approved_at < order_purchase_timestamp)
 OR (order_delivered_carrier_date IS NOT NULL AND order_purchase_timestamp IS NOT NULL
     AND order_delivered_carrier_date < order_purchase_timestamp)
 OR (order_delivered_customer_date IS NOT NULL AND order_purchase_timestamp IS NOT NULL
     AND order_delivered_customer_date < order_purchase_timestamp)
 OR (order_delivered_customer_date IS NOT NULL AND order_delivered_carrier_date IS NOT NULL
     AND order_delivered_customer_date < order_delivered_carrier_date);

SELECT COUNT(*) AS delivered_orders_missing_actual_delivery
FROM orders_stage
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- =========================================================
-- 3. ORDER ITEMS
-- =========================================================
USE ecommerce_delivery;

-- 1. Total order items
SELECT COUNT(*) AS total_items
FROM items_stage;

-- 2. Missing and blank values
SELECT
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(order_item_id IS NULL) AS missing_item_id,
    SUM(product_id IS NULL OR TRIM(product_id) = '') AS missing_product_id,
    SUM(seller_id IS NULL OR TRIM(seller_id) = '') AS missing_seller_id,
    SUM(price IS NULL) AS missing_price,
    SUM(freight_value IS NULL) AS missing_freight
FROM items_stage;

-- 3. Duplicate order-item combinations
SELECT order_id, order_item_id, COUNT(*) AS occurrence_count
FROM items_stage
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 4. Invalid price or freight
SELECT
    SUM(price < 0) AS negative_price_rows,
    SUM(freight_value < 0) AS negative_freight_rows,
    SUM(price = 0) AS zero_price_rows,
    SUM(freight_value = 0) AS zero_freight_rows
FROM items_stage;

-- 5. Order item quantity distribution
SELECT order_item_id, COUNT(*) AS row_count
FROM items_stage
GROUP BY order_item_id
ORDER BY order_item_id;

-- =========================================================
-- 4. REVIEWS
-- =========================================================
USE ecommerce_delivery;

-- 1. Total reviews
SELECT COUNT(*) AS total_reviews
FROM reviews_stage;

-- 2. Missing / blank values
SELECT
    SUM(review_id IS NULL OR TRIM(review_id) = '') AS missing_review_id,
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_comment_title IS NULL OR TRIM(review_comment_title) = '') AS missing_comment_title,
    SUM(review_comment_message IS NULL OR TRIM(review_comment_message) = '') AS missing_comment_message,
    SUM(review_creation_date IS NULL) AS missing_creation_date,
    SUM(review_answer_timestamp IS NULL) AS missing_answer_timestamp
FROM reviews_stage;

-- 3. Duplicate review IDs
SELECT review_id, COUNT(*) AS occurrence_count
FROM reviews_stage
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 4. Review score distribution
SELECT review_score, COUNT(*) AS review_count
FROM reviews_stage
GROUP BY review_score
ORDER BY review_score;

-- 5. Invalid review scores
SELECT COUNT(*) AS invalid_review_scores
FROM reviews_stage
WHERE review_score < 1 OR review_score > 5;

-- =========================================================
-- 5. PRODUCTS
-- =========================================================
SELECT COUNT(*) AS total_products FROM products_stage;

SELECT
    SUM(product_id IS NULL) AS missing_product_id,
    SUM(product_category_name IS NULL) AS null_product_category,
    SUM(TRIM(COALESCE(product_id, '')) = '') AS blank_product_id,
    SUM(TRIM(COALESCE(product_category_name, '')) = '') AS blank_product_category
FROM products_stage;

SELECT product_id, COUNT(*) AS occurrence_count
FROM products_stage
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Zero/missing dimensions may need different treatment from negative values.
SELECT
    SUM(product_length_cm IS NULL OR product_length_cm <= 0) AS null_or_nonpositive_length,
    SUM(product_height_cm IS NULL OR product_height_cm <= 0) AS null_or_nonpositive_height,
    SUM(product_width_cm IS NULL OR product_width_cm <= 0) AS null_or_nonpositive_width,
    SUM(product_weight_g IS NULL OR product_weight_g <= 0) AS null_or_nonpositive_weight,
    SUM(product_length_cm < 0) AS negative_length,
    SUM(product_height_cm < 0) AS negative_height,
    SUM(product_width_cm < 0) AS negative_width,
    SUM(product_weight_g < 0) AS negative_weight
FROM products_stage;

-- =========================================================
-- 6. PRODUCT CATEGORY TRANSLATION
-- =========================================================
SELECT COUNT(*) AS total_translation_rows FROM translation_stage;

SELECT
    SUM(product_category_name IS NULL) AS missing_source_category,
    SUM(product_category_name_english IS NULL) AS missing_english_category,
    SUM(TRIM(COALESCE(product_category_name, '')) = '') AS blank_source_category,
    SUM(TRIM(COALESCE(product_category_name_english, '')) = '') AS blank_english_category
FROM translation_stage;

SELECT product_category_name, COUNT(*) AS occurrence_count
FROM translation_stage
GROUP BY product_category_name
HAVING COUNT(*) > 1;

-- Product categories that do not have a translation row.
SELECT p.product_category_name, COUNT(*) AS product_count
FROM products_stage p
LEFT JOIN translation_stage t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND TRIM(p.product_category_name) <> ''
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;

-- =========================================================
-- 7. REFERENTIAL INTEGRITY
-- =========================================================


USE ecommerce_delivery;

-- 1. Orders with unknown customers
SELECT COUNT(*) AS orders_with_unknown_customer
FROM orders_stage o
LEFT JOIN customers_stage c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 2. Items with unknown orders
SELECT COUNT(*) AS items_with_unknown_order
FROM items_stage i
LEFT JOIN orders_stage o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 3. Items with unknown products
SELECT COUNT(*) AS items_with_unknown_product
FROM items_stage i
LEFT JOIN products_stage p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL;


-- =========================================================
-- 8. Optional spot-checks
-- =========================================================
SELECT * FROM customers_stage LIMIT 10;
SELECT * FROM orders_stage LIMIT 10;
SELECT * FROM items_stage LIMIT 10;
SELECT * FROM reviews_stage LIMIT 10;
SELECT * FROM products_stage LIMIT 10;
SELECT * FROM translation_stage LIMIT 10;

-- End of read-only audit. No records are modified.
