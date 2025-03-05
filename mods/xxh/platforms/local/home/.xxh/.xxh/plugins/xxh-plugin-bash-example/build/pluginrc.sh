#!/bin/bash
CURR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ $XXH_VERBOSE == '2' ]]; then
  echo 'Load xxh-plugin-bash-example'
fi

_ltz-xxh-bash-example(){
	echo 'ltz-xxh-bash-example'
}
