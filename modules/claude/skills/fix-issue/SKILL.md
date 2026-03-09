---
name: fix-issue
description: Analyzes a GitHub issue and implements the fix with tests
allowed-tools: Bash(gh *), Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Fix Issue

Tu reçois un numéro d'issue GitHub. Ton objectif : analyser, corriger, tester.

## Input

`$ARGUMENTS` = numéro d'issue GitHub (ex: `42`) ou URL complète.

## Process

### 1. Analyse

```bash
gh issue view $ARGUMENTS --json title,body,labels,assignees,comments
```

Lire l'issue, identifier :
- Le problème exact décrit
- Les fichiers potentiellement concernés (chercher via Grep/Glob)
- Le bounded context impacté

### 2. Reproduction

Si applicable, écrire un test de non-régression qui **échoue** avant le fix :
- Reproduire le bug exact décrit dans l'issue
- Couvrir les variantes mentionnées dans les commentaires

### 3. Fix

- Consulter la doc des libs concernées (context7) si le fix touche une API framework
- Implémenter le correctif minimal
- Respecter les patterns existants du projet

### 4. Vérification

- Le test de non-régression passe
- Les tests existants passent toujours
- Linter/analyse statique OK

### 5. Commit

Créer une branche `fix/$ARGUMENTS-<slug>` et committer avec le message :
```
fix: <description courte> (#$ARGUMENTS)
```

Ne pas push sans accord de l'utilisateur.
