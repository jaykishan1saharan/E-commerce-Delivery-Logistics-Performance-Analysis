
import csv
import getpass
from pathlib import Path

import mysql.connector

PROJECT_ROOT = Path(__file__).resolve().parents[2]
RAW_DIR = PROJECT_ROOT / "data" / "raw"

FILES = {
    "customers_stage": "olist_customers_dataset.csv",
    "orders_stage": "olist_orders_dataset.csv",
    "items_stage": "olist_order_items_dataset.csv",
    "reviews_stage": "olist_order_reviews_dataset.csv",
    "products_stage": "olist_products_dataset.csv",
    "translation_stage": "product_category_name_translation.csv",
}

# Use text columns initially to preserve source values.
# The cleaning SQL can convert and validate values afterward.
def quote_identifier(name):
    return "`" + name.replace("`", "``") + "`"


def main():
    password = getpass.getpass("MySQL root password: ")

    connection = mysql.connector.connect(
        host="localhost",
        port=3306,
        user="root",
        password=password,
        database="ecommerce_delivery",
        unix_socket="/tmp/mysql.sock",
    )

    try:
        cursor = connection.cursor()

        for table, filename in FILES.items():
            csv_path = RAW_DIR / filename

            if not csv_path.exists():
                raise FileNotFoundError(f"CSV not found: {csv_path}")

            print(f"\nLoading {filename} into {table}...")

            with csv_path.open(
                "r", encoding="utf-8-sig", newline=""
            ) as file:
                reader = csv.reader(file)
                headers = next(reader)

                if not headers:
                    raise ValueError(f"No CSV headers found in {filename}")

                columns = [h.strip() for h in headers]

                # Reject duplicate or empty column names.
                if any(not col for col in columns):
                    raise ValueError(f"Empty column name in {filename}")
                if len(set(columns)) != len(columns):
                    raise ValueError(f"Duplicate column names in {filename}")

                # Refuse to overwrite an existing staging table.
                cursor.execute(
                    """
                    SELECT COUNT(*)
                    FROM information_schema.tables
                    WHERE table_schema = %s AND table_name = %s
                    """,
                    ("ecommerce_delivery", table),
                )
                if cursor.fetchone()[0]:
                    raise RuntimeError(
                        f"Table {table} already exists. "
                        "Import stopped to avoid overwriting it."
                    )

                definitions = ", ".join(
                    f"{quote_identifier(col)} LONGTEXT NULL"
                    for col in columns
                )
                cursor.execute(
                    f"CREATE TABLE {quote_identifier(table)} ({definitions})"
                )

                quoted_columns = ", ".join(
                    quote_identifier(col) for col in columns
                )
                placeholders = ", ".join(["%s"] * len(columns))
                insert_sql = (
                    f"INSERT INTO {quote_identifier(table)} "
                    f"({quoted_columns}) VALUES ({placeholders})"
                )

                count = 0
                batch = []

                for row in reader:
                    if len(row) != len(columns):
                        raise ValueError(
                            f"{filename}: row {count + 2} has "
                            f"{len(row)} fields; expected {len(columns)}"
                        )

                    # Preserve CSV values as text; represent empty fields as NULL.
                    batch.append(tuple(value if value != "" else None for value in row))

                    if len(batch) >= 1000:
                        cursor.executemany(insert_sql, batch)
                        connection.commit()
                        count += len(batch)
                        batch.clear()

                if batch:
                    cursor.executemany(insert_sql, batch)
                    connection.commit()
                    count += len(batch)

                cursor.execute(
                    f"SELECT COUNT(*) FROM {quote_identifier(table)}"
                )
                actual_count = cursor.fetchone()[0]

                print(
                    f"Imported {count:,} rows; "
                    f"table contains {actual_count:,} rows."
                )

                if actual_count != count:
                    raise RuntimeError(f"Row count mismatch for {table}")

        print("\nAll six staging tables imported and row counts verified.")

    finally:
        connection.close()


if __name__ == "__main__":
    main()
