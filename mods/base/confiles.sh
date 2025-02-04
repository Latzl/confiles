#!/bin/bash

if ! which rsync &>/dev/null; then
	echo "rsync not found, required" >&2
	exit 1
fi

get_usage() {
	echo "Usage: $0 {status|apply|src_check} [--verbose|-v] [dst_dir]"
}

OPT_VERBOSE=false

ARGS="$(getopt -l verbose -o v -- "$@")"
if [ $? -ne 0 ]; then
	echo "$(get_usage)" >&2
	exit 1
fi

eval set -- "$ARGS"

while true; do
	case "$1" in
	-v | --verbose)
		OPT_VERBOSE=true
		shift
		;;
	--)
		shift
		break
		;;
	*)
		echo "Internal error: getopt problem" >&2
		exit 1
		;;
	esac
done

# static vars

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_MODS_DIR="${HOME}/.confiles/mods"

DST_DIR_PROVIDED=''
DST_DIR=''
IS_DST_REMOTE=false
DST_HOST=''
DST_UNAME=''
DST_OS=''
DST_ARCH=''

if [ -n "$2" ]; then
	DST_DIR_PROVIDED=true
else
	DST_DIR_PROVIDED=false
fi

if $DST_DIR_PROVIDED; then
	DST_DIR="$2"
else
	DST_DIR="$HOME"
fi

if grep -q ":" <<<"$DST_DIR"; then
	IS_DST_REMOTE=true
else
	IS_DST_REMOTE=false
fi

if $IS_DST_REMOTE; then
	DST_HOST="$(cut -d: -f1 <<<"$DST_DIR")"
else
	DST_HOST="$HOSTNAME"
fi

if $DST_DIR_PROVIDED; then
	if $IS_DST_REMOTE; then
		DST_UNAME=$(ssh $DST_HOST 'uname -sm')
	else
		DST_UNAME=$(uname -sm)
	fi
else
	DST_UNAME=$(uname -sm)
fi

DST_OS="$(awk '{print $1}' <<<$DST_UNAME)"
DST_ARCH="$(awk '{print $2}' <<<$DST_UNAME)"

# print infos
if $OPT_VERBOSE; then
	echo "DST_DIR=$DST_DIR"
	echo "DST_UNAME=$DST_UNAME"
	echo "DST_OS=$DST_OS"
	echo "DST_ARCH=$DST_ARCH"
fi

# fuctions

colorize() {
	local text="$1"
	local color="$2"

	case "$color" in
	black) echo -e "\033[0;30m$text\033[0m" ;;
	red) echo -e "\033[0;31m$text\033[0m" ;;
	green) echo -e "\033[0;32m$text\033[0m" ;;
	yellow) echo -e "\033[0;33m$text\033[0m" ;;
	blue) echo -e "\033[0;34m$text\033[0m" ;;
	magenta) echo -e "\033[0;35m$text\033[0m" ;;
	cyan) echo -e "\033[0;36m$text\033[0m" ;;
	white) echo -e "\033[0;37m$text\033[0m" ;;
	*) echo "$text" ;;
	esac
}

to_red() {
	echo "$(colorize "$1" red)"
}
to_green() {
	echo "$(colorize "$1" green)"
}

get_mod_platform_dir() {
	echo "$1/platforms/${DST_OS}/${DST_ARCH}"
}

cf_status() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	local dst_dir="$2"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	if ! [ -n "$dst_dir" ]; then
		dst_dir="$HOME"
	fi

	rsync -avzO --no-o --no-g --info=FLIST0,STATS0 -ni "${src_dir}/" "${dst_dir}/"
}

cf_apply() {
	local mod_dir="$1"
	local src_dir="$mod_dir/home"
	local dst_dir="$2"
	if ! [ -d "$src_dir" ]; then
		return 1
	fi
	if ! [ -n "$dst_dir" ]; then
		dst_dir="$HOME"
	fi

	rsync -avzO --no-o --no-g --info=FLIST0,STATS0 "${src_dir}/" "${dst_dir}/"
}

status_all() {
	local dst_dir="$1"
	local content=''
	for mod_dir in "${SRC_MODS_DIR}/"*; do
		content="$(cf_status "$mod_dir" "$dst_dir")"
		if [ -n "$content" ] || $OPT_VERBOSE; then
			echo ">>> $mod_dir"
		fi
		if [ -n "$content" ]; then
			echo "$content"
		fi

		# platform
		local mod_platform_dir="$(get_mod_platform_dir "$mod_dir")"
		if [ -d "$mod_platform_dir" ]; then
			content="$(cf_status "$mod_platform_dir" "$dst_dir")"
			if [ -n "$content" ] || $OPT_VERBOSE; then
				echo ">>> $mod_platform_dir"
			fi
			if [ -n "$content" ]; then
				echo "$content"
			fi
		fi
	done
}

apply_all() {
	local dst_dir="$1"
	local content=''
	for mod_dir in "${SRC_MODS_DIR}/"*; do
		content="$(cf_apply "$mod_dir" "$dst_dir")"
		if [ -n "$content" ] || $OPT_VERBOSE; then
			echo ">>> $mod_dir"
		fi
		if [ -n "$content" ]; then
			echo "$content"
		fi

		# platform
		local mod_platform_dir="$(get_mod_platform_dir "$mod_dir")"
		if [ -d "$mod_platform_dir" ]; then
			content="$(cf_apply "$mod_platform_dir" "$dst_dir")"
			if [ -n "$content" ] || $OPT_VERBOSE; then
				echo ">>> $mod_platform_dir"
			fi
			if [ -n "$content" ]; then
				echo "$content"
			fi
		fi
	done
}

# check if files duplicate
src_check_file_dup() {
	local list="$(
		cd "${SRC_MODS_DIR}"
		find -L . -type f -printf "%P\n" | grep -P '^[^/]*/(Linux|home)'
	)"

	local duplicated="$(
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
		echo "$(to_green "No duplicated files")"
		return 0
	fi
}
src_check() {
	src_check_file_dup
}

# main
case "$1" in
status)
	status_all "$2"
	;;
apply)
	apply_all "$2"
	;;
src_check)
	src_check
	;;
*)
	echo "$(get_usage)" >&2
	exit 1
	;;
esac

exit 0
