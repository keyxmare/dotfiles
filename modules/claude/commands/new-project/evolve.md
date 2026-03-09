---
name: new-project:evolve
description: Fait évoluer un projet d'un profil/complexité vers un niveau supérieur
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Evolve

Fait évoluer un projet d'un profil ou niveau de complexité vers un niveau supérieur (`simple → standard → advanced`).

## Références

- Structure DDD → `<skill-path>/references/ddd-features.md`
- Templates → `<skill-path>/assets/templates/`
- Modules → `<skill-path>/references/modules.md`
- Règles communes → `<skill-path>/references/rules-common.md`
- Diagnostic → `<skill-path>/references/troubleshooting.md`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, ce micro-generator ne peut pas fonctionner — signaler à l'utilisateur.

Déterminer le profil (`profile`) et la complexité (`complexity`) actuels depuis `scaffold.config.json`.

## Arguments

```
/new-project:evolve                      → mode interactif (propose le niveau suivant)
/new-project:evolve standard             → migrer vers standard
/new-project:evolve advanced             → migrer vers advanced
/new-project:evolve --dry-run advanced   → afficher le plan de migration sans rien modifier
```

## Étape 0 — Validation

Vérifier que la migration demandée est valide :

| Depuis | Vers | Valide |
|---|---|---|
| simple | standard | oui |
| simple | advanced | oui (applique standard puis advanced) |
| standard | advanced | oui |
| advanced | standard | non — signaler que le downgrade n'est pas supporté |
| advanced | simple | non |
| standard | simple | non |

Si la migration n'est pas valide, expliquer pourquoi et s'arrêter.

## Étape 1 — Snapshot de sécurité

Créer un commit de sauvegarde avant toute modification :

```bash
git add .
git commit -m "chore: snapshot before evolving to <target>"
```

Ce commit sert de point de rollback si la migration échoue.

## Étape 2 — Plan de migration

### simple → standard

Éléments ajoutés :

1. **Tests** :
   - Tests de mutation (Infection PHP / Stryker JS) — config + premiers tests.
   - Tests E2E (Playwright) — config + premiers scénarios CRUD.
2. **CI** :
   - Matrice CI étendue (versions PHP/Node multiples).
   - Job de couverture de code.
   - Job de tests de mutation.
3. **Documentation** :
   - OpenAPI (`docs/api/openapi.yaml`) — générée depuis les controllers existants.
   - Diagrammes C4 (`docs/c4/`) — context et container.
4. **Sécurité** :
   - Security headers (CSP, HSTS, X-Frame-Options) dans le middleware/config.
   - Rate limiting sur les endpoints d'authentification (si module auth présent).
5. **Accessibilité** :
   - ESLint plugin a11y (si frontend présent).
   - Premiers tests axe-core dans les E2E.

### standard → advanced

Éléments ajoutés :

1. **Migration DDD/CQRS** — voir workflow détaillé ci-dessous.
2. **Architecture Decision Records** — `docs/adr/` avec template et premier ADR (migration vers DDD).
3. **Tests de mutation** — si pas encore présents, les ajouter.
4. **Tests d'architecture** — `tests/Architecture/` vérifiant les règles de dépendances entre couches (Domain ne dépend de rien, Application ne dépend pas d'Infrastructure, etc.).
5. **Outbox pattern** — si module messenger présent, ajouter l'outbox pour les events domain.

### simple → advanced

Applique séquentiellement `simple → standard` puis `standard → advanced`.

## Workflow de migration DDD/CQRS (standard → advanced)

C'est la migration la plus complexe. Chaque étape est atomique et vérifiée.

### 2a — Proposer les bounded contexts

Analyser les entités existantes dans `src/Entity/` et proposer un découpage en bounded contexts :

```
Bounded contexts proposés :

  Catalog       ← Product, Category, Tag
  Identity      ← User, Role
  Order         ← Order, OrderLine, Invoice

ok ? (ou modifie)
```

### 2b — Créer la structure DDD

Exécuter `<skill-path>/assets/init-structure.sh` ou créer manuellement la structure pour chaque context :

```
src/<Context>/
├── Domain/
│   ├── Model/
│   ├── ValueObject/
│   ├── Repository/
│   ├── Event/
│   └── Exception/
├── Application/
│   ├── Command/
│   ├── CommandHandler/
│   ├── Query/
│   ├── QueryHandler/
│   └── DTO/
└── Infrastructure/
    ├── Persistence/Doctrine/
    ├── Controller/
    └── Messenger/
```

### 2c — Déplacer les entités

Pour chaque entité `src/Entity/<Entity>.php` → `src/<Context>/Domain/Model/<Entity>.php` :

- Mettre à jour le namespace.
- Mettre à jour les attributs ORM (table name inchangé).
- Conserver toutes les relations Doctrine.

### 2d — Extraire les interfaces de repository

Pour chaque repository concret `src/Repository/<Entity>Repository.php` :

- Créer l'interface dans `src/<Context>/Domain/Repository/<Entity>RepositoryInterface.php`.
- Déplacer l'implémentation dans `src/<Context>/Infrastructure/Persistence/Doctrine/Doctrine<Entity>Repository.php`.
- L'implémentation implémente l'interface.

### 2e — Créer Commands/Queries/Handlers

Pour chaque méthode de Service existante :

- Méthodes de modification (create, update, delete) → `Command` + `CommandHandler`.
- Méthodes de lecture (find, list, get) → `Query` + `QueryHandler`.
- Créer les DTOs correspondants (Input/Output).

### 2f — Mettre à jour les controllers

Remplacer les appels directs aux services par le dispatch de commands/queries :

```php
// Avant
$this->productService->create($data);

// Après
$this->commandBus->dispatch(new CreateProductCommand($data));
```

### 2g — Mettre à jour les tests

- Déplacer les tests dans la nouvelle arborescence (`tests/Unit/<Context>/`, `tests/Integration/<Context>/`).
- Mettre à jour les namespaces et imports.
- Ajouter des tests pour les nouveaux handlers.

### 2h — Configurer les buses

Mettre à jour `config/services.yaml` et `config/packages/messenger.yaml` :

- Autowiring par context.
- Configuration du command bus et query bus.

### 2i — Mettre à jour les imports

Scanner tout le code pour les anciens namespaces et les remplacer par les nouveaux.

### 2j — Vérifier

```bash
make quality
```

Corriger les erreurs avant de passer à l'étape suivante.

## Étape 3 — Dry-run (si `--dry-run`)

Si `--dry-run` est passé, afficher le plan complet sans rien modifier :

```
Plan de migration — <nom du projet>
  simple → advanced

  Étape 1 : simple → standard
  ─────────────────────────────────────────────────────
  [CREATE] infection.json5                       Tests de mutation
  [CREATE] playwright.config.ts                  Tests E2E
  [CREATE] docs/api/openapi.yaml                 Documentation API
  [CREATE] docs/c4/context.md                    Diagramme C4
  [EDIT]   .github/workflows/ci.yml              Matrice CI étendue
  ...

  Étape 2 : standard → advanced
  ─────────────────────────────────────────────────────
  [MOVE]   src/Entity/Product.php → src/Catalog/Domain/Model/Product.php
  [CREATE] src/Catalog/Domain/Repository/ProductRepositoryInterface.php
  [MOVE]   src/Repository/ProductRepository.php → src/Catalog/Infrastructure/Persistence/Doctrine/DoctrineProductRepository.php
  [CREATE] src/Catalog/Application/Command/CreateProductCommand.php
  ...

Total : X fichiers créés, Y fichiers déplacés, Z fichiers modifiés
```

Puis s'arrêter.

## Étape 4 — Mise à jour de scaffold.config.json

Via `Edit` :

- Mettre à jour `complexity` avec le nouveau niveau.
- Mettre à jour `profile` si pertinent.
- Ajouter `bounded_contexts` si migration DDD.
- Mettre à jour `updated_at`.

## Étape 5 — Vérification finale

```bash
make quality                 # lint + tests
```

Corriger toutes les erreurs avant de terminer. Voir `<skill-path>/references/troubleshooting.md`.

## Étape 6 — Commit

```bash
git add .
git commit -m "feat: evolve project from <source> to <target>"
```

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Créer un snapshot git avant de commencer** — c'est le filet de sécurité. Ne jamais sauter cette étape.
- **Chaque étape de migration est atomique** — vérifier après chaque étape que le code compile et que les tests passent avant de continuer.
- **Ne jamais supprimer de code fonctionnel** — déplacer et refactorer. Les anciens fichiers sont déplacés, pas supprimés puis recréés.
- **Le downgrade n'est pas supporté** — la migration vers un niveau inférieur est trop destructrice pour être automatisée.
- **Migration DDD/CQRS** : toujours proposer les bounded contexts à l'utilisateur et attendre validation avant de déplacer les fichiers.
- **Conserver les tables Doctrine existantes** — les noms de tables en base ne changent pas, seuls les namespaces PHP changent.
