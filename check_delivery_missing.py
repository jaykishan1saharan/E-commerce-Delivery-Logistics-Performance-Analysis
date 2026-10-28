
import pandas as pd

df = pd.read_csv("data/interim/kpi_orders.csv")

df["order_delivered_customer_date"] = pd.to_datetime(
    df["order_delivered_customer_date"], errors="coerce"
)

print("Delivered orders by status:")
print(df["order_status"].value_counts(dropna=False))

print("\nMissing delivery timestamps by status:")
print(
    df.groupby("order_status", dropna=False)[
        "order_delivered_customer_date"
    ].agg(total="size", missing="count")
)

print("\nDelivered-order reconciliation:")
delivered = df[df["order_status"].eq("delivered")]

print("Delivered rows:", len(delivered))
print("Delivered rows with timestamp:",
      delivered["order_delivered_customer_date"].notna().sum())
print("Delivered rows missing timestamp:",
      delivered["order_delivered_customer_date"].isna().sum())
