#!/usr/bin/env bash
set -euo pipefail

GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

CHAR_CHECK=$(printf '\xe2\x9c\x93')
CHAR_WARN=$(printf '\xe2\x9a\xa0')
CHAR_CROSS=$(printf '\xe2\x9c\x97')

ok()   { printf "  ${GREEN}${CHAR_CHECK}${RESET}  %s\n" "$*"; }
warn() { printf "  ${YELLOW}${CHAR_WARN}${RESET}  %s\n" "$*"; }
err()  { printf "  ${RED}${CHAR_CROSS}${RESET}  %s\n" "$*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

OS="$(uname -s)"
ARCH="$(uname -m)"

detect_os() {
    case "$OS" in
        Darwin) echo "macos" ;;
        Linux)
            if grep -qi microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *) echo "unknown" ;;
    esac
}

detect_package_manager() {
    local os="$1"
    local managers=()

    case "$os" in
        macos)
            command -v brew &>/dev/null && managers+=("brew")
            command -v npm &>/dev/null && managers+=("npm")
            command -v pnpm &>/dev/null && managers+=("pnpm")
            command -v bun &>/dev/null && managers+=("bun")
            ;;
        linux|wsl)
            command -v npm &>/dev/null && managers+=("npm")
            command -v pnpm &>/dev/null && managers+=("pnpm")
            command -v bun &>/dev/null && managers+=("bun")
            command -v brew &>/dev/null && managers+=("brew")
            ;;
        windows)
            command -v npm &>/dev/null && managers+=("npm")
            command -v pnpm &>/dev/null && managers+=("pnpm")
            command -v bun &>/dev/null && managers+=("bun")
            ;;
    esac

    echo "${managers[*]:-}"
}

install_with() {
    local manager="$1"
    case "$manager" in
        brew)  brew install backlog-md ;;
        npm)   npm install -g backlog.md ;;
        pnpm)  pnpm add -g backlog.md ;;
        bun)   bun install -g backlog.md ;;
    esac
}

register_mcp() {
    if ! command -v claude &>/dev/null; then
        warn "claude CLI not found — MCP server not registered"
        printf "    ${DIM}Run: claude mcp add --scope user backlog -- backlog mcp start${RESET}\n"
        return
    fi

    local existing
    existing=$(python3 -c "
import json, sys, os
p = os.path.expanduser('~/.claude.json')
if not os.path.exists(p):
    sys.exit(0)
with open(p) as f:
    data = json.load(f)
srv = data.get('mcpServers', {}).get('backlog', {})
args = srv.get('args', [])
print(' '.join(args))
" 2>/dev/null || true)

    if [[ "$existing" == *"backlog"*"mcp"*"start"* ]]; then
        ok "MCP server already registered"
        return
    fi

    claude mcp remove backlog >/dev/null 2>&1 || true
    claude mcp add --scope user backlog -- backlog mcp start >/dev/null 2>&1
    ok "MCP server registered ${DIM}(scope: user)${RESET}"
}

main() {
    local current_os
    current_os="$(detect_os)"

    printf "\n  ${BOLD}backlog.md${RESET} ${DIM}— install${RESET}\n"
    printf "  ${DIM}OS: %s (%s)${RESET}\n\n" "$current_os" "$ARCH"

    if command -v backlog &>/dev/null; then
        local version
        version=$(backlog --version 2>/dev/null || echo "unknown")
        ok "Already installed ${DIM}(v${version})${RESET}"
        register_mcp
        return 0
    fi

    local managers
    managers="$(detect_package_manager "$current_os")"

    if [[ -z "$managers" ]]; then
        if [[ "$current_os" == "macos" ]]; then
            warn "No package manager found — installing Homebrew first"
            if "$DOTFILES_DIR/bin/install-brew"; then
                managers="brew"
            else
                err "Homebrew installation failed"
                return 1
            fi
        else
            err "No supported package manager found"
            printf "    ${DIM}Install one of: npm, pnpm, bun${RESET}\n"
            printf "    ${DIM}Then re-run this script${RESET}\n"
            return 1
        fi
    fi

    printf "  ${DIM}Available managers: %s${RESET}\n" "$managers"

    local installed=0
    for manager in $managers; do
        printf "  ${DIM}Trying %s…${RESET}\n" "$manager"
        if install_with "$manager" 2>/dev/null; then
            ok "Installed via ${BOLD}$manager${RESET}"
            installed=1
            break
        else
            warn "Failed with $manager, trying next…"
        fi
    done

    if [[ $installed -eq 0 ]]; then
        err "All package managers failed"
        printf "    ${DIM}Try manually: npm install -g backlog.md${RESET}\n"
        return 1
    fi

    register_mcp
}

main "$@"
