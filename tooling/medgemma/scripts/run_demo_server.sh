#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$TOOL_DIR/../.." && pwd)"
PYTHON="${PYTHON:-$REPO_DIR/.venv/bin/python}"

if [[ ! -x "$PYTHON" ]]; then
  echo "Create the repository .venv and install tooling/medgemma first" >&2
  exit 1
fi

exec "$PYTHON" -m whypulse_medgemma.service.cli serve "$@"
