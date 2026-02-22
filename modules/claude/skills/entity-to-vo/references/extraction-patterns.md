# Patterns de détection et extraction — Entity to Value Object

## Commandes de scan rapide

### Inventaire des entités Doctrine

```bash
# Entités par attribut
grep -rln "#\[ORM\\\\Entity" src/ --include="*.php" 2>/dev/null

# Entités par mapping XML
find src/ -name "*.orm.xml" 2>/dev/null

# Entités par mapping YAML (legacy)
find src/ -name "*.orm.yml" -o -name "*.orm.yaml" 2>/dev/null

# Embeddables existants
grep -rln "#\[ORM\\\\Embeddable" src/ --include="*.php" 2>/dev/null
grep -rn "<embeddable" src/ --include="*.orm.xml" 2>/dev/null

# Embedded existants dans les entités
grep -rn "#\[ORM\\\\Embedded" src/ --include="*.php" 2>/dev/null
grep -rn "<embedded " src/ --include="*.orm.xml" 2>/dev/null
```

### Détecter les groupes de champs par préfixe

```bash
# Champs avec préfixe commun dans les entités
# Extraire les noms de propriétés des entités
grep -rn "private.*\$\|protected.*\$" src/ --include="*.php" | grep -v "function\|static\|const"

# Champs address*
grep -rn "address\|street\|city\|zipCode\|zip_code\|postalCode\|postal_code\|country\|state\|province\|region" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs money/price*
grep -rn "amount\|currency\|price\|cost\|total\|subtotal\|tax\|fee\|discount" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs contact*
grep -rn "email\|phone\|fax\|mobile\|contactName\|contact_name" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs coordonnées
grep -rn "latitude\|longitude\|lat\|lng\|lon" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs nom complet
grep -rn "firstName\|first_name\|lastName\|last_name\|middleName\|middle_name\|fullName\|full_name" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs date range
grep -rn "startDate\|start_date\|endDate\|end_date\|validFrom\|valid_from\|validUntil\|valid_until\|publishedAt\|expiredAt\|startsAt\|endsAt" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"

# Champs dimensions
grep -rn "width\|height\|depth\|length\|weight\|volume" src/ --include="*.php" | grep -i "private\|protected\|#\[ORM"
```

### Détecter les Value Objects existants

```bash
# VO dans le SharedKernel
find src/ -path "*/ValueObject/*" -name "*.php" 2>/dev/null
find src/ -path "*/SharedKernel/*" -name "*.php" 2>/dev/null

# Classes readonly (souvent des VO)
grep -rln "readonly class" src/ --include="*.php" 2>/dev/null

# Classes avec méthode equals (signature de VO)
grep -rln "function equals" src/ --include="*.php" 2>/dev/null

# Embeddables Doctrine existants
grep -rln "Embeddable\|embeddable" src/ --include="*.php" --include="*.xml" 2>/dev/null
```

### Détecter les usages des champs dans le code

```bash
# Usages dans les repositories (DQL, QueryBuilder)
grep -rn "\.addressStreet\|\.addressCity\|\.address_street\|\.address_city" src/ --include="*.php" 2>/dev/null

# Usages dans les formulaires
grep -rn "->add.*address\|->add.*street\|->add.*city" src/ --include="*.php" 2>/dev/null

# Usages dans les serializers/normalizers
grep -rn "addressStreet\|addressCity\|address_street\|address_city" src/ --include="*.php" 2>/dev/null | grep -i "normaliz\|serializ\|denormaliz"

# Usages dans les templates Twig
grep -rn "\.addressStreet\|\.addressCity\|\.address_street\|\.address_city" templates/ --include="*.twig" 2>/dev/null
```

## Templates de Value Objects courants

### Address

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Address
{
    public function __construct(
        public string $street,
        public string $city,
        public string $zipCode,
        public string $country,
        public ?string $state = null,
        public ?string $complement = null,
    ) {
        if (trim($this->street) === '') {
            throw new \InvalidArgumentException('Street cannot be empty.');
        }
        if (trim($this->city) === '') {
            throw new \InvalidArgumentException('City cannot be empty.');
        }
        if (trim($this->zipCode) === '') {
            throw new \InvalidArgumentException('Zip code cannot be empty.');
        }
        if (trim($this->country) === '') {
            throw new \InvalidArgumentException('Country cannot be empty.');
        }
    }

    public function equals(self $other): bool
    {
        return $this->street === $other->street
            && $this->city === $other->city
            && $this->zipCode === $other->zipCode
            && $this->country === $other->country
            && $this->state === $other->state
            && $this->complement === $other->complement;
    }

    public function withStreet(string $street): self
    {
        return new self($street, $this->city, $this->zipCode, $this->country, $this->state, $this->complement);
    }

    public function __toString(): string
    {
        $parts = [$this->street];
        if ($this->complement !== null) {
            $parts[] = $this->complement;
        }
        $parts[] = sprintf('%s %s', $this->zipCode, $this->city);
        if ($this->state !== null) {
            $parts[] = $this->state;
        }
        $parts[] = $this->country;

        return implode(', ', $parts);
    }
}
```

### Money

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Money
{
    public function __construct(
        public int $amount, // in cents to avoid float precision issues
        public string $currency,
    ) {
        if ($this->amount < 0) {
            throw new \InvalidArgumentException('Amount cannot be negative.');
        }
        if (strlen($this->currency) !== 3) {
            throw new \InvalidArgumentException('Currency must be a 3-letter ISO 4217 code.');
        }
    }

    public static function fromFloat(float $amount, string $currency): self
    {
        return new self((int) round($amount * 100), $currency);
    }

    public function toFloat(): float
    {
        return $this->amount / 100;
    }

    public function add(self $other): self
    {
        $this->assertSameCurrency($other);

        return new self($this->amount + $other->amount, $this->currency);
    }

    public function subtract(self $other): self
    {
        $this->assertSameCurrency($other);
        $result = $this->amount - $other->amount;
        if ($result < 0) {
            throw new \InvalidArgumentException('Resulting amount cannot be negative.');
        }

        return new self($result, $this->currency);
    }

    public function multiply(float $factor): self
    {
        return new self((int) round($this->amount * $factor), $this->currency);
    }

    public function isGreaterThan(self $other): bool
    {
        $this->assertSameCurrency($other);

        return $this->amount > $other->amount;
    }

    public function equals(self $other): bool
    {
        return $this->amount === $other->amount
            && $this->currency === $other->currency;
    }

    public function __toString(): string
    {
        return sprintf('%.2f %s', $this->toFloat(), $this->currency);
    }

    private function assertSameCurrency(self $other): void
    {
        if ($this->currency !== $other->currency) {
            throw new \InvalidArgumentException(
                sprintf('Cannot operate on different currencies: %s vs %s.', $this->currency, $other->currency),
            );
        }
    }
}
```

### Email

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Email
{
    public string $value;

    public function __construct(string $value)
    {
        $normalized = mb_strtolower(trim($value));
        if (!filter_var($normalized, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException(sprintf('Invalid email address: "%s".', $value));
        }
        $this->value = $normalized;
    }

    public function domain(): string
    {
        return substr($this->value, strpos($this->value, '@') + 1);
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

### DateRange / Period

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class DateRange
{
    public function __construct(
        public \DateTimeImmutable $startDate,
        public \DateTimeImmutable $endDate,
    ) {
        if ($this->startDate > $this->endDate) {
            throw new \InvalidArgumentException('Start date must be before or equal to end date.');
        }
    }

    public function contains(\DateTimeImmutable $date): bool
    {
        return $date >= $this->startDate && $date <= $this->endDate;
    }

    public function overlaps(self $other): bool
    {
        return $this->startDate <= $other->endDate && $this->endDate >= $other->startDate;
    }

    public function durationInDays(): int
    {
        return (int) $this->startDate->diff($this->endDate)->days;
    }

    public function isActive(?\DateTimeImmutable $now = null): bool
    {
        $now ??= new \DateTimeImmutable();

        return $this->contains($now);
    }

    public function equals(self $other): bool
    {
        return $this->startDate == $other->startDate
            && $this->endDate == $other->endDate;
    }

    public function __toString(): string
    {
        return sprintf('%s → %s', $this->startDate->format('Y-m-d'), $this->endDate->format('Y-m-d'));
    }
}
```

### Coordinates / GeoPoint

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Coordinates
{
    public function __construct(
        public float $latitude,
        public float $longitude,
    ) {
        if ($this->latitude < -90.0 || $this->latitude > 90.0) {
            throw new \InvalidArgumentException(
                sprintf('Latitude must be between -90 and 90, got %f.', $this->latitude),
            );
        }
        if ($this->longitude < -180.0 || $this->longitude > 180.0) {
            throw new \InvalidArgumentException(
                sprintf('Longitude must be between -180 and 180, got %f.', $this->longitude),
            );
        }
    }

    /**
     * Haversine formula — distance in kilometers.
     */
    public function distanceTo(self $other): float
    {
        $earthRadius = 6371.0;
        $dLat = deg2rad($other->latitude - $this->latitude);
        $dLon = deg2rad($other->longitude - $this->longitude);
        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($this->latitude)) * cos(deg2rad($other->latitude)) * sin($dLon / 2) ** 2;

        return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
    }

    public function equals(self $other): bool
    {
        return abs($this->latitude - $other->latitude) < 0.000001
            && abs($this->longitude - $other->longitude) < 0.000001;
    }

    public function __toString(): string
    {
        return sprintf('(%f, %f)', $this->latitude, $this->longitude);
    }
}
```

### FullName

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class FullName
{
    public function __construct(
        public string $firstName,
        public string $lastName,
    ) {
        if (trim($this->firstName) === '') {
            throw new \InvalidArgumentException('First name cannot be empty.');
        }
        if (trim($this->lastName) === '') {
            throw new \InvalidArgumentException('Last name cannot be empty.');
        }
    }

    public function fullName(): string
    {
        return sprintf('%s %s', $this->firstName, $this->lastName);
    }

    public function initials(): string
    {
        return sprintf('%s%s', mb_strtoupper(mb_substr($this->firstName, 0, 1)), mb_strtoupper(mb_substr($this->lastName, 0, 1)));
    }

    public function equals(self $other): bool
    {
        return $this->firstName === $other->firstName
            && $this->lastName === $other->lastName;
    }

    public function __toString(): string
    {
        return $this->fullName();
    }
}
```

### Dimensions

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Dimensions
{
    public function __construct(
        public float $width,
        public float $height,
        public ?float $depth = null,
    ) {
        if ($this->width <= 0) {
            throw new \InvalidArgumentException('Width must be positive.');
        }
        if ($this->height <= 0) {
            throw new \InvalidArgumentException('Height must be positive.');
        }
        if ($this->depth !== null && $this->depth <= 0) {
            throw new \InvalidArgumentException('Depth must be positive.');
        }
    }

    public function area(): float
    {
        return $this->width * $this->height;
    }

    public function volume(): ?float
    {
        if ($this->depth === null) {
            return null;
        }

        return $this->width * $this->height * $this->depth;
    }

    public function equals(self $other): bool
    {
        return abs($this->width - $other->width) < 0.001
            && abs($this->height - $other->height) < 0.001
            && (($this->depth === null && $other->depth === null)
                || ($this->depth !== null && $other->depth !== null && abs($this->depth - $other->depth) < 0.001));
    }

    public function __toString(): string
    {
        if ($this->depth !== null) {
            return sprintf('%.1f x %.1f x %.1f', $this->width, $this->height, $this->depth);
        }

        return sprintf('%.1f x %.1f', $this->width, $this->height);
    }
}
```

### Percentage

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

readonly class Percentage
{
    public function __construct(
        public float $value,
    ) {
        if ($this->value < 0.0 || $this->value > 100.0) {
            throw new \InvalidArgumentException(
                sprintf('Percentage must be between 0 and 100, got %f.', $this->value),
            );
        }
    }

    public function asDecimal(): float
    {
        return $this->value / 100.0;
    }

    public function applyTo(int|float $base): float
    {
        return $base * $this->asDecimal();
    }

    public function equals(self $other): bool
    {
        return abs($this->value - $other->value) < 0.001;
    }

    public function __toString(): string
    {
        return sprintf('%.1f%%', $this->value);
    }
}
```

### EntityId (Symfony Uid)

```php
<?php

declare(strict_types=1);

namespace App\SharedKernel\Domain\ValueObject;

use Symfony\Component\Uid\Uuid;

readonly class EntityId
{
    public string $value;

    public function __construct(?string $value = null)
    {
        $this->value = $value ?? Uuid::v7()->toRfc4122();
    }

    public static function fromString(string $value): self
    {
        if (!Uuid::isValid($value)) {
            throw new \InvalidArgumentException(sprintf('Invalid UUID: "%s".', $value));
        }

        return new self($value);
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
```

> **Note** : Ce VO wrap `symfony/uid` (Uuid v7) pour les identifiants exposés en API. Pour un BC spécifique, créer un alias typé (`ProductId extends EntityId`) pour le typage fort.

## Mapping XML — Templates

### Embeddable générique

```xml
<doctrine-mapping xmlns="http://doctrine-project.org/schemas/orm/doctrine-mapping"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xsi:schemaLocation="http://doctrine-project.org/schemas/orm/doctrine-mapping
                  https://www.doctrine-project.org/schemas/orm/doctrine-mapping.xsd">

    <embeddable name="App\SharedKernel\Domain\ValueObject\__VO_NAME__">
        <!-- fields here -->
    </embeddable>
</doctrine-mapping>
```

### Embedded dans une entite

```xml
<!-- Inside <entity> or <mapped-superclass> -->
<embedded name="__property__"
          class="App\SharedKernel\Domain\ValueObject\__VO_NAME__"
          column-prefix="__prefix__"/>
```

### Money mapping

```xml
<embeddable name="App\SharedKernel\Domain\ValueObject\Money">
    <field name="amount" type="integer"/>
    <field name="currency" type="string" length="3"/>
</embeddable>
```

### Email mapping

```xml
<embeddable name="App\SharedKernel\Domain\ValueObject\Email">
    <field name="value" type="string" length="320" column="email"/>
</embeddable>
```

**Note** : pour un VO a un seul champ comme `Email`, le `column` dans le mapping peut pointer vers le nom de colonne original pour eviter un renommage.

### DateRange mapping

```xml
<embeddable name="App\SharedKernel\Domain\ValueObject\DateRange">
    <field name="startDate" type="datetime_immutable" column="start_date"/>
    <field name="endDate" type="datetime_immutable" column="end_date"/>
</embeddable>
```

### Coordinates mapping

```xml
<embeddable name="App\SharedKernel\Domain\ValueObject\Coordinates">
    <field name="latitude" type="float"/>
    <field name="longitude" type="float"/>
</embeddable>
```

## Heuristiques de détection par préfixe

### Algorithme de groupement

1. Extraire tous les noms de propriétés d'une entite.
2. Normaliser les noms en camelCase.
3. Pour chaque propriété, extraire le préfixe potentiel :
   - `addressStreet` → préfixe `address`
   - `billingCity` → préfixe `billing`
   - `shippingZipCode` → préfixe `shipping`
4. Regrouper les propriétés par préfixe.
5. Filtrer les groupes de taille >= 2.
6. Croiser avec les patterns connus (Address, Money, etc.).

### Faux positifs a eviter

| Pattern | Raison | Action |
|---------|--------|--------|
| `createdAt` + `updatedAt` | Timestamps Doctrine, pas un concept métier | Ignorer |
| `createdBy` + `updatedBy` | Audit trail, gere par listeners | Ignorer |
| `id` + `uuid` | Identifiants, deja geres | Ignorer |
| Relations ManyToOne/OneToMany | Pas embeddable | Ignorer |
| Collections Doctrine | Pas embeddable | Ignorer |
| Champs avec `@ORM\GeneratedValue` | IDs auto-generes | Ignorer |
| Champs dans des traits Timestampable/Blameable | Geres par des extensions | Ignorer |

### Champs qui meritent un VO meme seuls

| Champ | Validation | Comportement | VO justifie si... |
|-------|-----------|-------------|-------------------|
| `email` | format RFC | normalisation lowercase | Utilise dans > 1 entite |
| `phone` | format E.164 | parsing indicatif | Validation métier requise |
| `url` | format URL | — | Validation métier requise |
| `slug` | format slug | normalisation | Logique de generation |
| `ipAddress` | format IPv4/v6 | — | Validation requise |
| `currency` | ISO 4217 | — | Mieux comme enum |
| `country` | ISO 3166 | — | Mieux comme enum |
| `locale` | BCP 47 | — | Validation requise |
| `color` | hex/rgb | conversion | Logique de rendu |
| `percentage` | 0-100 | calcul | Invariant métier |
| `quantity` | >= 0 | operations | Invariant métier |

## Checklist pre-extraction

Avant d'extraire, verifier :

- [ ] Les colonnes en base sont identifiees et documentees
- [ ] Le column-prefix est determine pour preserver les noms
- [ ] Les champs nullables sont identifies et la strategie est choisie (VO nullable vs Null Object)
- [ ] Les repositories qui utilisent ces champs en DQL sont identifies
- [ ] Les formulaires qui referent ces champs sont identifies
- [ ] Les serializers/normalizers concernes sont identifies
- [ ] Le format de mapping (XML vs attributs) est determine
- [ ] L'emplacement du VO est determine (SharedKernel vs BC-specifique)

## Checklist post-extraction

Apres l'extraction, verifier :

- [ ] `make phpstan` passe
- [ ] `make test` passe
- [ ] `make migration` genere une migration **vide** (schema inchange)
- [ ] Les repositories compilent (DQL adapte : `entity.address.city`)
- [ ] Les formulaires fonctionnent
- [ ] La serialization/deserialization fonctionne
- [ ] Les fixtures/seeds sont adaptees
