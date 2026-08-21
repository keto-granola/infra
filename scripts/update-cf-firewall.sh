#!/usr/bin/env bash
set -euo pipefail

echo "Fetching current Cloudflare IP ranges..."
CF_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

echo "Removing existing broad rules for 80/443 (if present)..."
sudo ufw delete allow 80/tcp 2>/dev/null || true
sudo ufw delete allow 443/tcp 2>/dev/null || true

echo "Allowing Cloudflare IPv4 ranges..."
for ip in $CF_IPV4; do
  sudo ufw allow from "$ip" to any port 80,443 proto tcp
done

echo "Allowing Cloudflare IPv6 ranges..."
for ip in $CF_IPV6; do
  sudo ufw allow from "$ip" to any port 80,443 proto tcp
done

sudo ufw reload
sudo ufw status numbered