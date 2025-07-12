CF_BIN_DIR=${CF_DIR}/bin
mkdir -p "${CF_BIN_DIR}"

CF_PROJ_BIN_DIR="${CURR_DIR}/bin"
# confiles.sh
if [ -d "$CF_PROJ_BIN_DIR" ]; then
	ln -svf "${CF_PROJ_BIN_DIR}/confiles.sh" "${CF_BIN_DIR}/"
	ln -svf "${CF_PROJ_BIN_DIR}/lib/confiles" "${CF_BIN_DIR}/lib/"
fi