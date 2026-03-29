#!/bin/bash
# always show balloon if claude complete, asking questions or permissions
# Usage: notify.sh "notification message"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/notify.ps1" "$1" &
