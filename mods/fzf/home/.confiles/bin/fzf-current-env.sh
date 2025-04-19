#!/bin/bash

env | \
awk -F= '{print $1 "\t" $0}' | \
fzf --delimiter=$'\t' --with-nth=1 --preview="echo {2} | cut -d= -f2-" --preview-window="bottom:30%" | \
cut -d= -f2-