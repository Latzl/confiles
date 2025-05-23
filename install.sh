#!/bin/bash

if ! which rsync &>/dev/null; then
	echo "rsync not found, required" >&2
	exit 1
fi

OPT_ALL=false
OPT_DEBUG=false

get_usage() {
	local this_sh='install.sh'
	cat <<_USAGE_EOF_
Usage: $this_sh [OPTIONS] [modules...]
OPTIONS:
	-a, --all	Install all modules
	-h, --help	Show this help message and exit
	--debug		Enable debug mode

module name is directory name in mods/, except that starts with '.'
_USAGE_EOF_
}

ARGS="$(getopt -l all,help,debug -o a,h -- "$@")" || {
	get_usage >&2
	exit 1
}

eval set -- "$ARGS"

while true; do
	case "$1" in
	-a | --all)
		OPT_ALL=true
		shift
		;;
	-h | --help)
		get_usage >&2
		exit 0
		;;
	--debug)
		OPT_DEBUG=true
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

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CF_PROJ_MODS_DIR="${CURR_DIR}/mods"

CF_DIR=${HOME}/.confiles
CF_MODS_DIR=${CF_DIR}/mods
mkdir -p "${CF_MODS_DIR}"

modules=()
if [ "$OPT_ALL" = false ]; then
	modules=("$@")
else
	readarray -t modules < <(find "${CF_PROJ_MODS_DIR}/"* -maxdepth 0 -type d -exec basename {} \;)
fi

if [ "$OPT_ALL" = false ] && [ ${#modules[@]} -eq 0 ]; then
	echo "No modules specified" >&2
	exit 1
fi

if [ "$OPT_DEBUG" = true ]; then
	echo "CF_PROJ_MODS_DIR: ${CF_PROJ_MODS_DIR}"
	echo "CF_DIR: ${CF_DIR}"
	echo "CF_MODS_DIR: ${CF_MODS_DIR}"
	echo "modules: ${modules[*]}"
fi

# modules
for mod in "${modules[@]}"; do
	proj_mod_dir="${CF_PROJ_MODS_DIR}/${mod}"
	dst_mod_dir="${CF_MODS_DIR}/${mod}"
	if ! [ -d "$proj_mod_dir" ]; then
		echo "Module ${mod} not found in ${CF_PROJ_MODS_DIR}" >&2
		continue
	fi
	if [ -d "$dst_mod_dir" ]; then
		rm "$dst_mod_dir"
	fi
	ln -sv "$proj_mod_dir" "$dst_mod_dir"
done

[ -f "$CURR_DIR/install-origin.bash" ] && source "$CURR_DIR/install-origin.bash"
