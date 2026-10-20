
"""Reusable data loader for logistics order analysis.

Configure LOGISTICS_DATA_SOURCE as 'csv' or 'mysql' only after
the team confirms the canonical input method.
"""

import os
from pathlib import Path

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[2]

REQUIRED_COLUMNS = [
    "order_id",
    "customer_id",
    "order_status",
]

TIMESTAMP_COLUMNS = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]


def validate_order_analysis_data(df: pd.DataFrame) -> pd.DataFrame:
    """Validate required columns, order IDs, and timestamp values."""
    missing_columns = [
        column for column in REQUIRED_COLUMNS
        if column not in df.columns
    ]

    if missing_columns:
        raise ValueError(
            f"Analytical dataset is missing required columns: "
            f"{missing_columns}"
        )

    if df["order_id"].isna().any():
        raise ValueError("The dataset contains missing order IDs.")

    if df["order_id"].duplicated().any():
        raise ValueError("The dataset contains duplicate order IDs.")

    for column in TIMESTAMP_COLUMNS:
        if column not in df.columns:
            continue

        original = df[column]
        parsed = pd.to_datetime(original, errors="coerce")
        invalid = original.notna() & parsed.isna()

        if invalid.any():
            raise ValueError(
                f"Column '{column}' contains "
                f"{int(invalid.sum())} invalid timestamp values."
            )

        df[column] = parsed

    return df


def load_order_analysis_data() -> pd.DataFrame:
    """Load and validate the team's agreed analytical dataset."""
    source = os.getenv("LOGISTICS_DATA_SOURCE", "").strip().lower()

    if source == "csv":
        csv_setting = os.getenv(
            "LOGISTICS_ANALYSIS_CSV",
            "data/processed/order_analysis.csv",
        )
        csv_path = Path(csv_setting)

        if not csv_path.is_absolute():
            csv_path = PROJECT_ROOT / csv_path

        if not csv_path.is_file():
            raise FileNotFoundError(
                f"Verified analytical CSV not found: {csv_path}. "
                "Ask the team for the approved export path."
            )

        df = pd.read_csv(csv_path)
        return validate_order_analysis_data(df)

    if source == "mysql":
        required = (
            "MYSQL_HOST",
            "MYSQL_USER",
            "MYSQL_PASSWORD",
            "MYSQL_DATABASE",
            "LOGISTICS_ANALYSIS_SQL_FILE",
        )

        missing = [
            name for name in required
            if not os.getenv(name)
        ]

        if missing:
            raise RuntimeError(
                "Missing required environment variables: "
                + ", ".join(missing)
            )

        sql_path = Path(os.environ["LOGISTICS_ANALYSIS_SQL_FILE"])

        if not sql_path.is_absolute():
            sql_path = PROJECT_ROOT / sql_path

        if not sql_path.is_file():
            raise FileNotFoundError(
                f"Analytical SQL file not found: {sql_path}"
            )

        query = sql_path.read_text(encoding="utf-8").strip()

        if not query:
            raise ValueError(
                f"Analytical SQL file is empty: {sql_path}"
            )

        try:
            import mysql.connector
        except ImportError as exc:
            raise RuntimeError(
                "MySQL mode requires mysql-connector-python. "
                "Install it in the project's Python environment."
            ) from exc

        connection = None
        cursor = None

        try:
            connection = mysql.connector.connect(
                host=os.environ["MYSQL_HOST"],
                user=os.environ["MYSQL_USER"],
                password=os.environ["MYSQL_PASSWORD"],
                database=os.environ["MYSQL_DATABASE"],
            )

            cursor = connection.cursor()
            cursor.execute(query)

            if cursor.description is None:
                raise ValueError(
                    "The analytical SQL did not return a result set."
                )

            columns = [
                column[0] for column in cursor.description
            ]
            rows = cursor.fetchall()

            df = pd.DataFrame(rows, columns=columns)
            return validate_order_analysis_data(df)

        except Exception as exc:
            raise RuntimeError(
                "Could not load the analytical dataset from MySQL: "
                f"{exc}"
            ) from exc

        finally:
            if cursor is not None:
                cursor.close()

            if connection is not None:
                connection.close()

    raise RuntimeError(
        "Data source is not configured. After team confirmation, set "
        "LOGISTICS_DATA_SOURCE to 'mysql' or 'csv'."
    )
