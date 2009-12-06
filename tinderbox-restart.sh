#!/bin/sh

set -e

echo "#syncing anew upon request" | bti

emerge --sync

echo > /etc/portage/package.mask/currentrun

./unavailable_installed.py | xargs -r emerge -C

sed -i -e '$r /var/log/emerge.log' /var/log/emerge-total.log
rm -f /var/log/emerge.log

emerge -1 --selective gcc
if fgrep -q '>>> emerge' /var/log/emerge.log; then
    ./update-gcc-asneeded.sh
fi

emerge -1 --selective glibc portage bti screen avahi nfs-utils gentoolkit java-dep-check portage-utils

sed -i -e '$r /var/log/emerge.log' /var/log/emerge-total.log
rm -f /var/log/emerge.log
