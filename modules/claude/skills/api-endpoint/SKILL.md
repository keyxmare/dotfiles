---
name: api-endpoint
description: Scaffolds a complete DDD API endpoint with tests and OpenAPI spec
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — API Endpoint

Tu scaffoldes un endpoint API complet en suivant l'architecture DDD du projet.

## Input

`$ARGUMENTS` peut être :
- Une route (ex: `POST /api/products`)
- Une description (ex: `endpoint pour lister les commandes d'un utilisateur`)
- Un verbe + ressource (ex: `create product`, `list orders`, `delete user`)

## Process

### 1. Analyse

Déduire :
- **Méthode HTTP** et **route**
- **Bounded context** cible
- **Type d'opération** : Command (POST/PUT/PATCH/DELETE) ou Query (GET)
- **Entité** concernée et ses champs
- **Format de réponse** : single resource, collection (paginée), ou vide (204)

Lire les endpoints existants du même bounded context pour rester cohérent (nommage, structure, patterns).

### 2. Recherche

Consulter context7 si l'endpoint utilise des features framework (validation, serialization, pagination).

### 3. Génération

Créer les fichiers dans l'ordre :

**Command (écriture)**
1. `Application/Command/<Action>Command.php` — DTO immutable
2. `Application/Command/<Action>Handler.php` — Logique métier
3. `Presentation/Controller/<Action>Controller.php` — Route + validation + dispatch

**Query (lecture)**
1. `Application/Query/<Action>Query.php` — DTO immutable
2. `Application/Query/<Action>Handler.php` — Lecture via repository
3. `Presentation/Controller/<Action>Controller.php` — Route + dispatch + serialization

**Commun**
4. `Application/DTO/<Entity>Output.php` — DTO de sortie (si nouveau)
5. Tests : Handler (unit) + Controller (integration)

### 4. OpenAPI

Si `docs/openapi.yaml` existe, ajouter l'endpoint :
- Path + méthode
- Request body schema (si POST/PUT/PATCH)
- Response schemas (200/201/204/400/404/422)
- Tags par bounded context

### 5. Vérification

```bash
make quality
make test
```

- Le endpoint répond correctement
- Les tests couvrent : cas nominal, validation error, not found (si applicable)
- La spec OpenAPI est valide

### 6. Commit

```
feat: add <METHOD> <route> endpoint
```

Ne pas push sans accord de l'utilisateur.
