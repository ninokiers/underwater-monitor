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

