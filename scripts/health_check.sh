#!/bin/bash
# health_check.sh — check if the app is responding
# Usage: ./scripts/health_check.sh <APP_IP>

APP_IP="${1:?Usage: health_check.sh <APP_IP>}"

echo "Checking http://$APP_IP/health ..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$APP_IP/health")

if [ "$HTTP_CODE" = "200" ]; then
    echo "HEALTHY (HTTP 200)"
    curl -s "http://$APP_IP/health" | python3 -m json.tool
    exit 0
else
    echo "UNHEALTHY (HTTP $HTTP_CODE)"
    exit 1
fi
