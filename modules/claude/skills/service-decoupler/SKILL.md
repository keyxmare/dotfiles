---
name: service-decoupler
description: Détecter les services Symfony avec trop de dépendances (violation SRP) et proposer un plan de découpage. Utiliser quand l'utilisateur veut auditer le couplage de ses services, réduire les dépendances, identifier les god services, ou nettoyer des services trop chargés.
argument-hint: [scope] [--bc=<name>] [--threshold=5] [--type=all|constructor|methods|concerns|lines] [--output=report|json] [--summary] [--resume] [--full]
---

# Service Decoupler — Détection SRP et plan de découpage

Tu es un expert en conception orientée objet et en architecture DDD/Symfony. Tu analyses les services d'un projet pour détecter ceux qui violent le Single Responsibility Principle (SRP) — trop de dépendances, trop de méthodes, trop de préoccupations mélangées — et tu proposes un plan de découpage actionnable.

## Arguments

- `$ARGUMENTS` : scope optionnel (dossier, Bounded Context, ou fichier spécifique). Si vide, analyser tout `src/`.
- `--threshold=<N>` : seuil de dépendances constructeur à partir duquel un service est signalé. Défaut : `5`.
- `--type=<type>` : filtrer le type de violation à détecter :
  - `all` (défaut) : toutes les catégories
  - `constructor` : services avec trop de dépendances constructeur
  - `methods` : services avec trop de méthodes publiques
  - `concerns` : services mêlant plusieurs préoccupations
  - `lines` : services trop longs (god classes)
- `--output=<format>` :
  - `report` (défaut) : rapport Markdown structuré
  - `json` : sortie JSON pour traitement automatisé
- `--summary` : si présent, produire uniquement un résumé compact (nombre de god services + top 5 + score SRP) au lieu du rapport complet. Utile pour un aperçu rapide ou un suivi régulier.

## Phase 0 — Chargement du contexte

**OBLIGATOIRE** avant toute analyse :

1. **Appliquer `~/.claude/stacks/skill-directives.md` Phase 0** (contexte global + docs projet + stacks).
2. Charger les stacks spécifiques : `ddd.md`, `symfony.md`
   - Avec Messenger → charger aussi `messenger.md`
3. Identifier la structure du projet :
   - Lister `src/` pour détecter les Bounded Contexts.
   - Identifier la structure des couches (Domain, Application, Infrastructure).
   - Lister `config/services.yaml` pour les services déclarés explicitement.
   - Vérifier `composer.json` pour les dépendances clés.

## Prérequis recommandés

| Skill | Pourquoi avant service-decoupler |
|-------|----------------------------------|
| `/dependency-diagram` | Cartographier les dépendances inter-BC pour contextualiser les plans de découpage |

Exploitation cross-skill : voir `skill-directives.md`.

## Phase 1 — Inventaire des services

Avant de détecter les violations, construire un **inventaire exhaustif** de tous les services du projet. Scanner toutes les classes PHP dans le scope demandé.

### 1.1 Identification des services

Un service est toute classe PHP qui :

- Est dans le scope de l'autodiscovery Symfony (`services.yaml` → `resource:`)
- OU est déclarée explicitement dans `services.yaml` / `services/*.yaml`
- OU possède l'attribut `#[AsService]` ou `#[Autoconfigure]`
- OU est autoconfigurable par tag (handlers, listeners, voters, etc.)

**Exclure** :
- Entités/Agrégats (`Domain/Model/`)
- Value Objects
- DTOs / Commands / Queries (classes de données)
- Enums
- Interfaces
- Domain Events
- Exceptions
- Migrations et Fixtures
- Tests

### 1.2 Extraction des métriques par service

Pour chaque service identifié, extraire :

#### A. Dépendances constructeur

Lire le constructeur et compter les paramètres injectés :

```php
public function __construct(
    private readonly ProductRepositoryInterface $productRepository,  // 1
    private readonly CategoryRepositoryInterface $categoryRepository, // 2
    private readonly EventDispatcherInterface $eventDispatcher,       // 3
    private readonly LoggerInterface $logger,                         // 4
    private readonly MailerInterface $mailer,                         // 5
    private readonly TranslatorInterface $translator,                 // 6
    private readonly CacheInterface $cache,                           // 7
    private readonly MessageBusInterface $messageBus,                 // 8
) {}
// → 8 dépendances = signal SRP fort
```

Pour chaque dépendance, enregistrer :
- Nom de la variable
- Type (FQCN ou interface)
- Catégorie fonctionnelle (voir section 1.3)
- Couche d'origine (Domain, Application, Infrastructure, Framework)

**Ignorer dans le comptage** :
- `LoggerInterface` (cross-cutting concern accepté)
- `string $parameterName` (paramètres scalaires de config)

#### B. Méthodes publiques

Compter les méthodes publiques (hors constructeur et méthodes magiques). Plus une classe a de méthodes publiques, plus elle a de responsabilités :

| Seuil | Niveau |
|-------|--------|
| 1-3 | Normal |
| 4-7 | Attention |
| 8+ | Violation probable |

#### C. Longueur du fichier

| Seuil | Niveau |
|-------|--------|
| < 100 lignes | Normal |
| 100-200 lignes | Attention |
| 200-300 lignes | Warning |
| 300+ lignes | God class |

#### D. Complexité cyclomatique estimée

Compter les branches de décision (if, match, switch, foreach, while, try/catch, ternaires, ??) pour estimer la complexité globale.

### 1.3 Classification fonctionnelle des dépendances

Catégoriser chaque dépendance injectée par **préoccupation fonctionnelle** :

| Catégorie | Pattern de détection | Exemples |
|-----------|---------------------|----------|
| `persistence` | `*RepositoryInterface`, `EntityManagerInterface`, `Connection` | `ProductRepositoryInterface`, `OrderRepositoryInterface` |
| `messaging` | `MessageBusInterface`, `*BusInterface` | `$commandBus`, `$queryBus`, `$eventBus` |
| `notification` | `MailerInterface`, `NotifierInterface`, `*Notifier` | `$mailer`, `$smsNotifier` |
| `eventing` | `EventDispatcherInterface` | `$eventDispatcher` |
| `caching` | `CacheInterface`, `CacheItemPoolInterface`, `*Cache` | `$cache`, `$redisCache` |
| `logging` | `LoggerInterface` | `$logger` |
| `security` | `Security`, `AuthorizationCheckerInterface`, `TokenStorageInterface` | `$security` |
| `validation` | `ValidatorInterface` | `$validator` |
| `serialization` | `SerializerInterface`, `NormalizerInterface` | `$serializer` |
| `translation` | `TranslatorInterface` | `$translator` |
| `http` | `HttpClientInterface`, `RequestStack` | `$httpClient` |
| `filesystem` | `FilesystemInterface`, `Filesystem` | `$filesystem` |
| `domain_service` | Classes du même BC dans `Domain/Service/` | `$pricingService` |
| `application_service` | Classes du même BC dans `Application/` | `$productFinder` |
| `cross_bc` | Classes d'un autre Bounded Context | `$inventoryChecker` |
| `configuration` | Paramètres scalaires, `ParameterBagInterface` | `$defaultLocale`, `$apiKey` |

### 1.4 Détection des groupes de préoccupations

Pour chaque service, grouper les dépendances par catégorie et identifier les **clusters fonctionnels** :

```
ProductService:
  Cluster 1 (CRUD): $productRepository, $categoryRepository
  Cluster 2 (Notification): $mailer, $translator
  Cluster 3 (Cache): $cache
  Cluster 4 (Search): $elasticClient, $searchIndexer
```

**Règle** : si un service a **3 clusters fonctionnels ou plus** (hors logging), c'est un signal SRP fort.

## Phase 2 — Détection des violations SRP

### 2.1 Violation par nombre de dépendances

Un service viole potentiellement le SRP quand il a trop de dépendances constructeur.

| Seuil (configurable via `--threshold`) | Niveau | Action |
|-------|--------|--------|
| 1-4 | OK | Rien à signaler |
| 5-6 | `warning` | Examiner les clusters de préoccupations |
| 7-8 | `high` | Découpage recommandé |
| 9+ | `critical` | Découpage urgent |

**Ajustements** :
- Si le service est un **Controller** : les controllers injectent naturellement plus de dépendances (command/query bus, serializer, etc.). Seuil ajusté : +2.
- Si le service est un **CompilerPass** ou un **Kernel listener** : exclure (pattern différent).
- Si le service est un **Command Handler** ou **Query Handler** : un handler devrait avoir peu de dépendances (1-3). Seuil ajusté : -2.

### 2.2 Violation par méthodes publiques excessives

Un service avec trop de méthodes publiques est un signe de responsabilités multiples :

| Indicateur | Détection |
|-----------|-----------|
| > 7 méthodes publiques | Violation SRP probable |
| Méthodes sans rapport sémantique | Nommage divergent (`createProduct()`, `sendNotification()`, `validateOrder()`) |
| Méthodes utilisées par des consommateurs différents | Un controller utilise `methodA`, un handler utilise `methodB` |

### 2.3 Violation par mélange de préoccupations

Analyser le **corps des méthodes** pour détecter les préoccupations mélangées :

| Pattern | Violation |
|---------|-----------|
| Persistence + Notification dans la même méthode | Oui — séparer le side effect |
| Validation + Business logic + Persistence | Oui — classique fat service |
| HTTP call + Domain logic | Oui — l'appel HTTP doit être derrière un port |
| Cache read + Cache write + Business logic | Peut-être — le caching peut être un decorator |
| Logging partout | Non — cross-cutting concern accepté |

**Détection heuristique** : pour chaque méthode, lister les dépendances du constructeur effectivement utilisées. Si une méthode utilise des dépendances de clusters différents, c'est un signal.

### 2.4 Violation par accès cross-BC

Un service qui injecte des dépendances de **plusieurs Bounded Contexts** est un signe :
- Soit d'un service mal placé (il devrait être dans un autre BC)
- Soit d'une logique d'orchestration qui devrait être un Saga ou un Event Handler
- Soit d'un couplage trop fort entre BC

**Détection** : vérifier le namespace de chaque dépendance injectée et compter les BC distincts.

| BCs référencés | Niveau |
|----------------|--------|
| 1 | Normal |
| 2 | Acceptable (si l'un est Shared) |
| 3+ | Violation — couplage excessif |

### 2.5 Violation par god class

Un fichier > 300 lignes avec un constructeur chargé est presque certainement une violation SRP :

| Critère | Seuil |
|---------|-------|
| Lignes de code | > 300 |
| Dépendances constructeur | > 5 |
| Méthodes publiques | > 5 |
| Score combiné (lignes/100 + deps + méthodes) | > 15 |

### 2.6 Détection des patterns spécifiques

#### A. Service "orchestrateur"

Un service qui fait de l'orchestration procédurale (étape 1 → étape 2 → étape 3) devrait souvent être un **Command Handler** avec des Domain Events pour les side effects :

```php
// AVANT — orchestrateur procedural
public function processOrder(Order $order): void
{
    $this->validator->validate($order);            // Step 1
    $this->orderRepository->save($order);          // Step 2
    $this->paymentGateway->charge($order);         // Step 3
    $this->mailer->sendConfirmation($order);       // Step 4
    $this->inventoryService->decrementStock($order); // Step 5
    $this->analyticsService->track('order_placed'); // Step 6
}
```

**Signal** : méthode qui appelle > 3 dépendances en séquence.

#### B. Service "facade"

Un service qui délègue tout à d'autres services sans ajouter de logique :

```php
public function getProduct(string $id): ProductDTO
{
    return $this->productRepository->findById($id);  // Delegation pure
}
```

**Signal** : méthodes one-liner qui ne font que relayer.

#### C. Service "switchboard"

Un service avec des méthodes conditionnelles qui routent vers des traitements différents :

```php
public function process(string $type, array $data): void
{
    match($type) {
        'email' => $this->mailer->send(...),
        'sms' => $this->smsNotifier->send(...),
        'push' => $this->pushService->send(...),
    };
}
```

**Signal** : `match` ou `switch` avec des appels à des dépendances différentes → extraire en Strategy pattern.

## Phase 3 — Plan de découpage

Pour chaque service en violation, proposer un plan de découpage concret.

### 3.1 Stratégies de découpage

#### Stratégie 1 — Extraction par préoccupation (la plus courante)

Séparer un service en plusieurs services, chacun responsable d'une seule préoccupation :

```
OrderService (8 deps) → DECOUPE EN :
  ├── CreateOrderCommandHandler (2 deps: orderRepo, validator)
  ├── SendOrderConfirmationHandler (2 deps: mailer, translator)
  ├── DecrementStockOnOrderPlaced (1 dep: inventoryRepo)
  └── TrackOrderAnalytics (1 dep: analyticsClient)
```

**Quand l'utiliser** : le service mêle persistence, notification, side effects.

#### Stratégie 2 — Extraction vers Domain Events

Déplacer les side effects en Event Handlers asynchrones :

```
OrderService.processOrder()
  └── persist() + raise(OrderPlaced)
        ├── [async] SendConfirmationOnOrderPlaced
        ├── [async] DecrementStockOnOrderPlaced
        └── [async] TrackAnalyticsOnOrderPlaced
```

**Quand l'utiliser** : le service a un flux linéaire avec des étapes indépendantes après l'action principale.

#### Stratégie 3 — Extraction vers CQRS

Séparer les responsabilités de lecture et d'écriture :

```
ProductService (lecture + ecriture) → DECOUPE EN :
  ├── CreateProductCommandHandler (ecriture)
  ├── UpdateProductCommandHandler (ecriture)
  ├── GetProductQueryHandler (lecture)
  └── ListProductsQueryHandler (lecture)
```

**Quand l'utiliser** : le service a des méthodes de lecture ET d'écriture.

#### Stratégie 4 — Extraction vers Decorator

Isoler une préoccupation transversale (caching, logging, métriques) dans un decorator :

```
ProductRepository (cache inline) → DECOUPE EN :
  ├── ProductRepositoryInterface
  ├── DoctrineProductRepository (implements interface)
  └── CachedProductRepository (decorator, implements interface)
```

**Quand l'utiliser** : le caching ou une préoccupation transversale est mélangée avec la logique principale.

#### Stratégie 5 — Extraction vers Strategy/Chain

Remplacer un switchboard par un pattern Strategy ou Chain of Responsibility :

```
NotificationService (switch type) → DECOUPE EN :
  ├── NotificationChannelInterface
  ├── EmailNotificationChannel
  ├── SmsNotificationChannel
  ├── PushNotificationChannel
  └── NotificationDispatcher (itere sur les channels tagges)
```

**Quand l'utiliser** : le service route conditionnellement vers des implémentations différentes.

#### Stratégie 6 — Extraction de Domain Service

Déplacer la logique métier pure (calculs, règles, invariants) dans un Domain Service :

```
OrderApplicationService:
  - calculateDiscount() → OrderPricingService (Domain)
  - validateOrder() → OrderValidator (Domain/Specification)
  - processPayment() → PaymentGatewayInterface (Domain port)
```

**Quand l'utiliser** : le service applicatif contient de la logique métier qui devrait être dans le Domain.

### 3.2 Format du plan de découpage

Pour chaque service en violation, produire :

```markdown
### [ServiceName] — Score: X/10

**Localisation** : `src/<BC>/Application/Service/OrderService.php`
**Bounded Context** : Order
**Couche** : Application

#### Métriques actuelles
| Métrique | Valeur | Seuil | Statut |
|----------|--------|-------|--------|
| Dépendances constructeur | 8 | 5 | critical |
| Méthodes publiques | 6 | 7 | warning |
| Lignes de code | 280 | 300 | warning |
| Clusters de préoccupations | 4 | 3 | high |
| BCs référencés | 2 | 2 | ok |

#### Dépendances actuelles
| # | Dépendance | Catégorie | Cluster | Utilisée par |
|---|-----------|-----------|---------|-------------|
| 1 | ProductRepositoryInterface | persistence | CRUD | create(), update(), delete() |
| 2 | CategoryRepositoryInterface | persistence | CRUD | create(), update() |
| 3 | EventDispatcherInterface | eventing | Events | create(), delete() |
| 4 | MailerInterface | notification | Notif | create() |
| 5 | TranslatorInterface | translation | Notif | create() |
| 6 | CacheInterface | caching | Cache | findById(), list() |
| 7 | ValidatorInterface | validation | Validation | create(), update() |
| 8 | MessageBusInterface | messaging | CQRS | — |

#### Clusters identifiés
```
Cluster 1 — CRUD Persistence : $productRepository, $categoryRepository
Cluster 2 — Notification : $mailer, $translator
Cluster 3 — Caching : $cache
Cluster 4 — Validation : $validator
```

#### Stratégie recommandée : Extraction par préoccupation + Domain Events

#### Arborescence cible

```
src/Order/
  Application/
    Command/
      CreateOrderCommand.php           ← NEW
      CreateOrderCommandHandler.php    ← NEW (cluster CRUD + validation)
      UpdateOrderCommand.php           ← NEW
      UpdateOrderCommandHandler.php    ← NEW
    Query/
      GetOrderQuery.php                ← NEW
      GetOrderQueryHandler.php         ← NEW
    EventHandler/
      SendConfirmationOnOrderCreated.php  ← NEW (cluster Notif)
  Infrastructure/
    Persistence/
      CachedOrderRepository.php        ← NEW (decorator, cluster Cache)
  OrderService.php                     ← DELETE apres migration
```

#### Impact
- Fichiers à créer : 7
- Fichiers à modifier : 2 (controllers qui injectent OrderService)
- Fichiers à supprimer : 1 (OrderService)
- Dépendances max par nouveau service : 3
```

## Phase 4 — Rapport

### Format du rapport

**Consulter `references/report-template.md`** pour le template complet du rapport Markdown et JSON.

Le rapport doit inclure :
- Résumé (services analysés, violations par sévérité, god classes, stats de dépendances)
- Classement par sévérité (critique, haute, warning) avec métriques
- Plans de découpage détaillés par service
- Distribution des dépendances (histogramme)
- Top 10 des dépendances les plus injectées
- Métriques par Bounded Context
- Anti-patterns globaux détectés
- Plan de refactorisation global avec estimation d'effort

## Phase 5 — Découpage assisté (optionnel)

**Seulement si l'utilisateur le demande explicitement.** Ne jamais découper de service automatiquement.

### Processus de découpage

1. **Présenter le rapport** et attendre la validation de l'utilisateur.
2. **Demander confirmation** pour chaque service à découper (commencer par les critiques).
3. **Découper par lots** :
   - Créer les nouveaux fichiers (Command/Handler, Event Handler, Decorator, etc.)
   - Modifier les services consommateurs (controllers, handlers qui injectent le service d'origine)
   - Mettre à jour `services.yaml` si nécessaire (bindings, alias, decorators)
   - Supprimer le service d'origine une fois la migration complète
4. **Vérifier après chaque lot** :
   - Exécuter `make phpstan` pour détecter les erreurs de type.
   - Exécuter `make test` pour s'assurer que rien n'est cassé.
   - Exécuter `make cs-fix` pour nettoyer le code style.
   - Vider le cache (`make cache`).
5. **Mettre à jour les tests** :
   - Adapter les tests existants du service d'origine aux nouveaux services.
   - Créer les tests manquants pour les nouveaux services.

### Commits

Proposer un commit par service découpé :
```
refactor(order): split OrderService into CQRS handlers and event handlers
refactor(catalog): extract notification concern from ProductService
refactor(infra): replace EntityManager injection with repository interfaces
chore: remove deprecated OrderService after CQRS migration
```

## Skills complémentaires

Selon les résultats de l'analyse, suggérer à l'utilisateur :

| Si... | Alors suggérer |
|-------|---------------|
| God services avec logique CRUD | `/extract-to-cqrs` pour migrer vers CQRS |
| Dépendances cross-BC excessives | `/dependency-diagram` pour cartographier |
| Score legacy inconnu | `/full-audit` pour un audit global |
| Code mort dans les services découpés | `/dead-code-detector` pour nettoyer |

## Phase Finale — Mise à jour documentaire (OBLIGATOIRE)

Appliquer les obligations de `~/.claude/stacks/skill-directives.md` (Phase Finale).

## Directives

Appliquer les directives communes de `skill-directives.md`.

Directives spécifiques à ce skill :
- **Respecter le seuil configuré** : le seuil par défaut (5) peut être ajusté par l'utilisateur. Un seuil de 3 est strict, un seuil de 7 est permissif.
- **Contextualiser** : un handler avec 4 deps est plus suspect qu'un controller avec 4 deps. Adapter l'analyse au type de service.
- **Pas de sur-ingénierie** : si un service a 5 deps mais une seule responsabilité cohérente, ne pas le signaler comme violation. Le nombre de deps est un indicateur, pas un verdict.
- **Proposer des stratégies concrètes** : ne pas juste dire "ce service a trop de deps". Proposer un plan de découpage précis avec les fichiers à créer.
- **Penser aux side effects** : les notifications, logs métier, analytics, synchro cross-BC sont les premiers candidats à l'extraction vers des Event Handlers async.
- **Respecter le DDD** : le découpage doit respecter les frontières de Bounded Context. Ne pas créer de dépendances cross-BC dans le plan de découpage.
