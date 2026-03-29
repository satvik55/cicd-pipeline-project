#!/bin/bash
# cleanup_images.sh — remove old Docker images on target server
# Usage: ./scripts/cleanup_images.sh <SERVER_IP> <SSH_KEY_PATH>

SERVER_IP="${1:?Usage: cleanup_images.sh <SERVER_IP> <SSH_KEY_PATH>}"
SSH_KEY="${2:-~/.ssh/devops-project-key.pem}"

echo "Cleaning Docker images on $SERVER_IP ..."

ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" ubuntu@"$SERVER_IP" << 'REMOTE'
    echo "Before cleanup:"
    docker system df

    # Remove dangling images
    docker image prune -f

    # Remove images older than 24h (except currently running)
    RUNNING_IMAGE=$(docker inspect --format='{{.Image}}' cicd-api 2>/dev/null || echo "none")
    echo "Currently running: $RUNNING_IMAGE"

    echo ""
    echo "After cleanup:"
    docker system df
REMOTE

echo "Cleanup complete on $SERVER_IP"
