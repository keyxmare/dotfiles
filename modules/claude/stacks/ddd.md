# Architecture DDD Strict

## Principes fondamentaux
- **Domain-Driven Design** strict avec architecture hexagonale (Ports & Adapters).
- Le domaine est le coeur de l'application. Il ne dépend de RIEN d'externe (ni Symfony, ni Doctrine, ni aucun framework).
- Toute dépendance pointe vers le domaine, jamais l'inverse.

## Structure par Bounded Context

```
src/
├── BoundedContext1/
│   ├── Domain/
│   │   ├── Model/
│   │   │   ├── Entity.php              ← Aggregate Root / Entity
│   │   │   ├── ValueObject.php         ← Value Objects (immutables)
│   │   │   └── Collection.php          ← Collections typées
│   │   ├── Event/
│   │   │   └── SomethingHappened.php   ← Domain Events
│   │   ├── Exception/
│   │   │   └── DomainException.php     ← Exceptions métier
│   │   ├── Repository/
│   │   │   └── EntityRepositoryInterface.php  ← Port (interface)
│   │   ├── Service/
│   │   │   └── DomainService.php       ← Logique métier cross-entity
│   │   └── Specification/
│   │       └── SomeSpecification.php   ← Règles métier réutilisables
│   │
│   ├── Application/
│   │   ├── Command/
│   │   │   ├── DoSomethingCommand.php      ← DTO immutable
│   │   │   └── DoSomethingCommandHandler.php
│   │   ├── Query/
│   │   │   ├── GetSomethingQuery.php       ← DTO immutable
│   │   │   └── GetSomethingQueryHandler.php
│   │   ├── DTO/
│   │   │   └── EntityDTO.php               ← Réponse applicative
│   │   ├── Port/
│   │   │   └── ExternalServiceInterface.php ← Port secondaire
│   │   └── EventHandler/
│   │       └── OnSomethingHappened.php
│   │
│   └── Infrastructure/
│       ├── Persistence/
│       │   ├── DoctrineEntityRepository.php  ← Adapter (implémente le port)
│       │   └── Mapping/
│       │       └── Entity.orm.xml            ← Mapping Doctrine XML
│       ├── Symfony/
│       │   ├── Controller/
│       │   │   └── EntityController.php
│       │   └── Form/
│       │       └── EntityType.php
│       ├── Adapter/
│       │   └── ExternalServiceAdapter.php    ← Adapter (implémente le port)
│       └── EventSubscriber/
│           └── DoctrineEventSubscriber.php
│
├── SharedKernel/
│   ├── Domain/
│   │   ├── ValueObject/
│   │   │   ├── Uuid.php
│   │   │   ├── Email.php
│   │   │   └── Money.php
│   │   └── Event/
│   │       └── DomainEventInterface.php
│   └── Infrastructure/
│       └── Bus/
│           └── MessengerCommandBus.php
```

## Couche Domain (aucune dépendance framework)
- **Entities** : identité propre, mutables via des méthodes métier explicites. Pas de setters publics.
- **Value Objects** : immutables, comparés par valeur. Utiliser `readonly class`. Valident leurs invariants dans le constructeur.
- **Aggregate Roots** : point d'entrée unique pour modifier un agrégat. Protègent les invariants.
- **Domain Events** : émis par les entités/agrégats quand un fait métier se produit. Simples DTO immutables.
- **Repository Interfaces** : interfaces définies dans le domaine. L'infrastructure les implémente.
- **Domain Services** : logique métier qui n'appartient pas naturellement à une entité.
- **Specifications** : encapsulent des règles métier réutilisables et composables.
- **INTERDIT dans le domaine** : aucun `use Symfony\...`, aucun `use Doctrine\...`, aucune annotation/attribut framework.

## Couche Application (orchestration)
- **CQRS** : séparer Commands (écriture) et Queries (lecture) via Symfony Messenger.
- **Command/Query** : DTO `readonly class` immutables. Un handler par command/query.
- **Handlers** : orchestrent les appels au domaine. Pas de logique métier ici.
- **Ports** : interfaces pour les services externes (mail, API tierces, storage...).
- **Pas d'accès direct** à Doctrine ou au framework. Passer par les interfaces.

## Couche Infrastructure (adapters)
- **Doctrine Repositories** : implémentent les interfaces du domaine.
- **Mapping Doctrine** : préférer le mapping XML (`*.orm.xml`) pour garder les entités du domaine pures (pas d'attributs Doctrine).
- **Controllers** : minimalistes. Désérialisent la requête → dispatchent un Command/Query → retournent la réponse.
- **Adapters** : implémentent les ports de la couche Application.

## Règles strictes
1. **Pas de setter** : les entités exposent des méthodes métier nommées (`publish()`, `cancel()`, `changeEmail()`).
2. **Pas d'anemic domain model** : la logique métier vit dans le domaine, pas dans les services applicatifs.
3. **Pas de couplage entre Bounded Contexts** : communiquer via des Domain Events ou un SharedKernel minimal.
4. **Pas d'héritage Doctrine** dans le domaine : les entités ne doivent pas étendre de classe Doctrine.
5. **Identifiants** : utiliser des Value Objects pour les IDs (ex: `UserId`, `OrderId`) plutôt que des `int` ou `string`.
6. **Nommage ubiquitaire** : les noms de classes, méthodes et variables reflètent le langage métier, pas le jargon technique.
7. **Un agrégat = une transaction** : ne pas modifier plusieurs agrégats dans la même transaction.
8. **Fail fast** : valider les invariants au plus tôt (constructeur des VO, méthodes métier des entités).
