
import csv

path = "data/interim/kpi_orders.csv"
rows_scanned = 0
negative_count = 0
shown = 0

with open(path, encoding="utf-8-sig", newline="") as file:
    reader = csv.DictReader(file)

    for row in reader:
        rows_scanned += 1

        try:
            value = float(row.get("carrier_handoff_days", ""))
        except (ValueError, TypeError):
            continue

        if value < 0:
            negative_count += 1

            if shown < 10:
                print({
                    "order_id": row.get("order_id"),
                    "approved_at": row.get("order_approved_at"),
                    "carrier_date": row.get("order_delivered_carrier_date"),
                    "carrier_handoff_days": value,
                })
                shown += 1

print("\nRows scanned:", rows_scanned)
print("Negative handoff durations:", negative_count)
