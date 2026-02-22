# Gestion documentaire des projets

Ce fichier est la source de vérité pour les obligations documentaires (MEMORY, FEATURES, TASKS, Makefile) dans chaque projet.

## Makefile
- Chaque projet doit avoir un `Makefile` à la racine avec les commandes courantes.
- Utiliser le Makefile comme point d'entrée pour toutes les commandes (build, tests, qualité, etc.).
- Quand un Makefile existe, toujours l'utiliser plutôt que les commandes Docker directes.
- Quand un projet n'a pas de Makefile, en proposer un.
- Pour les commandes spécifiques Symfony, voir `~/.claude/stacks/symfony.md` section Makefile.

## MEMORY.md
- Utiliser un fichier `MEMORY.md` à la racine du projet pour persister la mémoire **entre toutes les sessions**.
- **Relire `MEMORY.md` en début de chaque session** pour reprendre le contexte.
- **OBLIGATOIRE : Mettre à jour `MEMORY.md` avant chaque fin de réponse.** Même pour des petits changements. Si rien n'a changé, ne pas mettre à jour.
- Contenu attendu :
  - Décisions architecturales prises
  - Fichiers clés identifiés et leur rôle
  - Bugs rencontrés et leurs solutions
  - Contexte métier découvert (Bounded Contexts, entités, règles)
  - Tâches terminées et en cours
- Garder MEMORY.md **concis** (< 200 lignes). C'est un **index**, pas un dump.
- **Ne pas stocker** : le code source, les données temporaires, les informations sensibles.

### Mémoire hiérarchique (projets > 5 BCs ou > 300 fichiers)
- Utiliser un dossier `memory/` avec des fichiers spécialisés :
  - `memory/architecture.md` — décisions archi, diagrammes, patterns choisis
  - `memory/debug.md` — bugs rencontrés et solutions
  - `memory/<bc-name>.md` — contexte spécifique à un Bounded Context
  - `memory/audit-history.md` — historique des scores d'audit (full-audit)
- MEMORY.md contient les **références** vers ces fichiers, pas leur contenu.

### Bloc "Contexte projet" (auto-généré)
- Persister en haut de MEMORY.md un bloc structuré pour éviter de relire composer.json à chaque session :
```
## Contexte projet (auto-généré)
PHP: 8.x | Symfony: 8.x | Doctrine: 3.x | API Platform: 4.x
BCs: Catalog, Order, Identity (N)
Stacks applicables: symfony, ddd, api-platform, messenger
Fichiers src/: ~N | Tests: ~N
Dernier scan: <commit-sha> (YYYY-MM-DD)
```
- Ce bloc est mis à jour quand composer.json change ou quand un skill détecte un changement structurel.

## FEATURES.md
- Maintenir un fichier `FEATURES.md` à la racine du projet qui documente toutes les fonctionnalités.
- **Relire `FEATURES.md` en début de session** pour connaître le périmètre fonctionnel.
- **Mettre à jour `FEATURES.md`** quand une fonctionnalité est ajoutée, modifiée ou supprimée.
- Structure attendue :
  - Nom de la feature
  - Description courte
  - Bounded Context associé
  - Statut (done, in progress, planned)
- Garder le fichier factuel et à jour : c'est la source de vérité fonctionnelle du projet.

### Scaling (projets > 20 features)
- Découper en `features/<bc-name>.md`.
- FEATURES.md devient un **index** :
  ```
  | BC | Done | In Progress | Planned | Détail |
  |----|------|-------------|---------|--------|
  | Catalog | 8 | 2 | 3 | [features/catalog.md](features/catalog.md) |
  | Order | 5 | 1 | 4 | [features/order.md](features/order.md) |
  ```

## TASKS.md
- Maintenir un fichier `TASKS.md` à la racine du projet pour suivre les tâches.
- **Relire `TASKS.md` en début de session** pour connaître le travail en cours et à venir.
- **Mettre à jour `TASKS.md`** à chaque changement de statut d'une tâche.
- Structure attendue :
  - `[ ]` à faire
  - `[~]` en cours
  - `[x]` terminée
  - Feature / Bounded Context associé
  - Priorité (haute, moyenne, basse)
- Quand une tâche est terminée, la garder cochée comme historique (ne pas supprimer).
- Archiver périodiquement les tâches terminées sous une section `## Archive`.

### Scaling (projets > 30 tâches actives)
- Découper en `tasks/<bc-name>.md`.
- TASKS.md devient un **index** avec compteurs :
  ```
  | BC | A faire | En cours | Détail |
  |----|---------|----------|--------|
  | Catalog | 5 | 2 | [tasks/catalog.md](tasks/catalog.md) |
  | Order | 3 | 1 | [tasks/order.md](tasks/order.md) |
  ```
- Archive dans `tasks/archive.md` (pas dans TASKS.md ni dans les fichiers par BC).
