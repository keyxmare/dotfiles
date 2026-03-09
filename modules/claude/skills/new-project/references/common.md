# Référence — Éléments communs à tous les types

## CLAUDE.md du projet

Créer `.claude/CLAUDE.md` dans le projet :

```markdown
# <project-name>

## Description

<description du projet>

## Type

<Application web | Script / CLI | Librairie / Package>

## Stack

<détail de la stack choisie>

## Configuration

Les valeurs ci-dessous surchargent la configuration globale (~/.claude/CONFIG.md).
Seules les valeurs différentes des défauts globaux sont listées.

| Clé | Valeur |
|---|---|
| `<clé>` | `<valeur>` |

## Bounded Contexts

<liste des bounded contexts si mode advanced, sinon supprimer cette section>

## Modules

<liste des modules activés, sinon supprimer cette section>
```

Ne lister que les valeurs qui **diffèrent** des défauts globaux.

---

## CONTRIBUTING.md

Générer à la racine :

```markdown
# Contribuer à <project-name>

## Prérequis

- Docker et Docker Compose
- Make
- Git

Vérifier l'installation : `make doctor`

## Installation

\`\`\`bash
make install
make up
\`\`\`

## Workflow

1. Créer une branche : `git checkout -b feature/ma-feature`
2. Développer avec les tests : `make test`
3. Vérifier la qualité : `make quality`
4. Commit : conventional commits (`feat:`, `fix:`, `docs:`, etc.)
5. Push et créer une PR

## Commandes utiles

`make help` pour voir toutes les commandes disponibles.
```

Adapter selon le type (retirer Docker si non activé, ajuster les commandes).

---

## Git hooks

Lire et suivre `~/.claude/stacks/git.md`.

### .gitignore

Complet et adapté aux stacks sélectionnées.

### .editorconfig

Standard pour le projet.

### Hook commit-msg (conventional commits)

Créer `.githooks/commit-msg` :

```bash
#!/bin/sh
commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?(!)?: .{1,}$'
if ! head -1 "$1" | grep -qE "$commit_regex"; then
  echo "Format de commit invalide. Utiliser conventional commits :"
  echo "  feat: description"
  echo "  fix(scope): description"
  exit 1
fi
```

Configurer git : `git config core.hooksPath .githooks`

Target Makefile :

```makefile
.PHONY: hooks
hooks: ## Installe les git hooks
	@git config core.hooksPath .githooks
	@chmod +x .githooks/*
	@echo "Git hooks installés"
```

### .gitmessage

Générer `.gitmessage` à la racine pour guider les développeurs :

```
# <type>(<scope>): <subject>
#
# Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
# Scope: optional, e.g. auth, catalog, frontend
# Subject: imperative, lowercase, no period
#
# Body: explain what and why (not how)
#
# Footer: BREAKING CHANGE, Fixes #123
```

Configurer dans le Makefile (target `hooks`) : `git config commit.template .gitmessage`

### Template PR (GitHub)

`.github/PULL_REQUEST_TEMPLATE.md`.

---

## Commits intermédiaires (scaffold)

Pendant le scaffolding (`/new-project`), créer des commits intermédiaires pour permettre un rollback propre en cas de problème :

| Moment | Message de commit | Contenu |
|---|---|---|
| Après étape 7 (scaffold validé) | `feat: scaffold project structure` | Arborescence + config + code structurel + modules |
| Après chaque feature (étape 8) | `feat(<context>): add <Entity> CRUD` | Code + tests + doc de la feature |
| Fin (étape 10) | Pas de commit supplémentaire — le git init final fait un squash | — |

### Comportement

- Les commits intermédiaires sont créés **dans le répertoire du projet**.
- Git est initialisé **dès le début de l'étape 6** (avant le scaffold) pour pouvoir committer et permettre le rollback.
- Si une feature échoue et que l'utilisateur veut revenir en arrière : `git reset --hard HEAD~1` revient au dernier état propre.
- À l'étape 10, le git init final est déjà fait — on a un historique propre par feature.

### Commande de rollback

Si l'utilisateur demande d'annuler la dernière feature :

```bash
git log --oneline -5     # voir les commits récents
git reset --hard HEAD~1   # revenir au commit précédent
```

---

## CI/CD

### GitHub Actions (`ci.provider` = `github`)

```
.github/
├── workflows/
│   ├── ci.yml                 ← pipeline principal (PR + push main)
│   ├── deploy.yml             ← déploiement (reusable workflow) — si app web
│   └── security.yml           ← audit de sécurité (schedule hebdo) — si app web
└── PULL_REQUEST_TEMPLATE.md
```

`ci.yml` — `concurrency`, `permissions: contents: read`, actions épinglées par SHA. Jobs en parallèle :

| Type | Jobs |
|---|---|
| App web | lint-backend, lint-frontend, test-backend, test-frontend, build, security |
| Script/CLI | lint, test |
| Librairie | lint, test, coverage, mutation, build |

Si `tests.architecture` = `true` : ajouter un job `architecture` (après lint, avant test) qui exécute `deptrac analyse` (backend) et le lint boundaries (frontend). Voir `references/architecture-tests.md`.

### Dependabot (si `ci.dependabot` = `true`)

Générer `.github/dependabot.yml` :

```yaml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/backend"
    schedule:
      interval: "weekly"
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]
  - package-ecosystem: "npm"
    directory: "/frontend"
    schedule:
      interval: "weekly"
    groups:
      minor-and-patch:
        update-types: ["minor", "patch"]
  - package-ecosystem: "docker"
    directory: "/docker"
    schedule:
      interval: "monthly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

Adapter les `directory` et `package-ecosystem` selon le type de projet (retirer ceux non pertinents).

### Matrix testing (si `ci.matrix_testing` = `true`)

Dans `ci.yml`, tester sur plusieurs versions :

```yaml
strategy:
  matrix:
    php-version: ['8.3', '8.4']
    node-version: ['20', '22']
```

Appliquer la matrice aux jobs de test backend et frontend.

### GitLab CI (`ci.provider` = `gitlab`)

`.gitlab-ci.yml` avec stages lint → test → build → security → deploy. Mêmes jobs, syntaxe GitLab (`rules`, `cache`, `artifacts`).

### Bonnes pratiques

Actions/images épinglées par SHA, cache dépendances, permissions minimales, secrets dans les variables CI, `concurrency` pour annuler les pipelines obsolètes.
- `dependabot.yml` pour les mises à jour automatiques de dépendances (si `ci.dependabot`).
- Matrix testing sur PHP 8.3/8.4 et Node 20/22 (si `ci.matrix_testing`).

---

## Documentation (si `doc.enabled`)

```
docs/
├── README.md              ← vue d'ensemble, quickstart
├── SETUP.md               ← prérequis, installation, variables d'env
├── ARCHITECTURE.md        ← si app web : stack, choix techniques, patterns
├── c4/                    ← si doc.c4
│   ├── README.md
│   └── context.md         ← C1 en Mermaid (C2 si app web)
├── api/                   ← si doc.openapi
│   ├── README.md
│   └── openapi.yaml       ← uniquement endpoints réellement créés
├── adr/                   ← si doc.adr
│   ├── README.md
│   └── 0001-initial-architecture.md
└── features/              ← si advanced
    ├── README.md
    └── [context].md       ← périmètre du bounded context
```

Règles :
- **La documentation ne doit jamais décrire quelque chose qui n'existe pas dans le code.**
- Diagrammes C4 en Mermaid — consulter la doc Mermaid avant génération.
- Si `doc.c4` + app web → C1 (context) ET C2 (container) au minimum.
- OpenAPI : squelette vide (`paths: {}`) si pas de features, sinon endpoints réels.

---

## Sécurité

Suivre `~/.claude/stacks/security.md` :
- `.env.example` sans vraies valeurs.
- `.gitignore` exclut les fichiers sensibles.
