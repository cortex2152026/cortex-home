#!/usr/bin/env bash
set -euo pipefail

OUT="$(dirname "$0")/../status.json"
TMP=$(mktemp)

GH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
GOOG_LINE=$(GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-openclaw}" gog auth list --plain 2>/dev/null | head -n1 || true)
GOOG_EMAIL=$(echo "$GOOG_LINE" | awk '{print $1}')
GOOG_SERVICES=$(echo "$GOOG_LINE" | awk '{print $3}')
SEC_JSON=$(openclaw status --json 2>/dev/null)

python3 - <<'PY' "$OUT" "$GH_USER" "$GOOG_EMAIL" "$GOOG_SERVICES" "$SEC_JSON"
import json,sys,datetime
out,gh,ge,gs,sj = sys.argv[1:6]
data=json.loads(sj)
obj={
  "updatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "runtime": {
    "gateway": "running" if data.get("gateway",{}).get("reachable") else "down",
    "discord": "connected",
    "agents": len(data.get("agents",{}).get("agents",[])),
    "bootstrapPending": data.get("agents",{}).get("bootstrapPendingCount",0)
  },
  "models": {
    "main": "openai-codex/gpt-5.3-codex",
    "specialists": ["google/gemini-3-pro-preview", "anthropic/claude-opus-4-6"]
  },
  "integrations": {
    "github": {"status": "ok" if gh!="unknown" else "unknown", "account": gh},
    "google": {"status": "ok" if ge else "unknown", "account": ge or "unknown", "services": gs.split(',') if gs else []},
    "discord": {"status": "ok", "mode": "dm-only"}
  },
  "ops": {
    "backup": {"latest": "openclaw-STABLE.tgz", "path": "/home/ubuntu/.openclaw/backups/openclaw-STABLE.tgz", "schedule": "Daily 04:00 America/Chicago"},
    "security": data.get("securityAudit",{}).get("summary", {"critical":0,"warn":0,"info":0})
  }
}
open(out,'w').write(json.dumps(obj,indent=2))
PY

echo "updated $OUT"