-- 06_create_kpi_views.sql
-- Builds the Week 2 master tables (SQLite). Assumes raw tables already loaded:
-- orders, customers, order_items, order_reviews, products, category_translation

DROP VIEW IF EXISTS kpi_orders;
DROP VIEW IF EXISTS kpi_orders_all;

-- Master table: ONE ROW PER ORDER (all statuses, so cancellation rate can be computed)
CREATE VIEW kpi_orders_all AS
WITH items AS (          -- collapse items to one row per order
    SELECT order_id,
           COUNT(*)                         AS n_items,
           SUM(price)                       AS order_value,
           SUM(freight_value)               AS freight_total
    FROM order_items GROUP BY order_id
),
main_item AS (           -- category of the most expensive item represents the order
    SELECT order_id, product_id FROM (
        SELECT order_id, product_id,
               ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY price DESC, order_item_id) AS rn
        FROM order_items) WHERE rn = 1
),
reviews AS (             -- one review per order: the most recent one
    SELECT order_id, review_score FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (PARTITION BY order_id
                                  ORDER BY review_answer_timestamp DESC, review_id) AS rn
        FROM order_reviews) WHERE rn = 1
)
SELECT
    o.order_id,
    o.order_status,
    c.customer_state,
    CASE WHEN c.customer_state IN ('AC','AP','AM','PA','RO','RR','TO') THEN 'North'
         WHEN c.customer_state IN ('AL','BA','CE','MA','PB','PE','PI','RN','SE') THEN 'Northeast'
         WHEN c.customer_state IN ('DF','GO','MT','MS') THEN 'Central-West'
         WHEN c.customer_state IN ('ES','MG','RJ','SP') THEN 'Southeast'
         WHEN c.customer_state IN ('PR','RS','SC') THEN 'South' END AS region,
    o.order_purchase_timestamp,
    STRFTIME('%w', o.order_purchase_timestamp) AS weekday_num,   -- 0 = Sunday
    CASE STRFTIME('%w', o.order_purchase_timestamp)
         WHEN '0' THEN 'Sun' WHEN '1' THEN 'Mon' WHEN '2' THEN 'Tue' WHEN '3' THEN 'Wed'
         WHEN '4' THEN 'Thu' WHEN '5' THEN 'Fri' WHEN '6' THEN 'Sat' END AS weekday,
    COALESCE(t.product_category_name_english, p.product_category_name) AS category,
    i.n_items, i.order_value, i.freight_total,
    r.review_score,
    -- KPI columns (days)
    ROUND(JULIANDAY(o.order_approved_at) - JULIANDAY(o.order_purchase_timestamp), 3)          AS approval_days,
    ROUND(JULIANDAY(o.order_delivered_carrier_date) - JULIANDAY(o.order_approved_at), 3)      AS handling_days,
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_purchase_timestamp), 2) AS delivery_days,
    ROUND(JULIANDAY(o.order_delivered_customer_date) - JULIANDAY(o.order_estimated_delivery_date), 2) AS delay_days,
    CASE WHEN o.order_delivered_customer_date IS NULL OR o.order_delivered_customer_date = '' THEN NULL
         WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1 ELSE 0 END AS is_on_time,
    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END AS is_canceled,
    CASE WHEN r.review_score <= 2 THEN 1 WHEN r.review_score IS NULL THEN NULL ELSE 0 END AS is_low_rating
FROM orders o
LEFT JOIN customers c   ON c.customer_id = o.customer_id
LEFT JOIN items i       ON i.order_id = o.order_id
LEFT JOIN main_item m   ON m.order_id = o.order_id
LEFT JOIN products p    ON p.product_id = m.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
LEFT JOIN reviews r     ON r.order_id = o.order_id;

-- Delivered-order subset used for all delay KPIs
CREATE VIEW kpi_orders AS
SELECT * FROM kpi_orders_all
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL
  AND delay_days IS NOT NULL;