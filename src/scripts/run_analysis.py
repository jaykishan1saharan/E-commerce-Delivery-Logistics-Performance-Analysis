
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
db_path = PROJECT_ROOT / "delivery_analysis.db"

queries = {
    "1. Order Volume by Status": """
        SELECT order_status, COUNT(*) AS total_orders
        FROM orders
        GROUP BY order_status
        ORDER BY total_orders DESC;
    """,
    "2. Delivery Duration (Days)": """
        SELECT
            ROUND(AVG(JULIANDAY(order_delivered_customer_date)
                - JULIANDAY(order_purchase_timestamp)), 2) AS average_days,
            ROUND(MIN(JULIANDAY(order_delivered_customer_date)
                - JULIANDAY(order_purchase_timestamp)), 2) AS minimum_days,
            ROUND(MAX(JULIANDAY(order_delivered_customer_date)
                - JULIANDAY(order_purchase_timestamp)), 2) AS maximum_days
        FROM orders
        WHERE order_status = 'delivered'
          AND order_purchase_timestamp IS NOT NULL
          AND order_delivered_customer_date IS NOT NULL;
    """,
    "3. Late Deliveries": """
        SELECT COUNT(*) AS late_deliveries
        FROM orders
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
          AND order_delivered_customer_date > order_estimated_delivery_date;
    """,
    "4. Cancelled Orders": """
        SELECT COUNT(*) AS cancelled_orders
        FROM orders
        WHERE order_status = 'canceled';
    """,
    "5. Cancellation Percentage": """
        SELECT ROUND(
            100.0 * SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END)
            / COUNT(*), 2
        ) AS cancellation_percentage
        FROM orders;
    """,
    "6. Review Score Distribution": """
        SELECT review_score, COUNT(*) AS total_reviews
        FROM order_reviews
        GROUP BY review_score
        ORDER BY review_score;
    """
}

with sqlite3.connect(db_path) as connection:
    for title, sql in queries.items():
        print("\n" + "=" * 45)
        print(title)
        print("=" * 45)

        cursor = connection.execute(sql)
        print(" | ".join(column[0] for column in cursor.description))
        for row in cursor.fetchall():
            print(" | ".join(str(value) for value in row))

print("\nAnalysis completed successfully!")
