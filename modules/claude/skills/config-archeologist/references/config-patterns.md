# Patterns de détection de configuration — Symfony

## Commandes de scan rapide

### Cartographie des fichiers de config

```bash
# Lister tous les fichiers de configuration
find config/ -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.xml" -o -name "*.php" \) 2>/dev/null | sort

# Compter les lignes par fichier
find config/ -type f -name "*.yaml" -exec wc -l {} \; 2>/dev/null | sort -rn
```

### Inventaire services.yaml

```bash
# Blocs autodiscovery (resource + exclude)
grep -n "resource:\|exclude:" config/services.yaml config/services/*.yaml 2>/dev/null

# Services déclarés explicitement (indentés sous un FQCN)
grep -n "^    App\\\\" config/services.yaml config/services/*.yaml 2>/dev/null

# Alias de services
grep -n "alias:" config/services.yaml config/services/*.yaml 2>/dev/null

# Tags sur les services
grep -n "tags:" config/services.yaml config/services/*.yaml 2>/dev/null

# Bindings globaux (_defaults.bind)
grep -n "bind:" config/services.yaml 2>/dev/null

# Services publics
grep -n "public: true" config/services.yaml config/services/*.yaml 2>/dev/null

# Imports
grep -n "resource:\|imports:" config/services.yaml 2>/dev/null

# Paramètres
grep -n "^parameters:" config/services.yaml 2>/dev/null
grep -A 50 "^parameters:" config/services.yaml 2>/dev/null | grep -E "^\s+\w"

# Decorators
grep -n "decorates:" config/services.yaml config/services/*.yaml 2>/dev/null

# Factories
grep -n "factory:" config/services.yaml config/services/*.yaml 2>/dev/null
```

### Inventaire du routing

```bash
# Fichiers de routes
find config/routes* -type f 2>/dev/null

# Contenu des routes YAML
cat config/routes.yaml 2>/dev/null

# Imports de routes
grep -n "resource:\|prefix:\|name_prefix:" config/routes.yaml config/routes/*.yaml 2>/dev/null

# Routes avec type: attribute
grep -n "type: attribute\|type: annotation" config/routes.yaml config/routes/*.yaml 2>/dev/null

# Attributs #[Route] dans les controllers
grep -rn "#\[Route" src/ --include="*.php" 2>/dev/null
```

### Inventaire bundles

```bash
# Bundles enregistrés
cat config/bundles.php 2>/dev/null

# Fichiers de config de bundles
ls -la config/packages/ 2>/dev/null

# Configs par environnement
ls -la config/packages/dev/ config/packages/test/ config/packages/prod/ 2>/dev/null

# Blocs when@
grep -rn "when@" config/packages/ --include="*.yaml" 2>/dev/null
```

### Inventaire des paramètres

```bash
# Paramètres déclarés
grep -rn "^parameters:" config/ --include="*.yaml" 2>/dev/null

# Paramètres utilisés (%param%)
grep -rn "%[a-z_\.]*%" config/ --include="*.yaml" 2>/dev/null | grep -v "^#" | grep -v "%env("

# Variables d'environnement dans la config
grep -rn "%env(" config/ --include="*.yaml" 2>/dev/null
```

### Inventaire des variables d'environnement

```bash
# Variables dans .env
grep -n "^[A-Z]" .env 2>/dev/null

# Variables dans .env.local
grep -n "^[A-Z]" .env.local 2>/dev/null

# Variables dans .env.test
grep -n "^[A-Z]" .env.test 2>/dev/null

# Variables dans docker-compose
grep -n "environment:" docker-compose.yml docker-compose.override.yml 2>/dev/null
grep -rn "\${.*}" docker-compose.yml 2>/dev/null

# Variables utilisées dans la config Symfony
grep -rn "env(" config/ --include="*.yaml" 2>/dev/null | sed 's/.*env(\([^)]*\)).*/\1/' | sort -u
```

## Détection des anomalies

### Doublons de services

```bash
# Services potentiellement en doublon avec autodiscovery
# Extraire les FQCN déclarés explicitement
grep -n "^    App\\\\" config/services.yaml 2>/dev/null

# Vérifier s'ils sont dans le scope de l'autodiscovery
# Croiser avec les blocs resource:/exclude:
```

### Doublons de routes

```bash
# Routes avec le même nom (le dernier gagne)
grep -rn "name:" config/routes*.yaml 2>/dev/null | awk -F: '{print $NF}' | sort | uniq -d

# Routes avec le même path
grep -rn "path:" config/routes*.yaml 2>/dev/null | awk -F'path:' '{print $2}' | sort | uniq -d
```

### Dépréciations

```bash
# sensio/framework-extra-bundle
grep -rn "sensio" composer.json config/bundles.php 2>/dev/null

# swiftmailer
grep -rn "swiftmailer" composer.json config/bundles.php config/packages/ 2>/dev/null

# fos/rest-bundle (si API Platform est installé)
grep -l "api-platform" composer.json 2>/dev/null && grep -rn "fos.*rest" composer.json 2>/dev/null

# Doctrine annotations (vs attributes)
grep -rn "type: annotation" config/packages/doctrine* 2>/dev/null

# Public services par défaut
grep -n "public: true" config/services.yaml 2>/dev/null | head -5
```

### Incohérences services vs code

```bash
# Extraire les FQCN des services déclarés
grep -n "class:" config/services.yaml config/services/*.yaml 2>/dev/null | grep "App\\\\"

# Pour chaque FQCN, vérifier que le fichier PHP existe
# Convertir namespace en path : App\Foo\Bar → src/Foo/Bar.php
```

### Incohérences config vs bundles installés

```bash
# Bundles dans config/packages/ sans le package installé
for config_file in config/packages/*.yaml; do
  bundle_key=$(head -1 "$config_file" | sed 's/://')
  echo "Config: $config_file → key: $bundle_key"
done

# Packages installés sans config
# Comparer composer.json require avec config/packages/
```

### Config morte

```bash
# Paramètres déclarés dans services.yaml
grep -A 50 "^parameters:" config/services.yaml 2>/dev/null | grep -E "^\s+(\w+)" | awk '{print $1}' | sed 's/://'

# Pour chaque paramètre, vérifier s'il est utilisé
# PARAM="app.my_param"
# grep -rn "%${PARAM}%" config/ src/ 2>/dev/null

# Variables .env non utilisées
# Pour chaque variable dans .env, chercher dans config/ et src/
```

### Sécurité

```bash
# Secret hardcodé
grep -rn "secret:" config/packages/framework* 2>/dev/null | grep -v "env("

# Mots de passe en clair
grep -rn "password:" config/ --include="*.yaml" 2>/dev/null | grep -v "env(" | grep -v "#"

# CORS ouvert
grep -rn "allow_origin.*\*" config/packages/nelmio_cors* 2>/dev/null

# Firewall security: false
grep -rn "security: false" config/packages/security* 2>/dev/null

# Debug en prod
grep -n "APP_DEBUG=1\|APP_ENV=dev" .env 2>/dev/null
```

### Performance

```bash
# Doctrine logging/profiling en prod
grep -rn "logging:\|profiling:" config/packages/doctrine* 2>/dev/null

# Cache config
ls config/packages/cache* 2>/dev/null

# Preload
ls config/preload.php 2>/dev/null

# Messenger synchrone (pas de transport async)
grep -rn "transport:" config/packages/messenger* 2>/dev/null
```

## Patterns de faux positifs

### Services qui semblent en doublon mais ne le sont pas

| Pattern | Raison |
|---------|--------|
| Service avec `arguments:` custom | Override nécessaire de l'autowiring |
| Service avec `tags:` custom | Tag non-autoconfigurable |
| Service avec `calls:` | Setter injection nécessaire |
| Service avec `factory:` | Création via factory |
| Service avec `decorates:` | Decorator pattern |
| Service avec `lazy: true` | Proxy lazy nécessaire |
| Service avec `shared: false` | Prototype scope |
| Service avec `autowire: false` | Désactivation intentionnelle |

### Paramètres qui semblent morts mais ne le sont pas

| Pattern | Raison |
|---------|--------|
| Paramètres utilisés dans des CompilerPass | Résolution dynamique |
| Paramètres utilisés via `$container->getParameter()` | Accès programmatique |
| Paramètres hérités par convention Symfony | Utilisés par le framework |
| Paramètres `kernel.*` | Toujours utilisés |
| Paramètres `locale` / `default_locale` | Convention Symfony |

### Variables d'environnement qui semblent mortes mais ne le sont pas

| Pattern | Raison |
|---------|--------|
| `APP_ENV`, `APP_DEBUG`, `APP_SECRET` | Bootstrap Symfony |
| `DATABASE_URL` | Convention Doctrine |
| `MAILER_DSN` | Convention Mailer |
| `MESSENGER_TRANSPORT_DSN` | Convention Messenger |
| Variables utilisées dans `docker-compose.yml` | Injection Docker |
| Variables utilisées dans le Makefile | Commandes custom |
| Variables utilisées dans CI/CD | Pipelines |

## Versions et dépréciations connues

### Symfony 5.x → 6.x

| Déprécié | Remplacement |
|----------|-------------|
| `sensio/framework-extra-bundle` | Attributs natifs Symfony |
| `@ParamConverter` | `#[MapEntity]` |
| `@IsGranted` | `#[IsGranted]` |
| `@Template` | Attribut `#[Template]` ou return array |
| `framework.templating` | Supprimé |
| `framework.router.utf8` | Par défaut à true |

### Symfony 6.x → 7.x

| Déprécié | Remplacement |
|----------|-------------|
| `enable_authenticator_manager: true` | Par défaut, option supprimée |
| `security.enable_authenticator_manager` | Supprimé |
| `AbstractController::getDoctrine()` | Injecter `EntityManagerInterface` |
| Annotations de routing | Attributs PHP 8 |

### Symfony 7.x → 8.x

| Déprécié | Remplacement |
|----------|-------------|
| Configuration XML pour DI (`services.xml`) | Configuration YAML ou PHP uniquement |
| Configuration XML pour le routing (`routes.xml`) | Configuration YAML, PHP ou attributs |
| `session.sid_length` | Supprimé (valeur PHP par défaut) |
| `session.sid_bits_per_character` | Supprimé (valeur PHP par défaut) |
| `framework.session.storage_factory_id: session.storage.factory.native` | Vérifier les options supprimées |
| `#[TaggedIterator]` | `#[AutowireIterator]` |
| `#[TaggedLocator]` | `#[AutowireLocator]` |
| `security.firewalls.*.form_login.post_only` | Supprimé |
| `framework.form.legacy_error_messages` | Supprimé |
| `Request::get()` dans les controllers | `Request::query->get()` ou `Request::request->get()` |
| `kernel.reset` tag manuel | `#[AsResettable]` attribut |
| `Command::getDefaultName()` | `#[AsCommand]` attribut obligatoire |
| `Application::add()` | `Application::addCommand()` |
| `UrlType::default_protocol` (non-null) | Défaut à `null`, utiliser `default_protocol: 'https'` explicitement |

### Doctrine ORM 2.x → 3.x

| Déprécié | Remplacement |
|----------|-------------|
| `type: annotation` | `type: attribute` |
| `naming_strategy: underscore` | `underscore_number_aware` |
| `EntityManager::create()` | `EntityManager::create()` avec ManagerRegistry |
| XML mapping `<entity>` format v1 | Format v2 |

## Heuristiques de classification

### Sévérité "critique"

- Classe référencée dans services.yaml qui n'existe pas
- Secret hardcodé dans la config
- Variable d'environnement utilisée dans la config mais absente de `.env` et sans valeur par défaut
- Firewall `security: false` dans un contexte non-test
- Route pointant vers un controller inexistant

### Sévérité "majeur"

- Bundle déprécié encore installé
- Syntaxe de mapping Doctrine dépréciée
- Configuration dépréciée qui sera supprimée dans la prochaine version majeure
- Service décorant un service qui n'existe plus

### Sévérité "mineur"

- Service déclaré explicitement alors que l'autodiscovery le couvre
- Paramètre orphelin
- Variable d'environnement inutilisée dans `.env`
- Configuration de bundle avec valeurs par défaut redondantes
- Alias de service jamais injecté

### Sévérité "info"

- Bundle installé utilisant ses valeurs par défaut (pas de config)
- Configuration en `when@dev` uniquement
- Services avec `public: true` (valide mais à vérifier)
