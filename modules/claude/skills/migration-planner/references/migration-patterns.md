# Migration Planner — Breaking changes et Rector rules par version

> **Note importante** : la syntaxe `vendor/bin/rector process --set <name>` est celle de Rector 0.x (depreciee).
> Depuis **Rector 1.0+**, la configuration se fait dans le fichier `rector.php` a la racine du projet
> avec `RectorConfig::configure()->withSets([...])`. Les exemples ci-dessous utilisent la syntaxe moderne.

## Symfony 2.8 -> 3.4

### Breaking changes majeurs
- Structure `Bundle` obligatoire -> structure `src/` plate possible en 3.4+
- `DefinitionDecorator` -> `ChildDefinition`
- `FormTypeInterface::getName()` supprimé -> utiliser le FQCN
- `FormTypeInterface::setDefaultOptions()` -> `configureOptions()`
- `ChoiceType` : `choices_as_values` retiré (toujours true)
- `Translator::transChoice()` -> `trans()` avec paramètre `%count%`
- `ContainerAwareEventDispatcher` retiré
- `kernel.root_dir` déprécié -> `kernel.project_dir`

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_30,
        SymfonySetList::SYMFONY_31,
        SymfonySetList::SYMFONY_32,
        SymfonySetList::SYMFONY_33,
        SymfonySetList::SYMFONY_34,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 2
grep -rn "getName\(\)" src/ --include="*.php" | grep "Form"
grep -rn "setDefaultOptions" src/ --include="*.php"
grep -rn "DefinitionDecorator" src/ --include="*.php"
grep -rn "kernel.root_dir" config/ --include="*.yaml" --include="*.xml"
grep -rn "ContainerAware" src/ --include="*.php"
```

## Symfony 3.4 -> 4.4

### Breaking changes majeurs
- Nouvelle structure de dossiers : `app/` -> `config/`, `web/` -> `public/`, `app/Resources/views/` -> `templates/`
- Flex : `bundles.php` au lieu de `AppKernel::registerBundles()`
- Autowiring activé par défaut
- Services privés par défaut
- `TreeBuilder` : `root()` -> `getRootNode()`
- `ProcessBuilder` supprimé -> `Process::fromShellCommandline()` ou `Process` direct
- Configuration `security.yaml` : nouveau format

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_40,
        SymfonySetList::SYMFONY_41,
        SymfonySetList::SYMFONY_42,
        SymfonySetList::SYMFONY_43,
        SymfonySetList::SYMFONY_44,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 3
grep -rn "TreeBuilder" src/ --include="*.php" | grep -v "getRootNode"
grep -rn "ProcessBuilder" src/ --include="*.php"
grep -rn "public: true" config/ --include="*.yaml" | grep "_defaults"
ls app/config/ 2>/dev/null && echo "WARN: ancienne structure de dossiers détectée"
ls web/ 2>/dev/null && echo "WARN: web/ au lieu de public/"
```

## Symfony 4.4 -> 5.4

### Breaking changes majeurs
- `HttpKernel::terminate()` signature changée
- `session.storage` déprécié en faveur de `session.storage.factory`
- `RouterInterface::match()` peut lever `MethodNotAllowedException`
- `EventDispatcher::dispatch()` : signature inversée (event d'abord, puis nom)
- `PasswordEncoder` -> `PasswordHasher`
- `Guard` authenticators -> nouveaux `Authenticator`
- `Kernel::getProjectDir()` obligatoire

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_50,
        SymfonySetList::SYMFONY_51,
        SymfonySetList::SYMFONY_52,
        SymfonySetList::SYMFONY_53,
        SymfonySetList::SYMFONY_54,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 4
grep -rn "encoders:" config/ --include="*.yaml"
grep -rn "GuardAuthenticator\|AbstractGuardAuthenticator" src/ --include="*.php"
grep -rn "dispatch(" src/ --include="*.php" | grep "string.*Event\|'.*Event'"
grep -rn "PasswordEncoder" src/ --include="*.php"
```

## Symfony 5.4 -> 6.4

### Breaking changes majeurs
- PHP 8.1 minimum
- `AbstractController::getDoctrine()` supprimé -> injecter `EntityManagerInterface`
- `AbstractController::renderForm()` supprimé
- `Return type declarations` obligatoires sur toutes les méthodes overridées
- `security.yaml` : `enable_authenticator_manager: true` retiré (toujours true)
- Annotations `@Route` -> Attributs `#[Route]` (annotations encore supportées mais dépréciées)
- `FormEvents::PRE_SET_DATA` type-hint changé
- `Normalizer::CALLBACKS` déprécié en faveur de la configuration objet
- `session.storage.native` / `session.storage.mock_file` -> `session.storage.factory.native` / `session.storage.factory.mock_file`

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_60,
        SymfonySetList::SYMFONY_61,
        SymfonySetList::SYMFONY_62,
        SymfonySetList::SYMFONY_63,
        SymfonySetList::SYMFONY_64,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 5
grep -rn "getDoctrine\(\)" src/ --include="*.php"
grep -rn "renderForm\(\)" src/ --include="*.php"
grep -rn "@Route" src/ --include="*.php"
grep -rn "@ORM" src/ --include="*.php"
grep -rn "enable_authenticator_manager" config/ --include="*.yaml"
```

## Symfony 6.4 -> 7.x

### Breaking changes majeurs
- PHP 8.2 minimum
- `EventSubscriberInterface` déprécié -> `#[AsEventListener]`
- `MessageHandlerInterface` déprécié -> `#[AsMessageHandler]`
- `Command::$defaultName` -> `#[AsCommand]`
- `AbstractController::getParameter()` doit être utilisé avec prudence
- Nombreuses interfaces legacy retirées
- `PropertyAccess` : changements de comportement sur les types
- `Validator` : contraintes immutables

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_70,
        SymfonySetList::SYMFONY_71,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 6
grep -rn "EventSubscriberInterface" src/ --include="*.php"
grep -rn "MessageHandlerInterface" src/ --include="*.php"
grep -rn "defaultName" src/ --include="*.php" | grep "Command"
grep -rn "implements.*HandlerInterface" src/ --include="*.php"
```

## Symfony 7.x -> 8.x

### Breaking changes majeurs
- PHP 8.4 minimum (8.5 recommandé)
- Configuration XML supprimée pour DI (`services.xml`) et Routing (`routes.xml`) — migrer vers YAML, PHP ou attributs
- `Request::get()` supprimé — utiliser `$request->query->get()` ou `$request->request->get()`
- `#[TaggedIterator]` → `#[AutowireIterator]`, `#[TaggedLocator]` → `#[AutowireLocator]`
- `Command::getDefaultName()` / `Command::getDefaultDescription()` supprimés — `#[AsCommand]` obligatoire
- `Application::add()` → `Application::addCommand()`
- Nombreuses classes marquées `final` : `Router`, `Translator`, `UrlMatcher`, `CompiledUrlMatcher`, etc.
- `DoctrineExtractor::getTypes()` supprimé → `getType()` (retourne un seul `Type` via `symfony/type-info`)
- `PropertyTypeExtractorInterface::getTypes()` supprimé → utiliser `symfony/type-info`
- Options de session supprimées : `sid_length`, `sid_bits_per_character`
- `UrlType::default_protocol` : défaut changé de `'http'` à `null`
- `security.firewalls.*.form_login.post_only` supprimé
- `framework.form.legacy_error_messages` supprimé
- `kernel.reset` tag → `#[AsResettable]` attribut
- `AbstractController::renderForm()` définitivement supprimé
- Retrait de toutes les dépréciations Symfony 7.x

### Rector rules
```php
// rector.php
return RectorConfig::configure()
    ->withPaths(['src/'])
    ->withSets([
        SymfonySetList::SYMFONY_80,
    ]);
```
```bash
vendor/bin/rector process
```

### Commandes de diagnostic
```bash
# Chercher les patterns Symfony 7 dépréciés
grep -rn "Request::get\b\|->get(" src/ --include="*.php" | grep -v "query->get\|request->get\|headers->get\|attributes->get"
grep -rn "TaggedIterator\|TaggedLocator" src/ --include="*.php"
grep -rn "getDefaultName\|getDefaultDescription" src/ --include="*.php" | grep "Command"
grep -rn "Application::add(" src/ --include="*.php"
grep -rn "services\.xml\|routes\.xml" config/ --include="*.yaml" --include="*.php"
find config/ -name "*.xml" 2>/dev/null
grep -rn "default_protocol" config/ --include="*.yaml"
grep -rn "sid_length\|sid_bits_per_character" config/ --include="*.yaml"
grep -rn "post_only" config/ --include="*.yaml" | grep "form_login"
grep -rn "legacy_error_messages" config/ --include="*.yaml"
grep -rn "renderForm(" src/ --include="*.php"
```

## Doctrine ORM par version Symfony

| Symfony | Doctrine ORM | Doctrine DBAL | Changements clés |
|---------|-------------|---------------|-----------------|
| 2.x | 2.4-2.5 | 2.x | Annotations `@ORM\*` |
| 3.x | 2.5-2.6 | 2.x | Annotations `@ORM\*` |
| 4.x | 2.6-2.7 | 2.x | `repository_class` déprécié sur Entity |
| 5.x | 2.7-2.14 | 2.x-3.x | Attributs `#[ORM\*]` supportés |
| 6.x | 2.13+ / 3.x | 3.x-4.x | Attributs recommandés, annotations dépréciées |
| 7.x | 3.x+ | 4.x | Attributs ou XML uniquement |
| 8.x | 3.x+ | 4.x+ | Annotations supprimées |

## Diagnostic Doctrine ORM 2.x -> 3.x

### Breaking changes majeurs
- Annotations `@ORM\*` supprimees (utiliser les attributs `#[ORM\*]` ou le mapping XML)
- `UnitOfWork` n'est plus accessible directement (`$em->getUnitOfWork()` retire)
- `getName()` supprime des types DBAL custom (DBAL 4+)
- Mapping XML : extension `.dcm.xml` depreciee en faveur de `.orm.xml`
- Plusieurs methodes de `EntityRepository` renommees ou supprimees

### Commandes de diagnostic
```bash
# Detect annotation-based mapping (removed in ORM 3.x)
grep -rn "@ORM\\\\" src/ --include="*.php"
grep -rn "@Entity\|@Table\|@Column\|@OneToMany\|@ManyToOne" src/ --include="*.php"

# Detect XML mapping files
find config/ src/ -name "*.orm.xml" -o -name "*.dcm.xml"

# Detect deprecated UnitOfWork usage
grep -rn "getUnitOfWork\|UnitOfWork" src/ --include="*.php"

# Detect getName() in custom Doctrine types (removed DBAL 4+)
grep -rn "function getName" src/ --include="*.php" | grep -i "type"
```

## Commandes utiles pendant la migration

```bash
# Vérifier les dépréciations au runtime
APP_ENV=dev bin/console --deprecations

# Chercher les vulnérabilités
composer audit

# Vérifier les packages outdated
composer outdated --direct

# Lancer Rector en dry-run
vendor/bin/rector process src/ --dry-run

# Régénérer le cache après migration
bin/console cache:clear
bin/console cache:warmup

# Vérifier le container
bin/console lint:container

# Vérifier le routing
bin/console debug:router
```
