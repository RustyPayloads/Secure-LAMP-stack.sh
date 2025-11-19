#!/bin/bash

# --- Automated System Hardening Script for Ubuntu 22.04+ and Apache ---
# This script performs basic OS, Apache, and SSL hardening, and runs a Lynis audit.

LOG_FILE="/var/log/hardening_script.log"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="/root/hardening_backups/$DATE"
APACHE_CONF_DIR="/etc/apache2/conf-available"
APACHE_SECURITY_FILE="apache_security.conf"
SSL_SECURITY_FILE="ssl_security.conf"

# Function for logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

log "Starting system and Apache hardening script..."

# ... (Sections 1, 2, 3 remain the same: Updates, User/SSH, UFW/Sysctl) ...

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  log "ERROR: Please run as root (sudo)."
  exit 1
fi

## 1. System Updates and Cleanup ##
log "Starting system updates and cleanup..."
apt update -y >> $LOG_FILE 2>&1
apt upgrade -y >> $LOG_FILE 2>&1
apt autoremove -y >> $LOG_FILE 2>&1
log "System updates and cleanup complete."

## 2. User and Access Control ##
log "Applying User and Access Control hardening..."
# 2.1 SSH Hardening
cp /etc/ssh/sshd_config $BACKUP_DIR/sshd_config_pre_hardening
log "Backing up sshd_config."
# Disable Root SSH Login and Password Authentication
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication no/PasswordAuthentication no/' /etc/ssh/ssd_config'
# 2.2 Secure Permissions
echo "umask 027" >> /etc/profile
echo "umask 027" >> /etc/bash.bashrc
# 2.3 Password Policy 
apt install -y libpam-pwquality >> $LOG_FILE 2>&1
chage -M 90 -m 7 -W 7 $(awk -F: '($3 >= 1000 && $1 != "nobody"){print $1}' /etc/passwd)
log "User and Access Control hardening complete."

## 3. Network Hardening (UFW and Sysctl) ##
log "Applying Network Hardening (UFW and Sysctl)..."
# 3.1 UFW Firewall Setup
apt install -y ufw >> $LOG_FILE 2>&1
log "Configuring UFW firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable
log "UFW configured and enabled." 
# 3.2 Kernel Parameter Hardening via sysctl
SYSCTL_CONF="/etc/sysctl.d/99-security-hardening.conf"
cp /etc/sysctl.conf $BACKUP_DIR/sysctl.conf_pre_hardening
cat << EOF > $SYSCTL_CONF
# ... (Sysctl hardening rules from previous response) ...
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.ip_forward = 0
kernel.randomize_va_space = 2
EOF
sysctl -p $SYSCTL_CONF >> $LOG_FILE 2>&1
log "Kernel parameters hardened."

## 4. Apache Hardening and SSL Configuration ##
log "Starting Apache Web Server and SSL Hardening..."

if command -v apache2 &> /dev/null; then
    # 4.1 Install Fail2Ban
    apt install -y fail2ban >> $LOG_FILE 2>&1
    systemctl enable fail2ban && systemctl start fail2ban
    log "Fail2Ban installed and enabled."

    # 4.2 Module Management
    a2enmod headers
    a2enmod rewrite
    a2enmod ssl
    a2dismod status
    log "Required Apache modules enabled."

    # 4.3 Apply Custom Security Configurations
    cp ./configs/$APACHE_SECURITY_FILE $APACHE_CONF_DIR/$APACHE_SECURITY_FILE
    a2enconf $APACHE_SECURITY_FILE
    log "Enabled custom Apache security configuration."

    # 4.4 Apply Custom SSL Configuration (Crucial for strong TLS)
    cp ./configs/$SSL_SECURITY_FILE $APACHE_CONF_DIR/$SSL_SECURITY_FILE
    a2enconf $SSL_SECURITY_FILE
    log "Enabled strong SSL/TLS configuration." 

    # 4.5 Restart Apache
    systemctl restart apache2
    log "Apache service restarted to apply new configurations."
else
    log "Apache (apache2) is not installed. Skipping Apache hardening."
fi

## 5. Security Auditing (Lynis) ##
log "Starting Lynis Security Audit..."
# Install Lynis
apt install -y lynis >> $LOG_FILE 2>&1

# Run the audit and save the report
lynis audit system --quick >> $LOG_FILE
log "Lynis audit complete. Review the full report in: $LOG_FILE"

## 6. Final Steps and Conclusion ##
log "System Hardening complete."
systemctl restart sshd >> $LOG_FILE 2>&1
log "SSHD service restarted to apply new configurations."
log "Review log file: $LOG_FILE"
log "Configuration backups are in: $BACKUP_DIR"
echo "--- Script Finished ---"
