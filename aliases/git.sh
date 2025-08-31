#!/usr/bin/env bash
# Shell aliases

alias_git_prune_branches_desc='Fetch all remote branches, check out main, and delete all other local and remote branches'
alias_aliases_desc='List all defined aliases with descriptions'

_git_prune_branches() {
  git fetch --all --prune
  if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
    git checkout main
  fi

  # Ensure progress bar helper is available
  if ! type load_bar >/dev/null 2>&1; then
    if [ -n "$BASH_VERSION" ]; then
      script_source="${BASH_SOURCE[0]}"
    else
      eval 'script_source="${(%):-%x}"'
    fi
    dotfiles_root="$(cd "$(dirname "$script_source")/.." && pwd)"
    # shellcheck disable=SC1090,SC1091
    source "$dotfiles_root/helpers.sh"
  fi

  # Delete remote branches on origin and report progress
  remote="origin"
  url=$(git remote get-url "$remote" 2>/dev/null || echo "N/A")
  remote_branches=$(git for-each-ref --format='%(refname:strip=3)' "refs/remotes/$remote" | grep -vE '^(HEAD|main)$')
  remote_total=$(printf '%s\n' "$remote_branches" | sed '/^$/d' | wc -l)
  if [ "$remote_total" -eq 0 ]; then
    printf 'No remote branches to prune on %s\n' "$remote"
  else
    i=0
    printf '%s\n' "$remote_branches" | while IFS= read -r branch; do
      [ -z "$branch" ] && continue
      i=$((i + 1))
      if git push "$remote" --delete "$branch" >/dev/null 2>&1; then
        branch_status="OK"
      else
        branch_status="KO"
      fi
      bar=$(load_bar "$i" "$remote_total"); bar=${bar%$'\n'}
      print_over '%s %s %s %s %s' "$bar" "$remote" "$url" "$branch" "$branch_status"
    done
    printf '\n'
  fi

  # Delete local branches and report progress
  local_branches=$(git for-each-ref --format='%(refname:strip=2)' refs/heads | grep -vE '^(main)$')
  local_total=$(printf '%s\n' "$local_branches" | sed '/^$/d' | wc -l)
  if [ "$local_total" -eq 0 ]; then
    printf 'No local branches to prune\n'
  else
    i=0
    printf '%s\n' "$local_branches" | while IFS= read -r branch; do
      [ -z "$branch" ] && continue
      i=$((i + 1))
      if git branch -D "$branch" >/dev/null 2>&1; then
        branch_status="OK"
      else
        branch_status="KO"
      fi
      bar=$(load_bar "$i" "$local_total"); bar=${bar%$'\n'}
      print_over '%s %s %s %s %s' "$bar" "local" "N/A" "$branch" "$branch_status"
    done
    printf '\n'
  fi
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

