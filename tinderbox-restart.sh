#!/bin/sh

reset_emergelog() {
    rm -f /var/log/emerge.log
}

dent() {
    # Ignore failure that might be caused by network being
    # unavailable, the service being unavailable or things like those.
    echo "$@" | bti || true
}

set -e

dent "#syncing anew upon request"

emerge --sync

echo > /etc/portage/package.mask/currentrun

./unavailable_installed.py | xargs -r emerge -C

reset_emergelog

emerge -u1 portage

emerge -u1 gcc
if fgrep -q '>>> emerge' /var/log/emerge.log; then
    ./update-gcc-asneeded.sh
fi

reset_emergelog

if emerge -u1 ghc haskell-updater &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent "running #haskell-updater"
    /usr/sbin/haskell-updater --upgrade
fi

reset_emergelog

if emerge -u1 dev-lang/ocaml &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent "running #ocaml-rebuild"
    /usr/sbin/ocaml-rebuild.sh -f
fi

emerge -u1 glibc bti screen avahi nfs-utils gentoolkit java-dep-check portage-utils

reset_emergelog
