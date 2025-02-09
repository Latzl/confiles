#!/bin/bash
# get DST_HOST, DST_OS, DST_ARCH

if [ -z "$DST_DIR" ]; then
	echo "DST_DIR is not set" >&2
	exit 1
fi

_is_dst_remote() {
	grep -q ":" <<<"$1"
}

if _is_dst_remote "$DST_DIR"; then
	DST_HOST="$(cut -d: -f1 <<<"$DST_DIR")"
else
	DST_HOST="localhost"
fi

if [ "$DST_HOST" != "localhost" ]; then
	_CF_DESTINATION_UNAME="$(ssh "$DST_HOST" 'uname -sm')"
else
	_CF_DESTINATION_UNAME="$(uname -sm)"
fi

DST_OS="$(awk '{print $1}' <<<"$_CF_DESTINATION_UNAME")"
DST_ARCH="$(awk '{print $2}' <<<"$_CF_DESTINATION_UNAME")"