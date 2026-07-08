# --- Homebrew Path Setup ---
if [ -d "/opt/homebrew/bin" ]; then
  export PATH="/opt/homebrew/bin:$PATH"
elif [ -d "/usr/local/bin" ]; then
  export PATH="/usr/local/bin:$PATH"
fi

# --- Main Shell Configuration ---

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Aliases
alias gs="git status"
alias p="pnpm"
alias px="pnpm dlx"
alias n="npm"
alias nr="npm run"
alias g="git"

# NVM Function Replacement
nvm() {
  source $(brew --prefix nvm)/nvm.sh --no-use
  nvm "$@"
}

# NVM Initialization
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"  # Loads nvm
nvm use default --silent

# Brew path set up early in the file

# Windsurf 
export PATH="/Applications/Windsurf.app/Contents/Resources/app/bin:$PATH"

# For fetch mcp (bun)
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Auto-activate/deactivate python virtual env 
eval "$(direnv hook zsh)"
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

alias python="/opt/homebrew/opt/python@3.12/bin/python3.12"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Added by Windsurf - Next
export PATH="$HOME/.codeium/windsurf/bin:$PATH"
eval "$(direnv hook zsh)"
export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export PATH="$JAVA_HOME/bin:$PATH"
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-23.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"

# Initialize Starship Prompt
eval "$(starship init zsh)"

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
