#!/usr/bin/env bash
set -euo pipefail

ROOT="/home/ubuntu/.openclaw/workspace/cortex-home"
cd "$ROOT"

# Keep gog usable in non-interactive cron runs
export GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-openclaw}"

./scripts/update-status.sh

if ! git diff --quiet -- status.json; then
  git add status.json
  git commit -m "chore: auto-refresh status.json"
  git push
fi

# Force production deploy (works even if Git integration is flaky)
npx vercel --prod --yes >/tmp/cortex-home-vercel.log 2>&1 || true
