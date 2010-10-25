#!/bin/sh
#
# Copyright © 2008-2010 Diego Elio Pettenò <flameeyes@gentoo.org>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
# ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
# CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
# PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
# SOFTWARE.

tboxdir=$(dirname $0)

mkdir -p /var/cache/tinderbox

reset_emergelog() {
    rm -f /var/log/emerge.log
}

source /etc/make.tinderbox.private.conf

if [[ -n ${BTI_ACCOUNT} ]]; then
    dent_me() {
        echo "$@" | bti ${TINDERBOX_PROXY:+--proxy "${TINDERBOX_PROXY}"} --host "${BTI_HOST}" --account "${BTI_ACCOUNT}" --password "${BTI_PASSWORD}" --background
    }
else
    dent_me() { :; }
fi

set -e

dent_me "#syncing anew upon request"

emerge --sync

echo > /etc/portage/package.mask/currentrun

${tboxdir}/unavailable_installed.py | xargs -r emerge -C

reset_emergelog

emerge -u1 portage

emerge -u1 gcc
if fgrep -q '>>> emerge' /var/log/emerge.log && gcc-config -l | tail -n 1 | grep -v asneeded; then
    ${tboxdir}/update-gcc-asneeded.sh
    exit 0
fi

reset_emergelog

if emerge -u1 perl-cleaner perl &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent_me "running per-cleaner"
    perl-cleaner --all -- --keep-going
fi

reset_emergelog

if emerge -u1 ghc haskell-updater &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent_me "running #haskell-updater"
    /usr/sbin/haskell-updater --upgrade
fi

reset_emergelog

if emerge -u1 dev-lang/ocaml &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent_me "running #ocaml-rebuild"
    # Don't fail if ocaml-rebuild fails, because of bug #319553
    /usr/sbin/ocaml-rebuild.sh -f || true
fi

reset_emergelog

[[ -f /usr/src/linux/.config ]] && cp /usr/src/linux/.config /usr/src/config

if emerge -u1 sys-kernel/gentoo-sources &&
    fgrep -q '>>> emerge' /var/log/emerge.log; then

    dent_me "new #gentoo-sources, making oldconfig"
    [[ -f /usr/src/config ]] && cp /usr/src/config /usr/src/linux/.config

    pushd /usr/src/linux
        yes '' | make -j14 oldconfig && \
            make -j14 prepare modules_prepare
    popd

    emerge -P gentoo-sources
fi

emerge -u1 glibc bti screen gentoolkit java-dep-check portage-utils

reset_emergelog

# Generate a new complete list, this will also produce the list of new
# dependencies to satisfy. Ignore new-style virtuals, leave them to be
# merged out of dependencies.
${tboxdir}/tinderbox.py | egrep -v '^virtual/' > /var/cache/tinderbox/list-complete

# Launch the fetch operation in background, saving the log (of both
# good results and failures).
nohup xargs -a /var/cache/tinderbox/list-complete emerge -FO --keep-going &> /var/log/tinderbox-fetch.log &

# Now replace the old queue with a new one, skipping everything that
# we wouldn't otherwise be merging (packages masked, removed, and
# similar).
mv /var/cache/tinderbox/queue /var/cache/tinderbox/queue.old
sort /var/cache/tinderbox/queue.old /var/cache/tinderbox/list-complete | uniq -d | sort -R > /var/cache/tinderbox/queue
