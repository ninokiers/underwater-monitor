#!/bin/sh

echo "Enter your Cloudflare API Token:"
read -r CF_API_TOKEN

echo "Enter your root domain (zone name, e.g. hanobayreef.com):"
read -r ZONE_NAME

RECORDS="$ZONE_NAME www.$ZONE_NAME"
CONFIG_FILE="ddns_config.env"

# Get Zone ID
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$ZONE_NAME" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
  echo "Error: Could not find Zone ID for $ZONE_NAME"
  exit 1
fi

echo "ZONE_NAME=$ZONE_NAME" > "$CONFIG_FILE"
echo "ZONE_ID=$ZONE_ID" >> "$CONFIG_FILE"
echo "CF_API_TOKEN=$CF_API_TOKEN" >> "$CONFIG_FILE"

# Get Record IDs
for RECORD in $RECORDS; do
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$RECORD" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
    echo "Error: Could not find DNS record for $RECORD"
    exit 1
  fi

  VAR_NAME=$(echo "$RECORD" | sed 's/^www\..*/WWW/; t; s/.*/ROOT/')_ID
  echo "$VAR_NAME=$RECORD_ID" >> "$CONFIG_FILE"
done

echo "Configuration saved to $CONFIG_FILE"

# Download updater script from GitHub
REPO_URL="https://raw.githubusercontent.com/ninokiers/underwater-monitor/ddns/"
SCRIPT_NAME="ddns_update.sh"

echo "Downloading $SCRIPT_NAME from GitHub..."
curl -fsSL "$REPO_URL$SCRIPT_NAME" -o "$SCRIPT_NAME" || {
  echo "Failed to download $SCRIPT_NAME from GitHub."
  exit 1
}

chmod +x "$SCRIPT_NAME"
echo "Download complete."

# Set up systemd timer and service to run updater every minute
SERVICE_PATH="/etc/systemd/system/ddns_update.service"
TIMER_PATH="/etc/systemd/system/ddns_update.timer"

# Create systemd service
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Cloudflare DDNS Update

[Service]
Type=oneshot
ExecStart=$PWD/$SCRIPT_NAME
EOF

# Create system-wide systemd timer
sudo tee "$TIMER_PATH" > /dev/null <<EOF
[Unit]
Description=Run Cloudflare DDNS Update every minute

[Timer]
OnBootSec=30
OnUnitActiveSec=60
Unit=ddns_update.service
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable --now ddns_update.timer

echo "Systemd timer installed and running:"
sudo systemctl list-timers ddns_update.timer
