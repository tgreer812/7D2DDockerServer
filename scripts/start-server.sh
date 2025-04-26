#!/bin/bash

# Define paths
STEAMCMD_DIR="/opt/steamcmd"
INSTALL_DIR="/data" # Mount point for persistent Azure File Share
CONFIG_SOURCE_PATH="/7dtd/serverconfig.xml" # Config copied from image
CONFIG_DEST_PATH="$INSTALL_DIR/serverconfig.xml"
SERVER_EXEC="$INSTALL_DIR/7DaysToDieServer.x86_64"

# Ensure the install directory exists (it should be mounted, but check anyway)
mkdir -p "$INSTALL_DIR"

# Check if server executable exists in the persistent volume
if [ ! -f "$SERVER_EXEC" ]; then
  echo "7 Days to Die server not found in $INSTALL_DIR. Installing for the first time..."
  $STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir "$INSTALL_DIR" +app_update 294420 validate +quit
else
  echo "7 Days to Die server found in $INSTALL_DIR. Checking for updates..."
  # Optionally update on every start - SteamCMD should only download changes
  $STEAMCMD_DIR/steamcmd.sh +login anonymous +force_install_dir "$INSTALL_DIR" +app_update 294420 validate +quit
fi

# Copy/update serverconfig.xml from the image build to the persistent volume
# Only do this if COPY_CONFIG_ON_START is explicitly set to true (or is unset, defaulting to true)
if [ "${COPY_CONFIG_ON_START:-true}" = "true" ]; then
  echo "Copying serverconfig.xml from image to $CONFIG_DEST_PATH..."
  cp "$CONFIG_SOURCE_PATH" "$CONFIG_DEST_PATH"
else
  echo "Skipping serverconfig.xml copy. Server will use existing or generate default in $CONFIG_DEST_PATH."
  # Ensure the config file path exists if we aren't copying, allowing server to generate if needed
  # If the server needs the file to exist even if empty, use touch.
  # If it can create it itself, this might not be needed.
  # Let's assume touching it is safe.
  touch "$CONFIG_DEST_PATH"
fi

# Start the server using the config file
# Environment variables SERVERNAME and SERVERPASSWORD are set by Bicep,
# but the server typically reads most settings from serverconfig.xml.
# The -configfile parameter points to the config on the persistent volume.
echo "Starting 7 Days to Die server..."
exec "$SERVER_EXEC" -logfile /dev/stdout -quit -batchmode -nographics -configfile="$CONFIG_DEST_PATH" -dedicated