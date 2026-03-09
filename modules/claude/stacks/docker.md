# Stack — Docker

## Structure du dossier

```
docker/
├── compose.yaml               ← Configuration principale des services
├── compose.override.yaml      ← Surcharges pour le développement (auto-chargé)
├── compose.prod.yaml          ← Surcharges pour la production
├── .env                       ← Variables d'environnement par défaut
├── .env.example               ← Template des variables d'environnement (versionné)
├── backend/
│   └── Dockerfile             ← Dockerfile du backend
├── frontend/
│   └── Dockerfile             ← Dockerfile du frontend
└── ...                        ← Autres services si nécessaire (nginx, worker, etc.)
```

## Dockerfile — Bonnes pratiques

### Multi-stage builds

Toujours utiliser des multi-stage builds pour séparer les dépendances de build et de runtime :

- **Stage dev** — Image de développement avec les outils nécessaires. Le `CMD` doit inclure l'installation des dépendances avant le démarrage (`sh -c "composer install && php -S ..."` ou `sh -c "pnpm install && pnpm dev"`), car les bind mounts en dev écrasent les layers du build.
- **Stage build** — Installe les dépendances, compile, génère les assets.
- **Stage production** — Image minimale, ne contient que les artefacts nécessaires.

### Utilisateur non-root

- Utiliser un utilisateur non-root pour l'exécution.
- Sur `node:*-alpine` : utiliser le user `node` déjà présent (UID 1000). Ne pas créer un user `appuser` qui entre en conflit.
- Sur `php:*-alpine` : créer un user `appuser` (pas de user applicatif par défaut).

### Layer caching

Optimiser le cache des layers en ordonnant les instructions du moins fréquemment modifié au plus fréquemment modifié :

1. Image de base (`FROM`)
2. Installation des dépendances système
3. Copie des fichiers de dépendances (package.json, composer.json, etc.)
4. Installation des dépendances applicatives
5. Copie du code source
6. Build

Utiliser `--mount=type=cache` pour les caches de package managers (npm, composer, pip, etc.).

### Sécurité

- Toujours exécuter le process applicatif avec un utilisateur non-root (`USER`).
- Ne jamais passer de secrets via `ARG` ou `ENV` — utiliser `--mount=type=secret` pour les secrets de build.
- Utiliser des images de base Alpine ou distroless pour réduire la surface d'attaque.
- Toujours inclure un `.dockerignore` pour exclure les fichiers inutiles (voir template ci-dessous).
- Épingler les versions des images de base (pas de `latest`).

### Template `.dockerignore`

```dockerignore
.git
.github
.claude
node_modules
vendor
*.md
!README.md
docker/
docs/
tests/
coverage/
.env
.env.*
!.env.example
.idea/
.vscode/
.DS_Store
```
- → Voir [security.md](./security.md#secrets) pour les règles complètes de gestion des secrets.

### Optimisation

- Utiliser `COPY --chown` plutôt que `COPY` + `RUN chown` pour éviter une layer supplémentaire.
- Combiner les `RUN` quand c'est pertinent pour réduire le nombre de layers.
- Nettoyer les caches dans le même `RUN` que l'installation (`apt-get clean`, `rm -rf /var/lib/apt/lists/*`).
- Exposer uniquement les ports nécessaires avec `EXPOSE`.
- Préférer `ENTRYPOINT` + `CMD` pour une exécution configurable.

## Compose — Bonnes pratiques

> Toujours utiliser `docker compose` (Compose V2). L'ancienne commande `docker-compose` (V1, avec tiret) est dépréciée depuis juillet 2023.

### Services

- Nommer les services de manière explicite et cohérente (ex: `backend`, `frontend`, `db`, `redis`, `worker`).
- Toujours définir `depends_on` avec des conditions de santé quand c'est possible.
- Toujours définir des `healthcheck` pour les services critiques. Exemples :

```yaml
services:
  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER"]
      interval: 5s
      timeout: 3s
      retries: 5
  backend:
    healthcheck:
      test: ["CMD-SHELL", "php-fpm-healthcheck || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 3
    depends_on:
      db:
        condition: service_healthy
  redis:
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5
```
- Utiliser `restart: unless-stopped` en production.

### Environnements

- `compose.yaml` — Configuration de base, commune à tous les environnements.
- `compose.override.yaml` — Surcharges développement (auto-chargé par Docker Compose). Volumes pour le hot-reload, ports de debug, variables de debug.
- `compose.prod.yaml` — Surcharges production (`docker compose -f compose.yaml -f compose.prod.yaml up`). Pas de volumes de code source, restart policies, limites de ressources.

### Volumes

- Utiliser des named volumes pour les données persistantes (base de données, cache, etc.).
- Utiliser des bind mounts uniquement en développement pour le hot-reload du code source.
- Ne jamais monter le code source en production.
- Les bind mounts en dev provoquent la création de fichiers locaux par les containers (`.pnpm-store/`, `node_modules/`, `vendor/`, `var/`). S'assurer que le `.gitignore` les exclut tous.

### Utilisateur non-root en dev (bind mounts)

Les stages `dev` des Dockerfiles ne définissent pas de `USER` car le user du container doit correspondre au UID/GID de l'hôte pour éviter les problèmes de permissions sur les bind mounts. Configurer le user dans `compose.override.yaml` :

```yaml
services:
  backend:
    user: "${UID:-1000}:${GID:-1000}"
  frontend:
    user: "${UID:-1000}:${GID:-1000}"
```

Sur macOS, les UID sont typiquement `501`. Ajouter `UID=501` et `GID=20` dans le fichier `docker/.env`.

### Profiles

- Utiliser les [profiles](https://docs.docker.com/compose/how-tos/profiles/) Compose pour les services optionnels (mailcatcher, adminer, phpmyadmin, swagger-ui, etc.).
- Un service avec `profiles: [debug]` ne démarre pas par défaut — uniquement via `docker compose --profile debug up`.
- Garder les services indispensables (backend, frontend, db, redis) sans profile.

### Networks

- Isoler les services dans des networks dédiés quand le projet comporte plusieurs domaines.
- Le network par défaut du projet suffit pour les projets simples.

### Variables d'environnement

- Utiliser un fichier `.env` pour les valeurs par défaut.
- Préférer `environment` dans le compose pour les valeurs non sensibles.
- Utiliser `secrets` pour les données sensibles en production.
- **Fail fast** — Valider les variables d'environnement requises au démarrage de l'application. Si une variable critique est manquante ou invalide, l'application doit refuser de démarrer avec un message d'erreur explicite (pas une erreur runtime tardive).
  - **Symfony** : valider dans le Kernel ou un CompilerPass. Les paramètres container (`%env(VAR)%`) lèvent une exception au boot si la var est manquante.
  - **Nuxt/Node** : valider dans un plugin serveur ou au point d'entrée avec un schéma (zod, env-var, etc.).
- → Voir [security.md](./security.md#secrets) pour les règles de gestion des secrets et fichiers `.env`.

### Ressources

- Définir des limites de mémoire et CPU en production (`deploy.resources.limits`).
- Définir des réservations pour garantir les ressources minimales (`deploy.resources.reservations`).

## Squelettes Dockerfile

### Dockerfile PHP (Symfony)

Stage **dev** : image complète avec Composer, CMD qui installe les deps puis lance php-fpm (bind mount friendly).
Stage **prod** : deps de prod uniquement, cache Composer monté, user non-root `appuser`, code copié en dernier pour maximiser le cache des layers.

```dockerfile
FROM php:8.4-fpm-alpine AS base

RUN apk add --no-cache icu-libs libzip libpng \
    && docker-php-ext-install intl opcache zip gd

WORKDIR /app

FROM base AS dev

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN apk add --no-cache linux-headers $PHPIZE_DEPS \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

EXPOSE 9000

CMD sh -c "composer install && php-fpm"

FROM base AS prod

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./

RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-dev --no-scripts --prefer-dist

COPY --chown=appuser:appgroup . .

RUN composer dump-autoload --optimize --classmap-authoritative

USER appuser

EXPOSE 9000

CMD ["php-fpm"]
```

### Dockerfile Node (Frontend)

Stage **dev** : pnpm install + serveur de dev (bind mount friendly).
Stage **build** : lockfile gelé, build de production avec cache pnpm.
Stage **prod** : nginx pour servir le build statique, user non-root `node` non applicable sur nginx — on utilise la config par défaut nginx sans root.

```dockerfile
FROM node:22-alpine AS base

WORKDIR /app

COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack install

FROM base AS dev

EXPOSE 5173

CMD sh -c "pnpm install && pnpm dev --host 0.0.0.0"

FROM base AS build

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

COPY . .

RUN pnpm build

FROM nginx:alpine AS prod

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

Pour du SSR (Nuxt, Next), remplacer le stage **prod** par `node:22-alpine`, copier le build output, et exécuter avec `USER node` :

```dockerfile
FROM node:22-alpine AS prod

WORKDIR /app

COPY --from=build --chown=node:node /app/.output ./.output

USER node

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
```
