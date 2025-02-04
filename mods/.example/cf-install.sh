#!/bin/bash

CURR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOD_NAME="$(basename "$CURR_DIR")"
source "$CURR_DIR/../../cf-base.sh"
