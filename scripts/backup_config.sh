#!/bin/bash
# backup_config.sh — backup Jenkins and Nginx configs
# Usage: ./scripts/backup_config.sh <JENKINS_IP> <APP_IP> <SSH_KEY_PATH>

JENKINS_IP="${1:?Usage: backup_config.sh <JENKINS_IP> <APP_IP> <SSH_KEY>}"
APP_IP="${2:?Provide APP_IP as second argument}"
SSH_KEY="${3:-~/.ssh/devops-project-key.pem}"
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"

echo "Backing up configs to $BACKUP_DIR ..."

# Backup Nginx config from App server
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
    ubuntu@"$APP_IP":/etc/nginx/sites-available/cicd-api \
    "$BACKUP_DIR/nginx-cicd-api.conf" 2>/dev/null && echo "Nginx config saved" || echo "Nginx config not found"

# Backup Jenkins job config
scp -o StrictHostKeyChecking=no -i "$SSH_KEY" \
    ubuntu@"$JENKINS_IP":/var/lib/jenkins/jobs/cicd-pipeline/config.xml \
    "$BACKUP_DIR/jenkins-job-config.xml" 2>/dev/null && echo "Jenkins job config saved" || echo "Jenkins config not found"

echo ""
echo "Backup location: $BACKUP_DIR"
ls -la "$BACKUP_DIR/"
