---
name: pr-description
description: Générer une description de Pull Request en Markdown à partir des commits divergeant de master/main, ou d'une plage de commits précisée. Utiliser quand l'utilisateur veut rédiger une PR, documenter ses changements, ou préparer une description de merge request.
argument-hint: [--base=<branch>] [--last=<N>] [--from=<commit>] [--title=<titre>] [--lang=fr|en]
---

# PR Description Generator

Tu es un expert en communication technique. Tu analyses les changements git d'une branche et tu produits une description de Pull Request claire, structurée et directement utilisable sur GitHub / GitLab / Bitbucket.

## Arguments

- `--base=<branch>` : branche de référence pour le diff (défaut : `main` ou `master`, auto-détecté)
- `--last=<N>` : limiter à N commits récents (ex: `--last=3`)
- `--from=<commit>` : partir d'un commit précis (SHA, tag, ou ref)
- `--title=<titre>` : forcer le titre de la PR (sinon, généré automatiquement)
- `--lang=fr|en` : langue de la description (défaut : `fr`)

> **Priorité des options** : `--last` ou `--from` priment sur `--base`. Si aucun argument n'est fourni, utiliser la divergence par rapport à la branche principale auto-détectée.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet).
2. Stacks spécifiques : `git.md` si disponible.
3. **Déterminer la plage de commits** selon les arguments :
   - `--last=N` → `HEAD~N..HEAD`
   - `--from=<commit>` → `<commit>..HEAD`
   - `--base=<branch>` → `<branch>..HEAD`
   - (défaut) → détecter la branche principale puis `<main|master>..HEAD`
4. **Lire MEMORY.md** pour connaître le contexte du projet (stack, conventions, BCs).

## Phase 1 — Collecte des données git

Exécuter les commandes suivantes (via Bash) pour collecter les données brutes :

### 1.1 Informations de branche

```bash
# Branche courante
git branch --show-current

# Détection de la branche principale si --base non fourni
git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}'
# ou fallback :
git branch -r | grep -E 'origin/(main|master)' | head -1
```

### 1.2 Log des commits de la plage

```bash
git log <plage> --no-merges --oneline
# Ex : git log main..HEAD --no-merges --oneline
```

### 1.3 Log détaillé (messages + auteurs)

```bash
git log <plage> --no-merges --pretty=format:"%h|%s|%b|%an" --date=short
```

### 1.4 Statistiques du diff

```bash
git diff <plage> --stat
```

### 1.5 Diff complet (pour analyse de contenu)

```bash
git diff <plage> --diff-filter=ACMDR --name-only
```

> Si le diff dépasse 300 fichiers, se limiter à `--stat` et `--name-only`. Ne pas lire le diff complet fichier par fichier.

### 1.6 Variables d'environnement ajoutées

```bash
git diff <plage> -- "*.env*" ".env.example" ".env.dist" | grep "^+" | grep -v "^+++"
```

## Phase 2 — Analyse et catégorisation

### 2.1 Classifier les commits

Lire les messages de commit et les classer par type (Conventional Commits si présents, sinon inférer) :

| Type | Conventional | Mots-clés inférés |
|------|-------------|-------------------|
| Feature | `feat` | add, create, implement, new, introduce |
| Fix | `fix` | fix, correct, patch, repair, resolve, hotfix |
| Refactor | `refactor` | refactor, extract, move, rename, reorganize |
| Performance | `perf` | optim, cache, perf, speed, improve |
| Tests | `test` | test, spec, coverage |
| Docs | `docs` | doc, readme, comment, changelog |
| Chore | `chore` | bump, update deps, upgrade, config, ci, build |
| Breaking | `!` ou `BREAKING` | breaking, remove, drop, deprecate |

### 2.2 Identifier les fichiers clés modifiés

Regrouper les fichiers modifiés par catégorie :
- **Entités / Domaine** : `Entity/`, `Domain/`, `Model/`
- **API / Controllers** : `Controller/`, `Action/`, `DataProvider/`, `DataPersister/`
- **Infrastructure** : `Repository/`, `Service/`, migrations, config
- **Tests** : `tests/`
- **Configuration** : `.env`, `config/`, `docker-compose`, `Makefile`
- **Frontend** : `assets/`, `*.vue`, `*.ts`, `*.js`

### 2.3 Détecter les points d'attention

- **Migrations** : présence de fichiers dans `migrations/`
- **Breaking changes** : type `!`, `BREAKING CHANGE`, ou suppression de classe/route publique
- **Nouvelles variables d'env** : fichiers `.env*` modifiés
- **Dépendances** : `composer.json`, `package.json` modifiés
- **Sécurité** : `security.yaml`, fichiers d'auth modifiés
- **Performance** : changements sur cache, queries, index

### 2.4 Générer le titre

Si `--title` non fourni, générer un titre à partir :
1. Du message du commit le plus significatif (feature ou fix principal)
2. Du type dominant (feat, fix, refactor, etc.)
3. Format : `[type]: description courte en <lang>` (max 72 caractères)

## Phase 3 — Génération et écriture du fichier

**Consulter `references/report-template.md`** pour le template complet.

Règles de rédaction :
- **Concis** : chaque puce = 1 ligne, pas de rembourrage.
- **Orienté "pourquoi"** : expliquer l'intention, pas juste "on a modifié X".
- **Supprimer les sections vides** : ne pas laisser de sections sans contenu.
- **Langue** : respecter `--lang` (défaut `fr`). Titres de sections en `--lang`, code et noms de fichiers toujours en anglais.
- **Conventional Commits** : si le projet utilise les conventional commits (détecté sur le log), s'y conformer pour le titre.

### Écriture du fichier (OBLIGATOIRE)

**Écrire la description générée dans `PR_DESCRIPTION.md` à la racine du projet** (répertoire de travail courant) via le tool Write.

- Le fichier est écrasé à chaque exécution du skill.
- Confirmer à l'utilisateur : `PR_DESCRIPTION.md généré.` avec le chemin absolu.

## Phase Finale — Mise à jour documentaire

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

- MEMORY.md : mettre à jour uniquement si des insights pertinents ont été identifiés (ex : pattern architectural nouveau, dette découverte).
- Ne PAS mettre à jour FEATURES.md ni TASKS.md automatiquement — la PR description n'implique pas de modification du périmètre documenté.

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à pr-description :
- **Pas de hallucination** : ne décrire que ce qui est réellement dans le diff. Ne pas inventer de contexte.
- **Ignorer les merge commits** : `--no-merges` systématique.
- **Gros diffs** : si le diff est très large (>50 fichiers), se concentrer sur les fichiers les plus significatifs et mentionner le volume total dans le résumé.
- **Fixup/squash** : si le log contient `fixup!` ou `squash!`, les mentionner comme "corrections mineures" sans les détailler.
- **Toujours écrire le fichier `PR_DESCRIPTION.md`** à la racine du projet — ne jamais seulement afficher le contenu en console.
