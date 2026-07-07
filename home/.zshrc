# --- Auto-bootstrap Dotfiles & Symlinks ---
if [ -d "$HOME/dotfiles" ]; then
  # Ensure ~/.zshrc is symlinked to this file
  if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc")" != "$HOME/dotfiles/home/.zshrc" ]; then
    rm -f "$HOME/.zshrc"
    ln -sfn "$HOME/dotfiles/home/.zshrc" "$HOME/.zshrc"
  fi

  mkdir -p "$HOME/.config"

  # Symlink config directories/files if they aren't already correct
  # wezterm config
  if [ ! -L "$HOME/.config/wezterm" ] || [ "$(readlink "$HOME/.config/wezterm")" != "$HOME/dotfiles/home/.config/wezterm" ]; then
    rm -rf "$HOME/.config/wezterm"
    ln -sfn "$HOME/dotfiles/home/.config/wezterm" "$HOME/.config/wezterm"
  fi

  # tmux config
  if [ ! -L "$HOME/.config/tmux" ] || [ "$(readlink "$HOME/.config/tmux")" != "$HOME/dotfiles/home/.config/tmux" ]; then
    rm -rf "$HOME/.config/tmux"
    ln -sfn "$HOME/dotfiles/home/.config/tmux" "$HOME/.config/tmux"
  fi

  # herdr config (handle files/directories carefully since herdr writes logs here)
  if [ ! -L "$HOME/.config/herdr/config.toml" ] || [ "$(readlink "$HOME/.config/herdr/config.toml")" != "$HOME/dotfiles/home/.config/herdr/config.toml" ]; then
    mkdir -p "$HOME/.config/herdr"
    rm -f "$HOME/.config/herdr/config.toml"
    ln -sfn "$HOME/dotfiles/home/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
  fi

  # starship config
  if [ ! -L "$HOME/.config/starship.toml" ] || [ "$(readlink "$HOME/.config/starship.toml")" != "$HOME/dotfiles/home/.config/starship.toml" ]; then
    rm -f "$HOME/.config/starship.toml"
    ln -sfn "$HOME/dotfiles/home/.config/starship.toml" "$HOME/.config/starship.toml"
  fi

  # Install Starship if it's missing
  if ! command -v starship &>/dev/null; then
    echo "Starship prompt not found, installing via Homebrew..."
    brew install starship
  fi
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

# Brew
export PATH="/opt/homebrew/bin:$PATH"

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
