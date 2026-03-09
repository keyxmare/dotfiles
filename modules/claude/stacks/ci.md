# Stack — CI/CD

## Principes

- Chaque PR déclenche un pipeline complet (lint, tests, build).
- Le merge sur `main` n'est possible que si le pipeline passe.
- Les pipelines doivent être rapides : paralléliser les jobs autant que possible.
- Ne pas écraser une configuration CI/CD déjà existante.
- Le provider est configurable. ← `ci.provider`

## Pipeline standard

### Sur PR (pull_request)

```
┌─────────┐   ┌─────────┐   ┌──────────────┐
│  Lint   │   │  Test   │   │   Security   │
│         │   │         │   │    Audit     │
└─────────┘   └─────────┘   └──────────────┘
     ↓              ↓               ↓
     └──────────────┼───────────────┘
                    ↓
              ┌─────────┐
              │  Build  │
              └─────────┘
                    ↓
              ┌─────────┐
              │  Status │
              │  Check  │
              └─────────┘
```

Stage 1 — en parallèle :
1. **Lint** — Linters et formatters de chaque application (backend + frontend).
2. **Test** — Tests unitaires, intégration, mutation testing.
3. **Security Audit** — Audit des dépendances (`composer audit`, `pnpm audit`).

Stage 2 — après lint + test + security :
4. **Build** — Vérification que l'application compile / build correctement (`needs: [lint, test, security]`).

### Sur merge main (push)

Même pipeline que PR + étapes supplémentaires :
1. **Deploy staging** — Déploiement automatique sur l'environnement de staging.
2. **E2E** — Tests end-to-end sur l'environnement de staging.
3. **Deploy prod** — Déploiement en production (manuel ou automatique selon la config). ← `ci.auto_deploy_prod`

## GitHub Actions

### Structure des workflows

```
.github/
├── workflows/
│   ├── ci.yml                 ← Pipeline principal (PR + push main)
│   ├── deploy.yml             ← Déploiement (reusable workflow)
│   └── security.yml           ← Audit de sécurité (schedule hebdomadaire)
└── PULL_REQUEST_TEMPLATE.md   ← Template PR (voir stacks/git.md)
```

### Bonnes pratiques

- Épingler les actions par SHA commit, pas par tag (`actions/checkout@<sha>`). Les `<sha>` dans les exemples ci-dessous sont des placeholders — les remplacer par le SHA réel de la version souhaitée (ex: `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` pour v4).
- Utiliser le cache pour les dépendances (`actions/cache` ou cache intégré du setup).
- Utiliser des reusable workflows pour éviter la duplication entre backend et frontend.
- Utiliser `matrix` pour tester sur plusieurs versions si nécessaire.
- Stocker les secrets dans GitHub Secrets, jamais en dur dans les workflows.
- Utiliser `secrets: inherit` pour les reusable workflows.
- Limiter les permissions avec `permissions:` au strict nécessaire.
- Utiliser `concurrency` pour annuler les pipelines obsolètes sur la même branche.
- Utiliser le cache de layers Docker (`docker/build-push-action` avec `cache-from`/`cache-to` sur le cache backend GitHub Actions) pour accélérer les builds entre runs.

### Stratégie d'exécution en CI

Les Makefiles des sous-projets utilisent `docker compose exec` pour exécuter les commandes. En CI, deux stratégies sont possibles :

#### Option A — Build et start des containers (recommandé pour la parité dev/CI)

Le workflow build les images Docker et démarre les services avant d'exécuter les commandes via les Makefiles existants. Garantit que la CI utilise le même environnement que le développement.

#### Option B — Exécution directe (plus rapide, moins fidèle)

Le workflow installe les runtimes directement sur le runner (setup-node, setup-php) et exécute les commandes sans Docker. Nécessite un Makefile CI dédié ou des variables `EXEC` surchargées.

La stratégie recommandée est l'option A. L'option B est acceptable pour les projets simples ou quand la vitesse est critique.

### Note sur compose.override.yaml

En CI, **ne jamais inclure** `compose.override.yaml` (bind mounts, ports de debug, variables de dev). Les workflows utilisent uniquement `-f docker/compose.yaml`. L'override est réservé au développement local.

### Exemple de workflow CI (option A — Docker)

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  prepare:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha>
      - name: Build Docker images
        run: docker compose -f docker/compose.yaml build
      - name: Save Docker images
        run: docker compose -f docker/compose.yaml config --images | xargs docker save -o /tmp/ci-images.tar
      - name: Upload images artifact
        uses: actions/upload-artifact@<sha>
        with:
          name: ci-images
          path: /tmp/ci-images.tar
          retention-days: 1

  lint:
    runs-on: ubuntu-latest
    needs: [prepare]
    steps:
      - uses: actions/checkout@<sha>
      - name: Download images
        uses: actions/download-artifact@<sha>
        with:
          name: ci-images
          path: /tmp
      - name: Load images
        run: docker load -i /tmp/ci-images.tar
      - name: Start containers
        run: docker compose -f docker/compose.yaml up -d
      - name: Lint backend
        run: make -C backend lint
      - name: Lint frontend
        run: make -C frontend lint

  test:
    runs-on: ubuntu-latest
    needs: [prepare]
    steps:
      - uses: actions/checkout@<sha>
      - name: Download images
        uses: actions/download-artifact@<sha>
        with:
          name: ci-images
          path: /tmp
      - name: Load images
        run: docker load -i /tmp/ci-images.tar
      - name: Start containers
        run: docker compose -f docker/compose.yaml up -d
      - name: Wait for services
        run: docker compose -f docker/compose.yaml exec backend php -v
      - name: Test backend
        run: make -C backend test
      - name: Test frontend
        run: make -C frontend test
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@<sha>
        with:
          name: test-results
          path: |
            backend/var/log/
            frontend/coverage/
          retention-days: 7

  security:
    runs-on: ubuntu-latest
    needs: [prepare]
    steps:
      - uses: actions/checkout@<sha>
      - name: Download images
        uses: actions/download-artifact@<sha>
        with:
          name: ci-images
          path: /tmp
      - name: Load images
        run: docker load -i /tmp/ci-images.tar
      - name: Start containers
        run: docker compose -f docker/compose.yaml up -d
      - name: Audit backend
        run: make -C backend audit
      - name: Audit frontend
        run: make -C frontend audit

  build:
    runs-on: ubuntu-latest
    needs: [lint, test, security]
    steps:
      - uses: actions/checkout@<sha>
      - name: Build production images
        run: docker compose -f docker/compose.yaml -f docker/compose.prod.yaml build
```

## GitLab CI

Si `ci.provider` = `gitlab`, utiliser `.gitlab-ci.yml` avec la même logique de stages :

```yaml
stages:
  - lint
  - test
  - build
  - security
  - deploy
```

Les mêmes principes s'appliquent : parallélisation, cache, secrets via CI/CD variables.
