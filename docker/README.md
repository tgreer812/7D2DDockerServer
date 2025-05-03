# Docker Build Files

This directory contains the `Dockerfile` used to build the 7 Days to Die server image.

## `Dockerfile`

This file defines the steps to create the Docker image:

1.  **Base Image:** Starts from a specific Ubuntu base image (e.g., `ubuntu:22.04`).
2.  **Install Dependencies:** Installs necessary packages like `wget`, `lib32gcc-s1`, `steamcmd`, and potentially others required by the game server or scripts.
3.  **Set up SteamCMD:** Creates a directory for SteamCMD, downloads, and extracts it.
4.  **Create App Directory:** Creates the `/app` directory where server files will reside.
5.  **Copy Server Config:** Copies the `configs/serverconfig.xml` from the build context into the image at `/app/serverconfig.xml`.
6.  **Copy Scripts:** Copies the scripts from the `scripts/` directory into the image at `/app/scripts/` and makes them executable.
7.  **Set Working Directory:** Sets the working directory to `/app`.
8.  **Expose Ports:** Declares the ports the container will listen on (though actual mapping happens during `docker run`).
9.  **Define Entrypoint:** Sets the `start-server.sh` script as the command to run when the container starts.

This image is built and pushed to your Azure Container Registry using the `push-to-acr.ps1` script.
