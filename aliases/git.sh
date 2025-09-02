#!/usr/bin/env bash
# Shell aliases

# shellcheck source=../helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local and remote branches'
alias_aliases_desc='List all defined aliases with descriptions'
alias_git_squash_first_desc='Squash all commits onto the first commit and force push to origin'

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
  local line name desc
  local header_color="$COLOR_INFO"
  local alias_color="$COLOR_SUCCESS"

  printf '%b%s%b\n' "$header_color" "✨ Alias disponibles" "$COLOR_RESET"
  alias | while IFS= read -r line; do
    name=$(printf '%s' "$line" | cut -d= -f1 | sed "s/^alias //")
    case "$name" in
      git-prune-branches)
        desc=$alias_git_prune_branches_desc
        ;;
      aliases)
        desc=$alias_aliases_desc
        ;;
      git-squash-first)
        desc=$alias_git_squash_first_desc
        ;;
      *)
        desc=''
        ;;
    esac
    if [ -n "$desc" ]; then
      printf '  • %b%s%b\n      %s\n' \
        "$alias_color" "$name" "$COLOR_RESET" \
        "$desc"
    else
      printf '  • %b%s%b\n' \
        "$alias_color" "$name" "$COLOR_RESET"
    fi
  done
}

_git_squash_first() {
  local first_commit current_branch
  first_commit=$(git rev-list --max-parents=0 HEAD)
  git reset --soft "$first_commit"
  git commit --amend -C "$first_commit"
  current_branch=$(git rev-parse --abbrev-ref HEAD)
  git push --force-with-lease origin "$current_branch"
}

alias git-prune-branches='_git_prune_branches'
alias aliases='_aliases'
alias git-squash-first='_git_squash_first'

