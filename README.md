# dotfiles

This repository contains a bash/shell project structure to manage personal dotfiles.

## Installation
Run `./install.sh` to sync the repository into `~/.local/share/dotfiles` and source the aliases in your `~/.bashrc`. Restart your shell to use the aliases.

## Aliases
- `git-prune-branches`: fetch all remote branches, check out `main`, and delete all other local branches.
- `aliases`: list all defined aliases with descriptions.

## Syncing scripts
- `./sync.sh`: mirror repository files into `~/.local/share/dotfiles` using `rsync`.
