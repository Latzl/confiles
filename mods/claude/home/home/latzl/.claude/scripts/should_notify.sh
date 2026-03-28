#!/bin/bash
# Check foreground window, then show balloon if needed
# Usage: should_notify.sh "notification message"

result=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/should_check.ps1")

if [ "$result" = "notify" ]; then
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/notify.ps1" "$1" &
fi
