#!/usr/bin/env bash
#
# Restricts Docker-published ports 80/443 to Cloudflare's current IP ranges.

set -euo pipefail

CHAIN="CLOUDFLARE-ONLY"
SCRIPT_PATH="/usr/local/sbin/configure-cloudflare-firewall"
SYSTEMD_SERVICE_PATH="/etc/systemd/system/cloudflare-docker-firewall.service"

SELF_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SELF_PATH")" && pwd)"

source "$SCRIPT_DIR/configure-ipv4.sh"
source "$SCRIPT_DIR/configure-ipv6.sh"
source "$SCRIPT_DIR/configure-ufw.sh"
source "$SCRIPT_DIR/install-systemd-service.sh"

echo "Fetching current Cloudflare IP ranges..."
CF_IPV4=$(curl -fsSL https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -fsSL https://www.cloudflare.com/ips-v6)

if [[ -z "$CF_IPV4" || -z "$CF_IPV6" ]]; then
    echo "Failed to retrieve Cloudflare IP ranges."
    exit 1
fi

echo "Configuring Docker firewall..."
configure_ipv4
configure_ipv6

configure_ufw

install_systemd_service "$SELF_PATH"

# --- Print status ---

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