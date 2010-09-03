#!/bin/sh
#
# Copyright © 2007-2010 Diego Elio Pettenò <flameeyes@gentoo.org>
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

export SPECSFILE=$(dirname "$(gcc -print-libgcc-file-name)")/asneeded.specs
export CURRPROFILE=/etc/env.d/gcc/$(gcc-config -c)
gcc -dumpspecs | sed -e '/link:/,+1 s:--eh-frame-hdr:\0 --as-needed:' > "$SPECSFILE"
sed "${CURRPROFILE}" -e '1i\GCC_SPECS='$SPECSFILE > "${CURRPROFILE}-asneeded"
gcc-config "$(basename "${CURRPROFILE}")-asneeded"
source /etc/profile
