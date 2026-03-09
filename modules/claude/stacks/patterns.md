# Stack — Patterns d'architecture

## Principe

Ce fichier définit les patterns d'architecture transverses, indépendants de la stack technologique. Chaque stack spécifique (Symfony, Nuxt, etc.) implémente ces patterns avec ses propres outils.

En mode avancé (`profile` = `advanced`), tous les patterns de ce fichier sont systématiquement appliqués.

## SOLID

Fondation de tout code extensible. Ces principes s'appliquent systématiquement.

### Single Responsibility (SRP)

- Une classe / un module a une seule raison de changer.
- Un handler gère une seule command. Un service résout un seul problème.
- Si une classe a besoin de plus de 3-4 dépendances, c'est un signal qu'elle fait trop de choses.

### Open/Closed (OCP)

- Ouvert à l'extension, fermé à la modification.
- Ajouter un comportement ne doit pas nécessiter de modifier le code existant.
- Utiliser des interfaces, des Strategy, des Decorator pour étendre.

### Liskov Substitution (LSP)

- Une sous-classe doit pouvoir remplacer sa classe parente sans casser le comportement.
- Ne pas utiliser l'héritage pour partager du code — préférer la composition.

### Interface Segregation (ISP)

- Préférer plusieurs interfaces petites et spécifiques à une grosse interface générique.
- Un client ne doit pas dépendre de méthodes qu'il n'utilise pas.
- Découper les interfaces par rôle : `Readable`, `Writable`, `Deletable` plutôt qu'un seul `Repository`.

### Dependency Inversion (DIP)

- Les modules de haut niveau (Domain, Application) ne dépendent pas des modules de bas niveau (Infrastructure).
- Les deux dépendent d'abstractions (interfaces).
- C'est le fondement de l'architecture hexagonale (ports & adapters).

## CQRS, Transactionalité, Outbox, Résilience & Observabilité

→ Voir [patterns-async.md](./patterns-async.md) pour les patterns CQRS, bus, transactionalité, outbox, circuit breaker, retry, idempotency key, saga et observabilité (OpenTelemetry).

## Patterns complémentaires

### Repository pattern

- Les repositories sont des interfaces définies dans le domain (ports).
- L'infrastructure fournit les implémentations concrètes (adapters).
- Un repository par agrégat.
- Les méthodes du repository manipulent des objets du domain, jamais des tableaux ou des structures brutes.

```php
<?php declare(strict_types=1);

interface OrderRepositoryInterface
{
    public function save(Order $order): void;

    public function findById(OrderId $id): ?Order;

    public function remove(Order $order): void;
}
```

### Value Objects

- Immutables, sans identité. Comparés par valeur.
- Utilisés pour encapsuler les règles de validation et de formatage (Email, Money, Uuid, etc.).
- Privilégier les value objects aux types primitifs pour les concepts métier.

```php
<?php declare(strict_types=1);

final readonly class Email
{
    public function __construct(public string $value)
    {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email: {$value}");
        }
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }
}
```

### Domain Events

- Émis par les agrégats quand un changement d'état significatif se produit.
- Collectés par l'agrégat, dispatchés après la persistence.
- Nommés au passé composé : `OrderPlaced`, `UserRegistered`, `PaymentReceived`.
- Portent les données nécessaires aux subscribers, pas l'entité entière.

### Specification pattern

- Encapsule une règle métier dans un objet réutilisable et composable.
- Utilisé pour les critères de filtrage complexes dans les repositories.
- Composable via `and()`, `or()`, `not()`.

```php
<?php declare(strict_types=1);

/** @template T */
interface SpecificationInterface
{
    /** @param T $candidate */
    public function isSatisfiedBy(mixed $candidate): bool;
}
```

```php
<?php declare(strict_types=1);

final readonly class OrderIsOverdue implements SpecificationInterface
{
    public function __construct(
        private \DateTimeImmutable $referenceDate = new \DateTimeImmutable(),
    ) {}

    public function isSatisfiedBy(mixed $candidate): bool
    {
        assert($candidate instanceof Order);

        return $candidate->dueDate() < $this->referenceDate
            && !$candidate->isPaid();
    }
}
```

L'interface `SpecificationInterface` utilise `mixed` pour rester générique. PHPStan assure le typage via `@template T`. Alternative : typer par agrégat avec une interface dédiée (`OrderSpecificationInterface::isSatisfiedBy(Order $candidate)`) pour un typage strict à la compilation. Ne jamais narrower le type du paramètre dans l'implémentation — PHP 8 lève une fatal error.

## Patterns d'extensibilité

### Strategy

- Permet de définir une famille d'algorithmes interchangeables derrière une interface commune.
- Le choix de l'implémentation se fait à l'injection (configuration, runtime).
- Exemple : `PaymentProcessor` avec des implémentations `StripePayment`, `PaypalPayment`, `BankTransferPayment`.
- Utiliser quand un comportement a plusieurs variantes et que de nouvelles variantes sont prévisibles.

### Decorator

- Permet d'ajouter des responsabilités à un objet sans modifier sa classe.
- L'objet décoré et le décorateur implémentent la même interface.
- Exemple : `LoggingCommandBus` qui wrappe un `CommandBus` pour ajouter du logging, `CachingRepository` qui wrappe un `Repository`.
- Chaînable : plusieurs décorateurs peuvent s'empiler.
- Utiliser pour les préoccupations transverses (logging, caching, retry, metrics).

### Factory

- Centralise la création d'objets complexes.
- Encapsule la logique de construction et les dépendances nécessaires.
- Utiliser quand la création d'un objet nécessite de la logique conditionnelle ou plusieurs étapes.
- Favoriser les Factory Methods (méthodes statiques nommées sur l'objet) pour les cas simples : `Order::createFromCart(cart)`.
- Utiliser des Abstract Factory pour les familles d'objets liés.

### Ports & Adapters (Hexagonal)

- Le domain définit des **ports** (interfaces) pour tout ce dont il a besoin du monde extérieur.
- L'infrastructure fournit des **adapters** (implémentations) pour ces ports.
- Permet de changer d'infrastructure (BDD, API externe, broker) sans toucher au domain.
- Chaque adapter est testable et remplaçable indépendamment.
- Déjà implicite dans la structure DDD. Ce pattern le formalise.

### Anti-corruption layer (ACL)

- Couche de traduction entre un bounded context et un système externe (API tierce, legacy, autre contexte).
- Protège le domain des modèles et conventions externes.
- Traduit les données entrantes dans les value objects et entités du domain.
- Traduit les données sortantes dans le format attendu par le système externe.
- Utiliser systématiquement pour les intégrations tierces (paiement, shipping, CRM, etc.).

## Logging

### Principes

- Logger sur `stderr`, réserver `stdout` pour les données (applicable surtout aux CLI/scripts).
- Utiliser du structured logging (JSON) pour faciliter l'agrégation et l'analyse.
- Ne jamais logger de données sensibles (mots de passe, tokens, PII).

### Champs obligatoires

| Champ | Description |
|---|---|
| `timestamp` | ISO 8601 avec timezone |
| `level` | `debug`, `info`, `warning`, `error`, `critical` |
| `message` | Description courte de l'événement |
| `context` | Données structurées associées (user_id, request_id, etc.) |
| `correlation_id` | Identifiant de traçabilité partagé entre services (si applicable) |

### Niveaux de log

| Niveau | Usage |
|---|---|
| `debug` | Développement uniquement, jamais en production |
| `info` | Événements normaux (requête traitée, job exécuté) |
| `warning` | Situation anormale mais non bloquante (retry, deprecation) |
| `error` | Erreur récupérable (requête échouée, service indisponible) |
| `critical` | Erreur irrécupérable nécessitant une intervention immédiate |

### Outils par stack

| Stack | Outil |
|---|---|
| PHP / Symfony | Monolog (`monolog-bundle`) |
| Node / Nuxt | consola (intégré Nuxt), pino (recommandé hors Nuxt) |

## Quand appliquer

| Pattern | Quand l'utiliser |
|---|---|
| SOLID | Toujours. Fondation de tout code. |
| Strategy | Quand un comportement a plusieurs variantes actuelles ou prévisibles. |
| Decorator | Pour les préoccupations transverses (logging, caching, retry). |
| Factory | Quand la création d'un objet est complexe ou conditionnelle. |
| Ports & Adapters | Toujours en DDD. Formalise l'isolation du domain. |
| ACL | À chaque intégration avec un système externe. |
| Repository | Toujours en DDD. Un par agrégat. |
| Specification | Pour les critères de filtrage complexes et composables. |
| Logging structuré | Toujours. Fondation de l'observabilité. |

→ Patterns async (CQRS, Outbox, Circuit Breaker, Saga, etc.) : [patterns-async.md](./patterns-async.md#quand-appliquer)
