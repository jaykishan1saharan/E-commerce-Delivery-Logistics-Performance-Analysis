USE ecommerce_delivery;
SHOW TABLES;
select count(*) as Something
from reviews;
describe reviews;

SELECT
    SUM(review_id IS NULL) AS missing_review_id,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(review_score IS NULL) AS missing_review_score,
    SUM(review_comment_title IS NULL) AS missing_review_comment_title,
    SUM(TRIM(review_comment_title)='')AS empty_review_comment_title,
    SUM(review_comment_message IS NULL) AS missing_review_comment_message,
    SUM(TRIM(review_comment_message) = '') AS empty_review_comment_message,
    SUM(review_creation_date IS NULL) AS missing_review_creation_date,
    SUM(review_answer_timestamp IS NULL) AS missing_review_answer_timestamp
FROM reviews;

SELECT review_score ,COUNT(*) AS score
FROM reviews
group by review_score
ORDER BY review_score;



