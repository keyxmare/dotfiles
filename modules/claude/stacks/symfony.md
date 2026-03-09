# Stack — PHP / Symfony

## Version

- Symfony 8.x
- PHP 8.4+

## Dépendances compatibles Symfony 8

Les versions majeures suivantes sont requises pour Symfony 8 :

| Package | Version min | Note |
|---|---|---|
| `doctrine/doctrine-bundle` | `^3.2` | La v2.x ne supporte que Symfony 6/7 |
| `doctrine/doctrine-migrations-bundle` | `^4.0` | La v3.x ne supporte que Symfony 6/7 |
| `doctrine/orm` | `^3.0` | |

### Options de config supprimées dans doctrine-bundle 3.x

Les options suivantes n'existent plus dans `config/packages/doctrine.yaml` :

- `auto_generate_proxy_classes` — supprimée
- `enable_lazy_ghost_objects` — supprimée (lazy ghost objects sont le défaut)

### Fichier .env

Symfony requiert un fichier `.env` dans le répertoire backend (convention Symfony) :

- `backend/.env` — versionné, contient les valeurs par défaut de développement
- `backend/.env.local` — gitignored, surcharges locales
- `backend/.env.test` — versionné, surcharges pour l'environnement de test

→ Voir [security.md](./security.md#secrets) pour les règles générales de gestion des secrets et fichiers `.env`.

## Conventions de code

- PER-CS2.0 pour le style de code (successeur de PSR-12, adopté par PHP-FIG).
- Utiliser les PHP attributes natifs (pas d'annotations Doctrine).
- `#[AsController]` pour les controllers.
- `#[AsMessageHandler]` pour les handlers Messenger.
- `#[AsCommand]` pour les commandes console.
- `#[Route]` pour le routing (directement sur les méthodes).
- Injection de dépendances via le constructeur, autowiring activé.
- `#[Autowire]` pour les injections spécifiques (services nommés, paramètres).
- `readonly` sur les classes et propriétés quand c'est possible.
- Typage strict partout (`declare(strict_types=1)`).
- `final` par défaut sur les classes sauf besoin explicite d'héritage.

## Outils

| Outil | Usage |
|---|---|
| Composer | Package manager |
| PHPUnit | Tests unitaires et intégration |
| Behat | Tests E2E / fonctionnels |
| Infection | Mutation testing |
| PHP-CS-Fixer | Formatage (PER-CS2.0) |
| PHPStan (level max) | Analyse statique |

## Configuration qualité & Tests

→ Voir [symfony-testing.md](./symfony-testing.md) pour les configurations PHPStan, PHP-CS-Fixer, Infection et les conventions de test.

## Structure standard

Quand `symfony.ddd` = `false`, suivre la structure Symfony par défaut :

```
backend/
├── bin/
│   └── console
├── config/
│   ├── packages/
│   ├── routes/
│   ├── bundles.php
│   ├── routes.yaml
│   └── services.yaml
├── migrations/
├── public/
│   └── index.php
├── src/
│   ├── Kernel.php
│   ├── Command/
│   ├── Controller/
│   ├── DataFixtures/
│   ├── Entity/
│   ├── EventSubscriber/
│   ├── Form/
│   ├── Repository/
│   ├── Security/
│   └── Service/
├── templates/
├── tests/
│   ├── Unit/
│   ├── Integration/
│   └── Functional/
├── translations/
├── var/
│   ├── cache/
│   └── log/
├── vendor/
├── composer.json
├── composer.lock
├── Makefile
├── phpunit.xml.dist
├── phpstan.neon
└── .php-cs-fixer.dist.php
```

## Structure DDD

Quand `symfony.ddd` = `true`, le code métier est organisé par bounded context dans `src/`. ← `symfony.ddd`

```
backend/
├── bin/
│   └── console
├── config/
│   ├── packages/
│   ├── routes/
│   ├── bundles.php
│   ├── routes.yaml
│   └── services.yaml
├── migrations/
├── public/
│   └── index.php
├── src/
│   ├── Kernel.php
│   │
│   ├── Shared/                          ← Code partagé entre bounded contexts
│   │   ├── Domain/
│   │   │   ├── ValueObject/
│   │   │   ├── Event/
│   │   │   └── Exception/
│   │   └── Infrastructure/
│   │       ├── Persistence/
│   │       ├── Messenger/
│   │       └── Security/
│   │
│   ├── [BoundedContextA]/               ← Ex: Identity, Catalog, Billing…
│   │   ├── Domain/
│   │   │   ├── Model/                   ← Entités, agrégats
│   │   │   ├── ValueObject/
│   │   │   ├── Repository/             ← Interfaces des repositories (ports)
│   │   │   ├── Event/                  ← Domain events
│   │   │   ├── Exception/
│   │   │   └── Service/               ← Domain services
│   │   │
│   │   ├── Application/
│   │   │   ├── Command/               ← Commands CQRS
│   │   │   ├── CommandHandler/        ← Handlers de commands
│   │   │   ├── Query/                 ← Queries CQRS
│   │   │   ├── QueryHandler/         ← Handlers de queries
│   │   │   ├── DTO/                   ← Data Transfer Objects
│   │   │   └── Event/                 ← Application events / listeners
│   │   │
│   │   └── Infrastructure/
│   │       ├── Persistence/           ← Implémentations des repositories (adapters)
│   │       │   ├── Doctrine/          ← Repositories Doctrine
│   │       │   └── Mapping/           ← Mapping Doctrine XML (si Domain sans attributs PHP)
│   │       ├── Controller/            ← Controllers HTTP
│   │       ├── Console/              ← Commandes console
│   │       └── Messenger/            ← Configuration Messenger (transports, handlers)
│   │
│   └── [BoundedContextB]/
│       ├── Domain/
│       ├── Application/
│       └── Infrastructure/
│
├── templates/
├── tests/
│   ├── Unit/
│   │   ├── [BoundedContextA]/
│   │   │   ├── Domain/
│   │   │   └── Application/
│   │   └── [BoundedContextB]/
│   ├── Integration/
│   │   ├── [BoundedContextA]/
│   │   │   └── Infrastructure/
│   │   └── [BoundedContextB]/
│   └── Functional/
│       ├── [BoundedContextA]/
│       └── [BoundedContextB]/
├── translations/
├── var/
├── vendor/
├── composer.json
├── composer.lock
├── Makefile
├── phpunit.xml.dist
├── phpstan.neon
└── .php-cs-fixer.dist.php
```

### Règles DDD strictes

- **Domain** — Aucune dépendance vers l'extérieur hormis Doctrine ORM (attributs). Les attributs ORM (`#[ORM\Entity]`, `#[ORM\Column]`) sont placés directement sur les entités Domain — c'est l'approche standard Symfony 8 (le mapping XML a été supprimé).
- **Application** — Dépend uniquement du Domain. Orchestre les use cases via les commands/queries (CQRS). Utilise Symfony Messenger avec des bus séparés (command.bus, query.bus, event.bus).
- **Infrastructure** — Implémente les interfaces définies dans le Domain (ports/adapters). Contient les controllers, repositories Doctrine, transports Messenger, etc.
- **Shared** — Contient uniquement les value objects, events et exceptions réellement transverses. Ne pas en abuser.
- Les bounded contexts ne se connaissent pas directement. La communication entre contextes passe par des domain events via Messenger.
- Les tests suivent la même structure de bounded contexts.

### CQRS, Messenger & Endpoints de santé

→ Voir [symfony-cqrs.md](./symfony-cqrs.md) pour la configuration Messenger (3 buses), CQRS, outbox et les health endpoints.

## Identifiants

### UUIDv7 avec Symfony Uid

Utiliser exclusivement le composant `symfony/uid` pour la génération d'identifiants. Requiert `composer require symfony/uid`. Pas de `ramsey/uuid`, pas de génération côté BDD.

```php
<?php declare(strict_types=1);

use Symfony\Component\Uid\Uuid;

final readonly class OrderId
{
    public function __construct(public Uuid $value) {}

    public static function generate(): self
    {
        return new self(Uuid::v7());
    }

    public static function fromString(string $value): self
    {
        return new self(Uuid::fromString($value));
    }

    public function toString(): string
    {
        return (string) $this->value;
    }

    public function equals(self $other): bool
    {
        return $this->value->equals($other->value);
    }
}
```

### Doctrine mapping

Utiliser le type `uuid` de Doctrine avec le composant Symfony Uid :

```php
#[ORM\Id]
#[ORM\Column(type: 'uuid')]
private Uuid $id;
```

### Règles

- Toujours générer les UUIDs côté applicatif (pas côté BDD).
- Wrapper chaque identifiant dans un value object typé (`OrderId`, `UserId`, etc.).
- UUIDv7 par défaut : triable chronologiquement, performant sur les index B-tree.
- Pas de `ramsey/uuid`, pas de `gen_random_uuid()` PostgreSQL.

## composer.json — Pièges connus

### allow-plugins

Toujours déclarer les plugins Composer nécessaires dans `config.allow-plugins`. Plugins à inclure systématiquement :

```json
{
    "config": {
        "allow-plugins": {
            "symfony/runtime": true,
            "infection/extension-installer": true
        },
        "sort-packages": true
    }
}
```

`sort-packages` trie alphabétiquement les entrées `require`/`require-dev`, ce qui réduit les conflits git sur les diffs.

Sans ces déclarations, `composer install` échoue en mode interactif (pas de TTY dans Docker).

### Scripts post-install / post-update

Ne pas utiliser `symfony-cmd` (fourni par `symfony/flex`) sauf si Flex est explicitement installé. Utiliser des commandes PHP directes :

```json
{
    "scripts": {
        "post-install-cmd": [
            "@php bin/console cache:clear --no-warmup --quiet 2>/dev/null || true"
        ],
        "post-update-cmd": [
            "@php bin/console cache:clear --no-warmup --quiet 2>/dev/null || true"
        ]
    }
}
```

Le `|| true` évite que le script échoue si la console Symfony n'est pas encore fonctionnelle (première installation, pas de .env, etc.).

## Makefile backend

Suit les conventions de [makefile.md](./makefile.md) (couleurs, help, `.DEFAULT_GOAL`, `.PHONY`). Variable d'exécution : `EXEC = $(DC) exec backend`.

| Target | Commande | Description |
|---|---|---|
| `install` | `$(EXEC) composer install` | Installe les dépendances |
| `db-migrate` | `$(EXEC) bin/console doctrine:migrations:migrate --no-interaction` | Joue les migrations |
| `db-fixtures` | `$(EXEC) bin/console doctrine:fixtures:load --no-interaction` | Charge les fixtures |
| `test` | `$(EXEC) bin/phpunit` | Lance les tests PHPUnit |
| `test-coverage` | `$(EXEC) bin/phpunit --coverage-text` | Tests avec couverture |
| `test-mutation` | `$(EXEC) vendor/bin/infection --min-msi=80` | Mutation testing (Infection) |
| `lint` | `$(EXEC) vendor/bin/php-cs-fixer fix --dry-run --diff` | Lint PHP-CS-Fixer |
| `lint-fix` | `$(EXEC) vendor/bin/php-cs-fixer fix` | Corrige avec PHP-CS-Fixer |
| `phpstan` | `$(EXEC) sh -c "bin/console cache:warmup --env=dev -q && vendor/bin/phpstan analyse"` | Analyse statique PHPStan (warmup cache pour le container XML) |
| `audit` | `$(EXEC) composer audit` | Audite les dépendances |
| `quality` | `lint phpstan test test-mutation audit` | Tous les checks qualité |
