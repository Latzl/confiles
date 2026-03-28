#!/bin/bash
# Show Windows notification if foreground window is NOT Windows Terminal
# Usage: should_notify.sh "notification message"

msg="${1:-Claude Code needs your attention}"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME/.claude/scripts/notify.ps1" "$msg"
