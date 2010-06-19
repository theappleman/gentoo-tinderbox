#!/bin/sh

wget -q -O- http://tinderbox.dev.gentoo.org/misc/{r,d}index/$1 | \
    xargs -n1 qatom | \
    cut -d ' ' -f 1-2 | \
    tr ' ' '/' | \
    sort -u
