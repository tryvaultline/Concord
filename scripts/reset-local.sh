#!/usr/bin/env bash

echo "Resetting Concord Local Environment..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

bash "$SCRIPT_DIR/stop-local.sh"
rm -f .env.local
bash "$SCRIPT_DIR/bootstrap-local.sh"

echo "[RESET] Environment fully reset!"
