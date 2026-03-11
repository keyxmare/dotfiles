# Référence — App web : Backend Symfony

## Backend Symfony

Lire et suivre `~/.claude/stacks/symfony.md`.

### Structure simple

```
backend/
├── bin/console
├── config/ (packages/, routes/, bundles.php, routes.yaml, services.yaml)
├── migrations/
├── public/index.php
├── src/ (Kernel.php, Controller/, Entity/, Repository/, Service/)
├── tests/ (Unit/, Integration/, Functional/)
├── composer.json
├── Makefile
├── phpunit.xml.dist
├── phpstan.neon
├── .php-cs-fixer.dist.php
└── .env
```

### Structure advanced (DDD)

```
backend/
├── bin/console
├── config/
├── migrations/
├── public/index.php
├── src/
│   ├── Kernel.php
│   ├── Shared/ (Domain/, Infrastructure/, Application/)
│   └── [Context]/ (Domain/, Application/, Infrastructure/)
├── tests/
│   ├── Unit/[Context]/ ...
│   └── Factory/[Context]/ ...
├── composer.json, Makefile, phpunit.xml.dist, phpstan.neon, .php-cs-fixer.dist.php, .env
```

Chaque bounded context :
- `Domain/` — Model/ (entités avec attributs ORM), ValueObject/, Repository/ (interfaces), Port/ (interfaces pour clients externes), Event/, Exception/
- `Application/` — Command/, CommandHandler/, Query/, QueryHandler/, DTO/
- `Infrastructure/` — Persistence/Doctrine/, Controller/, Messenger/

Les entités utilisent les **PHP attributes Doctrine** directement sur le domain model (approche standard Symfony 8 — XML mapping supprimé).

### Fichiers de configuration

- **composer.json** — Symfony 8.x, PHP 8.4+, Doctrine ORM (`doctrine/orm`, `doctrine/doctrine-bundle` ^3.2, `doctrine/doctrine-migrations-bundle` ^4.0), PHPUnit, PHPStan, PHP-CS-Fixer, Infection. Si advanced : `symfony/messenger`. Scripts post-install/post-update avec `|| true` (voir stack). `config.allow-plugins` : `symfony/runtime`, `infection/extension-installer`.
- **phpunit.xml.dist** — Testsuites : Unit, Integration, Functional.
- **phpstan.neon** — Level max, paths `src/`. Ne pas inclure manuellement `phpstan-symfony` ou `phpstan-doctrine` — ils sont auto-chargés par `phpstan/extension-installer`. Ne pas désactiver des checks (`checkMissingIterableValueType`, `checkGenericClassInNonGenericObjectType`).
- **.php-cs-fixer.dist.php** — PSR-12, `declare_strict_types` forcé.
- **.env** — `APP_ENV=dev`, `APP_SECRET=changeme`, `DATABASE_URL` si BDD.
- **Makefile** — Suivre `~/.claude/stacks/makefile.md`. Targets : install, test, test-coverage, test-mutation, lint, lint-fix, phpstan, rector, rector-dry, audit, outdated, quality, help. Si BDD : db-migrate, db-fixtures, db-reset.
- **services.yaml** — Si advanced : autowiring par bounded context, bus Messenger (command.bus, query.bus, event.bus). **Bindings** : binder les interfaces Port aux implémentations concrètes (`App\{Context}\Domain\Port\{Client}Interface: '@App\{Context}\Infrastructure\{Client}'`). Injecter les paramètres de configuration aux clients externes via `bind` (`$gitlabUrl: '%env(GITLAB_URL)%'`, `$gitlabToken: '%env(GITLAB_TOKEN)%'`, etc.). Chaque variable d'environnement utilisée dans un binding doit être documentée dans `.env.example`.
- **bundles.php** — Doit inclure **tous** les bundles requis. Ne pas oublier `TwigBundle` (requis par Symfony), `DoctrineFixturesBundle` (si fixtures), `WebProfilerBundle` (dev/test), `TwigExtraBundle` (si Twig), `MonologBundle`, `MercureBundle` (si module Mercure).
- **Packages config Symfony** — En plus de `doctrine.yaml`, `framework.yaml`, `messenger.yaml`, générer les fichiers de config standards manquants :
  - `config/packages/routing.yaml` — `framework: router: { default_uri: '%env(DEFAULT_URI)%' }` (requis pour la génération d'URLs en CLI).
  - `config/packages/doctrine_migrations.yaml` — configuration du DoctrineMigrationsBundle.
  - `config/packages/validator.yaml` — `framework: validation: { email_validation_mode: html5 }`.
  - `config/packages/property_info.yaml` — `framework: property_info: { enabled: true }`.
  - `config/packages/twig.yaml` — `twig: { default_path: '%kernel.project_dir%/templates' }` (si TwigBundle).
  - `config/packages/http_discovery.yaml` — configuration HTTP client discovery (si nyholm/psr7).
  - `config/preload.php` — fichier de preload PHP pour optimisation opcache.
  - `templates/` — répertoire vide (requis par TwigBundle).
- **Doctrine config** — Ne pas ajouter d'options obsolètes dans `doctrine.yaml` : `auto_generate_proxy_classes`, `enable_lazy_ghost_objects` sont les défauts de Doctrine 3 (ne pas les spécifier). `controller_resolver.auto_mapping` est supprimé. Utiliser la version correcte de PostgreSQL (`server_version` dans `doctrine.yaml` doit correspondre à la version dans `versions.json`).

### Rector

`rector/rector` dans les devDependencies. Configuration `rector.php` :

```php
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\SetList;
use Rector\Symfony\Set\SymfonySetList;

return RectorConfig::configure()
    ->withPaths(['src'])
    ->withSets([
        SetList::PHP_84,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SymfonySetList::SYMFONY_80,
    ]);
```

Targets Makefile :

```makefile
.PHONY: rector
rector: ## Applique les refactorings Rector
	$(DC_EXEC_BACKEND) vendor/bin/rector

.PHONY: rector-dry
rector-dry: ## Affiche les refactorings Rector sans les appliquer
	$(DC_EXEC_BACKEND) vendor/bin/rector --dry-run

.PHONY: outdated
outdated: ## Vérifie les dépendances obsolètes
	$(DC_EXEC_BACKEND) composer outdated --direct
```

---

## Validation & Error Handling

Infrastructure commune générée dans `Shared/` (mode advanced) ou `src/` (mode simple) :

### Mode advanced

- `Shared/Domain/Exception/DomainException.php` — exception de base (template `domain-exception.php.tpl`).
- `Shared/Domain/Exception/NotFoundException.php` — entité non trouvée (template `not-found-exception.php.tpl`).
- `Shared/Application/DTO/ErrorOutput.php` — DTO de réponse erreur (template `error-output.php.tpl`).
- `Shared/Application/DTO/ApiResponse.php` — envelope de réponse standardisée (template `api-response.php.tpl`).
- `Shared/Application/DTO/PaginatedOutput.php` — sortie paginée générique (template `paginated-output.php.tpl`).
- `Shared/Infrastructure/EventListener/ExceptionListener.php` — global exception handler JSON (template `exception-listener.php.tpl`).
- Config `services.yaml` : enregistrer l'ExceptionListener sur `kernel.exception`.

### Mode simple

Mêmes fichiers dans `src/Exception/`, `src/DTO/`, `src/EventListener/`. Les fichiers `ApiResponse.php` et `PaginatedOutput.php` sont dans `src/DTO/`.

### Validation des DTOs Input

Les DTOs Input (Create/Update) utilisent les attributs Symfony Validator :

```php
use Symfony\Component\Validator\Constraints as Assert;

final readonly class CreateProductInput
{
    public function __construct(
        #[Assert\NotBlank]
        #[Assert\Length(max: 255)]
        public string $name,

        #[Assert\Positive]
        public float $price,
    ) {
    }
}
```

Les controllers valident le DTO avant dispatch. En cas d'erreur, l'ExceptionListener formate la réponse 422.

### Mise à jour partielle (PATCH)

En plus de PUT (remplacement complet), les entités peuvent supporter PATCH (mise à jour partielle). Le DTO utilise des propriétés nullables :

```php
final readonly class Patch{{Entity}}Input
{
    public function __construct(
        #[Assert\Length(max: 255)]
        public ?string $name = null,

        #[Assert\Positive]
        public ?float $price = null,
    ) {
    }

    public function hasChanges(): bool
    {
        return $this->name !== null || $this->price !== null;
    }
}
```

Le handler applique uniquement les champs non-null :

```php
public function __invoke(Patch{{Entity}}Command $command): void
{
    $entity = $this->repository->get($command->id);

    if ($command->input->name !== null) {
        $entity->updateName($command->input->name);
    }
    if ($command->input->price !== null) {
        $entity->updatePrice($command->input->price);
    }

    $this->repository->save($entity);
}
```

Route : `PATCH /api/{context}/{entities}/{id}`. Response : 200 avec l'entité mise à jour.

### Envelope de réponse API

Toutes les réponses API utilisent un wrapper standardisé (template `api-response.php.tpl`) :

```json
{
  "data": { "id": "...", "name": "..." },
  "meta": { "page": 1, "total": 42, "limit": 20 },
  "errors": []
}
```

- `data` : le payload (objet, tableau, ou null).
- `meta` : métadonnées (pagination, timestamps, etc.). Absent si non pertinent.
- `errors` : tableau de messages d'erreur. Vide si succès.

Le `ExceptionListener` utilise `ApiResponse::error()` pour formatter les réponses d'erreur.
Les controllers utilisent `ApiResponse::success()` pour formatter les réponses réussies.

### Pagination

Les queries LIST supportent la pagination :

```php
final readonly class ListProductsQuery
{
    public function __construct(
        public int $page = 1,
        public int $limit = 20,
    ) {
    }
}
```

Le handler retourne un `PaginatedOutput` :

```php
final readonly class PaginatedOutput
{
    public function __construct(
        public array $items,
        public int $total,
        public int $page,
        public int $limit,
    ) {
    }
}
```

### Filtrage et tri

Les queries LIST supportent le filtrage et le tri optionnels :

```php
final readonly class List{{Entities}}Query
{
    /**
     * @param array<string, mixed> $filters
     */
    public function __construct(
        public int $page = 1,
        public int $limit = 20,
        public ?string $sortBy = null,
        public string $sortOrder = 'asc',
        public array $filters = [],
    ) {
    }
}
```

Le handler applique les filtres au QueryBuilder Doctrine :

```php
$qb = $this->repository->createQueryBuilder('e');

foreach ($query->filters as $field => $value) {
    $qb->andWhere("e.{$field} = :{$field}")
       ->setParameter($field, $value);
}

if ($query->sortBy !== null) {
    $qb->orderBy("e.{$query->sortBy}", $query->sortOrder);
}
```

Les filtres sont passés en query string : `GET /api/catalog/products?sortBy=price&sortOrder=desc&name=Widget`.

---

## Fixtures et données de test

### Backend — DoctrineFixturesBundle

Si le projet a un backend avec BDD, générer un système de fixtures :

- `doctrine/doctrine-fixtures-bundle` dans `composer.json` (dev dependency).
- **Ne pas générer** de `AppFixtures.php` vide — générer directement les fixtures par entité.
- Une fixture par entité : `src/DataFixtures/{Context}/{Entity}Fixtures.php` (advanced) ou `src/DataFixtures/{Entity}Fixtures.php` (simple).
- Données réalistes et cohérentes (noms, emails, dates plausibles). Pas de `foo`, `bar`, `test123`.
- Utiliser `Symfony\Component\Uid\Uuid::v7()` pour les identifiants.
- Quantité : 5-10 enregistrements par entité, suffisant pour démontrer la pagination.
- Respecter les relations entre entités (foreign keys cohérentes).

### Targets Makefile

```makefile
.PHONY: db-fixtures
db-fixtures: ## Charge les fixtures en base de données
	$(DC_EXEC_BACKEND) php bin/console doctrine:fixtures:load --no-interaction

.PHONY: db-reset
db-reset: ## Reset la base de données et charge les fixtures
	$(DC_EXEC_BACKEND) php bin/console doctrine:database:drop --force --if-exists
	$(DC_EXEC_BACKEND) php bin/console doctrine:database:create
	$(DC_EXEC_BACKEND) php bin/console doctrine:migrations:migrate --no-interaction
	$(DC_EXEC_BACKEND) php bin/console doctrine:fixtures:load --no-interaction
```

### Factories de test

Chaque entité a une factory de test (template `entity-factory.php.tpl`) dans `tests/Factory/{Context}/` :

```php
final class ProductFactory
{
    public static function create(array $overrides = []): Product
    {
        return Product::create(
            id: $overrides['id'] ?? Uuid::v7()->toRfc4122(),
            name: $overrides['name'] ?? 'Default Product',
            price: $overrides['price'] ?? 19.99,
        );
    }

    public static function createMany(int $count, array $overrides = []): array
    {
        return array_map(fn () => self::create($overrides), range(1, $count));
    }
}
```

Utilisable dans les tests unitaires et d'intégration. Les valeurs par défaut sont réalistes et cohérentes. La factory est générée automatiquement lors de la création d'une entité (étape 8).
