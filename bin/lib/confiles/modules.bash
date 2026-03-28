# module discovery helpers
# All functions output results to stdout; caller decides how to collect them.

# Returns all module basenames from CF_MODS_DIR, one per line
list_all_mod_names() {
	cd "${CF_MODS_DIR}" && find ./* -maxdepth 0 -exec basename {} \;
}

# $1: comma-separated mod names → prints matching mod paths to stdout
filter_mods_include() {
	local mods_csv="$1"
	readarray -td, mods < <(printf "%s" "$mods_csv")
	for mod in "${mods[@]}"; do
		local mod_path="${CF_MODS_DIR}/${mod}"
		if [ -d "$mod_path" ]; then
			echo "$mod_path"
		fi
	done
}

# $1: comma-separated mod names to exclude → prints remaining mod paths to stdout
filter_mods_exclude() {
	local exclude_csv="$1"
	local exclude_list="${exclude_csv//,/$'\n'}"
	readarray -t all_mods < <(list_all_mod_names)
	for mod in "${all_mods[@]}"; do
		if ! grep -q "^${mod}$" <<<"$exclude_list"; then
			echo "${CF_MODS_DIR}/${mod}"
		fi
	done
}
