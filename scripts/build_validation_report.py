
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "interim" / "kpi_orders.csv"
OUT = ROOT / "reports" / "validation_report.md"

EXPECTED = {
    "total_orders": 99441,
    "delivered": 96478,
    "cancelled": 625,
    "eligible_delivered": 96470,
    "late": 6534,
    "on_time": 89936,
}

if not DATA.exists():
    raise FileNotFoundError(
        f"Missing {DATA}. Check the location of kpi_orders.csv."
    )

df = pd.read_csv(DATA)
df.columns = [c.strip() for c in df.columns]

def find_col(*names):
    lookup = {c.lower(): c for c in df.columns}
    for name in names:
        if name.lower() in lookup:
            return lookup[name.lower()]
    return None

def truth(series):
    return (
        series.astype(str).str.strip().str.lower()
        .isin(["1", "true", "yes", "y"])
    )

def metrics(data):
    status_col = find_col("order_status")
    if status_col:
        status = data[status_col].astype(str).str.strip().str.lower()
        delivered = status.eq("delivered")
        cancelled = status.isin(["canceled", "cancelled"])
    else:
        delivered = pd.Series(False, index=data.index)
        cancelled = pd.Series(False, index=data.index)

    eligible_col = find_col("on_time_eligible")
    ontime_col = find_col("on_time")

    eligible = (
        truth(data[eligible_col]) & delivered
        if eligible_col else delivered.copy()
    )
    ontime = (
        truth(data[ontime_col]) & eligible
        if ontime_col else pd.Series(False, index=data.index)
    )

    late_col = find_col("late", "is_late")
    if late_col:
        late = truth(data[late_col]) & eligible
    elif ontime_col:
        late = eligible & ~truth(data[ontime_col])
    else:
        actual = find_col("order_delivered_customer_date",
                          "delivered_customer_date",
                          "actual_delivery_date")
        estimate = find_col("order_estimated_delivery_date",
                            "estimated_delivery_date")
        if actual and estimate:
            a = pd.to_datetime(data[actual], errors="coerce")
            e = pd.to_datetime(data[estimate], errors="coerce")
            late = eligible & a.notna() & e.notna() & (a.dt.normalize() > e.dt.normalize())
        else:
            late = pd.Series(False, index=data.index)

    return {
        "total_orders": len(data),
        "delivered": int(delivered.sum()),
        "cancelled": int(cancelled.sum()),
        "eligible_delivered": int(eligible.sum()),
        "on_time": int(ontime.sum()),
        "late": int(late.sum()),
        "on_time_rate_pct": round(100 * ontime.sum() / eligible.sum(), 2)
            if eligible.sum() else 0,
        "late_rate_pct": round(100 * late.sum() / eligible.sum(), 2)
            if eligible.sum() else 0,
    }

# Flag missing identifiers/status, duplicate order IDs, malformed
# nonblank timestamps, and negative numeric duration fields.
flags = pd.DataFrame(index=df.index)
for col in ["order_id", "customer_id", "order_status"]:
    actual_col = find_col(col)
    if actual_col:
        flags[f"missing_{col}"] = (
            df[actual_col].isna()
            | df[actual_col].astype(str).str.strip().eq("")
        )

order_id_col = find_col("order_id")
if order_id_col:
    flags["duplicate_order_id"] = df[order_id_col].duplicated(keep=False)

timestamp_cols = [
    c for c in df.columns
    if "date" in c.lower() or "timestamp" in c.lower()
]
for col in timestamp_cols:
    raw = df[col]
    nonblank = raw.notna() & raw.astype(str).str.strip().ne("")
    parsed = pd.to_datetime(raw, errors="coerce")
    flags[f"invalid_{col}"] = nonblank & parsed.isna()

duration_cols = [
    c for c in df.columns
    if any(word in c.lower() for word in ["days", "duration"])
]
for col in duration_cols:
    values = pd.to_numeric(df[col], errors="coerce")
    flags[f"negative_{col}"] = values.notna() & (values < 0)

if flags.empty:
    flagged = pd.Series(False, index=df.index)
else:
    flagged = flags.fillna(False).astype(bool).any(axis=1)

clean = df.loc[~flagged].copy()
all_metrics = metrics(df)
clean_metrics = metrics(clean)

lines = [
    "# Validation and Sensitivity Report",
    "",
    "## 1. Scope and method",
    "",
    f"- Source: `{DATA.relative_to(ROOT).as_posix()}`",
    "- Baseline includes every source row.",
    "- Sensitivity population excludes rows flagged for missing key fields,",
    "  duplicate order IDs, malformed nonblank timestamps, or negative",
    "  numeric duration values.",
    "- A missing timestamp alone is not automatically treated as invalid;",
    "  it may be legitimate for a cancelled or incomplete order.",
    "- Duplicate IDs are flagged on every occurrence, not just later rows.",
    "",
    "## 2. Record-quality checks",
    "",
    f"- Source rows: **{len(df):,}**",
    f"- Rows with at least one quality flag: **{int(flagged.sum()):,}**",
    f"- Rows retained after exclusion: **{len(clean):,}**",
    "",
    "| Quality check | Flagged records |",
    "|---|---:|",
]
for col in flags.columns:
    lines.append(f"| `{col}` | {int(flags[col].fillna(False).sum()):,} |")

lines += [
    "",
    "Counts by check can overlap; do not sum them to obtain unique flagged rows.",
    "",
    "## 3. KPI sensitivity comparison",
    "",
    "| Metric | All source rows | Excluding flagged rows | Change |",
    "|---|---:|---:|---:|",
]
for key in [
    "total_orders", "delivered", "cancelled", "eligible_delivered",
    "on_time", "late", "on_time_rate_pct", "late_rate_pct"
]:
    before = all_metrics[key]
    after = clean_metrics[key]
    suffix = "%" if key.endswith("_pct") else ""
    lines.append(
        f"| {key} | {before:,}{suffix} | {after:,}{suffix} "
        f"| {after - before:+,}{suffix} |"
    )

lines += [
    "",
    "## 4. Reconciliation against established baseline",
    "",
    "| Metric | Expected baseline | Recomputed | Result |",
    "|---|---:|---:|---|",
]
for key, expected in EXPECTED.items():
    actual = all_metrics[key]
    result = "PASS" if actual == expected else "CHECK"
    lines.append(f"| {key} | {expected:,} | {actual:,} | {result} |")

lines += [
    "",
    "The expected values are the previously recorded project validation totals.",
    "A CHECK means the source file or KPI definitions need investigation; it",
    "must not be silently adjusted to force a match.",
    "",
    "## 5. Interpretation and limitations",
    "",
    "- Compare the all-row KPIs with the filtered KPIs before deciding whether",
    "  flagged records materially affect the conclusions.",
    "- Quality flags can overlap, so the unique excluded-row count is reported",
    "  separately from individual check counts.",
    "- If `on_time_eligible` or `on_time` is absent, the report uses available",
    "  delivery dates when possible; unavailable metrics may not reconcile.",
    "- SQL parity must be confirmed against the latest SQL validation output.",
    "  Python-only flags are not evidence that the same flags exist in SQL.",
    "- Review every CHECK and investigate differences before sign-off.",
    "",
    "## 6. Conclusion",
    "",
    f"- **{int(flagged.sum()):,}** records are flagged for sensitivity analysis.",
    f"- **{len(clean):,}** records remain in the filtered population.",
    "- Use the sensitivity table to document whether KPI conclusions change.",
    "- Complete final SQL comparison and reviewer sign-off after investigating",
    "  any baseline mismatch.",
    "",
]

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text("\n".join(lines), encoding="utf-8")
print(f"Report written: {OUT}")
print(f"Source rows: {len(df):,}")
print(f"Flagged rows: {int(flagged.sum()):,}")
print(f"Filtered rows: {len(clean):,}")
print("Baseline checks:")
for key, expected in EXPECTED.items():
    actual = all_metrics[key]
    print(f"  {key}: expected={expected:,}, actual={actual:,}, "
          f"{'PASS' if actual == expected else 'CHECK'}")
