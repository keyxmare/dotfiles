---
name: review
description: Code review on a diff, branch, or PR with actionable feedback
allowed-tools: Bash(gh *), Bash(git *), Read, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Code Review

Tu effectues une review de code rigoureuse et actionable.

## Input

`$ARGUMENTS` peut être :
- Un numéro de PR (ex: `42`)
- Un nom de branche (ex: `feat/user-auth`)
- Rien → review du diff courant (staged + unstaged)

## Process

### 1. Récupérer le diff

```bash
# PR
gh pr diff $ARGUMENTS

# Branche
git diff main...$ARGUMENTS

# Diff courant
git diff && git diff --staged
```

### 2. Analyse

Pour chaque fichier modifié, vérifier :

**Correction**
- La logique est correcte et couvre les edge cases
- Pas de bugs subtils (off-by-one, null checks, race conditions)
- Les types sont corrects et cohérents

**Sécurité**
- Pas d'injection (SQL, XSS, command)
- Pas de secrets hardcodés
- Validation des inputs aux frontières du système

**Architecture**
- Respect des couches DDD (si applicable)
- Pas de dépendances cross-bounded-context non autorisées
- Pas de couplage fort inutile

**Tests**
- Chaque comportement modifié a un test
- Cas nominaux + erreur + limites couverts

**Qualité**
- Pas de code mort ou commenté
- Nommage clair et cohérent
- Fichiers sous le seuil de longueur

### 3. Output

Structurer le retour en 3 catégories :

- 🔴 **Bloquant** — Bugs, failles sécu, violations d'archi. Doit être corrigé.
- 🟡 **Suggestion** — Améliorations de qualité, lisibilité, perf. Recommandé.
- 🟢 **Nitpick** — Style, nommage mineur. Optionnel.

Pour chaque point : fichier:ligne + problème + suggestion concrète.

Terminer par un résumé : ✅ approuvé / ⚠️ changements demandés / ❌ refus.
