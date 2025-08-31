# dotfiles

This repository contains a bash/shell project structure to manage personal dotfiles.

## Installation
Run `./install.sh` to sync the repository into `~/.local/share/dotfiles` and source the aliases in your `~/.bashrc` or `~/.zshrc`. The aliases are also loaded for your current shell session.

## Aliases
- `git-prune-branches`: fetch all remote branches, check out `main`, and delete all other local and remote branches.
- `aliases`: list all defined aliases with descriptions in a simplified colorized list.

## Syncing scripts
- `./sync.sh`: mirror repository files into `~/.local/share/dotfiles` using `rsync` and reload the alias definitions.
- A Git post-merge hook runs `sync.sh` after `git pull` to keep the local copy synchronized automatically.
