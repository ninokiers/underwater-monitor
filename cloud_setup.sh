#!/usr/bin/env bash

. ./config.env

# Configure AWS credentials
echo "Setting up AWS credentials..."
rm -f "/root/.aws/config" "/root/.aws/credentials"

aws configure --profile default set aws_access_key_id "$AWS_ACCESS_KEY"
aws configure --profile default set aws_secret_access_key "$AWS_SECRET_KEY"
aws configure --profile default set region "auto"

echo "Credentials installed."

# Download cloud_upload.sh from GitHub
echo "Downloading script(s) from GitHub..."
SCRIPT_FILE="cloud_upload.sh"

curl -fsSL "$REPOSITORY/$SCRIPT_FILE" -o "$SCRIPT_FILE" || {
  echo "Unable to download $SCRIPT_FILE from GitHub."
  exit 1
}

chmod +x "$SCRIPT_FILE"

echo "Script downloaded and installed."

# Create systemd service
echo "Creating systemd service and timer..."

cat <<EOF | sudo tee /etc/systemd/system/cloud_upload.service > /dev/null
[Unit]
Description=Upload mp4 files and database to the cloud.

[Service]
Type=oneshot
WorkingDirectory=$PWD
ExecStart=$PWD/$SCRIPT_FILE
EOF

# Create systemd timer
cat <<EOF | sudo tee /etc/systemd/system/cloud_upload.timer > /dev/null
[Unit]
Description=Run cloud upload service every 6 hours.

[Timer]
OnBootSec=2min
OnUnitActiveSec=6h
Unit=cloud_upload.service

[Install]
WantedBy=timers.target
EOF

# --- Enable and start the timer ---
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now cloud_upload.timer

echo "Done. Videos will upload to the cloud every 6 hours."
