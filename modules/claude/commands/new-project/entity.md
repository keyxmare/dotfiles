---
name: new-project:entity
description: Adds a new entity with full CRUD to an existing bounded context
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Entity

Ajoute une entité avec CRUD complet (backend + frontend + tests) dans un bounded context existant.

## Références

Les conventions de nommage, tables de génération CRUD et mapping de types sont dans le skill principal :

- Conventions de nommage → `<skill-path>/references/ddd-features.md` (section "Conventions de nommage")
- Tables de génération → `<skill-path>/references/ddd-features.md` (sections "Backend" et "Frontend")
- Mapping de types → `<skill-path>/references/ddd-features.md` (section "Mapping de types")
- Templates → `<skill-path>/assets/templates/`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, demander la stack manuellement.

Valider que le bounded context cible existe dans `scaffold.config.json.bounded_contexts`. Si non, lister les contexts disponibles et demander confirmation.

## Arguments

```
/new-project:entity                              → mode interactif
/new-project:entity Product Catalog              → entité Product dans le context Catalog
/new-project:entity Product Catalog "name:string, price:float, description:text"  → avec propriétés
/new-project:entity --dry-run Product Catalog    → afficher les fichiers sans les créer
```

## Mode light (`--light`)

Génère une entité simplifiée sans la pile CQRS complète. Utile pour les entités simples (lookup tables, configuration, enums persistés).

```
/new-project:entity --light Tag Catalog "name:string"
```

Fichiers générés (mode light) :
- Entity (domain model)
- Repository interface + implémentation Doctrine
- Mapping Doctrine
- Un controller CRUD unique (toutes les méthodes dans un seul fichier, template `controller-crud.php.tpl`)
- Un test fonctionnel unique (template `controller-crud-test.php.tpl` ou `controller-crud-test-pest.php.tpl`)
- Types frontend + service + store + page liste

Pas de Commands/Queries/Handlers/DTOs séparés. Pas d'events domain. Le mode light est indépendant du profil — il est utilisable en mode advanced pour des entités qui ne justifient pas la pile CQRS.

## Étape 0 — Dry-run (si `--dry-run`)

Si `--dry-run` est passé, exécuter les étapes de définition (1-2) puis afficher la liste des fichiers qui seraient générés par opération CRUD, sans rien écrire. Format :

```
Fichiers qui seraient générés pour <Entity> dans <Context> :

  CREATE
  ├── [CREATE] backend/src/<Context>/Domain/Model/<Entity>.php
  ├── [CREATE] backend/src/<Context>/Application/Command/Create<Entity>Command.php
  ├── ...
  └── [CREATE] backend/tests/Unit/<Context>/Application/CommandHandler/Create<Entity>HandlerTest.php

  READ
  ├── ...

  [EDIT] backend/config/services.yaml
  [EDIT] scaffold.config.json

Total : X fichiers créés, Y fichiers modifiés
```

Puis s'arrêter.

## Étape 1 — Définition

Si pas fourni en argument :

```
Entité :
  Nom (PascalCase singulier) : ___
  Bounded context : ___ (proposer la liste depuis scaffold.config.json)
  Propriétés (format "nom:type") : ___
```

Types supportés : `string`, `text`, `int`, `float`, `bool`, `datetime`, `uuid`, `json`, `enum(val1,val2,...)`.

Si les propriétés ne sont pas fournies, les déduire du nom de l'entité et demander confirmation.

## Étape 2 — Opérations CRUD

```
Opérations à générer pour <Entity> :

  [x] CREATE   POST   /api/<context>/<entities>
  [x] READ     GET    /api/<context>/<entities>/{id}
  [x] LIST     GET    /api/<context>/<entities>
  [x] UPDATE   PUT    /api/<context>/<entities>/{id}
  [x] PATCH    PATCH  /api/<context>/<entities>/{id}
  [x] DELETE   DELETE /api/<context>/<entities>/{id}

ok ? (ou décoche : -delete, -update)
```

## Étape 3 — Génération

### Gestion des conflits

Avant de créer un fichier, vérifier s'il existe déjà :
- **Fichier identique** → ignorer silencieusement.
- **Fichier différent** → signaler le conflit et demander : `écraser`, `garder`, `diff`.
- **Fichier de config partagé** (`services.yaml`, `scaffold.config.json`, `openapi.yaml`) → toujours modifier via `Edit`, ne jamais écraser.

### Mode advanced (DDD/CQRS)

Pour chaque opération sélectionnée, générer les fichiers selon les tables dans `<skill-path>/references/ddd-features.md`. Utiliser les templates dans `<skill-path>/assets/templates/`.

Ordre de génération par opération :

PATCH suit le même pattern que UPDATE : Command + Handler + PatchInput DTO + Controller + tests. Le `PatchInput` utilise des propriétés nullables (template `patch-input.php.tpl`).

1. Domain (Model avec attributs ORM, Repository interface, Event)
1b. Factory de test (`tests/Factory/{Context}/{Entity}Factory.php` — template `entity-factory.php.tpl`)
2. Application (Command/Query, Handler, DTO)
3. Infrastructure (Controller, Doctrine Repository via `doctrine-repository.php.tpl`)
4. **Tests unitaires backend** (handler-test, query-handler-test — immédiatement)
5. **Tests intégration backend** (integration-repository-test, integration-controller-test)
6. Frontend (types via `entity-type.ts.tpl`, service, store, pages — liste via `page.vue.tpl`, formulaire via `form-page.vue.tpl`)
7. **Tests unitaires frontend** (store-test — immédiatement)
8. **Test E2E** (si `tests.e2e` = `true` et frontend présent, via `e2e-crud.spec.ts.tpl`)
9. Documentation (openapi, features/{context}.md)

### Mode simple

1. Entity, Repository, Service, Controller (méthodes CRUD)
2. Tests unitaires backend (ServiceTest, ControllerTest)
3. Tests intégration backend (RepositoryTest via DB, ControllerTest fonctionnel)
4. Frontend (types via `entity-type.ts.tpl`, pages, store, service API)
5. Tests unitaires frontend (store-test)
6. Test E2E (si `tests.e2e` = `true` et frontend présent)
7. Documentation (openapi, features si advanced)

### Propriétés → code

Voir la table complète dans `<skill-path>/references/ddd-features.md` (section "Mapping de types").

## Étape 4 — Mise à jour

- Mettre à jour `scaffold.config.json` — ajouter l'entité aux features du context (via `Edit`).
- Migration Doctrine — créer la migration pour la nouvelle table.
- `docs/api/openapi.yaml` — ajouter les endpoints (si `doc.openapi`, via `Edit`).

## Étape 5 — Vérification

Lancer `make quality` et corriger les erreurs.

Voir `<skill-path>/references/troubleshooting.md`

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **PATCH** : si sélectionné, le `PatchInput` utilise des propriétés nullables. Template : `patch-input.php.tpl`.
- **Mode light** (`--light`) : génère un CRUD simplifié sans CQRS. Utilisable en mode advanced pour les entités simples.
- **Factory** : générée automatiquement pour chaque entité (template `entity-factory.php.tpl`).
- **Soft delete** (`--soft-delete`) : ajoute un champ `deletedAt` nullable (`?\DateTimeImmutable`) à l'entité, une méthode `softDelete()` qui set la date courante, une méthode `restore()` qui remet à null, et un filtre Doctrine global qui exclut les entités supprimées des requêtes par défaut. L'opération DELETE utilise `softDelete()` au lieu de `remove()`. Stocké dans `scaffold.config.json` : `soft_delete: true` sur l'entité.
