#!/bin/bash

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
MOD_NAME="$(basename "$CURR_DIR")"
source "$CURR_DIR/../../cf-base.sh"

mkdir -p ~/bin
# install ${CURR_DIR}/confiles.sh ~/.confiles/bin/
ln -svf "${CURR_DIR}/confiles.sh" ~/.confiles/bin/
