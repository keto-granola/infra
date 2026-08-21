#!/usr/bin/env bash
#
# ufw only handles SSH (22) and the default incoming/outgoing policy here.

configure_ufw() {
    echo "Configuring UFW..."

    sudo ufw allow 22/tcp >/dev/null
    sudo ufw default deny incoming >/dev/null
    sudo ufw default allow outgoing >/dev/null
    sudo ufw --force enable >/dev/null
}