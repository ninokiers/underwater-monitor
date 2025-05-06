#!/usr/bin/env bash
set -e

# Prompt for configuration
CONFIG_FILE="config.env"
echo "CONFIG_FILE=$CONFIG_FILE" > "$SSH_CONFIG"

read -rp "Enter remote username (on Pi 5): " SSH_REMOTE_USER
read -rp "Enter remote LAN IP address (of Pi 5): " SSH_REMOTE_HOST
read -rp "Enter the Cloudflare API token: " CF_API_TOKEN
read -rp "Enter the Cloudflare root domain (zone name, e.g. hanobayreef.com): " CF_ZONE_NAME

echo "REMOTE_USER=$REMOTE_USER" >> "$SSH_CONFIG"
echo "REMOTE_HOST=$REMOTE_HOST" >> "$SSH_CONFIG"
echo "CF_API_TOKEN=$CF_API_TOKEN" >> "$SSH_CONFIG"
echo "CF_ZONE_NAME=$CF_ZONE_NAME" >> "$SSH_CONFIG"

# Install dependencies
sudo apt update
sudo apt install -y ffmpeg sqlite3 rsync curl openssh-client jq

# Set up SSH authorization
echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"

echo "Setting up SSH access to $REMOTE_USER@$REMOTE_HOST..."
ssh-copy-id "$REMOTE_USER@$REMOTE_HOST"
