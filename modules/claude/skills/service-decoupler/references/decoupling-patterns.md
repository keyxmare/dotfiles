# Patterns de détection de couplage — Services Symfony

## Commandes de scan rapide

### Inventaire des services avec leur nombre de dépendances

```bash
# Lister tous les constructeurs et compter les paramètres typés
for f in $(find src/ -name "*.php" -not -path "*/Entity/*" -not -path "*/Model/*" -not -path "*/DTO/*" -not -path "*/Command/*Command.php" -not -path "*/Query/*Query.php" -not -path "*/Event/*" -not -path "*/Exception/*" -not -path "*/Enum/*" -not -path "*/ValueObject/*" -not -path "*/Migration/*" -not -path "*/Fixtures/*"); do
  deps=$(grep -A 30 "public function __construct" "$f" 2>/dev/null | grep -c "private\|public\|protected.*readonly\|private.*\$\|public.*\$" 2>/dev/null)
  if [ "$deps" -gt 0 ]; then
    echo "$f: $deps deps"
  fi
done | sort -t: -k2 -rn
```

### Top services par nombre de dépendances

```bash
# Trouver les services avec > N dépendances constructeur
THRESHOLD=5
for f in $(find src/ -name "*.php"); do
  deps=$(grep -A 50 "public function __construct" "$f" 2>/dev/null | grep -c "private\s\+readonly\|private\s\+\$" 2>/dev/null)
  if [ "$deps" -ge "$THRESHOLD" ]; then
    echo "$deps deps → $f"
  fi
done | sort -rn
```

### Compter les méthodes publiques par classe

```bash
# Méthodes publiques (hors constructeur et méthodes magiques)
for f in $(find src/ -name "*.php"); do
  methods=$(grep -c "public function [a-z]" "$f" 2>/dev/null)
  # Soustraire le constructeur s'il existe
  has_construct=$(grep -c "public function __construct" "$f" 2>/dev/null)
  methods=$((methods - has_construct))
  if [ "$methods" -gt 5 ]; then
    echo "$f: $methods public methods"
  fi
done | sort -t: -k2 -rn
```

### God classes (> 300 lignes)

```bash
find src/ -name "*.php" -not -path "*/Migration/*" -not -path "*/Fixtures/*" \
  -exec awk 'END{if(NR>300) print FILENAME": "NR" lines"}' {} \; | sort -t: -k2 -rn
```

### Détecter EntityManager injecté directement

```bash
# EntityManager au lieu de Repository Interface
grep -rln "EntityManagerInterface" src/ --include="*.php" 2>/dev/null \
  | grep -v "Repository" \
  | grep -v "Migration" \
  | grep -v "Fixtures"
```

### Détecter les services orchestrateurs

```bash
# Méthodes qui appellent > 3 dépendances (heuristique: $this->dep->method())
for f in $(find src/ -name "*.php" -path "*/Service/*" -o -name "*.php" -path "*/Handler/*"); do
  max_calls=$(grep -c '\$this->[a-z].*->' "$f" 2>/dev/null)
  if [ "$max_calls" -gt 5 ]; then
    echo "$f: ~$max_calls dependency calls"
  fi
done | sort -t: -k2 -rn
```

### Détecter les injections cross-BC

```bash
# Pour chaque service, lister les BC des dépendances
for bc_dir in src/*/; do
  bc=$(basename "$bc_dir")
  echo "=== $bc ==="
  # Constructeurs avec types d'autres BC
  grep -rn "__construct" "$bc_dir" --include="*.php" -A 30 2>/dev/null \
    | grep "App\\\\" \
    | grep -v "App\\\\${bc}\\\\" \
    | grep -v "App\\\\Shared\\\\" \
    | grep -v "App\\\\Common\\\\"
done
```

### Détecter les side effects dans les services

```bash
# Envoi d'email
grep -rln "MailerInterface\|->send(" src/ --include="*.php" 2>/dev/null | grep -v "Mailer\|Notification\|EventHandler"

# Dispatch d'evenement
grep -rln "EventDispatcherInterface\|->dispatch(" src/ --include="*.php" 2>/dev/null | grep -v "Listener\|Subscriber\|EventHandler"

# Appel HTTP externe
grep -rln "HttpClientInterface\|->request(" src/ --include="*.php" 2>/dev/null | grep -v "Client\|Adapter"

# Cache inline
grep -rln "CacheInterface\|CacheItemPoolInterface\|->get(\|->delete(" src/ --include="*.php" 2>/dev/null | grep -v "Cache"
```

## Patterns de classification des dépendances

### Categories automatiques par namespace/interface

| Pattern FQCN | Categorie |
|---|---|
| `*RepositoryInterface` | `persistence` |
| `EntityManagerInterface` | `persistence` (anti-pattern si pas dans un repo) |
| `Connection` (DBAL) | `persistence` |
| `MessageBusInterface` | `messaging` |
| `*BusInterface` | `messaging` |
| `MailerInterface` | `notification` |
| `NotifierInterface` | `notification` |
| `*Notifier`, `*Mailer` | `notification` |
| `EventDispatcherInterface` | `eventing` |
| `CacheInterface` | `caching` |
| `CacheItemPoolInterface` | `caching` |
| `TagAwareCacheInterface` | `caching` |
| `LoggerInterface` | `logging` (exempte du comptage) |
| `Security` | `security` |
| `AuthorizationCheckerInterface` | `security` |
| `TokenStorageInterface` | `security` |
| `ValidatorInterface` | `validation` |
| `SerializerInterface` | `serialization` |
| `NormalizerInterface` | `serialization` |
| `DenormalizerInterface` | `serialization` |
| `TranslatorInterface` | `translation` |
| `HttpClientInterface` | `http` |
| `RequestStack` | `http` |
| `FilesystemInterface` | `filesystem` |
| `Filesystem` (Symfony) | `filesystem` |
| `ParameterBagInterface` | `configuration` |
| `ClockInterface` | `utility` (exempte du comptage) |
| Scalaires (`string`, `int`, `bool`, `array`) | `configuration` (exemptes du comptage) |

### Categories par emplacement dans le projet

| Chemin de la dépendance | Catégorie |
|---|---|
| `src/<MemeBC>/Domain/Service/*` | `domain_service` |
| `src/<MemeBC>/Domain/Repository/*Interface` | `persistence` |
| `src/<MemeBC>/Application/*` | `application_service` |
| `src/<AutreBC>/*` | `cross_bc` (signal fort) |
| `src/Shared/*` | `shared_kernel` |
| `Symfony\*`, `Doctrine\*` | `framework` |

## Scoring des violations

### Calcul du score de severite (0-10)

```
score = 0

# Dépendances constructeur (poids: 40%)
if deps >= 9:  score += 4
elif deps >= 7: score += 3
elif deps >= 5: score += 2
elif deps >= 4: score += 1

# Méthodes publiques (poids: 20%)
if methods >= 10: score += 2
elif methods >= 7:  score += 1.5
elif methods >= 5:  score += 1

# Lignes de code (poids: 20%)
if lines >= 400: score += 2
elif lines >= 300: score += 1.5
elif lines >= 200: score += 1

# Clusters de preoccupations (poids: 20%)
if clusters >= 5: score += 2
elif clusters >= 4: score += 1.5
elif clusters >= 3: score += 1

# Bonus (aggravants)
if cross_bc >= 3: score += 1
if has_entity_manager_direct: score += 0.5
if is_handler_with_many_deps: score += 1

# Cap a 10
score = min(score, 10)
```

### Classification par score

| Score | Severite | Action |
|-------|----------|--------|
| 0-2 | OK | Aucune action |
| 3-4 | `info` | Documenter, surveiller |
| 5-6 | `warning` | Planifier un decoupage |
| 7-8 | `high` | Decoupage recommande |
| 9-10 | `critical` | Decoupage urgent |

## Strategies de decoupage — decision tree

```
Le service a-t-il des méthodes de lecture ET d'écriture ?
├── OUI → Strategie 3 : Extraction CQRS
└── NON
    Le service a-t-il des side effects (mail, notif, API externe) ?
    ├── OUI → Strategie 2 : Extraction vers Domain Events
    └── NON
        Le service a-t-il un caching inline ?
        ├── OUI → Strategie 4 : Extraction vers Decorator
        └── NON
            Le service route-t-il vers des implementations differentes (match/switch) ?
            ├── OUI → Strategie 5 : Extraction vers Strategy/Chain
            └── NON
                Le service contient-il de la logique metier pure ?
                ├── OUI → Strategie 6 : Extraction de Domain Service
                └── NON → Strategie 1 : Extraction par preoccupation (generique)
```

## Anti-patterns courants et corrections

### 1. EntityManager direct dans un service applicatif

**Symptome** :
```php
class ProductService
{
    public function __construct(
        private EntityManagerInterface $em, // Anti-pattern
    ) {}

    public function findProduct(string $id): Product
    {
        return $this->em->getRepository(Product::class)->find($id);
    }
}
```

**Correction** : injecter `ProductRepositoryInterface` au lieu de `EntityManagerInterface`.

### 2. Service "God" orchestrateur

**Symptome** :
```php
class OrderService
{
    public function __construct(
        private OrderRepository $orderRepo,
        private ProductRepository $productRepo,
        private PaymentGateway $paymentGateway,
        private MailerInterface $mailer,
        private StockService $stockService,
        private InvoiceService $invoiceService,
        private AnalyticsService $analytics,
        private EventDispatcherInterface $dispatcher,
    ) {}

    public function processOrder(Order $order): void
    {
        // 8 étapes séquentielles utilisant 7 dépendances
    }
}
```

**Correction** :
- `CreateOrderCommandHandler` : persiste l'order + leve OrderPlaced event
- `ChargePaymentOnOrderPlaced` : event handler async
- `SendConfirmationOnOrderPlaced` : event handler async
- `DecrementStockOnOrderPlaced` : event handler async
- `GenerateInvoiceOnOrderPlaced` : event handler async
- `TrackOrderAnalytics` : event handler async

### 3. Caching inline dans un repository

**Symptome** :
```php
class ProductRepository
{
    public function __construct(
        private EntityManagerInterface $em,
        private CacheInterface $cache, // Melange persistence + caching
    ) {}

    public function findById(string $id): ?Product
    {
        return $this->cache->get("product_$id", function() use ($id) {
            return $this->em->find(Product::class, $id);
        });
    }
}
```

**Correction** : decorator `CachedProductRepository` qui wrappe `DoctrineProductRepository`.

### 4. Facade inutile

**Symptome** :
```php
class ProductService
{
    public function __construct(
        private ProductRepositoryInterface $repo,
    ) {}

    // One-liner qui ne fait que deleguer
    public function findById(string $id): ?Product
    {
        return $this->repo->findById($id);
    }

    public function save(Product $product): void
    {
        $this->repo->save($product);
    }
}
```

**Correction** : supprimer la facade, injecter directement le repository.

### 5. Service avec validations multiples

**Symptome** :
```php
class OrderService
{
    public function createOrder(OrderDTO $dto): Order
    {
        // Validation 1 : format
        if (empty($dto->customerEmail)) {
            throw new \InvalidArgumentException('Email required');
        }
        // Validation 2 : metier
        if ($dto->total < 0) {
            throw new \InvalidArgumentException('Total must be positive');
        }
        // Validation 3 : existence
        $customer = $this->customerRepo->find($dto->customerId);
        if (!$customer) {
            throw new CustomerNotFoundException($dto->customerId);
        }
        // ... creation
    }
}
```

**Correction** :
- Validation 1 (format) → `#[Assert\NotBlank]` sur le Command DTO
- Validation 2 (métier) → dans l'entité `Order::create()` ou un Specification
- Validation 3 (existence) → dans le Handler (repository lookup)

## Faux positifs — Services qui semblent surcharges mais ne le sont pas

| Pattern | Raison |
|---------|--------|
| Controller avec 5+ deps (buses, serializer, validator) | Normal pour un controller Symfony |
| Command Handler avec 3-4 repos | Acceptable si l'operation touche plusieurs aggregats atomiquement |
| Subscriber/Listener avec 4+ deps | Peut etre normal si l'evenement declenche des actions multiples |
| CompilerPass avec beaucoup de services references | Pattern Symfony standard |
| Twig Extension avec helpers multiples | Les extensions groupent des fonctionnalites Twig liees |
| Normalizer/Denormalizer avec deps | Peut necessiter des services pour la serialisation |
| Voter avec 2-3 repos | Acceptable pour des regles d'acces complexes |
| API Platform State Provider/Processor | Peuvent legitimement avoir des deps variees |

## Checklist de verification post-decoupage

### Nouveau service

- [ ] Maximum 3-4 dépendances constructeur
- [ ] Une seule responsabilite clairement identifiable
- [ ] `declare(strict_types=1)`
- [ ] `final readonly class` si possible
- [ ] Injecte des interfaces (pas des implementations concretes)
- [ ] Pas de dépendance cross-BC (sauf Shared)
- [ ] Pas d'`EntityManagerInterface` direct (sauf dans les repositories)

### Service d'origine

- [ ] Toutes les responsabilites ont ete migrees
- [ ] Les consommateurs (controllers, handlers) injectent les nouveaux services
- [ ] Le service d'origine peut etre supprime
- [ ] Les tests ont ete adaptes
- [ ] `services.yaml` mis a jour si necessaire

### Projet

- [ ] `make phpstan` passe
- [ ] `make test` passe
- [ ] `make cs-fix` applique
- [ ] Cache vide (`make cache`)
- [ ] Pas de nouvelle dépendance cross-BC introduite
