#!/usr/bin/env bash
set -euo pipefail

# Usage: run-checks.sh <repo_path>
# Runs best-effort checks in a safe-ish order:
#   install -> lint -> test -> build
# Steps are skipped if not detected.

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "usage: $0 <repo_path>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECT="$SCRIPT_DIR/detect-stack.sh"
SCAN="$SCRIPT_DIR/secret-scan.sh"

cd "$REPO"

run_step() {
  local name="$1"
  local cmd="$2"

  if [[ -z "$cmd" || "$cmd" == "null" ]]; then
    echo "[checks] skip ${name} (no command)" >&2
    return 0
  fi

  echo "[checks] run ${name}: $cmd" >&2
  # shellcheck disable=SC2086
  bash -lc "$cmd"
}

cfg_json="$($DETECT "$REPO")"
stack=$(python3 - <<'PY' "$cfg_json"
import json,sys
cfg=json.loads(sys.argv[1])
print(cfg.get('stack') or 'unknown')
PY
)

install=$(python3 - <<'PY' "$cfg_json"
import json,sys
cfg=json.loads(sys.argv[1])
print(cfg.get('install') or '')
PY
)

lint=$(python3 - <<'PY' "$cfg_json"
import json,sys
cfg=json.loads(sys.argv[1])
print(cfg.get('lint') or '')
PY
)

test_cmd=$(python3 - <<'PY' "$cfg_json"
import json,sys
cfg=json.loads(sys.argv[1])
print(cfg.get('test') or '')
PY
)

build=$(python3 - <<'PY' "$cfg_json"
import json,sys
cfg=json.loads(sys.argv[1])
print(cfg.get('build') or '')
PY
)

echo "[checks] stack=${stack}" >&2

# Secret scan first (fast fail)
"$SCAN" "$REPO"

run_step install "$install"
run_step lint "$lint"
run_step test "$test_cmd"
run_step build "$build"

echo "[checks] OK" >&2
