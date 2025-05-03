# Azure Infrastructure (Bicep)

This directory contains the Bicep template used to define and deploy the Azure resources required for the 7D2D server.

## `deploy.bicep`

This file defines the following Azure resources:

*   **Virtual Network (VNet) & Subnet:** Creates a private network space for the VM.
*   **Network Security Group (NSG):** Defines firewall rules to allow necessary traffic:
    *   SSH (TCP port 22) - For administrative access.
    *   7D2D Game Ports (TCP/UDP 26900-26903) - For game clients.
    *   7D2D Web/Telnet Ports (TCP 8080-8081) - For server management interfaces.
*   **Public IP Address:** A static public IP address assigned to the VM so the server can be reached from the internet.
*   **Network Interface (NIC):** Connects the VM to the VNet and associates the Public IP and NSG.
*   **Virtual Machine (VM):** An Ubuntu 24.04 LTS VM where the Docker container will run.
    *   Uses `cloud-init` (via the `customData` property) for initial setup (installing Docker, creating directories).
*   **VM Extension (CustomScript):** Runs after the VM is provisioned to:
    *   Place the processed `7dtd.service` file in `/etc/systemd/system/`.
    *   Enable and start the `7dtd.service`.

## Parameters

The Bicep template accepts parameters provided by the `deploy-bicep.ps1` script, including:

*   `location`: Azure region for deployment.
*   `vmName`: Name for the virtual machine.
*   `adminUsername`: Admin username for the VM.
*   `adminPassword`: Admin password for the VM (passed securely).
*   `customDataBase64`: Base64 encoded cloud-init script content.
*   `customScriptCommand`: The command to be executed by the Custom Script Extension.

## Outputs

*   `publicIp`: The public IP address assigned to the VM.
