# Stack — Symfony / Tests & Qualité

## Configuration qualité

### phpstan.neon

```neon
parameters:
    level: max
    paths:
        - src
    excludePaths:
        - src/Kernel.php
    symfony:
        containerXmlPath: var/cache/dev/App_KernelDevDebugContainer.xml
includes:
    - vendor/phpstan/phpstan-symfony/extension.neon
    - vendor/phpstan/phpstan-doctrine/extension.neon
```

> **CI** : le fichier `containerXmlPath` n'existe qu'après un `cache:warmup` en mode `dev`. Ajouter une target Makefile `phpstan` qui exécute `bin/console cache:warmup --env=dev` avant `vendor/bin/phpstan analyse`.

### .php-cs-fixer.dist.php

```php
<?php

declare(strict_types=1);

$finder = (new PhpCsFixer\Finder())
    ->in([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ]);

return (new PhpCsFixer\Config())
    ->setRules([
        '@PER-CS2.0' => true,
        'declare_strict_types' => true,
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'single_quote' => true,
        'trailing_comma_in_multiline' => true,
        'global_namespace_import' => ['import_classes' => true],
    ])
    ->setFinder($finder)
    ->setRiskyAllowed(true);
```

### infection.json5

```json5
{
    "$schema": "vendor/infection/infection/resources/schema.json",
    "source": {
        "directories": ["src"]
    },
    "logs": {
        "text": "var/log/infection.log",
        "summary": "var/log/infection-summary.log"
    },
    "minMsi": 80,
    "minCoveredMsi": 90,
    "mutators": {
        "@default": true
    },
    "phpUnit": {
        "configDir": "."
    }
}
```

## Conventions de test

### Structure des tests

- Extension des fichiers de test : `*Test.php` (convention PHPUnit).
- Emplacement : miroir de la structure source dans `tests/`. Exemples : `tests/Unit/{Context}/Application/CommandHandler/`, `tests/Unit/{Context}/Domain/Model/`.
- Un fichier de test par classe source. Le nom du fichier de test reprend celui de la classe source suffixé par `Test` (ex : `CreateOrderCommandHandler.php` → `CreateOrderCommandHandlerTest.php`).

### Tests de handlers (CQRS)

- Toujours tester le handler en isolation : mocker les repositories, event bus, et autres dépendances.
- Vérifier que le handler appelle les bonnes méthodes sur les dépendances (save, dispatch, etc.).
- Vérifier les effets de bord : state changes sur l'agrégat, events émis.
- Tester les cas d'erreur : entité non trouvée, validation domain échouée, exception métier.

```php
final class CreateOrderCommandHandlerTest extends TestCase
{
    private OrderRepositoryInterface&MockObject $orderRepository;
    private EventBusInterface&MockObject $eventBus;
    private CreateOrderCommandHandler $handler;

    protected function setUp(): void
    {
        $this->orderRepository = $this->createMock(OrderRepositoryInterface::class);
        $this->eventBus = $this->createMock(EventBusInterface::class);
        $this->handler = new CreateOrderCommandHandler(
            $this->orderRepository,
            $this->eventBus,
        );
    }
}
```

### Tests de value objects

- Tester la validation dans le constructeur (cas valide + cas invalide).
- Tester la méthode `equals()` si elle existe.
- Tester les transformations (toString, toArray, etc.).

### Tests d'intégration

- Utiliser le `KernelTestCase` de Symfony pour tester avec le container de services.
- Réinitialiser la base de données entre chaque test (transactions ou fixtures).
- Tester les repositories Doctrine avec une vraie base de données (SQLite en mémoire ou service MySQL/PostgreSQL en CI).

### Conventions de mock

- `$this->createMock(Interface::class)` pour les dépendances du handler (PHPUnit).
- Avec Pest : utiliser `Mockery::mock(Interface::class)` ou `$this->createMock()` (les deux fonctionnent, Mockery est recommandé pour la syntaxe fluide de Pest).
- `$this->createStub(Interface::class)` quand on ne vérifie pas les appels, seulement les retours.
- Configurer les mocks dans `setUp()` / `beforeEach()` pour éviter la duplication.
- Réinitialiser les mocks — chaque test part d'un état propre.

### Fixtures et factories

- Utiliser des builders ou factories (Foundry si disponible) pour créer les objets de test. Éviter de construire manuellement les entités dans chaque test.
- Les fixtures doivent représenter des cas réalistes, pas des données aléatoires ou minimales qui masquent des bugs.
