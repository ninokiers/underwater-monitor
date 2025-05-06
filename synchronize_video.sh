#!/usr/bin/env bash

# Configuration
REMOTE_USER=admin
REMOTE_HOST=192.168.1.225
REMOTE_PATH=/home/admin/server/stream/
LOCAL_PATH=/home/admin/video_segments/
OUTPUT_PATH=/home/admin/video_archive/
DB_PATH=/home/admin/video_archive/recordings.db
TMP_CONCAT_LIST=/tmp/ts_concat_list.txt

# Create directories if they don't exist
mkdir -p "$LOCAL_PATH" "$OUTPUT_PATH"

# 1. Fetch list of in-use .ts files from m3u8
ssh "$REMOTE_USER@$REMOTE_HOST" "grep '.ts' ${REMOTE_PATH}stream.m3u8" | sort > /tmp/in_use_ts.txt

# 2. Fetch list of all .ts files in remote stream folder
ssh "$REMOTE_USER@$REMOTE_HOST" "cd $REMOTE_PATH && ls -1 *.ts" | sort > /tmp/all_ts.txt

# 3. Compute safe-to-copy files
comm -23 /tmp/all_ts.txt /tmp/in_use_ts.txt > /tmp/safe_ts.txt

# 4. Rsync safe files only
rsync -av --remove-source-files --files-from=/tmp/safe_ts.txt "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH" "$LOCAL_PATH"

# 5. Create concat list
cd "$LOCAL_PATH" || exit 1
ls -1v *.ts > /tmp/ts_file_list.txt

# Exit early if not enough files
FILE_COUNT=$(wc -l < /tmp/ts_file_list.txt)
if [ "$FILE_COUNT" -lt 5 ]; then
    echo "Not enough files to concatenate. Exiting."
    exit 0
fi

awk -v path="$LOCAL_PATH" '{print "file \x27" path $0 "\x27"}' /tmp/ts_file_list.txt > "$TMP_CONCAT_LIST"

# 6. Create output file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="clip_$TIMESTAMP.mp4"
ffmpeg -y -f concat -safe 0 -i "$TMP_CONCAT_LIST" -c copy "$OUTPUT_PATH/$OUTPUT_FILE"

# 7. Remove used .ts files
xargs rm < /tmp/ts_file_list.txt

# 8. Log in SQLite
sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS recordings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    on_disk BOOLEAN DEFAULT 1
);
INSERT INTO recordings (filename) VALUES ('$OUTPUT_FILE');
EOF

echo "Archived and logged $OUTPUT_FILE"

# 9. Check disk space and trim if < 2GB
FREE_KB=$(df "$OUTPUT_PATH" | awk 'NR==2 {print $4}')
FREE_MB=$((FREE_KB / 1024))
THRESHOLD_MB=2048

if [ "$FREE_MB" -lt "$THRESHOLD_MB" ]; then
    echo "Low disk space: $FREE_MB MB available. Starting cleanup..."

    while [ "$FREE_MB" -lt "$THRESHOLD_MB" ]; do
        OLDEST_FILE=$(ls -1tr "$OUTPUT_PATH"/*.mp4 2>/dev/null | head -n 1)

        if [ -z "$OLDEST_FILE" ]; then
            echo "No more files to delete."
            break
        fi

        echo "Deleting $OLDEST_FILE to free space..."
        BASENAME=$(basename "$OLDEST_FILE")
        sqlite3 "$DB_PATH" "UPDATE records SET on_disk = 0 WHERE filename = '$BASENAME';"
        rm "$OLDEST_FILE"

        # Recalculate space
        FREE_KB=$(df "$OUTPUT_PATH" | awk 'NR==2 {print $4}')
        FREE_MB=$((FREE_KB / 1024))
    done

    echo "Cleanup complete. $FREE_MB MB now available."
fi
