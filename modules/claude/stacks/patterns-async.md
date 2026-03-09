# Stack — Patterns asynchrones & résilience

> Patterns liés au messaging, à la résilience et à l'observabilité. Pour les patterns de base (SOLID, Repository, Value Objects, etc.), voir [patterns.md](./patterns.md).

## CQRS — Command Query Responsibility Segregation

### Principe

Séparer strictement les opérations d'écriture (commands) des opérations de lecture (queries). Cela permet d'optimiser, scaler et tester chaque côté indépendamment.

### Commands (write)

- Une command représente une intention de modification de l'état du système.
- Une command est un objet immutable (DTO) qui porte les données nécessaires à l'action.
- Un seul handler par command.
- Un handler ne retourne rien (ou uniquement un identifiant en cas de création).
- Les validations métier se font dans le domain, les validations de format dans la command.
- Le handler orchestre, il ne contient pas de logique métier.

```php
<?php declare(strict_types=1);

final readonly class CreateOrderCommand
{
    /**
     * @param list<OrderItemDto> $items
     */
    public function __construct(
        public CustomerId $customerId,
        public array $items,
    ) {}
}
```

```php
<?php declare(strict_types=1);

final readonly class CreateOrderCommandHandler
{
    public function __construct(
        private OrderRepositoryInterface $orderRepository,
        private EventBusInterface $eventBus,
    ) {}

    public function __invoke(CreateOrderCommand $command): string
    {
        $order = Order::create($command->customerId, $command->items);
        $this->orderRepository->save($order);
        $this->eventBus->dispatch(...$order->releaseEvents());

        return $order->id()->toString();
    }
}
```

### Queries (read)

- Une query représente une demande de données.
- Une query est un objet immutable (DTO) qui porte les critères de recherche.
- Un seul handler par query.
- Un handler retourne toujours un résultat (DTO, collection, ou null).
- Les queries ne modifient jamais l'état du système.
- Les queries peuvent bypasser le domain et lire directement depuis la persistence (read model) pour la performance.

```php
<?php declare(strict_types=1);

final readonly class GetOrderByIdQuery
{
    public function __construct(
        public OrderId $orderId,
    ) {}
}
```

```php
<?php declare(strict_types=1);

final readonly class GetOrderByIdQueryHandler
{
    public function __construct(
        private OrderReadModelInterface $readModel,
    ) {}

    public function __invoke(GetOrderByIdQuery $query): ?OrderDto
    {
        return $this->readModel->findById($query->orderId);
    }
}
```

### Events

- Un event représente un fait qui s'est produit dans le système (passé composé : UserRegistered, OrderPlaced).
- Un event est immutable.
- Zéro ou plusieurs handlers (subscribers) par event.
- Les events servent à déclencher des side effects (envoi d'email, synchronisation, analytics, etc.).
- Les events permettent la communication entre bounded contexts sans couplage direct.
- **Les events utilisent des types primitifs** (`string`, `int`, `array`) plutôt que des value objects. Raison : les events traversent les bounded contexts et doivent être sérialisables sans dépendance vers le domain émetteur.

```php
<?php declare(strict_types=1);

final readonly class OrderPlaced
{
    public function __construct(
        public string $orderId,
        public string $customerId,
        public \DateTimeImmutable $occurredAt = new \DateTimeImmutable(),
    ) {}
}
```

### Bus

Trois bus distincts avec des responsabilités claires :

| Bus | Responsabilité | Handlers | Retour | Middleware typique |
|---|---|---|---|---|
| Command bus | Écriture | 1 par command | Rien (ou ID) | Validation, transaction |
| Query bus | Lecture | 1 par query | Résultat | Validation |
| Event bus | Side effects | 0..n par event | Rien | Validation |

## Transactionalité

### Principe

Toute opération d'écriture passant par le command bus doit être atomique : tout réussit ou tout échoue. Pas d'état intermédiaire.

### Règles

- Le command bus wrappe chaque handler dans une transaction (middleware de transaction).
- Si le handler lève une exception, la transaction est rollback intégralement : persistence, events outbox, tout.
- Ne jamais committer manuellement dans un handler. C'est le middleware de transaction qui gère le commit/rollback.
- Les side effects non transactionnels (envoi d'email, appel API externe, publication sur broker) ne doivent jamais être exécutés dans la transaction. Ils passent par l'event bus ou l'outbox pattern, après le commit.
- Le query bus n'a pas de transaction : les lectures ne modifient pas l'état.
- L'event bus n'a pas de transaction propre : chaque subscriber gère sa propre unité de travail si nécessaire.

## Outbox pattern

← `patterns.outbox`

### Problème

Quand une opération doit à la fois persister un changement en base et publier un message (event, command) sur un broker (RabbitMQ, Kafka, etc.), il y a un risque d'incohérence : la base peut committer mais le message ne pas partir (ou l'inverse).

### Solution

L'outbox pattern garantit la cohérence entre la persistence et la messagerie :

1. **Écriture** — Dans la même transaction que l'opération métier, écrire le message à envoyer dans une table `outbox` en base de données.
2. **Publication** — Un process séparé (worker, cron, CDC) lit la table `outbox` et publie les messages sur le broker.
3. **Nettoyage** — Une fois le message publié et confirmé, le marquer comme traité ou le supprimer.

### Règles

- Le message est toujours persisté dans la même transaction que l'opération métier. Jamais de publish direct dans le handler.
- La table `outbox` contient au minimum : id, type, payload (JSON), created_at, processed_at.
- Le consumer outbox doit être idempotent : un message peut être publié plusieurs fois (at-least-once delivery).
- Les consumers qui reçoivent les messages doivent aussi être idempotents.

### Quand l'utiliser

- Dès qu'il y a de la messagerie asynchrone (events, commands async).
- Activé par défaut. Désactiver uniquement si le projet n'utilise pas de broker de messages.

## Circuit Breaker

### Problème

Un service externe lent ou down peut contaminer tout le système : threads bloqués, timeouts en cascade, saturation des ressources.

### Solution

Le circuit breaker monitore les appels et coupe le circuit après un seuil d'échecs consécutifs.

### États

| État | Comportement |
|---|---|
| **Closed** | Appels normaux. Compteur d'échecs incrémenté à chaque erreur. |
| **Open** | Tous les appels échouent immédiatement (fail fast). Timer de reset. |
| **Half-Open** | Un seul appel test est autorisé. Succès → Closed. Échec → Open. |

### Règles

- Seuil par défaut : 5 échecs consécutifs → ouverture.
- Durée d'ouverture : 30 secondes avant passage en half-open.
- Configurable par service externe.
- Logger chaque transition d'état.
- Retourner une réponse dégradée (cache, valeur par défaut) plutôt qu'une erreur quand le circuit est ouvert.

### Quand l'utiliser

- Appels HTTP vers des APIs tierces (paiement, email, notification).
- Requêtes vers des services internes potentiellement instables.

## Retry avec backoff exponentiel

### Principe

Les erreurs transitoires (timeout réseau, 503, lock BDD) se résolvent souvent d'elles-mêmes. Un retry avec délai croissant évite de surcharger le service en difficulté.

### Règles

- **Max retries** : 3 (défaut). Configurable par use case.
- **Délai initial** : 1 seconde.
- **Multiplicateur** : 2 (1s, 2s, 4s).
- **Jitter** : Ajouter un délai aléatoire (±20%) pour éviter les thundering herds.
- Ne retrier que les erreurs transitoires (5xx, timeout, connexion refusée). Jamais les 4xx (erreur client permanente).
- Logger chaque retry avec le numéro de tentative.

### Implémentation Symfony

Messenger gère nativement le retry via `retry_strategy` dans la config transport :

```yaml
transports:
    async:
        retry_strategy:
            max_retries: 3
            delay: 1000
            multiplier: 2
```

## Clé d'idempotence

### Problème

Les retries et les pannes réseau peuvent provoquer des doubles exécutions. Un paiement débité deux fois, une commande créée en double.

### Solution

Le client envoie une clé unique (`Idempotency-Key` header) à chaque requête. Le serveur vérifie si cette clé a déjà été traitée avant d'exécuter l'opération.

### Règles

- Stocker les clés traitées avec leur résultat (table `idempotency_keys` : key, response, created_at, expires_at).
- TTL : 24h minimum (configurable).
- Si la clé existe déjà : retourner le résultat précédent sans ré-exécuter.
- Vérification et insertion dans la même transaction que l'opération métier.
- Obligatoire sur les endpoints de création impliquant un effet de bord irréversible (paiement, envoi d'email).

### Quand l'utiliser

- Endpoints de paiement.
- Création de ressources avec side effects.
- Toute opération non-idempotente exposée à des retries client.

## Saga

### Problème

Une opération métier implique plusieurs bounded contexts ou services. La transaction distribuée classique (2PC) est fragile et ne scale pas.

### Solution

Le saga pattern orchestre une séquence d'opérations locales. Chaque étape est une transaction locale. En cas d'échec, des **compensations** sont exécutées pour annuler les étapes précédentes.

### Types

| Type | Orchestration | Communication |
|---|---|---|
| **Choreography** | Décentralisée — chaque service écoute les events et réagit | Events |
| **Orchestration** | Centralisée — un orchestrateur coordonne les étapes | Commands |

### Règles

- Chaque étape a une action et une compensation associée.
- Les compensations sont idempotentes.
- Logger chaque étape et chaque compensation pour auditabilité.
- Timeout global sur la saga (ex: 5 min). Si dépassé, déclencher les compensations.
- Préférer la chorégraphie pour les cas simples (2-3 étapes). L'orchestration pour les flux complexes (>3 étapes).

### Quand l'utiliser

- Processus de commande : réserver stock → débiter paiement → confirmer expédition.
- Inscription utilisateur multi-service : créer compte → configurer permissions → envoyer email.
- Toute opération cross-bounded-context nécessitant une cohérence éventuelle.

## Observabilité

### Principes

L'observabilité repose sur trois piliers : **logs**, **métriques** et **traces**. Les logs sont couverts dans [patterns.md](./patterns.md#logging). Cette section couvre les métriques et traces.

### OpenTelemetry

Standard open-source pour l'instrumentation. Fournit des SDKs pour collecter traces, métriques et logs de manière unifiée.

| Stack | Package |
|---|---|
| PHP / Symfony | `open-telemetry/opentelemetry-auto-symfony` |
| Node / Nuxt | `@opentelemetry/sdk-node` |

### Traces distribuées

- Chaque requête entrante génère un **trace ID** unique propagé entre services.
- Chaque opération significative (appel BDD, appel HTTP, job async) crée un **span** rattaché au trace.
- Propager le trace ID via le header `traceparent` (standard W3C).
- Instrumenter automatiquement via les auto-instrumentation SDKs.

### Correlation ID

- Chaque requête entrante reçoit un `X-Correlation-ID` (ou réutilise celui du client).
- Ce correlation ID est propagé dans tous les logs, spans et messages async.
- Permet de tracer une opération de bout en bout à travers les services.

### Métriques

Métriques à exposer par défaut (format Prometheus) :

| Métrique | Type | Description |
|---|---|---|
| `http_requests_total` | Counter | Nombre total de requêtes HTTP par status/method/route |
| `http_request_duration_seconds` | Histogram | Latence des requêtes HTTP |
| `db_query_duration_seconds` | Histogram | Latence des requêtes BDD |
| `messenger_messages_total` | Counter | Messages traités par type/status |

### Quand l'utiliser

- Tout projet avec plus d'un service (backend + worker, micro-services).
- Optionnel mais recommandé pour les monolithes (facilite le debugging et le capacity planning).

## Quand appliquer

| Pattern | Quand l'utiliser |
|---|---|
| CQRS | Dès qu'il y a des opérations de lecture et d'écriture distinctes |
| Outbox | Dès qu'il y a de la messagerie asynchrone |
| Circuit Breaker | Appels vers des services externes |
| Retry + backoff | Erreurs transitoires (réseau, 5xx, locks) |
| Idempotency Key | Opérations non-idempotentes avec side effects irréversibles |
| Saga | Transactions cross-bounded-context |
| Observabilité | Tout projet multi-service, recommandé pour les monolithes |
