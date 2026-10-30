
import os
import tempfile
from pathlib import Path

import pandas as pd
import pytest

from src.logistics_analysis.data_loading import load_order_analysis_data

SOURCE = Path("data/interim/kpi_orders.csv")


@pytest.fixture
def source_df():
    return pd.read_csv(SOURCE)


def run_loader_with_dataframe(df):
    temp_path = None
    old_source = os.environ.get("LOGISTICS_DATA_SOURCE")
    old_csv = os.environ.get("LOGISTICS_ANALYSIS_CSV")

    try:
        with tempfile.NamedTemporaryFile(
            suffix=".csv", delete=False, dir=SOURCE.parent
        ) as temp:
            temp_path = Path(temp.name)

        df.to_csv(temp_path, index=False)
        os.environ["LOGISTICS_DATA_SOURCE"] = "csv"
        os.environ["LOGISTICS_ANALYSIS_CSV"] = str(temp_path.resolve())

        return load_order_analysis_data()
    finally:
        if temp_path and temp_path.exists():
            temp_path.unlink()

        if old_source is None:
            os.environ.pop("LOGISTICS_DATA_SOURCE", None)
        else:
            os.environ["LOGISTICS_DATA_SOURCE"] = old_source

        if old_csv is None:
            os.environ.pop("LOGISTICS_ANALYSIS_CSV", None)
        else:
            os.environ["LOGISTICS_ANALYSIS_CSV"] = old_csv


def test_missing_required_column_is_rejected(source_df):
    bad_df = source_df.drop(columns=["customer_id"])

    with pytest.raises(ValueError, match="missing required columns"):
        run_loader_with_dataframe(bad_df)


def test_missing_order_id_is_rejected(source_df):
    bad_df = source_df.copy()
    bad_df.loc[0, "order_id"] = None

    with pytest.raises(ValueError, match="missing order IDs"):
        run_loader_with_dataframe(bad_df)


def test_duplicate_order_id_is_rejected(source_df):
    bad_df = source_df.copy()
    bad_df.loc[1, "order_id"] = bad_df.loc[0, "order_id"]

    with pytest.raises(ValueError, match="duplicate order IDs"):
        run_loader_with_dataframe(bad_df)


def test_invalid_timestamp_is_rejected(source_df):
    bad_df = source_df.copy()
    bad_df.loc[0, "order_purchase_timestamp"] = "not-a-date"

    with pytest.raises(ValueError, match="invalid timestamp"):
        run_loader_with_dataframe(bad_df)
