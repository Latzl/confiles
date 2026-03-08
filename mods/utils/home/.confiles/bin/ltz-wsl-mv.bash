#!/usr/bin/env bash
get_usage() {
    cat <<EOF
# move files by win/wsl path, src/dst path can be win and unix path
Usage: $0 {mv args}
EOF
}

if ! which wslpath >/dev/null 2>&1; then
    echo "wslpath not found" >&2
    exit 1
fi

opt_debug=false
log_debug() {
    $opt_debug || return
    echo "$@" >&2
}

trans_to_wsl_path() {
    local src_path=$1
    wsl_path=$(wslpath "$src_path" 2>/dev/null)
    local ret=$?
    if [ $ret -eq 0 ]; then
        # wslpath exit 1 if src_path is not win path
        echo "$wsl_path"
        return
    else
        echo "$src_path"
        return
    fi
}

if [ $# -lt 2 ]; then
    get_usage >&2
    exit 1
fi

args=("$@")

for ((i = 0; i < ${#args[@]}; i++)); do
    log_debug "with arg: ${args[$i]}"
    [[ "${args[$i]}" == -* ]] && {
        continue
	}
	[[ "${args[$i]}" == /* ]] && {
        continue
	}
	[[ "${args[$i]}" == .* ]] && {
        continue
	}
    log_debug "to trans_to_wsl_path: ${args[$i]}"
    args[i]=$(trans_to_wsl_path "${args[$i]}")
    log_debug "trans_to_wsl_path done: ${args[$i]}"
done

mv "${args[@]}"
