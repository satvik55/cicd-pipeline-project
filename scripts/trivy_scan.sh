#!/bin/bash
# trivy_scan.sh — scan Docker image and generate reports
# Usage: ./scripts/trivy_scan.sh <IMAGE:TAG> [--strict]

set -e

IMAGE="${1:?Usage: trivy_scan.sh <IMAGE:TAG> [--strict]}"
STRICT="${2:-}"
REPORT_DIR="trivy-reports"

mkdir -p "$REPORT_DIR"

echo "============================================"
echo "Trivy Security Scan"
echo "Image: $IMAGE"
echo "Mode:  ${STRICT:+STRICT (fail on CRITICAL)}${STRICT:-REPORT ONLY}"
echo "============================================"

# 🔥 COMMON FLAGS
TRIVY_FLAGS="--severity HIGH,CRITICAL --no-progress --ignorefile docker/.trivyignore"

echo ""
echo "--- Vulnerability Summary ---"

# Table output
trivy image $TRIVY_FLAGS --format table "$IMAGE" | tee "$REPORT_DIR/trivy-summary.txt" || true

# JSON report
trivy image $TRIVY_FLAGS --format json --output "$REPORT_DIR/trivy-report.json" "$IMAGE" || true

# 🔥 STRICT MODE (fail only on CRITICAL)
if [[ "$STRICT" == "--strict" ]]; then
    echo ""
    echo "Checking for CRITICAL vulnerabilities..."

    CRITICAL_COUNT=$(trivy image $TRIVY_FLAGS --format json "$IMAGE" | jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length')

    echo "CRITICAL count: $CRITICAL_COUNT"

    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo "❌ CRITICAL vulnerabilities found — failing pipeline"
        exit 1
    else
        echo "✅ No CRITICAL vulnerabilities — safe to proceed"
    fi
fi
