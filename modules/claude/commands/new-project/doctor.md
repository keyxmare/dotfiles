---
name: new-project:doctor
description: Vérifie la santé du skill et/ou d'un projet scaffoldé
allowed-tools: Bash(*), Read, Glob, Grep
---

# Micro-generator — Doctor

Vérifie la santé du skill `/new-project` et/ou d'un projet scaffoldé. Diagnostique les problèmes de configuration, de structure et de cohérence.

## Références

- Templates → `<skill-path>/assets/templates/`
- Versions → `<skill-path>/assets/versions.json`
- Schéma config → `<skill-path>/assets/scaffold.config.schema.json`
- Features DDD → `<skill-path>/references/ddd-features.md`
- Modules → `<skill-path>/references/modules.md`
- Skill principal → `<skill-path>/SKILL.md`

`<skill-path>` = `~/.claude/skills/new-project`

## Arguments

```
/new-project:doctor                      → auto-détection du mode
/new-project:doctor --skill              → vérifier uniquement le skill
/new-project:doctor --project            → vérifier uniquement le projet
/new-project:doctor --verbose            → afficher le détail de chaque vérification
```

## Détection du mode

- Si `--skill` est passé → mode skill.
- Si `--project` est passé → mode projet.
- Si aucun flag : vérifier si `scaffold.config.json` existe à la racine du projet.
  - **Oui** → mode projet.
  - **Non** → mode skill.

## Mode Skill (`--skill`)

Vérifie l'intégrité de l'installation du skill `/new-project`.

### Vérifications

| # | Vérification | Méthode |
|---|---|---|
| S1 | Tous les templates référencés dans `ddd-features.md` existent dans `assets/templates/` | Grep les noms de templates dans `ddd-features.md`, vérifier leur existence via Glob |
| S2 | Placeholders de templates valides (`{{...}}` correctement fermés) | Grep `{{` dans chaque template, vérifier que chaque ouverture a une fermeture correspondante |
| S3 | `versions.json` est un JSON valide avec toutes les clés requises | Read + parse, vérifier les clés : `skill_version`, `schema_version` |
| S4 | `scaffold.config.schema.json` est un JSON Schema valide | Read + parse, vérifier la structure `$schema`, `type`, `properties` |
| S5 | Tous les fichiers de stack référencés dans `SKILL.md` existent dans `~/.claude/stacks/` | Grep les noms de fichiers `.md` dans SKILL.md, vérifier leur existence |
| S6 | Tous les fichiers de référence existent dans `references/` | Glob `references/*.md` et `references/**/*.md`, comparer avec les fichiers référencés dans SKILL.md et les commandes |
| S7 | Toutes les commandes existent dans `commands/new-project/` | Glob `commands/new-project/*.md`, comparer avec les commandes référencées dans SKILL.md |
| S8 | `init-structure.sh` est exécutable | Bash `test -x` sur le fichier |

## Mode Projet (`--project`)

Vérifie la cohérence d'un projet scaffoldé.

### Vérifications

| # | Vérification | Méthode |
|---|---|---|
| P1 | `scaffold.config.json` existe et est valide contre le schéma | Read + valider les champs requis, comparer avec `scaffold.config.schema.json` |
| P2 | `skill_version` du projet est compatible avec la version courante du skill | Comparer avec `versions.json` — avertir si le projet est en retard |
| P3 | Tous les bounded contexts déclarés ont leurs répertoires | Pour chaque context dans `scaffold.config.json.bounded_contexts`, vérifier que `src/<Context>/` existe avec `Domain/`, `Application/`, `Infrastructure/` |
| P4 | Tous les modules déclarés ont leurs fichiers | Pour chaque module dans `scaffold.config.json.modules`, vérifier les fichiers attendus (config, services Docker, code) via `<skill-path>/references/modules/<module>.md` |
| P5 | Toutes les entités déclarées ont leurs fichiers | Pour chaque entité dans les features, vérifier : Model, Repository (interface + implémentation), Controller, tests unitaires, tests intégration |
| P6 | Services Docker cohérents avec les modules | Si module `cache` → service `redis` dans `compose.yaml`. Si module `search` → service `meilisearch`. Si module `mailer` → service `mailpit`. Etc. |
| P7 | Makefile/Taskfile contient les targets standard | Vérifier la présence de : `install`, `up`, `down`, `quality`, `test`, `lint`, `cs`, `phpstan` |
| P8 | Configuration CI cohérente avec le CI provider déclaré | Si `ci` = `github` → `.github/workflows/ci.yml` existe. Si `ci` = `gitlab` → `.gitlab-ci.yml` existe |
| P9 | Documentation cohérente avec les flags de doc | Si `doc.openapi` → `docs/api/openapi.yaml` existe. Si `doc.c4` → `docs/c4/` existe. Si `doc.adr` → `docs/adr/` existe |

## Format de sortie

### Tableau de résultats

```
Doctor — <mode> (<nom du projet ou skill path>)

  #   Statut   Vérification                              Détail
  ─── ──────── ───────────────────────────────────────── ──────────────────────────────
  S1  ✓        Templates référencés                      12/12 templates trouvés
  S2  ✓        Placeholders valides                      Aucun placeholder mal formé
  S3  ✓        versions.json                             JSON valide, toutes clés présentes
  S4  ✓        scaffold.config.schema.json               JSON Schema valide
  S5  ⚠        Fichiers de stack                         symfony.md trouvé, nuxt.md manquant
  S6  ✓        Fichiers de référence                     8/8 fichiers trouvés
  S7  ✓        Commandes                                 6/6 commandes trouvées
  S8  ✗        init-structure.sh                         Fichier non exécutable
```

### Légende des statuts

| Statut | Signification |
|---|---|
| ✓ | Vérification réussie |
| ⚠ | Avertissement — fonctionnel mais à corriger |
| ✗ | Échec — problème bloquant |

### Résumé

```
Résumé : 6 ✓  1 ⚠  1 ✗

  Actions recommandées :
  1. chmod +x ~/.claude/skills/new-project/assets/init-structure.sh
  2. Créer le fichier ~/.claude/stacks/nuxt.md ou retirer la référence de SKILL.md
```

## Mode verbose (`--verbose`)

En mode verbose, afficher le détail de chaque vérification :

```
  S1  ✓  Templates référencés
         ├── entity.php.tpl                    ✓
         ├── controller-crud.php.tpl           ✓
         ├── handler-test.php.tpl              ✓
         └── ... (12/12)
```

## Règles

- **Aucune modification** — ce micro-generator est en lecture seule. Il ne modifie aucun fichier.
- **Toujours afficher le résumé** — même si tout est vert, afficher le décompte.
- **Actions recommandées** — pour chaque ⚠ ou ✗, proposer une commande ou action corrective.
- **Pas de dépendance réseau** — toutes les vérifications sont locales (pas de WebSearch, pas de context7).
