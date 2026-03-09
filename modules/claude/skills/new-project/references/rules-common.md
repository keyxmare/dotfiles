# Référence — Règles communes

Règles applicables au skill principal et à tous les micro-generators.

## Code

- `declare(strict_types=1)` sur tous les fichiers PHP.
- `final` et `readonly` sur les classes PHP.
- Pas de commentaires dans le code (sauf si `code.comments: true`).
- **Doctrine : PHP attributes** sur les entités (plus de mapping XML — Symfony 8). Template `entity.php.tpl`.
- Conventions de nommage : voir `references/ddd-features.md`.
- **Invokable Commands** (Symfony 8) : les commandes console utilisent `#[AsCommand]` et `#[MapInput]` au lieu d'hériter de `Command`. Voir `references/project-types.md`.
- **Tests d'architecture** (si `tests.architecture: true`) : `deptrac` vérifie les règles de dépendances entre couches. Voir `references/architecture-tests.md`.
- **Relations Doctrine** : les relations entre entités génèrent les attributs ORM appropriés et les types TypeScript. Voir la section "Relations entre entités" dans `references/ddd-features.md`.

## Fichiers

- **Utiliser `Edit`** pour modifier les fichiers existants, `Write` uniquement pour les nouveaux fichiers.
- **Fichiers de config partagés** (`services.yaml`, `scaffold.config.json`, `composer.json`, `package.json`, `compose.yaml`, `openapi.yaml`, `routes.ts`) → toujours `Edit`, jamais écraser.

## Exécution

- **Commandes runtime via Docker** si `containers.runtime_only` = `true`. Voir `~/.claude/CONFIG.md`.
- **Recherche avant implémentation** si `research.before_impl` = `true` dans `scaffold.config.json.config` ou `~/.claude/CONFIG.md`.

## Tests

- **Tests immédiatement après chaque feature** — ne pas accumuler le code non testé.
- Si `tests.php_framework` = `pest` : générer les tests en syntaxe Pest. Utiliser les templates `*-pest.php.tpl`. Voir `references/ddd-features.md` (section "Tests Pest").
- Si `frontend.package_manager` est défini : utiliser le package manager correspondant.

## Gestion des conflits

Avant de créer un fichier, vérifier s'il existe déjà :
- **Fichier identique** → ignorer silencieusement.
- **Fichier différent** → signaler le conflit et demander : `écraser`, `garder`, `diff`.
- **Fichier de config partagé** → toujours modifier via `Edit`, ne jamais écraser.

## Diagnostic

Voir `references/troubleshooting.md` pour le tableau de diagnostic des erreurs courantes.
