#!/bin/bash

get_usage() {
    cat <<_USAGE_EOF_
local_info search with text. The environment variable LIF_SEARCH_DIRS is used to search for files.
Usage: lif-search-text.bash {pattern} [rg options] [extra search dir]
_USAGE_EOF_
}

if [ $# -lt 1 ]; then
    get_usage
    exit 1
fi

if [ -z "$LIF_SEARCH_DIRS" ]; then
    echo "LIF_SEARCH_DIRS is not set"
    exit 1
fi

rg_pattern="$1"
shift

# if found -h in args
if [[ "$*" =~ "-h" ]]; then
    get_usage
    exit 0
fi

readarray -d '' -t lif_search_dirs < <(
    perl -e '
        $path = $ENV{"LIF_SEARCH_DIRS"};
        @parts = grep { $_ ne "" } split ":", $path;
        print join("\0", @parts) . "\0";
    '
)

# echo "with LIF_SEARCH_DIRS: $LIF_SEARCH_DIRS"
# echo "${#lif_search_dirs[@]}: ${lif_search_dirs[*]}"
# for dir in "${lif_search_dirs[@]}"; do
#     echo "Searching in $dir"
# done

rgthefiles "$rg_pattern" "${lif_search_dirs[@]}" "$@"
