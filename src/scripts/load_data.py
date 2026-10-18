
import sqlite3
import pandas as pd
from pathlib import Path

# Project folder
BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data" / "raw"
DB_PATH = BASE_DIR / "delivery_analysis.db"

# CSV files to import
files = {
    "orders": "olist_orders_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv"
}

# Create SQLite database and import the CSV files
with sqlite3.connect(DB_PATH) as connection:
    for table_name, file_name in files.items():
        csv_path = DATA_DIR / file_name

        if not csv_path.exists():
            print(f"File not found: {csv_path}")
            continue

        df = pd.read_csv(csv_path)
        df.to_sql(table_name, connection, if_exists="replace", index=False)

        print(f"Imported {len(df)} rows into table: {table_name}")

print(f"\nDatabase created at: {DB_PATH}")
