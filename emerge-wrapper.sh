#!/bin/bash

if [[ -f /var/log/emerge.log ]]; then
    rm -f /var/log/emerge.log
fi

echo "$1 queued" | bti

emerge --nospinner -1Du --keep-going --selective=n "$1" < /dev/null

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
	    echo "$1 merge #rejected" | bti
	fi
    fi
fi

rm -f /var/log/emerge.log
