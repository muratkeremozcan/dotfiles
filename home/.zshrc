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

# --- Autocomplete Configuration ---

# Source zsh-autocomplete for real-time type-ahead completion
if [ -f "/opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
  source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
elif [ -f "/usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]; then
  source /usr/local/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
fi

# Select suggestions using Enter
bindkey -M menuselect '^M' .accept-line
