#!/usr/bin/env bash
# Git related aliases

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local branches'
alias_aliases_desc='List all defined aliases with descriptions'

_aliases() {
  local bold reset line name value desc
  bold=$(printf '\033[1m')
  reset=$(printf '\033[0m')
  printf '%b%-20s %-40s %s%b\n' "$bold" "Alias" "Command" "Description" "$reset"
  printf '%-20s %-40s %s\n' "-----" "-------" "-----------"
  alias | while IFS= read -r line; do
    name=$(printf '%s' "$line" | cut -d= -f1 | sed "s/^alias //")
    value=$(printf '%s' "$line" | cut -d= -f2- | sed "s/^'//; s/'$//")
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
    printf '%-20s %-40s %s\n' "$name" "$value" "$desc"
  done
}

alias git-prune-branches='git fetch --all && git checkout main && git branch | grep -v "main" | xargs git branch -D'
alias aliases='_aliases'
