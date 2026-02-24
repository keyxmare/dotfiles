---
name: pr-description
description: Générer une description de Pull Request en Markdown à partir des commits divergeant de master/main, ou d'une plage de commits précisée. Utiliser quand l'utilisateur veut rédiger une PR, documenter ses changements, ou préparer une description de merge request.
argument-hint: [--base=<branch>] [--last=<N>] [--from=<commit>] [--title=<titre>] [--lang=fr|en] [--short]
---

# PR Description Generator

Tu es un expert en communication technique. Tu analyses les changements git d'une branche et tu produits une description de Pull Request claire, visuellement soignée et directement utilisable sur GitHub / GitLab / Bitbucket.

## Arguments

- `--base=<branch>` : branche de référence pour le diff (défaut : `main` ou `master`, auto-détecté)
- `--last=<N>` : limiter à N commits récents (ex: `--last=3`)
- `--from=<commit>` : partir d'un commit précis (SHA, tag, ou ref)
- `--title=<titre>` : forcer le titre de la PR (sinon, généré automatiquement)
- `--lang=fr|en` : langue de la description (défaut : `fr`)
- `--short` : forcer le template court (sinon, auto-détecté selon la taille de la PR)

> **Priorité des options** : `--last` ou `--from` priment sur `--base`. Si aucun argument n'est fourni, utiliser la divergence par rapport à la branche principale auto-détectée.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet).
2. Stacks spécifiques : `git.md` si disponible.
3. **Consulter `references/report-template.md`** pour le template complet, les badges de taille, les emojis et les règles de mise en page.
4. **Déterminer la plage de commits** selon les arguments :
   - `--last=N` → `HEAD~N..HEAD`
   - `--from=<commit>` → `<commit>..HEAD`
   - `--base=<branch>` → `<branch>..HEAD`
   - (défaut) → détecter la branche principale puis `<main|master>..HEAD`
5. **Lire MEMORY.md** pour connaître le contexte du projet (stack, conventions, BCs).

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

### 1.4 Statistiques du diff (pour le badge de taille)

```bash
# Stats globales
git diff <plage> --stat

# Stats numériques pour le calcul de taille
git diff <plage> --shortstat

# Stats par fichier (pour le tableau de fichiers)
git diff <plage> --numstat
```

### 1.5 Fichiers modifiés avec statut

```bash
# Liste avec statut (A/M/D/R/C) et noms
git diff <plage> --name-status

# Fichiers détaillés (pour les renommages)
git diff <plage> --diff-filter=R --name-status
```

> Si le diff dépasse 300 fichiers, se limiter à `--stat` et `--name-status`. Ne pas lire le diff complet fichier par fichier.

### 1.6 Détection de changements spéciaux

```bash
# Variables d'environnement ajoutées
git diff <plage> -- "*.env*" ".env.example" ".env.dist" | grep "^+" | grep -v "^+++"

# Migrations
git diff <plage> --name-only -- "migrations/"

# Fichiers frontend
git diff <plage> --name-only -- "*.vue" "*.tsx" "*.ts" "*.css" "*.scss" "templates/"

# Dépendances
git diff <plage> --name-only -- "composer.json" "composer.lock" "package.json" "package-lock.json" "yarn.lock"
```

## Phase 2 — Analyse et catégorisation

### 2.1 Calculer la taille de la PR

À partir de `--shortstat`, extraire les lignes ajoutées et supprimées **hors fichiers de tests** :

```bash
# Lignes hors tests
git diff <plage> -- . ':!tests/' ':!test/' --shortstat
```

Appliquer le barème de taille (voir `references/report-template.md` section "Badges de taille") :

| Taille | Critère (lignes hors tests) | Badge |
|--------|----------------------------|-------|
| XS | < 10 | 🟢 **XS** |
| S | 10–49 | 🟡 **S** |
| M | 50–199 | 🟠 **M** |
| L | 200–499 | 🔴 **L** |
| XL | ≥ 500 | 🟣 **XL** |

### 2.2 Choisir le template

- **Template court** : si `--short` OU (≤ 3 commits ET taille XS ou S)
- **Template complet** : dans tous les autres cas

### 2.3 Classifier les commits

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

### 2.4 Identifier les zones impactées

Regrouper les fichiers modifiés par zone pour le tableau "Impact" :

| Zone | Patterns de détection |
|------|----------------------|
| **Bounded Contexts** | Dossiers de premier niveau sous `src/` qui contiennent des fichiers modifiés |
| **Couches DDD** | `Domain/`, `Application/`, `Infrastructure/`, `Presentation/` |
| **API** | `Controller/`, `Action/`, `DataProvider/`, `DataPersister/`, `State/`, `#[ApiResource]` |
| **Base de données** | `migrations/`, `Entity/`, fichiers avec `#[ORM\` |
| **Configuration** | `config/`, `.env*`, `docker-compose*`, `Makefile` |
| **Frontend** | `assets/`, `*.vue`, `*.ts`, `*.tsx`, `*.js`, `*.css`, `*.scss` |
| **Tests** | `tests/` |
| **Dépendances** | `composer.json`, `package.json` |

### 2.5 Construire le tableau des fichiers modifiés

À partir de `git diff --name-status` et `git diff --numstat`, construire le tableau pour la section collapsible `<details>` :

- **Statut** : A / M / D / R (centré)
- **Fichier** : chemin relatif entre backticks. Pour les renommages, afficher `ancien` → `nouveau`
- **Lignes** : `+N −M` (aligné à droite)

Trier les fichiers par zone (Domain → Application → Infrastructure → Config → Tests → Autres).

### 2.6 Détecter les points d'attention

- **Migrations** : fichiers dans `migrations/`
- **Breaking changes** : type `!`, `BREAKING CHANGE`, ou suppression de classe/route publique
- **Nouvelles variables d'env** : fichiers `.env*` modifiés
- **Dépendances** : `composer.json`, `package.json` modifiés
- **Sécurité** : `security.yaml`, fichiers d'auth modifiés
- **Frontend modifié** : fichiers `.vue`, `.tsx`, `.css`, `.scss` → déclencher la section "Captures d'écran"

### 2.7 Générer le titre

Si `--title` non fourni, générer un titre à partir :
1. Du message du commit le plus significatif (feature ou fix principal)
2. Du type dominant (feat, fix, refactor, etc.)
3. De l'emoji correspondant au type dominant (voir `references/report-template.md` section "Emojis de titre")
4. Format : `<emoji> <type>(<scope>): <description courte en --lang>` (max 72 caractères)

## Phase 3 — Génération et écriture du fichier

**Consulter `references/report-template.md`** pour le template complet et les règles de mise en page.

### Règles de mise en page (OBLIGATOIRES)

1. **Sections vides** — Supprimer toute section sans contenu. Ne jamais laisser de section vide ou avec "Aucun".
2. **Collapsible `<details>`** — Utiliser pour : fichiers modifiés (toujours), commits inclus (toujours), détail des tests (si > 3 tests). Toujours fermer `</details>`. Toujours une ligne vide après `<summary>` et avant `</details>`.
3. **Gras pour les scopes** — Chaque puce de changement commence par le scope en gras : `- **<scope>** — <description>`.
4. **Fichiers entre backticks** — Tous les noms de fichiers, classes et commandes entre backticks.
5. **Tableau metadata** — Le bloc metadata en haut (branche, taille, diff) utilise un tableau sans header `| | |`.
6. **Tableau Impact** — Afficher uniquement les lignes pertinentes (supprimer les lignes "Aucun changement").
7. **Checkboxes Tests** — Cocher uniquement les cases correspondant à des tests réellement détectés dans le diff.
8. **Ligne vide obligatoire** — Avant et après chaque `<details>`, tableau et `---`.

### Règles de rédaction

- **Concis** : chaque puce = 1 ligne, pas de rembourrage.
- **Orienté "pourquoi"** : expliquer l'intention, pas juste "on a modifié X".
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
- **Sections dynamiques** : le template est un guide, pas un carcan. Adapter les sections au contenu réel de la PR. Une PR de 2 lignes de fix n'a pas besoin d'un tableau Impact et d'une section Déploiement.
