#!/bin/bash

# Define backup directory and timestamp
BACKUP_DIR="/path/to/backup/directory"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup server data
tar -czf "$BACKUP_DIR/7dtd_backup_$TIMESTAMP.tar.gz" /path/to/server/data

# Optional: Remove backups older than 7 days
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;

echo "Backup completed: $BACKUP_DIR/7dtd_backup_$TIMESTAMP.tar.gz"