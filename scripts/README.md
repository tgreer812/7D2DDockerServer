# Container Scripts

These scripts are copied into the Docker image and run inside the container.

## `start-server.sh`

This is the main entrypoint script for the Docker container, executed when the container starts.

1.  **Update Server:** Runs SteamCMD to download/update the 7 Days to Die dedicated server files into the `/app/server` directory within the container. Logs output to `/data/steamcmd_update.log` (persistent volume).
2.  **Copy Config:** Copies the `serverconfig.xml` (baked into the image) from `/app/serverconfig.xml` to `/data/serverconfig.xml` (persistent volume). This ensures the server uses the configuration intended at build time, while also making it visible/modifiable on the persistent volume if needed (though changes there won't survive a container rebuild without manual intervention).
3.  **Set Library Path:** Sets the `LD_LIBRARY_PATH` environment variable, often needed to resolve issues with Steam client libraries.
4.  **Execute Server:** Changes to the server directory (`/app/server`) and runs the `7DaysToDieServer.x86_64` executable.
    *   Uses `-configfile=/data/serverconfig.xml` to load the configuration from the persistent volume.
    *   Redirects server output (stdout/stderr) to log files within `/data/logs/` (persistent volume).

## `backup.sh` (Example)

An example script demonstrating how one might create backups of the server data. *Note: This script is not currently integrated into the automated workflow.*

## `restore.sh` (Example)

An example script demonstrating how one might restore server data from a backup. *Note: This script is not currently integrated into the automated workflow.*
