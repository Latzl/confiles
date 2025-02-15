_CONFILES_SSH_RESULT_FLAG_=_CONFILES_SSH_RESULT_FLAG_
escape_ssh_cmd() {
	local escaped_cmd
	escaped_cmd=$(
		cat <<EOF
bash <<'_ESC_SSH_CMD_EOF_'
$@
_ESC_SSH_CMD_EOF_
EOF
	)
	echo "$escaped_cmd"
}
escape_ssh_cmd_with_cf_flag() {
	local escaped_cmd
	escaped_cmd=$(
		cat <<EOF
echo "$_CONFILES_SSH_RESULT_FLAG_"
$@
exit \$?
EOF
	)
	escape_ssh_cmd "$escaped_cmd"
}
parse_ssh_confiles_result() {
	local met_flag=false
	while IFS= read -r line || [ -n "$line" ]; do
		if [ "$line" = "$_CONFILES_SSH_RESULT_FLAG_" ]; then
			met_flag=true
			continue
		fi
		if [ "$met_flag" = true ]; then
			echo "$line"
		fi
	done
}
