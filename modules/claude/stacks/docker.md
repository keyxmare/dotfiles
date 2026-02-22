# Stack Docker

## Conventions générales
- Préférer `compose.yaml` (format moderne) à `docker-compose.yml`.
- Ne pas modifier les fichiers Docker (Dockerfile, compose.yaml) sans demander.
- Exécuter les commandes PHP/Symfony via les containers Docker quand applicable.
- Utiliser le Makefile comme point d'entrée (pas de `docker compose exec` en direct).

## Sécurité des images
- **JAMAIS de tag `latest`** dans les Dockerfiles et compose.yaml. Toujours une **version figée** (ex: `dunglas/frankenphp:1-php8.4`, `mysql:8.4.4`, `node:22.14-alpine`).
- Avant de référencer une image Docker, **vérifier les tags disponibles** sur Docker Hub.
- Raisons : reproductibilité des builds, pas de mise à jour surprise, traçabilité.

## Architecture multi-stage (FrankenPHP + Symfony)

### Stages obligatoires
```
frankenphp_upstream  →  Image de base FrankenPHP (tag figé)
frankenphp_base      →  Extensions PHP, Composer, config commune
frankenphp_dev       →  Xdebug, php.ini-development, worker --watch
frankenphp_prod      →  php.ini-production, opcache optimisé, sans dev deps
```

### Règles par stage

**Base** :
- Installer les extensions PHP nécessaires (apcu, intl, opcache, zip, pdo_pgsql/pdo_mysql).
- Copier Composer depuis l'image officielle (`COPY --from=composer:2 /usr/bin/composer`).
- `WORKDIR /app`.

**Dev** :
- `APP_ENV=dev`
- Installer Xdebug (`XDEBUG_MODE=off` par défaut, activable via env).
- Utiliser `php.ini-development`.
- Worker mode avec `--watch` pour hot reload : `FRANKENPHP_WORKER_CONFIG=watch`.
- **Ne PAS copier le code source** dans l'image dev (bind mount via compose).

**Prod** :
- `APP_ENV=prod`
- Utiliser `php.ini-production`.
- Copier `composer.json`, `composer.lock`, `symfony.lock` en premier (layer caching).
- `composer install --no-cache --prefer-dist --no-dev --no-autoloader --no-scripts`.
- Copier le code source ensuite.
- `composer dump-autoload --classmap-authoritative --no-dev`.
- `composer dump-env prod`.
- Exécuter en non-root quand possible (`USER www-data` + `CAP_NET_BIND_SERVICE`).

## Gestion des caches — Règle d'or

> **En dev : aucun cache persistant dans un volume nommé.**
> Tout cache doit être éphémère (tmpfs ou anonymous volume) pour éviter les incohérences
> qui nécessitent un rebuild ou un reboot du container.

### Dev — compose.yaml

```yaml
services:
  php:
    build:
      context: .
      target: frankenphp_dev
    volumes:
      # Bind mount du code source
      - ./:/app
      # Écraser var/ par un tmpfs : cache et logs éphémères, vidés à chaque restart
      - type: tmpfs
        target: /app/var
    environment:
      APP_ENV: dev
      XDEBUG_MODE: "off"
```

**Pourquoi tmpfs pour `var/`** :
- `var/cache/` est régénéré automatiquement par Symfony au premier request.
- Pas de cache stale après un `git pull`, un changement de branche ou un changement de config.
- `var/log/` reste accessible pendant la vie du container mais ne pollue pas le host.
- **Restart du container = cache propre**, sans `rm -rf var/cache/*` ni rebuild.

### Prod — compose.yaml

```yaml
services:
  php:
    build:
      context: .
      target: frankenphp_prod
    volumes:
      # Volume nommé pour var/ en prod (persistance logs, sessions)
      - app_var:/app/var
    environment:
      APP_ENV: prod

volumes:
  app_var:
```

### Récapitulatif caches par environnement

| Répertoire | Dev | Prod |
|---|---|---|
| `var/cache/` | tmpfs (éphémère) | Dans l'image ou volume nommé |
| `var/log/` | tmpfs (éphémère) | Volume nommé (persistant) |
| `vendor/` | Bind mount (via `./:/app`) | Dans l'image (COPY) |
| `node_modules/` | Anonymous volume | Dans l'image (COPY) |

## FrankenPHP — Worker mode

- **Dev** : `--watch` activé pour détecter les changements de fichiers et recharger automatiquement.
- **Prod** : worker mode standard sans `--watch`. Configurer `max_requests` pour éviter les memory leaks.
- Le worker mode garde l'app en mémoire : attention aux services stateful (reset entre les requêtes via Symfony Runtime).

## Commandes de référence

```makefile
# Dev : rebuild sans cache si problème
make rebuild:  ## docker compose build --no-cache php

# Dev : restart propre (tmpfs = cache vidé automatiquement)
make restart:  ## docker compose restart php

# Prod : warmup cache dans le Dockerfile
# RUN php bin/console cache:warmup
```

## Anti-patterns à éviter
- ❌ Volume nommé pour `var/cache/` en dev → cache stale, nécessite rebuild.
- ❌ `docker compose down -v` pour vider le cache → détruit aussi la DB si volume partagé.
- ❌ Bind mount de `vendor/` en prod → lent, fragile, pas reproductible.
- ❌ `latest` comme tag d'image → non reproductible.
- ❌ Worker mode sans `--watch` en dev → changements de code non pris en compte.
- ❌ Copier le code dans l'image dev → inutile avec le bind mount, ralentit le build.
