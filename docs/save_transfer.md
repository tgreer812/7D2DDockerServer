# Transferring Save Files

This guide explains how to transfer 7 Days to Die save game files between your local machine and the Azure VM.

**Location on VM:** Save files are stored within the persistent volume mapped to the container, specifically under `/opt/7dtd-data/Saves/` on the host VM.

**Location Locally (Windows Example):** Typically found under `C:\Users\<YourUsername>\AppData\Roaming\7DaysToDie\Saves\`.

**Tool:** We will use `scp` (Secure Copy), which works over SSH.

## Steps

1.  **SSH into Azure VM:** Connect to your VM using the credentials from `config.json` and the public IP address:
    ```powershell
    ssh <adminUsername>@<public-ip>
    ```

2.  **Stop the 7D2D Service (on VM):** Ensure the server is not running while modifying files.
    ```bash
    sudo systemctl stop 7dtd.service
    ```

3.  **Transfer Files (using `scp` from Local Machine):**
    *   Open a **new local PowerShell or Command Prompt** (keep the SSH session open).
    *   **To Upload (Local -> VM):**
        *   *(Optional but Recommended)* Remove the existing world save on the VM first (run in SSH session):
            ```bash
            # Replace 'YourWorldName' with the actual save directory name
            sudo rm -rf /opt/7dtd-data/Saves/YourWorldName
            ```
        *   Run `scp` on your **local machine**:
            ```powershell
            # Adjust local path and VM IP/world name as needed
            scp -r "C:\Users\<YourUsername>\AppData\Roaming\7DaysToDie\Saves\YourWorldName" <adminUsername>@<public-ip>:/opt/7dtd-data/Saves/YourWorldName
            ```
            *(Enter the VM admin password when prompted)*
    *   **To Download (VM -> Local):**
        *   Run `scp` on your **local machine**:
            ```powershell
            # Adjust local path and VM IP/world name as needed
            scp -r <adminUsername>@<public-ip>:/opt/7dtd-data/Saves/YourWorldName "C:\Path\To\Save\Downloads\YourWorldName"
            ```
            *(Enter the VM admin password when prompted)*

4.  **Verify Files (Optional - on VM):** Check if the files were transferred correctly.
    ```bash
    ls -l /opt/7dtd-data/Saves/
    ls -l /opt/7dtd-data/Saves/YourWorldName
    ```

5.  **Set Permissions (Important! - on VM):** Ensure the files copied have the correct ownership for the container process (often needed if copied as root/admin). The Docker container might run as a non-root user.
    *   *Determine the user/group the container runs as if necessary (e.g., using `docker exec 7dtd-server id`). Often it's a standard UID/GID like 1000:1000 or the user created in the Dockerfile.*
    *   *For simplicity, if unsure, making them world-readable/writable might work, but setting specific ownership is better if known. Assuming UID/GID 1000 for example:*
        ```bash
        # Replace YourWorldName. Adjust UID/GID if needed.
        sudo chown -R 1000:1000 /opt/7dtd-data/Saves/YourWorldName
        ```
        *If the container runs as root, this step might not be strictly necessary, but it's good practice.* 

6.  **Start the 7D2D Service (on VM):**
    ```bash
    sudo systemctl start 7dtd.service
    ```

7.  **Check Status (on VM):** Verify the service started correctly.
    ```bash
    sudo systemctl status 7dtd.service
    ```
