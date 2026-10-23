
from pathlib import Path
import pandas as pd

root = Path(__file__).resolve().parent
source = root / "data" / "interim" / "kpi_orders.csv"
out = root / "reports" / "member2"
out.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(source)

date_cols = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

timestamp_rows = []
parsed = {}

for col in date_cols:
    values = pd.to_datetime(df[col], errors="coerce")
    parsed[col] = values
    timestamp_rows.append({
        "column": col,
        "valid_timestamps": int(values.notna().sum()),
        "missing_values": int(df[col].isna().sum()),
        "invalid_nonblank": int(
            (df[col].notna() & values.isna()).sum()
        ),
    })

pd.DataFrame(timestamp_rows).to_csv(
    out / "timestamp_validation.csv", index=False
)

unique_orders = (
    df["order_id"].nunique()
    if "order_id" in df else 0
)
duplicate_orders = (
    int(df["order_id"].duplicated().sum())
    if "order_id" in df else None
)
missing_order_ids = (
    int(df["order_id"].isna().sum())
    if "order_id" in df else None
)

delivered_at = parsed["order_delivered_customer_date"]
estimated_at = parsed["order_estimated_delivery_date"]

# Shared KPI convention: compare calendar dates for delivered orders.
eligible = (
    df["order_status"].eq("delivered")
    & delivered_at.notna()
    & estimated_at.notna()
)
late_by_dates = eligible & (
    delivered_at.dt.date > estimated_at.dt.date
)
on_time_by_dates = eligible & ~late_by_dates

flag_eligible = (
    df["on_time_eligible"].astype(bool)
    if "on_time_eligible" in df else pd.Series(False, index=df.index)
)
flag_on_time = (
    df["on_time"].astype(bool)
    if "on_time" in df else pd.Series(False, index=df.index)
)
late_by_flags = flag_eligible & ~flag_on_time

cancelled = df["order_status"].eq("canceled")

metrics = [
    ("total_orders", len(df), "All dataset rows"),
    ("unique_order_ids", unique_orders, "Distinct order IDs"),
    ("duplicate_order_ids", duplicate_orders, "Expected zero"),
    ("missing_order_ids", missing_order_ids, "Expected zero"),
    ("delivered_orders", int(df["order_status"].eq("delivered").sum()),
     "Status equals delivered"),
    ("cancelled_orders", int(cancelled.sum()), "Status equals canceled"),
    ("late_deliveries_calendar_dates", int(late_by_dates.sum()),
     "Delivered; actual calendar date after estimate"),
    ("on_time_deliveries_calendar_dates", int(on_time_by_dates.sum()),
     "Eligible delivered orders not late"),
    ("eligible_delivered_orders", int(eligible.sum()),
     "Delivered with valid actual and estimated dates"),
    ("late_deliveries_existing_flags", int(late_by_flags.sum()),
     "Existing on_time_eligible and on_time flags"),
]

pd.DataFrame(
    metrics, columns=["metric", "python_value", "definition"]
).to_csv(out / "python_kpi_results.csv", index=False)

# SQL values are intentionally blank until the actual SQL output is supplied.
comparison = pd.DataFrame([
    {
        "metric": name,
        "python_value": value,
        "sql_value": None,
        "difference": None,
        "status": "PENDING SQL RESULT",
        "definition": definition,
    }
    for name, value, definition in metrics
])
comparison.to_csv(out / "sql_python_kpi_comparison.csv", index=False)

missing = df.isna().sum()
missing = missing[missing > 0]

lines = [
    "# Friday Validation Summary",
    "",
    "## Dataset integrity",
    f"- Source: `{source.relative_to(root)}`",
    f"- Rows: {len(df)}",
    f"- Unique order IDs: {unique_orders}",
    f"- Duplicate order IDs: {duplicate_orders}",
    f"- Missing order IDs: {missing_order_ids}",
    "- One row per order: " +
      ("PASS" if len(df) == unique_orders else "FAIL"),
    "",
    "## Delivery KPI checks",
    f"- Delivered orders: {int(df['order_status'].eq('delivered').sum())}",
    f"- Cancelled orders: {int(cancelled.sum())}",
    f"- Late by calendar-date rule: {int(late_by_dates.sum())}",
    f"- Late by existing flags: {int(late_by_flags.sum())}",
    f"- Eligible delivered orders: {int(eligible.sum())}",
    "",
    "## Missing values",
]
for col, count in missing.items():
    lines.append(f"- `{col}`: {int(count)}")

lines += [
    "",
    "## Outstanding items",
    "- Review the timestamp_validation.csv output.",
    "- Reconcile date-based late counts with existing flags.",
    "- Populate SQL values only from verified SQL query results.",
    "- Compare SQL and Python using identical definitions and filters.",
    "",
    "## Reproduction",
    "- Run `python run_analysis.py`",
    "- Run `python validate_friday.py`",
    "",
]

(out / "validation_summary.md").write_text(
    "\n".join(lines), encoding="utf-8"
)

print("Validation reports created:", out)
print("Rows:", len(df))
print("Unique order IDs:", unique_orders)
print("Late by calendar dates:", int(late_by_dates.sum()))
print("Late by existing flags:", int(late_by_flags.sum()))
print("SQL comparison: pending verified SQL results")
