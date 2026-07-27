#!/usr/bin/env bash

echo "Stopping Concord Local Services..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ -f ".concord-auth.pid" ]; then
    PID=$(cat .concord-auth.pid)
    kill -9 $PID 2>/dev/null || true
    rm .concord-auth.pid
    echo "[STOPPED] Concord Auth process ($PID) terminated."
else
    pkill -f "concord-auth" || true
fi
