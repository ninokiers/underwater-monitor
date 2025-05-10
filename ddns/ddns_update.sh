#!/usr/bin/env bash

LAST_IP_FILE="ddns/last_ip.txt"

. ./config.env

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

  RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "Authorization: Bearer $CF_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$RECORD_NAME\",\"content\":\"$IP\",\"ttl\":1,\"proxied\":true}")

  echo "$RESPONSE"
  if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "Update for $RECORD_NAME successful."
    return 1
  else
    echo "Update for $RECORD_NAME unsuccessful."
    return 0
  fi
}

SUCCESS1=$(update_record "$CF_ZONE_NAME" "$CF_ROOT_RECORD_ID")
SUCCESS2=$(update_record "www.$CF_ZONE_NAME" "$CF_WWW_RECORD_ID")

# Save current IP
if [ "$SUCCESS1" = "1" ] && [ "$SUCCESS2" = "1" ]; then
  echo "$CURRENT_IP" > "$LAST_IP_FILE"
else
  echo "$(date): Not saving IP — one or both updates failed."
fi
