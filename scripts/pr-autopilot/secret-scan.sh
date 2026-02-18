#!/usr/bin/env bash
set -euo pipefail

# Usage: secret-scan.sh <repo_path>
# Extremely lightweight grep-based scan. Not a substitute for real secret scanning.

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "usage: $0 <repo_path>" >&2
  exit 2
fi

cd "$REPO"

# Ignore common noise dirs (grep)
EXCLUDES=(--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build --exclude-dir=.vercel --exclude-dir=pr-autopilot)

# Patterns (best-effort). grep -E regex.
# NOTE: keep these specific to avoid false positives in lockfiles (e.g. "task-").
PATTERNS=(
  # OpenAI-style keys (require length)
  '\bsk-[A-Za-z0-9_-]{20,}\b'
  # Anthropic keys
  'sk-ant-'
  # Google API keys
  'AIza[0-9A-Za-z\-_]{10,}'
  # Slack tokens
  'xox[baprs]-'
  # Private keys
  '-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----'
)

found=0
for pat in "${PATTERNS[@]}"; do
  if grep -RInE "${pat}" . "${EXCLUDES[@]}" >/dev/null 2>&1; then
    echo "[secret-scan] potential match for pattern: ${pat}" >&2
    grep -RInE "${pat}" . "${EXCLUDES[@]}" | head -n 20 >&2 || true
    found=1
  fi
done

if [[ "$found" -eq 1 ]]; then
  echo "[secret-scan] FAIL: potential secrets detected" >&2
  exit 1
fi

echo "[secret-scan] OK" >&2
