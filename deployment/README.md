# Deployment Scripts and Templates

This directory contains PowerShell scripts and template files used to automate the deployment process.

## Scripts

*   **`initial_setup.ps1`:** (Run Once) Prepares the local environment by copying template files (`config.example.json` -> `config.json`, `serverconfig.default.xml` -> `serverconfig.xml`) and installing the Bicep CLI using `install-bicep.ps1`.
*   **`install-bicep.ps1`:** Installs or updates the Bicep CLI using the Azure CLI.
*   **`push-to-acr.ps1`:** Builds the Docker image defined in `docker/Dockerfile` using an Azure Container Registry (ACR) Task and pushes it to your configured ACR. Reads ACR details and image name/tag from `config/config.json`.
*   **`deploy-bicep.ps1`:** The main deployment script. It performs the following:
    1.  Reads configuration from `config/config.json`.
    2.  Checks for/creates the specified Azure Resource Group.
    3.  Reads the `7dtd.service.template` and replaces placeholders with values from `config.json` (ACR details, image name/tag).
    4.  Base64 encodes the processed service content.
    5.  Constructs the `commandToExecute` string for the Custom Script Extension (includes decoding the service file, writing it, and managing the systemd service).
    6.  Reads the `cloud-init.txt` template and Base64 encodes it.
    7.  Validates the deployment using `Test-AzResourceGroupDeployment`.
    8.  Executes the Bicep deployment using `New-AzResourceGroupDeployment`, passing parameters including the encoded cloud-init data and the custom script command.
    9.  Outputs the public IP address of the deployed VM.

## Templates

*   **`7dtd.service.template`:** A systemd unit file template for the 7D2D server container. Contains placeholders (`<acrLoginServer>`, `<acrUsername>`, `<acrPassword>`, `<imageName>`, `<imageTag>`) that are replaced by `deploy-bicep.ps1`.
*   **`cloud-init.txt`:** A cloud-config file used for initial VM setup. It installs Docker and creates the `/opt/7dtd-data` directory.

## Deployment Workflow Summary

1.  Run `initial_setup.ps1` once.
2.  Edit `config/config.json` and `configs/serverconfig.xml`.
3.  Get/update ACR password in `config.json`.
4.  Run `push-to-acr.ps1` to build/push the image.
5.  Run `deploy-bicep.ps1` to deploy/update the VM and start the server.
