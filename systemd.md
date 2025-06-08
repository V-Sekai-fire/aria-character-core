# Enabling Systemd in WSL

To enable systemd in your WSL distribution, follow these steps:

1.  **Ensure you are running the right version of WSL**: Systemd support is available in WSL version 0.67.6 and higher. You can check your WSL version by running `wsl --version` in PowerShell or Command Prompt. If the command fails or shows an older version, you need to update WSL from the Microsoft Store or download the latest release from the WSL GitHub repository.

2.  **Set the systemd flag in your WSL distro settings**:

    - Open your WSL distribution (e.g., Ubuntu).
    - Edit the `/etc/wsl.conf` file. You'll need superuser privileges, so use a command like `sudo nano /etc/wsl.conf` or `sudo vi /etc/wsl.conf`.
    - Add the following lines to the file:
      ```ini
      [boot]
      systemd=true
      ```
    - Save the file and exit the editor (e.g., `CTRL+O` then `CTRL+X` in nano).

3.  **Restart your WSL instance**:

    - Close your WSL distro window.
    - Open PowerShell or Command Prompt and run the command `wsl.exe --shutdown`.
    - Relaunch your WSL distribution.

4.  **Verify systemd is running**: After your WSL distribution restarts, you can check if systemd is running by executing a command like `systemctl list-unit-files --type=service`. This command should list the available services and their status.

These steps are based on the information provided by Microsoft in their blog post: [Systemd support is now available in WSL!](https://devblogs.microsoft.com/commandline/systemd-support-is-now-available-in-wsl/)
