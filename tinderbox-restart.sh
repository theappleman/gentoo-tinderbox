#!/bin/sh

reset_emergelog() {
    rm -f /var/log/emerge.log
}

set -e

echo "#syncing anew upon request" | bti

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

    echo "running #haskell-updater" | bti
    /usr/sbin/haskell-updater --upgrade
fi

reset_emergelog

if emerge -u1 dev-lang/ocaml &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    echo "running #ocaml-rebuild" | bti
    /usr/sbin/ocaml-rebuild.sh -f
fi

emerge -u1 glibc bti screen avahi nfs-utils gentoolkit java-dep-check portage-utils

reset_emergelog
