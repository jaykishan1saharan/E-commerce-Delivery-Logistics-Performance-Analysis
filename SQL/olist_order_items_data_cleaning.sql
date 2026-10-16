USE ecommerce_delivery;
SHOW TABLES;
SELECT COUNT(*) AS something
FROM ITEMS;
DESCRIBE items;
select
SUM(order_id IS NULL) AS missing_order_id,
SUM(order_item_id IS NULL) AS missing_order_item_id,
SUM(product_id IS NULL) AS missing_product_id,
SUM(seller_id IS NULL) AS missing_seller_id,
SUM(shipping_limit_date IS NULL) AS missing_shipping_limit_date,
SUM(price IS NULL) AS missing_price,
SUM(freight_value IS NULL) AS missing_freight_value
from items;
SELECT price,COUNT(*) As PRICE_count
FROM items
group by price
order by price DESC;



