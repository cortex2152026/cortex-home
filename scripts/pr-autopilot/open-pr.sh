#!/usr/bin/env bash
set -euo pipefail

# Usage: open-pr.sh <repo_path> <title> [body_file]
# Creates a PR for the current branch.

REPO="${1:-}"
TITLE="${2:-}"
BODY_FILE="${3:-}"

if [[ -z "$REPO" || -z "$TITLE" ]]; then
  echo "usage: $0 <repo_path> <title> [body_file]" >&2
  exit 2
fi

cd "$REPO"

if [[ -n "$BODY_FILE" ]]; then
  gh pr create --title "$TITLE" --body-file "$BODY_FILE"
else
  gh pr create --title "$TITLE" --fill
fi
