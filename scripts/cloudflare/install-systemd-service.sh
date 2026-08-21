#!/usr/bin/env bash
#
# Registers a systemd service tied to docker.service so the whole script re-runs on every Docker
# start or droplet reboot.
#
# Requires SCRIPT_DIR, SCRIPT_PATH, and SYSTEMD_SERVICE_PATH to already be
# set by the caller.

install_systemd_service() {
    local install_dir
    install_dir="$(dirname "$SCRIPT_PATH")"

    echo "Installing firewall configuration files to $install_dir..."
    sudo install -m 0755 "$SCRIPT_DIR/update-cf-firewall.sh" "$SCRIPT_PATH"
    sudo install -m 0644 "$SCRIPT_DIR/configure-ipv4.sh" "$install_dir/configure-ipv4.sh"
    sudo install -m 0644 "$SCRIPT_DIR/configure-ipv6.sh" "$install_dir/configure-ipv6.sh"
    sudo install -m 0644 "$SCRIPT_DIR/configure-ufw.sh" "$install_dir/configure-ufw.sh"
    sudo install -m 0644 "$SCRIPT_DIR/install-systemd-service.sh" "$install_dir/install-systemd-service.sh"

    echo "Creating systemd service..."
    sudo tee "$SYSTEMD_SERVICE_PATH" >/dev/null <<EOF
[Unit]
Description=Restrict Docker HTTP/HTTPS traffic to Cloudflare
Requires=docker.service
After=docker.service
PartOf=docker.service

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable cloudflare-docker-firewall.service
}