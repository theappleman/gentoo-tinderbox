#!/bin/bash
#
# Copyright © 2010 Diego Elio Pettenò <flameeyes@gentoo.org>
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

list=${1-/var/cache/tinderbox/list-complete}

echo > /etc/portage/package.mask/currentsession

while test -f /var/run/tinderbox.pleasestop; do
	echo -ne 'sleeping...\r'
	sleep 60
done

until [ -f /var/run/tinderbox.pleasestop ]; do
    ${tboxdir}/tinderbox-restart.sh

    sort -R ${list} | head -n 200 > /var/cache/tinderbox/myrunlist

    # I don't see the point of this
    #cp ${list} ${list}~
    #cat ${list}~ /var/cache/tinderbox/myrunlist | sort | uniq -u > ${list}

    [ -s /var/cache/tinderbox/myrunlist ] || break

    xargs -a /var/cache/tinderbox/myrunlist -n1 ${tboxdir}/emerge-wrapper.sh

    # before restarting, copy the current run's mask into the session
    # mask; rinse and repeat. This should achieve something much more
    # similar to what I did by hand before.
    cat /etc/portage/package.mask/currentrun >> /etc/portage/package.mask/currentsession
done
