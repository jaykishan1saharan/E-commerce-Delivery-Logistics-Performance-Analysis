
from pathlib import Path
import pandas as pd

root = Path(__file__).resolve().parent
raw = root / "data" / "raw"
out = root / "data" / "interim"
out.mkdir(parents=True, exist_ok=True)

orders = pd.read_csv(raw / "olist_orders_dataset.csv")

date_cols = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

for col in date_cols:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

orders["delivery_days"] = (
    orders["order_delivered_customer_date"]
    - orders["order_purchase_timestamp"]
).dt.total_seconds() / 86400

orders["approval_days"] = (
    orders["order_approved_at"]
    - orders["order_purchase_timestamp"]
).dt.total_seconds() / 86400

orders["carrier_handoff_days"] = (
    orders["order_delivered_carrier_date"]
    - orders["order_approved_at"]
).dt.total_seconds() / 86400

eligible = (
    orders["order_status"].eq("delivered")
    & orders["order_delivered_customer_date"].notna()
    & orders["order_estimated_delivery_date"].notna()
)

orders["on_time_eligible"] = eligible
orders["on_time"] = (
    eligible
    & (
        orders["order_delivered_customer_date"].dt.normalize()
        <= orders["order_estimated_delivery_date"].dt.normalize()
    )
)

orders["is_cancelled"] = orders["order_status"].eq("canceled")
orders["small_sample"] = False

columns = [
    "order_id",
    "customer_id",
    "order_status",
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
    "approval_days",
    "carrier_handoff_days",
    "delivery_days",
    "on_time_eligible",
    "on_time",
    "is_cancelled",
    "small_sample",
]

result = orders[columns].copy()
path = out / "kpi_orders.csv"
result.to_csv(path, index=False)

print("Saved:", path)
print("Rows:", len(result))
print("Unique order IDs:", result["order_id"].nunique())
print("Duplicate order IDs:", result["order_id"].duplicated().sum())
print("Status counts:")
print(result["order_status"].value_counts(dropna=False))
print("Delivered orders with valid delivery duration:",
      result.loc[result["order_status"].eq("delivered"), "delivery_days"].notna().sum())
