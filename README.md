# 7 Days to Die Docker Server on Azure

This project provides a Dockerized setup for running a 7 Days to Die server in the Azure cloud. It includes all necessary configurations, scripts, and deployment templates to get you started quickly.

## Project Structure

```
├── docker
│   ├── Dockerfile          # Instructions to build the Docker image
│   └── .dockerignore       # Files to ignore when building the image
├── azure
│   ├── azure-pipelines.yml # Azure DevOps pipeline configuration
│   └── deploy.bicep        # Bicep template for Azure resource deployment
├── configs
│   └── serverconfig.xml    # Configuration settings for the server
├── scripts
│   ├── start-server.sh     # Script to start the server
│   ├── backup.sh           # Script to create backups
│   └── restore.sh          # Script to restore from backups
├── .gitignore              # Git ignore file
└── README.md               # Project documentation
```

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd 7D2DDockerServer
   ```

2. **Configure the server**:
   Modify the `configs/serverconfig.xml` file to set your desired game settings.

3. **Backup and Restore**:
   Use the provided scripts in the `scripts` directory to manage backups:
   ```bash
   # To backup
   ./scripts/backup.sh

   # To restore
   ./scripts/restore.sh
   ```

**Note:** Local scripts for starting the server and managing Docker containers are deprecated. Use the Azure deployment workflow instead.

## Azure Deployment

**Prerequisites:**

*   **Azure Account:** You must have an active Azure account and subscription. This guide assumes you have the necessary permissions to create resources like Container Registries, Container Instances, and Storage Accounts.
*   **Azure Container Registry (ACR):** You need to have already created an Azure Container Registry instance. The deployment scripts require the name and credentials of your existing ACR. https://learn.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal?tabs=azure-cli
*   **Azure CLI:** Ensure you have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured.
*   **Azure PowerShell:** The deployment scripts require Azure PowerShell modules. Install them by running the following command in an **Administrator** PowerShell terminal:
    ```powershell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```
    *(You might need to accept prompts to trust the repository during installation.)*
*   **Bicep CLI:** The `deploy-bicep.ps1` script uses Bicep. The initial setup script will handle installing this.

**Initial Setup (Run Once):**

1.  **Run the setup script:** Open PowerShell, navigate to the repository root, and run:
    ```powershell
    ./deployment/initial_setup.ps1
    ```
    This script will:
    *   Copy `config/config.json.example` to `config/config.json`.
    *   Copy `configs/serverconfig.default.xml` to `configs/serverconfig.xml`.
    *   Attempt to install the Bicep CLI using `./deployment/install-bicep.ps1`.

2.  **Edit Configuration Files:**
    *   **Edit `config/config.json`:** Fill in all required values:
        - `acrName`: Your Azure Container Registry name (e.g., `myregistry`). This is also used as the username for pulling the image.
        - `acrLoginServer`: Your ACR login server (e.g., `myregistry.azurecr.io`)
        - `imageName`: The name of your Docker image (e.g., `7dtd-server`)
        - `tag`: The image tag (e.g., `latest`)
        - `containerGroupName`: Name for the Azure Container Instance group
        - `fileShareName`: Name for the Azure File Share
        - `serverName`: Your 7 Days to Die server name (This should match the `ServerName` property in `serverconfig.xml`)
        - `serverPassword`: Your 7 Days to Die server password (This should match the `ServerPassword` property in `serverconfig.xml`)
        - `resourceGroup`: The Azure resource group to deploy into
        - `location`: The Azure region where the resource group and resources should be created (e.g., `eastus`, `westus2`).
        - `acrPassword`: Your ACR password (see step 3).
    *   **Edit `configs/serverconfig.xml`:** Set your desired server name, password, game settings, etc. This is the file that will be baked into your Docker image.

3.  **Get your ACR password**
    - Run the following Azure CLI command:
      ```powershell
      az acr credential show --name <your-acr-name> --query "passwords[0].value" -o tsv
      ```
    - Copy the output and paste it into the `acrPassword` field in your `config.json`.

**Deployment Steps (After Initial Setup):**

1.  **Build and Push the Docker Image in Azure (No Local Docker Needed!)**
    - Use the provided script to build and push your image using Azure Container Registry Tasks:
      ```powershell
      ./deployment/push-to-acr.ps1
      ```
    - This will queue a cloud build using your Dockerfile and push the image to your ACR.

2.  **Deploy to Azure**
    - Run the deployment script:
      ```powershell
      ./deployment/deploy-bicep.ps1
      ```
    - The script provisions all required Azure resources and deploys your container using the values from `config/config.json`.
    - The `start-server.sh` script inside the container will automatically copy the `configs/serverconfig.xml` from your repository (which was baked into the image) to the persistent `/data` volume (`serverconfig.xml` on the Azure File Share) when the container starts.
    - **Disclaimer:** The very first time the container starts after deployment, it needs to check for server updates using SteamCMD. This can take a few minutes depending on Azure's network speed and the performance of the underlying file share. You can monitor the progress by `exec`-ing into the container and tailing the `/data/steamcmd_update.log` file. Subsequent starts should be much faster as it only downloads changes.

**Workflow Summary:**

1.  Run `./deployment/initial_setup.ps1` **once**. 
2.  Edit `config/config.json` and `configs/serverconfig.xml` with your settings.
3.  Get ACR password and add it to `config.json`.
4.  Run `./deployment/push-to-acr.ps1` to build/push the image.
5.  Run `./deployment/deploy-bicep.ps1` to deploy to Azure.

**Note:** Never commit your real `config.json` or `serverconfig.xml` to version control. Use the `.example` / `.default` files as templates.

## Known Issues

*   **Bicep Not Found in PATH:** Occasionally, after running `./deployment/install-bicep.ps1`, the `bicep` command might not be immediately available in your terminal's PATH, causing `./deployment/deploy-bicep.ps1` to fail. This can sometimes happen if the terminal session doesn't pick up the updated PATH environment variable correctly.
    *   **Solution:** Close and reopen your PowerShell terminal. If the issue persists, simply run `./deployment/install-bicep.ps1` again in the new terminal session. This usually resolves the problem.

## Contributing

Contributions not accepted at this time.

## License

This project is licensed under the MIT License. See the LICENSE file for details.