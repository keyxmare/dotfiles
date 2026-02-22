# Stack Messenger / Async

## Symfony Messenger

### Architecture avec DDD
- Les Domain Events sont dispatchés via Symfony Messenger.
- Séparer les bus : `command.bus` (sync), `query.bus` (sync), `event.bus` (async).
- Les Commands et Queries sont toujours synchrones. Seuls les Domain Events sont asynchrones.

### Transports
- **Développement** : transport `doctrine` ou `in-memory` pour simplifier.
- **Production** : RabbitMQ ou Redis selon les besoins.
- Un transport par type de message si des SLA différents sont nécessaires.

### Structure
```
Application/
├── Command/
│   ├── CreateOrderCommand.php          ← sync via command.bus
│   └── CreateOrderCommandHandler.php
├── Query/
│   ├── GetOrderQuery.php               ← sync via query.bus
│   └── GetOrderQueryHandler.php
└── EventHandler/
    ├── SendConfirmationOnOrderCreated.php   ← async via event.bus
    └── UpdateStockOnOrderCreated.php        ← async via event.bus
```

### Domain Events
- Émis par l'Aggregate Root via `record()` / `releaseEvents()`.
- Dispatchés après le flush Doctrine (via un EventSubscriber Doctrine `postFlush`).
- Un Domain Event = un fait passé immutable : `OrderCreated`, `PaymentReceived`.
- Nommage : passé composé, langage métier.
- Un event peut avoir N handlers dans N Bounded Contexts différents.

### Retries & Dead Letter
- Configurer une stratégie de retry avec backoff exponentiel.
- Définir un transport `failed` (dead letter) pour les messages en échec.
- Logger chaque échec avec le contexte complet.
- Ne jamais perdre un message silencieusement.

```yaml
# config/packages/messenger.yaml
framework:
    messenger:
        failure_transport: failed
        transports:
            async:
                dsn: '%env(MESSENGER_TRANSPORT_DSN)%'
                retry_strategy:
                    max_retries: 3
                    delay: 1000
                    multiplier: 2
            failed:
                dsn: 'doctrine://default?queue_name=failed'
```

### Règles
- Un handler fait UNE chose. Pas de handler qui orchestre 5 actions.
- Les handlers async doivent être idempotents (re-exécutables sans effet de bord).
- Ne jamais passer d'entités dans un message. Passer des IDs et recharger dans le handler.
- Tester les handlers async avec des tests d'intégration.
- Monitorer la file d'attente : taille, temps de traitement, taux d'échec.
