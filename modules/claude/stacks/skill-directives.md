# Directives communes à tous les skills

Ce fichier est la **source de vérité** pour les obligations qui s'appliquent à chaque skill sans exception. Tout SKILL.md doit référencer ce fichier en Phase 0.

## Directives communes

Tout skill DOIT respecter ces directives. Ne pas les re-spécifier dans chaque SKILL.md.

- **Lecture seule par défaut** : ne pas modifier le code sans demande explicite de l'utilisateur.
- **Exhaustivité** : scanner tout le scope demandé, ne pas sauter de fichiers.
- **Minimiser les faux positifs** : en cas de doute, arrondir vers le score le plus favorable. Mieux vaut sous-estimer que sur-alarmer.
- **Pédagogie** : voir `~/.claude/SOUL.md`. Expliquer chaque problème détecté et comment le corriger.
- **Pragmatisme** : voir `~/.claude/CLAUDE.md` Conventions. Pas de sur-ingénierie, adapter l'analyse au contexte du projet.
- **Shared Kernel** : attention particulière sur `Shared/`, `Common/`, `Kernel/` — ces classes sont souvent utilisées partout.
- **Consulter les references/** : chaque skill a un dossier `references/` avec les patterns de scan et les templates de rapport. Les lire en Phase 0.

## Table de grading universelle

Tous les skills avec scoring A-F utilisent cette table. Ne pas la copier dans chaque SKILL.md.

| Score | Grade | Label | Couleur |
|-------|-------|-------|---------|
| 9.0 - 10.0 | A | Excellent | vert |
| 7.0 - 8.9 | B | Bon | bleu |
| 5.0 - 6.9 | C | Acceptable | jaune |
| 3.0 - 4.9 | D | Préoccupant | orange |
| 0.0 - 2.9 | F | Critique | rouge |

## Exploitation cross-skill

Tout skill analytique DOIT lire `MEMORY.md` en Phase 0 pour exploiter les résultats des skills précédents. Si des résultats de `/full-audit`, `/dependency-diagram`, `/dead-code-detector` ou d'autres skills sont présents, les utiliser pour contextualiser et prioriser l'analyse.

Exemples : score de couplage existant → prioriser les axes faibles, diagramme de dépendances → connaître les BC les plus couplés, code mort détecté → exclure les fichiers déjà signalés.

Il n'est pas nécessaire de re-spécifier cette règle dans chaque SKILL.md via une section "Prérequis recommandés" ou "Astuce".

## Phase 0 — Obligations de chargement du contexte

Avant toute analyse ou modification, le skill **DOIT** exécuter les étapes suivantes dans l'ordre :

1. **Lire et appliquer les instructions globales** `~/.claude/CLAUDE.md` et `~/.claude/stacks/project-docs.md` :
   - Obligations documentaires (MEMORY, FEATURES, TASKS)
   - Conventions (langue, code, réponses)
   - Vérification documentaire avant d'utiliser des APIs/frameworks

2. **Lire les instructions projet** (si existants) :
   - `.claude/CLAUDE.md` du projet pour les conventions spécifiques
   - `MEMORY.md` pour le contexte accumulé entre sessions
   - `FEATURES.md` pour le périmètre fonctionnel (index uniquement si fichier > 50 lignes)
   - `TASKS.md` pour le travail en cours et à venir (index uniquement si fichier > 50 lignes)

3. **Identifier les technologies du projet** (mode normal ou cache) :

   **Mode cache** (si `MEMORY.md` contient un bloc `## Contexte projet`) :
   - Utiliser les infos du bloc cache (PHP, Symfony, BCs, stacks).
   - **Sauter les étapes 3-4** sauf si `composer.json` a un mtime plus récent que la date du dernier scan.
   - **Cache des versions** : une fois la version d'un framework/lib vérifiée dans une session, ne pas la re-vérifier via WebSearch. Ne vérifier via WebSearch que : (a) premier usage dans la session, (b) si la version a changé dans composer.json/package.json, (c) si un doute persiste.

   **Mode normal** (premier scan ou cache absent) :
   - Lire `composer.json` pour PHP, Symfony, Doctrine, API Platform, Messenger et les dépendances
   - Lire `package.json` pour le frontend (Vue.js, React, etc.) si existant
   - Lire `docker-compose.yml` pour les services Docker si existant
   - Lire `Makefile` pour les commandes disponibles si existant
   - **Persister le résultat** dans le bloc `## Contexte projet` de MEMORY.md.

4. **Charger les stacks pertinentes** depuis `~/.claude/stacks/` :
   - Charger UNIQUEMENT les stacks nécessaires au skill en cours (listées dans le SKILL.md).
   - Ne PAS charger systématiquement toutes les stacks du projet.
   - `definition-of-done.md` est chargé uniquement si le skill modifie du code (pas pour les skills analytiques).

5. **Exploiter les résultats précédents** : voir section "Exploitation cross-skill" ci-dessus.

### Mode incrémental (projets > 300 fichiers PHP)

Si `MEMORY.md` contient un bloc `## Contexte projet` avec un commit de dernier scan :

1. Exécuter `git diff --name-only <dernier-commit-scanné>..HEAD` pour obtenir les fichiers changés.
2. Limiter l'analyse aux fichiers changés + leurs dépendants directs (fichiers qui les importent via `use`).
3. Consolider avec les résultats du scan précédent (dans les checkpoints ou MEMORY.md).
4. Mettre à jour le commit HEAD dans le bloc `## Contexte projet` de MEMORY.md.

> **Quand forcer un scan complet** : si le delta dépasse 30% des fichiers du projet, ou si l'utilisateur passe `--full`.

## Scoping par Bounded Context

Tous les skills analytiques DOIVENT supporter le flag `--bc=<name>` :
- Si fourni, limiter l'analyse à `src/<BcName>/` uniquement.
- Si le BC n'existe pas, lister les BCs disponibles et demander confirmation.
- Sur un projet > 500 fichiers PHP, **recommander** l'exécution par BC plutôt que globale.
- Le rapport reste structuré par BC même en mode global (une section par BC).
- Plusieurs BCs peuvent être spécifiés : `--bc=Catalog,Order`.

## Phase Finale — Obligations de mise à jour documentaire

**OBLIGATOIRE.** Cette phase s'exécute systématiquement avant de rendre la main à l'utilisateur, que le skill ait modifié du code ou non (y compris en mode analytique / dry-run).

### 1. MEMORY.md (OBLIGATOIRE si le fichier existe)

Mettre à jour avec :
- Résultats clés de l'analyse (résumé, pas le rapport entier)
- Décisions prises ou recommandations validées par l'utilisateur
- Problèmes identifiés et leur sévérité
- Changements effectués (fichiers modifiés/créés/supprimés)

**Ne pas stocker** : le rapport complet, le code source, les données temporaires.

### 2. TASKS.md (OBLIGATOIRE si le fichier existe et que des tâches changent)

Mettre à jour :
- Marquer les tâches terminées (`[x]`)
- Ajouter les nouvelles tâches identifiées (`[ ]`)
- Mettre à jour le statut des tâches en cours (`[~]`)

### 3. FEATURES.md (si des fonctionnalités ont été ajoutées, modifiées ou supprimées)

Mettre à jour :
- Nouvelles fonctionnalités ajoutées
- Fonctionnalités modifiées ou supprimées
- Statut mis à jour (planned → in progress → done)

### Rappel

Ces obligations viennent de `~/.claude/stacks/project-docs.md`. Les skills ne les remplacent pas — ils doivent les appliquer.

## Workflow recommandé inter-skills

Ordre d'exécution recommandé pour un audit complet de projet :

```
1. /full-audit                    <- Point d'entrée : dashboard consolidé multi-axes
   |
2. /dependency-diagram            <- Cartographier les dépendances inter-BC
   |
3. /test-auditor                  <- Évaluer la couverture et qualité des tests
   |
4. En parallèle selon les résultats :
   |-- /config-archeologist       <- Si score config faible
   |-- /security-auditor          <- Si sécurité à vérifier
   |-- /api-auditor               <- Si API Platform installé
   |-- /dead-code-detector        <- Si code mort suspecté
   +-- /service-decoupler         <- Si couplage élevé
   |
5. Actions correctives :
   |-- /migration-planner         <- Si upgrade Symfony/PHP nécessaire
   |-- /extract-to-cqrs           <- Si controllers fat à refactorer
   |-- /entity-to-vo              <- Si entités à enrichir en VO
   +-- /refactor                  <- Pour appliquer les corrections
```

> **Raccourci** : utiliser `/full-audit` pour exécuter les étapes 1-4 en une seule passe et obtenir un dashboard consolidé.

## Budget de contexte

Sur les tâches longues (> 100k tokens estimés) ou les gros projets (> 300 fichiers), appliquer ces règles :

### Lecture économe
- Grep : TOUJOURS utiliser `head_limit` (max 50 résultats par requête). Affiner avec des patterns plus précis plutôt qu'augmenter la limite. Préférer `head_limit: 30` par défaut. Préférer `output_mode: "files_with_matches"` pour un premier scan. Préférer `output_mode: "count"` quand seul le nombre d'occurrences importe.
- Read : Fichier < 200 lignes → lecture complète OK. Fichier 200-500 lignes → lire avec `limit: 200`, puis cibler. Fichier > 500 lignes → TOUJOURS utiliser `offset`/`limit`.
- Glob : scope le plus étroit possible (`src/Catalog/Domain/**/*.php`), jamais `src/**/*.php` sur un gros projet. Si le résultat dépasse 100 fichiers, affiner le pattern.

### Checkpointing sur disque
- Sur une analyse multi-phases, écrire les résultats intermédiaires dans `/tmp/claude-<skill>-phase<N>.md`.
- Relire le fichier de checkpoint au début de la phase suivante avec `offset`/`limit`.
- Supprimer les fichiers temporaires en fin de tâche.

### Résumé progressif
- Après chaque phase, produire un résumé compact (10-20 lignes max).
- Le résumé doit contenir : métriques clés, fichiers problématiques, décisions prises.
- Écrire ce résumé dans MEMORY.md ET dans le contexte.

### Délégation aux subagents
- Si une tâche est décomposable en sous-tâches indépendantes, utiliser le Task tool pour les paralléliser.
- Chaque subagent retourne un résumé compact, pas le rapport brut.

## Stratégie d'analyse sur gros projets (> 500 fichiers PHP)

### Chunking par groupes

Si le scope contient > 500 fichiers PHP :

1. **Découper par BC** : analyser chaque BC séparément, puis consolider.
2. **Prioriser** : commencer par les BCs les plus modifiés récemment (`git log --oneline --since="3 months" -- src/<BC>/`).
3. **Grouper les catégories** : sur un inventaire multi-catégories, grouper :
   - (a) services + handlers + listeners
   - (b) DTOs + interfaces + repositories
   - (c) templates + traductions + FormTypes
   - (d) le reste
4. **Rapporter progressivement** : afficher les résultats au fil de l'eau, pas tout à la fin.

### Sampling (alternative au scan exhaustif)

Sur un projet > 1000 fichiers PHP :

1. **Pass rapide** : scanner les métriques structurelles (comptages via Glob)
2. **Pass ciblée** : analyser en profondeur les zones à risque (3 plus gros BCs, fichiers > 300 lignes, fichiers récents)
3. **Pass d'extrapolation** : estimer les métriques globales avec intervalle de confiance

## Parallélisation via subagents (projets > 5 BCs)

Les skills analytiques DOIVENT utiliser des subagents (Task tool) quand :
- Le projet a > 5 Bounded Contexts ET le scope est global
- Le skill a des axes/catégories indépendants analysables séparément

### Stratégie

**Par BC** (dead-code-detector, refactor, test-auditor) : 1 subagent par BC (max 3-4 en parallèle).

**Par axe** (full-audit) : lancer les axes en parallèle (ou par groupes de 3-4).

### Format de retour des subagents
Le subagent retourne UNIQUEMENT : score (si applicable), nombre de problèmes par sévérité, top 5 fichiers problématiques.

## Récupération post-compression

1. **Ne pas re-lire les stacks** — conventions stables.
2. **Relire MEMORY.md** — bloc `## Contexte projet` et résumés.
3. **Relire le dernier checkpoint** (`/tmp/claude-<skill>-phase<N>.md`).
4. **Ne PAS re-scanner les fichiers déjà analysés**.

## Reprise de session (--resume)

1. **Vérifier les checkpoints** : chercher `/tmp/claude-<skill>-*.md`.
2. Si des checkpoints existent, proposer la reprise.
3. Le flag `--resume` force la reprise sans demander.
4. Le flag `--full` force un scan complet en ignorant les checkpoints.

## Création d'un nouveau skill — Checklist

- [ ] Phase 0 qui réfère à `skill-directives.md` (pas de duplication)
- [ ] **Ne PAS dupliquer** les directives communes, la table de grading, ni les obligations documentaires
- [ ] Référencer les stacks pertinentes dans la Phase 0
- [ ] Analytique par défaut (lecture seule) + modification optionnelle sur demande
- [ ] Dossier `references/` avec patterns de scan et template de rapport
- [ ] Supporter les flags `--bc=<name>`, `--resume`, `--full`
- [ ] Supporter le checkpointing si l'analyse peut dépasser 3 phases
