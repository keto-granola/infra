#!/usr/bin/env bash

# Configures Docker's DOCKER-USER chain so that Docker-published ports
# 80/443 are only reachable from Cloudflare's IP ranges.
#
# This script is safe to run repeatedly.

set -euo pipefail

CHAIN="CLOUDFLARE-ONLY"

echo "Fetching current Cloudflare IP ranges..."

CF_IPV4=$(curl -fsSL https://www.cloudflare.com/ips-v4)
CF_IPV6=$(curl -fsSL https://www.cloudflare.com/ips-v6)

if [[ -z "$CF_IPV4" || -z "$CF_IPV6" ]]; then
    echo "Failed to retrieve Cloudflare IP ranges."
    exit 1
fi


configure_ipv4() {
    echo "Configuring IPv4 Docker firewall..."

    # Create our dedicated chain if it doesn't exist.
    sudo iptables -N "$CHAIN" 2>/dev/null || true

    # Only flush the chain owned by this script.
    sudo iptables -F "$CHAIN"

    # Remove any existing jump to our chain.
    while sudo iptables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo iptables -D DOCKER-USER -j "$CHAIN"
    done

    # Check our rules before any other DOCKER-USER rules.
    sudo iptables -I DOCKER-USER 1 -j "$CHAIN"

    # Allow return traffic for established connections.
    sudo iptables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # Allow Cloudflare IPv4 → original host port 80.
    for ip in $CF_IPV4; do
        sudo iptables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    # Allow Cloudflare IPv4 → original host port 443.
    for ip in $CF_IPV4; do
        sudo iptables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 443 \
            -j ACCEPT
    done

    # Drop everyone else → original host port 80.
    sudo iptables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 80 \
        -j DROP

    # Drop everyone else → original host port 443.
    sudo iptables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 443 \
        -j DROP

    # Everything else continues through DOCKER-USER.
    sudo iptables -A "$CHAIN" -j RETURN
}


configure_ipv6() {
    echo "Configuring IPv6 Docker firewall..."

    # Create our dedicated chain if it doesn't exist.
    sudo ip6tables -N "$CHAIN" 2>/dev/null || true

    # Only flush the chain owned by this script.
    sudo ip6tables -F "$CHAIN"

    # Remove any existing jump to our chain.
    while sudo ip6tables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo ip6tables -D DOCKER-USER -j "$CHAIN"
    done

    # Check our rules before any other DOCKER-USER rules.
    sudo ip6tables -I DOCKER-USER 1 -j "$CHAIN"

    # Allow return traffic for established connections.
    sudo ip6tables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # Allow Cloudflare IPv6 → original host port 80.
    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    # Allow Cloudflare IPv6 → original host port 443.
    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 443 \
            -j ACCEPT
    done

    # Drop everyone else → original host port 80.
    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 80 \
        -j DROP

    # Drop everyone else → original host port 443.
    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 443 \
        -j DROP

    # Everything else continues through DOCKER-USER.
    sudo ip6tables -A "$CHAIN" -j RETURN
}


configure_ipv4
configure_ipv6


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
echo "Cloudflare Docker firewall configuration complete."