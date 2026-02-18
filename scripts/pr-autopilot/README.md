# PR Autopilot (MVP)

These scripts are the mechanical layer for "PR autopilot": detect repo stack, run checks, and open PRs.

Design principle: scripts do mechanics, Cortex does judgment.

## Quick start

```bash
# From anywhere
REPO=/home/ubuntu/.openclaw/workspace/Insights-1   # or another repo path

./scripts/pr-autopilot/detect-stack.sh "$REPO"
./scripts/pr-autopilot/run-checks.sh "$REPO"
```

## Overrides

If detection isn't enough for a repo, add `.autopilot.json` at the repo root:

```json
{
  "stack": "custom",
  "install": "pip install -r requirements.txt",
  "lint": "ruff check .",
  "test": "pytest -q",
  "build": null
}
```

## Notes
- This is intentionally minimal.
- If checks fail, the right behavior is: open PR + report failures (don’t hide).
