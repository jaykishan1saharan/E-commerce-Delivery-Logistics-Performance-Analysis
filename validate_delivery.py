














import pandas as pd
from pathlib import Path

source = Path("data/interim/kpi_orders.csv")
output = Path("reports/member2/monthly_delivery_validation.csv")
output.parent.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(source)

purchase = "order_purchase_timestamp"
delivery = "order_delivered_customer_date"
duration = "delivery_days"

required = [purchase, delivery, duration]
missing_columns = [c for c in required if c not in df.columns]

if missing_columns:
    print("Missing columns:", missing_columns)
    print("Available columns:", df.columns.tolist())
    raise SystemExit(1)

# Preserve original values to identify invalid nonblank timestamps.
for col in [purchase, delivery]:
    original = df[col].copy()
    df[col] = pd.to_datetime(original, errors="coerce")
    invalid = original.notna() & original.astype(str).str.strip().ne("")
    invalid &= df[col].isna()
    print(f"Invalid nonblank {col}: {invalid.sum()}")

print("\n--- Timestamp completeness ---")
print("Total records:", len(df))
print("Missing purchase timestamps:", df[purchase].isna().sum())
print("Missing delivery timestamps:", df[delivery].isna().sum())
print("Missing duration values:", df[duration].isna().sum())

df["calculated_days"] = (
    df[delivery] - df[purchase]
).dt.total_seconds() / 86400

valid = df["calculated_days"].notna()
print("\n--- Duration validation ---")
print("Comparable timestamp pairs:", valid.sum())
print("Negative durations:", (df["calculated_days"] < 0).sum())
print("Zero durations:", (df["calculated_days"] == 0).sum())
print("Durations over 90 days:", (df["calculated_days"] > 90).sum())

compare = valid & df[duration].notna()
difference = (
    df.loc[compare, "calculated_days"] -
    df.loc[compare, duration]
).abs()

print("Comparable recorded durations:", compare.sum())
print("Duration mismatches > 0.001 days:", (difference > 0.001).sum())

# Use delivered records for the delivery-time trend.
if "order_status" in df.columns:
    trend_df = df[df["order_status"].eq("delivered")].copy()
else:
    trend_df = df[df[delivery].notna()].copy()

trend_df["purchase_month"] = trend_df[purchase].dt.to_period("M")

monthly = trend_df.groupby("purchase_month", dropna=True).agg(
    total_delivered_orders=("order_status", "size")
    if "order_status" in trend_df.columns
    else ("calculated_days", "size"),
    valid_delivery_timestamps=(delivery, "count"),
    valid_durations=("calculated_days", "count"),
    average_delivery_days=("calculated_days", "mean")
)

monthly["timestamp_completeness_pct"] = (
    monthly["valid_delivery_timestamps"] /
    monthly["total_delivered_orders"] * 100
).round(2)

monthly["duration_completeness_pct"] = (
    monthly["valid_durations"] /
    monthly["total_delivered_orders"] * 100
).round(2)

monthly.to_csv(output)
print("\n--- Monthly delivery trend ---")
print(monthly.to_string())
print("\nReport saved to:", output)
