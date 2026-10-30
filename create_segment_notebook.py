
from pathlib import Path
import nbformat as nbf

root = Path(__file__).resolve().parent
notebook_dir = root / "notebooks"
notebook_dir.mkdir(exist_ok=True)

nb = nbf.v4.new_notebook()
nb["metadata"] = {
    "kernelspec": {
        "display_name": "Python 3",
        "language": "python",
        "name": "python3",
    }
}

cells = [
    nbf.v4.new_markdown_cell("""# Week 2 — Segment Comparison

Compare delivery KPIs across order status, purchase weekday, and product category.
This notebook uses the validated order-level KPI dataset and raw Olist files.
Results are descriptive, not causal."""),
    nbf.v4.new_code_cell("""from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

ROOT = Path.cwd()
if not (ROOT / "data" / "interim" / "kpi_orders.csv").exists():
    ROOT = ROOT.parent

kpi_path = ROOT / "data" / "interim" / "kpi_orders.csv"
orders = pd.read_csv(kpi_path, parse_dates=[
    "order_purchase_timestamp",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
])

print("Rows:", len(orders))
print("Unique orders:", orders["order_id"].nunique())
orders.head()"""),
    nbf.v4.new_markdown_cell("## 1. Order status distribution"),
    nbf.v4.new_code_cell("""status_summary = (
    orders.groupby("order_status", dropna=False)
    .agg(order_count=("order_id", "nunique"))
    .reset_index()
    .sort_values("order_count", ascending=False)
)
status_summary["share_pct"] = (
    status_summary["order_count"] / orders["order_id"].nunique() * 100
).round(2)
display(status_summary)

status_summary.plot(
    x="order_status", y="order_count", kind="bar",
    legend=False, title="Order Volume by Status", figsize=(9, 4)
)
plt.ylabel("Distinct orders")
plt.tight_layout()
plt.show()"""),
    nbf.v4.new_markdown_cell("## 2. Delivery performance by purchase weekday"),
    nbf.v4.new_code_cell("""orders["purchase_weekday"] = (
    orders["order_purchase_timestamp"].dt.day_name()
)
orders["delivery_days"] = (
    orders["order_delivered_customer_date"]
    - orders["order_purchase_timestamp"]
).dt.total_seconds() / 86400

orders["on_time_eligible"] = (
    orders["order_status"].eq("delivered")
    & orders["order_delivered_customer_date"].notna()
    & orders["order_estimated_delivery_date"].notna()
)
orders["on_time"] = (
    orders["on_time_eligible"]
    & (orders["order_delivered_customer_date"].dt.normalize()
       <= orders["order_estimated_delivery_date"].dt.normalize())
)

delivered = orders[orders["order_status"].eq("delivered")].copy()
weekday_summary = (
    delivered.groupby("purchase_weekday", dropna=False)
    .agg(
        delivered_orders=("order_id", "nunique"),
        avg_delivery_days=("delivery_days", "mean"),
        median_delivery_days=("delivery_days", "median"),
    )
    .reset_index()
)
eligible = orders[orders["on_time_eligible"]].groupby(
    "purchase_weekday"
)["on_time"].mean().mul(100).rename("on_time_rate_pct")
weekday_summary = weekday_summary.merge(
    eligible, on="purchase_weekday", how="left"
)
weekday_summary[["avg_delivery_days", "median_delivery_days",
                 "on_time_rate_pct"]] = weekday_summary[
    ["avg_delivery_days", "median_delivery_days", "on_time_rate_pct"]
].round(2)

weekday_order = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday"
]
weekday_summary["purchase_weekday"] = pd.Categorical(
    weekday_summary["purchase_weekday"],
    categories=weekday_order, ordered=True
)
weekday_summary = weekday_summary.sort_values("purchase_weekday")
display(weekday_summary)

weekday_summary.plot(
    x="purchase_weekday", y="avg_delivery_days", kind="bar",
    legend=False, title="Average Delivery Duration by Purchase Weekday",
    figsize=(9, 4)
)
plt.ylabel("Days")
plt.tight_layout()
plt.show()"""),
    nbf.v4.new_markdown_cell("## 3. Product category comparison"),
    nbf.v4.new_code_cell("""category_path = ROOT / "reports" / "tables" / "kpi_by_category.csv"
category = pd.read_csv(category_path)
display(category.head(15))

category.sort_values("avg_delivery_days").plot(
    x="category", y="avg_delivery_days", kind="bar",
    legend=False, title="Average Delivery Duration — Top 15 Categories",
    figsize=(12, 5)
)
plt.ylabel("Days")
plt.xticks(rotation=75, ha="right")
plt.tight_layout()
plt.show()"""),
    nbf.v4.new_markdown_cell("""## 4. Interpretation and limitations

- Order status counts describe order outcomes; they do not explain why an order was canceled.
- Weekday comparisons are descriptive and may be affected by product mix, geography, seasonality, and carrier operations.
- Delivery duration includes only delivered orders with valid timestamps.
- On-time rate uses delivered orders with both actual and estimated delivery dates.
- Category order counts can overlap when an order contains products from multiple categories.
- Validate KPI definitions and figures against the team's SQL results before final submission."""),
]

nb["cells"] = cells
output = notebook_dir / "02_segment_comparison.ipynb"
nbf.write(nb, output)

print("Notebook created:", output)
print("Cells:", len(cells))

