#!/usr/bin/env bash

LAST_IP_FILE="last_ip.txt"

. ../config.env

# Get current IP
IP=$(curl -s https://api.ipify.org)

# Check if IP has changed
if [ -f "LAST_IP_FILE" ]; then
  LAST_IP=$(cat "$LAST_IP_FILE")
else
  LAST_IP=""
fi

if [ "$IP" = "$LAST_IP" ]; then
  exit 0
fi

update_record() {
  RECORD_NAME="$1"
  RECORD_ID="$2"
  echo "Updating $RECORD_NAME to $IP..."

  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":1,\"proxied\":true}" > /dev/null
}

update_record "$ZONE_NAME" "$ROOT_ID"
update_record "www.$ZONE_NAME" "$WWW_ID"

# Save current IP
echo "$IP" > "$LAST_IP_FILE"
