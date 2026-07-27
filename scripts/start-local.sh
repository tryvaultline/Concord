#!/usr/bin/env bash
set -e

echo "========================================"
echo "Starting Concord Local Service Stack..."
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "[SERVICE] Starting Concord Auth & Encryption Server..."
node services/concord-auth/server.js &
echo $! > .concord-auth.pid

sleep 2

curl -s http://localhost:8080/v1/health | grep -q "OK" && echo "[HEALTH] Concord Auth Service is LIVE!" || echo "[ERROR] Failed to start Concord Auth Service"
