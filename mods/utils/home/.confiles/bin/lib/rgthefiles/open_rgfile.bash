#!/bin/bash

get_usage() {
    cat <<_USAGE_EOF_
Usage: open_rgfile {pattern} {file_path} [rg options]
_USAGE_EOF_
}

if [ $# -lt 2 ]; then
    get_usage
    exit 1
fi

open_rgfile() {
    rg_result_path='/tmp/open_rgfile-rg_result.tmp'

    local rg_pattern="$1"
    local file_path="$2"
    shift 2
    local rg_opts=("$@")


    rg_result=$(rg "$rg_pattern" --vimgrep "$file_path" "${rg_opts[@]}")
    if [ "$?" -ne 0 ]; then
        echo "No match found"
        exit 1
    fi

    if [[ "$rg_result" == *$'\n'* ]]; then
        rg_result_multi=true
    else
        rg_result_multi=false
    fi

    echo "$rg_result" >$rg_result_path

    if [ "$rg_result_multi" = true ]; then
        vim +cw -q $rg_result_path
    else
        vim -q $rg_result_path
    fi

}

open_rgfile "$@"
