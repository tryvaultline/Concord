#!/usr/bin/env bash
set -e

echo "========================================"
echo "Running Concord Health Checks..."
echo "========================================"

HEALTH_JSON=$(curl -s http://localhost:8080/v1/health || echo "FAILED")

if [[ "$HEALTH_JSON" == *"OK"* ]]; then
    echo "✅ Concord Auth Service: HEALTHY"
    echo "Payload: $HEALTH_JSON"
    exit 0
else
    echo "❌ Concord Auth Service: UNHEALTHY"
    exit 1
fi
