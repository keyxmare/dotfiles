#!/usr/bin/env bash
# Git related aliases

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local branches'
alias_aliases_desc='List all defined aliases with descriptions'

_aliases() {
  local bold reset header_color alias_color command_color desc_color
  local line name value desc
  bold=$(printf '\033[1m')
  reset=$(printf '\033[0m')
  header_color=$(printf '\033[36m')
  alias_color=$(printf '\033[32m')
  command_color=$(printf '\033[34m')
  desc_color=$(printf '\033[33m')

  printf '%b%-20s %-40s %s%b\n' "$bold$header_color" "Alias" "Command" "Description" "$reset"
  printf '%b%-20s %-40s %s%b\n' "$header_color" "-----" "-------" "-----------" "$reset"
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
    printf '%b%-20s%b %b%-40s%b %b%s%b\n' \
      "$alias_color" "$name" "$reset" \
      "$command_color" "$value" "$reset" \
      "$desc_color" "$desc" "$reset"
  done
}

alias git-prune-branches='git fetch --all && git checkout main && git branch | grep -v "main" | xargs git branch -D'
alias aliases='_aliases'
