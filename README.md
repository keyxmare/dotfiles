# dotfiles

This repository contains a bash/shell project structure to manage personal dotfiles.

## Installation
Run `./install.sh` (which also installs missing dependencies) or `./sync.sh --install` to configure Git hooks, sync the repository into `~/.local/share/dotfiles`, and source the aliases in your `~/.bashrc` or `~/.zshrc`. The aliases and helper functions are also loaded for your current shell session, and subsequent `./sync.sh` runs keep your profiles up to date.

## Aliases
- `git-prune-branches`: fetch all remote branches, check out `main`, and delete all other local and remote branches.
- `aliases`: list all defined aliases with descriptions in a simplified colorized list.

## Utilities
- `load_bar`: render a basic progress bar for shell scripts.

## Syncing scripts
- `./sync.sh`: mirror repository files into `~/.local/share/dotfiles` using `rsync`, reload the alias definitions, and ensure shell profiles source them. Pass `--install` for initial hook setup.
- A Git post-merge hook runs `sync.sh` after `git pull` to keep the local copy synchronized automatically.
