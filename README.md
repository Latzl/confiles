# confiles

con(sistence)files for cross-platform like dotfiles, rather than just con(fig)files

# Modules

Module name is directory name in `mods/`, except that starts with `.`.

## make custom module

Copy `mods/.template` to `mods/<module_name>`, or `~/.confiles/mods/`, as former need tu run `install.sh` to install to `~/.confiles/mods/`. Put your confiles into `mods/<module_name>/home/`.

For binary files, put them into `mods/<module_name>/platforms/<kernel>/<arch>/home/.confiles/bin`.

It's not enough to just using `<kernel>/<arch>` to specify each platform. A bash script named `more-platforms.bash` can be supplied in `mods/<module_name>/platforms/` to specify more platforms by implementing function `more_platforms_check_dst_cmd()` and `more_platforms_get_src_mod_dir()`. See `mods/.template/platforms/more-platforms.bash`.

# Usage

## Install modules

Run `install.sh` to install add modules from `mods/`

See `install.sh -h` for usage

## Sync

Use `confiles.sh` implemented by rsync to sync files.

See `confiles.sh -h` for usage.

# Binary files

This reporsitory not supply binary files. Make your own module with binary file locally and put it to `~/.confiles/mods/`

