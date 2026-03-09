# Stack — Symfony / CQRS & Messenger

> Implémentation Symfony des patterns définis dans [patterns-async.md](./patterns-async.md).

## CQRS avec Messenger

Implémentation Symfony des patterns CQRS définis dans [patterns-async.md](./patterns-async.md#cqrs--command-query-responsibility-segregation) :

- 3 bus Messenger séparés : `command.bus`, `query.bus`, `event.bus`.
- Middleware `command.bus` : validation, doctrine_transaction.
- Middleware `query.bus` : validation.
- Middleware `event.bus` : validation.
- Handlers déclarés via `#[AsMessageHandler]`.

### Configuration Messenger (3 buses)

```yaml
# config/packages/messenger.yaml
framework:
    messenger:
        default_bus: command.bus

        buses:
            command.bus:
                middleware:
                    - validation
                    - doctrine_transaction
            query.bus:
                middleware:
                    - validation
            event.bus:
                middleware:
                    - validation

        transports:
            async:
                dsn: '%env(MESSENGER_TRANSPORT_DSN)%'
                retry_strategy:
                    max_retries: 3
                    delay: 1000
                    multiplier: 2

        routing: {}
```

Les handlers sont associés au bon bus via l'attribut `#[AsMessageHandler]` avec le paramètre `bus` :

```php
#[AsMessageHandler(bus: 'command.bus')]
final readonly class CreateOrderCommandHandler { /* ... */ }

#[AsMessageHandler(bus: 'query.bus')]
final readonly class GetOrderByIdQueryHandler { /* ... */ }

#[AsMessageHandler(bus: 'event.bus')]
final readonly class SendOrderConfirmationHandler { /* ... */ }
```

### Outbox avec Messenger

Implémentation Symfony de l'[outbox pattern](./patterns-async.md#outbox-pattern). ← `patterns.outbox`

- Les events sont persistés dans une table `outbox` dans la même transaction Doctrine que l'opération métier.
- Un transport Messenger dédié (doctrine) consomme la table outbox et publie vers le broker (RabbitMQ, etc.).

## Endpoints de santé

Implémentation Symfony des [endpoints de santé](./api.md#endpoints-de-santé-observabilité) définis dans api.md :

```php
<?php declare(strict_types=1);

#[AsController]
#[Route('/healthz', methods: ['GET'])]
final readonly class HealthzController
{
    public function __invoke(): JsonResponse
    {
        return new JsonResponse(['status' => 'ok']);
    }
}
```

```php
<?php declare(strict_types=1);

#[AsController]
#[Route('/readyz', methods: ['GET'])]
final readonly class ReadyzController
{
    public function __construct(
        private Connection $connection,
    ) {}

    public function __invoke(): JsonResponse
    {
        $checks = [];

        try {
            $this->connection->executeQuery('SELECT 1');
            $checks['database'] = 'ok';
        } catch (\Throwable) {
            $checks['database'] = 'fail';
        }

        $allOk = !in_array('fail', $checks, true);

        return new JsonResponse(
            ['status' => $allOk ? 'ok' : 'degraded', 'checks' => $checks],
            $allOk ? 200 : 503,
        );
    }
}
```

Ces controllers sont placés dans `src/Shared/Infrastructure/Controller/` (DDD) ou `src/Controller/` (standard). Ils ne nécessitent pas d'authentification — configurer le firewall Symfony en conséquence.
