#!/bin/sh
# simple-claude-statusline
# Compact, readable Claude Code status line.
#
# Usage (settings.json):
#   "statusLine": {
#     "type": "command",
#     "command": "bash /path/to/statusline.sh"
#   }

input=$(cat)

SEP=" | "

# ── Time formatting ───────────────────────────────────────────────
# <1h: "23m"  |  <24h: "2h16m"  |  >=24h: "4d6h"
fmt_duration() {
  secs="$1"
  [ "$secs" -le 0 ] 2>/dev/null && return
  if [ "$secs" -ge 86400 ]; then
    d=$((secs / 86400))
    h=$(( (secs % 86400) / 3600 ))
    [ "$h" -gt 0 ] && echo "${d}d${h}h" || echo "${d}d"
  elif [ "$secs" -ge 3600 ]; then
    h=$((secs / 3600))
    m=$(( (secs % 3600) / 60 ))
    [ "$m" -gt 0 ] && echo "${h}h${m}m" || echo "${h}h"
  else
    m=$((secs / 60))
    echo "${m}m"
  fi
}

fmt_reset() {
  [ -z "$1" ] && return
  diff=$(( $1 - $(date +%s) ))
  fmt_duration "$diff"
}

# ── Parse JSON ────────────────────────────────────────────────────
model_raw=$(echo "$input" | jq -r '.model.display_name // .model // "Unknown"')
cwd=$(echo "$input"       | jq -r '.workspace.current_dir // .cwd // ""')

used_pct=$(echo "$input"   | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
lines_add=$(echo "$input"  | jq -r '.cost.total_lines_added // empty')
lines_del=$(echo "$input"  | jq -r '.cost.total_lines_removed // empty')
vim_mode=$(echo "$input"   | jq -r '.vim.mode // empty')
worktree=$(echo "$input"   | jq -r '.worktree.name // empty')

# ── Model: strip "Claude " prefix ────────────────────────────────
model=$(echo "$model_raw" | sed 's/^Claude //')

# ── Workspace: git root name > cwd basename ───────────────────────
git_suffix=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  workspace=$(basename "$git_root")
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null)
  [ -n "$dirty" ] && git_suffix=" [${branch}*]" || git_suffix=" [${branch}]"
elif [ -n "$cwd" ]; then
  [ "$cwd" = "$HOME" ] && workspace="~" || workspace=$(basename "$cwd")
fi

# Worktree: append worktree name in braces
[ -n "$worktree" ] && git_suffix="${git_suffix} {${worktree}}"

# ── Build output ──────────────────────────────────────────────────
parts="${model}${SEP}${workspace}${git_suffix}"

# Lines changed (only when non-zero)
if [ -n "$lines_add" ] || [ -n "$lines_del" ]; then
  add=${lines_add:-0}
  del=${lines_del:-0}
  if [ "$add" -gt 0 ] || [ "$del" -gt 0 ]; then
    parts="${parts}${SEP}+${add} -${del}"
  fi
fi

# Vim mode (only when not NORMAL to reduce noise)
if [ -n "$vim_mode" ] && [ "$vim_mode" != "NORMAL" ]; then
  case "$vim_mode" in
    INSERT)  v="INS" ;;
    VISUAL)  v="VIS" ;;
    REPLACE) v="REP" ;;
    *)       v="$vim_mode" ;;
  esac
  parts="${parts}${SEP}-- ${v} --"
fi

# Context window
if [ -n "$used_pct" ]; then
  ctx=$(printf "%.0f" "$used_pct")
  parts="${parts}${SEP}ctx:${ctx}%"
fi

# 5-hour rate limit
if [ -n "$five_pct" ]; then
  five=$(printf "%.0f" "$five_pct")
  reset_str=""
  t=$(fmt_reset "$five_reset")
  [ -n "$t" ] && reset_str=" ⏳ ${t}"
  parts="${parts}${SEP}5h:${five}%${reset_str}"
fi

# 7-day rate limit
if [ -n "$week_pct" ]; then
  week=$(printf "%.0f" "$week_pct")
  reset_str=""
  t=$(fmt_reset "$week_reset")
  [ -n "$t" ] && reset_str=" ⏳ ${t}"
  parts="${parts}${SEP}7d:${week}%${reset_str}"
fi

echo "$parts"
