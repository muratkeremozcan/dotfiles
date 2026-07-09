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

# Brew path set up early in the file

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

# Initialize Starship Prompt
eval "$(starship init zsh)"

# WezTerm shell integration: reports cwd/prompt state to WezTerm on every
# prompt, so the right-status bar (git branch/stats) refreshes immediately
# after a command finishes instead of waiting on a fixed timer.
[ -n "$WEZTERM_PANE" ] && source "$HOME/.config/wezterm/shell-integration.sh"

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
