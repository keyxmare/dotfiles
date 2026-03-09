---
name: new-project:sync
description: Synchronise un projet existant avec les templates et conventions actuels du skill
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, Agent, WebSearch, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Micro-generator — Sync

Synchronise un projet existant avec les templates et conventions actuels du skill, sans regénérer l'ensemble du projet. Inspiré du mécanisme `copier update`.

## Références

- Versions de référence → `<skill-path>/assets/versions.json`
- Templates → `<skill-path>/assets/templates/`
- Schéma config → `<skill-path>/assets/scaffold.config.schema.json`
- Règles communes → `<skill-path>/references/rules-common.md`
- Diagnostic → `<skill-path>/references/troubleshooting.md`

`<skill-path>` = `~/.claude/skills/new-project`

## Prérequis

Lire `scaffold.config.json` à la racine du projet. Si le fichier n'existe pas, ce micro-generator ne peut pas fonctionner — signaler à l'utilisateur.

Comparer `scaffold.config.json.skill_version` avec la version courante dans `<skill-path>/assets/versions.json`. Si les versions sont identiques et qu'aucun fichier template n'a changé, signaler que le projet est déjà à jour.

## Arguments

```
/new-project:sync                        → synchronisation complète interactive
/new-project:sync --check                → dry-run, affiche les divergences sans rien modifier
/new-project:sync --force                → applique toutes les mises à jour sans demander (respecte les overrides)
```

## Étape 1 — Détection des divergences

Comparer `skill_version` dans `scaffold.config.json` avec la version courante dans `<skill-path>/assets/versions.json`.

Identifier les fichiers structurels/config divergents :

| Catégorie | Fichiers concernés |
|---|---|
| Composer | `composer.json` (scripts, autoload, require-dev) |
| NPM | `package.json` (scripts, devDependencies) |
| TypeScript | `tsconfig.json`, `tsconfig.app.json` |
| Build | `Makefile`, `Taskfile.yml` |
| Docker | `compose.yaml`, `compose.override.yaml`, `Dockerfile` |
| CI | `.github/workflows/*.yml`, `.gitlab-ci.yml` |
| Qualité | `phpstan.neon`, `.php-cs-fixer.dist.php`, `rector.php`, `.eslintrc.*`, `.prettierrc` |
| Config Symfony | `config/packages/*.yaml` |
| Config Nuxt/Vue | `nuxt.config.ts`, `vite.config.ts` |

Pour chaque fichier, comparer le contenu actuel avec le template courant du skill (en tenant compte des variables de substitution).

Respecter la liste `overrides` dans `scaffold.config.json` — les fichiers listés dans `overrides` sont ignorés (l'utilisateur les a volontairement écartés lors d'un sync précédent).

## Étape 2 — Rapport

Afficher un rapport structuré :

```
Synchronisation — <nom du projet>

  skill_version : 1.2.0 → 1.4.0

  Fichiers divergents
  ─────────────────────────────────────────────────────
  ~ Makefile                      3 sections modifiées
  ~ compose.yaml                  service redis ajouté
  ~ phpstan.neon                  level 8 → 9
  ~ .github/workflows/ci.yml     matrix PHP 8.3 → 8.4
  = .eslintrc.cjs                 (override, ignoré)

  Fichiers manquants
  ─────────────────────────────────────────────────────
  + rector.php                    ajouté dans skill 1.3.0
  + .github/workflows/deploy.yml  ajouté dans skill 1.4.0

Total : X divergents, Y manquants, Z overrides ignorés
```

Si `--check` : afficher le rapport et s'arrêter.

## Étape 3 — Résolution interactive

Pour chaque fichier divergent (hors overrides), afficher le diff et proposer :

```
── Makefile ──────────────────────────────────────────

  - quality: phpstan phpcs phpunit
  + quality: phpstan phpcs rector phpunit mutation

  Action : [apply] skip manual
```

- **`apply`** — appliquer la modification via `Edit` (jamais `Write`).
- **`skip`** — ignorer cette fois, ne pas ajouter aux overrides.
- **`manual`** — ignorer et ajouter le chemin du fichier dans `scaffold.config.json.overrides` pour les syncs futurs.

Si `--force` : appliquer automatiquement tous les fichiers non listés dans `overrides`.

Pour les fichiers manquants, proposer de les créer via `Write`.

## Étape 4 — Mise à jour de scaffold.config.json

Via `Edit` :

- Mettre à jour `skill_version` avec la version courante du skill.
- Mettre à jour `updated_at` avec la date du jour.
- Ajouter les chemins des fichiers `manual` dans le tableau `overrides` (sans doublons).

## Étape 5 — Vérification

```bash
make quality                 # lint + tests
```

Corriger les erreurs avant de terminer. Voir `<skill-path>/references/troubleshooting.md`.

## Étape 6 — Commit

Si des modifications ont été appliquées :

```bash
git add .
git commit -m "chore: sync project with skill v<version>"
```

## Règles

Voir `<skill-path>/references/rules-common.md` pour les règles communes.

Règles spécifiques à ce micro-generator :
- **Ne jamais toucher au code métier** — `Domain/`, `Application/` (handlers, commands, queries), code utilisateur. Uniquement les fichiers structurels et de configuration.
- **Uniquement `Edit` pour les fichiers existants** — ne jamais utiliser `Write` sur un fichier qui existe déjà, pour éviter d'écraser du contenu utilisateur.
- **Respecter les overrides** — les fichiers listés dans `scaffold.config.json.overrides` sont systématiquement ignorés, sauf si l'utilisateur demande explicitement de les resynchroniser.
- **Si un fichier a été modifié par l'utilisateur** depuis la dernière génération, toujours afficher le diff avant d'appliquer, même avec `--force`.
- **Pas de suppression** — ce micro-generator ajoute ou modifie, il ne supprime jamais de fichiers.
