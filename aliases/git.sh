#!/bin/sh
# Git related aliases
alias git-prune-branches='git fetch --all && git checkout main && git branch | grep -v "main" | xargs git branch -D'
