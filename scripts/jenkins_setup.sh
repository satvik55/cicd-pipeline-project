#!/bin/bash
set -e

echo "========================================="
echo "  Jenkins Server Setup (Optimized)"
echo "========================================="

# Update system
echo "[1/9] Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Java 17
echo "[2/9] Installing Java 17..."
sudo apt-get install -y fontconfig openjdk-17-jre

# Install Jenkins
echo "[3/9] Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins

# Configure Jenkins JVM — cap at 512MB to prevent OOM
echo "[4/9] Configuring Jenkins JVM limits..."
sudo mkdir -p /etc/systemd/system/jenkins.service.d
cat << 'OVERRIDE' | sudo tee /etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Xmx512m -Xms256m"
OVERRIDE
sudo systemctl daemon-reload

# Install Docker
echo "[5/9] Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Docker permissions
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# Install Trivy
echo "[6/9] Installing Trivy..."
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install -y trivy

# Install Ansible
echo "[7/9] Installing Ansible..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible

# Install Git + Node.js
echo "[8/9] Installing Git and Node.js..."
sudo apt-get install -y git nodejs npm

# Set up 2GB swap (persistent)
echo "[9/9] Configuring 2GB swap..."
if [ ! -f /swapfile ]; then
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  echo "Swap created and enabled"
else
  echo "Swap already exists"
fi

# Restart Jenkins
sudo systemctl restart jenkins
sudo systemctl enable jenkins
sleep 15

echo ""
echo "========================================="
echo "  Setup Complete!"
echo "========================================="
echo "Jenkins:  $(sudo systemctl is-active jenkins)"
echo "Java:     $(java -version 2>&1 | head -1)"
echo "Docker:   $(docker --version 2>&1)"
echo "Trivy:    $(trivy --version 2>&1 | head -1)"
echo "Ansible:  $(ansible --version 2>&1 | head -1)"
echo "Git:      $(git --version)"
echo "Swap:     $(swapon --show | tail -1)"
echo "Memory:   $(free -h | grep Mem | awk '{print $2}')"
echo ""
echo "Jenkins initial password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "(already configured)"
echo "========================================="
