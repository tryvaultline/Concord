#!/usr/bin/env bash
set -e

echo "========================================"
echo "Bootstrapping Concord Local Stack..."
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ ! -f ".env.local" ]; then
    echo "[CONFIG] Creating .env.local from .env.example..."
    cp .env.example .env.local
else
    echo "[CONFIG] .env.local already exists."
fi

echo "[NPM] Installing Concord Auth Service dependencies..."
cd services/concord-auth
npm install
cd ../..

echo "[BOOTSTRAP] Concord environment initialized successfully!"
