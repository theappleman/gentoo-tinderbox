#!/bin/bash

tboxdir=$(dirname $0)

until [ -e /var/run/tinderbox.pleasestop ]; do
    ${tboxdir}/tinderbox-restart.sh

    head -n 200 /var/cache/tinderbox/queue | xargs -n1 ${tboxdir}/emerge-wrapper.sh
done
