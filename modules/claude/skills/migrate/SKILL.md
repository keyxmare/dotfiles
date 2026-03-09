---
name: migrate
description: Generates and applies Doctrine migrations safely via Docker
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Write, Edit, Glob, Grep, Agent, mcp__context7__resolve-library-id, mcp__context7__query-docs
---

# Skill — Migration

Tu génères et appliques des migrations Doctrine de manière sécurisée.

## Input

`$ARGUMENTS` peut être :
- Une description du changement (ex: `ajouter un champ email_verified à User`)
- `status` → afficher l'état des migrations
- `rollback` → annuler la dernière migration
- Rien → détecter les changements de schema non migrés

## Process

### 1. État courant

```bash
docker compose exec php bin/console doctrine:migrations:status
```

Vérifier qu'il n'y a pas de migrations non exécutées. Si oui, les signaler avant de continuer.

### 2. Détection ou modification

**Si description fournie** : modifier les entités Doctrine concernées (attributs, relations, types).

**Si rien** : comparer le schema actuel avec les entités :
```bash
docker compose exec php bin/console doctrine:schema:validate
```

### 3. Génération

```bash
docker compose exec php bin/console doctrine:migrations:diff
```

Lire la migration générée et vérifier :
- La migration `up()` correspond au changement attendu
- La migration `down()` est l'inverse exact
- Pas de perte de données (DROP COLUMN sur des colonnes remplies → alerter)
- Les index sont cohérents
- Les contraintes FK sont correctes

Si la migration nécessite une transformation de données, ajouter les requêtes SQL dans `up()`.

### 4. Application

```bash
docker compose exec php bin/console doctrine:migrations:migrate --no-interaction
```

Puis valider :
```bash
docker compose exec php bin/console doctrine:schema:validate
```

### 5. Tests

```bash
make test
```

Vérifier que les tests passent avec le nouveau schema.

### 6. Commit

```bash
git add src/*/Infrastructure/Doctrine/Migrations/
git add src/*/Domain/Entity/
```

Message :
```
chore: add migration — <description courte>
```

Ne pas push sans accord de l'utilisateur.

## Rollback

Si `$ARGUMENTS` = `rollback` :
```bash
docker compose exec php bin/console doctrine:migrations:migrate prev --no-interaction
```

Confirmer avec l'utilisateur avant d'exécuter.
