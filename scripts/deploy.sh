#!/bin/bash
set -e

APP_IP="${1:?Usage: deploy.sh <APP_IP> <DOCKER_TAG> <SSH_KEY_PATH>}"
DOCKER_TAG="${2:-latest}"
SSH_KEY="${3:-/var/lib/jenkins/.ssh/devops-project-key.pem}"
DOCKER_IMAGE="satvik55/cicd-api"
CONTAINER_NAME="cicd-api"

# Use private IP for SSH (Jenkins connects internally via VPC)
PRIVATE_IP=$(grep ansible_host /opt/ansible/inventory.ini | cut -d= -f2 | tr -d ' ')

echo "============================================"
echo "Deploying $DOCKER_IMAGE:$DOCKER_TAG"
echo "Target (private IP): $PRIVATE_IP"
echo "============================================"

chmod 400 "$SSH_KEY"

if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes -i "$SSH_KEY" ubuntu@"$PRIVATE_IP" "echo 'SSH OK'" 2>/dev/null; then
    echo "ERROR: Cannot SSH to $PRIVATE_IP"
    exit 1
fi

ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i "$SSH_KEY" ubuntu@"$PRIVATE_IP" << REMOTE
    set -e
    echo "[1/5] Pulling image..."
    docker pull $DOCKER_IMAGE:$DOCKER_TAG

    echo "[2/5] Stopping old container..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true

    echo "[3/5] Starting new container..."
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p 3000:3000 \
        -e NODE_ENV=production \
        -e PORT=3000 \
        --log-driver json-file \
        --log-opt max-size=10m \
        --log-opt max-file=3 \
        $DOCKER_IMAGE:$DOCKER_TAG

    echo "[4/5] Health check..."
    for i in \$(seq 1 15); do
        if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
            echo "App is healthy!"
            break
        fi
        if [ \$i -eq 15 ]; then
            echo "ERROR: Health check failed"
            docker logs $CONTAINER_NAME --tail 20
            exit 1
        fi
        echo "  Waiting... (\$i/15)"
        sleep 3
    done

    echo "[5/5] Cleaning old images..."
    docker image prune -f
    echo ""
    echo "Running container:"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | grep $CONTAINER_NAME
REMOTE

echo ""
echo "============================================"
echo "SUCCESS: $DOCKER_IMAGE:$DOCKER_TAG deployed"
echo "============================================"
