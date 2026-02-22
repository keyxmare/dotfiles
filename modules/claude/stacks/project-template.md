# Template de projet

## Initialisation
Quand un nouveau projet est créé ou quand les fichiers de suivi manquent, proposer de créer la structure suivante à la racine :

### Fichiers à créer

#### CLAUDE.md (local au projet)
```markdown
# Nom du Projet

## Stacks
Lire les stacks suivantes :
- ~/.claude/stacks/symfony.md
- ~/.claude/stacks/ddd.md
- ~/.claude/stacks/docker.md
- ~/.claude/stacks/vuejs.md
- ~/.claude/stacks/git.md
- ~/.claude/stacks/testing.md
- ~/.claude/stacks/security.md
- ~/.claude/stacks/api-platform.md

## Contexte projet
- Description : [à compléter]
- Bounded Contexts : [à compléter]

## Spécificités
[Toute convention ou règle propre à ce projet]
```

#### MEMORY.md
```markdown
# Mémoire du projet

## Architecture
[Décisions architecturales, fichiers clés]

## Contexte métier
[Bounded Contexts identifiés, règles métier importantes]

## Notes
[Bugs résolus, points d'attention]
```

#### FEATURES.md
```markdown
# Features

## [Bounded Context]

| Feature | Description | Statut |
|---------|-------------|--------|
| | | planned / in progress / done |
```

#### TASKS.md
```markdown
# Tâches

## En cours

## À faire

## Archive
```

#### Makefile
```makefile
.PHONY: help install start stop sh test phpstan cs cs-fix migration migrate cache

DOCKER_COMPOSE = docker compose
PHP_CONTAINER  = php
EXEC_PHP       = $(DOCKER_COMPOSE) exec $(PHP_CONTAINER)
CONSOLE        = $(EXEC_PHP) php bin/console
COMPOSER       = $(EXEC_PHP) composer

help: ## Affiche cette aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Installer les dépendances
	$(COMPOSER) install
	npm install

start: ## Démarrer Docker Compose
	$(DOCKER_COMPOSE) up -d

stop: ## Arrêter Docker Compose
	$(DOCKER_COMPOSE) down

sh: ## Shell dans le container PHP
	$(EXEC_PHP) sh

test: ## Lancer les tests
	$(EXEC_PHP) ./vendor/bin/phpunit

phpstan: ## Lancer PHPStan
	$(EXEC_PHP) ./vendor/bin/phpstan analyse

cs: ## Vérifier le code style
	$(EXEC_PHP) ./vendor/bin/php-cs-fixer fix --dry-run --diff

cs-fix: ## Corriger le code style
	$(EXEC_PHP) ./vendor/bin/php-cs-fixer fix

migration: ## Générer une migration Doctrine
	$(CONSOLE) doctrine:migrations:diff

migrate: ## Exécuter les migrations
	$(CONSOLE) doctrine:migrations:migrate --no-interaction

cache: ## Vider le cache
	$(CONSOLE) cache:clear
```

## Règles
- Adapter les noms de containers Docker au projet.
- Adapter les stacks référencées dans le CLAUDE.md local selon le projet.
- Ne pas créer ces fichiers si ils existent déjà. Proposer de les compléter.
