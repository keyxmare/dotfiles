# Patterns de refactorisation courants

## 1. Fuite de dépendances dans le Domain

### Symptôme
```php
// src/Catalog/Domain/Model/Product.php
use Doctrine\ORM\Mapping as ORM;  // BAD: Forbidden in the Domain

#[ORM\Entity]
class Product { ... }
```

### Correction
- Déplacer les annotations/attributs Doctrine dans un mapping XML (`Infrastructure/Persistence/Mapping/Product.orm.xml`).
- L'entité Domain devient un POPO pur.

---

## 2. Anemic Domain Model

### Symptôme
```php
// Entity with only getters/setters
class Order {
    public function setStatus(string $status): void { ... }  // AVOID
}

// Business logic in an application service
class OrderService {
    public function cancelOrder(Order $order): void {
        $order->setStatus('cancelled');  // BAD: Business logic outside the domain
    }
}
```

### Correction
```php
class Order {
    public function cancel(): void  // GOOD: Business method
    {
        if ($this->status === OrderStatus::Shipped) {
            throw new OrderAlreadyShippedException($this->id);
        }
        $this->status = OrderStatus::Cancelled;
        $this->recordEvent(new OrderCancelled($this->id));
    }
}
```

---

## 3. Absence de Value Objects

### Symptôme
```php
class User {
    private string $email;  // BAD: Primitive string without validation
}
```

### Correction
```php
readonly class Email {
    public function __construct(public string $value) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidEmailException($value);
        }
    }
}
```

---

## 4. Controller trop chargé (Fat Controller)

### Symptôme
```php
class ProductController {
    public function create(Request $request): Response {
        $data = json_decode($request->getContent(), true);
        // BAD: Validation, business logic, persistence in the controller
        $product = new Product();
        $product->setName($data['name']);
        $this->em->persist($product);
        $this->em->flush();
        return new JsonResponse($product->toArray());
    }
}
```

### Correction
```php
class ProductController {
    public function create(Request $request): Response {
        $command = new CreateProductCommand(  // GOOD: DTO immutable
            name: $request->get('name'),
        );
        $this->commandBus->dispatch($command);  // GOOD: Dispatch to the handler
        return new JsonResponse(null, Response::HTTP_CREATED);
    }
}
```

---

## 5. Couplage entre Bounded Contexts

### Symptôme
```php
// src/Billing/Application/Command/CreateInvoiceHandler.php
use App\Catalog\Domain\Model\Product;  // BAD: Direct cross-BC import
```

### Correction
- Communiquer via Domain Events ou un SharedKernel minimal.
- Utiliser des IDs (Value Objects) plutôt que des références directes.

---

## 6. Absence de strict_types

### Symptôme
```php
<?php
// BAD: No declare(strict_types=1)
namespace App\...;
```

### Correction
```php
<?php

declare(strict_types=1);

namespace App\...;
```

---

## 7. Repository dans la mauvaise couche

### Symptôme
```php
// src/Catalog/Domain/Repository/ProductRepository.php
class ProductRepository extends ServiceEntityRepository  // BAD: Doctrine implementation in Domain
```

### Correction
```php
// Domain: interface only
// src/Catalog/Domain/Repository/ProductRepositoryInterface.php
interface ProductRepositoryInterface {
    public function findById(ProductId $id): ?Product;
    public function save(Product $product): void;
}

// Infrastructure: implementation
// src/Catalog/Infrastructure/Persistence/DoctrineProductRepository.php
class DoctrineProductRepository extends ServiceEntityRepository implements ProductRepositoryInterface
```

---

## 8. Catch générique

### Symptôme
```php
try {
    $this->doSomething();
} catch (\Exception $e) {  // BAD: Too broad
    return null;            // BAD: Swallowed silently
}
```

### Correction
```php
try {
    $this->doSomething();
} catch (SpecificDomainException $e) {
    $this->logger->warning('Contexte: {message}', ['message' => $e->getMessage()]);
    throw $e;
}
```

---

## 9. Magic strings / numbers

### Symptôme
```php
if ($order->getStatus() === 'pending') { ... }  // BAD: Magic string
if ($retryCount > 3) { ... }                     // BAD: Magic number
```

### Correction
```php
enum OrderStatus: string {
    case Pending = 'pending';
    // ...
}
if ($order->status === OrderStatus::Pending) { ... }  // GOOD: Enum value

private const MAX_RETRIES = 3;
if ($retryCount > self::MAX_RETRIES) { ... }  // GOOD: Named constant
```

---

## 10. Manque de typage

### Symptôme
```php
public function process($data)  // BAD: No type hint
{
    return $data;  // BAD: No return type
}
```

### Correction
```php
public function process(OrderData $data): ProcessedResult
{
    return new ProcessedResult($data);
}
```

---

## 11. Absence de Property Hooks (PHP 8.4+)

### Symptôme
```php
class Money {
    private int $amount;
    private string $currency;

    public function getAmount(): int { return $this->amount; }       // AVOID: Classic getter
    public function getCurrency(): string { return $this->currency; } // AVOID: Classic getter

    public function setAmount(int $amount): void {                    // AVOID: Setter with duplicated validation
        if ($amount < 0) {
            throw new \InvalidArgumentException('Amount must be positive.');
        }
        $this->amount = $amount;
    }
}
```

### Correction
```php
class Money {
    public int $amount {
        set {
            if ($value < 0) {
                throw new \InvalidArgumentException('Amount must be positive.');
            }
            $this->amount = $value;
        }
    }

    public string $currency { get; }  // GOOD: Read-only via property hook
}
```

**Quand utiliser les property hooks :**
- Remplacer les getters triviaux par `{ get; }` (en lecture seule asymétrique : `public Type $prop { get; }`)
- Remplacer les setters avec validation par `{ set { ... } }`
- Remplacer les getters/setters qui transforment la valeur (`{ get => ...; set => ...; }`)

**Quand NE PAS migrer :**
- Méthodes métier nommées (`publish()`, `cancel()`) — ce ne sont pas des setters
- Getters avec logique métier complexe ou dépendances
- Propriétés avec lazy loading ou calcul coûteux
