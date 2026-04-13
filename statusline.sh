#!/bin/sh
# simple-claude-statusline
# Compact status line: model, workspace, git, session lines, context/rate limits with progress bars.
#
# Usage (settings.json):
#   "statusLine": {
#     "type": "command",
#     "command": "bash /path/to/statusline.sh"
#   }

input=$(cat)

# Constants
BAR_WIDTH=6
FILLED_CHAR="█"
EMPTY_CHAR="░"
SEP=" · "

# Build ASCII progress bar: make_bar <percentage_float>
make_bar() {
  pct="$1"
  filled=$(awk "BEGIN {printf \"%.0f\", $pct * $BAR_WIDTH / 100}")
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  [ "$filled" -gt "$BAR_WIDTH" ] 2>/dev/null && filled=$BAR_WIDTH
  empty=$((BAR_WIDTH - filled))
  bar=""
  i=0
  while [ "$i" -lt "$filled" ]; do bar="${bar}${FILLED_CHAR}"; i=$((i+1)); done
  i=0
  while [ "$i" -lt "$empty" ]; do bar="${bar}${EMPTY_CHAR}"; i=$((i+1)); done
  echo "$bar"
}

# Format seconds until reset: 3700 → "1h2m", 150 → "2m"
fmt_reset() {
  now=$(date +%s)
  resets_at="$1"
  diff=$((resets_at - now))
  [ "$diff" -le 0 ] && return
  h=$((diff / 3600))
  m=$(( (diff % 3600) / 60 ))
  if [ "$h" -gt 0 ]; then
    echo "${h}h${m}m"
  else
    echo "${m}m"
  fi
}

# ── Parse JSON ──────────────────────────────────────────────────
model_raw=$(echo "$input" | jq -r '.model.display_name // .model // "Unknown"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

used_pct=$(echo "$input"  | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input"  | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
lines_add=$(echo "$input"  | jq -r '.cost.total_lines_added // empty')
lines_del=$(echo "$input"  | jq -r '.cost.total_lines_removed // empty')
vim_mode=$(echo "$input"   | jq -r '.vim.mode // empty')
worktree=$(echo "$input"   | jq -r '.worktree.name // empty')

# ── Model: strip "Claude " prefix for compactness ───────────────
model=$(echo "$model_raw" | sed 's/^Claude //')

# ── Path: abbreviate $HOME to ~ ─────────────────────────────────
home_esc=$(echo "$HOME" | sed 's|/|\\/|g')
short_cwd=$(echo "$cwd" | sed "s|^$HOME|~|")

# ── Git: branch + dirty indicator ───────────────────────────────
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  [ -n "$dirty" ] && git_info=" [${branch}*]" || git_info=" [${branch}]"
fi

# Worktree overrides git_info when active
if [ -n "$worktree" ]; then
  git_info=" {${worktree}}"
fi

# ── Vim mode ─────────────────────────────────────────────────────
vim_part=""
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    NORMAL)  vim_part="N" ;;
    INSERT)  vim_part="I" ;;
    VISUAL)  vim_part="V" ;;
    REPLACE) vim_part="R" ;;
    *)       vim_part="$vim_mode" ;;
  esac
  vim_part="${SEP}vim:${vim_part}"
fi

# ── Build output ─────────────────────────────────────────────────
parts="${model}${SEP}${short_cwd}${git_info}"

# Lines added/removed
if [ -n "$lines_add" ] || [ -n "$lines_del" ]; then
  add=${lines_add:-0}
  del=${lines_del:-0}
  parts="${parts}${SEP}+${add} -${del}"
fi

# Vim mode
parts="${parts}${vim_part}"

# Context window
if [ -n "$used_pct" ]; then
  ctx=$(printf "%.0f" "$used_pct")
  bar=$(make_bar "$used_pct")
  parts="${parts}${SEP}ctx:${bar} ${ctx}%"
fi

# 5-hour rate limit + reset timer
if [ -n "$five_pct" ]; then
  five=$(printf "%.0f" "$five_pct")
  bar=$(make_bar "$five_pct")
  reset_str=""
  if [ -n "$five_reset" ]; then
    t=$(fmt_reset "$five_reset")
    [ -n "$t" ] && reset_str=" ↺${t}"
  fi
  parts="${parts}${SEP}5h:${bar} ${five}%${reset_str}"
fi

# 7-day rate limit + reset timer
if [ -n "$week_pct" ]; then
  week=$(printf "%.0f" "$week_pct")
  bar=$(make_bar "$week_pct")
  reset_str=""
  if [ -n "$week_reset" ]; then
    t=$(fmt_reset "$week_reset")
    [ -n "$t" ] && reset_str=" ↺${t}"
  fi
  parts="${parts}${SEP}7d:${bar} ${week}%${reset_str}"
fi

echo "$parts"
