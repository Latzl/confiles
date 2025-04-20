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
source "${CURR_DIR}/lib-confiles/ssh.bash"

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
	# echo "DST_SSHPASS_CMD=$DST_SSHPASS_CMD"
	echo "DST_OS=$DST_OS"
	echo "DST_ARCH=$DST_ARCH"
	echo "module_paths:"
	printf "\t%s\n" "${module_paths[@]}"
fi

# fuctions

# shellcheck disable=SC2317
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

# shellcheck disable=SC2317
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

	$DST_SSHPASS_CMD rsync -avzO --no-o --no-g --info=FLIST0,STATS0 -ni "${src_dir}/" "${dst_dir}/" |
		print_rsync_output ">>> $src_dir -> $dst_dir"

	return "${PIPESTATUS[0]}"
}

# shellcheck disable=SC2317
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

	$DST_SSHPASS_CMD rsync -avzO --no-o --no-g --info=FLIST0,STATS0 "${src_dir}/" "${dst_dir}/" |
		print_rsync_output ">>> $src_dir -> $dst_dir"

	return "${PIPESTATUS[0]}"
}

# $0 <handler> <mod_platform_dir>
handle_more_platforms() {
	[ "$OPT_DEBUG" = "true" ] && echo "=== handle_more_platforms(): $1 $2"
	local handler="$1"
	local mod_platform_dir="$2"
	local mod_more_platforms_script
	mod_more_platforms_script="${mod_platform_dir}/more-platforms.bash"
	[ -f "$mod_more_platforms_script" ] || {
		return 0
	}
	[ "$OPT_DEBUG" = "true" ] && echo "with $mod_more_platforms_script"

	# shellcheck disable=SC1090
	source "$mod_more_platforms_script"

	local check_dst_cmd
	check_dst_cmd=$(more_platforms_check_dst_cmd) || {
		local exit_code=$?
		to_red "Exec more_platforms_check_dst_cmd failed[$?] in: $mod_more_platforms_script" >&2
		return $exit_code
	}
	[ -z "$check_dst_cmd" ] && {
		to_red "more_platforms_check_dst_cmd() returned empty" >&2
		return 1
	}
	[ "$OPT_DEBUG" = "true" ] && echo "check_dst_cmd: $check_dst_cmd"

	local check_dst_result
	check_dst_result="$(do_cmd_on_dst "$check_dst_cmd")" || {
		local exit_code=$?
		to_red "Exec failed[$exit_code], with check_dst_cmd: $check_dst_cmd " >&2
		return $exit_code
	}
	[ -z "$check_dst_result" ] && {
		to_red "Result is empty, with check_dst_cmd: $check_dst_cmd" >&2
		return 1
	}
	[ "$OPT_DEBUG" = "true" ] && echo "check_dst_result: $check_dst_result"

	local more_platforms_src_dir
	more_platforms_src_dir="$(more_platforms_get_src_mod_dir "$check_dst_result")" || {
		local exit_code=$?
		to_red "Exec more_platforms_get_src_mod_dir failed[$exit_code] in: $mod_more_platforms_script" >&2
		return $exit_code
	}
	more_platforms_src_dir="${mod_platform_dir}/${more_platforms_src_dir}"
	[ -d "$more_platforms_src_dir" ] || {
		return 0
	}
	[ "$OPT_DEBUG" = "true" ] && echo "more_platforms_src_dir: $more_platforms_src_dir"

	"$handler" "$more_platforms_src_dir" "$DST_DIR"
}

# $0 <handler>
# for handler need match signature: handler <src_mod_dir> [dst_dir]
for_each_src_to_dst_mods_handle() {
	local handler="$1"
	for mod_dir in "${module_paths[@]}"; do
		# base
		"$handler" "$mod_dir" "$DST_DIR"

		# platform
		local mod_base_platform_dir
		mod_base_platform_dir="${mod_dir}/$(cf_mod_base_platform_suffix)"
		if [ -d "$mod_base_platform_dir" ]; then
			"$handler" "$mod_base_platform_dir" "$DST_DIR"
		fi

		# more platforms
		local mod_platform_dir
		mod_platform_dir="${mod_dir}/$(cf_mod_platform_suffix)"
		handle_more_platforms "$handler" "$mod_platform_dir"
	done
}

status_all() {
	for_each_src_to_dst_mods_handle cf_status
}

apply_all() {
	for_each_src_to_dst_mods_handle cf_apply
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

CF_RM_CACHE_FILE="remove_files.list"
CF_RM_CACHE_RPATH="${CF_CACHE_RDIR}/${CF_RM_CACHE_FILE}"
CF_RM_CACHE_TMP_PATH="${CF_CACHE_DIR}/${CF_RM_CACHE_FILE}.tmp"
CF_RM_CACHE_PATH="${CF_CACHE_DIR}/${CF_RM_CACHE_FILE}"
CF_DST_RM_CHACHE_PATH="${DST_DIR}/${CF_RM_CACHE_RPATH}"

# shellcheck disable=SC2317
prepare_src_rm_tmp_files() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	{
		cd "$src_dir" && find -L . -mindepth 1 -printf "%P\n"
	} >>"$CF_RM_CACHE_TMP_PATH"
}
prepare_rm_cache() {
	[ -f "$CF_RM_CACHE_TMP_PATH" ] && rm "$CF_RM_CACHE_TMP_PATH"
	[ -f "$CF_RM_CACHE_PATH" ] && rm "$CF_RM_CACHE_PATH"
	[ ! -d "$CF_CACHE_DIR" ] && mkdir -p "$CF_CACHE_DIR"

	for_each_src_to_dst_mods_handle prepare_src_rm_tmp_files

	# sort by path depth to rm dir
	perl -e 'my %seen; print grep { !$seen{$_}++ } sort { length($b) <=> length($a) } <>' "$CF_RM_CACHE_TMP_PATH" > "$CF_RM_CACHE_PATH"
	rm "$CF_RM_CACHE_TMP_PATH"

	echo ">>> ${CF_RM_CACHE_PATH} -> ${CF_DST_RM_CHACHE_PATH}"
	local cmd
	cmd="$DST_SSHPASS_CMD rsync -avzO --no-o --no-g --rsync-path='mkdir -p ${CF_CACHE_RDIR} && rsync' --info=NONE ${CF_RM_CACHE_PATH} ${CF_DST_RM_CHACHE_PATH}"
	eval "$cmd"
}
do_remove_modules() {
	[ "$OPT_DEBUG" = "true" ] && echo "=== do_remove_modules()"
	local rm_cmd="for file in \$(cat ${DST_LRDIR}/${CF_RM_CACHE_RPATH}); do path=${DST_LRDIR}/\${file}; if [ -d \$path ]; then rm -dv \$path; else rm -v \$path; fi; done 2>&1"
	[ "$OPT_DEBUG" = "true" ] && echo "rm_cmd: $rm_cmd"
	do_cmd_on_dst "$rm_cmd"
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
