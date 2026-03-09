---
name: new-project:feature
description: Adds a custom feature (command, query, event listener, page) to an existing bounded context
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Feature

Ajoute une feature custom à un bounded context existant. Contrairement à `/new-project:entity` qui génère du CRUD, cette commande génère des éléments individuels.

## Références

Les conventions de nommage et templates sont dans le skill principal :

- Conventions de nommage → `<skill-path>/references/ddd-features.md` (section "Conventions de nommage")
- Templates → `<skill-path>/assets/templates/`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet.

Valider que le bounded context cible existe dans `scaffold.config.json.bounded_contexts`. Si non, lister les contexts disponibles et demander confirmation.

## Arguments

```
/new-project:feature                                         → mode interactif
/new-project:feature command SendWelcomeEmail Identity       → commande dans Identity
/new-project:feature query GetDashboardStats Analytics       → query dans Analytics
/new-project:feature event OrderCompleted Order              → event + listener
/new-project:feature page settings Identity                  → page frontend
/new-project:feature --dry-run command SendWelcomeEmail Identity  → afficher sans créer
```

## Étape 0 — Dry-run (si `--dry-run`)

Si `--dry-run` est passé, exécuter les étapes de définition puis afficher la liste des fichiers qui seraient générés, sans rien écrire. Format :

```
Fichiers qui seraient générés :

  [CREATE] backend/src/<Context>/Application/Command/<Name>Command.php
  [CREATE] backend/src/<Context>/Application/CommandHandler/<Name>Handler.php
  [CREATE] backend/tests/Unit/<Context>/Application/CommandHandler/<Name>HandlerTest.php
  [EDIT]   scaffold.config.json

Total : X fichiers créés, Y fichiers modifiés
```

Puis s'arrêter.

## Types de features

```
Type de feature :
  1. command     — Command + CommandHandler (action qui modifie l'état)
  2. query       — Query + QueryHandler (lecture sans effet de bord)
  3. event       — Event + EventListener (réaction à un événement)
  4. page        — Page frontend + route + composants
  5. endpoint    — Controller seul (GET/POST/PUT/DELETE)
  6. composable  — Composable Vue réutilisable
  7. service     — Service applicatif custom
```

## Gestion des conflits

Avant de créer un fichier, vérifier s'il existe déjà :
- **Fichier identique** → ignorer silencieusement.
- **Fichier différent** → signaler le conflit et demander : `écraser`, `garder`, `diff`.
- **Fichier de config partagé** (`scaffold.config.json`, `openapi.yaml`, `routes.ts`) → toujours modifier via `Edit`, ne jamais écraser.

## Génération par type

### command

```
src/<Context>/Application/Command/<Name>Command.php
src/<Context>/Application/CommandHandler/<Name>Handler.php
src/<Context>/Application/DTO/<Name>Input.php          ← si des données en entrée
src/<Context>/Infrastructure/Controller/<Name>Controller.php  ← si endpoint exposé
tests/Unit/<Context>/Application/CommandHandler/<Name>HandlerTest.php
```

Templates : `command.php.tpl`, `command-handler.php.tpl`, `dto-input.php.tpl`, `controller.php.tpl`, `handler-test.php.tpl`.

Demander :
- Nom de la commande (ex: `SendWelcomeEmail`)
- Propriétés du Command (données nécessaires)
- Exposer un endpoint ? Si oui, méthode HTTP + route.

### query

```
src/<Context>/Application/Query/<Name>Query.php
src/<Context>/Application/QueryHandler/<Name>Handler.php
src/<Context>/Application/DTO/<Name>Output.php
src/<Context>/Infrastructure/Controller/<Name>Controller.php  ← si endpoint exposé
tests/Unit/<Context>/Application/QueryHandler/<Name>HandlerTest.php
```

Templates : `query.php.tpl`, `query-handler.php.tpl`, `dto-output.php.tpl`, `controller.php.tpl`, `query-handler-test.php.tpl`.

### event

```
src/<Context>/Domain/Event/<Name>.php
src/<TargetContext>/Application/EventListener/On<Name>Listener.php
tests/Unit/<TargetContext>/Application/EventListener/On<Name>ListenerTest.php
```

Templates : `event.php.tpl`, `event-listener.php.tpl`, `event-listener-test.php.tpl`.

Demander :
- Nom de l'event (ex: `OrderCompleted`)
- Context source (qui émet)
- Context cible (qui écoute) — peut être le même ou différent
- Action du listener (description courte)

### page

```
frontend/app/<context>/pages/<page-name>.vue       ← Nuxt
frontend/src/<context>/pages/<PageName>.vue        ← Vue.js
frontend/app/<context>/stores/<related-store>.ts   ← si données nécessaires
frontend/tests/unit/<context>/stores/<store>.test.ts
```

Template : `page.vue.tpl`.

Détecter le framework frontend dans `scaffold.config.json.frontend` (`nuxt` ou `vue`).

Demander :
- Nom de la page
- Données à afficher (quels stores/queries utiliser)
- Layout à utiliser

### endpoint

```
src/<Context>/Infrastructure/Controller/<Name>Controller.php
tests/Unit/<Context>/Infrastructure/Controller/<Name>ControllerTest.php  ← si pertinent
```

Template : `controller.php.tpl`.

### composable

```
frontend/app/<context>/composables/use<Name>.ts    ← Nuxt
frontend/src/<context>/composables/use<Name>.ts    ← Vue.js
frontend/tests/unit/<context>/composables/use<Name>.test.ts
```

Templates : `composable.ts.tpl`, `composable-test.ts.tpl`.

### service

```
src/<Context>/Application/Service/<Name>Service.php
tests/Unit/<Context>/Application/Service/<Name>ServiceTest.php
```

Templates : `service-php.php.tpl`, `service-php-test.php.tpl`.

## Mise à jour

- `scaffold.config.json` — ajouter la feature au context concerné (via `Edit`).
- `docs/api/openapi.yaml` — si endpoint ajouté (si `doc.openapi`, via `Edit`).
- Routes/router — si page ou endpoint ajouté (via `Edit`).

## Vérification

Lancer `make quality` et corriger les erreurs.

Voir `<skill-path>/references/troubleshooting.md`

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Les events sont le seul moyen de communication inter-context.**
