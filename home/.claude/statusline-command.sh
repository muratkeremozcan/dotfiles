#!/usr/bin/env bash

input=$(cat)

# model + reasoning indicator
model_id=$(echo "$input" | jq -r '.model.id // empty')
model_name=$(echo "$input" | jq -r '.model.display_name // empty')
if echo "$model_id" | grep -qi "thinking\|reasoning"; then
  model_with_reasoning="${model_name} (reasoning)"
else
  model_with_reasoning="${model_name}"
fi

# context remaining
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# session cost + duration (may be absent depending on CC version)
session_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
duration_fmt=""
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
  duration_min=$(( duration_ms / 60000 ))
  if [ "$duration_min" -ge 60 ]; then
    duration_fmt="$(( duration_min / 60 ))h$(( duration_min % 60 ))m"
  elif [ "$duration_min" -gt 0 ]; then
    duration_fmt="${duration_min}m"
  fi
fi

# today's total cost - cached 60s to avoid scanning all JSONL files every refresh
today=$(date +%Y-%m-%d)
cache_file="/tmp/claude_today_cost_${today}.cache"
cache_ttl=60
now=$(date +%s)
today_cost=""

if [ -f "$cache_file" ]; then
  cache_age=$(( now - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))
  [ "$cache_age" -lt "$cache_ttl" ] && today_cost=$(cat "$cache_file")
fi

if [ -z "$today_cost" ]; then
  jsonl_files=$(find ~/.claude/projects -name '*.jsonl' 2>/dev/null)
  if [ -n "$jsonl_files" ]; then
    today_cost=$(echo "$jsonl_files" | xargs cat 2>/dev/null \
      | jq -rs "[.[] | select((.timestamp // \"\") | startswith(\"${today}\")) | .costUSD // 0] | add // 0" 2>/dev/null \
      | awk '{if($1>0) printf "%.4f", $1}')
  fi
  echo -n "${today_cost}" > "$cache_file"
fi

# five-hour rate limit
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

# build status line
parts=()
[ -n "$model_with_reasoning" ] && parts+=("$(printf '\033[0;36m%s\033[0m' "$model_with_reasoning")")
[ -n "$remaining" ]            && parts+=("$(printf '\033[0;32mctx-left:%.0f%%\033[0m' "$remaining")")
[ -n "$duration_fmt" ]         && parts+=("$(printf '\033[0;37m%s\033[0m' "$duration_fmt")")
[ -n "$session_cost" ]         && parts+=("$(printf '\033[0;33msession:$%.4f\033[0m' "$session_cost")")
[ -n "$today_cost" ]           && parts+=("$(printf '\033[0;33mtoday:$%.4f\033[0m' "$today_cost")")
[ -n "$five_pct" ]             && parts+=("$(printf '\033[0;31m5h-used:%.0f%%\033[0m' "$five_pct")")

( IFS='|'; printf '%s\n' "${parts[*]}" )
