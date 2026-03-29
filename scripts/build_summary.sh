#!/bin/bash
# build_summary.sh — clean build summary for Jenkins console output

BUILD_NUM="${1:-unknown}"
IMAGE_TAG="${2:-unknown}"
STATUS="${3:-SUCCESS}"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║           CI/CD Pipeline Build Summary           ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║  Status:    $STATUS"
echo "║  Build:     #$BUILD_NUM"
echo "║  Image:     satvik55/cicd-api:$IMAGE_TAG"
echo "║  App URL:   http://3.109.171.228"
echo "║  Health:    http://3.109.171.228/health"
echo "║  Info:      http://3.109.171.228/info"
echo "║  Jenkins:   http://13.126.223.204:8080"
echo "║  DockerHub: https://hub.docker.com/r/satvik55/cicd-api"
echo "╚══════════════════════════════════════════════════╝"
echo ""

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://3.109.171.228/health" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "Live verification: HEALTHY (HTTP 200)"
else
    echo "Live verification: HTTP $HTTP_CODE"
fi
