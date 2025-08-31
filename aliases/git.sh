#!/usr/bin/env bash
# Git related aliases

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local branches'
alias_aliases_desc='List all defined aliases with descriptions'

_git_prune_branches() {
  git fetch --all
  git checkout main
  git branch | grep -v "main" | xargs git branch -D
}

_aliases() {
  local bold reset header_color alias_color desc_color bullet_color
  local line name desc
  bold=$(printf '\033[1m')
  reset=$(printf '\033[0m')
  header_color=$(printf '\033[36m')
  alias_color=$(printf '\033[32m')
  desc_color=$(printf '\033[33m')
  bullet_color=$(printf '\033[35m')

  printf '%b%s%b\n' "$bold$header_color" "✨ Alias disponibles" "$reset"
  alias | while IFS= read -r line; do
    name=$(printf '%s' "$line" | cut -d= -f1 | sed "s/^alias //")
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
    if [ -n "$desc" ]; then
      printf '  %b•%b %b%s%b %b→ %s%b\n' \
        "$bullet_color" "$reset" \
        "$alias_color" "$name" "$reset" \
        "$desc_color" "$desc" "$reset"
    else
      printf '  %b•%b %b%s%b\n' \
        "$bullet_color" "$reset" \
        "$alias_color" "$name" "$reset"
    fi
  done
}

alias git-prune-branches='_git_prune_branches'
alias aliases='_aliases'
