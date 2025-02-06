_colorize() {
	local text="$1"
	local color="$2"

	case "$color" in
	black) echo -e "\033[0;30m$text\033[0m" ;;
	red) echo -e "\033[0;31m$text\033[0m" ;;
	green) echo -e "\033[0;32m$text\033[0m" ;;
	yellow) echo -e "\033[0;33m$text\033[0m" ;;
	blue) echo -e "\033[0;34m$text\033[0m" ;;
	magenta) echo -e "\033[0;35m$text\033[0m" ;;
	cyan) echo -e "\033[0;36m$text\033[0m" ;;
	white) echo -e "\033[0;37m$text\033[0m" ;;
	*) echo "$text" ;;
	esac
}

_to_red() {
	_colorize "$1" red
}
_to_green() {
	_colorize "$1" green
}
