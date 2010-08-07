#!/bin/sh

(
    for atom in $@; do
        wget -q -O- http://tinderbox.dev.gentoo.org/misc/{r,d}index/${atom}
    done
) | egrep -v '^\[B\]' | sort -u | \
    xargs -n1 qatom | \
    cut -d ' ' -f 1-2 | \
    tr ' ' '/' | \
    uniq
