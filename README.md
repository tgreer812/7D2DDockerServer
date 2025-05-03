# 7 Days to Die Docker Server on Azure VM

This project provides a Dockerized setup for running a 7 Days to Die dedicated server on a dedicated Ubuntu Virtual Machine (VM) in Azure. It includes configuration files, scripts, and Bicep templates for automated deployment.

## Project Structure

```
.
├── azure/                  # Azure infrastructure (Bicep)
│   ├── deploy.bicep
│   └── README.md
├── config/                 # Deployment configuration
│   ├── config.example.json
│   ├── config.json
│   └── README.md
├── configs/                # 7D2D server configuration
│   ├── serverconfig.default.xml
│   ├── serverconfig.xml
│   └── README.md
├── deployment/             # Deployment scripts and templates
│   ├── 7dtd.service.template
│   ├── cloud-init.txt
│   ├── deploy-bicep.ps1
│   ├── initial_setup.ps1
│   ├── install-bicep.ps1
│   ├── push-to-acr.ps1
│   └── README.md
├── docker/                 # Docker build files
│   ├── Dockerfile
│   └── README.md
├── scripts/                # Container scripts
│   ├── backup.sh
│   ├── restore.sh
│   ├── start-server.sh
│   └── README.md
├── docs/                   # Additional documentation and guides
│   ├── service_management.md
│   ├── save_transfer.md
│   └── sshfs_setup.md
├── .gitignore
├── LICENSE
└── README.md               # This file (main overview)
```

## Overview

This setup provisions an Azure VM, installs Docker, pulls a pre-built 7D2D server image from Azure Container Registry (ACR), and runs it as a systemd service. Server data is persisted on the VM's host disk.

See the README files within each directory for more specific details:

*   [`azure/README.md`](azure/README.md)
*   [`config/README.md`](config/README.md)
*   [`configs/README.md`](configs/README.md)
*   [`deployment/README.md`](deployment/README.md)
*   [`docker/README.md`](docker/README.md)
*   [`scripts/README.md`](scripts/README.md)

For operational guides (managing the service, transferring saves, etc.), see the [`docs/`](docs/) directory.

## Prerequisites

*   **Azure Account:** Active subscription with permissions to create resource groups, VMs, networking, and interact with ACR.
*   **Azure Container Registry (ACR):** An existing ACR instance.
*   **Azure CLI:** [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).
*   **Azure PowerShell:** [Install Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps).
*   **Bicep CLI:** Handled by the initial setup script.

## Initial Setup (Run Once)

1.  **Clone the repository**.
2.  **Run the setup script:** Open PowerShell, navigate to the repository root, and run:
    ```powershell
    ./deployment/initial_setup.ps1
    ```
    This copies configuration templates and installs Bicep.
3.  **Edit Configuration Files:**
    *   Fill in required values in `config/config.json` (see [`config/README.md`](config/README.md)).
    *   Configure your server settings in `configs/serverconfig.xml` (see [`configs/README.md`](configs/README.md)).
4.  **Get ACR Password:**
    *   Run `az acr credential show --name <your-acr-name> --query "passwords[0].value" -o tsv`.
    *   Copy the password into `config/config.json`.

## Deployment Workflow

1.  **Build/Push Image:**
    ```powershell
    ./deployment/push-to-acr.ps1
    ```
2.  **Deploy Infrastructure & Server:**
    ```powershell
    ./deployment/deploy-bicep.ps1
    ```
3.  **Access Server:** Use the public IP output by the deployment script.

See [`deployment/README.md`](deployment/README.md) for more details on the deployment process.

## Updating the Server

1.  Modify `configs/serverconfig.xml` if needed.
2.  Run `./deployment/push-to-acr.ps1` (potentially update `tag` in `config.json`).
3.  Run `./deployment/deploy-bicep.ps1` again.

## Persistence

Server configuration (`serverconfig.xml`), save games, and logs are stored in `/opt/7dtd-data` on the host VM's disk, mapped to `/data` inside the container.

## Known Issues

*   **Bicep Not Found in PATH:** After `initial_setup.ps1`, restart PowerShell.

## Contributing

Contributions not accepted at this time.

## License

This project is licensed under the MIT License. See the LICENSE file for details.