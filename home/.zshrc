# --- Homebrew Path Setup ---
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

typeset -U path PATH

# --- Main Shell Configuration ---

export NVM_DIR="$HOME/.nvm"

# Aliases
alias gs="git status"
alias p="pnpm"
alias px="pnpm dlx"
alias n="npm"
alias nr="npm run"
alias g="git"
alias cc="claude --dangerously-skip-permissions"

# AWS SSO helpers (SEON work accounts - harmless no-ops on non-work machines)
login() {
  local profile=${1:-development}
  aws sso login --profile "$profile"
}

logout() {
  aws sso logout
  rm -rf ~/.aws/sso/cache/*
}

login-ecr() {
  aws ecr get-login-password --region eu-west-1 --profile developer-tools | \
  docker login --username AWS --password-stdin 271518727158.dkr.ecr.eu-west-1.amazonaws.com
  echo "ECR login successful."
}

login:all() {
  echo "Logging into developer-tools in the background..."
  login developer-tools &
  echo "Logging into development in the background..."
  login development &
  wait
  echo "All logins completed."
}

# Lazy-load NVM on first Node-related command instead of during shell startup.
load-nvm() {
  local nvm_sh="$NVM_DIR/nvm.sh"
  [ -s "$nvm_sh" ] || return 1

  unset -f nvm node npm npx pnpm corepack 2>/dev/null
  source "$nvm_sh" --no-use
  nvm use default --silent >/dev/null 2>&1 || true
}

nvm() { load-nvm && nvm "$@"; }
node() { load-nvm && command node "$@"; }
npm() { load-nvm && command npm "$@"; }
npx() { load-nvm && command npx "$@"; }
pnpm() { load-nvm && command pnpm "$@"; }
corepack() { load-nvm && command corepack "$@"; }

# Auto-switch node version when cd'ing into a directory with .nvmrc.
# Walks up the tree first so we only pay the load-nvm cost when actually needed.
autoload -U add-zsh-hook
load-nvmrc() {
  local dir=$PWD
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    [[ -f "$dir/.nvmrc" ]] && break
    dir="${dir%/*}"
  done
  [[ -f "$dir/.nvmrc" ]] || return 0
  type nvm_find_nvmrc >/dev/null 2>&1 || load-nvm || return 0
  local nvmrc_path nvmrc_node_version
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use --silent
    fi
  elif [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default --silent
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# GNU coreutils on macOS (gives 'gls', 'gdate', etc. as their plain names)
[ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ] && export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# Windsurf
[ -d "/Applications/Windsurf.app/Contents/Resources/app/bin" ] && export PATH="/Applications/Windsurf.app/Contents/Resources/app/bin:$PATH"

# For fetch mcp (bun)
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"
[ -d "$HOME/.cargo/bin" ] && export PATH="$HOME/.cargo/bin:$PATH"

# Auto-activate/deactivate project environments.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# Homebrew's unversioned python/pip shims. Virtualenv paths still win when active.
[ -d "/opt/homebrew/opt/python@3.12/libexec/bin" ] && export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Added by Windsurf - Next
[ -d "$HOME/.codeium/windsurf/bin" ] && export PATH="$HOME/.codeium/windsurf/bin:$PATH"

if [ -d "/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home" ]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
elif /usr/libexec/java_home -v 21 >/dev/null 2>&1; then
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# Added by Antigravity CLI installer
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# Cursor app CLI. Keep this after ~/.local/bin so it wins over agent shims named cursor.
[ -d "/Applications/Cursor.app/Contents/Resources/app/bin" ] && export PATH="/Applications/Cursor.app/Contents/Resources/app/bin:$PATH"

# Initialize Starship Prompt once. Re-sourcing this file must not duplicate its
# precmd and preexec hooks.
if [[ -z "${__DOTFILES_STARSHIP_INITIALIZED:-}" ]]; then
  eval "$(starship init zsh)"
  typeset -g __DOTFILES_STARSHIP_INITIALIZED=1
fi

# Keep WezTerm's cwd and semantic prompt zones, but skip unused user vars and
# never register the hooks twice when this file is re-sourced.
if [[ -n "$WEZTERM_PANE" && -z "${__DOTFILES_WEZTERM_INTEGRATION_LOADED:-}" ]]; then
  export WEZTERM_SHELL_SKIP_USER_VARS=1
  source "$HOME/.config/wezterm/shell-integration.sh"
  typeset -g __DOTFILES_WEZTERM_INTEGRATION_LOADED=1
fi

# --- Autocomplete & Shell Refinements (Warp-like) ---

# Enable Zsh completion system
autoload -Uz compinit
compinit -u

# Source fzf-tab (replaces standard completion menu with fuzzy-find fzf selection)
if [ -f "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" ]; then
  source "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
elif [ -f "/usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" ]; then
  source "/usr/local/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
fi

# Case-insensitive tab completion, partial-word completion, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Colorize completion lists matching 'ls'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Source syntax highlighting and autosuggestions
if [ -f "/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [ -f "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

if [ -f "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Configure zsh-autosuggestions style (muted/greyish text)
export ZSH_AUTO_SUGGEST_HIGHLIGHT_STYLE="fg=8"

# Bindings for zsh-autosuggestions
bindkey '^f' forward-word          # Ctrl+F to accept one word of suggestion
bindkey '^e' end-of-line           # Ctrl+E to accept full suggestion

# --- Smart Tab Behavior ---
# If a shaded history suggestion is visible, Tab accepts it.
# Otherwise, Tab opens the interactive fuzzy-completion menu.
smart-tab() {
  if [[ -n "$POSTDISPLAY" ]]; then
    zle autosuggest-accept
  else
    zle expand-or-complete
  fi
}
zle -N smart-tab
bindkey '^I' smart-tab

# Map Shift+Enter (sent by WezTerm as \x1b[13;2u) to insert a newline
insert-newline() {
  LBUFFER+=$'\n'
}
zle -N insert-newline
bindkey "\e[13;2u" insert-newline

# Refresh Git metrics asynchronously while ZLE is waiting for input. This is
# sourced after other ZLE plugins so its redraw hook composes with them.
[ -r "$HOME/.config/zsh/async-git-prompt.zsh" ] && source "$HOME/.config/zsh/async-git-prompt.zsh"

# GitHub Packages auth - pull from gh CLI so no token is hardcoded in dotfiles.
# On work machine, ~/.zshrc.local overrides this with a PAT if needed.
# Requires: gh auth refresh -h github.com -s read:packages
export GITHUB_TOKEN=$(gh auth token 2>/dev/null)

# Machine-local overrides: tokens, work env vars, machine-specific paths.
# This file is NOT tracked by git - create it on each machine separately.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
