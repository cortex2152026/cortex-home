#!/usr/bin/env bash
set -euo pipefail

# Usage: watch-ci.sh <repo_path> <pr_number|pr_url> [timeout_seconds]
# Polls GitHub PR status checks until complete or timeout.

REPO="${1:-}"
PR_REF="${2:-}"
TIMEOUT="${3:-900}" # 15 minutes default

if [[ -z "$REPO" || -z "$PR_REF" ]]; then
  echo "usage: $0 <repo_path> <pr_number|pr_url> [timeout_seconds]" >&2
  exit 2
fi

cd "$REPO"

start=$(date +%s)
end=$((start + TIMEOUT))

get_rollup() {
  gh pr view "$PR_REF" --json statusCheckRollup,state,mergeStateStatus,isDraft,url,title --jq '{state,isDraft,mergeStateStatus,url,title,statusCheckRollup}'
}

is_complete() {
  # Returns 0 if all checks are completed (success/failure) or no checks.
  python3 - <<'PY'
import json,sys
obj=json.load(sys.stdin)
roll=obj.get('statusCheckRollup') or []
if not roll:
  print('no_checks')
  raise SystemExit(0)
for c in roll:
  st=(c.get('status') or '').upper()
  if st in ('IN_PROGRESS','QUEUED','PENDING'):
    raise SystemExit(1)
print('complete')
PY
}

last=""
while true; do
  now=$(date +%s)
  if [[ "$now" -gt "$end" ]]; then
    echo "[ci] TIMEOUT after ${TIMEOUT}s" >&2
    get_rollup
    exit 1
  fi

  rollup=$(get_rollup)
  summary=$(echo "$rollup" | python3 - <<'PY'
import json,sys
obj=json.load(sys.stdin)
roll=obj.get('statusCheckRollup') or []
# compact summary line
parts=[]
for c in roll:
  name=c.get('name') or c.get('context') or 'check'
  concl=(c.get('conclusion') or c.get('state') or c.get('status') or 'unknown')
  parts.append(f"{name}:{concl}")
print(' | '.join(parts) if parts else 'no checks')
PY
)

  if [[ "$summary" != "$last" ]]; then
    echo "[ci] $summary" >&2
    last="$summary"
  fi

  echo "$rollup" | is_complete && {
    echo "[ci] COMPLETE" >&2
    echo "$rollup"
    exit 0
  }

  sleep 15
done
