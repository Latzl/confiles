#!/bin/bash
# remove all confiles this mod contains

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
DST_UNAME=$(uname -sm)
DST_OS="$(awk '{print $1}' <<<$DST_UNAME)"
DST_ARCH="$(awk '{print $2}' <<<$DST_UNAME)"
CF_MOD_DIR="$CURR_DIR"
CF_MOD_PLATFORM_DIR="$CURR_DIR/platforms/${DST_OS}/${DST_ARCH}"

do_remove() {
	local mod_dir="$1"
	local prefix="$2"
	if ! [ -d "$mod_dir" ]; then
		return 0
	fi
	if ! [ -n "$prefix" ]; then
		return 1
	fi
	{
		cd "$mod_dir"
		for file in $(find . -type f); do
			rm -rv "$prefix/$file"
		done
		for dir in $(find . -type d); do
			local real_dir=$(realpath -m $prefix/$dir)
			if [ -d "$real_dir" ] && [ ! -n "$(ls -A $real_dir)" ]; then
				rm -rv "$real_dir"
			fi
		done
	}
}

remove_home() {
	do_remove "$CF_MOD_DIR/home" "$HOME"
}

remove_platform() {
	do_remove "$CF_MOD_PLATFORM_DIR/home" "$HOME"
}

remove_home
remove_platform
