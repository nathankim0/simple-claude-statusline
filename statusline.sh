#!/bin/sh
# simple-claude-statusline
# Shows model, current workspace, and progress bars for context/rate limits.
#
# Usage (settings.json):
#   "statusLine": {
#     "type": "command",
#     "command": "bash /path/to/statusline.sh"
#   }

input=$(cat)

# Constants
BAR_WIDTH=10
FILLED_CHAR="█"
EMPTY_CHAR="░"

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build ASCII progress bar: make_bar <percentage_float>
make_bar() {
  pct="$1"
  filled=$(awk "BEGIN {printf \"%.0f\", $pct * $BAR_WIDTH / 100}")
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  [ "$filled" -gt "$BAR_WIDTH" ] 2>/dev/null && filled=$BAR_WIDTH
  empty=$((BAR_WIDTH - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do
    bar="${bar}${FILLED_CHAR}"
    i=$((i + 1))
  done
  i=0
  while [ "$i" -lt "$empty" ]; do
    bar="${bar}${EMPTY_CHAR}"
    i=$((i + 1))
  done
  echo "$bar"
}

# Git branch + dirty indicator
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$dirty" ]; then
    git_info=" [$branch*]"
  else
    git_info=" [$branch]"
  fi
fi

# Model + full PWD + git
parts="$model | $cwd$git_info"

# Context window usage
if [ -n "$used_pct" ]; then
  ctx=$(printf "%.0f" "$used_pct")
  bar=$(make_bar "$used_pct")
  parts="$parts | ctx:[${bar}] ${ctx}%"
fi

# 5-hour rate limit
if [ -n "$five_pct" ]; then
  five=$(printf "%.0f" "$five_pct")
  bar=$(make_bar "$five_pct")
  parts="$parts | 5h:[${bar}] ${five}%"
fi

# 7-day rate limit
if [ -n "$week_pct" ]; then
  week=$(printf "%.0f" "$week_pct")
  bar=$(make_bar "$week_pct")
  parts="$parts | 7d:[${bar}] ${week}%"
fi

echo "$parts"
