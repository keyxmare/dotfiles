---
name: new-project:upgrade
description: Checks and updates project dependencies, scaffold config, and structure
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Upgrade

Vérifie et met à jour les dépendances, la configuration scaffold et la structure d'un projet existant.

## Références

- Versions de référence → `<skill-path>/assets/versions.json`
- Schéma config → `<skill-path>/assets/scaffold.config.schema.json`
- Règles communes → `<skill-path>/references/rules-common.md`
- Diagnostic → `<skill-path>/references/troubleshooting.md`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, ce micro-generator ne peut pas fonctionner — signaler à l'utilisateur.

## Arguments

```
/new-project:upgrade                     → analyse complète + propositions
/new-project:upgrade --check             → dry-run, liste les mises à jour possibles sans rien modifier
/new-project:upgrade deps                → met à jour uniquement les dépendances
/new-project:upgrade schema              → migre scaffold.config.json vers la dernière version du schéma
/new-project:upgrade structure           → aligne la structure de fichiers sur les conventions actuelles
```

## Étape 1 — Analyse

### Dépendances

Comparer les versions actuelles (depuis `composer.json`, `package.json`) avec :
1. Les versions dans `<skill-path>/assets/versions.json` (fallback).
2. Les versions les plus récentes via context7 / WebSearch (si `research.before_impl` = `true`).

Classer chaque dépendance :

| Statut | Description |
|---|---|
| ✅ À jour | Version actuelle ≥ version de référence |
| ⬆️ Mise à jour mineure | Patch ou minor disponible (safe) |
| ⚠️ Mise à jour majeure | Major disponible (breaking changes possibles) |
| 🔴 Obsolète | Package déprécié ou remplacé |

### Structure

Comparer l'arborescence du projet avec la structure attendue selon le type, le profil et la complexité dans `scaffold.config.json`.

Détecter :
- Dossiers manquants (ex: `tests/Factory/` si les factories n'existaient pas avant).
- Fichiers de configuration absents ou obsolètes (ex: `rector.php` si non présent).
- Fichiers `.tpl` utilisés qui ont été mis à jour dans le skill.

### Schéma

Comparer `scaffold.config.json.version` avec la version courante du schéma. Si la version est inférieure, proposer une migration.

Changements de schéma connus :

| De | Vers | Changements |
|---|---|---|
| 1.0 | 1.1 | Ajout de `PATCH` dans les opérations CRUD |
| 1.1 | 1.2 | Ajout de `ssr`, `nuxt_ddd_strategy`, `soft_delete` par entité. Suppression du mapping XML Doctrine (PHP attributes). |

## Étape 2 — Rapport

Afficher un rapport structuré :

```
Analyse du projet — <nom>

  Dépendances
  ─────────────────────────────────────────────────────
  ✅ symfony/framework-bundle    8.0.2 → 8.0.2 (à jour)
  ⬆️ doctrine/orm               3.4.1 → 3.5.0 (minor)
  ⚠️ nuxt                       4.0.0 → 4.2.1 (major features)
  🔴 some-deprecated-package    1.0.0 → remplacé par other-package

  Structure
  ─────────────────────────────────────────────────────
  + tests/Factory/               ← dossier manquant (factories de test)
  + rector.php                   ← fichier manquant (Rector config)
  ~ references/security.md      ← CSP header ajouté dans le skill

  Schéma
  ─────────────────────────────────────────────────────
  scaffold.config.json : 1.0 → 1.1 (ajout PATCH dans CRUD)

Appliquer les mises à jour ? (ok / sélectionne : deps, structure, schema, ou numéros)
```

Si `--check` : afficher le rapport et s'arrêter.

## Étape 3 — Application

### Dépendances (`deps`)

Pour chaque mise à jour acceptée :

1. **Mineures/patch** : mettre à jour la contrainte dans `composer.json` / `package.json` via `Edit`.
2. **Majeures** : rechercher les breaking changes via context7/web, lister les changements nécessaires, demander confirmation avant d'appliquer.
3. Exécuter `make install` pour appliquer les mises à jour.
4. Exécuter `make quality` pour vérifier qu'aucune régression n'est introduite.

### Structure (`structure`)

Pour chaque élément manquant :
- Créer les dossiers manquants.
- Générer les fichiers de configuration manquants (avec les templates du skill).
- Ne pas écraser les fichiers existants — signaler les différences.

### Schéma (`schema`)

Migrer `scaffold.config.json` :
- Mettre à jour le champ `version`.
- Ajouter les nouveaux champs avec leurs valeurs par défaut.
- Mettre à jour `updated_at`.
- Valider contre le schéma à jour.

## Étape 4 — Vérification

```bash
make quality                 # lint + tests
```

Corriger les erreurs avant de terminer. Voir `<skill-path>/references/troubleshooting.md`.

## Étape 5 — Commit

Si des modifications ont été appliquées :

```bash
git add .
git commit -m "chore: upgrade project dependencies and structure"
```

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Ne jamais downgrader** une version sans accord explicite de l'utilisateur.
- **Mises à jour majeures** : toujours rechercher les breaking changes et demander confirmation avant d'appliquer.
- **Pas de modification automatique du code métier** — uniquement les fichiers de configuration et de structure.
- **Backup implicite** : le commit précédent sert de point de rollback.
