#!/usr/bin/env bash

# Installs and configures the Cloudflare/Docker firewall.
#
# This script:
#   1. Configures UFW for host-level firewall protection.
#   2. Installs configure-firewall.sh to /usr/local/sbin.
#   3. Creates a systemd service tied to Docker.
#   4. Applies the Cloudflare firewall immediately.
#   5. Enables the systemd service for future Docker starts/restarts.

set -euo pipefail

INSTALL_DIR="/usr/local/sbin"
CONFIGURE_SCRIPT="$INSTALL_DIR/configure-firewall"
SERVICE_DIR="/etc/systemd/system"

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"


echo "Configuring UFW..."

sudo ufw allow 22/tcp >/dev/null
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw --force enable >/dev/null


echo "Installing firewall configuration script..."

sudo install -m 0755 \
    "$SCRIPT_DIR/configure-firewall.sh" \
    "$CONFIGURE_SCRIPT"


echo "Creating systemd service..."

sudo tee "$SERVICE_DIR/cloudflare-docker-firewall.service" >/dev/null <<EOF
[Unit]
Description=Restrict Docker HTTP/HTTPS traffic to Cloudflare
Requires=docker.service
After=docker.service
PartOf=docker.service

[Service]
Type=oneshot
ExecStart=$CONFIGURE_SCRIPT
RemainAfterExit=yes

[Install]
WantedBy=docker.service
EOF

sudo tee "${SERVICE_DIR}/cloudflare-docker-firewall-refresh.service" >/dev/null <<EOF
[Unit]
Description=Refresh Cloudflare Docker firewall rules
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/configure-firewall
EOF

sudo tee "${SERVICE_DIR}/cloudflare-docker-firewall-refresh.timer" >/dev/null <<EOF
[Unit]
Description=Daily refresh of Cloudflare Docker firewall rules

[Timer]
OnBootSec=10min
OnUnitActiveSec=24h
Persistent=true

[Install]
WantedBy=timers.target
EOF


echo "Reloading systemd..."

sudo systemctl daemon-reload


echo "Applying firewall configuration now..."

sudo "$CONFIGURE_SCRIPT"


echo "Enabling firewall service..."

sudo systemctl enable cloudflare-docker-firewall.service


echo
echo "Firewall installation complete."

echo
echo "Service:"
sudo systemctl --no-pager status cloudflare-docker-firewall.service

echo
echo "Enabled:"
sudo systemctl is-enabled cloudflare-docker-firewall.service