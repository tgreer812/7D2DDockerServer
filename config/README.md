# Deployment Configuration (`config.json`)

This directory holds the configuration file used by the deployment scripts.

## `config.json`

This file contains parameters needed by the deployment scripts (`push-to-acr.ps1`, `deploy-bicep.ps1`) to interact with Azure and configure the deployment.

**Important:** This file is created by copying `config.example.json` during the `initial_setup.ps1` script. You **must** fill in the required values before deploying.

### Parameters:

*   `acrName`: (Required) The name of your Azure Container Registry (e.g., `myacr`).
*   `acrLoginServer`: (Required) The full login server name of your ACR (e.g., `myacr.azurecr.io`).
*   `imageName`: (Required) The name for the Docker image in your ACR (e.g., `7dtd-server`).
*   `tag`: (Required) The tag for the Docker image (e.g., `latest`, `v1.0`).
*   `resourceGroup`: (Required) The name of the Azure Resource Group to deploy resources into.
*   `location`: (Required) The Azure region for deployment (e.g., `eastus`).
*   `vmName`: (Required) The desired name for the Azure Virtual Machine.
*   `adminUsername`: (Required) The username for the administrative user on the VM.
*   `adminPassword`: (Required) The password for the administrative user on the VM. **Treat this as sensitive.**
*   `acrPassword`: (Required) An admin password or token for your ACR, used by the systemd service on the VM to log in and pull the image. Get this using `az acr credential show --name <your-acr-name> --query "passwords[0].value" -o tsv`. **Treat this as sensitive.**

*Note: Some parameters from `config.example.json` like `containerGroupName`, `fileShareName`, `serverName`, `serverPassword`, and `adminPrincipalId` are not currently used by the VM deployment scripts but might be relevant for other deployment methods (like ACI) or future enhancements.*

## `config.example.json`

A template file showing the structure of `config.json`. It is copied to `config.json` by the `initial_setup.ps1` script.
