
import pandas as pd
from pathlib import Path

path = Path("data/interim/kpi_orders.csv")
out = Path("reports/member2/monthly_trend_impact.csv")
out.parent.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(path)
df["order_purchase_timestamp"] = pd.to_datetime(
    df["order_purchase_timestamp"], errors="coerce"
)
df["order_delivered_customer_date"] = pd.to_datetime(
    df["order_delivered_customer_date"], errors="coerce"
)

df["delivery_days_calc"] = (
    df["order_delivered_customer_date"]
    - df["order_purchase_timestamp"]
).dt.total_seconds() / 86400

d = df[df["order_status"].eq("delivered")].copy()
d["purchase_month"] = d["order_purchase_timestamp"].dt.to_period("M")

d["valid_duration"] = d["delivery_days_calc"].notna()
d["over_90_days"] = d["delivery_days_calc"] > 90

monthly = d.groupby("purchase_month").agg(
    delivered_orders=("order_id", "size"),
    valid_durations=("delivery_days_calc", "count"),
    outliers_over_90=("over_90_days", "sum"),
    mean_with_outliers=("delivery_days_calc", "mean"),
    median_with_outliers=("delivery_days_calc", "median")
)

filtered = d.loc[~d["over_90_days"]].groupby("purchase_month")[
    "delivery_days_calc"
].mean()

monthly["mean_without_over_90"] = filtered
monthly["mean_change_days"] = (
    monthly["mean_with_outliers"] - monthly["mean_without_over_90"]
).round(2)

monthly["timestamp_completeness_pct"] = (
    monthly["valid_durations"] / monthly["delivered_orders"] * 100
).round(2)

monthly.to_csv(out)

print(monthly.round(2).to_string())
print("\nSaved:", out)
print("Total >90-day deliveries:", int(d["over_90_days"].sum()))
print("Monthly report generated successfully.")
