USE ecommerce_delivery;

SELECT COUNT(*) AS total_products
FROM products;

DESCRIBE products;
SELECT 
    SUM(TRIM(product_id) = '') AS empty_product_id,
    SUM(TRIM(product_category_name) = '') AS empty_product_category_name
    FROM Products;





