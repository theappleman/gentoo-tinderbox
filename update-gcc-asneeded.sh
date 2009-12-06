#!/bin/sh

export SPECSFILE=$(dirname "$(gcc -print-libgcc-file-name)")/asneeded.specs
export CURRPROFILE=/etc/env.d/gcc/$(gcc-config -c)
gcc -dumpspecs | sed -e '/link:/,+1 s:--eh-frame-hdr:\0 --as-needed:' > "$SPECSFILE"
sed "${CURRPROFILE}" -e '1i\GCC_SPECS='$SPECSFILE > "${CURRPROFILE}-asneeded"
gcc-config "$(basename "${CURRPROFILE}")-asneeded"
source /etc/profile
