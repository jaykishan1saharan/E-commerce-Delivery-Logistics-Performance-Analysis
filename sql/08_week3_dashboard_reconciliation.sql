-- Reconcile every Week 3 PBIX visual to its imported CSV snapshot.
-- Load data/interim/kpi_orders_all.csv as a SQLite table named dashboard_orders
-- before running this query. The CSV has one row per order in the checked
-- snapshot; the query still uses DISTINCTCOUNT-equivalent expressions.
--
-- This validates the PBIX visual aggregations against their actual imported
-- source. It does not replace a fresh MySQL source-to-export reconciliation.

WITH dashboard AS (
    SELECT
        order_id,
        order_status,
        region,
        COALESCE(NULLIF(TRIM(category), ''), 'Unclassified') AS category,
        SUBSTR(order_purchase_timestamp, 1, 7) AS purchase_month,
        CAST(NULLIF(TRIM(delivery_days), '') AS REAL) AS delivery_days
    FROM dashboard_orders
)
SELECT
    'Unique orders by region' AS visual_name,
    region AS segment,
    COUNT(DISTINCT order_id) AS distinct_orders,
    NULL AS eligible_delivery_orders,
    NULL AS average_delivery_days
FROM dashboard
WHERE region IS NOT NULL
GROUP BY region

UNION ALL

SELECT
    'Orders by assigned category (coverage incomplete)',
    category,
    COUNT(DISTINCT order_id),
    NULL,
    NULL
FROM dashboard
GROUP BY category

UNION ALL

SELECT
    'Average elapsed delivery days by region',
    region,
    COUNT(DISTINCT order_id),
    COUNT(DISTINCT CASE
        WHEN order_status = 'delivered'
            AND delivery_days IS NOT NULL AND delivery_days >= 0
        THEN order_id
    END),
    AVG(CASE
        WHEN order_status = 'delivered'
            AND delivery_days IS NOT NULL AND delivery_days >= 0
        THEN delivery_days
    END)
FROM dashboard
WHERE region IS NOT NULL
GROUP BY region

UNION ALL

SELECT
    'Unique order volume by purchase month',
    purchase_month,
    COUNT(DISTINCT order_id),
    NULL,
    NULL
FROM dashboard
WHERE purchase_month IS NOT NULL
GROUP BY purchase_month

UNION ALL

SELECT
    'Average elapsed delivery days by purchase month',
    purchase_month,
    COUNT(DISTINCT order_id),
    COUNT(DISTINCT CASE
        WHEN order_status = 'delivered'
            AND delivery_days IS NOT NULL AND delivery_days >= 0
        THEN order_id
    END),
    AVG(CASE
        WHEN order_status = 'delivered'
            AND delivery_days IS NOT NULL AND delivery_days >= 0
        THEN delivery_days
    END)
FROM dashboard
WHERE purchase_month IS NOT NULL
GROUP BY purchase_month

UNION ALL

SELECT
    'Unique orders by source status',
    order_status,
    COUNT(DISTINCT order_id),
    NULL,
    NULL
FROM dashboard
WHERE order_status IS NOT NULL
GROUP BY order_status

ORDER BY visual_name, segment;
