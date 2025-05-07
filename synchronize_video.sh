#!/usr/bin/env bash

. ./config.env
# Temporary, move to setup.sh
REMOTE_SERVER_PATH="/home/$SSH_REMOTE_USER/server"
echo "REMOTE_SERVER_PATH=$REMOTE_SERVER_PATH" >> "$CONFIG_FILE"

# Configuration
REMOTE_PATH="$REMOTE_SERVER_PATH/stream"
SEGMENT_PATH="video_segments"
ARCHIVE_PATH="video_archive"
TMP_CONCAT_LIST=/tmp/ts_concat_list.txt

# Compute a list of all .ts files that are not currently in use (in the .m3u8 file)
ssh "$SSH_REMOTE_USER@$SSH_REMOTE_HOST" "grep '.ts' ${REMOTE_PATH}/stream.m3u8" | sort > /tmp/in_use_ts.txt
ssh "$SSH_REMOTE_USER@$SSH_REMOTE_HOST" "cd $REMOTE_PATH && ls -1 *.ts" | sort > /tmp/all_ts.txt
comm -23 /tmp/all_ts.txt /tmp/in_use_ts.txt > /tmp/safe_ts.txt

# Rsync all the .ts files that are safe to copy and remove from source
rsync -av --remove-source-files --files-from=/tmp/safe_ts.txt "$SSH_REMOTE_USER@$SSH_REMOTE_HOST:$REMOTE_PATH" "$SEGMENT_PATH"

# Create a list of all files to concatenate
cd "$SEGMENT_PATH" || exit 1
ls -1v *.ts > /tmp/ts_file_list.txt

FILE_COUNT=$(wc -l < /tmp/ts_file_list.txt)
if [ "$FILE_COUNT" -lt 5 ]; then
    echo "Not enough files to concatenate. Exiting."
    exit 0
fi


awk -v path="$PWD/" '{print "file \x27" path $0 "\x27"}' /tmp/ts_file_list.txt > "$TMP_CONCAT_LIST"
cd ..

# Create output .mp4 file and add to SQLite database
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="clip_$TIMESTAMP.mp4"
ffmpeg -y -f concat -safe 0 -i "$TMP_CONCAT_LIST" -c copy "$ARCHIVE_PATH/$OUTPUT_FILE"

sqlite3 "$DB_PATH" "INSERT INTO recordings (filename) VALUES ('$OUTPUT_FILE');"
echo "Archived and logged $OUTPUT_FILE"

# Remove used .ts files
xargs rm < /tmp/ts_file_list.txt

# Check disk space and trim if < 2GB free
FREE_KB=$(df "$ARCHIVE_PATH" | awk 'NR==2 {print $4}')
FREE_MB=$((FREE_KB / 1024))
THRESHOLD_MB=2048

if [ "$FREE_MB" -lt "$THRESHOLD_MB" ]; then
    echo "Low disk space: $FREE_MB MB available. Starting cleanup..."

    while [ "$FREE_MB" -lt "$THRESHOLD_MB" ]; do
        OLDEST_FILE=$(ls -1tr "$ARCHIVE_PATH"/*.mp4 2>/dev/null | head -n 1)

        if [ -z "$OLDEST_FILE" ]; then
            echo "No more files to delete."
            break
        fi

        echo "Deleting $OLDEST_FILE to free space..."
        BASENAME=$(basename "$OLDEST_FILE")
        sqlite3 "$DB_PATH" "UPDATE records SET on_disk = 0 WHERE filename = '$BASENAME';"
        rm "$OLDEST_FILE"

        # Recalculate space
        FREE_KB=$(df "$ARCHIVE_PATH" | awk 'NR==2 {print $4}')
        FREE_MB=$((FREE_KB / 1024))
    done

    echo "Cleanup complete. $FREE_MB MB now available."
fi
