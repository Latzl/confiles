CF_DIR="${HOME}/.confiles"
CF_MODS_DIR="${CF_DIR}/mods"
CF_CACHE_DIR="${CF_DIR}/.cache"

cf_mod_platform_suffix() {
	echo "platforms/${DST_OS}/${DST_ARCH}"
}