# Référence — Exécution du scaffold (Étapes 6-10)

## Étape 6 — Scaffold du projet vide

Créer le projet **sans logique métier**. L'objectif est d'avoir une base qui build, lint et teste à vide avant d'ajouter les features.

Appeler `EnterPlanMode` avant de commencer. Lister tous les fichiers à créer avec leur rôle. Une fois le plan validé, appeler `ExitPlanMode` et exécuter.

### Initialisation Git

Initialiser git au début du scaffold pour permettre les commits intermédiaires et le rollback :

```bash
cd <project-path>
git init
git config core.hooksPath .githooks
```

### Résolution des versions

Lire `<skill-path>/assets/versions.json` pour les versions fallback. Si `research.before_impl` = `true`, tenter de résoudre les versions majeures actuelles via context7 et utiliser `versions.json` comme fallback.

### Ordre d'exécution

```
 1. Git init             ← git init + hooks
 2. Arborescence         ← scripts/init-structure.sh
 3. scaffold.config.json ← valider contre assets/scaffold.config.schema.json (inclure skill_version)
 4. Fichiers de config   ← composer.json, package.json, tsconfig, Makefile/Taskfile, Docker, etc.
 5. Code structurel      ← Kernel, App.vue, layouts, router, services.yaml, health endpoints
 6. Modules              ← chaque module injecte config, services Docker, code de base
 7. Thème frontend       ← layout + page d'accueil
 8. Fixtures             ← DoctrineFixturesBundle + fixtures par entité (si backend + BDD)
 9. Sécurité             ← security headers, rate limiting (selon config)
10. Accessibilité        ← ESLint a11y plugin, structure sémantique (si a11y.enabled + frontend)
11. Tests d'architecture ← deptrac.yaml + eslint-boundaries (si tests.architecture = true)
12. Éléments communs     ← CLAUDE.md, CONTRIBUTING, Git hooks, CI/CD, Dependabot, docs, sécurité
```

### Parallélisation de l'étape 6

Les sous-étapes suivantes sont indépendantes et peuvent être exécutées en parallèle via des agents (si `continuity.parallel` = `true`) :

```
Séquentiel : 1 (git) → 2 (arbo) → 3 (scaffold.config.json) → 4 (config)
Parallèle  : 5 (code structurel) | 6 (modules) | 7 (thème) | 8 (fixtures)
Séquentiel : 9 (sécurité) → 10 (a11y) → 11 (archi tests) → 12 (communs)
```

Les sous-étapes parallélisables ne modifient pas les mêmes fichiers. Les agents worktree ne sont pas nécessaires ici — la parallélisation se fait par fichiers distincts dans le même repo.

### 1. Arborescence

Exécuter `scripts/init-structure.sh` pour créer tous les dossiers de manière déterministe :

```bash
bash <skill-path>/scripts/init-structure.sh <project-path> <type> \
  [--backend] [--frontend] [--frontend-framework nuxt|vue] [--docker] \
  [--docs] [--docs-c4] [--docs-openapi] [--docs-adr] [--docs-features] \
  [--ci github|gitlab] [--advanced] [--contexts Identity,Catalog,Order] \
  [--cli-lang php|ts|shell] [--lib-lang php|ts] [--layers] [--shared]
```

Ajouter `--layers` si Nuxt + advanced + `nuxt_ddd_strategy: "layers"` dans le plan.
Ajouter `--shared` pour créer le dossier `frontend/shared/` (Nuxt 4 shared directory).

### 2. scaffold.config.json

Générer à la racine. Mémorise les choix pour les micro-generators. Valider la structure contre `assets/scaffold.config.schema.json`.

```json
{
  "version": "1.0",
  "skill_version": "2.3.0",
  "created_at": "<date ISO>",
  "updated_at": "<date ISO>",
  "name": "<nom>",
  "description": "<description>",
  "type": "web|cli|lib",
  "preset": "<preset ou null>",
  "backend": "symfony|null",
  "frontend": "nuxt|vue|null",
  "database": "postgresql|mysql|sqlite|null",
  "task_runner": "make|taskfile",
  "complexity": "simple|advanced",
  "profile": "simple|standard|advanced",
  "test_php_framework": "pest|phpunit",
  "package_manager": "pnpm|bun|npm|null",
  "layout": "dashboard|landing|minimal|null",
  "ui_framework": "tailwind|shadcn-vue|primevue|vuetify|nuxt-ui|none|null",
  "nuxt_ddd_strategy": "directories|layers|null",
  "ssr": true,
  "bounded_contexts": ["Identity", "Catalog"],
  "modules": ["auth", "messenger", "mailer"],
  "cli_lang": "php|ts|shell|null",
  "lib_lang": "php|ts|null",
  "features": {
    "Identity": {
      "entities": [
        {
          "name": "User",
          "properties": { "email": "string", "password": "string", "name": "string" },
          "relations": [],
          "crud": ["CREATE", "READ", "UPDATE"]
        }
      ],
      "custom": ["SendWelcomeEmail"]
    },
    "Catalog": {
      "entities": [
        {
          "name": "Product",
          "properties": { "name": "string", "price": "float", "description": "text" },
          "relations": [
            { "target": "Category", "type": "ManyToOne", "nullable": false, "inversedBy": "products" }
          ],
          "crud": ["CREATE", "READ", "LIST", "UPDATE", "DELETE"]
        }
      ],
      "custom": []
    }
  },
  "config": {},
  "metrics": null
}
```

### Structure du champ `features`

- Clé de premier niveau = nom du bounded context (ou `"_root"` en mode simple).
- `entities[]` : liste des entités avec leur nom, propriétés, relations et opérations CRUD sélectionnées.
- `relations[]` : relations Doctrine entre entités (`ManyToOne`, `OneToMany`, `ManyToMany`, `OneToOne`). Voir `references/ddd-features.md` section "Relations entre entités".
- `custom[]` : noms des features non-CRUD (commands, queries, events, pages).
- Le champ `config` ne contient que les surcharges par rapport aux défauts du profil.
- Le champ `metrics` est `null` au scaffold, rempli à l'étape 10.

### 3. Fichiers de config

Lire la référence correspondante au type de projet :

| Type | Références |
|---|---|
| **App web** | `references/web-app/backend.md`, `references/web-app/frontend.md`, `references/web-app/infrastructure.md` |
| **Script / CLI** | `references/project-types.md` — PHP, TypeScript, Shell |
| **Librairie** | `references/project-types.md` — PHP Composer, TypeScript npm |

Ne charger que les fichiers pertinents : pas de `backend.md` si pas de backend, pas de `frontend.md` si pas de frontend.

Si `tests.php_framework` = `pest` : utiliser `pestphp/pest` au lieu de `phpunit/phpunit` dans `composer.json`, et générer `pest.php` en plus de `phpunit.xml.dist`.

Si `frontend.package_manager` ≠ `pnpm` : adapter les lockfiles, commandes install et Dockerfiles.

Si `database` = `sqlite` : pas de service Docker BDD, `DATABASE_URL=sqlite:///%kernel.project_dir%/var/data.db` dans `.env`, pas de port exposé. Doctrine utilise le driver SQLite. Les migrations sont simplifiées (pas de `db-reset` complexe — juste supprimer le fichier).

Si `task_runner` = `taskfile` : générer `Taskfile.yml` au lieu de `Makefile`. Les targets sont les mêmes, en syntaxe YAML Task. Voir `~/.claude/CONFIG.md` section "Task runner" pour les détails. Adapter toutes les références `make <target>` en `task <target>` dans la documentation et la CI.

Si `tests.testcontainers` = `true` : ajouter `testcontainers/testcontainers` dans les devDependencies Composer. Les tests d'intégration utilisent un container BDD éphémère au lieu de `docker compose`.

Générer tous les fichiers de configuration **avant** le code métier.

### 4. Code structurel

Squelettes de base sans logique métier : Kernel.php, App.vue, layouts, router, services.yaml, etc.

Si app web avec backend, générer l'infrastructure commune dans `Shared/` (advanced) ou `src/` (simple) :
- `DomainException.php` — template `domain-exception.php.tpl`
- `NotFoundException.php` — template `not-found-exception.php.tpl`
- `ErrorOutput.php` — template `error-output.php.tpl`
- `ApiResponse.php` — template `api-response.php.tpl`
- `PaginatedOutput.php` — template `paginated-output.php.tpl`
- `ExceptionListener.php` — template `exception-listener.php.tpl`
- `HealthController.php` — template `health-controller.php.tpl` (toujours, pas seulement si module monitoring)
- `ReadinessController.php` — template `readiness-controller.php.tpl` (toujours)
- Enregistrer l'ExceptionListener dans `services.yaml` (tag `kernel.exception`)
- **Port interfaces** — si des features dépendent de clients externes (API tierces), générer les interfaces Port dans `Domain/Port/` et les binder dans `services.yaml` (voir `references/ddd-features.md` section "Ports").
- **Fichiers config Symfony manquants** — ne pas oublier les config packages standards (voir `references/web-app/backend.md` section "Packages config Symfony").

Voir la section "Validation & Error Handling" dans `references/web-app/backend.md` et la table "Code structurel" dans `references/ddd-features.md`.

#### ObjectMapper (Symfony 8)

Si advanced, générer un `ObjectMapperConfig.php` dans `Shared/Infrastructure/Mapper/` (template `object-mapper.php.tpl`). Ce service configure le mapping automatique entre entités Domain et DTOs Application via les attributs `#[Map]`. Les handlers CRUD l'utilisent pour le mapping Entity↔DTO au lieu du mapping inline.

### 5. Modules

Lire `references/modules.md` pour l'index et les synergies, puis `references/modules/<module>.md` pour chaque module activé. Chaque module injecte ses fichiers dans la structure existante (config, services Docker, code de base, tests).

### 6. Thème frontend

Voir la section "Thème frontend" dans `references/web-app/frontend.md`. Installer le framework UI, créer le layout et la page d'accueil.

### 7. Fixtures

Voir la section "Fixtures et données de test" dans `references/web-app/backend.md`. Générer les fixtures pour chaque entité prévue dans le `scaffold.config.json`. Ne s'applique que si backend + BDD.

### 8. Sécurité

Lire `references/security.md`. Selon la configuration :

- Si `security.headers` = `true` : générer le `SecurityHeadersListener` (voir référence).
- Si `security.rate_limiting` = `true` et module `auth` actif : configurer `symfony/rate-limiter` sur les endpoints auth.
- Si `security.audit` = `true` : ajouter la target `audit` au Makefile et le job `security` en CI.

### 9. Accessibilité

Si `a11y.enabled` = `true` et frontend présent :

- Ajouter `eslint-plugin-vuejs-accessibility` aux devDependencies et l'activer dans `eslint.config.js`.
- Les layouts et pages générés utilisent des éléments sémantiques HTML5 (`<header>`, `<main>`, `<nav>`, `<footer>`).
- Les formulaires ont des labels associés aux inputs.

Voir la section "Accessibilité" dans `references/security.md`.

### 11. Tests d'architecture

Si `tests.architecture` = `true` :

Lire `references/architecture-tests.md`. Générer :

- **Backend** : `deptrac.yaml` avec les règles de dépendances entre couches (Domain → rien, Application → Domain, Infrastructure → tout). Ajouter `qossmic/deptrac` dans `composer.json` (devDependencies). Ajouter la target `deptrac` au Makefile/Taskfile et le job `architecture` en CI.
- **Frontend** (si advanced + bounded contexts) : configurer `eslint-plugin-boundaries` avec les zones par bounded context dans `eslint.config.js`. Ajouter `eslint-plugin-perfectionist` pour l'auto-sort des imports.
- Les règles cross-context sont incluses automatiquement (interdiction d'importer entre contexts, sauf via `Shared`).

### 12. Éléments communs

Lire `references/common.md` : CLAUDE.md du projet, CONTRIBUTING.md, Git hooks (.gitmessage), CI/CD, Dependabot, Documentation, Sécurité.

Si le projet utilise VS Code ou Cursor, générer `.devcontainer/devcontainer.json` avec la configuration Docker Compose du projet. Inclut les extensions recommandées et les settings projet.

### Commit du scaffold

Après génération de tous les fichiers :

```bash
git add .
git commit -m "feat: scaffold project structure"
```

---

## Étape 7 — Vérification du scaffold

Vérifier que le projet vide fonctionne **avant** d'implémenter les features. Ne jamais skipper.

```bash
make doctor                  # prérequis installés
make install                 # dépendances backend + frontend
make up                      # containers up + healthchecks
make quality                 # lint + fix + analyse statique + tests (à vide)
make migration               # doctrine:migrations:diff (si backend + BDD)
make seed                    # doctrine:fixtures:load (si backend + BDD + fixtures)
```

Si une commande échoue : diagnostiquer la cause racine, corriger, relancer **la même commande**. Si le problème persiste après correction, échanger avec l'utilisateur pour adapter l'approche. **Ne jamais downgrader une version sans accord explicite.**

Ne passer à l'étape 8 que quand tout est vert.

---

## Étape 8 — Implémentation des features

Implémenter les features validées à l'étape 4, **une par une**.

Pour les features CRUD standard : les fichiers sont prévisibles via les templates, générer directement sans plan mode.
Pour les features custom ou complexes : appeler `EnterPlanMode`, lister les fichiers, valider, puis `ExitPlanMode` et exécuter.

```
 Feature N
 ├── 1. Backend : Domain → Application → Infrastructure (templates .tpl)
 ├── 2. Factory de test (entity-factory)
 ├── 3. Tests unitaires backend (handler-test, query-handler-test)
 ├── 4. Tests intégration backend (repository-test, controller-test)
 ├── 5. Frontend : types → service → store → pages
 ├── 6. Tests unitaires frontend (store-test)
 ├── 7. Test E2E (si tests.e2e = true et frontend présent)
 ├── 8. Documentation (openapi, features/{context}.md, C4 si pertinent)
 └── 9. make quality ← lint + tests, tout doit passer
```

Lire `references/ddd-features.md` pour les tables de génération CRUD, la pyramide de tests et les conventions de nommage. Lire `references/template-resolution.md` pour les règles de résolution des placeholders, le mapping propriété → composant UI, et les conventions de routage frontend.

Utiliser les templates dans `assets/templates/` comme squelettes. **Sélectionner les templates par framework** :
- Nuxt → `*-nuxt.vue.tpl`, `service-nuxt.ts.tpl`
- Vue.js → `*-vue.vue.tpl`, `service-vue.ts.tpl`
- Communs → `store.ts.tpl`, `entity-type.ts.tpl`, `e2e-crud.spec.ts.tpl`

**Règles critiques pour la génération frontend :**

1. **Zéro données hardcodées** — tout contenu affiché provient du store Pinia (lui-même connecté au service API). Si du texte comme `"Mon produit"`, `"Lorem ipsum"`, ou `19.99` apparaît en dur dans un `.vue`, c'est un bug à corriger immédiatement.
2. **Liens fonctionnels** — chaque `NuxtLink`/`RouterLink` doit pointer vers un fichier/route qui existe. Après génération, vérifier que toutes les cibles existent.
3. **Navigation à jour** — après chaque entité, mettre à jour le layout (sidebar) avec un lien vers la page liste.
4. **Routes Vue.js** — si Vue.js, ajouter les routes dans `routes.ts` après chaque entité.
5. **Résolution des placeholders** — suivre `references/template-resolution.md` pour le mapping propriété → champ de formulaire, propriété → colonne de table, et valeurs par défaut.
6. **data-testid** — chaque élément interactif reçoit un `data-testid` (convention dans `references/template-resolution.md`).

Si `tests.php_framework` = `pest` : adapter les templates de test PHPUnit en syntaxe Pest. Voir la section "Tests Pest" dans `references/ddd-features.md` pour les exemples et la table de correspondance.

Si `make quality` échoue après une feature : corriger immédiatement avant de passer à la feature suivante.

### Vérification post-feature

Après avoir généré tous les fichiers d'une feature (backend + frontend + tests), exécuter cette checklist **avant** `make quality` :

1. **Liens** — vérifier que chaque `NuxtLink to="..."` / `RouterLink :to="..."` pointe vers un fichier/route existant
2. **API URLs** — vérifier que le `BASE_URL` dans le service frontend (`/api/{context}/{entities}`) correspond aux routes du backend
3. **Données dynamiques** — grep dans les `.vue` générés pour détecter des chaînes suspectes (données d'exemple hardcodées)
4. **Store connecté** — chaque page utilise le store et appelle les actions appropriées
5. **Types cohérents** — le type TS du formulaire et de l'entité correspondent aux propriétés backend
6. **Navigation** — le layout sidebar contient un lien vers la page liste de l'entité

### Commits intermédiaires

Après chaque feature validée (make quality vert) :

```bash
git add .
git commit -m "feat(<context-kebab>): add <Entity> CRUD"
```

Si une feature échoue et que l'utilisateur veut revenir en arrière : `git reset --hard HEAD~1` revient au dernier état propre. Voir `references/common.md` (section "Commits intermédiaires").

### Parallélisation

Si `continuity.parallel` = `true` et qu'il y a 3+ bounded contexts, créer chaque context en parallèle via des agents worktree. Les contextes sont isolés par design (pas d'imports croisés), donc la parallélisation est safe. Chaque agent exécute le cycle complet (code + tests + quality + doc) pour son context.

---

## Étape 9 — Vérification finale

Toutes les features sont implémentées. Lancer une dernière vérification complète :

```bash
make quality                 # lint + analyse statique + tous les tests
make down                    # cleanup
```

---

## Étape 10 — Récapitulatif

- Arborescence condensée (profondeur 2, compteurs par section — même format que l'étape 5).
- Écarts par rapport au plan s'il y en a eu (corrections, modules ajustés, features retirées). Si tout est conforme, une ligne suffit : "Projet créé conformément au plan."

### Métriques

Calculer et afficher les métriques du projet généré :

```
Métriques :
  Fichiers créés       : <N>
  Lignes de code       : ~<N>
  Lignes de tests      : ~<N>
  Ratio tests/code     : <N>%
  Bounded contexts     : <N>
  Entités              : <N>
  Relations            : <N>
  Endpoints API        : <N>
  Health endpoints     : /healthz, /readyz
  Skill version        : 2.3.0
```

Calculer via `find <project> -type f | wc -l` et `find <project> -name '*.php' -o -name '*.ts' -o -name '*.vue' | xargs wc -l`.

**Persister les métriques** dans `scaffold.config.json` pour servir de baseline :

```json
"metrics": {
  "generated_at": "<date ISO>",
  "files": <N>,
  "loc_code": <N>,
  "loc_tests": <N>,
  "test_ratio": <N>,
  "endpoints": <N>,
  "entities": <N>,
  "bounded_contexts": <N>
}
```

`/new-project:upgrade` pourra comparer les métriques actuelles avec cette baseline.

### Commandes pour démarrer

```
make doctor    → vérifier les prérequis
make install   → installer les dépendances
make up        → démarrer les services
make help      → voir toutes les commandes
make outdated  → vérifier les dépendances obsolètes
```

**Ne pas afficher de "prochaines étapes".** Le projet livré est complet et fonctionnel.

Supprimer `.claude/task-state.local.md`.
