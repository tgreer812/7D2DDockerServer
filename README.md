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

*   **Azure CLI:** Ensure you have the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured.
*   **Azure PowerShell:** The deployment scripts require Azure PowerShell modules. Install them by running the following command in an **Administrator** PowerShell terminal:
    ```powershell
    Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    ```
    *(You might need to accept prompts to trust the repository during installation.)*
*   **Bicep CLI:** The `deploy-bicep.ps1` script uses Bicep to deploy Azure resources. Install it by running the provided script (you may need to adjust PowerShell execution policy):
    ```powershell
    ./deployment/install-bicep.ps1
    ```
    *(You may need to close and reopen your terminal after running the script for the PATH changes to take effect.)*

To deploy the server on Azure, follow these steps:

1. **Configure Deployment Settings**
   - Copy `config/config.json.example` to `config/config.json`:
     ```bash
     cp config/config.json.example config/config.json
     ```
   - Edit `config/config.json` and fill in all required values:
     - `acrName`: Your Azure Container Registry name (e.g., `myregistry`). This is also used as the username for pulling the image.
     - `acrLoginServer`: Your ACR login server (e.g., `myregistry.azurecr.io`)
     - `imageName`: The name of your Docker image (e.g., `7dtd-server`)
     - `tag`: The image tag (e.g., `latest`)
     - `containerGroupName`: Name for the Azure Container Instance group
     - `fileShareName`: Name for the Azure File Share
     - `serverName`: Your 7 Days to Die server name
     - `serverPassword`: Your 7 Days to Die server password
     - `resourceGroup`: The Azure resource group to deploy into
     - `acrPassword`: Your ACR password (see below)

2. **Get your ACR password**
   - Run the following Azure CLI command:
     ```powershell
     az acr credential show --name <your-acr-name> --query "passwords[0].value" -o tsv
     ```
   - Copy the output and paste it into the `acrPassword` field in your `config.json`.

3. **Build and Push the Docker Image in Azure (No Local Docker Needed!)**
   - Use the provided script to build and push your image using Azure Container Registry Tasks:
     ```powershell
     ./deployment/push-to-acr.ps1
     ```
   - This will queue a cloud build using your Dockerfile and push the image to your ACR.

4. **Deploy to Azure**
   - Run the deployment script. You have an option for the initial deployment:
     - **First Time Deployment (Generate Default Config):** Run the script with `-CopyConfigOnStart:$false`. This will prevent the script from copying your local `configs/serverconfig.xml` into the running container's persistent storage. The server will start and generate its own default `serverconfig.xml` in the `/data` volume (viewable via the Azure File Share).
       ```powershell
       ./deployment/deploy-bicep.ps1 -CopyConfigOnStart:$false
       ```
     - **Subsequent Deployments (Use Your Custom Config):** After you've retrieved the generated default config (if needed), updated your local `configs/serverconfig.xml`, and rebuilt the image using `push-to-acr.ps1`, run the deployment script *without* the `-CopyConfigOnStart:$false` flag (or explicitly with `$true`). This will copy your custom config from the image into the persistent storage, ensuring your settings are used.
       ```powershell
       ./deployment/deploy-bicep.ps1
       # OR
       ./deployment/deploy-bicep.ps1 -CopyConfigOnStart:$true
       ```
   - The script provisions all required Azure resources and deploys your container using the values from `config/config.json` and the chosen config copy behavior.

**Workflow for Initial Setup & Custom Config:**

1.  Run `./deployment/push-to-acr.ps1` to build the initial image (the included `configs/serverconfig.xml` doesn't matter much yet).
2.  Run `./deployment/deploy-bicep.ps1 -CopyConfigOnStart:$false`.
3.  Wait for the container instance to start. Access the Azure File Share created during deployment (you can find it in the resource group via the Azure Portal).
4.  Navigate to the root of the file share (which corresponds to `/data` inside the container). You should find the `serverconfig.xml` generated by the server.
5.  Copy this generated file to your local machine, placing it in `configs/serverconfig.xml` in your repository.
6.  Modify this local `configs/serverconfig.xml` with your desired server name, password, game settings, etc.
7.  Commit your changes.
8.  Run `./deployment/push-to-acr.ps1` again to build a new image containing your *customized* config file.
9.  Run `./deployment/deploy-bicep.ps1` (this time *without* `-CopyConfigOnStart:$false`). The container will now start and the `start-server.sh` script will copy your custom config from the image into `/data/serverconfig.xml`, ensuring your settings are applied.

**Note:** Never commit your real `config.json` to version control. Use `config.json.example` as a template for sharing configuration requirements.

## Deprecated: Local Docker Build/Push

If you do have Docker installed locally, you may use the `push-to-acr.sh` script, but this is no longer required or recommended for most users.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.