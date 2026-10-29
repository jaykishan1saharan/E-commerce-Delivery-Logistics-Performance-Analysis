-- Export this one result set as cleaning_log.csv from MySQL Workbench.
-- Run standard_data_cleaning.sql first to create the *_clean views.
-- MySQL 8.0+. Aggregate CTEs avoid repeated scalar subqueries over the
-- large stage tables and window-function clean views.

USE ecommerce_delivery;

WITH
customer_keys AS (
    SELECT DISTINCT TRIM(customer_id) AS customer_id
    FROM customers_stage
    WHERE NULLIF(TRIM(customer_id), '') IS NOT NULL
),
order_keys AS (
    SELECT DISTINCT TRIM(order_id) AS order_id
    FROM orders_stage
    WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
),
product_keys AS (
    SELECT DISTINCT TRIM(product_id) AS product_id
    FROM products_stage
    WHERE NULLIF(TRIM(product_id), '') IS NOT NULL
),
clean_customer_rows AS (
    SELECT customer_id, customer_unique_id, customer_zip_code_prefix,
           customer_city, customer_state
    FROM customers_clean
),
clean_order_rows AS (
    SELECT order_id, customer_id, order_status, order_purchase_timestamp,
           order_approved_at, order_delivered_carrier_date,
           order_delivered_customer_date, order_estimated_delivery_date
    FROM orders_clean
),
clean_product_rows AS (
    SELECT product_id, product_category_name, product_weight_g,
           product_length_cm, product_height_cm, product_width_cm
    FROM products_clean
),
clean_item_rows AS (
    SELECT order_id, order_item_id, product_id, seller_id,
           shipping_limit_date, price, freight_value
    FROM items_clean
),
clean_review_rows AS (
    SELECT review_id, order_id, review_score, review_comment_title,
           review_comment_message, review_creation_date, review_answer_timestamp
    FROM reviews_clean
),
clean_translation_rows AS (
    SELECT source_category, english_category
    FROM translation_clean
),
clean_customer_keys AS (
    SELECT customer_id
    FROM clean_customer_rows
    WHERE customer_id IS NOT NULL
),
clean_order_keys AS (
    SELECT order_id
    FROM clean_order_rows
    WHERE order_id IS NOT NULL
),
clean_product_keys AS (
    SELECT product_id
    FROM clean_product_rows
    WHERE product_id IS NOT NULL
),
customer_stage AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(NULLIF(TRIM(customer_id), '') IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            NULLIF(TRIM(customer_unique_id), '') IS NULL
            OR NULLIF(TRIM(customer_zip_code_prefix), '') IS NULL
            OR NULLIF(TRIM(customer_city), '') IS NULL
            OR NULLIF(TRIM(customer_state), '') IS NULL
        ), 0) AS missing_attributes,
        COUNT(NULLIF(TRIM(customer_id), '')) AS valid_keys,
        COUNT(DISTINCT NULLIF(TRIM(customer_id), '')) AS distinct_keys
    FROM customers_stage
),
customer_clean AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(customer_id IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            customer_unique_id IS NULL
            OR customer_zip_code_prefix IS NULL
            OR customer_city IS NULL
            OR customer_state IS NULL
        ), 0) AS missing_attributes,
        COUNT(customer_id) AS valid_keys,
        COUNT(DISTINCT customer_id) AS distinct_keys
    FROM clean_customer_rows
),
order_stage AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(NULLIF(TRIM(order_id), '') IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            NULLIF(TRIM(customer_id), '') IS NULL
            OR NULLIF(TRIM(order_status), '') IS NULL
            OR order_purchase_timestamp IS NULL
            OR order_estimated_delivery_date IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(
            order_delivered_carrier_date IS NOT NULL
            AND order_purchase_timestamp IS NOT NULL
            AND order_delivered_carrier_date < order_purchase_timestamp
        ), 0) AS carrier_before_purchase,
        COUNT(NULLIF(TRIM(order_id), '')) AS valid_keys,
        COUNT(DISTINCT NULLIF(TRIM(order_id), '')) AS distinct_keys
    FROM orders_stage
),
order_clean AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(order_id IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            customer_id IS NULL
            OR order_status IS NULL
            OR order_purchase_timestamp IS NULL
            OR order_estimated_delivery_date IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(
            order_delivered_carrier_date IS NOT NULL
            AND order_purchase_timestamp IS NOT NULL
            AND order_delivered_carrier_date < order_purchase_timestamp
        ), 0) AS carrier_before_purchase,
        COUNT(order_id) AS valid_keys,
        COUNT(DISTINCT order_id) AS distinct_keys
    FROM clean_order_rows
),
order_customer_stage AS (
    SELECT COALESCE(SUM(ck.customer_id IS NULL), 0) AS unknown_customer
    FROM orders_stage AS o
    LEFT JOIN customer_keys AS ck
        ON ck.customer_id = TRIM(o.customer_id)
),
order_customer_clean AS (
    SELECT COALESCE(SUM(ck.customer_id IS NULL), 0) AS unknown_customer
    FROM clean_order_rows AS o
    LEFT JOIN clean_customer_keys AS ck ON ck.customer_id = o.customer_id
),
item_stage AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(
            NULLIF(TRIM(i.order_id), '') IS NULL
            OR i.order_item_id IS NULL
        ), 0) AS missing_key,
        COALESCE(SUM(
            NULLIF(TRIM(i.product_id), '') IS NULL
            OR NULLIF(TRIM(i.seller_id), '') IS NULL
            OR i.shipping_limit_date IS NULL
            OR i.price IS NULL
            OR i.freight_value IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(i.price < 0), 0) AS negative_price,
        COALESCE(SUM(i.freight_value < 0), 0) AS negative_freight,
        COALESCE(SUM(i.freight_value = 0), 0) AS zero_freight,
        COALESCE(SUM(ok.order_id IS NULL), 0) AS unknown_order,
        COALESCE(SUM(pk.product_id IS NULL), 0) AS unknown_product,
        COALESCE(SUM(
            NULLIF(TRIM(i.order_id), '') IS NOT NULL
            AND i.order_item_id IS NOT NULL
        ), 0) AS valid_keys,
        COUNT(DISTINCT
            IF(NULLIF(TRIM(i.order_id), '') IS NOT NULL, TRIM(i.order_id), NULL),
            i.order_item_id
        ) AS distinct_keys
    FROM items_stage AS i
    LEFT JOIN order_keys AS ok
        ON ok.order_id = TRIM(i.order_id)
    LEFT JOIN product_keys AS pk
        ON pk.product_id = TRIM(i.product_id)
),
item_clean AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(i.order_id IS NULL OR i.order_item_id IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            i.product_id IS NULL
            OR i.seller_id IS NULL
            OR i.shipping_limit_date IS NULL
            OR i.price IS NULL
            OR i.freight_value IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(i.price < 0), 0) AS negative_price,
        COALESCE(SUM(i.freight_value < 0), 0) AS negative_freight,
        COALESCE(SUM(i.freight_value = 0), 0) AS zero_freight,
        COALESCE(SUM(ok.order_id IS NULL), 0) AS unknown_order,
        COALESCE(SUM(pk.product_id IS NULL), 0) AS unknown_product,
        COUNT(*) AS valid_keys,
        COUNT(DISTINCT i.order_id, i.order_item_id) AS distinct_keys
    FROM clean_item_rows AS i
    LEFT JOIN clean_order_keys AS ok ON ok.order_id = i.order_id
    LEFT JOIN clean_product_keys AS pk ON pk.product_id = i.product_id
),
review_stage AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(NULLIF(TRIM(review_id), '') IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            NULLIF(TRIM(order_id), '') IS NULL
            OR review_score IS NULL
            OR review_creation_date IS NULL
            OR review_answer_timestamp IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(NULLIF(TRIM(review_comment_title), '') IS NULL), 0) AS missing_title,
        COALESCE(SUM(NULLIF(TRIM(review_comment_message), '') IS NULL), 0) AS missing_message,
        COALESCE(SUM(
            review_score IS NOT NULL
            AND review_score NOT BETWEEN 1 AND 5
        ), 0) AS invalid_score,
        COUNT(NULLIF(TRIM(review_id), '')) AS valid_keys,
        COUNT(DISTINCT NULLIF(TRIM(review_id), '')) AS distinct_keys
    FROM reviews_stage
),
review_clean AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(review_id IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            order_id IS NULL
            OR review_score IS NULL
            OR review_creation_date IS NULL
            OR review_answer_timestamp IS NULL
        ), 0) AS missing_attributes,
        COALESCE(SUM(review_comment_title IS NULL), 0) AS missing_title,
        COALESCE(SUM(review_comment_message IS NULL), 0) AS missing_message,
        COALESCE(SUM(
            review_score IS NOT NULL
            AND review_score NOT BETWEEN 1 AND 5
        ), 0) AS invalid_score,
        COUNT(review_id) AS valid_keys,
        COUNT(DISTINCT review_id) AS distinct_keys
    FROM clean_review_rows
),
product_stage AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(NULLIF(TRIM(product_id), '') IS NULL), 0) AS missing_key,
        COALESCE(SUM(NULLIF(TRIM(product_category_name), '') IS NULL), 0) AS missing_category,
        COALESCE(SUM(product_weight_g IS NULL), 0)
            + COALESCE(SUM(product_length_cm IS NULL), 0)
            + COALESCE(SUM(product_height_cm IS NULL), 0)
            + COALESCE(SUM(product_width_cm IS NULL), 0) AS missing_dimensions,
        COALESCE(SUM(product_weight_g <= 0), 0)
            + COALESCE(SUM(product_length_cm <= 0), 0)
            + COALESCE(SUM(product_height_cm <= 0), 0)
            + COALESCE(SUM(product_width_cm <= 0), 0) AS nonpositive_dimensions,
        COUNT(NULLIF(TRIM(product_id), '')) AS valid_keys,
        COUNT(DISTINCT NULLIF(TRIM(product_id), '')) AS distinct_keys
    FROM products_stage
),
product_clean AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(product_id IS NULL), 0) AS missing_key,
        COALESCE(SUM(product_category_name IS NULL), 0) AS missing_category,
        COALESCE(SUM(product_weight_g IS NULL), 0)
            + COALESCE(SUM(product_length_cm IS NULL), 0)
            + COALESCE(SUM(product_height_cm IS NULL), 0)
            + COALESCE(SUM(product_width_cm IS NULL), 0) AS missing_dimensions,
        COALESCE(SUM(product_weight_g <= 0), 0)
            + COALESCE(SUM(product_length_cm <= 0), 0)
            + COALESCE(SUM(product_height_cm <= 0), 0)
            + COALESCE(SUM(product_width_cm <= 0), 0) AS nonpositive_dimensions,
        COUNT(product_id) AS valid_keys,
        COUNT(DISTINCT product_id) AS distinct_keys
    FROM clean_product_rows
),
translation_stage_stats AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(NULLIF(TRIM(product_category_name), '') IS NULL), 0) AS missing_key,
        COALESCE(SUM(
            NULLIF(TRIM(product_category_name), '') IS NOT NULL
            AND NULLIF(TRIM(product_category_name_english), '') IS NULL
        ), 0) AS missing_english,
        COUNT(NULLIF(TRIM(product_category_name), '')) AS valid_keys,
        COUNT(DISTINCT NULLIF(TRIM(product_category_name), '')) AS distinct_keys
    FROM translation_stage
),
translation_clean_stats AS (
    SELECT
        COUNT(*) AS total_rows,
        COALESCE(SUM(source_category IS NULL), 0) AS missing_key,
        COALESCE(SUM(english_category IS NULL), 0) AS missing_english,
        COUNT(source_category) AS valid_keys,
        COUNT(DISTINCT source_category) AS distinct_keys
    FROM clean_translation_rows
),
log_rows AS (
    SELECT 'customers' AS dataset, 'Missing required customer_id' AS issue,
        'rows' AS measure, s.missing_key AS affected_rows,
        'Exclude rows without customer_id from customers_clean' AS action_taken,
        'A stable customer_id is required to identify a customer.' AS reason,
        s.missing_key AS before_count, c.missing_key AS after_count,
        IF(c.missing_key = 0, 'PASS', 'FAIL') AS verification_status
    FROM customer_stage AS s CROSS JOIN customer_clean AS c

    UNION ALL
    SELECT 'customers', 'Duplicate customer_id', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys,
        'Keep one most-complete row per ID',
        'One customer row per customer_id prevents duplicate entities.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM customer_stage AS s CROSS JOIN customer_clean AS c

    UNION ALL
    SELECT 'customers', 'Missing optional customer attributes', 'rows',
        s.missing_attributes,
        'Normalize blanks to NULL; retain missing attributes',
        'Do not infer customer values that are absent.',
        s.missing_attributes, c.missing_attributes, 'EXPECTED_RETAINED'
    FROM customer_stage AS s CROSS JOIN customer_clean AS c

    UNION ALL
    SELECT 'customers', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create customers_clean; preserve customers_stage',
        'Any row reduction should equal missing-key rows plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM customer_stage AS s CROSS JOIN customer_clean AS c

    UNION ALL
    SELECT 'orders', 'Missing required order_id', 'rows',
        s.missing_key, 'Exclude rows without order_id from orders_clean',
        'A stable order_id is required to identify an order.',
        s.missing_key, c.missing_key, IF(c.missing_key = 0, 'PASS', 'FAIL')
    FROM order_stage AS s CROSS JOIN order_clean AS c

    UNION ALL
    SELECT 'orders', 'Duplicate order_id', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys, 'Keep one most-complete row per ID',
        'One row per order_id prevents double-counting orders.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM order_stage AS s CROSS JOIN order_clean AS c

    UNION ALL
    SELECT 'orders', 'Missing non-key fields', 'rows',
        s.missing_attributes, 'Normalize blanks to NULL; retain missing values',
        'Missing dates or status cannot be safely reconstructed.',
        s.missing_attributes, c.missing_attributes, 'EXPECTED_RETAINED'
    FROM order_stage AS s CROSS JOIN order_clean AS c

    UNION ALL
    SELECT 'orders', 'Carrier timestamp before purchase', 'rows',
        s.carrier_before_purchase, 'Flag and retain; do not change timestamps',
        'Timezone or source timestamp problems need investigation.',
        s.carrier_before_purchase, c.carrier_before_purchase,
        IF(c.carrier_before_purchase = 0, 'PASS', 'REVIEW_REQUIRED')
    FROM order_stage AS s CROSS JOIN order_clean AS c

    UNION ALL
    SELECT 'orders', 'Orders with unknown customer', 'rows',
        s.unknown_customer,
        'Flag and retain; do not guess a customer ID',
        'A missing customer reference needs source investigation.',
        s.unknown_customer, c.unknown_customer,
        IF(c.unknown_customer = 0, 'PASS', 'REVIEW_REQUIRED')
    FROM order_customer_stage AS s CROSS JOIN order_customer_clean AS c

    UNION ALL
    SELECT 'orders', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create orders_clean; preserve orders_stage',
        'Any row reduction should equal missing-key rows plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM order_stage AS s CROSS JOIN order_clean AS c

    UNION ALL
    SELECT 'items', 'Missing composite order-item key', 'rows',
        s.missing_key, 'Exclude rows missing order_id or order_item_id',
        'Both columns are required to identify an order item.',
        s.missing_key, c.missing_key, IF(c.missing_key = 0, 'PASS', 'FAIL')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Duplicate order_id and order_item_id', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys, 'Keep one most-complete row per key',
        'The composite key identifies one order line.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Missing non-key fields', 'rows',
        s.missing_attributes, 'Normalize blanks to NULL; retain missing values',
        'Do not infer product, seller, shipping date, or amount values.',
        s.missing_attributes, c.missing_attributes, 'EXPECTED_RETAINED'
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Negative item prices', 'rows',
        s.negative_price, 'Set negative prices to NULL',
        'Negative prices are invalid; zero prices are retained.',
        s.negative_price, c.negative_price,
        IF(c.negative_price = 0, 'PASS', 'FAIL')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Negative freight values', 'rows',
        s.negative_freight, 'Set negative freight to NULL',
        'Negative freight is invalid; zero freight can be legitimate.',
        s.negative_freight, c.negative_freight,
        IF(c.negative_freight = 0, 'PASS', 'FAIL')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Zero freight values retained', 'rows',
        s.zero_freight, 'Retain zero freight values unchanged',
        'Zero freight can be a valid business value.',
        s.zero_freight, c.zero_freight,
        IF(s.zero_freight = c.zero_freight, 'PASS', 'CHECK')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Items with unknown order', 'rows',
        s.unknown_order, 'Flag and retain; do not delete the item',
        'Verify the missing order reference in the source data.',
        s.unknown_order, c.unknown_order,
        IF(c.unknown_order = 0, 'PASS', 'REVIEW_REQUIRED')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Items with unknown product', 'rows',
        s.unknown_product, 'Flag and retain; do not guess product details',
        'Verify the missing product reference in the source data.',
        s.unknown_product, c.unknown_product,
        IF(c.unknown_product = 0, 'PASS', 'REVIEW_REQUIRED')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'items', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create items_clean; preserve items_stage',
        'Any row reduction should equal missing-key rows plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM item_stage AS s CROSS JOIN item_clean AS c

    UNION ALL
    SELECT 'reviews', 'Missing required review_id', 'rows',
        s.missing_key, 'Exclude rows without review_id from reviews_clean',
        'review_id is required to identify and deduplicate a review.',
        s.missing_key, c.missing_key, IF(c.missing_key = 0, 'PASS', 'FAIL')
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Duplicate review_id', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys, 'Keep one most-complete row per review_id',
        'Duplicate review IDs inflate review counts.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Missing non-key review fields', 'rows',
        s.missing_attributes, 'Normalize blanks to NULL; retain review rows',
        'No missing score, order, or date is inferred.',
        s.missing_attributes, c.missing_attributes, 'EXPECTED_RETAINED'
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Missing optional comment title', 'rows',
        s.missing_title, 'Normalize blank titles to NULL; retain reviews',
        'Review titles are optional and should not be fabricated.',
        s.missing_title, c.missing_title, 'EXPECTED_RETAINED'
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Missing optional comment message', 'rows',
        s.missing_message, 'Normalize blank messages to NULL; retain reviews',
        'Review messages are optional and should not be fabricated.',
        s.missing_message, c.missing_message, 'EXPECTED_RETAINED'
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Invalid scores outside 1-5', 'rows',
        s.invalid_score, 'Set invalid scores to NULL',
        'Only scores 1 through 5 are valid; no replacement is inferred.',
        s.invalid_score, c.invalid_score, IF(c.invalid_score = 0, 'PASS', 'FAIL')
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'reviews', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create reviews_clean; preserve reviews_stage',
        'Row reduction should equal missing review IDs plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM review_stage AS s CROSS JOIN review_clean AS c

    UNION ALL
    SELECT 'products', 'Missing required product_id', 'rows',
        s.missing_key, 'Exclude rows without product_id from products_clean',
        'A stable product ID is required to identify a product.',
        s.missing_key, c.missing_key, IF(c.missing_key = 0, 'PASS', 'FAIL')
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'products', 'Duplicate product_id', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys, 'Keep one most-complete row per product',
        'One row per product_id prevents duplicate products.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'products', 'Missing or blank categories', 'rows',
        s.missing_category, 'Normalize blanks to NULL; retain unknown categories',
        'A missing product category cannot be safely inferred.',
        s.missing_category, c.missing_category, 'EXPECTED_RETAINED'
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'products', 'Missing dimensions', 'field values',
        s.missing_dimensions, 'Retain missing dimensions as NULL',
        'Missing weight or dimensions cannot be safely inferred.',
        s.missing_dimensions, c.missing_dimensions, 'EXPECTED_RETAINED'
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'products', 'Nonpositive dimensions', 'field values',
        s.nonpositive_dimensions, 'Set nonpositive dimensions to NULL',
        'Supplied weights and dimensions must be positive.',
        s.nonpositive_dimensions, c.nonpositive_dimensions,
        IF(c.nonpositive_dimensions = 0, 'PASS', 'FAIL')
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'products', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create products_clean; preserve products_stage',
        'Any row reduction should equal missing-key rows plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM product_stage AS s CROSS JOIN product_clean AS c

    UNION ALL
    SELECT 'translations', 'Missing source category key', 'rows',
        s.missing_key, 'Exclude rows without a source category key',
        'A translation cannot be joined without its source category.',
        s.missing_key, c.missing_key, IF(c.missing_key = 0, 'PASS', 'FAIL')
    FROM translation_stage_stats AS s CROSS JOIN translation_clean_stats AS c

    UNION ALL
    SELECT 'translations', 'Duplicate source category keys', 'excess duplicate rows',
        s.valid_keys - s.distinct_keys, 'Keep one translation per source category',
        'A source category should map to at most one clean translation.',
        s.valid_keys - s.distinct_keys, c.valid_keys - c.distinct_keys,
        IF(c.valid_keys = c.distinct_keys, 'PASS', 'FAIL')
    FROM translation_stage_stats AS s CROSS JOIN translation_clean_stats AS c

    UNION ALL
    SELECT 'translations', 'Missing English category label', 'rows',
        s.missing_english, 'Normalize blank labels to NULL; retain known source keys',
        'Do not guess an English translation.',
        s.missing_english, c.missing_english, 'EXPECTED_RETAINED'
    FROM translation_stage_stats AS s CROSS JOIN translation_clean_stats AS c

    UNION ALL
    SELECT 'translations', 'Total source versus clean rows', 'table rows',
        GREATEST(s.total_rows - c.total_rows, 0),
        'Create translation_clean; preserve translation_stage',
        'Any row reduction should equal missing keys plus duplicate excess.',
        s.total_rows, c.total_rows,
        IF(s.total_rows - c.total_rows = s.missing_key + s.valid_keys - s.distinct_keys,
            'PASS', 'CHECK')
    FROM translation_stage_stats AS s CROSS JOIN translation_clean_stats AS c
)
SELECT
    dataset,
    issue,
    measure,
    affected_rows,
    action_taken,
    reason,
    before_count,
    after_count,
    verification_status
FROM log_rows
ORDER BY dataset, issue;
