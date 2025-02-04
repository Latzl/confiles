if ! [ -n "$MOD_NAME" ]; then
	echo "MOD_NAME not set" >&2
	exit 1
fi

if ! which rsync &>/dev/null; then
	echo "rsync not found, required" >&2
	exit 1
fi

MOD_CF_DIR=${CURR_DIR}
MOD_CF_HOME=${MOD_CF_DIR}/home
CF_DIR=${HOME}/.confiles
CF_BIN_DIR=${CF_DIR}/bin
CF_MODS_DIR=${CF_DIR}/mods
mkdir -p "${CF_MODS_DIR}"
mkdir -p "${CF_BIN_DIR}"

CF_MOD_DIR=${CF_MODS_DIR}/${MOD_NAME}

if [ -d "${CF_MOD_DIR}" ]; then
	rm -r "${CF_MOD_DIR}"
fi
ln -svf "${MOD_CF_DIR}" "${CF_MOD_DIR}"
