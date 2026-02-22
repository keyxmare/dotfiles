# Stack Docker

## Conventions générales
- Préférer `compose.yaml` (format moderne) à `docker-compose.yml`.
- Ne pas modifier les fichiers Docker (Dockerfile, compose.yaml) sans demander.
- Exécuter les commandes PHP/Symfony via les containers Docker quand applicable.
- Utiliser le Makefile comme point d'entrée (pas de `docker compose exec` en direct).

## Sécurité des images
- **JAMAIS de tag `latest`** dans les Dockerfiles et compose.yaml. Toujours une **version figée** (ex: `php:8.4-fpm-alpine`, `nginx:1.27-alpine`, `mysql:8.4.4`, `node:22.14-alpine`).
- Avant de référencer une image Docker, **vérifier les tags disponibles** sur Docker Hub.
- Raisons : reproductibilité des builds, pas de mise à jour surprise, traçabilité.

## Architecture multi-stage (PHP-FPM + Nginx + Symfony)

### Stages obligatoires (Dockerfile PHP)
```
php_upstream  →  Image de base PHP-FPM (tag figé, ex: php:8.4-fpm-alpine)
php_base      →  Extensions PHP, Composer, config commune
php_dev       →  Xdebug, php.ini-development
php_prod      →  php.ini-production, opcache optimisé, sans dev deps
```

### Nginx
- Utiliser une image Nginx officielle avec tag figé (ex: `nginx:1.27-alpine`).
- Configurer le virtual host pour proxy les requêtes PHP vers le container PHP-FPM via FastCGI (`fastcgi_pass php:9000`).
- Servir les assets statiques directement depuis Nginx.

### Règles par stage

**Base** :
- Installer les extensions PHP nécessaires (apcu, intl, opcache, zip, pdo_pgsql/pdo_mysql).
- Copier Composer depuis l'image officielle (`COPY --from=composer:2 /usr/bin/composer`).
- `WORKDIR /app`.

**Dev** :
- `APP_ENV=dev`
- Installer Xdebug (`XDEBUG_MODE=off` par défaut, activable via env).
- Utiliser `php.ini-development`.
- **Ne PAS copier le code source** dans l'image dev (bind mount via compose).

**Prod** :
- `APP_ENV=prod`
- Utiliser `php.ini-production`.
- Copier `composer.json`, `composer.lock`, `symfony.lock` en premier (layer caching).
- `composer install --no-cache --prefer-dist --no-dev --no-autoloader --no-scripts`.
- Copier le code source ensuite.
- `composer dump-autoload --classmap-authoritative --no-dev`.
- `composer dump-env prod`.
- Exécuter en non-root quand possible (`USER www-data`).

## Gestion des caches en dev

- `var/cache/` et `var/log/` vivent dans le bind mount (visibles dans l'IDE).
- En cas de cache stale après un changement de branche ou de config : `rm -rf var/cache/*`.
- **Ne PAS utiliser de volume nommé** pour `var/cache/` en dev → risque de cache stale persistant.

### Dev — compose.yaml

```yaml
services:
  php:
    build:
      context: .
      target: php_dev
    volumes:
      - ./:/app
    environment:
      APP_ENV: dev
      XDEBUG_MODE: "off"

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
    volumes:
      - ./:/app:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php
```

### Prod — compose.yaml

```yaml
services:
  php:
    build:
      context: .
      target: php_prod
    volumes:
      # Volume nommé pour var/ en prod (persistance logs, sessions)
      - app_var:/app/var
    environment:
      APP_ENV: prod

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
    volumes:
      - app_public:/app/public:ro
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php

volumes:
  app_var:
  app_public:
```

### Récapitulatif caches par environnement

| Répertoire | Dev | Prod |
|---|---|---|
| `var/cache/` | Bind mount (visible IDE) | Dans l'image ou volume nommé |
| `var/log/` | Bind mount (visible IDE) | Volume nommé (persistant) |
| `vendor/` | Bind mount (via `./:/app`) | Dans l'image (COPY) |
| `node_modules/` | Anonymous volume | Dans l'image (COPY) |

## Nginx — Configuration FastCGI

- Le fichier de config Nginx doit être dans `docker/nginx/default.conf`.
- Proxy PHP via `fastcgi_pass php:9000` (nom du service compose).
- Servir les fichiers statiques (`/bundles/`, `/build/`, assets) directement depuis Nginx.
- `try_files $uri /index.php$is_args$args` pour le front controller Symfony.

## Commandes de référence

```makefile
# Dev : rebuild sans cache si problème
make rebuild:  ## docker compose build --no-cache php

# Dev : vider le cache Symfony
make cc:       ## rm -rf var/cache/*

# Prod : warmup cache dans le Dockerfile
# RUN php bin/console cache:warmup
```

## Anti-patterns à éviter
- Volume nommé pour `var/cache/` en dev → cache stale, nécessite rebuild.
- `docker compose down -v` pour vider le cache → détruit aussi la DB si volume partagé.
- Bind mount de `vendor/` en prod → lent, fragile, pas reproductible.
- `latest` comme tag d'image → non reproductible.
- Copier le code dans l'image dev → inutile avec le bind mount, ralentit le build.
