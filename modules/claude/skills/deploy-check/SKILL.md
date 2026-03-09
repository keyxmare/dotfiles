---
name: deploy-check
description: Pre-deployment checklist verifying migrations, tests, env, and build
allowed-tools: Bash(git *), Bash(make *), Bash(docker compose *), Read, Glob, Grep
---

# Skill — Deploy Check

Tu vérifies que le projet est prêt à être déployé.

## Input

`$ARGUMENTS` peut être :
- `staging` ou `production` (défaut : `staging`)
- Rien → staging

## Process

Exécuter chaque vérification et reporter le statut.

### 1. Git

- Branche courante (attendu : `main` pour production)
- Working tree propre (pas de fichiers non commités)
- Branche à jour avec le remote (`git fetch && git status`)

### 2. Tests

```bash
make test
```

- Tous les tests passent
- Pas de tests skippés sans raison

### 3. Qualité

```bash
make quality
```

- Linter, analyse statique, formatting OK

### 4. Migrations

```bash
docker compose exec php bin/console doctrine:migrations:status
```

- Pas de migrations non exécutées localement
- Pas de migrations en attente de génération :
```bash
docker compose exec php bin/console doctrine:schema:validate
```

### 5. Variables d'environnement

Comparer `.env` avec `.env.example` (ou `.env.dist`) :
- Toutes les variables de `.env.example` sont documentées
- Pas de valeurs de dev hardcodées pour la production (ex: `APP_DEBUG=1`, `APP_ENV=dev`)
- Les secrets sont des placeholders, pas des vraies valeurs

### 6. Docker

```bash
docker compose build --dry-run
```

- Le build passe sans erreur
- Pas de volumes de dev montés dans la config de production (si `docker-compose.prod.yml` existe)

### 7. Dépendances

```bash
docker compose exec php composer audit
```

- Pas de vulnérabilités critiques connues

Si frontend :
```bash
docker compose exec node pnpm audit
```

### 8. Documentation

- `CHANGELOG.md` à jour (si présent)
- Version bumped si applicable (composer.json, package.json)

## Rapport

```
╔══════════════════════════════════════╗
║         DEPLOY CHECK — <env>        ║
╠══════════════════════════════════════╣
║ Git              ✅ / ❌            ║
║ Tests            ✅ / ❌            ║
║ Quality          ✅ / ❌            ║
║ Migrations       ✅ / ❌            ║
║ Env vars         ✅ / ❌            ║
║ Docker build     ✅ / ❌            ║
║ Dependencies     ✅ / ❌            ║
║ Documentation    ✅ / ❌            ║
╠══════════════════════════════════════╣
║ VERDICT          GO / NO-GO         ║
╚══════════════════════════════════════╝
```

Si NO-GO : lister les blockers avec les actions correctives.
