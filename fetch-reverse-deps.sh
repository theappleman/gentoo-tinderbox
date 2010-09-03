#!/bin/sh
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

(
    source /etc/make.tinderbox.private.conf
    for atom in $@; do
        curl --fail ${TINDERBOX_PROXY+--proxy ${TINDERBOX_PROXY}} http://tinderbox.dev.gentoo.org/misc/{r,d}index/${atom}
    done
) | egrep -v '^\[B\]' | sort -u | \
    xargs -n1 qatom | \
    cut -d ' ' -f 1-2 | \
    tr ' ' '/' | \
    uniq
