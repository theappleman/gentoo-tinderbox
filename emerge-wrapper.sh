#!/bin/bash
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

if [[ -f /var/log/emerge.log ]]; then
    rm -f /var/log/emerge.log
fi

# Don't tweet this away if we're running a non-test try
if [[ -z "${FEATURES}" ]]; then
    echo "$1 queued" | bti --background;
fi

emerge --nospinner --oneshot --deep --update --keep-going --selective=n "$1" < /dev/null

res=$?

echo -5 | etc-update

if [[ $res != 0 ]]; then
    if ! fgrep -q ">>> emerge" /var/log/emerge.log; then
	# Here it means that the merge was rejected; the common case
	# it's a cyclic dependency that Portage cannot break, which is
	# unfortunately common when enabling tests e.g. with Ruby-NG
	# ebuilds. To try recovering from this, try a merge without
	# test features enabled.
	if [[ -z "${FEATURES}" ]]; then
	    FEATURES=-test $0 "$@"
	else
	    # This only hits the second time, so we're safely assuming
	    # that the package will reject to be merged as it is, why,
	    # we'll have to check.
	    echo "$1 merge #rejected" | bti --background
	fi
    fi
fi

rm -f /var/log/emerge.log
