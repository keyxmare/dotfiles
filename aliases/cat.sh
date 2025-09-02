#!/usr/bin/env bash
# shell aliases for cat replacement

# shellcheck source=../helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

alias_cat_desc='Display files with syntax highlighting via batcat'
alias cat='batcat'

