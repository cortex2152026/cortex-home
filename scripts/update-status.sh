#!/usr/bin/env bash
set -euo pipefail

OUT="$(dirname "$0")/../status.json"

GH_USER=$(gh api user --jq .login 2>/dev/null || echo "unknown")
GOOG_LINE=$(GOG_KEYRING_PASSWORD="${GOG_KEYRING_PASSWORD:-openclaw}" gog auth list --plain 2>/dev/null | head -n1 || true)
GOOG_EMAIL=$(echo "$GOOG_LINE" | awk '{print $1}')
GOOG_SERVICES=$(echo "$GOOG_LINE" | awk '{print $3}')

STATUS_JSON=$(openclaw status --json 2>/dev/null || echo '{}')
AGENTS_JSON=$(openclaw agents list --json 2>/dev/null || echo '[]')

BACKUP_PATH=$(ls -1t /home/ubuntu/.openclaw/backups/*.tgz 2>/dev/null | head -n1 || true)
BACKUP_LATEST=$(basename "${BACKUP_PATH:-}" 2>/dev/null || echo "")

python3 - <<'PY' "$OUT" "$GH_USER" "$GOOG_EMAIL" "$GOOG_SERVICES" "$STATUS_JSON" "$AGENTS_JSON" "$BACKUP_LATEST" "$BACKUP_PATH"
import json,sys,datetime

out,gh,ge,gs,status_json,agents_json,backup_latest,backup_path = sys.argv[1:9]

def safe_json(s, default):
  try:
    return json.loads(s)
  except Exception:
    return default

status = safe_json(status_json, {})
agents = safe_json(agents_json, [])

# Discord: OpenClaw status exposes configured channels, not a reliable "connected" probe.
channel_summary = status.get("channelSummary") or []
discord_configured = any(isinstance(x,str) and x.lower().startswith("discord:") for x in channel_summary)

def_agent = next((a for a in agents if a.get("isDefault")), agents[0] if agents else {})
main_model = def_agent.get("model") or "unknown"
specialists = [a.get("model") for a in agents if a.get("id") != def_agent.get("id") and a.get("model")]

security = (status.get("securityAudit") or {}).get("summary") or {"critical":0,"warn":0,"info":0}

obj={
  "updatedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "runtime": {
    "gateway": "running" if (status.get("gateway",{}) or {}).get("reachable") else "down",
    "agents": len(agents),
  },
  "models": {
    "main": main_model,
    "specialists": specialists,
  },
  "integrations": {
    "github": {"status": "ok" if gh!="unknown" else "unknown", "account": gh},
    "google": {"status": "ok" if ge else "unknown", "account": ge or "unknown", "services": gs.split(',') if gs else []},
    "discord": {"status": "configured" if discord_configured else "unknown", "mode": "dm-only" if discord_configured else ""},
  },
  "ops": {
    "backup": {
      "latest": backup_latest or "unknown",
      "path": backup_path or "unknown",
    },
    "security": security,
  }
}

open(out,'w').write(json.dumps(obj,indent=2))
PY

echo "updated $OUT"
