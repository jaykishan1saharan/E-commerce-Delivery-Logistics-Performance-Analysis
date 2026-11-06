-- Week 4 Thursday validation — Jaykishan / Member 3
-- MySQL 8.0+, ecommerce_delivery. Read-only queries.
-- Ensure sql/03_create_clean_views.sql has already been executed.
USE ecommerce_delivery;

-- 1) Regional results: export to data/exports/week4_regional_delay_analysis.csv
SELECT
 CASE
  WHEN c.customer_state IN ('AM','RR','AP','PA','TO','RO','AC') THEN 'North'
  WHEN c.customer_state IN ('MA','PI','CE','RN','PB','PE','AL','SE','BA') THEN 'Northeast'
  WHEN c.customer_state IN ('MT','MS','GO','DF') THEN 'Central-West'
  WHEN c.customer_state IN ('SP','RJ','MG','ES') THEN 'Southeast'
  WHEN c.customer_state IN ('PR','SC','RS') THEN 'South'
  ELSE 'Unknown'
 END AS region,
 COUNT(DISTINCT o.order_id) AS total_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
   AND o.order_delivered_customer_date IS NOT NULL
   AND o.order_estimated_delivery_date IS NOT NULL THEN o.order_id END) AS eligible_delivered_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
   AND o.order_delivered_customer_date IS NOT NULL
   AND o.order_estimated_delivery_date IS NOT NULL
   AND o.order_delivered_customer_date > o.order_estimated_delivery_date THEN o.order_id END) AS late_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
   AND o.order_delivered_customer_date IS NOT NULL
   AND o.order_estimated_delivery_date IS NOT NULL
   AND o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id END) AS on_time_orders,
 ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status='delivered'
   AND o.order_delivered_customer_date IS NOT NULL
   AND o.order_estimated_delivery_date IS NOT NULL
   AND o.order_delivered_customer_date > o.order_estimated_delivery_date THEN o.order_id END)
   / NULLIF(COUNT(DISTINCT CASE WHEN o.order_status='delivered'
   AND o.order_delivered_customer_date IS NOT NULL
   AND o.order_estimated_delivery_date IS NOT NULL THEN o.order_id END),0),2) AS late_delivery_rate_pct,
 ROUND(AVG(CASE WHEN o.order_status='delivered'
   AND o.order_purchase_timestamp IS NOT NULL
   AND o.order_delivered_customer_date IS NOT NULL
   THEN TIMESTAMPDIFF(SECOND,o.order_purchase_timestamp,o.order_delivered_customer_date)/86400.0 END),2)
   AS avg_purchase_to_delivery_days
FROM orders_clean o JOIN customers_clean c ON c.customer_id=o.customer_id
GROUP BY region ORDER BY late_delivery_rate_pct DESC, total_orders DESC;

-- 2) State results: export to data/exports/week4_state_delay_analysis.csv
SELECT
 c.customer_state,
 COUNT(DISTINCT o.order_id) AS total_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL THEN o.order_id END) AS eligible_delivered_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date THEN o.order_id END) AS late_orders,
 COUNT(DISTINCT CASE WHEN o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN o.order_id END) AS on_time_orders,
 ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date THEN o.order_id END)
  / NULLIF(COUNT(DISTINCT CASE WHEN o.order_status='delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL THEN o.order_id END),0),2) AS late_delivery_rate_pct,
 ROUND(AVG(CASE WHEN o.order_status='delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  THEN TIMESTAMPDIFF(SECOND,o.order_purchase_timestamp,o.order_delivered_customer_date)/86400.0 END),2)
  AS avg_purchase_to_delivery_days
FROM orders_clean o JOIN customers_clean c ON c.customer_id=o.customer_id
GROUP BY c.customer_state ORDER BY late_delivery_rate_pct DESC, eligible_delivered_orders DESC;

-- 3) Delivery-stage interval audit: export to data/exports/week4_delivery_stage_analysis.csv
SELECT 'purchase_to_approval' AS delivery_stage,
 COUNT(CASE WHEN order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL THEN 1 END) AS records_with_both_timestamps,
 COUNT(CASE WHEN order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL AND order_approved_at>=order_purchase_timestamp THEN 1 END) AS valid_intervals,
 COUNT(CASE WHEN order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL AND order_approved_at<order_purchase_timestamp THEN 1 END) AS negative_intervals,
 ROUND(AVG(CASE WHEN order_purchase_timestamp IS NOT NULL AND order_approved_at IS NOT NULL AND order_approved_at>=order_purchase_timestamp THEN TIMESTAMPDIFF(SECOND,order_purchase_timestamp,order_approved_at)/86400.0 END),2) AS avg_duration_days
FROM orders_clean
UNION ALL
SELECT 'approval_to_carrier_handoff',
 COUNT(CASE WHEN order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL THEN 1 END),
 COUNT(CASE WHEN order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date>=order_approved_at THEN 1 END),
 COUNT(CASE WHEN order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date<order_approved_at THEN 1 END),
 ROUND(AVG(CASE WHEN order_approved_at IS NOT NULL AND order_delivered_carrier_date IS NOT NULL AND order_delivered_carrier_date>=order_approved_at THEN TIMESTAMPDIFF(SECOND,order_approved_at,order_delivered_carrier_date)/86400.0 END),2)
FROM orders_clean
UNION ALL
SELECT 'carrier_handoff_to_customer_delivery',
 COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL THEN 1 END),
 COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date>=order_delivered_carrier_date THEN 1 END),
 COUNT(CASE WHEN order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date<order_delivered_carrier_date THEN 1 END),
 ROUND(AVG(CASE WHEN order_delivered_carrier_date IS NOT NULL AND order_delivered_customer_date IS NOT NULL AND order_delivered_customer_date>=order_delivered_carrier_date THEN TIMESTAMPDIFF(SECOND,order_delivered_carrier_date,order_delivered_customer_date)/86400.0 END),2)
FROM orders_clean;

-- 4) Verify the order/customer join does not multiply order rows.
SELECT COUNT(*) AS joined_rows, COUNT(DISTINCT o.order_id) AS distinct_orders,
 COUNT(*)-COUNT(DISTINCT o.order_id) AS possible_row_multiplication
FROM orders_clean o JOIN customers_clean c ON c.customer_id=o.customer_id;

-- 5) Verify eligible = late + on-time (unclassified should be zero).
SELECT
 COUNT(DISTINCT CASE WHEN order_status='delivered' AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL THEN order_id END) AS eligible_delivered_orders,
 COUNT(DISTINCT CASE WHEN order_status='delivered' AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL AND order_delivered_customer_date>order_estimated_delivery_date THEN order_id END) AS late_orders,
 COUNT(DISTINCT CASE WHEN order_status='delivered' AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL AND order_delivered_customer_date<=order_estimated_delivery_date THEN order_id END) AS on_time_orders,
 COUNT(DISTINCT CASE WHEN order_status='delivered' AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL THEN order_id END)
 - COUNT(DISTINCT CASE WHEN order_status='delivered' AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL AND
  (order_delivered_customer_date>order_estimated_delivery_date OR order_delivered_customer_date<=order_estimated_delivery_date)
  THEN order_id END) AS unclassified_eligible_orders
FROM orders_clean;

-- 6) Schema check: handoff timestamp is not carrier identity; seller_id is not carrier_id.
SHOW COLUMNS FROM orders_clean;
SHOW COLUMNS FROM items_clean;
SELECT COUNT(*) AS item_rows, COUNT(DISTINCT order_id) AS orders_with_items,
 COUNT(DISTINCT seller_id) AS distinct_sellers,
 SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller_id_rows
FROM items_clean;
