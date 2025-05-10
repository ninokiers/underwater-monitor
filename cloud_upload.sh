#!/usr/bin/env bash

. ./config.env

SOURCE_DIR="video_archive"

# Update 'on_disk' flag for all files to be deleted
echo "Updating local database..."

UPLOAD_LIST=$(find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.mp4")

for FILE in $UPLOAD_LIST; do
  BASENAME=$(basename "$FILE")
  sqlite3 "$DB_PATH" "UPDATE recordings SET on_disk = 0 WHERE filename = '$BASENAME';"
done

echo "All 'on_disk' flags updated successfully."

# Check if cloud upload is enabled
if [ "$CLOUD_UPLOAD" = "FALSE" ]; then
  echo "Cloud upload is diabled. Exiting and removing local files..."
  rm "$SOURCE_DIR"/*.mp4
  exit 0
fi

# Sync database and video files
echo "Synchronizing with cloud..."
aws s3 sync "$SOURCE_DIR" "s3://$AWS_BUCKET" \
  --endpoint-url "$AWS_ENDPOINT" \
  --exclude "*" \
  --include "*.mp4" \
  --include "data.db"

# Check exit status and remove old files
if [ $? -eq 0 ]; then
  find "$SOURCE_DIR" -type f -name "*.mp4" -delete
fi
