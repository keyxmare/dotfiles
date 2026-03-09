# Référence — Tests d'architecture

Tests automatisés qui vérifient les règles de dépendances entre couches. Activés si `tests.architecture` = `true`.

---

## Backend — Deptrac (si profil standard ou advanced)

### Installation

`qossmic/deptrac` dans les devDependencies de `composer.json`.

### Configuration

`deptrac.yaml` à la racine du backend :

#### Mode advanced (DDD/CQRS)

Layers :
- `Domain` : `src/*/Domain/**`
- `Application` : `src/*/Application/**`
- `Infrastructure` : `src/*/Infrastructure/**`
- `Shared` : `src/Shared/**`

Ruleset :
- `Domain` → (aucune dépendance sauf PHP natif + Doctrine ORM Mapping attributes)
- `Application` → `Domain`, `Shared`
- `Infrastructure` → `Application`, `Domain`, `Shared`
- Cross-context interdit : `src/Catalog/**` ne peut pas importer `src/Identity/**` (sauf via `Shared`)

```yaml
deptrac:
  paths:
    - src/
  layers:
    - name: Domain
      collectors:
        - type: directory
          value: src/*/Domain/.*
    - name: Application
      collectors:
        - type: directory
          value: src/*/Application/.*
    - name: Infrastructure
      collectors:
        - type: directory
          value: src/*/Infrastructure/.*
    - name: Shared
      collectors:
        - type: directory
          value: src/Shared/.*
  ruleset:
    Domain: []
    Application:
      - Domain
      - Shared
    Infrastructure:
      - Application
      - Domain
      - Shared
    Shared: []
```

#### Mode simple

Layers :
- `Controller` : `src/Controller/**`
- `Service` : `src/Service/**`
- `Entity` : `src/Entity/**`
- `Repository` : `src/Repository/**`

Ruleset :
- `Entity` → (aucune dépendance)
- `Repository` → `Entity`
- `Service` → `Entity`, `Repository`
- `Controller` → `Service`, `Entity`

```yaml
deptrac:
  paths:
    - src/
  layers:
    - name: Entity
      collectors:
        - type: directory
          value: src/Entity/.*
    - name: Repository
      collectors:
        - type: directory
          value: src/Repository/.*
    - name: Service
      collectors:
        - type: directory
          value: src/Service/.*
    - name: Controller
      collectors:
        - type: directory
          value: src/Controller/.*
  ruleset:
    Entity: []
    Repository:
      - Entity
    Service:
      - Entity
      - Repository
    Controller:
      - Service
      - Entity
```

### Target Makefile / Taskfile

```makefile
.PHONY: deptrac
deptrac: ## Vérifie les règles d'architecture
	$(DC_EXEC_BACKEND) vendor/bin/deptrac analyse --config-file=deptrac.yaml
```

### CI

Ajouter un job `architecture` dans la CI (après lint, avant test) :

```yaml
architecture:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Architecture tests
      run: docker compose exec -T backend vendor/bin/deptrac analyse --config-file=deptrac.yaml
```

---

## Frontend — eslint-plugin-boundaries (si Nuxt ou Vue + advanced)

### Installation

`eslint-plugin-boundaries` + `eslint-plugin-perfectionist` dans les devDependencies du frontend.

`eslint-plugin-perfectionist` auto-sort les imports, exports et objets — cohérence garantie sans effort. Configurer en mode `natural` (alphabétique).

### Configuration

Dans `eslint.config.js`, définir les zones par bounded context :

```javascript
import boundaries from 'eslint-plugin-boundaries'

export default [
  {
    plugins: { boundaries },
    settings: {
      'boundaries/elements': [
        { type: 'shared', pattern: ['app/shared/*', 'shared/*'], mode: 'folder' },
        { type: 'identity', pattern: ['app/identity/*'], mode: 'folder' },
        { type: 'catalog', pattern: ['app/catalog/*'], mode: 'folder' },
        // ... un par bounded context
      ],
      'boundaries/ignore': ['**/*.test.*', '**/*.spec.*'],
    },
    rules: {
      'boundaries/element-types': ['error', {
        default: 'disallow',
        rules: [
          { from: 'shared', allow: ['shared'] },
          { from: 'identity', allow: ['identity', 'shared'] },
          { from: 'catalog', allow: ['catalog', 'shared'] },
          // chaque context ne peut importer que lui-même et shared
        ],
      }],
    },
  },
]
```

Les zones sont générées dynamiquement à partir des `bounded_contexts` du `scaffold.config.json`.

---

## Quand générer

| Condition | Action |
|---|---|
| `/new-project` avec `tests.architecture: true` | Générer deptrac.yaml + eslint boundaries à l'étape 6 |
| `/new-project:bounded-context` | Mettre à jour deptrac.yaml et eslint boundaries avec le nouveau context |
| `/new-project:entity` | Rien — les règles existantes couvrent déjà le nouveau code |
| `/new-project:evolve` vers advanced | Générer deptrac.yaml + boundaries au moment de la migration DDD |
| `/new-project:remove` bounded-context | Retirer le context de deptrac.yaml et eslint boundaries |
