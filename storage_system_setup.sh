#!/usr/bin/env bash

set -e

# Create folders
echo "Creating directories..."
mkdir -v -p video_archive
mkdir -v -p video_segments
rm -f video_archive/*
rm -f video_segments/*

# Create the SQLite database and schema
DB_PATH="video_archive/data.db"
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
SCRIPT_PATH="synchronize_video.sh"
curl -fsSL https://raw.githubusercontent.com/ninokiers/underwater-monitor/storage-system/synchronize_video.sh -o "$SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

echo "Setup complete."

