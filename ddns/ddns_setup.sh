#!/usr/bin/env bash
set -e

. ./config.env

# Get Zone ID
CF_ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CF_ZONE_NAME" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$CF_ZONE_ID" = "null" ] || [ -z "$CF_ZONE_ID" ]; then
  echo "Error: Could not find Zone ID for $CF_ZONE_NAME"
  exit 1
fi

echo "CF_ZONE_ID=$CF_ZONE_ID" >> "$CONFIG_FILE"

# Get Record IDs
RECORDS="$CF_ZONE_NAME www.$CF_ZONE_NAME"
for RECORD in $RECORDS; do
  RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$RECORD" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
    echo "Error: Could not find DNS record for $RECORD"
    exit 1
  fi

  VAR_NAME=CF_$(echo "$RECORD" | sed 's/^www\..*/WWW/; t; s/.*/ROOT/')_RECORD_ID
  echo "$VAR_NAME=$RECORD_ID" >> "$CONFIG_FILE"
done

echo "Configuration saved to $CONFIG_FILE"

# Download updater script from GitHub
SCRIPT_NAME="ddns/ddns_update.sh"

echo "Downloading $SCRIPT_NAME from GitHub..."
curl -fsSL "$REPOSITORY/$SCRIPT_NAME" -o "$SCRIPT_NAME" || {
  echo "Failed to download $SCRIPT_NAME from GitHub."
  exit 1
}

chmod +x "$SCRIPT_NAME"
echo "Download complete."

# Create systemd service
sudo tee "/etc/systemd/system/ddns_update.service" > /dev/null <<EOF
[Unit]
Description=Cloudflare DDNS Update

[Service]
Type=oneshot
WorkingDirectory=$PWD
ExecStart=$PWD/$SCRIPT_NAME
EOF

# Create system-wide systemd timer
sudo tee "/etc/systemd/system/ddns_update.timer" > /dev/null <<EOF
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
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ddns_update.timer

echo "Systemd timer installed and running:"
sudo systemctl list-timers ddns_update.timer
