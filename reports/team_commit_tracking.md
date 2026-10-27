# Team Commit Tracking — Week 3

**Working branch:** `LavKumar`  
**Target branch:** `main`

This document records the four members’ GitHub commits, the work described by their commit messages, and integration status. It tracks committed work and does not assess code correctness.

## 1. Yashashvi — `origin/YY-M1`

**Commits:** `abc8d0d`, `dbca81b`

**Committed work:**
- Week 3 delivery analysis exports.
- Regional and state analysis CSV exports.
- Deeper analysis SQL for delivery and KPI business insights.
- KPI query work associated with pull request #20.

**Integration status:** The branch was merged into `LavKumar` in commit `9b44538`. The merge added `exports/week3_region_analysis.csv`, `exports/week3_state_analysis.csv`, and `sql/06_deeper_analysis.sql`.

## 2. Meghana — `origin/analysis`

**Commits recorded:**
- `397b202` — Add baseline SQL data quality validation checks
- `eb3f433` — Document verified MySQL validation results
- `437da97` — Fix SQL validation script
- `c6c7e99` — Document Day 2 join and segment validation

**Committed work:**
- SQL data-quality validation checks.
- MySQL validation results and validation documentation.
- SQL validation script.
- Join and segment validation summary.
- Related SQL/Python KPI comparison and loader-validation work recorded in the branch history.

**Integration status:** The branch has not been merged into `LavKumar`. The attempted merge encountered conflicts and was not completed.

## 3. Jaykishan — `origin/jaykishan`

**Commits recorded:**
- `2680bbb` — Finalize KPI rules and acceptance checks
- `8cc8036` — Initialize Week 3 analysis notebook

**Committed work:**
- KPI rules and acceptance criteria.
- Week 3 analysis notebook.

**Integration status:** The earlier Git comparison showed no commits unique to this branch relative to `main`. The listed Monday commits were already present in the compared `LavKumar` history, so avoid duplicating them.

## 4. Madhupriya — `origin/madhupriya/validation`

**Commits recorded:**
- `7b643fa` — Set up Week 3 dashboard structure
- `eae1db6` — Build regional performance dashboard
- `545c971` — Publish data validation summary
- `b4c7db5` — Add automated data validation tests

**Committed work:**
- Week 3 dashboard structure.
- Regional performance dashboard.
- Data-validation summary.
- Automated data-validation tests.
- Additional delivery-timestamp and primary-key/relationship audit work recorded in the branch history.

**Integration status:** The branch has not been merged into `LavKumar`.

## Consolidated integration status

| Member | Committed work identified | Status in `LavKumar` |
|---|---|---|
| Yashashvi | SQL analysis and regional/state exports | Branch merged |
| Meghana | SQL validation and validation reports | Not merged |
| Jaykishan | KPI rules and analysis notebook | Listed commits already present in compared history |
| Madhupriya | Dashboard and data-validation work | Not merged |

## Next steps

1. Keep this as the single team contribution document.
2. Add only the selected documentation or files from member work to `LavKumar`; do not merge entire member branches.
3. Commit and push the documentation on `LavKumar`.
4. Open a pull request from `LavKumar` into `main`.
5. Update this document when additional commits are confirmed.


## 5. Lav Kumar — `LavKumar`

**Role:** Team integration, documentation, and project coordination.

**Commits recorded:**
- `3690f4b` — Update Week 3 documentation and team progress
- `935ef20` — Update Member 5 project documentation
- `def185c` — Add daily project task documentation
- `f3bea32` — Merge origin/main into LavKumar and resolve conflicts
- `9b44538` — Merge Yashashvi's committed work into LavKumar

**Committed work:**
- Updated Week 3 project documentation and team progress.
- Maintained Member 5 documentation and daily task records.
- Integrated the latest `main` branch changes into `LavKumar`.
- Brought Yashashvi's committed Week 3 SQL analysis and regional/state exports into `LavKumar`.
- Prepared consolidated documentation to record all four members' commits and work.

**Current status:**
- Working branch: `LavKumar`
- Target branch: `main`
- Team contribution documentation: `reports/team_commit_tracking.md`
- Meghana's and Madhupriya's branches have not been merged into `LavKumar`.
- The consolidated documentation still needs to be committed and pushed, then submitted through a pull request to `main`.