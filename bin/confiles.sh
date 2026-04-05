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
	diff		interactively review differences with fzf and open with vimdiff; falls back to diff if fzf not found
	src_check	check if src contain duplicate files
	remove		remove confiles

OPTIONS:
	--debug				print debug info when running
	--help|-h			print this help and exit
	--mods|-m			specify mods to be done by action, mod seperated by comma, exclusive with --exclude-mods
	--exclude-mods|-e	specify mods to be excluded by action, mod seperated by comma exclusive with --mods
		if --mods or --exclude-mods not specified, all mods will be specified by default
	--dst|-d			specify dst directory, default is ~. No have to type --dst or -d explicitly, just type dst_dir can be ok.
	--dry-run			dry run for action: status and apply. Just print command, not run it

The option dst_dir can be remote directory with format follow rsync's. If dst_dir not specified, ~ will be used as default.

Examples:
	# show difference between src and dst
	$this_sh status
	# interactively review and edit differences
	$this_sh diff
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

ARGS="$(getopt -l debug,help,mods:,exclude-mods:,dst:,dry-run -o h,m:,e:,d: -- "$@")" || {
	get_usage >&2
	exit 1
}

eval set -- "$ARGS"

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${CURR_DIR}/lib/confiles"
source "${LIB_DIR}/source.bash"
source "${LIB_DIR}/color.bash"
source "${LIB_DIR}/ssh.bash"
source "${LIB_DIR}/rsync.bash"
source "${LIB_DIR}/modules.bash"

module_paths=()
DST_DIR=''

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
		while IFS= read -r mp; do
			module_paths+=("$mp")
		done < <(filter_mods_include "$2")
		if [ "${#module_paths[@]}" -eq 0 ]; then
			echo "No module found: $2" >&2
			exit 1
		fi
		shift 2
		;;
	--exclude-mods | -e)
		while IFS= read -r mp; do
			module_paths+=("$mp")
		done < <(filter_mods_exclude "$2")
		shift 2
		;;
	--dst | -d)
		DST_DIR="$2"
		shift 2
		;;
	--dry-run)
		OPT_DRY_RUN=true
		shift
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

if [ "${#module_paths[@]}" -eq 0 ]; then
	while IFS= read -r name; do
		module_paths+=("${CF_MODS_DIR}/${name}")
	done < <(list_all_mod_names)
fi

if [ -z "$DST_DIR" ]; then
	if [ -n "$2" ]; then
		DST_DIR="$2"
	else
		DST_DIR="$HOME"
	fi
fi

source "${CURR_DIR}/lib/confiles/destination.bash"

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
cf_status() {
	local src_dir="$1/home"
	local dst_dir="${2:-${HOME}}"
	do_cf_rsync "$src_dir" "$dst_dir" "-ni"
}

# shellcheck disable=SC2317
cf_apply() {
	local src_dir="$1/home"
	local dst_dir="${2:-${HOME}}"
	do_cf_rsync "$src_dir" "$dst_dir"
}

# $1: mod_dir
# Emits: "mod_name|src_path|resolved_dst_path|rel_path|attrs"
# shellcheck disable=SC2317
cf_diff() {
	local mod_dir="$1"
	local src_dir="${mod_dir}/home"
	local dst_dir="${DST_DIR}"
	local mod_name
	mod_name="$(basename "$mod_dir")"

	while IFS= read -r line; do
		local attrs rel_path
		attrs=$(echo "$line" | awk '{print $1}')
		rel_path=$(echo "$line" | awk '{print $2}')

		[[ "${#attrs}" != 11 ]] && continue
		[ -z "$rel_path" ] && continue

		rel_path="${rel_path#home/}"

		local src_path="${src_dir}/${rel_path}"
		local dst_path="${dst_dir}/${rel_path}"
		local resolved_dst
		if [ -e "$dst_path" ]; then
			resolved_dst="$(realpath "$dst_path" 2>/dev/null)"
		else
			# new file: destination does not exist yet
			resolved_dst="/dev/null"
		fi
		[ -z "$resolved_dst" ] && resolved_dst="$src_path"

		echo "${mod_name}|${src_path}|${resolved_dst}|${rel_path}|${attrs}"
	done < <(cf_status "$mod_dir" "$dst_dir")
}

cf_diff_main() {
	mapfile -t all_files < <(for_each_src_to_dst_mods_handle cf_diff)

	[ ${#all_files[@]} -eq 0 ] && echo "No content differences." && return 0

	# if command -v fzf &>/dev/null; then
	if false; then
		while true; do
			local selected
			# shellcheck disable=SC2016
			selected=$(printf '%s\n' "${all_files[@]}" | \
				awk -F'|' '{print $(NF-1) "\t" $0}' | \
				fzf --prompt "> diff > " \
					--with-nth='1' \
					--preview-window='right:60%,wrap' \
					--preview='
orig=$(echo {} | cut -f2-)
mod=$(echo "$orig" | cut -d"|" -f1)
src=$(echo "$orig" | cut -d"|" -f2)
dst=$(echo "$orig" | cut -d"|" -f3)
attrs=$(echo "$orig" | cut -d"|" -f5)
echo "mod: $mod"
echo "attrs: $attrs"
echo "src path: $src"
echo "dst path: $dst"
echo ""
echo "diff:"
diff -u "$src" "$dst" 2>/dev/null || {
[ ! -e "$src" ] && echo "(src missing)"
[ ! -e "$dst" ] && echo "(dst missing)"
}
					')
			[ -z "$selected" ] && break

			# extract original full line and show vimdiff
			local orig_line
			orig_line=$(printf '%s' "$selected" | cut -f2-)
			local src_path dst_path
			IFS="|" read -r _ src_path dst_path _ <<< "$orig_line"
			vimdiff "$src_path" "$dst_path"

			# remove from array (compare original full lines)
			local new_files=()
			for f in "${all_files[@]}"; do
				[ "$f" != "$orig_line" ] && new_files+=("$f")
			done
			all_files=("${new_files[@]}")
			[ ${#all_files[@]} -eq 0 ] && break
		done
	else
		for f in "${all_files[@]}"; do
			local mod_name src_path dst_path rel_path
			IFS="|" read -r mod_name src_path dst_path rel_path _ <<< "$f"
			echo "=== [${mod_name}] ${rel_path}"
			diff -u "$src_path" "$dst_path"
		done
	fi
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
src_check_permission() {
	local mods
	# mods=("$(find "${CF_MODS_DIR}" -maxdepth 1 -mindepth 1 -not -name '.*')")
	mapfile -t mods < <(find "${CF_MODS_DIR}" -maxdepth 1 -mindepth 1 -not -name '.*')
	local diffs
	diffs=$("${LIB_DIR}/diff-permission.pl" "${mods[@]}")
	if [ -n "$diffs" ]; then
		echo "$(to_red "Permission diffs"):"
		echo "$diffs"
		return 1
	fi

	to_green "No permission diffs"
	return 0
}
src_check() {
	src_check_file_dup
	src_check_permission
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
diff)
	cf_diff_main
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
