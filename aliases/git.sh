#!/usr/bin/env bash
# Shell aliases

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local and remote branches'
alias_aliases_desc='List all defined aliases with descriptions'

_git_prune_branches() {
  git fetch --all --prune --quiet
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
    git checkout main
  fi

  remote="origin"
  git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$remote" \
    | grep -vE '^(HEAD|main)$' \
    | while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        git push "$remote" --delete "$branch"
      done

  git for-each-ref --format='%(refname:strip=2)' refs/heads \
    | grep -vE '^(main)$' \
    | while IFS= read -r branch; do
        [ -z "$branch" ] && continue
        git branch -D "$branch"
      done
}

_aliases() {
  local bold reset header_color alias_color
  local line name desc
  bold=$(printf '\033[1m')
  reset=$(printf '\033[0m')
  header_color=$(printf '\033[36m')
  alias_color=$(printf '\033[32m')

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
      printf '  • %b%s%b\n      %s\n' \
        "$alias_color" "$name" "$reset" \
        "$desc"
    else
      printf '  • %b%s%b\n' \
        "$alias_color" "$name" "$reset"
    fi
  done
}

alias git-prune-branches='_git_prune_branches'
alias aliases='_aliases'

