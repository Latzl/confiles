#!/bin/bash
# Custom statusline for Claude Code
# Format: {user}@{hostname}:{current_work_path}
#         {model} [{used_token}/{total_token_win}]({used_percent}%)

input=$(cat)

# Extract values from JSON
user=$(whoami)
hostname=$(hostname)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name')
# Use current_usage.input_tokens for current context usage
used=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
total=$(echo "$input" | jq -r '.context_window.context_window_size')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Convert tokens to KB (bytes to KB: /1024, tokens are roughly similar)
used_kb=$(echo "$used" | awk '{printf "%.1f", $1/1024}')
total_kb=$(echo "$total" | awk '{printf "%.1f", $1/1024}')

# ANSI color codes
GREEN='\033[32m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

# First line: user@hostname:path (green for user@host, blue for path)
printf "${GREEN}%s@%s${RESET}:${BLUE}%s${RESET}\n" "$user" "$hostname" "$cwd"

# Second line: model [used/total](percent%) in yellow
if [ -n "$pct" ] && [ "$pct" != "null" ]; then
    printf "${YELLOW}%s [%sKB/%sKB](%.0f%%)${RESET}\n" "$model" "$used_kb" "$total_kb" "$pct"
else
    printf "${YELLOW}%s [0KB/%sKB](0%%)${RESET}\n" "$model" "$total_kb"
fi
