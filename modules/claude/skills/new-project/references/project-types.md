# Référence — Script / CLI et Librairie

## Script / CLI

### PHP

```
<project>/
├── README.md, CONTRIBUTING.md, .gitignore, .editorconfig, Makefile, scaffold.config.json
├── bin/<project-name>           ← point d'entrée exécutable
├── src/
├── tests/Unit/
├── composer.json                ← symfony/console si CLI
├── phpunit.xml.dist (ou pest.php si Pest), phpstan.neon, .php-cs-fixer.dist.php
├── docker/                      ← si Docker activé
├── docs/                        ← si doc.enabled
└── .github/ ou .gitlab/
```

- Créer `bin/<project-name>` comme point d'entrée exécutable.
- Si CLI : `symfony/console` dans `composer.json`.
- **Symfony 8 — Invokable Commands** : Utiliser le pattern invokable avec `#[AsCommand]` et `#[MapInput]` pour les commandes CLI :

```php
<?php

declare(strict_types=1);

namespace App\Command;

use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Attribute\MapInput;
use Symfony\Component\Console\Command\Command;

#[AsCommand(name: 'app:import', description: 'Import data from source')]
final readonly class ImportCommand
{
    public function __invoke(
        #[MapInput(description: 'Source file path')]
        string $source,
        #[MapInput(description: 'Dry run mode')]
        bool $dryRun = false,
    ): int {
        // command logic
        return Command::SUCCESS;
    }
}
```

  Plus besoin d'hériter de `Command` ni d'implémenter `configure()` / `execute()`. Les arguments et options sont mappés directement via les attributs `#[MapInput]`.
- Makefile : `run`, `test`, `lint`, `install`, `doctor`. Pas de `up`/`down` si pas Docker.
- Si `tests.php_framework` = `pest` : `pestphp/pest` au lieu de `phpunit/phpunit` dans `composer.json`.

### TypeScript

```
<project>/
├── README.md, CONTRIBUTING.md, .gitignore, .editorconfig, Makefile, scaffold.config.json
├── bin/<project-name>.ts        ← point d'entrée
├── src/
├── tests/unit/
├── package.json                 ← tsx, commander ou citty
├── tsconfig.json, eslint.config.js, prettier.config.js, vitest.config.ts
├── docker/                      ← si Docker activé
├── docs/                        ← si doc.enabled
└── .github/ ou .gitlab/
```

- `package.json` avec `tsx` pour l'exécution TypeScript directe.
- Si CLI : `commander` ou `citty` dans les dépendances.
- Makefile : `run`, `test`, `lint`, `install`, `doctor`.
- Package manager selon `frontend.package_manager` : adapter lockfile et commandes.

### Shell

Lire et suivre `~/.claude/stacks/shell.md`.

```
<project>/
├── README.md, CONTRIBUTING.md, .gitignore, .editorconfig, .shellcheckrc, Makefile, scaffold.config.json
├── bin/<project-name>           ← shebang + set -euo pipefail
├── lib/
├── tests/
│   ├── test_helper/ (common-setup.bash, bats-libs/)
│   ├── unit/*.bats
│   └── integration/*.bats
├── docs/                        ← si doc.enabled
└── .github/ ou .gitlab/
```

- Demander le shell cible : Bash (défaut), Sh (POSIX), Zsh.
- `.shellcheckrc` avec `shell=bash` (ou sh/zsh selon le choix).
- `tests/test_helper/common-setup.bash` avec chargement bats-assert, bats-support, bats-file.
- Libs Bats via git submodules.
- Makefile : `run`, `test` (bats), `lint` (shellcheck), `format` / `format-check` (shfmt), `quality`, `doctor`.
- Pas de Docker par défaut.

---

## Librairie / Package

### PHP (Composer)

```
<project>/
├── README.md, CONTRIBUTING.md, .gitignore, .editorconfig, Makefile, LICENSE, scaffold.config.json
├── src/
├── tests/ (Unit/, Integration/)
├── composer.json                ← configuré pour Packagist (namespace, autoload, description, license)
├── phpunit.xml.dist (ou pest.php si Pest), phpstan.neon, .php-cs-fixer.dist.php
├── docs/                        ← si doc.enabled
└── .github/ ou .gitlab/
```

- Makefile : `test`, `lint`, `lint-fix`, `phpstan`, `quality`, `install`, `doctor`.
- Pas de Docker par défaut.
- CI orientée qualité : lint, tests, coverage, mutation testing.
- Si `tests.php_framework` = `pest` : `pestphp/pest` dans `composer.json`.

### TypeScript / JavaScript (npm)

```
<project>/
├── README.md, CONTRIBUTING.md, .gitignore, .editorconfig, Makefile, LICENSE, scaffold.config.json
├── src/index.ts
├── tests/unit/
├── package.json                 ← configuré pour npm (name, main, types, exports, files)
├── tsconfig.json, tsconfig.build.json, eslint.config.js, prettier.config.js, vitest.config.ts
├── docs/                        ← si doc.enabled
└── .github/ ou .gitlab/
```

- Build via `tsup` ou `unbuild`.
- Package manager selon `frontend.package_manager`.
- Makefile : `build`, `test`, `lint`, `lint-fix`, `format`, `quality`, `install`, `doctor`.
- Pas de Docker par défaut.
