USE ecommerce_delivery;
SHOW tables;
SELECT COUNT(*)AS something
From orders;
SELECT* FROM orders LIMIT 10;

describe orders;

SELECT
SUM(order_id IS NULL) AS missing_order_id,
SUM(customer_id IS NULL) AS missing_customer_id,
SUM(order_status IS NULL) AS missing_order_status,
SUM(order_purchase_timestamp IS NULL) AS missing_purchase_timestamp,
SUM(order_approved_at IS NULL) AS missing_order_approval,
SUM(order_delivered_carrier_date IS NULL) AS missing_order_delivered_carrier_date,
SUM(order_delivered_customer_date IS NULL) AS missing_order_delivered_customer_date,
SUM(order_estimated_delivery_date IS NULL) AS missing_order_estimated_delivery_date
FROM orders;
SELECT order_id, COUNT(*) AS duplicate
FROM orders
group by order_id
HAVING COUNT(*)>1;
SELECT order_status , COUNT(*) AS stats
FROM orders
group by order_status
order by stats DESC;


