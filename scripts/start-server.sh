#!/bin/bash

# Define paths
STEAMCMD_DIR="/opt/steamcmd"
INSTALL_DIR="/7dtd" # Installation directory within the image
DATA_DIR="/data"    # Mount point for persistent Azure File Share
CONFIG_SOURCE_PATH="$INSTALL_DIR/myserverconfig.xml" # Config baked into image
CONFIG_DEST_PATH="$DATA_DIR/serverconfig.xml"      # Config on persistent volume
SERVER_EXEC="$INSTALL_DIR/7DaysToDieServer.x86_64"
STEAMCMD_LOG_FILE="$DATA_DIR/steamcmd_update.log" # Log file for steamcmd output
LOG_DIR="$DATA_DIR/logs" # Directory for server logs

# Ensure the data directory exists (it should be mounted, but check anyway)
mkdir -p "$DATA_DIR"
# Ensure the log directory exists
mkdir -p "$LOG_DIR"
# Clear or create the steamcmd log file on start
> "$STEAMCMD_LOG_FILE"

echo "Redirecting SteamCMD output to $STEAMCMD_LOG_FILE"

# Server is pre-installed in the image at $INSTALL_DIR
# Check for updates on every start directly in the installation directory
echo "Checking for 7 Days to Die server updates in $INSTALL_DIR..."
# Redirect stdout and stderr to the log file
$STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir "$INSTALL_DIR" +app_update 294420 validate +quit >> "$STEAMCMD_LOG_FILE" 2>&1

echo "SteamCMD update check finished. Check $STEAMCMD_LOG_FILE for details."

# Always copy serverconfig.xml from the image build to the persistent volume on start.
# This ensures the config defined in the repo/image is the one used,
# but allows it to be persisted and potentially modified later via the file share
# if the container restarts without a redeploy.
echo "Copying serverconfig.xml from image ($CONFIG_SOURCE_PATH) to persistent volume ($CONFIG_DEST_PATH)..."
if [ ! -f "$CONFIG_DEST_PATH" ]; then
    cp "$CONFIG_SOURCE_PATH" "$CONFIG_DEST_PATH"
else
    echo "Config file already exists at $CONFIG_DEST_PATH, not overwriting."
fi

# Start the server using the config file from the persistent volume
echo "Starting 7 Days to Die server..."

# Generate timestamp for the log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SERVER_LOG_FILE="$LOG_DIR/server_log_${TIMESTAMP}.txt"

echo "Server output will be logged to $SERVER_LOG_FILE"
echo "Using config file: $CONFIG_DEST_PATH"
echo "User data and saves will be stored in: $DATA_DIR"

# Set LD_LIBRARY_PATH to include the directory containing steamclient.so
export LD_LIBRARY_PATH="$STEAMCMD_DIR/linux64:$LD_LIBRARY_PATH"

# Use exec to replace the shell process with the server process
# -logfile: Specifies the log file path.
# -quit, -batchmode, -nographics: Standard dedicated server flags.
# -configfile: Points to the config on the persistent volume.
# NOTE: The directory in which the world is saved is specified in the server config file - not a command line arg!!
exec "$SERVER_EXEC" \
    -logfile "$SERVER_LOG_FILE" \
    -quit \
    -batchmode \
    -nographics \
    -configfile="$CONFIG_DEST_PATH" \
    -dedicated