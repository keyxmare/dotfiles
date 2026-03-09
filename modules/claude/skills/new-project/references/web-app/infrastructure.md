# Référence — App web : Infrastructure

## Structure monorepo

Lire et suivre `~/.claude/stacks/project-structure.md`.

```
<project>/
├── README.md
├── CONTRIBUTING.md
├── .gitignore
├── .editorconfig
├── .env.example
├── Makefile
├── scaffold.config.json
├── backend/               ← si backend sélectionné
├── frontend/              ← si frontend sélectionné
├── docker/                ← configuration Docker
├── .devcontainer/         ← configuration DevContainer
├── docs/                  ← si doc.enabled
└── .github/ ou .gitlab/   ← selon ci.provider
```

---

## DevContainer

Générer `.devcontainer/devcontainer.json` adapté à la stack :

```json
{
  "name": "<project-name>",
  "dockerComposeFile": ["../docker/compose.yaml", "../docker/compose.override.yaml"],
  "service": "<service principal : backend si présent, sinon frontend>",
  "workspaceFolder": "/app",
  "postCreateCommand": "make install",
  "customizations": {
    "vscode": {
      "extensions": []
    }
  }
}
```

Extensions selon la stack (n'inclure que celles pertinentes) :
- Backend PHP : `bmewburn.vscode-intelephense-client`, `xdebug.php-debug`
- Frontend Vue/Nuxt : `vue.volar`, `dbaeumer.vscode-eslint`, `esbenp.prettier-vscode`
- Docker : `ms-azuretools.vscode-docker`
- Base de données : `cweijan.vscode-database-client2`

---

## CORS

Si le projet a un frontend ET un backend (ports différents en dev), configurer CORS :

- `nelmio/cors-bundle` dans `composer.json`.
- `config/packages/nelmio_cors.yaml` :

```yaml
nelmio_cors:
    defaults:
        origin_regex: true
        allow_origin: ['%env(CORS_ALLOW_ORIGIN)%']
        allow_methods: ['GET', 'OPTIONS', 'POST', 'PUT', 'DELETE']
        allow_headers: ['Content-Type', 'Authorization']
        max_age: 3600
    paths:
        '^/api/': ~
```

- Variable `.env.example` : `CORS_ALLOW_ORIGIN='^https?://(localhost|127\.0\.0\.1)(:[0-9]+)?$'`.
- En production, restreindre `CORS_ALLOW_ORIGIN` au domaine réel.

### CORS en production

En production, restreindre strictement `CORS_ALLOW_ORIGIN` au domaine réel :

```bash
# .env.prod (ou variable d'environnement CI/CD)
CORS_ALLOW_ORIGIN='^https://mon-domaine\.com$'
```

Ne jamais utiliser de wildcard (`*`) ou de regex permissif en production. Si plusieurs domaines doivent être autorisés, les lister explicitement dans la regex :

```bash
CORS_ALLOW_ORIGIN='^https://(app\.mon-domaine\.com|admin\.mon-domaine\.com)$'
```

---

## API Versioning

Configurer selon `api.versioning` dans CONFIG.md.

### Path versioning (`api.versioning: path`) — défaut

Routes préfixées par la version :

- Controllers dans `Infrastructure/Controller/V1/` (ou `Controller/` sans sous-dossier en v1 initiale).
- Routes : `/api/v1/{context}/{entities}`.
- Quand une v2 est nécessaire : dupliquer le controller dans `V2/`, adapter, conserver la v1.

### Header versioning (`api.versioning: header`)

Version dans le header `Accept` :

- Header : `Accept: application/vnd.<project>.v1+json`.
- Un seul jeu de controllers. La version est extraite par un `EventSubscriber` qui set un attribut de requête.
- Le controller lit `$request->attributes->get('api_version')` si besoin de brancher.

### Scaffold initial

Pour la v1, ne pas créer de sous-dossier `V1/` — les controllers restent à plat. L'infrastructure de versioning est préparée (config, subscriber si header) mais ne complexifie pas la structure initiale.

---

## Gestion des fichiers d'environnement

Standardiser les fichiers `.env` pour éviter les confusions :

| Fichier | Rôle | Versionné |
|---|---|---|
| `backend/.env` | Valeurs par défaut Symfony (APP_ENV, APP_SECRET, DATABASE_URL) | Oui |
| `backend/.env.local` | Surcharges locales du développeur | Non (gitignored) |
| `backend/.env.test` | Config pour PHPUnit (APP_ENV=test, DATABASE_URL test) | Oui |
| `docker/.env` | Variables Docker Compose (ports, versions d'images) | Non (gitignored) |
| `docker/.env.example` | Template pour `docker/.env` — valeurs par défaut | Oui |

Règles :
- **Jamais de vrais secrets** dans les fichiers versionnés — uniquement des placeholders (`changeme`, `your-secret-here`).
- `.env.local` et `docker/.env` dans `.gitignore`.
- `docker/.env.example` copié en `docker/.env` par `make install`.
- Les variables sensibles en production sont injectées par le CI/CD (secrets GitHub/GitLab).

---

## API Documentation UI

Si `doc.openapi` = `true` et backend présent, exposer une interface de consultation de l'API en développement.

### Option recommandée — Scalar

```yaml
# config/packages/scalar.yaml (dev only)
# Pas de bundle Symfony — simple route statique
```

Créer un controller `ApiDocController` (dev only) :
- Route : `GET /api/docs`
- Sert une page HTML avec le CDN Scalar qui pointe vers `/api/docs/openapi.yaml`.
- Route `GET /api/docs/openapi.yaml` qui sert le fichier `docs/api/openapi.yaml`.
- Enregistrer le controller uniquement dans `config/routes/dev/api_doc.yaml`.

### Alternative — NelmioApiDocBundle

Si préféré, `nelmio/api-doc-bundle` peut auto-générer l'OpenAPI depuis les routes et attributs PHP. Mais cela couple la doc au code — préférer Scalar + OpenAPI versionné pour garder le contrôle.

---

## Docker

Lire et suivre `~/.claude/stacks/docker.md`.

```
docker/
├── compose.yaml               ← configuration principale
├── compose.override.yaml      ← surcharges dev (auto-chargé)
├── compose.prod.yaml          ← surcharges production
├── .env.example               ← template versionné
├── backend/Dockerfile         ← si backend
├── frontend/Dockerfile        ← si frontend
└── .dockerignore
```

- **compose.yaml** — Services nommés, `depends_on` avec healthchecks, named volumes.
- **compose.override.yaml** — Bind mounts hot-reload, ports debug, install deps avant démarrage.
- **compose.prod.yaml** — Pas de volumes source, `restart: unless-stopped`, limites ressources.
- **Dockerfiles** — Multi-stage (dev/build/prod), utilisateur non-root, layer caching optimisé, versions épinglées. Backend : `php:8.4-fpm-alpine`. Frontend : `node:22-alpine`. BDD : `postgres:17-alpine` ou `mysql:8.4`.
- **.dockerignore** — Exclut `.git`, `.env`, `node_modules`, `vendor`, `var`, `tests`, `docs`.

---

## Makefile racine

Lire et suivre `~/.claude/stacks/makefile.md` :
- `.DEFAULT_GOAL := help`
- Variables `APPS` avec les applications sélectionnées.
- Targets : `install`, `test`, `lint`, `clean`, `up`, `down`, `build`, `logs`, `doctor`, `outdated`, `help`.
- Délégation aux sous-projets via `$(MAKE) -C`.

Target `outdated` (racine) :

```makefile
.PHONY: outdated
outdated: ## Vérifie les dépendances obsolètes
	@for app in $(APPS); do \
		echo "── $$app ──"; \
		$(MAKE) -C $$app outdated; \
	done
```

Target `doctor` :

```makefile
.PHONY: doctor
doctor: ## Vérifie que tous les prérequis sont installés
	@echo "Vérification des prérequis..."
	@command -v docker >/dev/null 2>&1 || { echo "Docker non installé"; exit 1; }
	@docker compose version >/dev/null 2>&1 || { echo "Docker Compose non disponible"; exit 1; }
	@command -v make >/dev/null 2>&1 || { echo "Make non installé"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "Git non installé"; exit 1; }
	@echo "Tous les prérequis sont installés"
```
