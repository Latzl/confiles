# rsync helpers

CF_RSYNC_FLAGS="-avzO --no-o --no-g --info=FLIST0,STATS0"

# $1: src_dir  $2: dst_dir  $3: extra_flags (e.g. "-ni")
# Uses global OPT_DRY_RUN, OPT_DEBUG, DST_SSHPASS_CMD
do_cf_rsync() {
	local src_dir="$1"
	local dst_dir="${2:-${HOME}}"
	local extra_flags="${3:-}"

	if [ ! -d "$src_dir" ]; then
		return 1
	fi

	local rsync_cmd="$DST_SSHPASS_CMD rsync $CF_RSYNC_FLAGS $extra_flags"

	if [ "$OPT_DRY_RUN" = "true" ]; then
		echo "$rsync_cmd ${src_dir}/ ${dst_dir}/"
	else
		# Filter out t-only changes (file, size unchanged, time changed) using Perl
		$rsync_cmd "$src_dir/" "$dst_dir/" | perl -ne "print unless /^.f\.\.t\.\.\.\./" | print_rsync_output ">>> $src_dir -> $dst_dir"
		return "${PIPESTATUS[0]}"
	fi
}

# $1: header_text — prints header once, then streams output
print_rsync_output() {
	local header_printed=false
	[ "$OPT_DEBUG" = "true" ] && {
		echo "$*"
		header_printed=true
	}
	while IFS= read -r line || [ -n "$line" ]; do
		[ "$header_printed" = "false" ] && {
			header_printed=true
			echo "$*"
		}
		echo "$line"
	done
}
