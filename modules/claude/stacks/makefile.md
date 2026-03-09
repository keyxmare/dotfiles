# Stack — Makefile

## Principes

- Chaque projet utilise `make` comme point d'entrée unique pour toutes les commandes.
- Un Makefile racine orchestre les sous-projets via `$(MAKE) -C`.
- Chaque application (backend, frontend) possède son propre Makefile autonome.
- Les Makefiles doivent être auto-documentés via une target `help`.
- Toutes les commandes applicatives s'exécutent via Docker (docker compose exec / run). Seules les commandes système (rm, cp, etc.) s'exécutent en local.

## Affichage

### Couleurs et formatage

Définir des variables de couleur pour un output lisible et cohérent :

```makefile
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[34m
COLOR_SUCCESS = \033[32m
COLOR_WARNING = \033[33m
COLOR_ERROR   = \033[31m
COLOR_COMMENT = \033[90m
COLOR_TITLE   = \033[1;36m
```

### Messages dans les targets

Utiliser des messages formatés pour donner du feedback à l'utilisateur :

```makefile
.PHONY: install
install: ## Installe les dépendances de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Installation des dépendances…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app install; \
	done
	@printf "$(COLOR_SUCCESS)✔ Installation terminée$(COLOR_RESET)\n"
```

Conventions d'affichage :
- `▶` pour le début d'une action
- `→` pour une sous-action
- `✔` pour un succès
- `✖` pour une erreur
- `⚠` pour un avertissement
- Toujours préfixer les commandes par `@` pour ne pas afficher la commande elle-même.
- Utiliser `--no-print-directory` sur les appels récursifs pour éviter le bruit.

### Target help

```makefile
.PHONY: help
help: ## Affiche cette aide
	@printf "$(COLOR_TITLE)Usage:$(COLOR_RESET)\n"
	@printf "  make $(COLOR_SUCCESS)<target>$(COLOR_RESET)\n\n"
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{ \
			if ($$0 ~ /^##[^#]/) { \
				printf "\n$(COLOR_TITLE)%s$(COLOR_RESET)\n", substr($$0, 4); \
			} else if ($$0 ~ /^##$$/) { \
				printf "\n"; \
			} else { \
				printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2; \
			} \
		}'
```

Résultat attendu :

```
Usage:
  make <target>

Projet
  install              Installe les dépendances de tous les sous-projets
  test                 Lance les tests de tous les sous-projets
  lint                 Lance les linters de tous les sous-projets
  clean                Nettoie les artefacts de build

Docker
  up                   Démarre les containers
  down                 Stoppe les containers
  build                Build les images Docker
  logs                 Affiche les logs des containers

Aide
  help                 Affiche cette aide
```

## Conventions

### Structure d'un Makefile racine

```makefile
.DEFAULT_GOAL := help

APPS          = backend frontend
COMPOSE_DIR   = docker
COMPOSE_FILES = -f $(COMPOSE_DIR)/compose.yaml $(if $(wildcard $(COMPOSE_DIR)/compose.override.yaml),-f $(COMPOSE_DIR)/compose.override.yaml)
DC            = docker compose $(COMPOSE_FILES)

COLOR_RESET   = \033[0m
COLOR_INFO    = \033[34m
COLOR_SUCCESS = \033[32m
COLOR_WARNING = \033[33m
COLOR_ERROR   = \033[31m
COLOR_COMMENT = \033[90m
COLOR_TITLE   = \033[1;36m

##
## Projet
## ------

.PHONY: install
install: ## Installe les dépendances de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Installation des dépendances…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app install || exit 1; \
	done
	@printf "$(COLOR_SUCCESS)✔ Installation terminée$(COLOR_RESET)\n"

.PHONY: test
test: ## Lance les tests de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Lancement des tests…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app test || exit 1; \
	done
	@printf "$(COLOR_SUCCESS)✔ Tests terminés$(COLOR_RESET)\n"

.PHONY: lint
lint: ## Lance les linters de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Lancement des linters…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app lint || exit 1; \
	done
	@printf "$(COLOR_SUCCESS)✔ Lint terminé$(COLOR_RESET)\n"

.PHONY: quality
quality: ## Lance tous les checks qualité de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Checks qualité…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app quality || exit 1; \
	done
	@printf "$(COLOR_SUCCESS)✔ Qualité OK$(COLOR_RESET)\n"

.PHONY: clean
clean: ## Nettoie les artefacts de build de tous les sous-projets
	@printf "$(COLOR_INFO)▶ Nettoyage…$(COLOR_RESET)\n"
	@for app in $(APPS); do \
		printf "$(COLOR_COMMENT)  → $$app$(COLOR_RESET)\n"; \
		$(MAKE) --no-print-directory -C $$app clean || exit 1; \
	done
	@printf "$(COLOR_SUCCESS)✔ Nettoyage terminé$(COLOR_RESET)\n"

##
## Docker
## ------

.PHONY: up
up: ## Démarre les containers
	@printf "$(COLOR_INFO)▶ Démarrage des containers…$(COLOR_RESET)\n"
	@$(DC) up -d
	@printf "$(COLOR_SUCCESS)✔ Containers démarrés$(COLOR_RESET)\n"

.PHONY: down
down: ## Stoppe les containers
	@printf "$(COLOR_INFO)▶ Arrêt des containers…$(COLOR_RESET)\n"
	@$(DC) down
	@printf "$(COLOR_SUCCESS)✔ Containers stoppés$(COLOR_RESET)\n"

.PHONY: build
build: ## Build les images Docker
	@printf "$(COLOR_INFO)▶ Build des images…$(COLOR_RESET)\n"
	@$(DC) build
	@printf "$(COLOR_SUCCESS)✔ Build terminé$(COLOR_RESET)\n"

.PHONY: restart
restart: ## Redémarre les containers
	@printf "$(COLOR_INFO)▶ Redémarrage des containers…$(COLOR_RESET)\n"
	@$(DC) restart
	@printf "$(COLOR_SUCCESS)✔ Containers redémarrés$(COLOR_RESET)\n"

.PHONY: status
status: ## Affiche l'état des containers
	@$(DC) ps

.PHONY: logs
logs: ## Affiche les logs des containers
	@$(DC) logs -f

##
## Aide
## ----

.PHONY: help
help: ## Affiche cette aide
	@printf "$(COLOR_TITLE)Usage:$(COLOR_RESET)\n"
	@printf "  make $(COLOR_SUCCESS)<target>$(COLOR_RESET)\n\n"
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{ \
			if ($$0 ~ /^##[^#]/) { \
				printf "\n$(COLOR_TITLE)%s$(COLOR_RESET)\n", substr($$0, 4); \
			} else if ($$0 ~ /^##$$/) { \
				printf "\n"; \
			} else { \
				printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2; \
			} \
		}'
```

### Règles obligatoires

- `.DEFAULT_GOAL := help` — la target par défaut affiche l'aide.
- Toutes les targets doivent être déclarées `.PHONY` sauf si elles produisent un fichier.
- Chaque target publique doit avoir un commentaire `##` pour apparaître dans le `help`.
- Utiliser `$(MAKE)` et jamais `make` directement pour les appels récursifs.
- Préfixer toutes les commandes par `@` et utiliser `--no-print-directory` sur les appels récursifs.
- Considérer `.ONESHELL` pour les targets avec des commandes multi-lignes partageant des variables shell. Sans `.ONESHELL`, chaque ligne s'exécute dans un shell séparé.

### Exécution via Docker

- Les commandes applicatives passent par `docker compose exec` ou `docker compose run --rm`.
- Définir des variables `EXEC_*` en haut du Makefile pour centraliser les appels Docker.
- Seules les commandes purement système (rm, cp, mkdir, etc.) s'exécutent directement sur la machine hôte.

#### `exec` vs `run --rm`

| Commande | Prérequis | Usage |
|---|---|---|
| `docker compose exec <service>` | Container déjà démarré (`up -d`) | Commandes interactives, dev quotidien (tests, lint, console) |
| `docker compose run --rm <service>` | Aucun | CI, scripts one-shot, quand les containers ne tournent pas |

- Préférer `exec` en développement (plus rapide, réutilise le container existant).
- Préférer `run --rm` en CI ou pour les tâches ponctuelles (container éphémère, pas de side effects).
- Toujours `--rm` avec `run` pour nettoyer le container après exécution.

### Variables

- Déclarer les variables configurables en haut du fichier.
- Utiliser `?=` pour les variables surchargeables par l'environnement.
- Utiliser `:=` pour les variables évaluées immédiatement.
- Grouper les variables par contexte (apps, docker, couleurs, paths, etc.).

### Organisation

- Grouper les targets par section avec des commentaires `##`.
- Ordonner les sections du plus utilisé au moins utilisé.
- Les targets internes (non publiques) sont préfixées par `_` et n'ont pas de commentaire `##`.

### Délégation aux sous-projets

- Le Makefile racine délègue via `$(MAKE) --no-print-directory -C <app> <target>`.
- Les commandes communes (install, test, lint, clean) itèrent sur la variable `APPS`.
- Chaque sous-projet peut être ciblé directement : `make -C backend test`.
- Les Makefiles des sous-projets sont autonomes et fonctionnent indépendamment.

### Conditionnel

- Utiliser `ifeq` / `ifdef` pour adapter le comportement (présence de Docker, CI, etc.).
- Ne pas dupliquer de logique entre Makefiles — extraire dans un fichier `.mk` inclus via `include` si nécessaire.
- Cas typique : le bloc `help` (grep/awk) et les variables de couleur sont identiques entre le Makefile racine et les sous-Makefiles. Les extraire dans un `make/common.mk` inclus par chaque Makefile via `include ../make/common.mk` (sous-projets) ou `include make/common.mk` (racine).

### Template `make/common.mk`

```makefile
# make/common.mk — Inclus par tous les Makefiles du projet

COLOR_RESET   = \033[0m
COLOR_INFO    = \033[34m
COLOR_SUCCESS = \033[32m
COLOR_WARNING = \033[33m
COLOR_ERROR   = \033[31m
COLOR_COMMENT = \033[90m
COLOR_TITLE   = \033[1;36m

COMPOSE_DIR   ?= $(or $(wildcard docker),$(wildcard ../docker))
COMPOSE_FILES  = -f $(COMPOSE_DIR)/compose.yaml $(if $(wildcard $(COMPOSE_DIR)/compose.override.yaml),-f $(COMPOSE_DIR)/compose.override.yaml)
DC             = docker compose $(COMPOSE_FILES)

.PHONY: help
help: ## Affiche cette aide
	@printf "$(COLOR_TITLE)Usage:$(COLOR_RESET)\n"
	@printf "  make $(COLOR_SUCCESS)<target>$(COLOR_RESET)\n\n"
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{ \
			if ($$0 ~ /^##[^#]/) { \
				printf "\n$(COLOR_TITLE)%s$(COLOR_RESET)\n", substr($$0, 4); \
			} else if ($$0 ~ /^##$$/) { \
				printf "\n"; \
			} else { \
				printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2; \
			} \
		}'
```

Chaque Makefile inclut ce fichier et n'a plus qu'à définir ses targets et sa variable `EXEC` :

```makefile
# backend/Makefile
.DEFAULT_GOAL := help
include ../make/common.mk

EXEC = $(DC) exec backend

# ... targets spécifiques
```

## Makefile d'une application

Chaque application (backend, frontend) suit la même structure avec les mêmes conventions d'affichage :

```makefile
.DEFAULT_GOAL := help

COMPOSE_DIR   ?= ../docker
COMPOSE_FILES  = -f $(COMPOSE_DIR)/compose.yaml $(if $(wildcard $(COMPOSE_DIR)/compose.override.yaml),-f $(COMPOSE_DIR)/compose.override.yaml)
DC             = docker compose $(COMPOSE_FILES)
EXEC           = $(DC) exec <service>

COLOR_RESET   = \033[0m
COLOR_INFO    = \033[34m
COLOR_SUCCESS = \033[32m
COLOR_COMMENT = \033[90m
COLOR_TITLE   = \033[1;36m

##
## Application
## -----------

.PHONY: install
install: ## Installe les dépendances
	@printf "$(COLOR_INFO)▶ Installation des dépendances…$(COLOR_RESET)\n"
	@$(EXEC) <commande d'install>
	@printf "$(COLOR_SUCCESS)✔ Dépendances installées$(COLOR_RESET)\n"

.PHONY: test
test: ## Lance les tests
	@printf "$(COLOR_INFO)▶ Lancement des tests…$(COLOR_RESET)\n"
	@$(EXEC) <commande de test>
	@printf "$(COLOR_SUCCESS)✔ Tests passés$(COLOR_RESET)\n"

.PHONY: lint
lint: ## Lance le linter
	@printf "$(COLOR_INFO)▶ Lancement du linter…$(COLOR_RESET)\n"
	@$(EXEC) <commande de lint>
	@printf "$(COLOR_SUCCESS)✔ Lint passé$(COLOR_RESET)\n"

.PHONY: clean
clean: ## Nettoie les artefacts de build
	@printf "$(COLOR_INFO)▶ Nettoyage…$(COLOR_RESET)\n"
	@rm -rf <dossiers de build>
	@printf "$(COLOR_SUCCESS)✔ Nettoyage terminé$(COLOR_RESET)\n"

##
## Aide
## ----

.PHONY: help
help: ## Affiche cette aide
	@printf "$(COLOR_TITLE)Usage:$(COLOR_RESET)\n"
	@printf "  make $(COLOR_SUCCESS)<target>$(COLOR_RESET)\n\n"
	@grep -E '(^[a-zA-Z_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{ \
			if ($$0 ~ /^##[^#]/) { \
				printf "\n$(COLOR_TITLE)%s$(COLOR_RESET)\n", substr($$0, 4); \
			} else if ($$0 ~ /^##$$/) { \
				printf "\n"; \
			} else { \
				printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2; \
			} \
		}'
```

Les recettes de chaque target sont définies par la stack technologique du sous-projet.
