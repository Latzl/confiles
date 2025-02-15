# more platforms

# confiles.sh will call this function to get a command string.
# This command need to get the infomations of the dst platform.
# The output of this command will be passed to more_platforms_get_src_mod_dir() as the first argument to determine the src mod dir.
# If this function return code is not 0, or the output is empty, confiles.sh wiil not call more_platforms_check_dst_cmd().
more_platforms_check_dst_cmd() {
	_more_platform_get_glibc_ver_cmd
}

# $0 <check dst cmd result>
# confiles.sh will call this function, with result of more_platforms_check_dst_cmd() as arugment, to get the src mod directory, which is returned by this function and relative to this script directory.
more_platforms_get_src_mod_dir() {
	if [ -z "$DST_OS" ] || [ -z "$DST_ARCH" ]; then
		echo "DST_OS or DST_ARCH is not set" >&2
		return 1
	fi
	local dst_glibc_ver="$1"
	if [ -z "$dst_glibc_ver" ]; then
		echo "dst_glibc_ver is not set" >&2
		return 1
	fi
	if ! _more_platform_is_ver_valid "$dst_glibc_ver"; then
		echo "invalid glibc version: $1" >&2
		return 1
	fi
	local src_mod_dir="${DST_OS}/${DST_ARCH}/glibc/${dst_glibc_ver}"
	echo "$src_mod_dir"
}

# define functions to check dst platform below

_more_platform_is_ver_valid() {
	echo -n "$1" | perl -ne 'exit 0 if /^[^.][.0-9]+[^.]$/; exit 1'
}

_more_platform_get_glibc_ver_cmd() {
	local cmd
	cmd=$(
		cat <<'EOF'
ldd --version | \
perl -ne '
	if ($. == 1) { 
		@fields = split;
		print$fields[-1];
		last;
	}
'
EOF
	)
	echo "$cmd"
}
