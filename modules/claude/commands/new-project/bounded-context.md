---
name: new-project:bounded-context
description: Adds a new bounded context to an existing project scaffolded with /new-project
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Bounded Context

Ajoute un bounded context complet (backend + frontend + tests) à un projet existant.

## Références

Les conventions de nommage, tables de génération CRUD et mapping de types sont dans le skill principal :

- Conventions de nommage → `<skill-path>/references/ddd-features.md` (section "Conventions de nommage")
- Tables de génération → `<skill-path>/references/ddd-features.md` (sections "Backend" et "Frontend")
- Templates → `<skill-path>/assets/templates/`
- Modules → `<skill-path>/references/modules.md`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, demander à l'utilisateur de confirmer la stack manuellement.

Vérifier que `complexity` = `advanced`. Si `simple`, expliquer que les bounded contexts nécessitent le mode advanced et proposer de migrer.

## Arguments

```
/new-project:bounded-context                     → mode interactif
/new-project:bounded-context Billing             → créer le context "Billing"
/new-project:bounded-context Billing "Gestion des abonnements et paiements"  → avec description
/new-project:bounded-context --dry-run Billing   → afficher les fichiers sans les créer
```

## Étape 0 — Dry-run (si `--dry-run`)

Si `--dry-run` est passé, exécuter toutes les étapes de définition (1-2) puis afficher l'arborescence complète des fichiers qui seraient générés, sans rien écrire. Format :

```
Fichiers qui seraient générés pour <Context> :

  [CREATE] backend/src/<Context>/Domain/Model/...
  [CREATE] backend/src/<Context>/Application/Command/...
  [EDIT]   backend/config/services.yaml
  [EDIT]   scaffold.config.json
  ...

Total : X fichiers créés, Y fichiers modifiés
```

Puis s'arrêter.

## Étape 1 — Définition

Si pas fourni en argument, demander :

```
Nouveau bounded context :
  Nom : ___
  Responsabilité (une phrase) : ___
```

Valider que le nom est en PascalCase et n'existe pas déjà dans le projet.

## Étape 2 — Features

Proposer des features pour ce context. Lire `<skill-path>/references/ddd-features.md` pour les conventions.

**Recherche préalable** si `research.before_impl` = `true` dans `scaffold.config.json`.

```
Features proposées pour <Context> :

  <Context>
  ├── <Feature 1>
  ├── <Feature 2>
  └── <Feature 3>

ok ? (ou modifie)
```

## Étape 3 — Génération

### Gestion des conflits

Avant de créer un fichier, vérifier s'il existe déjà :
- **Fichier identique** → ignorer silencieusement.
- **Fichier différent** → signaler le conflit et demander : `écraser`, `garder`, `diff` (afficher les différences).
- **Fichier de config partagé** (`services.yaml`, `routes/*.yaml`, `scaffold.config.json`) → toujours modifier via `Edit`, ne jamais écraser.

### Backend (si présent dans scaffold.config.json)

Lire `~/.claude/stacks/symfony.md`. Utiliser les templates dans `<skill-path>/assets/templates/`. Créer la structure DDD :

```
src/<Context>/
├── Domain/
│   ├── Model/              ← entités avec attributs ORM
│   ├── ValueObject/
│   ├── Repository/         ← interfaces
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

- Mettre à jour `config/services.yaml` — ajouter l'autowiring du nouveau context.
- Mettre à jour `config/routes/` — ajouter les routes du nouveau context.
- Générer les fichiers de chaque feature selon les tables dans `<skill-path>/references/ddd-features.md`.

### Frontend (si présent dans scaffold.config.json)

Lire `~/.claude/stacks/nuxt.md` ou `~/.claude/stacks/vue.md` selon `scaffold.config.json.frontend`. Créer :

**Nuxt (directories)** : `frontend/app/<context>/`
**Nuxt (layers)** : `frontend/layers/<context>/` (auto-enregistré par Nuxt 4, créer un `nuxt.config.ts` vide)
**Vue.js** : `frontend/src/<context>/`

Lire `scaffold.config.json.nuxt_ddd_strategy` pour déterminer l'approche Nuxt.

```
[context]/
├── components/
├── composables/
├── pages/
├── stores/
├── types/
└── services/
```

- Si Vue.js : ajouter les routes dans `src/[context]/routes.ts` et les importer dans le router principal.
- Si Nuxt : les pages dans le bon dossier suffisent (auto-routing).

### Tests — pyramide complète

**Unitaires** (toujours) :
- Backend : `tests/Unit/<Context>/` — un test par handler. Templates : `handler-test.php.tpl`, `query-handler-test.php.tpl`.
- Frontend : `tests/unit/<context>/stores/` — un test par store. Template : `store-test.ts.tpl`.

**Intégration** (toujours) :
- Backend repository : `tests/Integration/<Context>/` — un test par repository. Template : `integration-repository-test.php.tpl`.
- Backend controller : `tests/Functional/<Context>/` — un test par controller. Template : `integration-controller-test.php.tpl`.

**E2E** (si `tests.e2e` = `true` et frontend présent) :
- `tests/e2e/<context>/` — un fichier par entité. Template : `e2e-crud.spec.ts.tpl`.

### Documentation

- `docs/features/<context>.md` — périmètre du context (si `doc.enabled`).
- `docs/api/openapi.yaml` — ajouter les nouveaux endpoints (si `doc.openapi`).
- `docs/c4/context.md` — mettre à jour le diagramme C2 avec le nouveau bounded context (si `doc.c4`).

## Étape 4 — Mise à jour

- Mettre à jour `scaffold.config.json` — ajouter le context et ses features (via `Edit`).
- Mettre à jour `.claude/CLAUDE.md` — ajouter le context à la section Bounded Contexts (via `Edit`).

## Étape 5 — Vérification

Lancer `make quality` (ou les checks appropriés) et corriger les erreurs avant de terminer.

Voir `<skill-path>/references/troubleshooting.md`

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Les bounded contexts ne s'importent pas entre eux.** Communication par events uniquement.
