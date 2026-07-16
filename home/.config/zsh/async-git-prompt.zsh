# Keep Starship's Git metrics fresh without running Git on the ZLE input path.
# A short-lived worker scans in the background. ZLE redraws only when the
# displayed branch or metrics change, preserving any command being typed.

[[ -o interactive ]] || return

zmodload zsh/sched
zmodload zsh/zle
autoload -Uz add-zsh-hook add-zle-hook-widget

if (( ! ${+__dotfiles_git_prompt_fd} )); then
  typeset -gi __dotfiles_git_prompt_fd=-1
fi
if (( ! ${+__dotfiles_git_prompt_signature} )); then
  typeset -g __dotfiles_git_prompt_signature=""
fi

typeset -gi __dotfiles_git_prompt_interval=2

__dotfiles_git_prompt_collect() {
  emulate -L zsh

  local cwd="$1"
  local status_output numstat_output line branch_signature added removed
  local -i files=0 additions=0 deletions=0

  status_output=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 command git -C "$cwd" status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null) || {
    print -r -- "$cwd"
    print -r -- "outside"
    print -r -- ""
    print -r -- "0"
    print -r -- "0"
    print -r -- "0"
    return
  }

  for line in "${(@f)status_output}"; do
    if [[ "$line" == "# branch."* ]]; then
      branch_signature+="$line"
    elif [[ -n "$line" ]]; then
      (( files++ ))
    fi
  done

  if (( files > 0 )); then
    # In a repo with no commits yet, HEAD doesn't resolve and `git diff HEAD`
    # fails (staged lines would show as +0). Diff against the empty tree so a
    # fresh repo still reports real additions. hash-object honors the repo's
    # object format (sha1 vs sha256).
    local base=HEAD
    command git -C "$cwd" rev-parse --verify -q HEAD >/dev/null 2>&1 || \
      base=$(command git -C "$cwd" hash-object -t tree /dev/null 2>/dev/null)
    numstat_output=$(LC_ALL=C GIT_OPTIONAL_LOCKS=0 command git -C "$cwd" diff --no-ext-diff "$base" --numstat 2>/dev/null)
    for line in "${(@f)numstat_output}"; do
      added="${line%%[[:space:]]*}"
      line="${line#*[[:space:]]}"
      removed="${line%%[[:space:]]*}"
      [[ "$added" == <-> ]] && (( additions += added ))
      [[ "$removed" == <-> ]] && (( deletions += removed ))
    done
  fi

  print -r -- "$cwd"
  print -r -- "repo"
  print -r -- "$branch_signature"
  print -r -- "$files"
  print -r -- "$additions"
  print -r -- "$deletions"
}

__dotfiles_git_prompt_close_worker() {
  emulate -L zsh

  local fd="${1:-$__dotfiles_git_prompt_fd}"
  if (( fd >= 0 )); then
    zle -F "$fd" 2>/dev/null
    exec {fd}<&-
  fi
  __dotfiles_git_prompt_fd=-1
}

__dotfiles_git_prompt_ready() {
  emulate -L zsh

  local fd="$1"
  local event="$2"
  local cwd state branch_signature files additions deletions

  if [[ -z "$event" ]]; then
    {
      IFS= read -r cwd
      IFS= read -r state
      IFS= read -r branch_signature
      IFS= read -r files
      IFS= read -r additions
      IFS= read -r deletions
    } <&"$fd"
  fi

  __dotfiles_git_prompt_close_worker "$fd"
  [[ -z "$event" && "$cwd" == "$PWD" ]] || return

  local signature="$cwd|$state|$branch_signature|$files|$additions|$deletions"
  [[ "$signature" == "$__dotfiles_git_prompt_signature" ]] && return
  __dotfiles_git_prompt_signature="$signature"

  if [[ "$state" == "repo" && "$files" == <-> && "$files" -gt 0 ]]; then
    export STARSHIP_ASYNC_GIT_FILES="$files"
    # Only surface +/- when non-zero. Untracked files count toward $files but
    # never appear in `git diff`, so without this an untracked-only tree shows
    # a misleading "+0 -0".
    if [[ "$additions" == <-> && "$additions" -gt 0 ]]; then
      export STARSHIP_ASYNC_GIT_ADDITIONS="$additions"
    else
      unset STARSHIP_ASYNC_GIT_ADDITIONS
    fi
    if [[ "$deletions" == <-> && "$deletions" -gt 0 ]]; then
      export STARSHIP_ASYNC_GIT_DELETIONS="$deletions"
    else
      unset STARSHIP_ASYNC_GIT_DELETIONS
    fi
  else
    unset STARSHIP_ASYNC_GIT_FILES
    unset STARSHIP_ASYNC_GIT_ADDITIONS
    unset STARSHIP_ASYNC_GIT_DELETIONS
  fi

  # NB: $CONTEXT/$KEYMAP are empty inside a zle -F handler, so they can't gate
  # this against menuselect. We rely instead on the signature check above (only
  # redraw when metrics actually changed) to keep spurious redraws near zero;
  # combined with fzf-tab's completion being synchronous, the menu-corruption
  # window is negligible. This mirrors powerlevel10k's unguarded reset-prompt.
  zle reset-prompt
}

__dotfiles_git_prompt_start() {
  emulate -L zsh

  zle >/dev/null 2>&1 || return
  (( __dotfiles_git_prompt_fd < 0 )) || return

  local fd
  exec {fd}< <(__dotfiles_git_prompt_collect "$PWD")
  __dotfiles_git_prompt_fd="$fd"
  zle -F "$fd" __dotfiles_git_prompt_ready
}

__dotfiles_git_prompt_unschedule() {
  emulate -L zsh

  local -i index
  for (( index = ${#zsh_scheduled_events}; index >= 1; index-- )); do
    if [[ "${zsh_scheduled_events[index]}" == *":__dotfiles_git_prompt_tick" ]]; then
      sched -$index
    fi
  done
}

__dotfiles_git_prompt_tick() {
  __dotfiles_git_prompt_start
  __dotfiles_git_prompt_unschedule
  sched +"$__dotfiles_git_prompt_interval" __dotfiles_git_prompt_tick
}

__dotfiles_git_prompt_line_init() {
  __dotfiles_git_prompt_start
}

__dotfiles_git_prompt_chpwd() {
  __dotfiles_git_prompt_signature=""
  unset STARSHIP_ASYNC_GIT_FILES
  unset STARSHIP_ASYNC_GIT_ADDITIONS
  unset STARSHIP_ASYNC_GIT_DELETIONS
}

# Re-sourcing .zshrc must not multiply hooks or scheduled scans.
add-zle-hook-widget -d line-init __dotfiles_git_prompt_line_init 2>/dev/null
add-zle-hook-widget line-init __dotfiles_git_prompt_line_init
add-zsh-hook -d chpwd __dotfiles_git_prompt_chpwd 2>/dev/null
add-zsh-hook chpwd __dotfiles_git_prompt_chpwd
__dotfiles_git_prompt_unschedule
sched +"$__dotfiles_git_prompt_interval" __dotfiles_git_prompt_tick
