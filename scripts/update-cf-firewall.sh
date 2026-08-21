#!/usr/bin/env bash

# Restricts inbound 80/443 to Cloudflare's current IP ranges.
#
# NOTE: ufw alone is NOT sufficient here. Docker manipulates iptables directly
# for published ports (-p 80:80 / -p 443:443), inserting rules that bypass
# ufw's own chain.
set -euo pipefail

echo "Fetching current Cloudflare IP ranges..."
CF_IPV4=$(curl -s https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -s https://www.cloudflare.com/ips-v6)

echo "Flushing existing DOCKER-USER rules..."
sudo iptables -F DOCKER-USER
sudo ip6tables -F DOCKER-USER 2>/dev/null || true

echo "Allowing established/related connections..."
sudo iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Allowing Cloudflare IPv4 ranges on 80/443..."
for ip in $CF_IPV4; do
  sudo iptables -I DOCKER-USER -s "$ip" -p tcp -m multiport --dports 80,443 -j ACCEPT
done

echo "Allowing Cloudflare IPv6 ranges on 80/443..."
for ip in $CF_IPV6; do
  sudo ip6tables -I DOCKER-USER -s "$ip" -p tcp -m multiport --dports 80,443 -j ACCEPT
done

echo "Dropping all other traffic to 80/443..."
sudo iptables -A DOCKER-USER -p tcp -m multiport --dports 80,443 -j DROP
sudo ip6tables -A DOCKER-USER -p tcp -m multiport --dports 80,443 -j DROP -m comment --comment "cf-only" 2>/dev/null || \
  sudo ip6tables -A DOCKER-USER -p tcp -m multiport --dports 80,443 -j DROP

echo "Ensuring SSH stays allowed via ufw..."
sudo ufw allow 22/tcp >/dev/null

echo "Setting ufw default policy (deny incoming, allow outgoing)..."
sudo ufw default deny incoming >/dev/null
sudo ufw default allow outgoing >/dev/null

echo "Enabling ufw (non-interactive)..."
sudo ufw --force enable >/dev/null

echo "Persisting rules across reboots..."
if ! dpkg -s iptables-persistent >/dev/null 2>&1; then
  echo "Installing iptables-persistent..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
fi
sudo netfilter-persistent save

echo ""
echo "Done. Current DOCKER-USER rules:"
sudo iptables -L DOCKER-USER -n --line-numbers