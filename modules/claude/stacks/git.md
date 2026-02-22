# Conventions Git

## Conventional Commits
Format : `<type>(<scope>): <description>`

### Types
- `feat` : nouvelle fonctionnalité
- `fix` : correction de bug
- `refactor` : refactoring sans changement de comportement
- `test` : ajout ou modification de tests
- `docs` : documentation
- `style` : formatage, semicolons, etc. (pas de changement de logique)
- `chore` : maintenance, dépendances, CI/CD
- `perf` : amélioration de performance
- `ci` : changements CI/CD

### Scope
- Utiliser le Bounded Context ou le module concerné comme scope.
- Exemples : `feat(order): add cancel order command`, `fix(auth): handle expired token`

### Règles
- Description en anglais, impératif, minuscule, sans point final.
- Une ligne max pour le sujet (< 72 caractères).
- Body optionnel pour le contexte et le "pourquoi".
- Footer pour les breaking changes : `BREAKING CHANGE: description`.

## Branches
Format : `<type>/<description-courte>`
- `feature/add-order-cancellation`
- `fix/expired-token-handling`
- `refactor/user-bounded-context`
- `chore/upgrade-symfony-8`

### Règles
- Toujours brancher depuis `main` (ou `develop` si le projet utilise git-flow).
- Une branche = une feature/fix. Pas de branches fourre-tout.
- Supprimer les branches mergées.

## Pull Requests
- Titre : même format que conventional commits.
- Description :
  - Résumé en 1-3 bullet points
  - Bounded Context impacté
  - Plan de test
- Toujours relire le diff complet avant de créer une PR.
