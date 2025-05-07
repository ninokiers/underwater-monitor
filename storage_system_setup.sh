#!/usr/bin/env bash
set -e

. ./config.env

# Create folders
echo "Creating directories..."
mkdir -vp video_archive video_segments
rm -f video_archive/* video_segments/*

# Create the SQLite database and schema
DB_PATH="video_archive/data.db"
echo "DB_PATH=$DB_PATH" >> "$CONFIG_FILE"
echo "Setting up SQLite database at $DB_PATH"

sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS recordings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    on_disk BOOLEAN DEFAULT 1
);

CREATE TABLE IF NOT EXISTS sensor_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    lux REAL,
    temperature REAL
);
EOF

# Download synchronize_video.sh from GitHub
echo "Downloading script(s) from GitHub..."
SCRIPT_FILE="synchronize_video.sh"

curl -fsSL "$REPOSITORY/$SCRIPT_FILE" -o "$SCRIPT_FILE" || {
  echo "Unable to download $SCRIPT_FILE from GitHub."
  exit 1
}

chmod +x "$SCRIPT_FILE"

echo "Setup complete."

