#!/usr/bin/env bash

# Restricts Docker-published ports 80/443 to Cloudflare's current IP ranges.

set -euo pipefail

CHAIN="CLOUDFLARE-ONLY"
SCRIPT_PATH="/usr/local/sbin/configure-cloudflare-firewall"

echo "Fetching current Cloudflare IP ranges..."

CF_IPV4=$(curl -fsSL https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -fsSL https://www.cloudflare.com/ips-v6)

if [[ -z "$CF_IPV4" || -z "$CF_IPV6" ]]; then
    echo "Failed to retrieve Cloudflare IP ranges."
    exit 1
fi

configure_ipv4() {
    echo "Configuring IPv4 rules..."

    # Create our dedicated chain if it doesn't exist.
    sudo iptables -N "$CHAIN" 2>/dev/null || true

    # Only flush our own chain.
    sudo iptables -F "$CHAIN"

    # Remove any existing jump to our chain.
    while sudo iptables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo iptables -D DOCKER-USER -j "$CHAIN"
    done

    # Put our chain first in DOCKER-USER.
    sudo iptables -I DOCKER-USER 1 -j "$CHAIN"

    # Allow established/related traffic.
    sudo iptables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # Allow Cloudflare IPv4 to the original port 80.
    for ip in $CF_IPV4; do
        sudo iptables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    # Allow Cloudflare IPv4 to the original port 443.
    for ip in $CF_IPV4; do
        sudo iptables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 443 \
            -j ACCEPT
    done

    # Drop everything else attempting to reach the published port 80.
    sudo iptables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 80 \
        -j DROP

    # Drop everything else attempting to reach the published port 443.
    sudo iptables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 443 \
        -j DROP

    sudo iptables -A "$CHAIN" -j RETURN
}

configure_ipv6() {
    echo "Configuring IPv6 rules..."

    sudo ip6tables -N "$CHAIN" 2>/dev/null || true

    sudo ip6tables -F "$CHAIN"

    while sudo ip6tables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo ip6tables -D DOCKER-USER -j "$CHAIN"
    done

    sudo ip6tables -I DOCKER-USER 1 -j "$CHAIN"

    # Allow established/related traffic.
    sudo ip6tables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # Allow Cloudflare IPv6 to port 80.
    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    # Allow Cloudflare IPv6 to port 443.
    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 443 \
            -j ACCEPT
    done

    # Drop everything else to port 80.
    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 80 \
        -j DROP

    # Drop everything else to port 443.
    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 443 \
        -j DROP

    sudo ip6tables -A "$CHAIN" -j RETURN
}

echo "Configuring Docker firewall..."

configure_ipv4
configure_ipv6

echo "Configuring UFW..."

sudo ufw allow 22/tcp >/dev/null
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null
sudo ufw --force enable >/dev/null

echo "Installing firewall configuration script..."

sudo install -m 0755 "$0" "$SCRIPT_PATH"

echo "Creating systemd service..."

sudo tee /etc/systemd/system/cloudflare-docker-firewall.service >/dev/null <<EOF
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

echo
echo "IPv4 DOCKER-USER:"
sudo iptables -L DOCKER-USER -n --line-numbers

echo
echo "IPv4 $CHAIN:"
sudo iptables -L "$CHAIN" -n --line-numbers

echo
echo "IPv6 DOCKER-USER:"
sudo ip6tables -L DOCKER-USER -n --line-numbers

echo
echo "IPv6 $CHAIN:"
sudo ip6tables -L "$CHAIN" -n --line-numbers

echo
echo "Firewall configuration complete."