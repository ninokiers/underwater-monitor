#!/usr/bin/env bash
set -e

# Prompt for configuration
CONFIG_FILE="config.env"
REPOSITORY="https://raw.githubusercontent.com/ninokiers/underwater-monitor/main"
echo "CONFIG_FILE=$CONFIG_FILE" > "$CONFIG_FILE"
echo "REPOSITORY=$REPOSITORY" >> "$CONFIG_FILE"

read -rp "Enter remote username (on Pi 5): " SSH_REMOTE_USER
read -rp "Enter remote LAN IP address (of Pi 5): " SSH_REMOTE_HOST
read -rp "Enter the Cloudflare API token: " CF_API_TOKEN
read -rp "Enter the Cloudflare root domain (zone name, e.g. hanobayreef.com): " CF_ZONE_NAME

echo "SSH_REMOTE_USER=$SSH_REMOTE_USER" >> "$CONFIG_FILE"
echo "SSH_REMOTE_HOST=$SSH_REMOTE_HOST" >> "$CONFIG_FILE"
echo "CF_API_TOKEN=$CF_API_TOKEN" >> "$CONFIG_FILE"
echo "CF_ZONE_NAME=$CF_ZONE_NAME" >> "$CONFIG_FILE"

# Install dependencies
sudo apt update
sudo apt install -y ffmpeg sqlite3 rsync curl openssh-client jq

# Set up SSH authorization
echo "Generating SSH key..."
ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"

echo "Setting up SSH access to $REMOTE_USER@$REMOTE_HOST..."
ssh-copy-id "$SSH_REMOTE_USER@$SSH_REMOTE_HOST"

# Download and install DDNS updater
DDNS_SETUP="ddns/ddns_setup.sh"
mkdir -vp "ddns"
curl -fsSL "$REPOSITORY/$DDNS_SETUP" -o "$DDNS_SETUP" || {
  echo "Failed to download $DDNS_SETUP from GitHub."
  exit 1
}

chmod +x "$DDNS_SETUP"

./"$DDNS_SETUP"
