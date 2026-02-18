# PR Autopilot Plan (Boss)

Goal: a reusable, stack-agnostic PR autopilot that works across repos in this workspace.

Core idea: **shell scripts do the mechanics, Cortex does the judgment**.

## 1) User contract

What Mr Fog says (examples):
- “Add X to repo Y. Done when Z.”
- “Fix failing CI in repo Y.”

What Cortex does:
- Creates a branch
- Implements the change
- Runs repo-appropriate checks automatically
- Pushes branch + opens PR
- Watches CI (v1+) and reports back

What Cortex reports:
- PR link
- Local checks run + pass/fail
- CI status (if available)
- Any follow-ups required

Optional modifiers (future):
- `--branch`, `--draft`, `--no-push`, `--no-ci-watch`

## 2) Repo detection strategy

Cascading detection:
1) `.autopilot.json` overrides
2) `package.json` (Node)
3) `pyproject.toml` (Python)
4) `go.mod` (Go)
5) `Cargo.toml` (Rust)
6) `Makefile`

If nothing matches: warn, don’t block.

## 3) Standard execution pipeline

1) Setup
2) Implement
3) Local Checks
4) Push + PR
5) CI watch (v1)

Branch naming: `cortex/<type>/<slug>`.

## 4) Guardrails + failure modes

Hard rules:
- Never push directly to main
- Never merge own PR
- Never commit secrets

If checks are missing: PR still opens, marked clearly.
If checks fail: PR still opens (draft optional in v1), report failure + next move.

## 5) Implementation plan (3 phases)

### MVP (today)
- `detect-stack.sh`
- `run-checks.sh`
- `open-pr.sh`
- `secret-scan.sh`

### v1 (week 1–2)
- CI watch
- `.autopilot.json` richer overrides
- optional lint autofix

### v2 (week 3–4)
- multi-repo support
- PR follow-up loops
- metrics/logging

## 6) File layout

All under:
- `scripts/pr-autopilot/`

Outputs:
- JSON for agent consumption
- human summaries for PR bodies
