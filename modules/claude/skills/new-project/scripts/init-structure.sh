#!/bin/bash
set -euo pipefail

# Usage: init-structure.sh <project-path> <type> [options]
# Creates the deterministic directory structure for a new project.
# Called by Claude during scaffolding — does NOT generate file content.

PROJECT_PATH="${1:?Usage: init-structure.sh <project-path> <type> [--backend] [--frontend] [--frontend-framework nuxt|vue] [--docker] [--docs] [--docs-c4] [--docs-openapi] [--docs-adr] [--docs-features] [--ci github|gitlab] [--advanced] [--contexts ctx1,ctx2,...] [--cli-lang php|ts|shell] [--lib-lang php|ts] [--layers] [--arch-tests] [--dry-run] [--force]}"
TYPE="${2:?Type required: web, cli, lib}"
shift 2

DRY_RUN=false
FORCE=false

BACKEND=false
FRONTEND=false
FRONTEND_FRAMEWORK=""
DOCKER=false
DOCS=false
CI=""
ADVANCED=false
CONTEXTS=""
CLI_LANG="php"
LIB_LANG="php"
DOCS_C4=false
DOCS_OPENAPI=false
DOCS_ADR=false
DOCS_FEATURES=false
LAYERS=false
ARCH_TESTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backend) BACKEND=true ;;
    --frontend) FRONTEND=true ;;
    --frontend-framework) FRONTEND_FRAMEWORK="$2"; shift ;;
    --docker) DOCKER=true ;;
    --docs) DOCS=true ;;
    --ci) CI="$2"; shift ;;
    --advanced) ADVANCED=true ;;
    --contexts) CONTEXTS="$2"; shift ;;
    --cli-lang) CLI_LANG="$2"; shift ;;
    --lib-lang) LIB_LANG="$2"; shift ;;
    --docs-c4) DOCS_C4=true ;;
    --docs-openapi) DOCS_OPENAPI=true ;;
    --docs-adr) DOCS_ADR=true ;;
    --docs-features) DOCS_FEATURES=true ;;
    --layers) LAYERS=true ;;
    --arch-tests) ARCH_TESTS=true ;;
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

# Dry-run support
make_dir() {
  if $DRY_RUN; then
    echo "[DRY-RUN] mkdir -p $1"
  else
    mkdir -p "$1"
  fi
}

make_dir "$PROJECT_PATH"
cd "$PROJECT_PATH"

# Safety check: refuse to scaffold in non-empty directory unless --force or existing scaffold
if [[ -n "$(ls -A "$PROJECT_PATH" 2>/dev/null)" ]] && ! $FORCE; then
  if [[ ! -f "$PROJECT_PATH/scaffold.config.json" ]]; then
    echo "ERROR: $PROJECT_PATH is not empty and doesn't look like a scaffold project."
    echo "Use --force to override, or choose an empty directory."
    exit 1
  fi
fi

# Common
make_dir .claude
make_dir .githooks

# Type-specific
case "$TYPE" in
  web)
    if $BACKEND; then
      if $ADVANCED && [[ -n "$CONTEXTS" ]]; then
        IFS=',' read -ra CTX_ARRAY <<< "$CONTEXTS"
        for ctx in "${CTX_ARRAY[@]}"; do
          make_dir "backend/src/$ctx/Domain/Model"
          make_dir "backend/src/$ctx/Domain/ValueObject"
          make_dir "backend/src/$ctx/Domain/Repository"
          make_dir "backend/src/$ctx/Domain/Port"
          make_dir "backend/src/$ctx/Domain/Event"
          make_dir "backend/src/$ctx/Domain/Exception"
          make_dir "backend/src/$ctx/Application/Command"
          make_dir "backend/src/$ctx/Application/CommandHandler"
          make_dir "backend/src/$ctx/Application/Query"
          make_dir "backend/src/$ctx/Application/QueryHandler"
          make_dir "backend/src/$ctx/Application/DTO"
          make_dir "backend/src/$ctx/Infrastructure/Persistence/Doctrine"
          make_dir "backend/src/$ctx/Infrastructure/Controller"
          make_dir "backend/src/$ctx/Infrastructure/Messenger"
          make_dir "backend/tests/Unit/$ctx/Application/CommandHandler"
          make_dir "backend/tests/Unit/$ctx/Application/QueryHandler"
          make_dir "backend/tests/Integration/$ctx/Infrastructure/Persistence/Doctrine"
          make_dir "backend/tests/Functional/$ctx/Infrastructure/Controller"
          make_dir "backend/tests/Factory/$ctx"
        done
        make_dir "backend/src/Shared/Domain/Exception"
        make_dir "backend/src/Shared/Infrastructure/EventListener"
        make_dir "backend/src/Shared/Application/DTO"
      else
        make_dir backend/src/Controller
        make_dir backend/src/Entity
        make_dir backend/src/Repository
        make_dir backend/src/Service
        make_dir backend/tests/Unit
        make_dir backend/tests/Integration
        make_dir backend/tests/Functional
        make_dir backend/tests/Factory
      fi
      make_dir backend/bin
      make_dir backend/config/packages
      make_dir backend/config/routes
      make_dir backend/migrations
      make_dir backend/public
      make_dir backend/src/DataFixtures
    fi

    if $FRONTEND; then
      if $ADVANCED && [[ -n "$CONTEXTS" ]]; then
        IFS=',' read -ra CTX_ARRAY <<< "$CONTEXTS"
        case "$FRONTEND_FRAMEWORK" in
          vue)
            make_dir frontend/src/app
            make_dir frontend/src/shared/components
            make_dir frontend/src/shared/composables
            make_dir frontend/src/shared/layouts
            make_dir frontend/src/shared/types
            make_dir frontend/src/shared/utils
            for ctx in "${CTX_ARRAY[@]}"; do
              ctx_lower=$(echo "$ctx" | tr '[:upper:]' '[:lower:]')
              make_dir "frontend/src/$ctx_lower/components"
              make_dir "frontend/src/$ctx_lower/composables"
              make_dir "frontend/src/$ctx_lower/pages"
              make_dir "frontend/src/$ctx_lower/stores"
              make_dir "frontend/src/$ctx_lower/types"
              make_dir "frontend/src/$ctx_lower/services"
              make_dir "frontend/tests/unit/$ctx_lower/stores"
            done
            ;;
          nuxt|*)
            if $LAYERS; then
              # Nuxt Layers structure (auto-registered in Nuxt 4)
              make_dir frontend/app
              make_dir frontend/app/assets
              make_dir frontend/app/layouts
              make_dir frontend/app/plugins
              make_dir frontend/app/shared/components
              make_dir frontend/app/shared/composables
              make_dir frontend/app/shared/utils
              make_dir frontend/app/shared/types
              for ctx in "${CTX_ARRAY[@]}"; do
                ctx_lower=$(echo "$ctx" | tr '[:upper:]' '[:lower:]')
                make_dir "frontend/layers/$ctx_lower/components"
                make_dir "frontend/layers/$ctx_lower/composables"
                make_dir "frontend/layers/$ctx_lower/pages"
                make_dir "frontend/layers/$ctx_lower/stores"
                make_dir "frontend/layers/$ctx_lower/types"
                make_dir "frontend/layers/$ctx_lower/services"
                make_dir "frontend/tests/unit/$ctx_lower/stores"
              done
            else
              # Nuxt app/ subdirectory structure
              make_dir frontend/app/assets
              make_dir frontend/app/layouts
              make_dir frontend/app/plugins
              make_dir frontend/app/shared/components
              make_dir frontend/app/shared/composables
              make_dir frontend/app/shared/utils
              make_dir frontend/app/shared/types
              for ctx in "${CTX_ARRAY[@]}"; do
                ctx_lower=$(echo "$ctx" | tr '[:upper:]' '[:lower:]')
                make_dir "frontend/app/$ctx_lower/components"
                make_dir "frontend/app/$ctx_lower/composables"
                make_dir "frontend/app/$ctx_lower/pages"
                make_dir "frontend/app/$ctx_lower/middleware"
                make_dir "frontend/app/$ctx_lower/stores"
                make_dir "frontend/app/$ctx_lower/types"
                make_dir "frontend/app/$ctx_lower/services"
                make_dir "frontend/tests/unit/$ctx_lower/stores"
              done
            fi
            make_dir frontend/server/api
            make_dir frontend/server/middleware
            make_dir frontend/server/plugins
            make_dir frontend/server/routes
            make_dir frontend/server/utils
            ;;
        esac
      else
        case "$FRONTEND_FRAMEWORK" in
          vue)
            make_dir frontend/src/assets
            make_dir frontend/src/components
            make_dir frontend/src/composables
            make_dir frontend/src/layouts
            make_dir frontend/src/pages
            make_dir frontend/src/plugins
            make_dir frontend/src/router
            make_dir frontend/src/stores
            make_dir frontend/src/types
            make_dir frontend/src/utils
            ;;
          nuxt|*)
            make_dir frontend/app/assets
            make_dir frontend/app/components
            make_dir frontend/app/composables
            make_dir frontend/app/layouts
            make_dir frontend/app/middleware
            make_dir frontend/app/pages
            make_dir frontend/app/plugins
            make_dir frontend/app/utils
            make_dir frontend/server/api
            make_dir frontend/server/middleware
            make_dir frontend/server/plugins
            make_dir frontend/server/routes
            make_dir frontend/server/utils
            make_dir frontend/shared
            ;;
        esac
        make_dir frontend/tests/unit
        make_dir frontend/tests/integration
      fi
      make_dir frontend/public
      make_dir frontend/tests/e2e
    fi

    if $DOCKER; then
      make_dir docker
      $BACKEND && make_dir docker/backend
      $FRONTEND && make_dir docker/frontend
    fi

    make_dir .devcontainer
    ;;

  cli)
    case "$CLI_LANG" in
      php)
        make_dir bin
        make_dir src
        make_dir tests/Unit
        ;;
      ts)
        make_dir bin
        make_dir src
        make_dir tests/unit
        ;;
      shell)
        make_dir bin
        make_dir lib
        make_dir tests/test_helper/bats-libs
        make_dir tests/unit
        make_dir tests/integration
        ;;
      *)
        echo "Unknown CLI language: $CLI_LANG (expected php|ts|shell)"; exit 1
        ;;
    esac
    ;;

  lib)
    case "$LIB_LANG" in
      php)
        make_dir src
        make_dir tests/Unit
        make_dir tests/Integration
        ;;
      ts)
        make_dir src
        make_dir tests/unit
        make_dir tests/integration
        ;;
      *)
        echo "Unknown lib language: $LIB_LANG (expected php|ts)"; exit 1
        ;;
    esac
    ;;
esac

# Documentation
if $DOCS; then
  make_dir docs
  $DOCS_C4 && make_dir docs/c4
  $DOCS_OPENAPI && make_dir docs/api
  $DOCS_ADR && make_dir docs/adr
  $DOCS_FEATURES && make_dir docs/features
fi

# CI
case "$CI" in
  github) make_dir .github/workflows ;;
  gitlab) ;; # single file, no directory needed
esac

# Architecture tests
if $ARCH_TESTS; then
  # deptrac config lives at backend root (or project root for cli/lib)
  # eslint-boundaries config is in eslint.config.js (no directory needed)
  # No directories to create — config files are generated by the skill
  true
fi

if $DRY_RUN; then
  echo "Dry-run complete — no directories were created."
else
  echo "Structure created at $PROJECT_PATH"
fi
