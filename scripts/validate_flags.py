
from pathlib import Path
import sys
import pandas as pd

root = Path(__file__).resolve().parent
source = root / "data" / "interim" / "kpi_orders.csv"
report_dir = root / "reports" / "member2"
report_dir.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(source)

required = [
    "order_status",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
    "on_time_eligible",
    "on_time",
]
missing_columns = [c for c in required if c not in df.columns]

if missing_columns:
    print("FAIL: Missing columns:", missing_columns)
    sys.exit(1)

actual = pd.to_datetime(
    df["order_delivered_customer_date"], errors="coerce"
)
estimated = pd.to_datetime(
    df["order_estimated_delivery_date"], errors="coerce"
)

expected_eligible = (
    df["order_status"].eq("delivered")
    & actual.notna()
    & estimated.notna()
)

expected_on_time = (
    expected_eligible
    & (actual.dt.normalize() <= estimated.dt.normalize())
)

def parse_boolean(series, name):
    if pd.api.types.is_bool_dtype(series):
        return series.fillna(False)

    normalized = series.astype("string").str.strip().str.lower()
    mapping = {
        "true": True,
        "false": False,
        "1": True,
        "0": False,
    }
    parsed = normalized.map(mapping)

    if parsed.isna().any():
        print(f"FAIL: Unrecognized values in {name}:")
        print(normalized[parsed.isna()].value_counts(dropna=False))
        sys.exit(1)

    return parsed.astype(bool)

stored_eligible = parse_boolean(
    df["on_time_eligible"], "on_time_eligible"
)
stored_on_time = parse_boolean(df["on_time"], "on_time")

checks = [
    (
        "on_time_eligible",
        expected_eligible,
        stored_eligible,
    ),
    (
        "on_time",
        expected_on_time,
        stored_on_time,
    ),
]

results = []

for name, expected, stored in checks:
    mismatches = int((expected != stored).sum())
    results.append({
        "check": name,
        "rows_checked": len(df),
        "expected_true": int(expected.sum()),
        "stored_true": int(stored.sum()),
        "mismatches": mismatches,
        "status": "PASS" if mismatches == 0 else "FAIL",
        "rule": (
            "Delivered status and both timestamps present"
            if name == "on_time_eligible"
            else (
                "Eligible and actual calendar date on or before "
                "estimated calendar date"
            )
        ),
    })

report = pd.DataFrame(results)
report_path = report_dir / "flag_validation.csv"
report.to_csv(report_path, index=False)

print(report.to_string(index=False))
print("\nReport saved:", report_path)

if (report["status"] != "PASS").any():
    print("FLAG VALIDATION FAILED. Investigate before committing.")
    sys.exit(1)

print("PASS: Both stored flags match independently recomputed rules.")
