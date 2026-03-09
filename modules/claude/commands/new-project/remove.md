---
name: new-project:remove
description: Removes an entity, module, or bounded context from an existing project
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent
---

# Micro-generator — Remove

Retire proprement une entité, un module ou un bounded context d'un projet existant. Supprime les fichiers générés, nettoie la config et met à jour la documentation.

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, ce micro-generator ne peut pas fonctionner — signaler à l'utilisateur.

## Arguments

```
/new-project:remove                                  → mode interactif
/new-project:remove entity Product Catalog           → retirer l'entité Product du context Catalog
/new-project:remove module cache                     → retirer le module cache
/new-project:remove context Billing                  → retirer le bounded context Billing
/new-project:remove --dry-run entity Product Catalog → lister les fichiers sans les supprimer
```

## Étape 0 — Dry-run (si `--dry-run`)

Lister tous les fichiers qui seraient supprimés et modifiés, sans rien toucher :

```
Fichiers qui seraient supprimés :

  [DELETE] backend/src/Catalog/Domain/Model/Product.php
  [DELETE] backend/src/Catalog/Application/Command/CreateProductCommand.php
  ...
  [EDIT]   scaffold.config.json
  [EDIT]   docs/api/openapi.yaml

Total : X fichiers supprimés, Y fichiers modifiés
```

## Types de suppression

### entity

Supprime tous les fichiers générés pour une entité :

1. **Identifier les fichiers** — depuis `scaffold.config.json`, lire les opérations CRUD de l'entité et lister tous les fichiers correspondants (Domain, Application, Infrastructure, tests, frontend, docs).
2. **Confirmer** — afficher la liste des fichiers et demander confirmation.
3. **Supprimer** — supprimer les fichiers.
4. **Nettoyer la config** :
   - `scaffold.config.json` — retirer l'entité du context (via `Edit`).
   - `docs/api/openapi.yaml` — retirer les endpoints (si `doc.openapi`, via `Edit`).
   - `config/services.yaml` — nettoyer si nécessaire (via `Edit`).
   - Migration Doctrine — créer une migration de suppression de la table.
5. **Vérifier** — `make quality`.

### module

Supprime tous les fichiers injectés par un module :

1. **Identifier les fichiers** — lire `<skill-path>/references/modules/<module>.md` pour connaître les fichiers injectés.
2. **Vérifier les dépendances** — si d'autres modules dépendent du module à retirer (ex: `admin` dépend de `auth`), signaler et demander confirmation.
3. **Vérifier les synergies** — si des intégrations inter-modules existent (ex: `auth` + `mailer` = email de bienvenue), signaler que le code de synergie sera aussi supprimé.
4. **Confirmer** — afficher la liste complète.
5. **Supprimer** — supprimer les fichiers du module et les fichiers de synergie.
6. **Nettoyer la config** :
   - `scaffold.config.json` — retirer le module de la liste (via `Edit`).
   - `composer.json` / `package.json` — retirer les dépendances spécifiques au module (via `Edit`).
   - `compose.yaml` — retirer les services Docker du module (via `Edit`).
   - `.env.example` — retirer les variables du module (via `Edit`).
7. **Vérifier** — `make install && make quality`.

### context

Supprime un bounded context entier :

1. **Identifier** — lister tous les fichiers dans `backend/src/<Context>/`, `backend/tests/*/<Context>/`, `frontend/app/<context>/` (ou `layers/<context>/`), `frontend/tests/unit/<context>/`.
2. **Confirmer** — afficher le nombre de fichiers et demander confirmation. C'est une opération destructrice.
3. **Supprimer** — supprimer les dossiers entiers.
4. **Nettoyer la config** :
   - `scaffold.config.json` — retirer le context et ses features (via `Edit`).
   - `config/services.yaml` — retirer l'autowiring du context (via `Edit`).
   - `config/routes/` — retirer les routes du context (via `Edit`).
   - `docs/features/<context>.md` — supprimer.
   - `docs/api/openapi.yaml` — retirer les endpoints du context (via `Edit`).
   - `docs/c4/context.md` — mettre à jour le diagramme (via `Edit`).
5. **Vérifier** — `make quality`.

## Règles

- **Toujours confirmer avant de supprimer** — même avec `--yes`, afficher un récapitulatif.
- **Créer un commit avant la suppression** pour permettre le rollback : `git add . && git commit -m "chore: snapshot before removing <element>"`.
- **Ne jamais supprimer des fichiers partagés** (`services.yaml`, `scaffold.config.json`, etc.) — toujours les modifier via `Edit`.
- **Migration de suppression** — pour les entités, créer une migration Doctrine qui drop la table.
- **Nettoyer les imports** — après suppression, vérifier qu'aucun fichier restant n'importe un fichier supprimé.

`<skill-path>` = `~/.claude/skills/new-project`
