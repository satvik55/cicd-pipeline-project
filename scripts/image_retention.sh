#!/bin/bash
# image_retention.sh — keep only the last N images on a server
# Usage: ./scripts/image_retention.sh <SERVER_IP> <SSH_KEY> [KEEP_COUNT]

SERVER_IP="${1:?Usage: image_retention.sh <SERVER_IP> <SSH_KEY> [KEEP_COUNT]}"
SSH_KEY="${2:?Provide SSH key path}"
KEEP_COUNT="${3:-3}"

echo "Image retention: keeping last $KEEP_COUNT images on $SERVER_IP"

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$SERVER_IP" << REMOTE
    echo "=== Before cleanup ==="
    docker images satvik55/cicd-api --format "{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | head -10

    # Get all tags except 'latest', sorted by creation date
    ALL_TAGS=\$(docker images satvik55/cicd-api --format "{{.CreatedAt}}\t{{.Tag}}" | grep -v latest | sort -r | awk '{print \$NF}')
    TOTAL=\$(echo "\$ALL_TAGS" | wc -l)

    if [ "\$TOTAL" -gt "$KEEP_COUNT" ]; then
        TO_DELETE=\$(echo "\$ALL_TAGS" | tail -n +\$(($KEEP_COUNT + 1)))
        echo ""
        echo "Removing \$(echo "\$TO_DELETE" | wc -l) old images..."
        for TAG in \$TO_DELETE; do
            echo "  Removing: satvik55/cicd-api:\$TAG"
            docker rmi "satvik55/cicd-api:\$TAG" 2>/dev/null || true
        done
    else
        echo "Only \$TOTAL images present — nothing to clean"
    fi

    # Also prune dangling images
    docker image prune -f > /dev/null 2>&1

    echo ""
    echo "=== After cleanup ==="
    docker images satvik55/cicd-api --format "{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
REMOTE
