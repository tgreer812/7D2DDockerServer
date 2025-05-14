# Accessing VM Files Locally using SSHFS

SSHFS (SSH File System) allows you to mount a directory from a remote server (like your Azure VM) onto your local machine using the secure SSH protocol. This makes accessing files in `/opt/7dtd-data` feel like accessing a local drive, without the security risks of exposing Samba/SMB directly to the internet.

## Prerequisites

1.  **SSH Access:** You must be able to SSH into your Azure VM.
2.  **SSHFS Client (Windows):** You need to install an SSHFS client on your Windows machine.
    *   **Recommended:** `sshfs-win`
        *   Download the latest `.msi` installer from the [sshfs-win GitHub Releases page](https://github.com/winfsp/sshfs-win/releases).
        *   You might also need to install the companion `WinFsp` (Windows File System Proxy) if the installer doesn't include it. Download it from the [WinFsp Releases page](https://github.com/winfsp/winfsp/releases).
        *   Install both, following their setup instructions.

## Mounting the Remote Directory

1.  **Open File Explorer** on your Windows machine.
2.  Right-click on **"This PC"** or **"Network"**.
3.  Select **"Map network drive..."**.
4.  **Choose a Drive Letter:** Select an available drive letter (e.g., `Z:`).
5.  **Enter the Folder Path:** Use the following format, replacing the placeholders:
    ```
    \\sshfs\<adminUsername>@<public-ip>\<remote-path>
    ```
    *   `<adminUsername>`: Your VM admin username (from `config.json`).
    *   `<public-ip>`: The public IP address of your Azure VM.
    *   `<remote-path>`: The absolute path on the VM you want to mount. For the 7D2D data, use `/opt/7dtd-data`.

    **Example:**
    ```
    \\sshfs\azureuser@20.10.20.30\opt\7dtd-data
    ```

6.  **Credentials:**
    *   Check **"Connect using different credentials"** if your Windows username differs from the VM username.
    *   Click **Finish**.
7.  **Enter Password:** You will likely be prompted for the password for the VM user (`<adminUsername>`). Enter the admin password from your `config.json`.

## Accessing Files

If successful, the chosen drive letter (e.g., `Z:`) will now appear under "This PC" in File Explorer, showing the contents of `/opt/7dtd-data` from your Azure VM. You can browse, open, and modify files (respecting Linux permissions) as if they were local.

## Unmounting

To disconnect the drive:

1.  Open File Explorer.
2.  Right-click on the mapped drive letter under "This PC".
3.  Select **"Disconnect"**.

## Important Notes

*   **Performance:** Access speed depends on your network connection to Azure. It won't be as fast as a local disk.
*   **Permissions:** File operations are subject to the Linux permissions of the `<adminUsername>` user on the VM for the `/opt/7dtd-data` directory and its contents. You might need `sudo` on the VM via SSH to change permissions if you encounter access issues.
*   **Server Status:** It's generally recommended to **stop the 7D2D server** (`sudo systemctl stop 7dtd.service`) before making significant changes to save files via SSHFS to avoid corruption.
