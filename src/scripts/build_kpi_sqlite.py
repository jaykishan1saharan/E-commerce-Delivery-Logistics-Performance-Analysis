import sqlite3, pandas as pd

RAW = "data/raw/"
files = {
    "orders": "olist_orders_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "products": "olist_products_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

con = sqlite3.connect("olist.db")
for table, file in files.items():
    df = pd.read_csv(RAW + file, encoding="utf-8-sig")
    df.to_sql(table, con, index=False, if_exists="replace")
    print(table, len(df))

con.executescript(open("sql/06_create_kpi_views.sql").read())

all_orders = pd.read_sql("SELECT * FROM kpi_orders_all", con)
delivered = pd.read_sql("SELECT * FROM kpi_orders", con)
all_orders.to_csv("data/interim/kpi_orders_all.csv", index=False)
delivered.to_csv("data/interim/kpi_orders.csv", index=False)

print("kpi_orders_all:", len(all_orders), "unique:", all_orders.order_id.is_unique)
print("kpi_orders:", len(delivered), "unique:", delivered.order_id.is_unique)
print("on-time rate:", round(delivered.is_on_time.mean(), 4))
print("cancel rate:", round(all_orders.is_canceled.mean(), 4))
print("cancel rate:", round(all_orders.is_canceled.mean(), 4))