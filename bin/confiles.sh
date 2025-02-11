#!/bin/bash

if ! which rsync &>/dev/null; then
	echo "rsync not found, required" >&2
	exit 1
fi

get_usage() {
	local this_sh='confiles.sh'
	cat <<_USAGE_EOF_
Usage: $this_sh {ACTION} [--debug] [--help|-h] [[--mods|-m]|[--exclude-mods|-e]] [[--dst|-d]dst_dir]
ACTION:
	status		show difference between src and dst
	apply		sync files to dst
	src_check	check if src contain duplicate files 
	remove		remove confiles

OPTIONS:
	--debug				print debug info when running
	--help|-h			print this help and exit
	--mods|-m			specify mods to be done by action, mod seperated by comma, exclusive with --exclude-mods
	--exclude-mods|-e	specify mods to be excluded by action, mod seperated by comma exclusive with --mods
		if --mods or --exclude-mods not specified, all mods will be specified by default
	--dst|-d			specify dst directory, default is ~. No have to type --dst or -d explicitly, just type dst_dir can be ok.

The option dst_dir can be remote directory with format follow rsync's. If dst_dir not specified, ~ will be used as default.

Examples:
	# show difference between src and dst
	$this_sh status
	# sync files to ~/
	$this_sh apply
	# show status as dst dir is /home/user, with specify mods mod1 and mod2
	$this_sh status --mods=mod1,mod2 --dst=/home/user
	# show status as dst dir is remote host
	$this_sh status user@remote:~
	# sync files to remote host, exclude mod1 and mod2
	$this_sh apply --exclude-mods=mod1,mod2 --dst=user@remote:~
	# remove confiles
	$this_sh remove
	# remove confiles with specify mods, with remote dst
	$this_sh remove --mods=mod1,mod2 --dst=user@remote:~
_USAGE_EOF_
}

OPT_DEBUG=false

ARGS="$(getopt -l debug,help,mods:,exclude-mods:,dst: -o h,m:,e:,d: -- "$@")" || {
	get_usage >&2
	exit 1
}

eval set -- "$ARGS"

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CURR_DIR}/lib-confiles/source.bash"
source "${CURR_DIR}/lib-confiles/color.bash"

module_paths=()
DST_DIR=''

handle_mods_option() {
	local mods=()
	local mod_path
	readarray -td, mods < <(printf "%s" "$1")
	for mod in "${mods[@]}"; do
		mod_path="${CF_MODS_DIR}/${mod}"
		if [ -d "$mod_path" ]; then
			module_paths+=("$mod_path")
		fi
	done
}

handle_exclude_mods_option() {
	local modules_exclude_list
	modules_exclude_list="${1//,/$'\n'}"
	local modules_all=()
	readarray -t modules_all <<<"$(cd "${CF_MODS_DIR}" && find ./* -maxdepth 0 -exec basename {} \;)"
	for module in "${modules_all[@]}"; do
		if ! grep -q "^${module}$" <<<"$modules_exclude_list"; then
			module_paths+=("${CF_MODS_DIR}/${module}")
		fi
	done
}

while true; do
	case "$1" in
	--debug)
		OPT_DEBUG=true
		shift
		;;
	--help | -h)
		get_usage
		exit 0
		;;
	--mods | -m)
		handle_mods_option "$2"
		if [ "${#module_paths[@]}" -eq 0 ]; then
			echo "No module found: $2" >&2
			exit 1
		fi
		shift 2
		;;
	--exclude-mods | -e)
		handle_exclude_mods_option "$2"
		shift 2
		;;
	--dst | -d)
		DST_DIR="$2"
		shift 2
		;;
	--)
		shift
		break
		;;
	*)
		echo "Unknown option: $1" >&2
		get_usage >&2
		exit 1
		;;
	esac
done

set_module_paths_all() {
	local mod_path
	readarray -t modules_all <<<"$(cd "${CF_MODS_DIR}" && find ./* -maxdepth 0 -exec basename {} \;)"
	for module in "${modules_all[@]}"; do
		module_paths+=("${CF_MODS_DIR}/${module}")
	done
}

if [ "${#module_paths[@]}" -eq 0 ]; then
	set_module_paths_all
fi

if [ -z "$DST_DIR" ]; then
	if [ -n "$2" ]; then
		DST_DIR="$2"
	else
		DST_DIR="$HOME"
	fi
fi

source "${CURR_DIR}/lib-confiles/destination.bash"

# print infos
if $OPT_DEBUG; then
	echo "DST_DIR=$DST_DIR"
	echo "DST_HOST=$DST_HOST"
	echo "DST_SSHPASS_CMD=$DST_SSHPASS_CMD"
	echo "DST_OS=$DST_OS"
	echo "DST_ARCH=$DST_ARCH"
	echo "module_paths:"
	printf "\t%s\n" "${module_paths[@]}"
fi

# fuctions
cf_status() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	local dst_dir="$2"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	if [ -z "$dst_dir" ]; then
		dst_dir="$HOME"
	fi

	local content
	content="$($DST_SSHPASS_CMD rsync -avzO --no-o --no-g --info=FLIST0,STATS0 -ni "${src_dir}/" "${dst_dir}/")"

	if [ -n "$content" ] || $OPT_DEBUG; then
		echo ">>> $src_dir -> $dst_dir"
	fi
	if [ -n "$content" ]; then
		echo "$content"
	fi
}

cf_apply() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	local dst_dir="$2"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	if [ -z "$dst_dir" ]; then
		dst_dir="$HOME"
	fi

	local content
	content="$($DST_SSHPASS_CMD rsync -avzO --no-o --no-g --info=FLIST0,STATS0 "${src_dir}/" "${dst_dir}/")"

	if [ -n "$content" ] || $OPT_DEBUG; then
		echo ">>> $src_dir -> $dst_dir"
	fi
	if [ -n "$content" ]; then
		echo "$content"
	fi
}

status_all() {
	local content=''
	for mod_dir in "${module_paths[@]}"; do
		cf_status "$mod_dir" "$DST_DIR"

		# platform
		local mod_platform_dir
		mod_platform_dir="${mod_dir}/$(cf_mod_platform_suffix)"
		if [ -d "$mod_platform_dir" ]; then
			cf_status "$mod_platform_dir" "$DST_DIR"
		fi
	done
}

apply_all() {
	local content=''
	for mod_dir in "${module_paths[@]}"; do
		cf_apply "$mod_dir" "$DST_DIR"

		# platform
		local mod_platform_dir
		mod_platform_dir="${mod_dir}/$(cf_mod_platform_suffix)"
		if [ -d "$mod_platform_dir" ]; then
			cf_apply "$mod_platform_dir" "$DST_DIR"
		fi
	done
}

# check if files duplicate
src_check_file_dup() {
	local list
	list="$(cd "${CF_MODS_DIR}" && find -L . -type f -printf "%P\n" | grep -P '^[^/]*/(Linux|home)')"

	local duplicated
	duplicated="$(
		sort -t'/' -k2 <<<"$list" |
			awk '{
				key = substr($0, index($0, "/") + 1)
				if (key == prev) {
					cnt++
					if (cnt == 1) print prev_line
					print $0
				} else {
					cnt = 0
					prev = key
					prev_line = $0
				}
			}'
	)"
	if [ -n "$duplicated" ]; then
		echo "$(to_red "Duplicated files"):"
		echo "$duplicated"
		return 1
	else
		to_green "No duplicated files"
		return 0
	fi
}
src_check() {
	src_check_file_dup
}

CF_RM_CHACHE_PATH="${CF_CACHE_DIR}/remove_files.list"
CF_DST_RM_CHACHE_PATH="${DST_DIR}/.confiles/.cache/remove_files.list"
prepare_src_rm_files() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	{
		cd "$src_dir" && find -L . -type f -printf "%P\n"
	} >>"$CF_RM_CHACHE_PATH"
}
prepare_rm_cache() {
	[ -f "$CF_RM_CHACHE_PATH" ] && rm "$CF_RM_CHACHE_PATH"
	[ ! -d "$(dirname "$CF_RM_CHACHE_PATH")" ] && mkdir -p "$(dirname "$CF_RM_CHACHE_PATH")"

	for mod_dir in "${module_paths[@]}"; do
		prepare_src_rm_files "$mod_dir"

		# platform
		local mod_platform_dir
		mod_platform_dir="${mod_dir}/$(cf_mod_platform_suffix)"
		if [ -d "$mod_platform_dir" ]; then
			prepare_src_rm_files "$mod_platform_dir" "$DST_DIR"
		fi
	done

	echo ">>> ${CF_RM_CHACHE_PATH} -> ${CF_DST_RM_CHACHE_PATH}"
	local cmd
	cmd="$DST_SSHPASS_CMD rsync -avzO --no-o --no-g --info=FLIST0,STATS0 ${CF_RM_CHACHE_PATH} ${CF_DST_RM_CHACHE_PATH}"
	eval "$cmd"
}
do_remove_modules() {
	# TODO
	:
}
remove_all() {
	prepare_rm_cache
	do_remove_modules
}

# main
case "$1" in
status)
	status_all
	;;
apply)
	apply_all
	;;
src_check)
	src_check
	;;
remove)
	remove_all
	;;
*)
	to_red "Unknown action: $1" >&2
	get_usage >&2
	exit 1
	;;
esac

exit 0
