#!/bin/bash

# Check if a backup file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <backup-file>"
  exit 1
fi

BACKUP_FILE=$1

# Check if the backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
  echo "Backup file $BACKUP_FILE does not exist."
  exit 1
fi

# Restore the server data from the backup file
echo "Restoring server data from $BACKUP_FILE..."
tar -xzf "$BACKUP_FILE" -C /path/to/server/data

echo "Restore completed."