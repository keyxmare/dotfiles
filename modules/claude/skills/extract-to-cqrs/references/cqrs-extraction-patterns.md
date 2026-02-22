# Patterns d'extraction CQRS — Controller Legacy vers Command/Query Handlers

## Commandes de scan rapide

### Identifier les controllers god class

```bash
# Controllers > 200 lignes (candidats à la refacto)
find src/ -path "*/Controller/*" -name "*.php" -exec awk 'END{if(NR>200) print FILENAME": "NR" lines"}' {} \;

# Controllers avec EntityManager injecté
grep -rln "EntityManagerInterface\|EntityManager " src/ --include="*.php" | grep -i controller

# Controllers avec persist/flush/remove direct
grep -rln "->persist(\|->flush(\|->remove(" src/ --include="*.php" | grep -i controller

# Controllers avec createQueryBuilder
grep -rln "createQueryBuilder\|createQuery\|->getRepository(" src/ --include="*.php" | grep -i controller

# Controllers avec logique métier (if/else complexes)
grep -rn "function.*Action\|function.*#\[Route" src/ --include="*.php" | grep -i controller
```

### Compter les actions par controller

```bash
# Nombre d'actions (méthodes avec #[Route]) par controller
for f in $(find src/ -path "*/Controller/*" -name "*.php"); do
  count=$(grep -c "#\[Route" "$f" 2>/dev/null)
  if [ "$count" -gt 0 ]; then
    echo "$f: $count actions"
  fi
done
```

### Détecter les code smells dans les controllers

```bash
# Doctrine inline
grep -rn "->persist(\|->flush(\|->remove(\|->createQueryBuilder(\|->getRepository(" src/ --include="*.php" | grep -i controller

# Logique métier (setters sur entités)
grep -rn "->set[A-Z]" src/ --include="*.php" | grep -i controller

# Validation manuelle
grep -rn "if.*empty\|if.*!isset\|if.*null ==\|if.*=== null" src/ --include="*.php" | grep -i controller

# json_decode dans les controllers
grep -rn "json_decode" src/ --include="*.php" | grep -i controller

# Envoi d'email dans les controllers
grep -rn "->send(\|MailerInterface\|Mailer" src/ --include="*.php" | grep -i controller

# Catch generique
grep -rn "catch.*\\\\Exception\|catch.*\Exception" src/ --include="*.php" | grep -i controller

# Service locator pattern
grep -rn "->get(\|container->get" src/ --include="*.php" | grep -i controller

# Transaction manuelle
grep -rn "beginTransaction\|->commit(\|->rollback(" src/ --include="*.php" | grep -i controller
```

### Detecter la structure CQRS existante

```bash
# Commands existants
find src/ -path "*/Command/*Command.php" -not -path "*/Console/*" 2>/dev/null

# Queries existantes
find src/ -path "*/Query/*Query.php" 2>/dev/null

# Handlers existants
find src/ -path "*Handler.php" -not -path "*/EventHandler/*" 2>/dev/null

# Config Messenger (bus)
cat config/packages/messenger.yaml 2>/dev/null

# Bus custom
grep -rn "command.bus\|query.bus\|event.bus\|CommandBusInterface\|QueryBusInterface" src/ config/ --include="*.php" --include="*.yaml" 2>/dev/null
```

## Patterns de dissection

### Pattern 1 — CRUD simple (Create)

**Avant** :
```php
public function create(Request $request): JsonResponse
{
    $data = json_decode($request->getContent(), true);      // Input
    if (empty($data['name'])) {                              // Validation
        return new JsonResponse(['error' => 'Name required'], 400);
    }
    $product = new Product();                                // Business
    $product->setName($data['name']);                         // Setter abuse
    $product->setPrice($data['price']);                       // Setter abuse
    $this->em->persist($product);                            // Persistence
    $this->em->flush();                                      // Persistence
    return new JsonResponse(['id' => $product->getId()], 201); // Output
}
```

**Apres** :
- `CreateProductCommand(name, price)` — validation via Assert
- `CreateProductCommandHandler` — `Product::create()` + repository
- Controller : deserialiser → dispatch → reponse 201

### Pattern 2 — CRUD simple (Read)

**Avant** :
```php
public function show(int $id): JsonResponse
{
    $product = $this->em->getRepository(Product::class)->find($id);
    if (!$product) {
        throw $this->createNotFoundException();
    }
    return new JsonResponse([
        'id' => $product->getId(),
        'name' => $product->getName(),
        'price' => $product->getPrice(),
    ]);
}
```

**Apres** :
- `GetProductQuery(productId)` — DTO immutable
- `GetProductQueryHandler` — repository + DTO Response
- `ProductResponse::fromEntity()` — mapping entite → DTO
- Controller : dispatch query → reponse JSON

### Pattern 3 — Action avec side effects

**Avant** :
```php
public function confirm(int $id): JsonResponse
{
    $order = $this->em->find(Order::class, $id);
    $order->setStatus('confirmed');                          // Setter
    $order->setConfirmedAt(new \DateTimeImmutable());        // Setter
    $this->em->flush();
    $this->mailer->send(new OrderConfirmationEmail($order)); // Side effect
    $this->logger->info('Order confirmed', ['id' => $id]);   // Side effect
    return new JsonResponse(null, 200);
}
```

**Apres** :
- `ConfirmOrderCommand(orderId)` — simple ID
- `ConfirmOrderCommandHandler` — `$order->confirm()` methode metier
- `Order::confirm()` — logique + `recordEvent(new OrderConfirmed(...))`
- `SendConfirmationOnOrderConfirmed` — Event Handler async (email)
- Le logging metier peut rester dans le handler ou aller dans un event handler

### Pattern 4 — Action avec logique metier complexe

**Avant** :
```php
public function applyDiscount(Request $request, int $orderId): JsonResponse
{
    $order = $this->em->find(Order::class, $orderId);
    $code = $request->get('discount_code');
    $discount = $this->em->getRepository(Discount::class)->findOneBy(['code' => $code]);
    if (!$discount || $discount->isExpired()) {
        return new JsonResponse(['error' => 'Invalid discount'], 400);
    }
    if ($order->getTotal() < $discount->getMinimumAmount()) {
        return new JsonResponse(['error' => 'Minimum not reached'], 400);
    }
    $newTotal = $order->getTotal() - ($order->getTotal() * $discount->getPercentage() / 100);
    $order->setTotal($newTotal);
    $order->setDiscountCode($code);
    $discount->incrementUsage();
    $this->em->flush();
    return new JsonResponse(['new_total' => $newTotal]);
}
```

**Apres** :
- `ApplyDiscountCommand(orderId, discountCode)`
- `ApplyDiscountCommandHandler` :
  - Charge Order et Discount via repositories
  - `$order->applyDiscount($discount)` — logique metier dans le Domain
- `Order::applyDiscount(Discount)` :
  - Verifie le minimum (throw `MinimumAmountNotReachedException`)
  - Calcule le nouveau total
  - Enregistre le code
  - Emet `DiscountApplied` event
- `Discount::use()` — incrémente l'usage, vérifie la limite

### Pattern 5 — Action de listing/recherche

**Avant** :
```php
public function list(Request $request): JsonResponse
{
    $qb = $this->em->createQueryBuilder()
        ->select('p')
        ->from(Product::class, 'p')
        ->where('p.active = :active')
        ->setParameter('active', true);

    if ($category = $request->query->get('category')) {
        $qb->andWhere('p.category = :cat')->setParameter('cat', $category);
    }
    if ($search = $request->query->get('q')) {
        $qb->andWhere('p.name LIKE :q')->setParameter('q', "%$search%");
    }

    $page = (int) $request->query->get('page', 1);
    $qb->setFirstResult(($page - 1) * 20)->setMaxResults(20);

    $products = $qb->getQuery()->getResult();
    $total = /* count query */;

    return new JsonResponse([
        'items' => array_map(fn($p) => [...], $products),
        'total' => $total,
        'page' => $page,
    ]);
}
```

**Apres** :
- `ListProductsQuery(category?, search?, page)` — criteres de recherche
- `ListProductsQueryHandler` — utilise le repository (le QueryBuilder reste dans l'implémentation du repo en Infrastructure)
- `ProductRepositoryInterface::findPaginated(criteria, page, limit)` — methode de recherche
- `PaginatedResponse<ProductResponse>` — DTO de reponse paginee

### Pattern 6 — Controller avec AbstractController

**Avant** (herite d'AbstractController) :
```php
class ProductController extends AbstractController
{
    public function create(Request $request): Response
    {
        $this->denyAccessUnlessGranted('ROLE_ADMIN');        // Security
        $form = $this->createForm(ProductType::class);       // Form
        $form->handleRequest($request);
        if ($form->isSubmitted() && $form->isValid()) {
            $product = $form->getData();
            $this->getDoctrine()->getManager()->persist($product);
            $this->getDoctrine()->getManager()->flush();
            $this->addFlash('success', 'Product created');
            return $this->redirectToRoute('product_list');
        }
        return $this->render('product/create.html.twig', [
            'form' => $form->createView(),
        ]);
    }
}
```

**Apres** :
- Garder `AbstractController` pour les controllers web (Twig).
- Garder `#[IsGranted('ROLE_ADMIN')]` sur la methode/classe.
- Garder le Form Symfony mais dispatch la Command dans le `if isValid`.
- Le controller Twig est moins "pur" qu'un controller API — c'est acceptable.

```php
#[IsGranted('ROLE_ADMIN')]
#[Route('/products/create')]
public function create(Request $request): Response
{
    $form = $this->createForm(ProductType::class);
    $form->handleRequest($request);

    if ($form->isSubmitted() && $form->isValid()) {
        $data = $form->getData();
        $this->commandBus->dispatch(new CreateProductCommand(
            name: $data['name'],
            price: $data['price'],
        ));
        $this->addFlash('success', 'Product created');
        return $this->redirectToRoute('product_list');
    }

    return $this->render('product/create.html.twig', [
        'form' => $form,
    ]);
}
```

## Option `--bus=custom` — Bus CQRS sans Messenger

Quand le projet n'utilise pas Symfony Messenger (framework legacy, choix architectural, ou bus maison), l'option `--bus=custom` adapte la generation de code pour utiliser des interfaces de bus simples au lieu des attributs `#[AsMessageHandler]`.

**Phase 0** : demander a l'utilisateur ses interfaces de bus existantes. S'il n'en a pas, proposer les interfaces suivantes comme base :

```php
<?php

declare(strict_types=1);

namespace App\Shared\Application\Bus;

interface CommandBusInterface
{
    /**
     * @throws \Throwable
     */
    public function dispatch(object $command): void;
}
```

```php
<?php

declare(strict_types=1);

namespace App\Shared\Application\Bus;

interface QueryBusInterface
{
    /**
     * @template T
     * @param object $query
     * @return T
     * @throws \Throwable
     */
    public function dispatch(object $query): mixed;
}
```

**Impact sur les templates** : avec `--bus=custom`, les handlers generes n'ont pas d'attribut `#[AsMessageHandler]` et ne dependent pas de Messenger. Le wiring se fait via le `services.yaml` du projet ou la configuration du bus custom de l'utilisateur.

**Exemple de Handler avec bus custom** :

```php
<?php

declare(strict_types=1);

namespace App\Order\Application\Command;

final readonly class CreateOrderCommandHandler
{
    public function __construct(
        private OrderRepositoryInterface $orderRepository,
    ) {}

    public function __invoke(CreateOrderCommand $command): void
    {
        // No #[AsMessageHandler] attribute — wiring is handled by the custom bus
        $order = Order::create($command->name, $command->total);
        $this->orderRepository->save($order);
    }
}
```

---

## Templates de code

### Template Command

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Application\Command;

readonly class __Name__Command
{
    public function __construct(
        // Properties from input dissection
    ) {}
}
```

### Template Command Handler

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Application\Command;

use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler(bus: 'command.bus')]
final readonly class __Name__CommandHandler
{
    public function __construct(
        // Repository interfaces from Domain
    ) {}

    public function __invoke(__Name__Command $command): void
    {
        // 1. Load aggregates from repositories
        // 2. Execute domain logic via entity methods
        // 3. Save via repository
    }
}
```

### Template Query

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Application\Query;

readonly class __Name__Query
{
    public function __construct(
        // Criteria / filters / IDs
    ) {}
}
```

### Template Query Handler

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Application\Query;

use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler(bus: 'query.bus')]
final readonly class __Name__QueryHandler
{
    public function __construct(
        // Repository interfaces
    ) {}

    public function __invoke(__Name__Query $query): __Response__
    {
        // 1. Query repository
        // 2. Map to DTO response
        // 3. Return DTO
    }
}
```

### Template DTO Response

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Application\DTO;

readonly class __Name__Response
{
    public function __construct(
        public string $id,
        // Mapped properties
    ) {}

    public static function fromEntity(__Entity__ $entity): self
    {
        return new self(
            id: (string) $entity->id(),
            // Map entity properties to scalars
        );
    }
}
```

### Template Controller API refactorisé

```php
<?php

declare(strict_types=1);

namespace App\__BC__\Infrastructure\Symfony\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Messenger\Stamp\HandledStamp;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/__resource__')]
final class __Name__Controller
{
    public function __construct(
        private MessageBusInterface $commandBus,
        private MessageBusInterface $queryBus,
    ) {}

    // Actions: deserialize -> dispatch -> response
}
```

## Heuristiques de classification Command vs Query

### Certainement une Command

- Methode HTTP : POST, PUT, PATCH, DELETE
- Contient `persist()`, `flush()`, `remove()`
- Contient des setters sur les entites
- Modifie l'etat d'un aggregat
- Envoie un email/notification
- Retourne 201, 204, ou redirect

### Certainement une Query

- Methode HTTP : GET
- Contient uniquement des `find()`, `findBy()`, `findAll()`
- Ne modifie aucun etat
- Retourne des donnees (JSON, HTML rendu)
- Contient de la pagination
- Contient des filtres/criteres de recherche

### Cas ambigus

| Cas | Resolution |
|---|---|
| GET avec side effect (compteur de vues) | Query + event async pour le side effect |
| POST pour une recherche complexe | Query (le POST sert a envoyer un body de criteres) |
| PUT/PATCH idempotent (upsert) | Command |
| Action qui lit ET ecrit | Separer en Query + Command, ou Command avec retour |
| Export CSV/PDF | Query (la generation est une lecture transformee) |

## Faux positifs — Ce qu'il ne faut PAS extraire

| Pattern | Raison |
|---|---|
| Controller deja mince (< 10 lignes par action) | Rien a extraire |
| Controller qui dispatch deja des commands | Deja fait |
| Controller de health check / status | Trop trivial |
| Controller de webhook (recoit des events externes) | Pattern different (Event ingestion) |
| Controller d'upload de fichier | Le traitement du fichier peut rester cote infra |
| API Platform controllers auto-generes | Geres par les State Providers/Processors |

## Checklist de revue post-extraction

### Controller

- [ ] Aucun `use Doctrine\...` dans le controller
- [ ] Aucun `EntityManager` / `EntityManagerInterface`
- [ ] Aucun `->persist()` / `->flush()` / `->remove()`
- [ ] Aucune logique if/else metier
- [ ] Aucun calcul/transformation de donnees metier
- [ ] Aucun envoi d'email/notification
- [ ] Chaque action : deserialise → dispatch → reponse (3 etapes max)
- [ ] Types de retour coherents (JsonResponse, Response)

### Command / Query

- [ ] `readonly class`
- [ ] `declare(strict_types=1)`
- [ ] Proprietes typees
- [ ] Validation via Assert si pertinent
- [ ] Pas de methode autre que le constructeur
- [ ] Nommage : imperatif (Command) ou descriptif (Query)

### Handler

- [ ] `final readonly class`
- [ ] Un seul `__invoke()` avec le bon type-hint
- [ ] Injecte des interfaces (pas des implementations)
- [ ] Pas de `flush()` direct (via le repository)
- [ ] Command Handler retourne `void` (ou valeur si convention projet)
- [ ] Query Handler retourne un DTO (pas l'entite directement)
- [ ] `#[AsMessageHandler(bus: '...')]` correct

### Domain

- [ ] Entite modifiee via methodes metier (pas de setters)
- [ ] Domain Events emis pour les faits metier importants
- [ ] Exceptions metier specifiques (pas de `\RuntimeException` generique)
- [ ] Value Objects pour les concepts metier (email, money, status)
