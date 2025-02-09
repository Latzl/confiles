# confiles

con(sistence)files for cross-platform like dotfiles, rather than just con(fig)files

# Modules

Module name is directory name in `mods/`, except that starts with `.`.

## make custom module

Copy `mods/.template` to `mods/<module_name>`, or `~/.confiles/mods/`, as former need tu run `install.sh` to install to `~/.confiles/mods/`. Put your confiles into `mods/<module_name>/home/`.

For binary files, put them into `mods/<module_name>/platforms/<kernel>/<arch>/home/.confiles/bin`.

# Usage

## Install modules

Run `install.sh` to install add modules from `mods/`

See `install.sh -h` for usage

## Sync

Use `confiles.sh` implemented by rsync to sync files.

See `confiles.sh -h` for usage.

# Binary files

This reporsitory not supply binary files. Make your own module with binary file locally and put it to `~/.confiles/mods/`

