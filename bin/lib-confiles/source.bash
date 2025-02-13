CF_RDIR=".confiles"
CF_MODS_RDIR="${CF_RDIR}/mods"
CF_MODS_DIR="${HOME}/${CF_MODS_RDIR}"
CF_CACHE_RDIR="${CF_RDIR}/.cache"
CF_CACHE_DIR="${HOME}/${CF_CACHE_RDIR}"

cf_mod_platform_suffix() {
	echo "platforms/${DST_OS}/${DST_ARCH}"
}