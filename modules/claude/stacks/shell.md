# Stack — Shell (Bash / Sh / Zsh)

## Shells supportés

- **Bash** (5.x+) — Shell par défaut pour les scripts.
- **Sh** (POSIX) — Pour la portabilité maximale.
- **Zsh** (5.x+) — Pour les plugins, dotfiles et outils interactifs.

Toujours spécifier le shell cible dans le shebang. Ne pas utiliser `#!/bin/sh` si le script utilise des features Bash.

## Conventions de code

### Shebang et options

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e` — Exit immédiat en cas d'erreur.
- `set -u` — Erreur sur variable non définie.
- `set -o pipefail` — Propager les erreurs dans les pipes.
- Pour les scripts POSIX (`sh`) : `set -eu` uniquement (`pipefail` n'est pas POSIX).
- Pour Zsh : `#!/usr/bin/env zsh` avec `setopt ERR_EXIT PIPE_FAIL NO_UNSET`.

### Nommage

- Fichiers : `kebab-case` sans extension pour les exécutables, `.sh` / `.bash` / `.zsh` pour les fichiers sourcés.
- Fonctions : `snake_case`.
- Variables locales : `snake_case`, déclarées avec `local`.
- Variables globales / constantes : `UPPER_SNAKE_CASE`, déclarées avec `readonly`.
- Variables d'environnement exportées : `UPPER_SNAKE_CASE`, déclarées avec `export`.

### Variables

```bash
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

local my_var="value"
```

- Toujours quoter les variables : `"$var"`, jamais `$var` nu.
- Utiliser `${var:-default}` pour les valeurs par défaut.
- Utiliser `${var:?error message}` pour les variables requises.
- Déclarer `local` dans les fonctions pour éviter les fuites de scope.
- Utiliser `readonly` pour les constantes.

### Fonctions

```bash
my_function() {
    local arg1="$1"
    local arg2="${2:-default}"

    # ...
}
```

- Pas de mot-clé `function` — utiliser la syntaxe POSIX `name()`.
- Toujours déclarer les paramètres en `local` en début de fonction.
- Une fonction = une responsabilité.
- Retourner des codes d'erreur explicites (`return 0`, `return 1`).
- Préférer les substitutions de commande `$(...)` aux backticks `` `...` ``.

### Structures de contrôle

```bash
if [[ -f "$file" ]]; then
    # ...
elif [[ -d "$dir" ]]; then
    # ...
fi

for item in "${array[@]}"; do
    # ...
done

while IFS= read -r line; do
    # ...
done < "$file"
```

- Utiliser `[[ ]]` au lieu de `[ ]` en Bash/Zsh (meilleur parsing, pas besoin de quoter dans les tests).
- Pour POSIX `sh` : utiliser `[ ]` avec quotes.
- Toujours utiliser `"$@"` pour passer les arguments, jamais `$*`.

### Gestion des erreurs

```bash
trap 'cleanup' EXIT
trap 'error_handler "$LINENO" "$?"' ERR

cleanup() {
    rm -rf "$tmp_dir"
}

error_handler() {
    local line="$1"
    local exit_code="$2"
    log_error "Erreur ligne $line (code $exit_code)"
}

die() {
    log_error "$@"
    exit 1
}
```

- Toujours utiliser `trap` pour le nettoyage (`EXIT`, `ERR`, `INT`, `TERM`).
- Créer une fonction `die` pour les erreurs fatales.
- Utiliser `trap ... ERR` pour capturer les erreurs non gérées.
- Nettoyer les fichiers temporaires via `trap ... EXIT`.

### Output et logging

→ Voir [makefile.md](./makefile.md) pour les conventions de couleurs et formatage d'affichage.

- Logger sur `stderr` (`>&2`), réserver `stdout` pour les données.
- Utiliser `printf` au lieu de `echo` pour la portabilité.
- Détecter si le terminal supporte les couleurs avant de les utiliser : `[[ -t 2 ]]`.

### Parsing des arguments

```bash
usage() {
    cat <<EOF
Usage: $(basename "$0") [options] <argument>

Options:
    -h, --help      Affiche cette aide
    -v, --verbose   Mode verbeux
    -o, --output    Fichier de sortie
EOF
}

parse_args() {
    local VERBOSE=false
    local OUTPUT=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)    usage; exit 0 ;;
            -v|--verbose) VERBOSE=true; shift ;;
            -o|--output)  OUTPUT="$2"; shift 2 ;;
            --)           shift; break ;;
            -*)           die "Option inconnue : $1" ;;
            *)            break ;;
        esac
    done
}
```

- Supporter les formes courtes (`-v`) et longues (`--verbose`).
- Toujours fournir une option `--help` / `-h`.
- Utiliser `--` pour séparer les options des arguments positionnels.
- Pour les CLI complexes : envisager un framework (voir section Outils).

### Sécurité

- Ne jamais utiliser `eval` avec des entrées utilisateur.
- Ne jamais utiliser `source` sur un fichier non fiable.
- Utiliser `mktemp` pour les fichiers temporaires, jamais de chemin fixe dans `/tmp`.
- Valider et sanitizer toutes les entrées externes.
- Préférer les chemins absolus pour les commandes critiques (`/usr/bin/rm` vs `rm`).

## Outils

| Outil | Usage |
|---|---|
| ShellCheck | Analyse statique (linter) |
| shfmt | Formatage automatique |
| Bats | Tests unitaires et intégration |
| bats-assert | Assertions pour Bats |
| bats-support | Helpers de base pour Bats (requis par bats-assert) |
| bats-file | Assertions filesystem pour Bats |

## ShellCheck

Linter statique pour scripts shell. Détecte les erreurs de syntaxe, les problèmes de portabilité, les failles de sécurité et les mauvaises pratiques.

### Configuration

Fichier `.shellcheckrc` à la racine du projet :

```shellcheckrc
shell=bash
severity=style
```

### Directives inline

```bash
# shellcheck disable=SC2086
echo $variable_volontairement_non_quotee

# shellcheck source=./lib/config.sh
source "$CONFIG_DIR/config.sh"

# shellcheck source-path=SCRIPTDIR
source "$here/utils.sh"
```

- Désactiver un warning uniquement avec justification.
- Utiliser `source=` pour aider ShellCheck à résoudre les sources dynamiques.
- Utiliser `source-path=SCRIPTDIR` quand les sources sont relatives au script.

### Erreurs courantes détectées

- Variables non quotées (SC2086).
- Glob qui peut devenir une option (SC2035).
- Injection de commande via `eval` ou expansion non protégée.
- Masquage du code de retour avec `export VAR=$(cmd)` (SC2155).
- Itération sur `ls` au lieu de globs (SC2045).
- `cd` sans vérification d'erreur (SC2164).

## shfmt

Formateur automatique pour scripts shell.

### Configuration

Utiliser un fichier `.editorconfig` (shfmt le respecte) :

```editorconfig
[*.{sh,bash,zsh}]
indent_style = space
indent_size = 4
shell_variant = bash
binary_next_line = true
switch_case_indent = true
```

### Utilisation

```bash
shfmt -d .          # Vérifier (dry-run)
shfmt -w .          # Corriger
shfmt -i 4 -bn -ci  # Options inline : indent 4, binary next line, case indent
```

## Tests avec Bats

### Structure du projet de tests

```
tests/
├── test_helper/
│   ├── common-setup.bash          ← Setup commun à tous les tests
│   └── bats-libs/                 ← Libs Bats installées (git submodules ou binstubs)
│       ├── bats-support/
│       ├── bats-assert/
│       └── bats-file/
├── unit/
│   ├── my-function.bats           ← Tests unitaires
│   └── another-function.bats
└── integration/
    └── my-script.bats             ← Tests d'intégration
```

### Setup commun

```bash
# tests/test_helper/common-setup.bash

_common_setup() {
    load 'bats-libs/bats-support/load'
    load 'bats-libs/bats-assert/load'
    load 'bats-libs/bats-file/load'

    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." >/dev/null 2>&1 && pwd)"
    PATH="$PROJECT_ROOT/bin:$PROJECT_ROOT/lib:$PATH"
}
```

### Écriture des tests

```bats
#!/usr/bin/env bats

setup() {
    load 'test_helper/common-setup'
    _common_setup

    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP_DIR"
}

@test "my-script prints usage with --help" {
    run my-script --help
    assert_success
    assert_output --partial "Usage:"
}

@test "my-script fails without required argument" {
    run my-script
    assert_failure
    assert_output --partial "Error"
}

@test "my-script processes input file" {
    echo "test content" > "$TEST_TEMP_DIR/input.txt"
    run my-script "$TEST_TEMP_DIR/input.txt"
    assert_success
    assert_output "test content"
}

@test "my-script handles empty file" {
    touch "$TEST_TEMP_DIR/empty.txt"
    run my-script "$TEST_TEMP_DIR/empty.txt"
    assert_success
    assert_output ""
}
```

### Assertions

Consulter la documentation officielle Bats pour la liste complète des assertions disponibles.

### Installation des libs Bats

Via git submodules (recommandé) :

```bash
git submodule add https://github.com/bats-core/bats-support tests/test_helper/bats-libs/bats-support
git submodule add https://github.com/bats-core/bats-assert tests/test_helper/bats-libs/bats-assert
git submodule add https://github.com/bats-core/bats-file tests/test_helper/bats-libs/bats-file
```

## Makefile

Suit les conventions de [makefile.md](./makefile.md) (couleurs, help, `.DEFAULT_GOAL`, `.PHONY`). Pas de Docker pour les scripts shell — exécution directe.

Variable : `SHELL_FILES = $(shell find bin/ lib/ -type f -name '*.sh' -o -name '*.bash' -o -name '*.zsh' 2>/dev/null) $(shell find bin/ -type f ! -name '*.*' 2>/dev/null)`

| Target | Commande | Description |
|---|---|---|
| `run` | `bin/$(notdir $(CURDIR))` | Lance le script principal |
| `test` | `bats tests/` | Lance les tests Bats |
| `lint` | `shellcheck $(SHELL_FILES)` | Lance ShellCheck |
| `format` | `shfmt -w $(SHELL_FILES)` | Formate avec shfmt |
| `format-check` | `shfmt -d $(SHELL_FILES)` | Vérifie le formatage (dry-run) |
| `quality` | `lint format-check test` | Tous les checks qualité |

## CI/CD

### GitHub Actions

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - name: Install ShellCheck
        run: sudo apt-get install -y shellcheck
      - name: Lint
        run: make lint

  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - name: Install shfmt
        run: go install mvdan.cc/sh/v3/cmd/shfmt@latest
      - name: Format check
        run: make format-check

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
        with:
          submodules: true
      - name: Install Bats
        run: sudo apt-get install -y bats
      - name: Test
        run: make test
```
