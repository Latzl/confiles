if [ ! -n "$BASH_VERSION" ]; then
	return
fi

if [ -d "$HOME/.bash_profile.d" ]; then
	for profile in $HOME/.bash_profile.d/*; do
		source $profile
	done
fi

if [ -f "$HOME/.bashrc" ]; then
	source $HOME/.bashrc
fi
