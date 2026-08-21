#!/usr/bin/env bash

# Builds the CLOUDFLARE-ONLY iptables (IPv4) chain and wires it into
# DOCKER-USER. Requires CF_IPV4 and CHAIN to already be set by the caller.

configure_ipv4() {
    echo "Configuring IPv4 rules..."

    # Create our dedicated chain if it doesn't exist.
    sudo iptables -N "$CHAIN" 2>/dev/null || true

    # Only flush our own chain — never touch the rest of DOCKER-USER.
    sudo iptables -F "$CHAIN"

    # Remove any existing jump to our chain, so re-runs don't duplicate it.
    while sudo iptables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo iptables -D DOCKER-USER -j "$CHAIN"
    done

    # Put our chain first in DOCKER-USER, so it's consulted before
    # anything else Docker manages.
    sudo iptables -I DOCKER-USER 1 -j "$CHAIN"

    # Allow established/related traffic (return traffic for connections
    # we've already accepted).
    sudo iptables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # Allow Cloudflare IPv4 ranges to the original published port 80.
    for ip in $CF_IPV4; do
        sudo iptables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    # Allow Cloudflare IPv4 ranges to the original published port 443.
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

    # Anything not relevant to this chain (not port 80/443) continues
    # through the rest of DOCKER-USER.
    sudo iptables -A "$CHAIN" -j RETURN
}