---
name: config-archeologist
description: Analyser les fichiers de configuration Symfony (services.yaml, routes.yaml, configs de bundles) et produire un rapport lisible de ce qui est configuré, déprécié, en doublon, ou incohérent. Utiliser quand l'utilisateur demande un audit de config, veut comprendre sa configuration, cherche des doublons, ou veut nettoyer ses fichiers YAML/XML.
argument-hint: [scope] [--bc=<name>] [--type=all|services|routes|bundles|parameters|env] [--output=report|json] [--summary] [--resume] [--full]
---

# Config Archeologist — Symfony

Tu es un expert en configuration Symfony. Tu fouilles les fichiers de configuration d'un projet Symfony/DDD pour cartographier tout ce qui est déclaré, détecter les dépréciations, les doublons, les incohérences et les configurations mortes. Tu produis un rapport archéologique clair et actionnable.

## Arguments

- `$ARGUMENTS` : scope optionnel (fichier ou dossier de config spécifique). Si vide, analyser tout `config/`.
- `--type=<type>` : filtrer la catégorie de configuration à analyser :
  - `all` (défaut) : toutes les catégories
  - `services` : services.yaml et déclarations de services
  - `routes` : routes.yaml et fichiers de routing
  - `bundles` : configuration des bundles (config/packages/)
  - `parameters` : paramètres globaux et bindings
  - `env` : variables d'environnement et .env
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (métriques clés + top 5 anomalies) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

1. **Appliquer `skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Stacks spécifiques : `ddd.md`, `symfony.md`, `env.md`, `security.md`
3. Identifier l'environnement du projet :
   - Lire `composer.json` pour la version de Symfony et les bundles installés.
   - Lister `config/` récursivement pour cartographier tous les fichiers de configuration.
   - Lister `config/packages/` pour identifier les bundles configurés.
   - Vérifier `.env`, `.env.local`, `.env.test` pour les variables d'environnement.
   - Identifier la structure `src/` (Bounded Contexts, Bundles internes).
   - Lire `config/bundles.php` pour les bundles enregistrés.
4. **Consulter les références** : lire `references/config-patterns.md` pour les commandes de scan et les patterns de détection.

## Prérequis recommandés

| Skill | Pourquoi avant config-archeologist |
|-------|-----------------------------------|
| `/full-audit` | Avoir le score global pour contextualiser les anomalies de configuration |

Exploitation cross-skill : voir `skill-directives.md`.

## Phase 1 — Inventaire exhaustif des configurations

> Voir `references/config-patterns.md` pour les commandes de scan detaillees et les patterns de detection par categorie.

Avant toute analyse, construire un **inventaire complet** de tout ce qui est configuré. L'inventaire est la base : on ne peut détecter les anomalies que si on connaît tout ce qui existe.

### 1.1 Inventaire des fichiers de configuration

Scanner et classifier chaque fichier dans `config/` :

| Type | Fichiers attendus |
|------|-------------------|
| Services | `config/services.yaml`, `config/services/*.yaml`, `config/services_*.yaml` |
| Routes | `config/routes.yaml`, `config/routes/*.yaml`, `config/routes_*.yaml` |
| Bundles | `config/packages/*.yaml`, `config/packages/<env>/*.yaml` |
| Parameters | Sections `parameters:` dans services.yaml et imports |
| Preload | `config/preload.php` |
| Bundles registry | `config/bundles.php` |

Pour chaque fichier, enregistrer :
- Chemin
- Type (services, routes, bundle config, parameters)
- Format (YAML, XML, PHP)
- Taille (lignes)
- Dernière modification estimée (si disponible via git)
- Environnement ciblé (all, dev, test, prod) déduit du chemin ou des `when@` blocks

### 1.2 Inventaire des déclarations de services

Dans `services.yaml` et fichiers importés, inventorier :

**Blocs autodiscovery :**
- Namespace de base (ex: `App\`)
- Chemin `resource` (ex: `../src/`)
- Exclusions `exclude` (et vérifier qu'elles correspondent à des chemins existants)

**Services explicites :**
- Service ID (FQCN ou alias)
- Classe (`class:`)
- Arguments injectés (`arguments:`)
- Tags ajoutés (`tags:`)
- Calls (`calls:`)
- Factories (`factory:`)
- Decorators (`decorates:`)
- Public/private
- Lazy
- Shared
- Autowire on/off
- Autoconfigure on/off

**Alias :**
- ID de l'alias
- Service cible
- Public/private

**Bindings globaux :**
- Variables bindées (`$variableName: '@service_id'` ou `$variableName: '%parameter%'`)
- Bindings typés (`Interface\Class: '@service_id'`)

**Imports :**
- Fichiers importés (`imports:` ou `resource:`)
- Chaîne de résolution des imports (un import peut importer un autre fichier)

### 1.3 Inventaire du routing

**Routes YAML :**
- Nom de la route
- Chemin (`path:`)
- Controller et action (`controller:`)
- Méthodes HTTP (`methods:`)
- Conditions (`condition:`)
- Requirements (`requirements:`)
- Defaults (`defaults:`)
- Host / scheme

**Imports de routes :**
- Resources importées (`resource:`)
- Préfixes appliqués (`prefix:`)
- Name prefix (`name_prefix:`)
- Type d'import (`type: attribute` pour les routes par attributs)

**Routes par attributs (cross-reference) :**
- Lister les `#[Route]` déclarés dans les controllers PHP
- Vérifier la cohérence avec les imports YAML (ex: un namespace de controllers est-il bien importé dans routes.yaml ?)

### 1.4 Inventaire de la configuration Scheduler (Symfony 7+)

Si `symfony/scheduler` est installé :

- Fichiers `config/packages/scheduler.yaml`
- Classes avec `#[AsSchedule]`
- Providers implémentant `ScheduleProviderInterface`
- Messages planifiés (`RecurringMessage::every()`, `RecurringMessage::cron()`)
- Vérifier la cohérence : un message planifié a-t-il un handler Messenger correspondant ?

### 1.5 Inventaire de la configuration AssetMapper (Symfony 7+)

Si `symfony/asset-mapper` est installé :

- Fichier `config/packages/asset_mapper.yaml`
- `importmap.php` à la racine du projet
- Paths configurés (`framework.asset_mapper.paths`)
- Vérifier si Webpack Encore est **aussi** installé (doublon potentiel)
- Vérifier la cohérence entre `importmap.php` et les assets réels dans `assets/`

### 1.6 Inventaire des configurations de bundles

Pour chaque fichier dans `config/packages/` :

- Bundle concerné
- Version du bundle installée (via `composer.json` / `composer.lock`)
- Clé racine de configuration
- Options configurées vs options par défaut
- Blocs `when@dev`, `when@test`, `when@prod` (configurations par environnement)

**Bundles courants à analyser en profondeur :**

| Bundle | Fichier config | Points d'attention |
|--------|---------------|-------------------|
| Doctrine ORM | `doctrine.yaml` | Mappings, types custom, DQL functions, proxies, cache |
| Doctrine Migrations | `doctrine_migrations.yaml` | Namespace migrations, storage, transactional |
| Security | `security.yaml` | Firewalls, providers, access control, authenticators |
| Twig | `twig.yaml` | Paths, globals, form themes |
| Framework | `framework.yaml` | Secret, session, CSRF, validation, serializer |
| Messenger | `messenger.yaml` | Transports, routing, buses, retry strategy, failure transport |
| Monolog | `monolog.yaml` | Handlers, channels, per-env config |
| API Platform | `api_platform.yaml` | Formats, pagination, docs, defaults |
| Cache | `cache.yaml` | Pools, adapters, Redis DSN |
| Mailer | `mailer.yaml` | DSN, envelope |
| Notifier | `notifier.yaml` | Channels, admin recipients |

### 1.7 Inventaire des paramètres

- Paramètres déclarés dans `parameters:` (services.yaml et fichiers importés)
- Paramètres référencés par `%parameter_name%` dans la config
- Variables d'environnement utilisées via `'%env(VAR_NAME)%'` et variantes (`env(resolve:)`, `env(file:)`, `env(json:)`, etc.)
- Paramètres de container (`kernel.project_dir`, `kernel.environment`, etc.)

### 1.8 Inventaire des variables d'environnement

- Variables dans `.env` (valeurs par défaut)
- Variables dans `.env.local` (overrides locaux)
- Variables dans `.env.test` (overrides de test)
- Variables dans `.env.prod` si existant
- Variables référencées dans la config Symfony (`%env(...)%`)
- Variables dans `docker-compose.yml` / `docker-compose.override.yml`
- Variables dans les Dockerfiles

## Phase 2 — Analyse des anomalies

### 2.1 Doublons

**Doublons de services :**
- Un service déclaré explicitement ET couvert par l'autodiscovery → doublon (la déclaration explicite override silencieusement).
- Un alias qui pointe vers un service qui est lui-même un alias → chaîne d'alias.
- Même FQCN déclaré dans deux fichiers de services différents → conflit.
- Un `bind` global et un argument explicite sur le même service → le bind est ignoré silencieusement.

**Doublons de routes :**
- Deux routes avec le même `name` → la seconde écrase la première silencieusement.
- Deux routes avec le même `path` + mêmes `methods` → conflit potentiel.
- Route YAML qui déclare un path déjà couvert par un attribut `#[Route]` sur le controller → doublon.

**Doublons de paramètres :**
- Même paramètre déclaré dans deux fichiers → le dernier chargé gagne.
- Variable d'environnement déclarée dans `.env` et jamais référencée dans la config → orpheline.
- Variable d'environnement référencée dans la config mais absente de `.env` → erreur potentielle au runtime.

**Doublons de configuration de bundles :**
- Même clé configurée à la fois dans le fichier principal et dans un bloc `when@<env>` avec la même valeur → redondant.
- Configuration identique dans `config/packages/dev/` et `config/packages/test/` → factoriser.

### 2.2 Dépréciations

**Syntaxe YAML dépréciée :**
- `_defaults: { public: true }` → en Symfony 4+, les services sont privés par défaut, `public: true` sur `_defaults` est un anti-pattern.
- `arguments: ['@service_id']` avec le `@` inline au lieu de `'@service_id'` → valide mais style ancien.
- Clé `controller:` dans les routes YAML au lieu du format `App\Controller\Class::method`.
- Pattern `resource: '../src/*'` trop large (devrait exclure les couches non-service).

**Bundles / packages dépréciés :**
- Comparer les bundles dans `config/bundles.php` avec les packages dans `composer.json`.
- Signaler les bundles connus comme dépréciés :
  - `sensio/framework-extra-bundle` → attributs natifs Symfony 6.2+
  - `symfony/swiftmailer-bundle` → remplacé par `symfony/mailer`
  - `nelmio/alice` anciennes versions
  - `fos/rest-bundle` si API Platform est installé
  - `jms/serializer-bundle` si le Serializer Symfony est utilisé
  - `stof/doctrine-extensions-bundle` → vérifier si les features utilisées sont dans Doctrine natif

**Configurations dépréciées de Symfony :**
- Vérifier les clés de configuration selon la version de Symfony installée.
- Options renommées entre versions majeures (ex: `framework.router.utf8` → par défaut en Symfony 6+).
- Options supprimées (ex: `framework.templating` supprimé en Symfony 6).

**Configurations dépréciées de Doctrine :**
- `auto_mapping: true` sans spécifier les mappings explicitement.
- `type: annotation` → déprécié en faveur de `type: attribute` (Doctrine 3+).
- `naming_strategy: doctrine.orm.naming_strategy.underscore` → `doctrine.orm.naming_strategy.underscore_number_aware` en Doctrine 2.13+.

### 2.3 Incohérences

**Incohérences services vs code :**
- Service déclaré avec `class: App\Foo\Bar` mais la classe n'existe pas → erreur au build du container.
- Tag ajouté à un service qui n'implémente pas l'interface requise (ex: `kernel.event_subscriber` sans `EventSubscriberInterface`).
- Argument injecté avec un type qui ne correspond pas au type-hint du constructeur.
- Exclusion dans l'autodiscovery qui cible un chemin qui n'existe pas (mort silencieuse).
- Exclusion manquante : des classes non-service (Entity, VO, Event, DTO) sont dans le scope de l'autodiscovery sans exclusion.

**Incohérences routes vs controllers :**
- Route YAML qui référence un controller::action inexistant.
- Import de routes `resource` pointant vers un namespace qui n'existe pas.
- Préfixe de route inconsistant entre YAML et attributs.

**Incohérences config vs bundles installés :**
- Fichier de config dans `config/packages/` pour un bundle non installé dans `composer.json` → config morte.
- Bundle installé dans `composer.json` mais non enregistré dans `bundles.php` → bundle installé mais inactif.
- Bundle enregistré dans `bundles.php` mais pas de config dans `config/packages/` → utilise les valeurs par défaut (OK mais à documenter).

**Incohérences environnements :**
- Variable `%env(DATABASE_URL)%` utilisée mais `DATABASE_URL` absent de `.env`.
- Configuration `when@prod` qui référence un service qui n'existe qu'en dev (ex: profiler).
- Monolog handler qui écrit dans un chemin qui n'existe pas en prod.

### 2.4 Configuration morte

**Services configurés mais jamais utilisés :**
- Alias déclaré mais jamais injecté nulle part.
- Binding déclaré mais aucun service ne type-hint cette variable.
- Tag personnalisé déclaré mais aucun CompilerPass ne le collecte.
- Decorator qui décore un service qui n'existe plus.

**Routes mortes :**
- Route YAML pointant vers un controller supprimé.
- Import de routes avec `resource` vers un dossier vide.

**Paramètres morts :**
- Paramètre déclaré dans `parameters:` mais jamais référencé par `%param%` nulle part.
- Variable d'environnement dans `.env` jamais utilisée dans la config ni le code.

> Pour les problèmes de sécurité dans la configuration, voir `/security-auditor`.

### 2.5 Problèmes de performance dans la configuration

- Cache non configuré en prod (pas de pool Redis/Memcached).
- Doctrine `auto_mapping: true` avec `type: annotation` (scan coûteux au boot).
- Pas de preload PHP (`config/preload.php` manquant ou vide).
- Monolog handler `stream` vers stdout sans buffer en prod.
- Messenger sans transport async configuré (tout synchrone).
- Doctrine `logging: true` et `profiling: true` en prod (si pas conditionné à `when@dev`).

## Phase 3 — Classification et scoring

### 3.1 Sévérité des anomalies

| Sévérité | Description | Action |
|----------|-------------|--------|
| `critique` | Erreur qui casse le build, faille de sécurité, ou perte de données | Corriger immédiatement |
| `majeur` | Dépréciation qui cassera à la prochaine version, incohérence fonctionnelle | Corriger rapidement |
| `mineur` | Doublon, configuration morte, optimisation possible | Nettoyer quand opportun |
| `info` | Configuration valide mais non standard, documentation manquante | Documenter |

### 3.2 Catégories d'anomalies

| Catégorie | Icone | Exemples |
|-----------|-------|----------|
| Doublon | `DUP` | Service déclaré 2 fois, route en double |
| Dépréciation | `DEP` | Bundle déprécié, syntaxe obsolète |
| Incohérence | `INC` | Config vs code, env vs config |
| Config morte | `DEAD` | Paramètre orphelin, alias inutilisé |
| Sécurité | `SEC` | Secret hardcodé, CORS ouvert |
| Performance | `PERF` | Cache manquant, logging excessif |
| Manquant | `MISS` | Env var absente, exclusion manquante |

## Phase 4 — Rapport

### Format du rapport

**Consulter `references/report-template.md`** pour le template complet du rapport Markdown et JSON.

Le rapport doit inclure :
- Vue d'ensemble (fichiers analysés, version Symfony, bundles, anomalies)
- Cartographie de la configuration (fichiers, autodiscovery, services, paramètres, variables d'env)
- Anomalies par sévérité (critique, majeur, mineur, info) avec fichier, description, correction
- État de santé des bundles (installé, enregistré, configuré)
- Matrice de cohérence environnements
- Chronologie archéologique
- Plan de nettoyage recommandé

## Phase 5 — Correction assistée (optionnel)

**Seulement si l'utilisateur le demande explicitement.** Ne jamais modifier la configuration automatiquement.

### Processus de correction

1. **Présenter le rapport** et attendre la validation de l'utilisateur.
2. **Demander confirmation** pour chaque lot de corrections (critiques d'abord).
3. **Corriger par lots** :
   - Supprimer les déclarations mortes
   - Corriger les dépréciations
   - Dédupliquer les configurations
   - Ajouter les variables d'environnement manquantes
4. **Vérifier après chaque lot** :
   - Vider le cache (`make cache` ou `php bin/console cache:clear`)
   - Exécuter `php bin/console lint:container` pour valider le container
   - Exécuter `php bin/console debug:router` pour vérifier les routes
   - Exécuter `make test` pour s'assurer que rien n'est cassé
5. **Committer** : proposer un commit par catégorie de correction.

### Commits

Proposer un commit par type de nettoyage :
```
chore(config): remove deprecated sensio/framework-extra-bundle
chore(config): remove orphan parameters and dead service declarations
chore(config): deduplicate services covered by autodiscovery
fix(config): use env var for framework secret
fix(config): add missing REDIS_URL to .env
perf(config): disable Doctrine logging in prod
```

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| Config morte détectée (services, routes) | `/dead-code-detector` pour vérifier les services PHP associés |
| Dépréciations élevées | `/migration-planner` pour planifier l'upgrade Symfony |
| Bundles dépréciés détectés | `/migration-planner` pour un plan de migration |
| Score legacy inconnu | `/full-audit` pour un audit global |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à config-archeologist :
- **Vérifier les versions** : les dépréciations dépendent de la version de Symfony installée. Lire `composer.json` / `composer.lock` pour la version exacte.
- **Attention aux environnements** : une config dans `when@dev` n'est pas une anomalie en prod et vice-versa.
- **Penser aux imports** : les fichiers de services peuvent s'importer en chaîne. Suivre la chaîne d'imports pour ne rien rater.
- **Contexte DDD** : dans une architecture DDD, vérifier que les services déclarés respectent les couches (pas de service Domain configuré avec des dépendances Infrastructure explicites).
