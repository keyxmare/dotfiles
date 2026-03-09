---
name: adr
description: Creates a numbered Architecture Decision Record
allowed-tools: Bash(git *), Read, Write, Edit, Glob, Grep
---

# Skill — ADR

Tu crées un Architecture Decision Record numéroté et structuré.

## Input

`$ARGUMENTS` = titre de la décision (ex: `utiliser PostgreSQL plutôt que MySQL`).

## Process

### 1. Numérotation

Chercher les ADR existants :

```
docs/adr/
```

Déterminer le prochain numéro (format `NNNN`, ex: `0001`, `0012`).

Si le dossier `docs/adr/` n'existe pas, le créer.

### 2. Contexte

Analyser le projet pour enrichir le contexte :
- Stack technique actuelle (composer.json, package.json, docker-compose.yml)
- Patterns déjà en place (DDD, CQRS, etc.)
- ADR précédents liés au même sujet

Demander à l'utilisateur de compléter le contexte si nécessaire (max 1 question).

### 3. Rédaction

Créer `docs/adr/NNNN-<slug>.md` :

```markdown
# NNNN. <Titre>

Date : YYYY-MM-DD

## Statut

Accepted

## Contexte

<Pourquoi cette décision est nécessaire. Contraintes, forces en jeu, problème à résoudre.>

## Options envisagées

### Option A — <nom>
- Avantages : ...
- Inconvénients : ...

### Option B — <nom>
- Avantages : ...
- Inconvénients : ...

## Décision

<L'option retenue et pourquoi.>

## Conséquences

- <Impact positif>
- <Impact négatif ou trade-off>
- <Actions à mener>
```

Règles :
- Français pour le contenu, anglais pour le slug du fichier
- Factuel et concis, pas de prose inutile
- Lister au moins 2 options avec avantages/inconvénients
- Les conséquences incluent les trade-offs assumés

### 4. Liens

Si l'ADR remplace ou amende un ADR précédent :
- Ajouter `Supersedes [NNNN](NNNN-slug.md)` dans le statut
- Mettre à jour l'ancien ADR : statut → `Superseded by [NNNN](NNNN-slug.md)`
