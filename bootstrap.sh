#!/usr/bin/env bash
# Takes a fresh Mac from nothing to a fully configured Homebrew & symlink setup.
# Run this once to bootstrap, and run it (or ./rebuild.sh) to apply any future updates.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Ensure Homebrew is installed"
if ! command -v brew &>/dev/null; then
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "    Homebrew not found. Installing via curl..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Load Homebrew for the rest of the script
    if [ -d "/opt/homebrew/bin" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -d "/usr/local/bin" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
else
  echo "    Homebrew already installed, skipping"
fi

echo "==> Step 2: Set macOS system defaults"
# Match configuration.nix system defaults
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain _HIHideMenuBar -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.dock autohide -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder CreateDesktop -bool false
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write -g com.apple.mouse.tapBehavior -int 1
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1

# Apply system defaults by restarting affected applications
for app in "Dock" "Finder"; do
  killall "${app}" &>/dev/null || true
done
echo "    macOS system defaults configured"

echo "==> Step 3: Symlink configuration files"
link_item() {
  local src="$1"
  local dest="$2"
  
  # Ensure the parent directory exists
  mkdir -p "$(dirname "$dest")"
  
  if [ -L "$dest" ]; then
    # It is already a symlink, check if it points to the correct target
    if [ "$(readlink "$dest")" != "$src" ]; then
      echo "    Updating symlink: $dest -> $src"
      rm -f "$dest"
      ln -sfn "$src" "$dest"
    fi
  elif [ -e "$dest" ]; then
    # It exists but is a regular file/directory, back it up first
    echo "    Warning: $dest already exists and is not a symlink. Backing up to $dest.bak"
    mv "$dest" "$dest.bak"
    ln -sfn "$src" "$dest"
  else
    # Doesn't exist, create it
    echo "    Creating symlink: $dest -> $src"
    ln -sfn "$src" "$dest"
  fi
}

# Symlink all configuration folders and files
link_item "$DIR/home/.zshrc" "$HOME/.zshrc"
link_item "$DIR/home/.config/wezterm" "$HOME/.config/wezterm"
link_item "$DIR/home/.config/nvim" "$HOME/.config/nvim"
link_item "$DIR/home/.config/herdr" "$HOME/.config/herdr"
link_item "$DIR/home/.config/tmux" "$HOME/.config/tmux"
link_item "$DIR/home/.config/starship.toml" "$HOME/.config/starship.toml"
link_item "$DIR/home/.claude/settings.json" "$HOME/.claude/settings.json"
link_item "$DIR/home/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link_item "$DIR/home/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_item "$DIR/home/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"

echo "==> Step 4: Install packages via Homebrew Bundle"
# Install everything from Brewfile and clean up any unlisted formulas/casks
brew bundle install --file="$DIR/Brewfile" --cleanup --force

echo "==> Done. Your Mac has been configured without Nix!"
