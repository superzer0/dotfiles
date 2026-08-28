#!/usr/bin/env bash
# Claude Code status line script
export LC_ALL=C

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$dir" ] && dir=$(pwd)

model=$(echo "$input" | jq -r '.model.display_name // empty')

# "--" until the first response lands (remaining_percentage is null pre-first-turn)
ctx=$(echo "$input" | jq -r 'if .context_window.remaining_percentage == null then "--" else (.context_window.remaining_percentage | round | tostring) end')

# cost field name isn't confirmed from here; try both shapes, default to 0
cost=$(echo "$input" | jq -r '(.cost.total_cost_usd // .total_cost_usd // 0)')
cost_fmt=$(printf '%.2f' "$cost")

five=$(echo "$input" | jq -r 'if .rate_limits.five_hour then (100 - .rate_limits.five_hour.used_percentage | round | tostring) else empty end')
week=$(echo "$input" | jq -r 'if .rate_limits.seven_day then (100 - .rate_limits.seven_day.used_percentage | round | tostring) else empty end')

session_id=$(echo "$input" | jq -r '.session_id // empty')

# ANSI-C quoting: escapes become real bytes now, so a literal backslash in
# $dir (e.g. a Windows-style path) can't be swallowed by printf later.
RESET=$'\033[0m'
CYAN=$'\033[1;96m'      # bold bright cyan
BOLD=$'\033[1;97m'      # bold bright white (was dim)
MAGENTA=$'\033[1;95m'   # bold bright magenta
YELLOW=$'\033[1;93m'    # bold bright yellow
RED=$'\033[1;91m'       # bold bright red (dirty / <10% remaining)
ORANGE=$'\033[1;38;5;208m'  # bold bright orange, 10-24% remaining
BRGREEN=$'\033[1;92m'   # bold bright green, >=25% remaining
GREEN=$'\033[0;32m'     # subtle green (clean)
DIM=$'\033[2m'          # dim separator, not another bright color
SEP=" ${DIM}│${RESET} "

# threshold coloring for a remaining-percentage value; $1=value ("--" or int),
# $2=color to use when there's no data (null case stays neutral, not red)
pct_color() {
  local v="$1" neutral="$2"
  if [ "$v" = "--" ] || [ -z "$v" ]; then
    echo "$neutral"
  elif [ "$v" -lt 10 ]; then
    echo "$RED"
  elif [ "$v" -lt 25 ]; then
    echo "$ORANGE"
  else
    echo "$BRGREEN"
  fi
}

line="$dir"
[ -n "$model" ] && line="$line${SEP}${CYAN}${model}${RESET}"
line="$line${SEP}$(pct_color "$ctx" "$BOLD")ctx:${ctx}%${RESET}"
line="$line${SEP}${BOLD}\$${cost_fmt}${RESET}"
[ -n "$five" ] && line="$line${SEP}$(pct_color "$five" "$MAGENTA")5h:${five}%${RESET}"
[ -n "$week" ] && line="$line${SEP}$(pct_color "$week" "$MAGENTA")7d:${week}%${RESET}"
[ -n "$session_id" ] && line="$line${SEP}${YELLOW}id:${session_id}${RESET}"

# git dirty marker: single call, skips optional locks; non-zero exit
# (not a repo, missing dir, etc.) just omits the marker, never hangs.
git_status=$(git --no-optional-locks -C "$dir" status --porcelain 2>/dev/null)
if [ $? -eq 0 ]; then
  if [ -n "$git_status" ]; then
    line="$line${SEP}${RED}✗${RESET}"
  else
    line="$line${SEP}${GREEN}✓${RESET}"
  fi
fi

printf '%s\n' "$line"
