# Pull Request and Merge Steps

GitHub screenshot evidence shows:
- Base branch: `main`
- Compare branch: `LavKumar`
- GitHub status: **Able to merge**
- 2 commits and 3 files changed in the screenshot.

This indicates mergeability, not that the PR has already been created or merged.

## Create and merge
1. Create the PR with title: `Week 4: Documentation and Final Project Integration`.
2. Review the **Files changed** tab; confirm only intended files are included.
3. Request the repository owner's review if required.
4. Resolve any comments.
5. Use **Merge pull request** only after approval.
6. Confirm the PR shows **Merged**.

## Verify locally after merge
```bash
git fetch origin
git switch main
git pull origin main
git log -1 --oneline
git status
```

To confirm the Member 5 documentation files are on main:
```bash
git ls-tree -r --name-only origin/main | grep -E '(^docs/|README.md|presentation/)'
```

Record the merge commit SHA and verify that the final files are present. Do not force-push or merge unreviewed changes.
