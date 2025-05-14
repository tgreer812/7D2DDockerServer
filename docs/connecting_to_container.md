# Connecting to the Running Docker Container

Sometimes you might need to execute commands *inside* the running 7D2D Docker container for debugging or administrative tasks.

You will need to be SSH'd into the Azure VM first.

## Command: `docker exec`

The primary command is `docker exec`. It allows you to run a command in a running container.

**Syntax:**

```bash
docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
```

*   `CONTAINER`: The name or ID of the container. In our setup, the container name is `7dtd-server` (defined in `7dtd.service.template`).
*   `COMMAND`: The command you want to run inside the container.
*   `[ARG...]`: Any arguments for the command.

**Common Options:**

*   `-it` (`-i` and `-t` combined): This is crucial for interactive processes, like starting a shell. It allocates a pseudo-TTY and keeps STDIN open.

## Examples

1.  **Get an Interactive Shell (Bash) inside the container:**
    This is the most common use case for exploring the container's filesystem or running commands interactively.
    ```bash
    sudo docker exec -it 7dtd-server /bin/bash
    ```
    *   You will get a new prompt (e.g., `root@<container_id>:/app#`).
    *   You are now inside the container.
    *   You can `cd`, `ls`, `cat`, etc., to explore.
    *   Type `exit` to leave the container shell and return to the VM's shell.

2.  **List files in a specific directory inside the container:**
    ```bash
    sudo docker exec 7dtd-server ls -l /data/Saves
    ```

3.  **Run a specific command non-interactively:**
    ```bash
    sudo docker exec 7dtd-server ps aux
    ```
    (This would show processes running *inside* the container).

## Important Notes

*   **`sudo`:** You need `sudo` on the VM to run Docker commands.
*   **Container Must Be Running:** `docker exec` only works if the container (`7dtd-server`) is actually running. Check with `sudo docker ps` or `sudo systemctl status 7dtd.service` first.
*   **User:** By default, `docker exec` runs the command as the user the container is configured to run as (often `root` unless specified otherwise in the Dockerfile).
