#!/usr/bin/env bash

. ./config.env

SOURCE_DIR="video_archive"

# Temporary: check bucket size
MAX_BYTES=$((10 * 1024 * 1024 * 1024)) # 10 GB

BUCKET_SIZE=$(aws s3api list-objects-v2 \
  --bucket "$AWS_BUCKET" \
  --query "sum(Contents[].size)" \
  --output text)

BUCKET_SIZE=${BUCKET_SIZE:-0}

if [ "$BUCKET_SIZE" -lt "$MAX_BYTES" ]; then
  echo "Bucket under 10GB ($BUCKET_SIZE bytes), syncing..."

# Sync database and video files
aws s3 sync "$SOURCE_DIR" "s3://$AWS_BUCKET" \
  --exclude "*" \
  --include "*.mp4" \
  --include "data.db"

# Check exit status and remove old files
if [ $? -eq 0 ]; then
  find "$SOURCE_DIR" -type f -name "*.mp4" -delete
fi

# Temporary: check bucket size
else
  echo "Bucket exceeds 10GB, skipping sync!"
fi
