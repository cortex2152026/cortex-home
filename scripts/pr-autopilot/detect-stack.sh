#!/usr/bin/env bash
set -euo pipefail

# Usage: detect-stack.sh <repo_path>
# Outputs: JSON with best-effort detected stack + commands.

REPO="${1:-}"
if [[ -z "$REPO" ]]; then
  echo "usage: $0 <repo_path>" >&2
  exit 2
fi

cd "$REPO"

json_escape() {
  python3 - <<'PY' "$1"
import json,sys
print(json.dumps(sys.argv[1]))
PY
}

has() { command -v "$1" >/dev/null 2>&1; }

# 1) .autopilot.json override (if present)
if [[ -f .autopilot.json ]]; then
  python3 - <<'PY'
import json
with open('.autopilot.json','r') as f:
  cfg=json.load(f)
# minimal normalization
out={
  "source":".autopilot.json",
  "stack": cfg.get("stack") or "custom",
  "install": cfg.get("install"),
  "lint": cfg.get("lint"),
  "test": cfg.get("test"),
  "build": cfg.get("build"),
}
print(json.dumps(out,indent=2))
PY
  exit 0
fi

# 2) Node (package.json)
if [[ -f package.json ]]; then
  node - <<'NODE'
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json','utf8'));
const s = pkg.scripts || {};
const pm = fs.existsSync('pnpm-lock.yaml') ? 'pnpm'
  : fs.existsSync('yarn.lock') ? 'yarn'
  : 'npm';
const run = (script) => script ? `${pm} run ${script}` : null;
const install = pm === 'npm' ? 'npm ci' : pm === 'pnpm' ? 'pnpm install --frozen-lockfile' : 'yarn install --frozen-lockfile';
const out = {
  source: 'package.json',
  stack: 'node',
  packageManager: pm,
  install,
  lint: s.lint ? run('lint') : null,
  test: s.test ? run('test') : null,
  build: s.build ? run('build') : null,
};
console.log(JSON.stringify(out,null,2));
NODE
  exit 0
fi

# 3) Python (pyproject)
if [[ -f pyproject.toml ]]; then
  # Best-effort defaults; override via .autopilot.json for real commands.
  python3 - <<'PY'
import json
out={
  "source":"pyproject.toml",
  "stack":"python",
  "install": None,
  "lint": None,
  "test": None,
  "build": None,
  "note":"Python detected. Add .autopilot.json to define install/lint/test/build commands for this repo."
}
print(json.dumps(out,indent=2))
PY
  exit 0
fi

# 4) Go
if [[ -f go.mod ]]; then
  python3 - <<'PY'
import json
out={
  "source":"go.mod",
  "stack":"go",
  "install": None,
  "lint": None,
  "test": "go test ./...",
  "build": "go build ./...",
}
print(json.dumps(out,indent=2))
PY
  exit 0
fi

# 5) Rust
if [[ -f Cargo.toml ]]; then
  python3 - <<'PY'
import json
out={
  "source":"Cargo.toml",
  "stack":"rust",
  "install": None,
  "lint": "cargo fmt --check",
  "test": "cargo test",
  "build": "cargo build",
}
print(json.dumps(out,indent=2))
PY
  exit 0
fi

# 6) Makefile
if [[ -f Makefile ]]; then
  python3 - <<'PY'
import json
out={
  "source":"Makefile",
  "stack":"make",
  "install": None,
  "lint": "make lint",
  "test": "make test",
  "build": "make build",
  "note":"Commands are best-effort; if targets don't exist, add .autopilot.json."
}
print(json.dumps(out,indent=2))
PY
  exit 0
fi

# Nothing detected
python3 - <<'PY'
import json
out={
  "source":"none",
  "stack":"unknown",
  "install": None,
  "lint": None,
  "test": None,
  "build": None,
  "note":"No known stack detected. Add .autopilot.json to define checks."
}
print(json.dumps(out,indent=2))
PY
