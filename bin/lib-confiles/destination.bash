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

# dst local relative dir
if [ "$DST_HOST" = "localhost" ]; then
	DST_LRDIR="$DST_DIR"
else
	DST_LRDIR="$(perl -pe 's/^[^:]*://' <<<"$DST_DIR")"
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
		identity_path=$(
			perl -ne '
			BEGIN { $host = shift;$in_block = 0; }
			if (m/(?i)^Host\s+$host$/) { $in_block = 1; next; }
			if ($in_block && m/(?i)^Host/) {$in_block = 0; }
			if ($in_block && m/(?i)IdentityFile\s+(?<identity>.*)/) {
				print "$+{identity}\n";
				exit;
			}' -- "$DST_HOST" <"$ssh_conf_path"
		)
		identity_path="${identity_path/#\~/$HOME}"
		# echo "$identity_path"
		if [ -f "$identity_path" ]; then
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

do_cmd_on_dst() {
	local cmd
	if [ "$DST_HOST" != "localhost" ]; then
		cmd="$DST_SSHPASS_CMD ssh $DST_HOST $(escape_ssh_cmd_with_cf_flag "$*")"
		eval "$cmd" | parse_ssh_confiles_result
		return "${PIPESTATUS[0]}"
	else
		cmd="$*"
		eval "$cmd"
		return "$?"
	fi
}
