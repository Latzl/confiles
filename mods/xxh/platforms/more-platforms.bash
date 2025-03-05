# more platforms

# confiles.sh will call this function to get a command string.
# This command need to get the infomations of the dst platform.
# The output of this command will be passed to more_platforms_get_src_mod_dir() as the first argument to determine the src mod dir.
# If this function return code is not 0, or the output is empty, confiles.sh wiil not call more_platforms_check_dst_cmd().
more_platforms_check_dst_cmd() {
	if [ "$DST_HOST" = localhost ]; then
		echo "echo true"
	else
		echo "echo false"
	fi
}

# $0 <check dst cmd result>
# confiles.sh will call this function, with result of more_platforms_check_dst_cmd() as arugment, to get the src mod directory, which is returned by this function and relative to this script directory.
more_platforms_get_src_mod_dir() {
	local is_localhost
	is_localhost=$1
	if [ "$is_localhost" = true ]; then
		local src_mod_dir="local"
		echo "$src_mod_dir"
	else
		echo ""
	fi
}

# define functions to check dst platform below
