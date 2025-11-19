# Automated Ubuntu and Apache Hardening Script

This repository contains an automated Bash script and configuration files to perform basic security hardening on an **Ubuntu 22.04+** server running the **Apache2** web server.

## ⚠️ WARNING

**USE AT YOUR OWN RISK.** Always test hardening scripts in a staging or development environment before applying them to a production system. Incorrect configurations (especially SSH and Firewall settings) can lead to service outages or locking yourself out of the server.

## 🚀 Usage

Follow these steps to run the hardening script:

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/RustyPayloads/Automated-Hardening-Script.git](https://github.com/RustyPayloadse/Automated-Hardening-Script.git)
    cd Automated-Hardening-Script
    ```

2.  **Make the Script Executable:**
    ```bash
    chmod +x scripts/harden_ubuntu_apache.sh
    ```

3.  **Run the Script (as root/sudo):**
    You must execute the script from the **root directory** of the cloned repository (`Automated-Hardening-Script/`) so it can successfully find and copy the necessary configuration files from the `configs/` folder.
    ```bash
    sudo ./scripts/harden_ubuntu_apache.sh
    ```
    * The script will log all actions to `/var/log/hardening_script.log`.
    * Original configuration files will be backed up to `/root/hardening_backups/`.

---

## Key Hardening Steps

| Component | Hardening Action |
| :--- | :--- |
| **System** | Updates/Upgrades, Secure `umask` |
| **SSH** | Disable **Root Login** and **Password Authentication** |
| **Firewall** | Enables **UFW** and allows SSH, HTTP, and HTTPS ports |
| **Kernel** | Disables source routing, enables TCP SYN cookies |
| **Protection** | Installs and enables **Fail2Ban** |
| **Apache** | Hides server signature, enables XSS/Clickjacking headers, disables TRACE |
| **SSL/TLS** | Disables weak protocols (SSLv2/3, TLSv1.0/1.1), enforces strong ciphers |
| **Audit** | Installs and runs **Lynis** to generate a security health report |
