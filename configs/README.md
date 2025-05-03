# 7D2D Server Configuration (`serverconfig.xml`)

This directory contains the configuration file for the 7 Days to Die dedicated server itself.

## `serverconfig.xml`

This is the main configuration file used by the `7DaysToDieServer.x86_64` process. It controls game settings like server name, password, difficulty, player limits, etc.

*   This file is copied from `serverconfig.default.xml` by the `initial_setup.ps1` script.
*   You should edit this file to customize your server settings **before** building the Docker image.
*   The `Dockerfile` copies this file into the image at `/app/serverconfig.xml`.
*   The `start-server.sh` script copies this file from `/app/serverconfig.xml` (inside the container) to `/data/serverconfig.xml` (the persistent volume) when the container starts, ensuring the latest configured settings are used and persisted.

Refer to the [7 Days to Die Wiki](https://7daystodie.fandom.com/wiki/Server_Configuration) or other community resources for details on the available settings within this file.

## `serverconfig.default.xml`

A default server configuration file provided by the game developers. It serves as the template for your `serverconfig.xml`.
