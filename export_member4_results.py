
import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd

BASE = Path(__file__).resolve().parent
REPORTS = BASE / "reports" / "member4"
REPORTS.mkdir(parents=True, exist_ok=True)

with sqlite3.connect(BASE / "delivery_analysis.db") as conn:
    # 1. Order status summary
    status = pd.read_sql_query(
        """
        SELECT order_status, COUNT(*) AS total_orders
        FROM orders
        GROUP BY order_status
        ORDER BY total_orders DESC
        """,
        conn,
    )
    status.to_csv(REPORTS / "order_status_summary.csv", index=False)

    # 2. Delivery duration details
    # Compare calendar dates to match the shared KPI definition.
    delivery = pd.read_sql_query(
        """
        SELECT
            order_id,
            ROUND(
                JULIANDAY(order_delivered_customer_date)
                - JULIANDAY(order_purchase_timestamp),
                2
            ) AS delivery_days,
            CASE
                WHEN order_estimated_delivery_date IS NULL
                    THEN 'Unknown'
                WHEN DATE(order_delivered_customer_date)
                     > DATE(order_estimated_delivery_date)
                    THEN 'Late'
                ELSE 'On time or early'
            END AS delivery_status
        FROM orders
        WHERE order_status = 'delivered'
          AND order_purchase_timestamp IS NOT NULL
          AND order_delivered_customer_date IS NOT NULL
          AND order_estimated_delivery_date IS NOT NULL
        """,
        conn,
    )
    delivery.to_csv(
        REPORTS / "delivery_duration_details.csv",
        index=False,
    )

    # 3. Cancellation summary
    cancellation = pd.read_sql_query(
        """
        SELECT order_status, COUNT(*) AS total_orders
        FROM orders
        WHERE order_status IN ('canceled', 'delivered')
        GROUP BY order_status
        """,
        conn,
    )
    cancellation.to_csv(
        REPORTS / "cancellation_summary.csv",
        index=False,
    )

    # 4. Review score distribution
    reviews = pd.read_sql_query(
        """
        SELECT review_score, COUNT(*) AS total_reviews
        FROM order_reviews
        WHERE review_score IS NOT NULL
        GROUP BY review_score
        ORDER BY review_score
        """,
        conn,
    )
    reviews.to_csv(
        REPORTS / "review_score_distribution.csv",
        index=False,
    )

# Chart 1: Order status
plt.figure(figsize=(9, 5))
plt.bar(status["order_status"], status["total_orders"])
plt.title("Order Volume by Status")
plt.xlabel("Order Status")
plt.ylabel("Number of Orders")
plt.xticks(rotation=35)
plt.tight_layout()
plt.savefig(REPORTS / "order_volume_by_status.png", dpi=150)
plt.close()

# Chart 2: Delivery duration
plt.figure(figsize=(9, 5))
plt.hist(delivery["delivery_days"].dropna(), bins=40)
plt.title("Distribution of Delivery Duration")
plt.xlabel("Delivery Duration (Days)")
plt.ylabel("Number of Orders")
plt.tight_layout()
plt.savefig(REPORTS / "delivery_duration_distribution.png", dpi=150)
plt.close()

# Chart 3: Cancellations
plt.figure(figsize=(7, 5))
plt.bar(cancellation["order_status"], cancellation["total_orders"])
plt.title("Delivered vs Cancelled Orders")
plt.xlabel("Order Status")
plt.ylabel("Number of Orders")
plt.tight_layout()
plt.savefig(REPORTS / "cancellation_comparison.png", dpi=150)
plt.close()

# Chart 4: Review scores
plt.figure(figsize=(7, 5))
plt.bar(reviews["review_score"].astype(str), reviews["total_reviews"])
plt.title("Customer Review Score Distribution")
plt.xlabel("Review Score")
plt.ylabel("Number of Reviews")
plt.tight_layout()
plt.savefig(REPORTS / "review_score_distribution.png", dpi=150)
plt.close()

# Print delivery classification summary
print("Delivery classification:")
print(delivery["delivery_status"].value_counts().to_string())

classified = delivery[
    delivery["delivery_status"].isin(["On time or early", "Late"])
]
if not classified.empty:
    on_time_count = (classified["delivery_status"] == "On time or early").sum()
    late_count = (classified["delivery_status"] == "Late").sum()

    print("Eligible orders:", len(classified))
    print("On-time or early:", on_time_count)
    print("Late:", late_count)
    print(f"On-time rate: {on_time_count / len(classified) * 100:.2f}%")

print("\nMember 4 results exported successfully!")
print("Files saved in:", REPORTS)
print("CSV reports: 4")
print("Charts: 4")