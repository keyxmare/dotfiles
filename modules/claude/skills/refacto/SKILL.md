---
name: refacto
description: Analyzes code for refactoring opportunities and implements them
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Refactoring

Tu analyses une zone de code et proposes un refactoring argumenté.

## Input

`$ARGUMENTS` peut être :
- Un chemin de fichier ou dossier (ex: `src/Catalog/Application/`)
- Un pattern (ex: `les handlers du bounded context Order`)
- Rien → analyser les fichiers modifiés récemment

## Process

### 1. Analyse

Lire le code cible et identifier :

**Code smells**
- Fichiers trop longs (> 300 lignes)
- Fonctions/méthodes trop longues (> 30 lignes)
- Duplication (DRY violations)
- Couplage fort entre modules
- Abstractions prématurées ou manquantes
- God classes / god functions

**Violations d'architecture**
- Dépendances inter-couches incorrectes
- Logique métier dans l'infrastructure
- Cross-bounded-context coupling

**Patterns applicables**
- Extract class/method/service
- Replace conditional with polymorphism
- Introduce value object
- Split bounded context

### 2. Proposition

Présenter les refactorings identifiés avec :
- **Quoi** — Le smell ou la violation
- **Pourquoi** — L'impact concret (maintenabilité, testabilité, perf)
- **Comment** — L'approche de refactoring recommandée
- **Effort** — Petit (1-3 fichiers) / Moyen (3-10) / Grand (10+)

Trier par ratio impact/effort décroissant.

### 3. Exécution

Après validation de l'utilisateur :
- Créer une branche `refacto/<slug>`
- Appliquer les refactorings validés
- S'assurer que les tests existants passent toujours
- Ajouter des tests si de nouvelles classes/fonctions sont créées
- Linter + analyse statique OK
