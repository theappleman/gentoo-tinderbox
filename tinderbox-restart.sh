#!/bin/sh

reset_emergelog() {
    sed -i -e '$r /var/log/emerge.log' /var/log/emerge-total.log
    rm -f /var/log/emerge.log
}

set -e

echo "#syncing anew upon request" | bti

emerge --sync

echo > /etc/portage/package.mask/currentrun

./unavailable_installed.py | xargs -r emerge -C

reset_emergelog

emerge -1 --selective gcc
if fgrep -q '>>> emerge' /var/log/emerge.log; then
    ./update-gcc-asneeded.sh
fi

reset_emergelog

emerge -1 --selective ghc haskell-updater
if fgrep -q '>>> emerge' /var/log/emerge.log; then
    echo "running #haskell-updater"
    /usr/sbin/haskell-updater --upgrade
fi

emerge -1 --selective glibc portage bti screen avahi nfs-utils gentoolkit java-dep-check portage-utils

reset_emergelog
