escape_single_quote() {
	echo "${1//\'/\\\'}"
}
