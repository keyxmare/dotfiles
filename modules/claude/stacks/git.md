# Stack — Git

## Branching strategy

### Trunk-based par défaut ← `git.strategy`

- La branche principale est `main`.
- Les features sont développées sur des branches courtes (`feature/xxx`, `fix/xxx`).
- Les branches de feature doivent être mergées rapidement (idéalement < 2 jours).
- Les branches `epic/` sont les seules branches longue durée autorisées en dehors de `main`. Elles regroupent plusieurs features liées à une même épopée.

### Création automatique de branche ← `git.auto_branch`

Quand `git.auto_branch` = `true`, créer automatiquement une branche feature avant toute modification de code sur `main` :

1. Détecter le type de changement (`feature/`, `fix/`, `refactor/`, etc.) à partir de la demande utilisateur.
2. Générer un nom de branche descriptif en kebab-case (ex: `feature/user-registration`, `fix/cart-total`).
3. Créer la branche et basculer dessus **sans demander confirmation** — c'est le comportement attendu.
4. Si l'utilisateur est déjà sur une branche feature, ne pas en créer une nouvelle.

### Nommage des branches

Format : `<type>/<description-kebab-case>`

| Type | Usage |
|---|---|
| `feature/` | Nouvelle fonctionnalité |
| `fix/` | Correction de bug |
| `hotfix/` | Fix urgent en production |
| `refactor/` | Refactoring sans changement fonctionnel |
| `chore/` | Maintenance, tooling, CI |
| `docs/` | Documentation uniquement |
| `epic/` | Branche longue durée regroupant plusieurs features |

Exemples : `feature/user-registration`, `fix/cart-total-calculation`, `hotfix/payment-crash`, `epic/checkout-redesign`

### Gitflow (si `git.strategy: gitflow`)

- Branches longue durée : `main` (production), `develop` (intégration).
- Features branchées depuis `develop`, mergées dans `develop`.
- `release/*` branchée depuis `develop` pour préparer une version, mergée dans `main` ET `develop`.
- `hotfix/*` branchée depuis `main`, mergée dans `main` ET `develop`.
- Merge commit classique (pas de squash) pour conserver la traçabilité des branches.

### Mise à jour des feature branches

- Avant de merger une PR, la branche doit être à jour avec la branche cible (`main` en trunk-based, `develop` en Gitflow).
- Utiliser `git rebase <branche-cible>` (pas `git merge`) pour garder un historique linéaire.
- En cas de conflits lors du rebase, les résoudre commit par commit.
- Ne jamais rebase une branche partagée (`epic/`, `develop`, `release/*`) — utiliser `git merge` dans ce cas.

## Conventional Commits

Tous les messages de commit suivent la spécification [Conventional Commits 1.0.0](https://www.conventionalcommits.org/).

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | SemVer |
|---|---|---|
| `feat` | Nouvelle fonctionnalité | MINOR |
| `fix` | Correction de bug | PATCH |
| `docs` | Documentation uniquement | — |
| `style` | Formatage, pas de changement de logique | — |
| `refactor` | Refactoring sans changement fonctionnel | — |
| `perf` | Amélioration de performance | — |
| `test` | Ajout ou correction de tests | — |
| `build` | Changement de build ou dépendances | — |
| `ci` | Configuration CI/CD | — |
| `chore` | Maintenance, tâches diverses | — |

### Scope

Le scope est optionnel et correspond au bounded context ou au module concerné :
`feat(catalog): add product search`, `fix(billing): correct tax calculation`

### Breaking changes

- Indiquer avec `!` après le type/scope : `feat(api)!: change auth endpoint`
- Ou via le footer : `BREAKING CHANGE: description`

### Règles

- Le message est en anglais.
- La description commence par un verbe à l'impératif, en minuscule.
- La description fait maximum 72 caractères.
- Le body explique le "pourquoi", pas le "quoi".
- Un commit = un changement logique. Ne pas mélanger feature et refactor.

## Pull Requests

### Règles

- Une PR par feature ou fix.
- Le titre suit le format conventional commits.
- La description contient un résumé et un plan de test.
- La PR doit passer tous les checks CI avant merge.
- Squash merge par défaut pour garder un historique propre. ← `git.merge_strategy`
- Supprimer la branche après merge.

### Template PR

Le template est défini dans `.github/PULL_REQUEST_TEMPLATE.md` (voir [stacks/ci.md](./ci.md#structure-des-workflows)) :

```markdown
## Summary
<!-- Résumé des changements en 1-3 bullet points -->

## Test plan
<!-- Comment tester ces changements -->
- [ ] ...
```

## Hooks

- Pre-commit : lint + format (via les outils de la stack).
- Commit-msg : validation du format conventional commits (commitlint ou équivalent).
- Pre-push : tests unitaires.

### Tooling

Utiliser un gestionnaire de hooks pour automatiser leur installation et leur exécution :

| Stack | Outil recommandé |
|---|---|
| Node / pnpm | [Lefthook](https://github.com/evilmartians/lefthook) (binaire Go, pas de dépendance Node) |
| PHP / Composer | [CaptainHook](https://github.com/captainhookphp/captainhook) ou [GrumPHP](https://github.com/phpro/grumphp) |
| Multi-stack | Lefthook (fonctionne indépendamment de la stack) |

Lefthook est le choix par défaut pour les projets monorepo car il est agnostique de la stack et ne nécessite pas Node.js.

### Template Lefthook (`lefthook.yml`)

```yaml
pre-commit:
  parallel: true
  commands:
    backend-lint:
      root: backend/
      run: make lint
    frontend-lint:
      root: frontend/
      run: make lint
    frontend-format:
      root: frontend/
      run: make format-check

commit-msg:
  commands:
    conventional-commit:
      run: 'head -1 "$1" | grep -qE "^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\(.+\))?!?: .{1,72}$"'
      fail_text: "Commit message must follow Conventional Commits: <type>[scope]: <description> (max 72 chars)"

pre-push:
  parallel: true
  commands:
    backend-test:
      root: backend/
      run: make test
    frontend-test:
      root: frontend/
      run: make test
```

> La validation commit-msg utilise une regex intégrée. Pour les projets nécessitant une validation plus poussée (scopes autorisés, body obligatoire pour breaking changes), installer [commitlint](https://commitlint.js.org/) et remplacer la commande par `npx commitlint --edit "$1"`.

## .gitignore

Le `.gitignore` doit inclure **au minimum** les entrées suivantes selon les stacks utilisées :

### PHP
```
vendor/
var/
.phpunit.result.cache
.php-cs-fixer.cache
.infection/
```

### Node / pnpm
```
node_modules/
dist/
.vite/
.nuxt/
.output/
.pnpm-store/
.stryker-tmp/
coverage/
reports/
*.tsbuildinfo
```

### Environnement
```
.env.local
.env.*.local
```

### Docker
```
docker/.env
```

### Claude Code
```
.claude/task-state.local.md
```

### IDE / OS
```
.idea/
.vscode/
*.swp
*.swo
.DS_Store
Thumbs.db
```

Le `.pnpm-store/` est créé localement quand pnpm tourne dans un container Docker avec un bind mount. Il doit toujours être exclu.

## Branch protection

Configurer les branch protection rules sur `main` (GitHub) ou les protected branches (GitLab) pour enforcer les règles automatiquement :

| Règle | Valeur |
|---|---|
| Require pull request before merging | Oui |
| Require status checks to pass | Oui (jobs CI : lint, test, security, build) |
| Require branches to be up to date | Oui |
| Do not allow bypassing | Oui (inclure les admins) |
| Allow force pushes | Non |
| Allow deletions | Non |

> Ces règles ne sont pas configurables via des fichiers versionnés. Les appliquer manuellement via l'interface GitHub/GitLab ou via Terraform/Pulumi si l'infra est codifiée.

## Règles générales

- Ne jamais push directement sur `main`.
- Ne jamais force push sur `main`.
- Utiliser `.gitignore` rigoureusement.
- Signer les commits si l'organisation le requiert. Configuration recommandée avec SSH (plus simple que GPG) :
  ```bash
  git config --global gpg.format ssh
  git config --global user.signingkey ~/.ssh/id_ed25519.pub
  git config --global commit.gpgsign true
  ```
- → Voir [security.md](./security.md#secrets) pour les règles de gestion des secrets et fichiers `.env`.
