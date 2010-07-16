#!/bin/sh

mkdir -p /var/cache/tinderbox

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
    exit 0
fi

reset_emergelog

if emerge -u1 perl-cleaner perl &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent "running per-cleaner"
    perl-cleaner --all
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
    # Don't fail if ocaml-rebuild fails, because of bug #319553
    /usr/sbin/ocaml-rebuild.sh -f || true
fi

reset_emergelog

if emerge -u1 sys-kernel/gentoo-sources &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent "new #gentoo-sources, making oldconfig"
    cp -l /usr/src/config /usr/src/linux/.config

    pushd /usr/src/linux
        make -j14 oldconfig && \
            make -j14 prepare modules_prepare
    popd

    emerge -P gentoo-sources
fi

emerge -u1 glibc bti screen gentoolkit java-dep-check portage-utils

reset_emergelog

# Generate a new complete list, this will also produce the list of new
# dependencies to satisfy.
./tinderbox.py > /var/cache/tinderbox/list-complete

# Launch the fetch operation in background, saving the log (of both
# good results and failures).
nohup xargs -a /var/cache/tinderbox/list-complete emerge -fO --keep-going &> /var/log/tinderbox-fetch.log &

# Now replace the old queue with a new one, skipping everything that
# we wouldn't otherwise be merging (packages masked, removed, and
# similar).
mv /var/cache/tinderbox/queue /var/cache/tinderbox/queue.old
sort /var/cache/tinderbox/queue.old /var/cache/tinderbox/list-complete | uniq -d | sort -R > /var/cache/tinderbox/queue
