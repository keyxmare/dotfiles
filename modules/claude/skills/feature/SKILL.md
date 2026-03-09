---
name: feature
description: Implements a feature end-to-end following DDD and trunk-based workflow
allowed-tools: Bash(gh *), Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Feature

Tu implémentes une feature complète en suivant le workflow trunk-based et les patterns DDD du projet.

## Input

`$ARGUMENTS` peut être :
- Un numéro d'issue GitHub (ex: `42`)
- Une description textuelle (ex: `ajouter l'export CSV des commandes`)
- Rien → demander une description

## Process

### 1. Cadrage

Si issue GitHub :
```bash
gh issue view $ARGUMENTS --json title,body,labels,comments
```

Identifier :
- Le ou les bounded contexts impactés
- Les entités/value objects concernés
- Les couches à modifier (Domain, Application, Infrastructure, Presentation)
- Backend, frontend, ou les deux

Lire les fichiers existants du bounded context pour comprendre les patterns en place.

### 2. Recherche

Consulter la doc des libs concernées via context7 si la feature touche une API framework.

Charger les stacks pertinentes (`~/.claude/stacks/`) selon la nature de la feature :
- Backend Symfony → `symfony.md`, `symfony-cqrs.md`
- Frontend Vue/Nuxt → `vue.md` ou `nuxt.md`
- API → `api.md`
- Async → `patterns-async.md`

### 3. Plan

Présenter un plan concis :
- Fichiers à créer/modifier (groupés par couche)
- Approche technique (1-2 phrases)
- Nombre estimé de fichiers

Attendre validation si > 5 fichiers ou si impact multi-bounded-context.

### 4. Branche

```bash
git switch -c feat/<slug>
```

Si issue GitHub : `feat/$ARGUMENTS-<slug>`.

### 5. Implémentation

Ordre d'implémentation :
1. **Domain** — Entités, value objects, interfaces repository, domain events
2. **Application** — Commands/Queries, Handlers, DTOs
3. **Infrastructure** — Repositories Doctrine, services externes
4. **Presentation** — Controllers, validation
5. **Frontend** — Composables, stores, composants, pages
6. **Tests** — Unitaires (handlers, domain), intégration (controllers), E2E si applicable

Règles :
- Un commit par unité logique cohérente
- `make quality` après chaque commit
- Respecter les patterns existants du projet (nommage, structure, conventions)
- Pas de code mort, pas de commentaires

### 6. Vérification

- Tous les tests passent (`make test`)
- Qualité OK (`make quality`)
- Coverage >= 80% sur le code ajouté
- Fichiers sous le seuil de longueur (300 lignes)

### 7. Finalisation

Message de commit conventionnel :
```
feat: <description courte>
```

Si issue GitHub : `feat: <description courte> (#$ARGUMENTS)`

Ne pas push sans accord de l'utilisateur.
