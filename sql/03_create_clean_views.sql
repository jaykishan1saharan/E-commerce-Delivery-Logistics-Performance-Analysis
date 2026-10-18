-- =========================================================
-- E-commerce Delivery & Logistics Performance Analysis
-- MySQL 8.0+ data profiling and cleaning views
-- Database: ecommerce_delivery
--
-- Source tables (*_stage) are read-only inputs. This script
-- creates/replaces *_clean views and does not modify CSV imports.
-- Run the profile queries first and review exceptions before analysis.
-- =========================================================

USE ecommerce_delivery;

-- 1. IMPORT COUNTS
SELECT 'customers_stage' AS table_name, COUNT(*) AS total_rows FROM customers_stage
UNION ALL SELECT 'orders_stage', COUNT(*) FROM orders_stage
UNION ALL SELECT 'items_stage', COUNT(*) FROM items_stage
UNION ALL SELECT 'reviews_stage', COUNT(*) FROM reviews_stage
UNION ALL SELECT 'products_stage', COUNT(*) FROM products_stage
UNION ALL SELECT 'translation_stage', COUNT(*) FROM translation_stage;

-- 2. PROFILE MISSING AND BLANK VALUES
SELECT
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS missing_customer_id,
    SUM(customer_unique_id IS NULL OR TRIM(customer_unique_id) = '') AS missing_customer_unique_id,
    SUM(customer_zip_code_prefix IS NULL OR TRIM(customer_zip_code_prefix) = '') AS missing_zip,
    SUM(customer_city IS NULL OR TRIM(customer_city) = '') AS missing_city,
    SUM(customer_state IS NULL OR TRIM(customer_state) = '') AS missing_state
FROM customers_stage;

SELECT
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(customer_id IS NULL OR TRIM(customer_id) = '') AS missing_customer_id,
    SUM(order_status IS NULL OR TRIM(order_status) = '') AS missing_order_status,
    SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamp,
    SUM(order_estimated_delivery_date IS NULL) AS missing_estimated_delivery_date
FROM orders_stage;

SELECT
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(order_item_id IS NULL) AS missing_order_item_id,
    SUM(product_id IS NULL OR TRIM(product_id) = '') AS missing_product_id,
    SUM(seller_id IS NULL OR TRIM(seller_id) = '') AS missing_seller_id,
    SUM(shipping_limit_date IS NULL) AS missing_shipping_limit_date,
    SUM(price IS NULL) AS missing_price,
    SUM(freight_value IS NULL) AS missing_freight_value
FROM items_stage;

SELECT
    SUM(review_id IS NULL OR TRIM(review_id) = '') AS missing_review_id,
    SUM(order_id IS NULL OR TRIM(order_id) = '') AS missing_order_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_comment_title IS NULL OR TRIM(review_comment_title) = '') AS blank_comment_title,
    SUM(review_comment_message IS NULL OR TRIM(review_comment_message) = '') AS blank_comment_message,
    SUM(review_creation_date IS NULL) AS missing_creation_date,
    SUM(review_answer_timestamp IS NULL) AS missing_answer_timestamp
FROM reviews_stage;

SELECT
    SUM(product_id IS NULL OR TRIM(product_id) = '') AS missing_product_id,
    SUM(product_category_name IS NULL OR TRIM(product_category_name) = '') AS missing_product_category,
    SUM(product_length_cm IS NULL OR product_length_cm <= 0) AS invalid_length,
    SUM(product_height_cm IS NULL OR product_height_cm <= 0) AS invalid_height,
    SUM(product_width_cm IS NULL OR product_width_cm <= 0) AS invalid_width,
    SUM(product_weight_g IS NULL OR product_weight_g <= 0) AS invalid_weight
FROM products_stage;

-- Translation table columns use the CSV header names without a BOM.
DESCRIBE translation_stage;

SELECT
    SUM(product_category_name IS NULL
        OR TRIM(product_category_name) = '') AS missing_source_category,
    SUM(product_category_name_english IS NULL
        OR TRIM(product_category_name_english) = '') AS missing_english_category
FROM translation_stage;

-- 3. PROFILE DUPLICATE KEYS
SELECT customer_id, COUNT(*) AS row_count
FROM customers_stage
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS row_count
FROM orders_stage
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*) AS row_count
FROM items_stage
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT review_id, COUNT(*) AS row_count
FROM reviews_stage
GROUP BY review_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*) AS row_count
FROM products_stage
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 4. PROFILE INVALID VALUES AND TIMESTAMP SEQUENCES
SELECT
    SUM(price < 0) AS negative_price_rows,
    SUM(freight_value < 0) AS negative_freight_rows,
    SUM(price = 0) AS zero_price_rows,
    SUM(freight_value = 0) AS zero_freight_rows
FROM items_stage;

SELECT review_score, COUNT(*) AS review_count
FROM reviews_stage
GROUP BY review_score
ORDER BY review_score;

SELECT *
FROM reviews_stage
WHERE review_score IS NOT NULL
  AND review_score NOT BETWEEN 1 AND 5;

SELECT order_id, order_status, order_purchase_timestamp, order_approved_at,
       order_delivered_carrier_date, order_delivered_customer_date,
       order_estimated_delivery_date
FROM orders_stage
WHERE (order_approved_at IS NOT NULL
       AND order_purchase_timestamp IS NOT NULL
       AND order_approved_at < order_purchase_timestamp)
   OR (order_delivered_carrier_date IS NOT NULL
       AND order_purchase_timestamp IS NOT NULL
       AND order_delivered_carrier_date < order_purchase_timestamp)
   OR (order_delivered_customer_date IS NOT NULL
       AND order_purchase_timestamp IS NOT NULL
       AND order_delivered_customer_date < order_purchase_timestamp);

-- 5. PROFILE ORPHANED REFERENCES
SELECT COUNT(*) AS orders_with_unknown_customer
FROM orders_stage AS o
LEFT JOIN customers_stage AS c
    ON TRIM(o.customer_id) = TRIM(c.customer_id)
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_with_unknown_order
FROM items_stage AS i
LEFT JOIN orders_stage AS o
    ON TRIM(i.order_id) = TRIM(o.order_id)
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_with_unknown_product
FROM items_stage AS i
LEFT JOIN products_stage AS p
    ON TRIM(i.product_id) = TRIM(p.product_id)
WHERE p.product_id IS NULL;

-- 6. CREATE CLEAN VIEWS
-- These views trim text, convert blank text to NULL, omit rows without
-- required keys, and retain one row per business key. Duplicate rows are
-- ranked by completeness and then by values for repeatable tie-breaking.
-- Zero prices/freight are retained; negative amounts and nonpositive
-- product dimensions are set to NULL in the clean views.

CREATE OR REPLACE VIEW customers_clean AS
SELECT customer_id, customer_unique_id, customer_zip_code_prefix,
       customer_city, customer_state
FROM (
    SELECT
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(customer_unique_id), '') AS customer_unique_id,
        NULLIF(TRIM(customer_zip_code_prefix), '') AS customer_zip_code_prefix,
        NULLIF(TRIM(customer_city), '') AS customer_city,
        UPPER(NULLIF(TRIM(customer_state), '')) AS customer_state,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(customer_id), '')
            ORDER BY
                ((NULLIF(TRIM(customer_unique_id), '') IS NOT NULL)
                 + (NULLIF(TRIM(customer_zip_code_prefix), '') IS NOT NULL)
                 + (NULLIF(TRIM(customer_city), '') IS NOT NULL)
                 + (NULLIF(TRIM(customer_state), '') IS NOT NULL)) DESC,
                NULLIF(TRIM(customer_unique_id), ''),
                NULLIF(TRIM(customer_zip_code_prefix), ''),
                NULLIF(TRIM(customer_city), ''),
                UPPER(NULLIF(TRIM(customer_state), ''))
        ) AS row_num
    FROM customers_stage
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
) AS ranked
WHERE row_num = 1;

CREATE OR REPLACE VIEW orders_clean AS
SELECT order_id, customer_id, order_status, order_purchase_timestamp,
       order_approved_at, order_delivered_carrier_date,
       order_delivered_customer_date, order_estimated_delivery_date
FROM (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        LOWER(NULLIF(TRIM(order_status), '')) AS order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(order_id), '')
            ORDER BY
                ((NULLIF(TRIM(customer_id), '') IS NOT NULL)
                 + (NULLIF(TRIM(order_status), '') IS NOT NULL)
                 + (order_purchase_timestamp IS NOT NULL)
                 + (order_approved_at IS NOT NULL)
                 + (order_delivered_carrier_date IS NOT NULL)
                 + (order_delivered_customer_date IS NOT NULL)
                 + (order_estimated_delivery_date IS NOT NULL)) DESC,
                NULLIF(TRIM(customer_id), ''),
                LOWER(NULLIF(TRIM(order_status), '')),
                order_purchase_timestamp,
                order_approved_at,
                order_delivered_carrier_date,
                order_delivered_customer_date,
                order_estimated_delivery_date
        ) AS row_num
    FROM orders_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
) AS ranked
WHERE row_num = 1;

CREATE OR REPLACE VIEW items_clean AS
SELECT order_id, order_item_id, product_id, seller_id,
       shipping_limit_date, price, freight_value
FROM (
    SELECT
        NULLIF(TRIM(order_id), '') AS order_id,
        order_item_id,
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(seller_id), '') AS seller_id,
        shipping_limit_date,
        CASE WHEN price >= 0 THEN price ELSE NULL END AS price,
        CASE WHEN freight_value >= 0 THEN freight_value ELSE NULL END AS freight_value,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(order_id), ''), order_item_id
            ORDER BY
                ((NULLIF(TRIM(product_id), '') IS NOT NULL)
                 + (NULLIF(TRIM(seller_id), '') IS NOT NULL)
                 + (shipping_limit_date IS NOT NULL)
                 + COALESCE(price >= 0, 0)
                 + COALESCE(freight_value >= 0, 0)) DESC,
                NULLIF(TRIM(product_id), ''),
                NULLIF(TRIM(seller_id), ''),
                shipping_limit_date,
                CASE WHEN price >= 0 THEN price ELSE NULL END,
                CASE WHEN freight_value >= 0 THEN freight_value ELSE NULL END
        ) AS row_num
    FROM items_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
      AND order_item_id IS NOT NULL
) AS ranked
WHERE row_num = 1;

CREATE OR REPLACE VIEW reviews_clean AS
SELECT review_id, order_id, review_score, review_comment_title,
       review_comment_message, review_creation_date, review_answer_timestamp
FROM (
    SELECT
        NULLIF(TRIM(review_id), '') AS review_id,
        NULLIF(TRIM(order_id), '') AS order_id,
        CASE WHEN review_score BETWEEN 1 AND 5 THEN review_score ELSE NULL END
            AS review_score,
        NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
        NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(review_id), '')
            ORDER BY
                ((NULLIF(TRIM(order_id), '') IS NOT NULL)
                 + COALESCE(review_score BETWEEN 1 AND 5, 0)
                 + (NULLIF(TRIM(review_comment_title), '') IS NOT NULL)
                 + (NULLIF(TRIM(review_comment_message), '') IS NOT NULL)
                 + (review_creation_date IS NOT NULL)
                 + (review_answer_timestamp IS NOT NULL)) DESC,
                NULLIF(TRIM(order_id), ''),
                review_score,
                NULLIF(TRIM(review_comment_title), ''),
                NULLIF(TRIM(review_comment_message), ''),
                review_creation_date,
                review_answer_timestamp
        ) AS row_num
    FROM reviews_stage
    WHERE NULLIF(TRIM(review_id), '') IS NOT NULL
) AS ranked
WHERE row_num = 1;

CREATE OR REPLACE VIEW products_clean AS
SELECT product_id, product_category_name, product_name_lenght,
       product_description_lenght, product_photos_qty, product_weight_g,
       product_length_cm, product_height_cm, product_width_cm
FROM (
    SELECT
        NULLIF(TRIM(product_id), '') AS product_id,
        NULLIF(TRIM(product_category_name), '') AS product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        CASE WHEN product_weight_g > 0 THEN product_weight_g ELSE NULL END
            AS product_weight_g,
        CASE WHEN product_length_cm > 0 THEN product_length_cm ELSE NULL END
            AS product_length_cm,
        CASE WHEN product_height_cm > 0 THEN product_height_cm ELSE NULL END
            AS product_height_cm,
        CASE WHEN product_width_cm > 0 THEN product_width_cm ELSE NULL END
            AS product_width_cm,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(product_id), '')
            ORDER BY
                ((NULLIF(TRIM(product_category_name), '') IS NOT NULL)
                 + (product_name_lenght IS NOT NULL)
                 + (product_description_lenght IS NOT NULL)
                 + (product_photos_qty IS NOT NULL)
                 + COALESCE(product_weight_g > 0, 0)
                 + COALESCE(product_length_cm > 0, 0)
                 + COALESCE(product_height_cm > 0, 0)
                 + COALESCE(product_width_cm > 0, 0)) DESC,
                NULLIF(TRIM(product_category_name), ''),
                product_name_lenght,
                product_description_lenght,
                product_photos_qty,
                product_weight_g,
                product_length_cm,
                product_height_cm,
                product_width_cm
        ) AS row_num
    FROM products_stage
    WHERE NULLIF(TRIM(product_id), '') IS NOT NULL
) AS ranked
WHERE row_num = 1;

CREATE OR REPLACE VIEW translation_clean AS
SELECT source_category, english_category
FROM (
    SELECT
        NULLIF(TRIM(product_category_name), '') AS source_category,
        NULLIF(TRIM(product_category_name_english), '') AS english_category,
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(product_category_name), '')
            ORDER BY
                (NULLIF(TRIM(product_category_name_english), '') IS NOT NULL) DESC,
                NULLIF(TRIM(product_category_name_english), '')
        ) AS row_num
    FROM translation_stage
    WHERE NULLIF(TRIM(product_category_name), '') IS NOT NULL
) AS ranked
WHERE row_num = 1;

-- 7. VALIDATE CLEAN VIEWS
SELECT 'customers_clean' AS table_name, COUNT(*) AS total_rows FROM customers_clean
UNION ALL SELECT 'orders_clean', COUNT(*) FROM orders_clean
UNION ALL SELECT 'items_clean', COUNT(*) FROM items_clean
UNION ALL SELECT 'reviews_clean', COUNT(*) FROM reviews_clean
UNION ALL SELECT 'products_clean', COUNT(*) FROM products_clean
UNION ALL SELECT 'translation_clean', COUNT(*) FROM translation_clean;

SELECT customer_id, COUNT(*) AS row_count
FROM customers_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS row_count
FROM orders_clean
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_id, order_item_id, COUNT(*) AS row_count
FROM items_clean
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

SELECT
    (SELECT COUNT(*)
     FROM orders_clean AS o
     LEFT JOIN customers_clean AS c ON o.customer_id = c.customer_id
     WHERE c.customer_id IS NULL) AS orders_without_clean_customer,
    (SELECT COUNT(*)
     FROM items_clean AS i
     LEFT JOIN orders_clean AS o ON i.order_id = o.order_id
     WHERE o.order_id IS NULL) AS items_without_clean_order,
    (SELECT COUNT(*)
     FROM items_clean AS i
     LEFT JOIN products_clean AS p ON i.product_id = p.product_id
     WHERE p.product_id IS NULL) AS items_without_clean_product;

-- Spot-check cleaned results.
SELECT * FROM customers_clean LIMIT 10;
SELECT * FROM orders_clean LIMIT 10;
SELECT * FROM items_clean LIMIT 10;
SELECT * FROM reviews_clean LIMIT 10;
SELECT * FROM products_clean LIMIT 10;
SELECT * FROM translation_clean LIMIT 10;
