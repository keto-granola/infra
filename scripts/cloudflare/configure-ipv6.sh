#!/usr/bin/env bash

# Builds the CLOUDFLARE-ONLY ip6tables chain and wires it into
# DOCKER-USER. Requires CF_IPV6 and CHAIN to already be set by the caller.
# Mirror of configure-ipv4.sh — see that file for inline comments.

configure_ipv6() {
    echo "Configuring IPv6 rules..."

    sudo ip6tables -N "$CHAIN" 2>/dev/null || true
    sudo ip6tables -F "$CHAIN"

    while sudo ip6tables -C DOCKER-USER -j "$CHAIN" 2>/dev/null; do
        sudo ip6tables -D DOCKER-USER -j "$CHAIN"
    done

    sudo ip6tables -I DOCKER-USER 1 -j "$CHAIN"

    sudo ip6tables -A "$CHAIN" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 80 \
            -j ACCEPT
    done

    for ip in $CF_IPV6; do
        sudo ip6tables -A "$CHAIN" \
            -s "$ip" \
            -p tcp \
            -m conntrack --ctorigdstport 443 \
            -j ACCEPT
    done

    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 80 \
        -j DROP

    sudo ip6tables -A "$CHAIN" \
        -p tcp \
        -m conntrack --ctorigdstport 443 \
        -j DROP

    sudo ip6tables -A "$CHAIN" -j RETURN
}