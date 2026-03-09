---
name: new-project:module
description: Adds a module (auth, mailer, cache, etc.) to an existing project scaffolded with /new-project
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Module

Ajoute un module optionnel à un projet existant. Injecte config, services Docker, code de base et tests.

## Références

- Index des modules → `<skill-path>/references/modules.md`
- Détail par module → `<skill-path>/references/modules/<module>.md`
- Templates → `<skill-path>/assets/templates/`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, demander la stack manuellement.

## Arguments

```
/new-project:module                              → mode interactif
/new-project:module mailer                       → ajouter le module mailer
/new-project:module cache search                 → ajouter plusieurs modules
/new-project:module --dry-run scheduler          → afficher les fichiers sans les créer
```

## Étape 0 — Dry-run (si `--dry-run`)

Si `--dry-run` est passé, exécuter l'étape de sélection puis afficher la liste des fichiers qui seraient générés, sans rien écrire. Format :

```
Fichiers qui seraient générés pour le module <module> :

  [CREATE] backend/config/packages/<module>.yaml
  [CREATE] docker/compose.yaml (service ajouté)
  [EDIT]   backend/composer.json
  [EDIT]   scaffold.config.json
  ...

Total : X fichiers créés, Y fichiers modifiés
```

Puis s'arrêter.

## Étape 1 — Sélection

Lire les modules déjà activés depuis `scaffold.config.json.modules`. N'afficher que les modules **non encore activés** et pertinents pour la stack du projet.

```
Modules disponibles (non activés) :

  Infra                                         Fonctionnel
  ─────────────────────────────────────────     ─────────────────────────────────────────
  1. messenger   CQRS buses (command/query)     5. mailer       Emails transactionnels
  2. monitoring  Health endpoint + logs          6. file-upload  Upload + stockage local
  3. cache       Redis cache layer              7. i18n         Internationalisation
  4. scheduler   Tâches planifiées              8. search       Meilisearch
                                                9. admin        EasyAdmin backoffice

  Temps réel
  ─────────────────────────────────────────
  10. mercure    SSE temps réel

ok → aucun | numéros → ajouter
```

Affichage conditionnel : `mailer`, `file-upload`, `cache`, `scheduler`, `search`, `admin` → si backend. `mercure` → si backend + frontend. `i18n` → si frontend. `monitoring` → toujours si app web. `messenger` → si backend.

Si le module est passé en argument, sauter cette étape.

## Étape 2 — Synergies

Vérifier les synergies entre le(s) nouveau(x) module(s) et les modules déjà activés. Lire `<skill-path>/references/modules.md` (section "Synergies inter-modules").

```
Synergies détectées :
  auth + mailer → Email de bienvenue à l'inscription
  messenger + mailer → Envoi d'emails asynchrone

Le code d'intégration sera généré automatiquement. ok ?
```

Si aucune synergie, passer directement à l'étape 3.

## Étape 3 — Génération

Lire `<skill-path>/references/modules/<module>.md` pour les détails du module concerné. Pour chaque module sélectionné :

### Gestion des conflits

Avant de créer un fichier, vérifier s'il existe déjà :
- **Fichier identique** → ignorer silencieusement.
- **Fichier différent** → signaler le conflit et demander : `écraser`, `garder`, `diff`.
- **Fichier de config partagé** (`composer.json`, `package.json`, `compose.yaml`, `services.yaml`, `scaffold.config.json`) → toujours modifier via `Edit`, ne jamais écraser.

### Ordre d'injection

```
 1. Dépendances     ← composer.json et/ou package.json (via Edit)
 2. Config          ← config/packages/<module>.yaml, .env variables
 3. Docker          ← service dans compose.yaml + compose.override.yaml (via Edit)
 4. Code backend    ← controllers, services, listeners selon le module
 5. Code frontend   ← composables, pages, stores si pertinent
 6. Tests           ← tests unitaires et intégration pour le code ajouté
 7. Documentation   ← docs/ARCHITECTURE.md mis à jour (via Edit)
```

### Recherche avant implémentation

Si `research.before_impl` = `true` dans `scaffold.config.json.config` ou `~/.claude/CONFIG.md` : consulter la doc à jour du package/bundle via context7 avant d'implémenter.

## Étape 4 — Mise à jour

- `scaffold.config.json` — ajouter le module à la liste `modules` (via `Edit`).
- `.claude/CLAUDE.md` — ajouter le module à la section Modules si elle existe (via `Edit`).
- `docs/ARCHITECTURE.md` — mentionner le nouveau module (via `Edit`).
- `docs/c4/context.md` — mettre à jour le diagramme C2 si le module ajoute un service Docker (via `Edit`).

## Étape 5 — Vérification

```bash
make install                 # nouvelles dépendances
make up                      # nouveaux services Docker
make quality                 # lint + tests
```

Corriger les erreurs avant de terminer.

Voir `<skill-path>/references/troubleshooting.md` pour le diagnostic des erreurs courantes.

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Lire `references/modules/<module>.md`** pour les détails du module avant d'implémenter.
- **Signaler les synergies** avec les modules déjà actifs — ne pas les ignorer silencieusement.
- Si `security.headers` ou `security.rate_limiting` dans la config : appliquer les éléments de sécurité. Voir `<skill-path>/references/security.md`.
