#!/bin/bash
#####################################################################################################################
# @brief: This script sets up a VPC for n8n on AWS using Terraform.
#####################################################################################################################
### @file : vpc_n8n_setup.sh
### @author: Venu
### @date: 2023-10-01
### @version: 1.0
### @license: ----
### @description : This script sets up a VPC for n8n
#####################################################################################################################
#####################################################################################################################

set -e
# Docker installation
if ! command -v docker &> /dev/null; then
    echo "🚀 Docker not found. Installing Docker..."
    
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-cache policy docker.io
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    # Ensure Docker is running
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "✅ Docker installed successfully."
else
    echo "Docker is already installed."
    echo "⭕ Skipping Docker installation."
fi

#Creating volume volume for n8n workflow data
if ! docker volume ls | grep -q n8n_data; then
    echo "🚀 Creating Docker volume for n8n workflow data..."
    docker volume create n8n_data
    echo "✅ Docker volume 'n8n_data' created successfully."
else
    echo "Docker volume 'n8n_data' already exists."
    echo "⭕ Skipping Docker volume creation."
fi

#Run n8n using Docker compose
wget -q https://raw.githubusercontent.com/vencu/vpc_n8n/refs/heads/main/docker-compose.yaml -O docker-compose.yml
if [ ! -f docker-compose.yml ]; then
    echo "❌ Failed to download docker-compose.yml. Exiting."
    exit 1
fi
echo "🚀 Starting n8n using Docker Compose..."
export EXTERNAL_IP=$(hostname -I | awk '{print $1}')
sudo -E docker compose up -d

# Check if n8n is started
if docker ps | grep -q n8n; then
    echo "n8n is already running."
    echo "⭕ Skipping n8n installation."
else
    echo "🚀 Starting n8n..."
    docker-compose up -d
    echo " n8n started successfully."
fi

# Check if n8n is already running
if docker ps | grep -q n8n; then
    echo "✅ n8n is running successfully."
else
    echo "❌ n8n failed to start. Please check the logs for more details."
    exit 1
fi
echo "✅ n8n setup completed successfully."

# Display n8n URL
echo "You can access n8n at: http://${EXTERNAL_IP}:80"
# Display Docker volume information
echo "Docker volume 'n8n_data' is created and used for storing n8n workflow data."

# Display n8n logs
echo "n8n logs:"
docker logs n8n
