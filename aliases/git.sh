#!/usr/bin/env bash
# Git related aliases

alias_git_prune_branches_desc='fetch all remote branches, check out main, and delete all other local branches'
alias_aliases_desc='list all defined aliases with descriptions'

_aliases() {
  alias -p | while IFS= read -r line; do
    local name desc
    name=$(printf '%s' "$line" | sed -n "s/^alias \([^=]*\)=.*/\1/p")
    case "$name" in
      git-prune-branches)
        desc=$alias_git_prune_branches_desc
        ;;
      aliases)
        desc=$alias_aliases_desc
        ;;
      *)
        desc=''
        ;;
    esac
    printf '%s # %s\n' "$line" "$desc"
  done
}

alias git-prune-branches='git fetch --all && git checkout main && git branch | grep -v "main" | xargs git branch -D'
alias aliases='_aliases'
