#!/usr/bin/env bash
# Bootstraps the dotfiles environment (Nix-free).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

echo "==> Step 1: Ensure Homebrew is installed"
if command -v brew >/dev/null 2>&1; then
  echo "    Homebrew already installed, skipping installation"
else
  echo "    Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for the rest of this script session
  if [ -d "/opt/homebrew/bin" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -d "/usr/local/bin" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

echo "==> Step 2: Symlink repo to ~/.dotfiles"
ln -sfn "$DIR" ~/.dotfiles

echo "==> Step 3: Symlink shell configuration"
ln -sfn "$DIR/home/.zshrc" ~/.zshrc

echo "==> Step 4: Create ~/.config and symlink configuration directories"
mkdir -p ~/.config

# Link configuration directories/files
ln -sfn "$DIR/home/.config/wezterm" ~/.config/wezterm
ln -sfn "$DIR/home/.config/herdr" ~/.config/herdr
ln -sfn "$DIR/home/.config/nvim" ~/.config/nvim
ln -sfn "$DIR/home/.config/starship.toml" ~/.config/starship.toml
ln -sfn "$DIR/home/.config/tmux" ~/.config/tmux

echo "==> Step 5: Install Homebrew bundle"
if [ -f "$DIR/Brewfile" ]; then
  brew bundle --file="$DIR/Brewfile"
else
  echo "    No Brewfile found, skipping bundle install"
fi

echo "==> Done bootstrapping dev environment!"
