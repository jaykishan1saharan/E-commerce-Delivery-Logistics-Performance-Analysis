from pathlib import Path

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from scipy.stats import mannwhitneyu, chi2_contingency

ROOT = Path(__file__).resolve().parents[2]

INPUT = ROOT / "data/interim/kpi_orders.csv"
TABLES = ROOT / "reports/tables"
FIGURES = ROOT / "reports/figures"
REPORT = ROOT / "reports/week2_ratings_lateness_analysis.md"

TABLES.mkdir(parents=True, exist_ok=True)
FIGURES.mkdir(parents=True, exist_ok=True)

# --------------------------------------------------
# 1. Load and validate data
# --------------------------------------------------

df = pd.read_csv(INPUT)

required = {
    "order_id", "order_status", "review_score",
    "delay_days", "is_on_time"
}

missing_columns = required - set(df.columns)

if missing_columns:
    raise ValueError(f"Missing required columns: {sorted(missing_columns)}")

if df["order_id"].isna().any():
    raise ValueError("Missing order IDs found.")

if df["order_id"].duplicated().any():
    raise ValueError("Duplicate order IDs found.")

if not df["order_status"].eq("delivered").all():
    raise ValueError("Dataset contains non-delivered orders.")

df["review_score"] = pd.to_numeric(
    df["review_score"], errors="coerce"
)

df["delay_days"] = pd.to_numeric(
    df["delay_days"], errors="coerce"
)

df["is_on_time"] = pd.to_numeric(
    df["is_on_time"], errors="coerce"
)

if not df["is_on_time"].dropna().isin([0, 1]).all():
    raise ValueError("Unexpected values in is_on_time.")

# Use the existing KPI timeliness flag for group assignment.
df = df[df["is_on_time"].isin([0, 1])].copy()
df["is_on_time"] = df["is_on_time"].astype(int)

# Valid review scores are 1 through 5.
df.loc[
    ~df["review_score"].between(1, 5),
    "review_score"
] = np.nan

df["delivery_group"] = df["is_on_time"].map({
    1: "On-time",
    0: "Late"
})

# Identify inconsistencies for documentation.
df["delay_sign_on_time"] = df["delay_days"].le(0)

mismatch_count = int(
    (df["delay_sign_on_time"] != df["is_on_time"].eq(1)).sum()
)

# --------------------------------------------------
# 2. Delay bucket analysis
# --------------------------------------------------

def assign_delay_bucket(row):
    if row["is_on_time"] == 1:
        return "On-time"

    delay = row["delay_days"]

    if pd.isna(delay) or delay <= 0:
        return "Late flag — verify delay value"

    if delay <= 3:
        return "Late: >0–3 days"
    elif delay <= 7:
        return "Late: >3–7 days"
    else:
        return "Late: >7 days"


df["delay_bucket"] = df.apply(assign_delay_bucket, axis=1)

bucket_order = [
    "On-time",
    "Late: >0–3 days",
    "Late: >3–7 days",
    "Late: >7 days",
    "Late flag — verify delay value"
]

bucket_summary = (
    df.groupby("delay_bucket", observed=False)
      .agg(
          order_count=("order_id", "nunique"),
          valid_review_count=("review_score", "count"),
          average_rating=("review_score", "mean"),
          median_rating=("review_score", "median")
      )
      .reindex(bucket_order)
      .fillna({
          "order_count": 0,
          "valid_review_count": 0
      })
      .reset_index()
)

bucket_summary["order_percentage"] = (
    bucket_summary["order_count"] / len(df) * 100
)

bucket_summary.to_csv(
    TABLES / "delay_bucket_analysis.csv", index=False
)

# --------------------------------------------------
# 3. Rating comparison
# --------------------------------------------------

valid = df.dropna(subset=["review_score"]).copy()

rating_summary = (
    valid.groupby("delivery_group")
         .agg(
             order_count=("order_id", "nunique"),
             mean_rating=("review_score", "mean"),
             median_rating=("review_score", "median"),
             standard_deviation=("review_score", "std")
         )
         .reindex(["On-time", "Late"])
         .reset_index()
)

rating_summary.to_csv(
    TABLES / "ratings_by_delivery_status.csv", index=False
)

on_time_ratings = valid.loc[
    valid["is_on_time"] == 1, "review_score"
]

late_ratings = valid.loc[
    valid["is_on_time"] == 0, "review_score"
]

# --------------------------------------------------
# 4. Mann–Whitney U test
# --------------------------------------------------

if len(on_time_ratings) == 0 or len(late_ratings) == 0:
    raise ValueError("Both delivery groups need valid review scores.")

mw = mannwhitneyu(
    on_time_ratings,
    late_ratings,
    alternative="two-sided",
    method="auto"
)

rank_biserial = (
    2 * mw.statistic /
    (len(on_time_ratings) * len(late_ratings))
) - 1

# --------------------------------------------------
# 5. Chi-Square test
# --------------------------------------------------

# Group averaged review scores into predefined rating bands.
rating_data = df.dropna(subset=["review_score"]).copy()

rating_data["rating_band"] = pd.cut(
    rating_data["review_score"],
    bins=[0, 2, 4, 5],
    labels=["Low (1-2)", "Moderate (>2-4)", "High (>4-5)"],
    include_lowest=True,
    right=True
)

contingency = pd.crosstab(
    rating_data["delivery_group"],
    rating_data["rating_band"]
).reindex(
    index=["On-time", "Late"],
    columns=["Low (1-2)", "Moderate (>2-4)", "High (>4-5)"],
    fill_value=0
)

chi2, chi_p, chi_dof, expected = chi2_contingency(contingency)

n = contingency.to_numpy().sum()
minimum_dimension = min(contingency.shape) - 1

minimum_expected_frequency = float(expected.min())

cramers_v = (
    np.sqrt(chi2 / (n * minimum_dimension))
    if n > 0 and minimum_dimension > 0
    else np.nan
)

contingency.to_csv(
    TABLES / "delivery_status_rating_contingency.csv"
)

mw_p_display = "<0.001" if mw.pvalue < 0.001 else f"{mw.pvalue:.6g}"
chi_p_display = "<0.001" if chi_p < 0.001 else f"{chi_p:.6g}"

# --------------------------------------------------
# 6. Export statistical results
# --------------------------------------------------

stat_results = pd.DataFrame([
    {
        "test": "Mann-Whitney U",
        "statistic": mw.statistic,
        "p_value": mw.pvalue,
        "p_value_display": mw_p_display,
        "degrees_of_freedom": np.nan,
        "effect_size": rank_biserial,
        "effect_size_name": "Rank-biserial correlation",
        "sample_size": len(valid)
    },
    {
        "test": "Chi-Square",
        "statistic": chi2,
        "p_value": chi_p,
        "p_value_display": chi_p_display,
        "degrees_of_freedom": chi_dof,
        "effect_size": cramers_v,
        "effect_size_name": "Cramer's V",
        "sample_size": n
    }
])

stat_results.to_csv(
    TABLES / "statistical_test_results.csv", index=False
)

# --------------------------------------------------
# 7. Visualisations
# --------------------------------------------------

plt.figure(figsize=(10, 6))

plt.bar(
    bucket_summary["delay_bucket"],
    bucket_summary["order_count"]
)

plt.title("Order Distribution by Delivery Delay Bucket")
plt.xlabel("Delivery delay bucket")
plt.ylabel("Number of orders")
plt.xticks(rotation=25, ha="right")
plt.tight_layout()

plt.savefig(
    FIGURES / "delay_bucket_distribution.png",
    dpi=150
)
plt.close()

plt.figure(figsize=(8, 6))

valid.boxplot(
    column="review_score",
    by="delivery_group",
    grid=False
)

plt.title("Customer Ratings: On-time vs Late Deliveries")
plt.suptitle("")
plt.xlabel("Delivery group")
plt.ylabel("Customer review score")
plt.tight_layout()

plt.savefig(
    FIGURES / "ratings_by_delivery_status.png",
    dpi=150
)
plt.close()

# --------------------------------------------------
# 8. Generate report
# --------------------------------------------------

alpha = 0.05

mw_interpretation = (
    "Statistically significant difference detected."
    if mw.pvalue < alpha
    else "Insufficient evidence of a statistically significant difference."
)

chi_interpretation = (
    "Statistically significant association detected."
    if chi_p < alpha
    else "Insufficient evidence of a statistically significant association."
)

report = f"""# Week 2 — Ratings vs. Delivery Lateness Analysis

## 1. Objective

Investigate whether customer review scores differ between on-time
and late deliveries and whether delivery timeliness is associated
with customer rating categories.

## 2. Dataset

- Source: `data/interim/kpi_orders.csv`
- Total eligible delivered orders: {len(df):,}
- Unique order IDs: {df['order_id'].nunique():,}
- Valid review scores: {len(valid):,}
- Missing or invalid review scores: {df['review_score'].isna().sum():,}
- On-time orders: {(df['is_on_time'] == 1).sum():,}
- Late orders: {(df['is_on_time'] == 0).sum():,}

## 3. Delay Buckets

Delay buckets use the existing `is_on_time` flag for on-time
classification and positive `delay_days` values for late-order
grouping.

Orders with a late flag but non-positive or missing delay values
are kept in a separate verification bucket.

See `tables/delay_bucket_analysis.csv`.

## 4. Descriptive Rating Comparison

{rating_summary.to_string(index=False)}

## 5. Mann–Whitney U Test

- Null hypothesis: On-time and late deliveries have the same
  review-score distributions.
- Alternative hypothesis: Their review-score distributions differ.
- On-time sample size: {len(on_time_ratings):,}
- Late sample size: {len(late_ratings):,}
- U statistic: {mw.statistic:.4f}
- p-value: {mw_p_display}
- Rank-biserial correlation: {rank_biserial:.6f}
- Significance level: {alpha}

**Interpretation:** {mw_interpretation}

## 6. Chi-Square Test of Independence

- Null hypothesis: Delivery timeliness and review-score category
  are independent.
- Alternative hypothesis: They are associated.
- Chi-square statistic: {chi2:.4f}
- Degrees of freedom: {chi_dof}
- p-value: {chi_p_display}
- Cramer's V: {cramers_v:.6f}

**Interpretation:** {chi_interpretation}
- Minimum expected cell frequency: {minimum_expected_frequency:.2f}

See `tables/delivery_status_rating_contingency.csv`.

## 7. Data Quality Notes

- Delay-sign versus timeliness-flag discrepancies: {mismatch_count}
- The existing `is_on_time` flag was used for group assignment.
- Missing review scores were excluded from statistical tests.
- Original source data was not modified.
- Delay-sign discrepancies should be reconciled with the SQL
  calendar-date timeliness definition.

## 8. Limitations

These tests identify differences or associations, not causation.
Other factors may influence customer ratings. The analysis depends
on the correctness of the existing KPI flags and source dataset.

## 9. Output Files

- `tables/delay_bucket_analysis.csv`
- `tables/ratings_by_delivery_status.csv`
- `tables/delivery_status_rating_contingency.csv`
- `tables/statistical_test_results.csv`
- `figures/delay_bucket_distribution.png`
- `figures/ratings_by_delivery_status.png`
"""

REPORT.write_text(report, encoding="utf-8")

print("\nAnalysis completed.")
print("Input:", INPUT)
print("\nDelay bucket summary:")
print(bucket_summary.to_string(index=False))

print("\nRating summary:")
print(rating_summary.to_string(index=False))

print("\nMann–Whitney U statistic:", mw.statistic)
print("Mann–Whitney p-value:", mw.pvalue)

print("\nChi-Square statistic:", chi2)
print("Chi-Square degrees of freedom:", chi_dof)
print("Chi-Square p-value:", chi_p)
print("Cramer's V:", cramers_v)

print("\nDelay classification discrepancies:", mismatch_count)
print("\nReport saved to:", REPORT)
