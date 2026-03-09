# Stack — Point d'entrée

## Principe

Les instructions spécifiques à chaque stack sont isolées dans des fichiers dédiés dans le dossier `stacks/`. Charger le fichier correspondant à la stack du projet :

- **Projet existant** — Détecter la stack en analysant les fichiers du projet (composer.json, package.json, Cargo.toml, etc.) et charger le fichier correspondant.
- **Nouveau projet** — Demander la stack à l'utilisateur et charger le fichier correspondant.

## Stacks disponibles

| Stack | Fichier |
|---|---|
| Structure de projet | [stacks/project-structure.md](./stacks/project-structure.md) |
| Docker | [stacks/docker.md](./stacks/docker.md) |
| Makefile | [stacks/makefile.md](./stacks/makefile.md) |
| Patterns d'architecture (base) | [stacks/patterns.md](./stacks/patterns.md) |
| Patterns async & résilience | [stacks/patterns-async.md](./stacks/patterns-async.md) |
| PHP / Symfony | [stacks/symfony.md](./stacks/symfony.md) |
| Symfony / CQRS & Messenger | [stacks/symfony-cqrs.md](./stacks/symfony-cqrs.md) |
| Symfony / Tests & Qualité | [stacks/symfony-testing.md](./stacks/symfony-testing.md) |
| Nuxt | [stacks/nuxt.md](./stacks/nuxt.md) |
| Vue.js | [stacks/vue.md](./stacks/vue.md) |
| Vue.js / Tests & Qualité | [stacks/vue-testing.md](./stacks/vue-testing.md) |
| Git | [stacks/git.md](./stacks/git.md) |
| API REST | [stacks/api.md](./stacks/api.md) |
| Sécurité | [stacks/security.md](./stacks/security.md) |
| Shell (Bash / Sh / Zsh) | [stacks/shell.md](./stacks/shell.md) |
| CI/CD | [stacks/ci.md](./stacks/ci.md) |
| Base de données | [stacks/database.md](./stacks/database.md) |

## Matrice de chargement

| Type de tâche | Stacks à charger |
|---|---|
| Fix/feature backend | symfony.md, symfony-testing.md, patterns.md, git.md |
| Fix/feature backend (CQRS) | symfony.md, symfony-cqrs.md, symfony-testing.md, patterns-async.md, git.md |
| Fix/feature frontend | nuxt.md ou vue.md, vue-testing.md, git.md |
| Full-stack | symfony.md, nuxt/vue.md, patterns.md, git.md, api.md |
| Full-stack (CQRS) | + symfony-cqrs.md, patterns-async.md |
| Nouveau projet / scaffold | project-structure.md, docker.md, makefile.md, + stacks du projet |
| CI/CD | ci.md, git.md |
| Script shell | shell.md, git.md |
| Schema / migrations seules | database.md, git.md |
| Refacto BDD / migrations | database.md, symfony.md |
| Review / commit seul | git.md uniquement |
| Sécurité | security.md, + stack concernée |
| Design / modification API | api.md, + stack backend |
| Doc API / OpenAPI seule | api.md, git.md |

## Surcharge

Un projet peut compléter ou surcharger les instructions de stack via son propre CLAUDE.md local.
