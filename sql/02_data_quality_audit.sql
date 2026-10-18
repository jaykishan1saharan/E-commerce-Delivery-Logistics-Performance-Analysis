-- =========================================================
-- E-commerce Delivery & Logistics Performance Analysis
-- Data Quality Audit (read-only)
-- Database: ecommerce_delivery
-- Source tables: *_stage
-- IMPORTANT: This file only runs SELECT statements; it does not
-- modify or delete source records.
-- =========================================================

USE ecommerce_delivery;

-- 1. ROW COUNTS
SELECT 'customers_stage' AS table_name, COUNT(*) AS total_rows FROM customers_stage
UNION ALL SELECT 'items_stage', COUNT(*) FROM items_stage
UNION ALL SELECT 'orders_stage', COUNT(*) FROM orders_stage
UNION ALL SELECT 'reviews_stage', COUNT(*) FROM reviews_stage
UNION ALL SELECT 'products_stage', COUNT(*) FROM products_stage
UNION ALL SELECT 'translation_stage', COUNT(*) FROM translation_stage;

-- 2. CUSTOMERS
SELECT
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS blank_customer_id
FROM customers_stage;

SELECT customer_id, COUNT(*) AS occurrence_count
FROM customers_stage
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3. ORDERS
SELECT
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(TRIM(COALESCE(order_id, '')) = '') AS blank_order_id,
    SUM(TRIM(COALESCE(customer_id, '')) = '') AS blank_customer_id
FROM orders_stage;

SELECT order_id, COUNT(*) AS occurrence_count
FROM orders_stage
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. ORDER ITEMS
SELECT
    SUM(order_id IS NULL OR TRIM(COALESCE(order_id, '')) = '') AS missing_order_id,
    SUM(order_item_id IS NULL) AS missing_order_item_id,
    SUM(product_id IS NULL OR TRIM(COALESCE(product_id, '')) = '') AS missing_product_id,
    SUM(seller_id IS NULL OR TRIM(COALESCE(seller_id, '')) = '') AS missing_seller_id,
    SUM(price IS NULL) AS missing_price,
    SUM(freight_value IS NULL) AS missing_freight
FROM items_stage;

SELECT
    SUM(price < 0) AS negative_price_rows,
    SUM(freight_value < 0) AS negative_freight_rows,
    SUM(price = 0) AS zero_price_rows,
    SUM(freight_value = 0) AS zero_freight_rows
FROM items_stage;

SELECT order_id, order_item_id, COUNT(*) AS occurrence_count
FROM items_stage
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- 5. REVIEWS
SELECT COUNT(*) AS total_reviews FROM reviews_stage;

SELECT
    SUM(review_id IS NULL OR TRIM(COALESCE(review_id, '')) = '') AS missing_review_id,
    SUM(order_id IS NULL OR TRIM(COALESCE(order_id, '')) = '') AS missing_order_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_comment_title IS NULL OR TRIM(COALESCE(review_comment_title, '')) = '') AS blank_comment_title,
    SUM(review_comment_message IS NULL OR TRIM(COALESCE(review_comment_message, '')) = '') AS blank_comment_message,
    SUM(review_creation_date IS NULL) AS missing_creation_date,
    SUM(review_answer_timestamp IS NULL) AS missing_answer_timestamp
FROM reviews_stage;

SELECT review_id, COUNT(*) AS occurrence_count
FROM reviews_stage
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT review_score, COUNT(*) AS review_count
FROM reviews_stage
GROUP BY review_score
ORDER BY review_score;

SELECT COUNT(*) AS invalid_review_scores
FROM reviews_stage
WHERE review_score < 1 OR review_score > 5;

-- 6. PRODUCTS
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

-- 7. PRODUCT CATEGORY TRANSLATION
SELECT COUNT(*) AS total_translation_rows FROM translation_stage;

-- The first translation column was imported with a UTF-8 BOM in its
-- name in this database. Use the exact column name shown by DESCRIBE.
-- The query below assumes the column is named `ï»¿product_category_name`.
SELECT
    SUM(`ï»¿product_category_name` IS NULL) AS missing_source_category,
    SUM(product_category_name_english IS NULL) AS missing_english_category,
    SUM(TRIM(COALESCE(`ï»¿product_category_name`, '')) = '') AS blank_source_category,
    SUM(TRIM(COALESCE(product_category_name_english, '')) = '') AS blank_english_category
FROM translation_stage;

SELECT `ï»¿product_category_name`, COUNT(*) AS occurrence_count
FROM translation_stage
GROUP BY `ï»¿product_category_name`
HAVING COUNT(*) > 1;

SELECT p.product_category_name, COUNT(*) AS product_count
FROM products_stage p
LEFT JOIN translation_stage t
    ON p.product_category_name = t.`ï»¿product_category_name`
WHERE p.product_category_name IS NOT NULL
  AND TRIM(p.product_category_name) <> ''
  AND t.`ï»¿product_category_name` IS NULL
GROUP BY p.product_category_name
ORDER BY product_count DESC;

-- 8. REFERENTIAL INTEGRITY
SELECT COUNT(*) AS orders_with_unknown_customer
FROM orders_stage o
LEFT JOIN customers_stage c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_with_unknown_order
FROM items_stage i
LEFT JOIN orders_stage o ON i.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_with_unknown_product
FROM items_stage i
LEFT JOIN products_stage p ON i.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 9. OPTIONAL SPOT-CHECKS
SELECT * FROM customers_stage LIMIT 10;
SELECT * FROM orders_stage LIMIT 10;
SELECT * FROM items_stage LIMIT 10;
SELECT * FROM reviews_stage LIMIT 10;
SELECT * FROM products_stage LIMIT 10;
SELECT * FROM translation_stage LIMIT 10;

-- End of read-only audit. No records are modified.
