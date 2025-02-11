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

DST_SSHPASS_CMD=''
_set_sshpass_cmd() {
	# localhost no need sshpass
	if [ "$DST_HOST" = "localhost" ]; then
		return 0
	fi

	# if ssh config has IdentityFile for DST_HOST, use it
	local ssh_conf_path="$HOME/.ssh/config"
	if [ -f "$ssh_conf_path" ]; then
		local identity_path
		identity_path=$(awk -v host="$HOST" '
		in_host_block=0
		{
			if ($1 == "Host" && index($0, host) != 0) {
				in_host_block=1
			} else if (in_host_block && $1 == "IdentityFile") {
				print $2
				exit
			} else if ($1 == "Host") {
				in_host_block=0
			}
		}
		' "$ssh_conf_path")
		if [ -n "$identity_path" ] && [ -f "$identity_path" ]; then
			return 0
		fi
	fi

	# ask password
	local remote_passwd
	while true; do
		read -rsp 'Enter password for remote host:' remote_passwd
		echo
		# TODO consider some situations
		sshpass -p "$remote_passwd" ssh "$DST_HOST" exit 0 && break
	done

	DST_SSHPASS_CMD="sshpass -p $remote_passwd"
}
_set_sshpass_cmd

if [ "$DST_HOST" != "localhost" ]; then
	_CF_DESTINATION_UNAME="$($DST_SSHPASS_CMD ssh "$DST_HOST" 'uname -sm')"
else
	_CF_DESTINATION_UNAME="$(uname -sm)"
fi

DST_OS="$(awk '{print $1}' <<<"$_CF_DESTINATION_UNAME")"
DST_ARCH="$(awk '{print $2}' <<<"$_CF_DESTINATION_UNAME")"
