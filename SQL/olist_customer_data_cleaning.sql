USE ecommerce_delivery;

SHOW TABLES;

SELECT COUNT(*) AS TOTAL_CUSTOMERS
FROM customers;
SELECT * FROM customers LIMIT 10;
describe customers;

SELECT 
SUM(customer_id Is NULL)AS missing_customer_id,
SUM(customer_unique_id IS NULL)AS missing_customer_uid,
SUM(customer_zip_code_prefix IS NULL)AS missing_zip,
SUM(customer_city IS NULL)AS missing_city,
SUM(customer_state IS NULL)AS missing_state
FROM customers;

SELECT customer_id , COUNT(*)AS duplicate
FROM customers
group by customer_id
HAVING COUNT(*)>1;

SELECT customer_state ,COUNT(*)AS state
FROM customers
group by customer_state
ORDER BY state  DESC;


