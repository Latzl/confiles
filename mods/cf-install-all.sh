#!/bin/bash

# This script will install all the mods in the mods folder

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for dir in "$CURR_DIR/"*; do
	if ! [ -d "$dir" ]; then
		continue
	fi
	echo "Installing $(basename "$dir")"
	eval "$dir/cf-install.sh"
done