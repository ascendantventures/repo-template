# Project Name

> Built on the Ascendant Ventures governed SDLC stack.

## Getting Started

This repo uses the Foundary governed pipeline. All code changes must go through a pipeline run.

```bash
# Feature work
foundary run --task '{"description": "...", "taskId": "issue-N", "allowedFiles": ["src/**"]}'

# Small fixes (1-5 files)
foundary hotfix --message "fix: description"

# Emergency only (audited)
FOUNDARY_ADMIN=1 git commit -m "..."
```

## Setup

```bash
bash SETUP.sh
```

## Stack

- **Governance:** Foundary (ascendantventures/foundary)
- **Skills:** Superpowers + Impeccable + Context7 + ui-ux-pro-max
- **CI:** GitHub Actions (Foundary Governance Check — required on all PRs)
