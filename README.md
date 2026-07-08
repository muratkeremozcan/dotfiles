# dotfiles

My personal Mac setup, managed with Homebrew Bundle and native shell scripting.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools declared in `Brewfile`)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config)
- Terminal (WezTerm config)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review the `Brewfile` to customize your packages, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Ensures Homebrew is installed.
2. Sets macOS system defaults (dark mode, key repeats, Dock, Finder, trackpad).
3. Symlinks this repo's configs (from `home/`) to your home directory (`~/.zshrc`, `~/.config/wezterm`, `~/.config/nvim`, etc.).
4. Runs `brew bundle install --cleanup` to install all packages declared in the `Brewfile` and remove any unlisted/ad-hoc packages.

## Daily use

Edit the config files in place, or add/remove packages in the `Brewfile`, then apply:

```sh
./rebuild.sh
```

That's it. No separate build-and-copy step.

## Homebrew cleanup warning

The bootstrap and rebuild scripts run `brew bundle install --cleanup`.
This means every time you rebuild/bootstrap, Homebrew removes any package or cask on your machine that isn't listed in the `Brewfile`.
If you already have Homebrew stuff installed that isn't in that list, the first run will uninstall it.
Read through `Brewfile` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

## Repo tour

- `Brewfile` - declarations of all Homebrew taps, CLI packages, desktop applications (casks), and VS Code extensions.
- `bootstrap.sh` - sets up Homebrew, macOS defaults, creates the symlinks, and syncs packages.
- `rebuild.sh` - wrapper for `./bootstrap.sh` to easily sync/refresh configs.
- `home/` - the actual config files that get symlinked into place (Neovim, WezTerm, herdr, Claude settings, the shared `AGENTS.md`).

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`bootstrap.sh` symlinks paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you add/remove packages in the `Brewfile` or change macOS system defaults.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
