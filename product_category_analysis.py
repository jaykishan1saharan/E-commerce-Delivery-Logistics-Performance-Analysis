
from pathlib import Path

import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "data" / "raw"
TABLES = ROOT / "reports" / "tables"
FIGURES = ROOT / "reports" / "figures"

TABLES.mkdir(parents=True, exist_ok=True)
FIGURES.mkdir(parents=True, exist_ok=True)

# Load source files without modifying the raw data.
orders = pd.read_csv(RAW / "olist_orders_dataset.csv")
items = pd.read_csv(RAW / "olist_order_items_dataset.csv")
products = pd.read_csv(RAW / "olist_products_dataset.csv")
translation = pd.read_csv(RAW / "product_category_name_translation.csv")

# Parse timestamps consistently.
date_cols = [
    "order_purchase_timestamp",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]
for col in date_cols:
    orders[col] = pd.to_datetime(orders[col], errors="coerce")

# Keep one row per order/category pair to avoid counting multiple
# items in the same category as multiple orders.
category_items = items[["order_id", "product_id"]].merge(
    products[["product_id", "product_category_name"]],
    on="product_id",
    how="left",
    validate="many_to_one",
)

category_items = category_items.merge(
    translation,
    on="product_category_name",
    how="left",
    validate="many_to_one",
)

category_items["category"] = (
    category_items["product_category_name_english"]
    .fillna(category_items["product_category_name"])
    .fillna("Unknown")
)

order_categories = category_items[["order_id", "category"]].drop_duplicates()

# Attach order-level delivery and cancellation information.
joined = order_categories.merge(
    orders[
        [
            "order_id",
            "order_status",
            "order_purchase_timestamp",
            "order_delivered_customer_date",
            "order_estimated_delivery_date",
        ]
    ],
    on="order_id",
    how="left",
    validate="many_to_one",
)

joined["delivery_days"] = (
    joined["order_delivered_customer_date"]
    - joined["order_purchase_timestamp"]
).dt.total_seconds() / 86400

valid_delivery = (
    joined["order_status"].eq("delivered")
    & joined["order_delivered_customer_date"].notna()
    & joined["order_purchase_timestamp"].notna()
)
joined["valid_delivery"] = valid_delivery
joined["valid_on_time_check"] = (
    valid_delivery
    & joined["order_estimated_delivery_date"].notna()
)

# Compare calendar dates, as required by the project KPI definition.
joined["on_time"] = (
    joined["order_delivered_customer_date"].dt.normalize()
    <= joined["order_estimated_delivery_date"].dt.normalize()
)

def summarize_category(group):
    delivered = group[group["valid_delivery"]]
    eligible = group[group["valid_on_time_check"]]

    return pd.Series({
        "order_count": group["order_id"].nunique(),
        "small_sample": group["order_id"].nunique() < 30,
        "cancelled_orders": group.loc[
            group["order_status"].eq("canceled"), "order_id"
        ].nunique(),
        "cancellation_rate_pct": (
            100 * group.loc[group["order_status"].eq("canceled"), "order_id"].nunique()
            / group["order_id"].nunique()
            if group["order_id"].nunique() else 0
        ),
        "delivered_order_count": delivered["order_id"].nunique(),
        "avg_delivery_days": delivered["delivery_days"].mean(),
        "on_time_eligible_orders": eligible["order_id"].nunique(),
        "on_time_rate_pct": (
            100 * eligible.loc[eligible["on_time"], "order_id"].nunique()
            / eligible["order_id"].nunique()
            if eligible["order_id"].nunique() else float("nan")
        ),
    })

summary = (
    joined.groupby("category", dropna=False)
    .apply(summarize_category, include_groups=False)
    .reset_index()
    .sort_values(["order_count", "category"], ascending=[False, True])
)

top15 = summary.head(15).copy()
top15["avg_delivery_days"] = top15["avg_delivery_days"].round(2)
top15["cancellation_rate_pct"] = top15["cancellation_rate_pct"].round(2)
top15["on_time_rate_pct"] = top15["on_time_rate_pct"].round(2)

output_csv = TABLES / "kpi_by_category.csv"
top15.to_csv(output_csv, index=False)

# Plot the 15 highest-volume categories.
plot_data = top15.sort_values("order_count", ascending=True)
plt.figure(figsize=(11, 7))
plt.barh(plot_data["category"], plot_data["order_count"])
plt.title("Top 15 Product Categories by Distinct Order Count")
plt.xlabel("Distinct Orders")
plt.ylabel("Product Category")
plt.tight_layout()
plt.savefig(FIGURES / "category_top15_order_count.png", dpi=150)
plt.close()

# Document limitations and counting rules.
limitations = """# Product Category Analysis — Limitations

- Categories are joined through order items, products, and the category translation file.
- An order is counted once within each category, even if it contains multiple items from that category.
- An order containing products from different categories appears in each relevant category. Therefore, category order counts must not be summed to estimate unique overall orders.
- Delivery duration uses delivered orders with valid purchase and delivery timestamps.
- On-time rate uses delivered orders with both actual and estimated delivery timestamps and compares calendar dates.
- Cancellation rate uses all orders assigned to the category as its denominator.
- Categories with fewer than 30 distinct orders are flagged as small samples.
- Missing or untranslated category names are retained as Unknown or the original category name.
- Carrier comparisons and distance-band analysis are not supported by the available files.
- These descriptive comparisons show associations, not causation.
"""
(ROOT / "reports" / "limitations.md").write_text(
    limitations, encoding="utf-8"
)

print("Product category analysis completed.")
print("Order-category pairs:", len(order_categories))
print("Categories analyzed:", len(summary))
print("Top 15 table:", output_csv)
print("Chart:", FIGURES / "category_top15_order_count.png")
print("Limitations:", ROOT / "reports" / "limitations.md")
print("\nTop categories:")
print(top15[["category", "order_count", "small_sample",
             "cancellation_rate_pct", "avg_delivery_days",
             "on_time_rate_pct"]].to_string(index=False))

