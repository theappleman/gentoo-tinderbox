#!/bin/bash

if [[ -f /var/log/emerge.log ]]; then
    rm -f /var/log/emerge.log
fi

echo "$1 queued" | bti

emerge -1Du --keep-going --selective=n "$1" < /dev/null

res=$?

if [[ $res != 0 ]]; then
    if ! fgrep -q ">>> emerge" /var/log/emerge.log; then
	echo "$1 merge #rejected" | bti
    fi
fi

rm -f /var/log/emerge.log
