# confiles

con(sistence)files for cross-platform like dotfiles, rather than just con(fig)files

# Usage

## Install

Install all mods: `cd mods/; ./cf-install-all.sh`, or install specify mod: `cd mods/<mod_name>/; ./cf-install.sh`.

## Sync

Using rsync to sync files.

`confiles.sh {ACTION} [dst_dir]`

ACTION:
* status: show difference between src and dst
* apply: sync files to dst
* src_check: check if src contain duplicate files 

The option dst_dir can be remote directory with format follow rsync's. If dst_dir not specified, `~` will be used as default.

# Binary files

This reporsitory not supply binary files. Make your mod with binary file locally and put it to `~/.confiles/mods/`

