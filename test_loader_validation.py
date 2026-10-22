import os
import tempfile
from pathlib import Path

import pandas as pd

from src.logistics_analysis.data_loading import load_order_analysis_data

source = Path("data/interim/kpi_orders.csv")
df = pd.read_csv(source)

tests = [
    ("Missing required column", df.drop(columns=["customer_id"])),
    ("Missing order ID", df.assign(order_id=df["order_id"].mask(df.index == 0, None))),
]

for name, bad_df in tests:
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(
            suffix=".csv", delete=False, dir="data/interim"
        ) as temp:
            temp_path = Path(temp.name)

        bad_df.to_csv(temp_path, index=False)
        os.environ["LOGISTICS_DATA_SOURCE"] = "csv"
        os.environ["LOGISTICS_ANALYSIS_CSV"] = str(temp_path)

        try:
            load_order_analysis_data()
            print(f"FAIL: {name} was accepted")
        except ValueError as exc:
            print(f"PASS: {name} rejected — {exc}")
    finally:
        if temp_path and temp_path.exists():
            temp_path.unlink()

